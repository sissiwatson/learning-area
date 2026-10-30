extends GutTest

const S := ConstructionSite.State


func test_lifecycle_with_exact_duration() -> void:
	var c := ConstructionSite.new()
	assert_true(c.start(1000, 300).ok)
	assert_false(c.update(1299))
	assert_eq(c.remaining(1299), 1)
	assert_almost_eq(c.progress(1150), 0.5, 0.0001)
	assert_true(c.update(1300), "terminé à 5 min pile")
	assert_eq(c.state, S.BUILT)
	assert_false(c.update(99999), "ne se termine qu'une fois")


func test_cannot_start_twice() -> void:
	var c := ConstructionSite.new()
	c.start(0, 300)
	assert_eq(c.start(10, 300).error, &"already_started")
	c.update(300)
	assert_eq(c.start(400, 300).error, &"already_started", "déjà construit")


func test_round_trip_and_sanitizing() -> void:
	var c := ConstructionSite.new()
	c.start(500, 300)
	var copy := ConstructionSite.from_dict(JSON.parse_string(JSON.stringify(c.to_dict())))
	assert_eq(copy.to_dict(), c.to_dict())
	assert_eq(ConstructionSite.from_dict({"state": "BUILDING", "start_at": 10, "end_at": 5}).state, S.IDLE)
	assert_eq(ConstructionSite.from_dict({"state": "??"}).state, S.IDLE)
