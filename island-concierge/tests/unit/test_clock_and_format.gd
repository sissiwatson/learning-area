extends GutTest

const FakeClock := preload("res://tests/helpers/fake_clock.gd")


func test_system_clock_is_close_to_system_time() -> void:
	var now := Clock.new().now()
	assert_almost_eq(float(now), Time.get_unix_time_from_system(), 2.0)


func test_fake_clock_only_moves_on_demand() -> void:
	var clock := FakeClock.new()
	var start := clock.now()
	assert_eq(clock.now(), start)
	clock.advance(90)
	assert_eq(clock.now(), start + 90)


func test_thousands_separator() -> void:
	assert_eq(NumberFormat.thousands(0), "0")
	assert_eq(NumberFormat.thousands(20), "20")
	assert_eq(NumberFormat.thousands(999), "999")
	assert_eq(NumberFormat.thousands(1000), "1 000")
	assert_eq(NumberFormat.thousands(1234567), "1 234 567")
	assert_eq(NumberFormat.thousands(-4500), "-4 500")
