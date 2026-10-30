extends GutTest

var p: Progression


func before_each() -> void:
	p = Progression.new([0, 50, 150, 300] as Array[int])


func test_level_boundaries() -> void:
	assert_eq(p.level(), 1)
	p.add_xp(49)
	assert_eq(p.level(), 1)
	p.add_xp(1)
	assert_eq(p.level(), 2, "niveau 2 à 50 XP exactement")
	p.add_xp(99)
	assert_eq(p.level(), 2)
	p.add_xp(1)
	assert_eq(p.level(), 3)


func test_add_xp_reports_levels_gained() -> void:
	assert_eq(p.add_xp(10).value, 0)
	assert_eq(p.add_xp(300).value, 3, "saut de plusieurs niveaux")
	assert_eq(p.level(), 4)
	assert_eq(p.level(), p.max_level())
	assert_eq(p.progress_in_level(), Vector2i(0, 0), "niveau maximum")


func test_progress_in_level() -> void:
	p.add_xp(80)
	assert_eq(p.progress_in_level(), Vector2i(30, 100))


func test_invalid_amounts() -> void:
	assert_eq(p.add_xp(0).error, &"invalid_amount")
	assert_eq(p.add_xp(-5).error, &"invalid_amount")
	assert_eq(p.xp, 0)


func test_round_trip_and_sanitizing() -> void:
	p.add_xp(77)
	var copy := Progression.from_dict(JSON.parse_string(JSON.stringify(p.to_dict())), p.thresholds)
	assert_eq(copy.xp, 77)
	assert_eq(Progression.from_dict({"xp": -9}, p.thresholds).xp, 0)
	assert_eq(Progression.from_dict({"xp": "beaucoup"}, p.thresholds).xp, 0)
