## Fichier de sauvegarde : écriture atomique, secours, corruption, versions.
extends GutTest

const DIR := "user://gut/save_manager"

var sm: Node


func before_each() -> void:
	sm = get_tree().root.get_node("SaveManager")
	sm.enabled = true
	sm.save_path = DIR.path_join("save.json")
	sm.migrations = {}
	_clean()


func after_each() -> void:
	_clean()
	sm.enabled = false
	sm.migrations = {}


func _clean() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func _files() -> PackedStringArray:
	return DirAccess.get_files_at(DIR)


func _write_raw(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func test_round_trip() -> void:
	assert_true(sm.write_save({"answer": 42}).ok)
	var r: Result = sm.read_save()
	assert_true(r.ok)
	assert_eq(r.value, {"answer": 42.0})
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(sm.save_path))
	assert_eq(raw.format, "island_concierge_save")
	assert_eq(int(raw.version), 1)


func test_no_save() -> void:
	assert_false(sm.has_save())
	assert_eq(sm.read_save().error, &"no_save")


func test_atomic_write_keeps_previous_save_as_backup() -> void:
	sm.write_save({"n": 1})
	sm.write_save({"n": 2})
	assert_false(FileAccess.file_exists(sm.save_path + ".tmp"), "pas de fichier temporaire restant")
	assert_true(FileAccess.file_exists(sm.backup_path()))
	var backup: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(sm.backup_path()))
	assert_eq(int(backup.data.n), 1)
	assert_eq(int(sm.read_save().value.n), 2)


func test_corrupt_main_save_falls_back_to_backup() -> void:
	sm.write_save({"n": 1})
	sm.write_save({"n": 2})
	_write_raw(sm.save_path, "{ ceci n'est pas du JSON")
	var r: Result = sm.read_save()
	assert_true(r.ok)
	assert_eq(int(r.value.n), 1)
	assert_eq(sm.last_issue, &"recovered_from_backup")
	var kept := Array(_files()).filter(func(f): return f.begins_with("save.json.corrupt-"))
	assert_eq(kept.size(), 1, "le fichier illisible est conservé à part")


func test_everything_corrupt_means_new_game_without_crash() -> void:
	_write_raw(sm.save_path, "")
	_write_raw(sm.backup_path(), "[1, 2, 3]")
	var r: Result = sm.read_save()
	assert_eq(r.error, &"corrupt_save")
	assert_eq(sm.last_issue, &"corrupt_save")
	assert_false(sm.has_save(), "les fichiers abîmés sont mis de côté")
	assert_eq(Array(_files()).filter(func(f): return "corrupt" in f).size(), 2)


func test_wrong_format_is_corrupt() -> void:
	_write_raw(sm.save_path, JSON.stringify({"format": "other_game", "version": 1, "data": {}}))
	assert_eq(sm.read_save().error, &"corrupt_save")


func test_save_from_a_newer_version_is_set_aside_not_overwritten() -> void:
	_write_raw(sm.save_path, JSON.stringify({"format": "island_concierge_save", "version": 99, "data": {"x": 1}}))
	assert_eq(sm.read_save().error, &"save_from_future")
	assert_eq(Array(_files()).filter(func(f): return "future" in f).size(), 1)


func test_migrations_are_applied_in_order() -> void:
	sm.migrations = {0: func(d: Dictionary) -> Dictionary:
		var out := d.duplicate()
		out["shells"] = out.get("coins", 0)
		out.erase("coins")
		return out}
	_write_raw(sm.save_path, JSON.stringify({"format": "island_concierge_save", "version": 0, "data": {"coins": 75}}))
	var r: Result = sm.read_save()
	assert_true(r.ok)
	assert_eq(int(r.value.shells), 75)
	assert_false(r.value.has("coins"))


func test_missing_migration_is_unsupported() -> void:
	_write_raw(sm.save_path, JSON.stringify({"format": "island_concierge_save", "version": 0, "data": {}}))
	assert_eq(sm.read_save().error, &"unsupported_version")


func test_disabled_manager_never_writes() -> void:
	sm.enabled = false
	assert_eq(sm.save_now().error, &"save_disabled")
	assert_false(sm.load_into_game(load("res://data/maps/mahana.tres")))
	assert_eq(_files().size(), 0)
