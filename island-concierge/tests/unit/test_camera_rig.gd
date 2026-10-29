extends GutTest

const VIEW := Vector2(1920, 1080)
const BOUNDS := Rect2(-2000, 0, 4000, 2000)

var rig: CameraRig


func before_each() -> void:
	rig = CameraRig.new()
	rig.configure(VIEW, BOUNDS, 2.0)
	rig.set_zoom(1.0)
	rig.center_on(BOUNDS.get_center())


func test_min_zoom_fits_whole_map() -> void:
	assert_almost_eq(rig.min_zoom, minf(1920.0 / 4000.0, 1080.0 / 2000.0), 0.0001)
	rig.set_zoom(0.01)
	assert_almost_eq(rig.zoom, rig.min_zoom, 0.0001)
	var visible := rig.visible_rect()
	assert_true(visible.size.x >= BOUNDS.size.x - 0.01)


func test_zoom_is_clamped_to_max() -> void:
	rig.set_zoom(50.0)
	assert_eq(rig.zoom, 2.0)


func test_pan_follows_finger() -> void:
	var before := rig.position
	rig.set_zoom(2.0)
	rig.center_on(before)
	rig.pan_screen(Vector2(100, 40))
	# le contenu suit le doigt : la caméra recule de delta / zoom
	assert_almost_eq(rig.position.x, before.x - 50.0, 0.001)
	assert_almost_eq(rig.position.y, before.y - 20.0, 0.001)


func test_zoom_at_keeps_point_under_cursor() -> void:
	var screen_point := Vector2(300, 200)
	var world_before := rig.screen_to_world(screen_point)
	rig.zoom_at(screen_point, 1.5)
	assert_almost_eq(rig.zoom, 1.5, 0.0001)
	assert_almost_eq(rig.screen_to_world(screen_point).distance_to(world_before), 0.0, 0.001)


func test_zoom_out_then_in_returns_to_same_view() -> void:
	var start := rig.position
	rig.zoom_at(Vector2(900, 500), 1.25)
	rig.zoom_at(Vector2(900, 500), 1.0 / 1.25)
	assert_almost_eq(rig.position.distance_to(start), 0.0, 0.01)


func test_pinch_moves_anchor_to_new_center() -> void:
	var anchor := rig.screen_to_world(Vector2(800, 500))
	rig.pinch(Vector2(800, 500), Vector2(900, 520), 1.2)
	assert_almost_eq(rig.world_to_screen(anchor).distance_to(Vector2(900, 520)), 0.0, 0.01)


func test_view_never_leaves_bounds() -> void:
	for z in [rig.min_zoom, 0.8, 1.0, 2.0]:
		rig.set_zoom(z)
		for d in [Vector2(1e6, 0), Vector2(-1e6, 0), Vector2(0, 1e6), Vector2(0, -1e6), Vector2(1e6, 1e6)]:
			rig.pan_screen(d)
			var v := rig.visible_rect()
			if v.size.x <= BOUNDS.size.x:
				assert_true(v.position.x >= BOUNDS.position.x - 0.01 and v.end.x <= BOUNDS.end.x + 0.01,
						"x hors limites à zoom %s" % z)
			if v.size.y <= BOUNDS.size.y:
				assert_true(v.position.y >= BOUNDS.position.y - 0.01 and v.end.y <= BOUNDS.end.y + 0.01,
						"y hors limites à zoom %s" % z)


func test_axis_smaller_than_view_is_centered() -> void:
	rig.set_zoom(rig.min_zoom)  # la largeur tient, la hauteur est plus petite que la vue
	rig.pan_screen(Vector2(0, 5000))
	assert_almost_eq(rig.position.y, BOUNDS.get_center().y, 0.01)


func test_zoom_near_edge_stays_in_bounds() -> void:
	rig.set_zoom(2.0)
	rig.pan_screen(Vector2(1e6, 1e6))  # coin haut-gauche
	rig.zoom_at(Vector2(0, 0), 0.6)
	var v := rig.visible_rect()
	assert_true(v.position.x >= BOUNDS.position.x - 0.01)
	assert_true(v.position.y >= BOUNDS.position.y - 0.01)


func test_fling_decelerates_and_stops() -> void:
	rig.fling(Vector2(-1500, 0))
	var start := rig.position
	var frames := 0
	while rig.step(1.0 / 60.0):
		frames += 1
		assert_lt(frames, 600, "l'inertie ne s'arrête pas")
		if frames >= 600:
			break
	assert_gt(rig.position.x, start.x, "l'inertie part dans le sens du geste")
	assert_eq(rig.velocity, Vector2.ZERO)


func test_fling_stops_at_bounds() -> void:
	rig.set_zoom(2.0)
	rig.fling(Vector2(-1e6, 0))
	for i in 120:
		rig.step(1.0 / 60.0)
	assert_eq(rig.velocity.x, 0.0)
	assert_almost_eq(rig.visible_rect().end.x, BOUNDS.end.x, 0.01)
