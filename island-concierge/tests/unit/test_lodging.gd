## Machine à états d'un logement et minuteurs (horloge passée en paramètre).
extends GutTest

const S := Lodging.State
const A := Lodging.Action
const CLEANING := 120
const NIGHT := 300

var l: Lodging
var tpl := BookingTemplateDef.new()


func before_each() -> void:
	l = Lodging.new()
	l.capacity = 2
	tpl.id = &"couple"; tpl.guest_name = "Camille et Noé"; tpl.guests = 2; tpl.nights = 2; tpl.nightly_price = 300


func _booking() -> Booking:
	return Booking.create(&"bk_0001", tpl, 20, 1000)


func _run_to(state: S, t := 1000) -> void:
	if state == S.VACANT: return
	l.book(_booking())
	if state == S.BOOKED: return
	l.start_preparing(t, CLEANING)
	if state == S.PREPARING: return
	l.update(t + CLEANING)
	if state == S.READY: return
	l.welcome_guests(t + CLEANING, NIGHT)
	if state == S.OCCUPIED: return
	l.update(t + CLEANING + 2 * NIGHT)


func test_nominal_cycle() -> void:
	assert_eq(l.state, S.VACANT)
	assert_true(l.book(_booking()).ok)
	assert_eq(l.state, S.BOOKED)
	assert_true(l.start_preparing(1000, CLEANING).ok)
	assert_eq(l.state, S.PREPARING)
	l.update(1000 + CLEANING)
	assert_eq(l.state, S.READY)
	assert_true(l.welcome_guests(1200, NIGHT).ok)
	assert_eq(l.state, S.OCCUPIED)
	l.update(1200 + 2 * NIGHT)
	assert_eq(l.state, S.STAY_COMPLETE)
	var r := l.collect_commission()
	assert_true(r.ok)
	assert_eq(r.value.id, &"bk_0001")
	assert_eq(l.state, S.VACANT)
	assert_null(l.booking)


func test_cleaning_lasts_exactly_the_configured_time() -> void:
	_run_to(S.PREPARING)
	assert_eq(l.update(1000 + CLEANING - 1), [] as Array[S])
	assert_eq(l.state, S.PREPARING)
	assert_eq(l.remaining(1000 + CLEANING - 1), 1)
	assert_eq(l.update(1000 + CLEANING), [S.READY] as Array[S])


func test_stay_lasts_nights_times_night_duration() -> void:
	_run_to(S.OCCUPIED)
	var start := 1000 + CLEANING
	l.update(start + 2 * NIGHT - 1)
	assert_eq(l.state, S.OCCUPIED, "2 nuits × 300 s = 600 s")
	assert_almost_eq(l.progress(start + NIGHT), 0.5, 0.0001)
	l.update(start + 2 * NIGHT)
	assert_eq(l.state, S.STAY_COMPLETE, "fin automatique du séjour")


func test_update_is_idempotent_and_never_skips_the_player_steps() -> void:
	_run_to(S.PREPARING)
	l.update(10_000_000)
	assert_eq(l.state, S.READY, "l'accueil reste une action du joueur")
	l.update(20_000_000)
	assert_eq(l.state, S.READY)


func test_available_actions_per_state() -> void:
	var expected := {
		S.VACANT: [], S.BOOKED: [A.PREPARE], S.PREPARING: [], S.READY: [A.WELCOME_GUESTS],
		S.OCCUPIED: [], S.STAY_COMPLETE: [A.COLLECT_COMMISSION],
	}
	for state in expected:
		before_each()
		_run_to(state)
		assert_eq(l.state, state)
		assert_eq(Array(l.available_actions()), expected[state], S.keys()[state])


func test_every_invalid_transition_is_refused_without_change() -> void:
	for state in S.values():
		for step in ["book", "prepare", "welcome", "collect"]:
			before_each()
			_run_to(state)
			var valid := {"book": S.VACANT, "prepare": S.BOOKED, "welcome": S.READY, "collect": S.STAY_COMPLETE}
			if valid[step] == state:
				continue
			var before := l.to_dict()
			var r: Result
			match step:
				"book": r = l.book(_booking())
				"prepare": r = l.start_preparing(5000, CLEANING)
				"welcome": r = l.welcome_guests(5000, NIGHT)
				"collect": r = l.collect_commission()
			assert_false(r.ok, "%s depuis %s" % [step, S.keys()[state]])
			assert_eq(l.to_dict(), before, "état inchangé après %s depuis %s" % [step, S.keys()[state]])


func test_collect_only_once() -> void:
	_run_to(S.STAY_COMPLETE)
	assert_true(l.collect_commission().ok)
	assert_eq(l.collect_commission().error, &"invalid_action")


func test_booking_refusals() -> void:
	tpl.guests = 3
	assert_eq(l.book(_booking()).error, &"capacity_exceeded")
	tpl.guests = 2
	l.book(_booking())
	assert_eq(l.book(_booking()).error, &"lodging_not_vacant")
	before_each()
	l.locked = true
	assert_eq(l.book(_booking()).error, &"lodging_locked")
	assert_eq(l.available_actions().size(), 0)


func test_timers_continue_while_the_game_is_closed() -> void:
	_run_to(S.OCCUPIED)
	var saved := JSON.parse_string(JSON.stringify(l.to_dict()))
	# ... application fermée deux heures ...
	var restored := Lodging.from_dict(saved, 2, false)
	assert_eq(restored.state, S.OCCUPIED)
	restored.update(1000 + CLEANING + 7200)
	assert_eq(restored.state, S.STAY_COMPLETE)
	assert_eq(restored.booking.commission(), 120)


func test_inconsistent_save_falls_back_to_vacant() -> void:
	var restored := Lodging.from_dict({"state": "OCCUPIED", "booking": null}, 2, false)
	assert_eq(restored.state, S.VACANT)
	assert_eq(Lodging.from_dict({"state": "DANCING"}, 2, false).state, S.VACANT)
