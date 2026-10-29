## Rejoue de vrais InputEvent sur la scène principale.
extends GutTest

var main: Node
var cam: MapCamera


func before_each() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child_autofree(main)
	cam = main.camera
	# Le viewport headless est carré : on impose un écran paysage réaliste.
	var bounds: Rect2 = main.map.world_bounds()
	cam.setup(bounds, bounds.get_center(), Vector2(1920, 1080))


func _touch(i: int, pressed: bool, pos: Vector2, t: int) -> void:
	var e := InputEventScreenTouch.new()
	e.index = i; e.pressed = pressed; e.position = pos
	cam.handle_input(e, t)


func _drag(i: int, pos: Vector2, t: int) -> void:
	var e := InputEventScreenDrag.new()
	e.index = i; e.position = pos
	cam.handle_input(e, t)


func test_initial_state() -> void:
	assert_almost_eq(cam.zoom.x, cam.initial_zoom_level, 0.0001)
	assert_true(cam.rig.bounds.grow(0.01).encloses(cam.rig.visible_rect()))


func test_one_finger_drag_moves_camera_node() -> void:
	var start := cam.position
	_touch(0, true, Vector2(900, 500), 0)
	_drag(0, Vector2(960, 500), 16)
	_drag(0, Vector2(1060, 540), 32)
	_touch(0, false, Vector2(1060, 540), 500)
	assert_almost_eq(cam.position.x, start.x - 100 / cam.zoom.x, 0.01)
	assert_almost_eq(cam.position.y, start.y - 40 / cam.zoom.x, 0.01)


func test_tap_emits_world_position_and_does_not_move() -> void:
	watch_signals(cam)
	var start := cam.position
	_touch(0, true, Vector2(960, 540), 0)
	_drag(0, Vector2(965, 543), 20)
	_touch(0, false, Vector2(965, 543), 80)
	assert_eq(cam.position, start)
	assert_signal_emitted(cam, "tapped_world")
	var world: Vector2 = get_signal_parameters(cam, "tapped_world")[0]
	assert_almost_eq(world.distance_to(cam.rig.screen_to_world(Vector2(965, 543))), 0.0, 0.01)


func test_wheel_zooms_at_cursor() -> void:
	var cursor := Vector2(1200, 300)
	var anchor := cam.rig.screen_to_world(cursor)
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_WHEEL_UP; e.pressed = true; e.position = cursor
	cam.handle_input(e, 0)
	assert_almost_eq(cam.zoom.x, cam.initial_zoom_level * cam.wheel_step, 0.0001)
	assert_almost_eq(cam.rig.world_to_screen(anchor).distance_to(cursor), 0.0, 0.01)
	e.button_index = MOUSE_BUTTON_WHEEL_DOWN
	cam.handle_input(e, 0)
	assert_almost_eq(cam.zoom.x, cam.initial_zoom_level, 0.0001)


func test_pinch_reaches_max_and_min_zoom() -> void:
	_touch(0, true, Vector2(860, 540), 0)
	_touch(1, true, Vector2(1060, 540), 0)
	_drag(1, Vector2(1900, 540), 16)
	_drag(0, Vector2(20, 540), 32)
	assert_almost_eq(cam.zoom.x, cam.max_zoom_level, 0.0001)
	_drag(0, Vector2(950, 540), 48)
	_drag(1, Vector2(960, 540), 64)
	assert_almost_eq(cam.zoom.x, cam.rig.min_zoom, 0.0001)


func test_touch_over_ui_is_ignored() -> void:
	cam.ui_hit_test = func(p: Vector2) -> bool: return p.x < 200
	var start := cam.position
	_touch(0, true, Vector2(100, 500), 0)
	_drag(0, Vector2(600, 500), 16)
	_touch(0, false, Vector2(600, 500), 32)
	assert_eq(cam.position, start)


func test_camera_is_idle_when_not_moving() -> void:
	assert_false(cam.is_processing(), "pas de traitement par image à l'arrêt")
