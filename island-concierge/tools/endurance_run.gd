## Recette d'endurance : la scène complète tourne en temps réel pendant
## plusieurs minutes, un joueur automatique (graine fixe) touche boutons,
## bâtiments et carte, la sauvegarde réelle (fichier temporaire) fonctionne,
## et le temps de jeu passe `SPEED` fois plus vite que le temps réel.
## Toutes les 10 s : mémoire, objets, nœuds, orphelins, images par seconde.
##
## godot --path . -s tools/endurance_run.gd -- <durée_s> <fichier_csv>
extends SceneTree

const SPEED := 20  # 1 s réelle = 20 s de jeu : séjours, productions, offres
const SAMPLE_EVERY := 10.0
const ACTION_EVERY := 0.4


## Horloge accélérée, monotone : part de l'heure système.
class FastClock:
	extends Clock
	var start_unix := int(Time.get_unix_time_from_system())
	var start_ms := Time.get_ticks_msec()

	func now() -> int:
		return start_unix + (Time.get_ticks_msec() - start_ms) * SPEED / 1000


var main: Node
var rng := RandomNumberGenerator.new()
var samples: Array[Dictionary] = []
var actions := {"buttons": 0, "taps": 0, "drags": 0, "wheels": 0}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var duration := float(args[0]) if args.size() > 0 else 300.0
	var csv_path := args[1] if args.size() > 1 else "user://endurance.csv"
	rng.seed = 12
	var save_manager := root.get_node("SaveManager")
	save_manager.save_path = "user://endurance/save.json"
	save_manager.delete_save()
	root.get_node("GameState").clock = FastClock.new()
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var started := Time.get_ticks_msec()
	var next_sample := 0.0
	var next_action := 0.0
	var frames := 0
	var frame_window_start := started
	while (Time.get_ticks_msec() - started) / 1000.0 < duration:
		await process_frame
		frames += 1
		var elapsed := (Time.get_ticks_msec() - started) / 1000.0
		if elapsed >= next_action:
			next_action += ACTION_EVERY
			_random_action()
		if elapsed >= next_sample:
			next_sample += SAMPLE_EVERY
			var window := maxf((Time.get_ticks_msec() - frame_window_start) / 1000.0, 0.001)
			_sample(elapsed, frames / window)
			frames = 0
			frame_window_start = Time.get_ticks_msec()
	var saved: bool = save_manager.save_now().ok
	_write_csv(csv_path)
	var gs := root.get_node("GameState")
	print("ENDURANCE actions %s ; partie : niveau %d, %d coquillages, %d séjours, quêtes terminées %d ; sauvegarde %s" % [
			actions, gs.level(), gs.wallet.balance(&"shells"), gs.stay_history.size(),
			gs.quest_log.with_status(QuestLog.Status.COMPLETED).size(), "ok" if saved else "ÉCHEC"])
	save_manager.delete_save()
	quit(0 if saved else 1)


func _random_action() -> void:
	var roll := rng.randf()
	var buttons: Array[BaseButton] = []
	for node in main.find_children("*", "BaseButton", true, false):
		if node.is_visible_in_tree() and not node.disabled:
			buttons.append(node)
	if roll < 0.5 and not buttons.is_empty():
		buttons[rng.randi_range(0, buttons.size() - 1)].pressed.emit()
		actions.buttons += 1
	elif roll < 0.80:
		var views: Array = main.map.buildings.values()
		var view: BuildingView = views[rng.randi_range(0, views.size() - 1)]
		var pos: Vector2 = main.camera.rig.world_to_screen(view.global_position + Vector2(0, -20))
		_touch(0, true, pos)
		_touch(0, false, pos)
		actions.taps += 1
	elif roll < 0.92:
		var wheel := InputEventMouseButton.new()
		wheel.button_index = MOUSE_BUTTON_WHEEL_UP if rng.randf() < 0.5 else MOUSE_BUTTON_WHEEL_DOWN
		wheel.pressed = true
		wheel.position = _to_window(root.get_visible_rect().size / 2.0)
		Input.parse_input_event(wheel)
		actions.wheels += 1
	else:
		var size: Vector2 = root.get_visible_rect().size
		var a := Vector2(rng.randf() * size.x, rng.randf() * size.y)
		var b := a + Vector2(rng.randf_range(-300, 300), rng.randf_range(-200, 200))
		_touch(0, true, a)
		for k in 4:
			var e := InputEventScreenDrag.new()
			e.index = 0; e.position = _to_window(a.lerp(b, (k + 1) / 4.0))
			Input.parse_input_event(e)
			Input.flush_buffered_events()  # sinon les mouvements sont fusionnés
		_touch(0, false, b)
		actions.drags += 1


func _touch(index: int, pressed: bool, pos: Vector2) -> void:
	var e := InputEventScreenTouch.new()
	e.index = index; e.pressed = pressed; e.position = _to_window(pos)
	Input.parse_input_event(e)
	Input.flush_buffered_events()


## Coordonnées de la scène (base 1920×1080 étirée) vers celles de la fenêtre.
func _to_window(pos: Vector2) -> Vector2:
	return root.get_final_transform() * pos


func _sample(elapsed: float, fps: float) -> void:
	var s := {
		"t": int(elapsed),
		"fps": snappedf(fps, 0.1),
		"static_mb": snappedf(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.01),
		"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"orphans": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
		"draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
	}
	samples.append(s)
	print("ENDURANCE ", s)


func _write_csv(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("CSV impossible : " + path)
		return
	var keys: Array = samples[0].keys() if not samples.is_empty() else []
	file.store_line(",".join(keys))
	for s in samples:
		file.store_line(",".join(keys.map(func(k): return str(s[k]))))
