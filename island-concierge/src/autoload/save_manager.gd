## Sauvegarde locale (autoload `SaveManager`).
##
## - Fichier JSON versionné : { "format", "version", "saved_at", "data" }.
## - Écriture atomique : fichier temporaire relu et vérifié, puis l'ancienne
##   sauvegarde devient la copie de secours (.bak) et le temporaire la remplace.
## - Lecture : sauvegarde principale, sinon copie de secours ; un fichier
##   illisible est conservé à part (.corrupt-<horodatage>) et n'empêche
##   jamais de jouer (nouvelle partie).
## - Migrations successives des anciennes versions ; une sauvegarde d'une
##   version plus récente est mise de côté, jamais écrasée.
## - Déclencheurs : passage en arrière-plan ou fermeture (immédiat),
##   encaissement (immédiat), toute autre modification (après 2 s de calme).
extends Node

const FORMAT := "island_concierge_save"
const CURRENT_VERSION := 1
const DEBOUNCE_SECONDS := 2.0

## Désactivée pendant les tests (voir tests/helpers/pre_run_hook.gd).
var enabled := true
var save_path := "user://save.json"
## Migrations : version n -> Callable(data: Dictionary) -> Dictionary (version n + 1).
var migrations := {}
## Dernier incident de lecture (&"" si aucun) : corrupt_save, recovered_from_backup,
## save_from_future, unsupported_version.
var last_issue := &""

var _session_started := false
var _debounce := Timer.new()


func _ready() -> void:
	_debounce.one_shot = true
	_debounce.wait_time = DEBOUNCE_SECONDS
	_debounce.timeout.connect(save_now)
	add_child(_debounce)
	for sig in [EventBus.currency_changed, EventBus.inventory_changed, EventBus.lodging_state_changed,
			EventBus.offers_changed, EventBus.production_started, EventBus.production_completed]:
		sig.connect(func(_a = null, _b = null): request_save())
	EventBus.commission_collected.connect(func(_a, _b, _c): save_now())


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST \
			or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		save_now()


func backup_path() -> String:
	return save_path + ".bak"


func has_save() -> bool:
	return FileAccess.file_exists(save_path) or FileAccess.file_exists(backup_path())


## Charge la sauvegarde dans GameState. Renvoie false s'il faut commencer une
## nouvelle partie (pas de sauvegarde, ou sauvegarde inutilisable).
func load_into_game(map: MapDef) -> bool:
	if not enabled:
		return false
	_session_started = true
	var read := read_save()
	if not read.ok:
		return false
	var restored := GameState.load_save_dict(read.value, map)
	if not restored.ok:
		last_issue = restored.error
		return false
	return true


## Lit la sauvegarde (principale puis secours) et applique les migrations.
func read_save() -> Result:
	last_issue = &""
	if not has_save():
		return Result.failure(&"no_save")
	var main := _read_file(save_path)
	if main.ok:
		return main
	if main.error in [&"save_from_future", &"unsupported_version"]:
		last_issue = main.error
		_set_aside(save_path, "future" if main.error == &"save_from_future" else "unsupported")
		return main
	var backup := _read_file(backup_path())
	if FileAccess.file_exists(save_path):
		_set_aside(save_path, "corrupt")
	if backup.ok:
		last_issue = &"recovered_from_backup"
		return backup
	last_issue = &"corrupt_save"
	if FileAccess.file_exists(backup_path()):
		_set_aside(backup_path(), "corrupt")
	return Result.failure(&"corrupt_save")


## Programme une sauvegarde après quelques secondes sans modification.
func request_save() -> void:
	if enabled and _session_started:
		_debounce.start()


## Sauvegarde immédiatement l'état de GameState.
func save_now() -> Result:
	_debounce.stop()
	if not enabled or not _session_started or GameState.map == null:
		return Result.failure(&"save_disabled")
	return write_save(GameState.to_save_dict())


func write_save(data: Dictionary) -> Result:
	var payload := JSON.stringify({
		"format": FORMAT, "version": CURRENT_VERSION,
		"saved_at": int(Time.get_unix_time_from_system()), "data": data,
	}, "\t")
	DirAccess.make_dir_recursive_absolute(save_path.get_base_dir())
	var tmp := save_path + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		return Result.failure(&"write_failed")
	file.store_string(payload)
	file.close()
	# Vérifie le fichier écrit avant de remplacer quoi que ce soit.
	if not _read_file(tmp).ok:
		DirAccess.remove_absolute(tmp)
		return Result.failure(&"write_failed")
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(backup_path())
		DirAccess.rename_absolute(save_path, backup_path())
	if DirAccess.rename_absolute(tmp, save_path) != OK:
		return Result.failure(&"write_failed")
	return Result.success()


## Supprime la sauvegarde et sa copie (nouvelle partie volontaire, tests).
func delete_save() -> void:
	for path in [save_path, backup_path(), save_path + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


func _read_file(path: String) -> Result:
	if not FileAccess.file_exists(path):
		return Result.failure(&"no_save")
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return Result.failure(&"corrupt_save")
	var parsed: Variant = json.data
	if not parsed is Dictionary or parsed.get("format") != FORMAT or not parsed.get("data") is Dictionary:
		return Result.failure(&"corrupt_save")
	var version := int(parsed.get("version", 0))
	if version > CURRENT_VERSION:
		return Result.failure(&"save_from_future")
	var data: Dictionary = parsed.data
	while version < CURRENT_VERSION:
		if not migrations.has(version):
			return Result.failure(&"unsupported_version")
		data = migrations[version].call(data)
		version += 1
	return Result.success(data)


## Met un fichier problématique de côté (jamais supprimé).
func _set_aside(path: String, label: String) -> void:
	var target := "%s.%s-%d" % [save_path, label, Time.get_ticks_usec()]
	DirAccess.rename_absolute(path, target)
