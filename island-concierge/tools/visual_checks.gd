## Vérifications visuelles : lance la scène principale, rejoue des gestes
## simulés (mêmes InputEvent que sur un écran tactile) et enregistre une
## capture par scénario. Voir tools/visual_checks.sh.
##
## godot --path . -s tools/visual_checks.gd -- <dossier_sortie> [scénario...]
extends SceneTree

const SCENARIOS := ["zoom_initial", "zoom_min", "zoom_max", "pan_after_drag"]

var main: Node
var cam: MapCamera
var out_dir := ""
var _t := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("Usage : -- <dossier_sortie> [scénario...]")
		quit(2)
		return
	out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	var wanted: Array = args.slice(1) if args.size() > 1 else SCENARIOS
	for name in wanted:
		await _reset()
		await call("_scenario_" + name)
		await _capture(name)
	quit()


func _reset() -> void:
	if main:
		main.queue_free()
		await process_frame
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	cam = main.camera


func _capture(name: String) -> void:
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var path := out_dir.path_join(name + ".png")
	root.get_texture().get_image().save_png(path)
	print("capture : %s (zoom %.3f)" % [path, cam.rig.zoom])


func _touch(i: int, pressed: bool, pos: Vector2) -> void:
	var e := InputEventScreenTouch.new()
	e.index = i; e.pressed = pressed; e.position = pos
	_t += 16
	cam.handle_input(e, _t)


func _drag(i: int, pos: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = i; e.position = pos
	_t += 16
	cam.handle_input(e, _t)


## Pincement simulé autour de `center`, écart des doigts de `from` à `to` px.
func _pinch(center: Vector2, from: float, to: float) -> void:
	_touch(0, true, center - Vector2(from / 2, 0))
	_touch(1, true, center + Vector2(from / 2, 0))
	for k in range(1, 11):
		var gap := lerpf(from, to, k / 10.0)
		_drag(0, center - Vector2(gap / 2, 0))
		_drag(1, center + Vector2(gap / 2, 0))
	_touch(0, false, center - Vector2(to / 2, 0))
	_touch(1, false, center + Vector2(to / 2, 0))


func _scenario_zoom_initial() -> void:
	pass


func _scenario_zoom_min() -> void:
	_pinch(Vector2(960, 540), 900, 60)


func _scenario_zoom_max() -> void:
	# Pincement écartant centré sur le bureau de conciergerie (parcelle 14,14).
	var target: Vector2 = cam.rig.world_to_screen(main.map.cell_center(Vector2i(15, 15)) - Vector2(0, 32))
	_pinch(target, 100, 1400)
	_pinch(target, 100, 1400)


func _scenario_pan_after_drag() -> void:
	_touch(0, true, Vector2(1400, 700))
	for k in range(1, 21):
		_drag(0, Vector2(1400 - 30 * k, 700 - 12 * k))
	_t += 400  # pause avant le lâcher : pas d'inertie
	_touch(0, false, Vector2(800, 460))
