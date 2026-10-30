extends GutTest

var recipe := RecipeDef.new()
var p: Producer


func before_each() -> void:
	recipe.id = &"harvest_pineapple"
	recipe.duration_seconds = 30
	p = Producer.new(1)


func test_start_then_done_at_exact_duration() -> void:
	assert_true(p.start(recipe, 1000).ok)
	assert_eq(p.slot_state(0, 1029), Producer.SlotState.RUNNING)
	assert_eq(p.remaining(0, 1029), 1)
	assert_almost_eq(p.progress(0, 1015), 0.5, 0.0001)
	assert_eq(p.slot_state(0, 1030), Producer.SlotState.DONE)
	assert_eq(p.done_slots(1030), [0] as Array[int])


func test_busy_slot_refuses_a_second_start() -> void:
	p.start(recipe, 0)
	assert_eq(p.start(recipe, 1).error, &"producer_busy")
	p.clear(0)
	assert_true(p.start(recipe, 2).ok)


func test_multiple_slots() -> void:
	var two := Producer.new(2)
	assert_eq(two.start(recipe, 0).value, 0)
	assert_eq(two.start(recipe, 0).value, 1)
	assert_eq(two.start(recipe, 0).error, &"producer_busy")


func test_round_trip_and_sanitizing() -> void:
	p.start(recipe, 500)
	var copy := Producer.from_dict(JSON.parse_string(JSON.stringify(p.to_dict())), 1, [&"harvest_pineapple"])
	assert_eq(copy.slot_state(0, 529), Producer.SlotState.RUNNING)
	assert_eq(copy.slot_state(0, 530), Producer.SlotState.DONE)
	var unknown := Producer.from_dict(p.to_dict(), 1, [&"other"])
	assert_eq(unknown.slot_state(0, 600), Producer.SlotState.IDLE, "recette disparue : emplacement libéré")
	var bad := Producer.from_dict({"slots": [{"recipe": "harvest_pineapple", "start": 100, "end": 50}]}, 1, [&"harvest_pineapple"])
	assert_eq(bad.slot_state(0, 0), Producer.SlotState.IDLE)
