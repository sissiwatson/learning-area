extends GutTest

const S := Lodging.State
const A := Lodging.Action


func test_starts_vacant_with_accept_booking_only() -> void:
	var l := Lodging.new()
	assert_eq(l.state, S.VACANT)
	assert_eq(l.available_actions(), [A.ACCEPT_BOOKING] as Array[Lodging.Action])


func test_full_cycle_returns_to_vacant() -> void:
	var l := Lodging.new()
	var expected := [S.BOOKED, S.READY, S.OCCUPIED, S.STAY_COMPLETE, S.VACANT]
	var actions := [A.ACCEPT_BOOKING, A.PREPARE, A.WELCOME_GUESTS, A.END_STAY, A.COLLECT_COMMISSION]
	for i in actions.size():
		var r := l.perform(actions[i])
		assert_true(r.ok)
		assert_eq(l.state, expected[i])


func test_exactly_one_action_per_state() -> void:
	var l := Lodging.new()
	for action in [A.ACCEPT_BOOKING, A.PREPARE, A.WELCOME_GUESTS, A.END_STAY, A.COLLECT_COMMISSION]:
		assert_eq(l.available_actions().size(), 1)
		l.perform(action)


func test_invalid_action_is_refused_and_changes_nothing() -> void:
	var l := Lodging.new()
	var r := l.perform(A.WELCOME_GUESTS)  # accueillir sans réservation ni préparation
	assert_false(r.ok)
	assert_eq(r.error, &"invalid_action")
	assert_eq(l.state, S.VACANT)


func test_action_cannot_be_repeated() -> void:
	var l := Lodging.new()
	assert_true(l.perform(A.ACCEPT_BOOKING).ok)
	assert_false(l.perform(A.ACCEPT_BOOKING).ok)
	assert_eq(l.state, S.BOOKED)
