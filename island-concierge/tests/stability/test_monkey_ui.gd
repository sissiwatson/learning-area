## Recette de stabilité de l'interface : des milliers de touchers, glissés et
## pincements aléatoires (graine fixe) sur la scène complète, avec le temps
## qui passe. Aucune erreur moteur (vérifiée par tools/run_tests.sh), pas de
## fuite de nœuds, panneau et dialogue jamais affichés ensemble.
extends GutTest

const FakeClock := preload("res://tests/helpers/fake_clock.gd")
const VIEW := Vector2(1920, 1080)
const EVENTS := 1200

var main: Node
var clock: FakeClock
var rng := RandomNumberGenerator.new()
var stats := {}


func before_each() -> void:
	clock = FakeClock.new()
	GameState.clock = clock
	GameState.new_game(load("res://data/maps/mahana.tres"))
	main = load("res://scenes/main.tscn").instantiate()
	add_child_autofree(main)
	main.camera.setup(main.map.world_bounds(), main.map.world_bounds().get_center(), VIEW)
	await get_tree().process_frame
	main.camera.tapped_world.connect(func(_w): stats.map_taps += 1)
	stats = {"map_taps": 0, "taps": 0, "buttons": 0, "drags": 0, "pinches": 0, "panels": 0, "dialogues": 0}


func after_each() -> void:
	GameState.clock = Clock.new()


func _send(event: InputEvent) -> void:
	Input.parse_input_event(event)
	Input.flush_buffered_events()


## Les positions sont données dans la scène ; Input attend celles de la
## fenêtre (en headless, fenêtre 0×0 : l'étirement n'est pas l'identité).
func _to_window(pos: Vector2) -> Vector2:
	return get_tree().root.get_final_transform() * pos


func _touch(index: int, pressed: bool, pos: Vector2) -> void:
	var e := InputEventScreenTouch.new()
	e.index = index; e.pressed = pressed; e.position = _to_window(pos)
	_send(e)


func _drag(index: int, from: Vector2, to: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = index; e.position = _to_window(to); e.relative = _to_window(to) - _to_window(from)
	_send(e)


func _random_point() -> Vector2:
	return Vector2(rng.randf_range(0, VIEW.x), rng.randf_range(0, VIEW.y))


## Boutons visibles et actifs de l'interface (dialogue, panneau, bandeau…).
func _visible_buttons() -> Array[BaseButton]:
	var result: Array[BaseButton] = []
	for node in main.find_children("*", "BaseButton", true, false):
		var button := node as BaseButton
		if button.is_visible_in_tree() and not button.disabled:
			result.append(button)
	return result


func _random_event() -> void:
	var roll := rng.randf()
	if roll < 0.35:
		var buttons := _visible_buttons()
		if not buttons.is_empty():
			var button: BaseButton = buttons[rng.randi_range(0, buttons.size() - 1)]
			button.pressed.emit()
			stats.buttons += 1
			return
	if roll < 0.70:
		var pos := _random_point()
		_touch(0, true, pos)
		_touch(0, false, pos)
		stats.taps += 1
	elif roll < 0.90:
		var a := _random_point()
		var b := a + Vector2(rng.randf_range(-400, 400), rng.randf_range(-300, 300))
		_touch(0, true, a)
		for i in 4:
			_drag(0, a.lerp(b, i / 4.0), a.lerp(b, (i + 1) / 4.0))
		_touch(0, false, b)
		stats.drags += 1
	else:
		var c := _random_point()
		var spread := rng.randf_range(0.5, 2.0)
		_touch(0, true, c - Vector2(100, 0))
		_touch(1, true, c + Vector2(100, 0))
		_drag(1, c + Vector2(100, 0), c + Vector2(100 * spread, 0))
		_touch(1, false, c + Vector2(100 * spread, 0))
		_touch(0, false, c - Vector2(100, 0))
		stats.pinches += 1


func _check_screen() -> void:
	var panel_open: bool = main.panel.visible
	var dialogue_open: bool = main.dialogue_box.visible
	if panel_open:
		stats.panels += 1
	if dialogue_open:
		stats.dialogues += 1
	if panel_open and dialogue_open:
		fail_test("panneau et dialogue affichés ensemble")


func test_monkey_session_stays_stable_without_leaks() -> void:
	rng.seed = 7
	await wait_process_frames(5)
	var nodes_before := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var orphans_before := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	for i in EVENTS:
		_random_event()
		if rng.randf() < 0.3:
			clock.advance([1, 10, 30, 60, 300][rng.randi_range(0, 4)])
			GameState.tick()
		if i % 4 == 0:
			await get_tree().process_frame
			_check_screen()
	gut.p("singe : %s, solde %d, niveau %d, quêtes terminées %d" % [stats,
			GameState.wallet.balance(&"shells"), GameState.level(),
			GameState.quest_log.with_status(QuestLog.Status.COMPLETED).size()])
	# Laisse finir les animations (arrivées, gains flottants, bulles).
	await wait_seconds(6)
	var nodes_after := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var orphans_after := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	gut.p("nœuds %d -> %d, orphelins %d -> %d" % [nodes_before, nodes_after, orphans_before, orphans_after])
	assert_lt(nodes_after - nodes_before, 40.0, "pas d'accumulation de nœuds")
	assert_lte(orphans_after, orphans_before, "aucun nœud orphelin créé")
	assert_gt(stats.buttons, 50, "les boutons de l'interface ont réellement été utilisés")
	assert_gt(stats.panels, 0, "des panneaux de bâtiment ont été ouverts")
