## Met en scène les quêtes : joue le dialogue d'introduction d'une quête
## disponible (puis la démarre), le dialogue de conclusion d'une quête
## terminée, annonce les fins de quête et place les pastilles « ! » sur les
## personnages. Un seul dialogue à la fois, dans l'ordre d'arrivée.
class_name QuestDirector
extends Node

var dialogue_box: DialogueBox
var toasts: ToastStack
var map: WorldMap
## File d'attente : { "dialogue": DialogueDef, "start": StringName (quête à démarrer ou &"") }.
var queue: Array[Dictionary] = []
var _playing: Dictionary = {}


func setup(box: DialogueBox, toast_stack: ToastStack, world: WorldMap) -> void:
	dialogue_box = box
	toasts = toast_stack
	map = world
	box.finished.connect(_on_dialogue_finished)
	EventBus.quest_available.connect(_on_quest_available)
	EventBus.quest_completed.connect(_on_quest_completed)
	EventBus.quest_started.connect(func(_id): refresh_markers())
	# Quêtes déjà disponibles (nouvelle partie ou sauvegarde reprise).
	for q in GameState.quest_log.with_status(QuestLog.Status.AVAILABLE):
		_on_quest_available(q.id)
	refresh_markers()


func _on_quest_available(id: StringName) -> void:
	var q := GameState.quest_log.get_quest(id)
	for entry in queue + ([_playing] if not _playing.is_empty() else []):
		if entry.start == id:
			return
	if q.intro_dialogue:
		_enqueue({"dialogue": q.intro_dialogue, "start": id})
	else:
		GameState.start_quest(id)
	refresh_markers()


func _on_quest_completed(id: StringName) -> void:
	var q := GameState.quest_log.get_quest(id)
	toasts.show_message(tr("TOAST_QUEST_DONE") % tr(q.title_key))
	if q.outro_dialogue:
		_enqueue({"dialogue": q.outro_dialogue, "start": &""})


## Joue maintenant le dialogue en attente d'un personnage (toucher le PNJ).
func play_for_npc(npc_id: StringName) -> bool:
	for i in queue.size():
		var line: DialogueLineDef = queue[i].dialogue.lines[0]
		if line.speaker and line.speaker.id == npc_id and _playing.is_empty():
			var entry := queue[i]
			queue.remove_at(i)
			queue.push_front(entry)
			_play_next()
			return true
	return false


func refresh_markers() -> void:
	if map == null:
		return
	var waiting := {}
	for entry in queue:
		var line: DialogueLineDef = entry.dialogue.lines[0]
		if line.speaker:
			waiting[line.speaker.id] = true
	for id in map.npcs:
		map.npcs[id].set_has_story(waiting.has(id))


func _enqueue(entry: Dictionary) -> void:
	queue.append(entry)
	refresh_markers()
	if _playing.is_empty():
		_play_next.call_deferred()


func _play_next() -> void:
	if not _playing.is_empty() or queue.is_empty():
		return
	_playing = queue.pop_front()
	refresh_markers()
	dialogue_box.play(_playing.dialogue)


func _on_dialogue_finished(_id: StringName) -> void:
	var entry := _playing
	_playing = {}
	if entry.get("start", &"") != &"":
		GameState.start_quest(entry.start)
	refresh_markers()
	_play_next()
