extends GutTest

var g: TouchGestures
var pans: Array = []
var pinches: Array = []
var taps: Array = []
var flings: Array = []


func before_each() -> void:
	g = TouchGestures.new()
	pans.clear(); pinches.clear(); taps.clear(); flings.clear()
	g.panned.connect(func(d): pans.append(d))
	g.pinched.connect(func(a, b, f): pinches.append([a, b, f]))
	g.tapped.connect(func(p): taps.append(p))
	g.flung.connect(func(v): flings.append(v))


func _total_pan() -> Vector2:
	var s := Vector2.ZERO
	for d in pans:
		s += d
	return s


func test_simple_tap() -> void:
	g.touch(0, true, Vector2(500, 500), 0)
	g.touch(0, false, Vector2(500, 500), 120)
	assert_eq(taps, [Vector2(500, 500)])
	assert_eq(pans.size(), 0)


func test_jittery_tap_does_not_move_map() -> void:
	g.touch(0, true, Vector2(500, 500), 0)
	g.drag(0, Vector2(508, 495), 30)
	g.drag(0, Vector2(512, 503), 60)
	g.touch(0, false, Vector2(512, 503), 100)
	assert_eq(pans.size(), 0, "aucun déplacement pendant un tap")
	assert_eq(taps.size(), 1)


func test_long_press_is_not_a_tap() -> void:
	g.touch(0, true, Vector2(500, 500), 0)
	g.touch(0, false, Vector2(500, 500), 1000)
	assert_eq(taps.size(), 0)


func test_drag_beyond_slop_pans_without_jump() -> void:
	g.touch(0, true, Vector2(500, 500), 0)
	g.drag(0, Vector2(540, 500), 16)  # franchit le seuil : début du glisser, pas de saut
	assert_eq(pans.size(), 0)
	g.drag(0, Vector2(560, 510), 32)
	g.drag(0, Vector2(600, 530), 48)
	assert_eq(_total_pan(), Vector2(60, 30))
	g.touch(0, false, Vector2(600, 530), 60)
	assert_eq(taps.size(), 0, "un glisser n'est pas un tap")


func test_quick_release_after_drag_flings() -> void:
	g.touch(0, true, Vector2(500, 500), 0)
	for i in range(1, 8):
		g.drag(0, Vector2(500 + 40 * i, 500), 16 * i)
	g.touch(0, false, Vector2(780, 500), 16 * 7 + 10)
	assert_eq(flings.size(), 1)
	assert_gt(flings[0].x, 0.0)


func test_release_after_pause_does_not_fling() -> void:
	g.touch(0, true, Vector2(500, 500), 0)
	g.drag(0, Vector2(560, 500), 16)
	g.drag(0, Vector2(600, 500), 32)
	g.touch(0, false, Vector2(600, 500), 500)
	assert_eq(flings.size(), 0)


func test_pinch_factor_and_centers() -> void:
	g.touch(0, true, Vector2(400, 500), 0)
	g.touch(1, true, Vector2(600, 500), 10)
	g.drag(1, Vector2(800, 500), 20)  # écart 200 -> 400
	assert_eq(pinches.size(), 1)
	assert_almost_eq(pinches[0][2], 2.0, 0.0001)
	assert_eq(pinches[0][0], Vector2(500, 500))
	assert_eq(pinches[0][1], Vector2(600, 500))
	assert_eq(pans.size(), 0)


func test_second_finger_cancels_tap() -> void:
	g.touch(0, true, Vector2(400, 500), 0)
	g.touch(1, true, Vector2(600, 500), 10)
	g.touch(1, false, Vector2(600, 500), 50)
	g.touch(0, false, Vector2(400, 500), 60)
	assert_eq(taps.size(), 0)


func test_lifting_one_finger_continues_drag_without_jump() -> void:
	g.touch(0, true, Vector2(400, 500), 0)
	g.touch(1, true, Vector2(600, 500), 10)
	g.drag(1, Vector2(700, 500), 20)
	g.touch(0, false, Vector2(400, 500), 30)  # le doigt 0 se lève
	assert_eq(g.finger_count(), 1)
	assert_true(g.is_dragging())
	g.drag(1, Vector2(710, 505), 40)
	assert_eq(pans, [Vector2(10, 5)], "le glisser reprend depuis la position du doigt restant")
	g.touch(1, false, Vector2(710, 505), 300)
	assert_eq(taps.size(), 0)


func test_third_finger_is_ignored() -> void:
	g.touch(0, true, Vector2(400, 500), 0)
	g.touch(1, true, Vector2(600, 500), 0)
	g.touch(2, true, Vector2(500, 300), 0)
	g.drag(2, Vector2(100, 100), 10)
	assert_eq(pinches.size(), 0)
	g.touch(0, false, Vector2(400, 500), 20)
	# restent 1 et 2 : le pincement utilise désormais ces deux doigts sans saut
	g.drag(1, Vector2(600, 500), 30)
	assert_almost_eq(pinches[-1][2], 1.0, 0.0001)


func test_gesture_starting_on_ui_is_ignored() -> void:
	g.touch(0, true, Vector2(100, 100), 0, true)
	g.drag(0, Vector2(400, 400), 10)
	g.touch(0, false, Vector2(400, 400), 20)
	assert_eq(pans.size() + taps.size() + flings.size(), 0)
	assert_eq(g.finger_count(), 0)


func test_cancel_resets_everything() -> void:
	g.touch(0, true, Vector2(100, 100), 0)
	g.touch(1, true, Vector2(300, 100), 0)
	g.cancel()
	assert_eq(g.finger_count(), 0)
	g.touch(1, false, Vector2(300, 100), 10)
	assert_eq(taps.size(), 0)
