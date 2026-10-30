## Boucle de réservation complète sur Mahana, via GameState, avec horloge
## simulée : aucun test n'attend réellement.
extends GutTest

const FakeClock := preload("res://tests/helpers/fake_clock.gd")

var clock: FakeClock
var map: MapDef


func before_each() -> void:
	clock = FakeClock.new()
	GameState.clock = clock
	map = load("res://data/maps/mahana.tres")
	GameState.new_game(map)


func after_each() -> void:
	GameState.clock = Clock.new()


func _first_offer() -> StringName:
	return GameState.bookings.offers[0].id


func _advance(seconds: int) -> void:
	clock.advance(seconds)
	GameState.tick()


## Ménage avec le panier d'accueil exigé (les productions ont leurs propres tests).
func _prepare() -> Result:
	GameState.add_items({&"welcome_basket": 1})
	return GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.PREPARE)


func _state() -> Lodging.State:
	return GameState.get_lodging(&"hibiscus_1").state


func test_prototype_durations_come_from_data() -> void:
	assert_eq(GameState.timings.night_seconds, 300, "une nuit = 5 min")
	assert_eq(GameState.timings.cleaning_seconds, 120, "ménage = 2 min")
	var recipes := {}
	for r in Database.catalog["recipes"]:
		recipes[r.id] = r.duration_seconds
	assert_eq(recipes, {&"harvest_pineapple": 30, &"craft_welcome_basket": 60})
	var site: BuildingDef = Database.get_def("buildings", &"tiki_bar_site")
	assert_eq(site.construction.build_seconds, 300, "tiki bar = 5 min")
	assert_between(GameState.timings.excursion_min_seconds, 180, 300)
	assert_between(GameState.timings.excursion_max_seconds, 180, 300)


func test_first_offer_is_the_tutorial_couple() -> void:
	assert_eq(GameState.bookings.offers.size(), 1)
	assert_eq(GameState.bookings.offers[0].template.id, &"couple_camille_noe")


func test_full_loop_amounts_and_durations() -> void:
	watch_signals(EventBus)
	var r := GameState.accept_offer(_first_offer())
	assert_true(r.ok)
	assert_eq(_state(), Lodging.State.BOOKED)
	assert_signal_emitted(EventBus, "booking_accepted")

	assert_true(_prepare().ok)
	_advance(119)
	assert_eq(_state(), Lodging.State.PREPARING)
	_advance(1)
	assert_eq(_state(), Lodging.State.READY)

	assert_true(GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.WELCOME_GUESTS).ok)
	_advance(599)
	assert_eq(_state(), Lodging.State.OCCUPIED)
	assert_eq(GameState.wallet.balance(&"shells"), 50, "rien n'est versé avant la fin")
	_advance(1)
	assert_eq(_state(), Lodging.State.STAY_COMPLETE, "fin automatique après 2 nuits")
	assert_signal_emitted_with_parameters(EventBus, "stay_completed", [&"hibiscus_1", r.value.id, 120])
	assert_eq(GameState.wallet.balance(&"shells"), 50, "la commission attend d'être encaissée")

	var paid := GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.COLLECT_COMMISSION)
	assert_true(paid.ok)
	assert_eq(paid.value, 120)
	assert_eq(GameState.wallet.balance(&"shells"), 170, "50 + 20 % de 2 × 300")
	assert_eq(_state(), Lodging.State.VACANT)
	assert_eq(GameState.wallet.history[-1].reason, StringName("commission:" + r.value.id))
	assert_eq(GameState.stay_history.size(), 1)
	assert_eq(GameState.stay_history[0].owner_share, 480, "versé à Hina")


func test_double_payment_is_impossible() -> void:
	var booking: Booking = GameState.accept_offer(_first_offer()).value
	_prepare()
	_advance(120)
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.WELCOME_GUESTS)
	_advance(600)
	assert_true(GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.COLLECT_COMMISSION).ok)
	var again := GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.COLLECT_COMMISSION)
	assert_false(again.ok)
	_advance(10_000)
	assert_eq(GameState.wallet.balance(&"shells"), 170, "aucun second versement, même plus tard")
	# Garde-fou : une sauvegarde incohérente qui remettrait le même séjour à payer.
	var lodging := GameState.get_lodging(&"hibiscus_1")
	lodging.booking = booking
	lodging.state = Lodging.State.STAY_COMPLETE
	assert_eq(GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.COLLECT_COMMISSION).error, &"already_paid")
	assert_eq(GameState.wallet.balance(&"shells"), 170)


func test_invalid_reservations() -> void:
	assert_eq(GameState.accept_offer(&"offer_9999").error, &"unknown_offer")
	_advance(60)  # deux offres affichées
	var offer := _first_offer()
	assert_eq(GameState.accept_offer(offer, &"corail_1").error, &"lodging_locked")
	assert_eq(GameState.accept_offer(offer, &"office_1").error, &"unknown_lodging")
	assert_true(GameState.accept_offer(offer, &"hibiscus_1").ok)
	assert_eq(GameState.accept_offer(offer).error, &"unknown_offer", "une offre ne s'accepte qu'une fois")
	var next := _first_offer()
	assert_eq(GameState.accept_offer(next, &"hibiscus_1").error, &"lodging_not_vacant")
	assert_eq(GameState.accept_offer(next).error, &"no_vacant_lodging")
	assert_eq(GameState.wallet.balance(&"shells"), 50)


func test_family_is_never_offered_while_only_small_lodgings_are_open() -> void:
	for i in 12:
		for offer in GameState.bookings.offers:
			assert_ne(offer.template.id, &"family_morel")
		GameState.accept_offer(_first_offer())
		_prepare()
		_advance(120)
		GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.WELCOME_GUESTS)
		_advance(3 * 300)
		GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.COLLECT_COMMISSION)


func test_invalid_lodging_transitions_through_game_state() -> void:
	for action in [Lodging.Action.PREPARE, Lodging.Action.WELCOME_GUESTS, Lodging.Action.COLLECT_COMMISSION]:
		assert_eq(GameState.perform_lodging_action(&"hibiscus_1", action).error, &"invalid_action")
	GameState.accept_offer(_first_offer())
	_prepare()
	assert_eq(GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.WELCOME_GUESTS).error,
			&"invalid_action", "pas d'accueil pendant le ménage")
	assert_eq(GameState.perform_lodging_action(&"nowhere", Lodging.Action.PREPARE).error, &"unknown_lodging")


func test_preparation_requires_and_consumes_one_basket() -> void:
	GameState.accept_offer(_first_offer())
	var r := GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.PREPARE)
	assert_eq(r.error, &"missing_items")
	assert_eq(_state(), Lodging.State.BOOKED, "rien ne change sans panier")
	GameState.add_items({&"welcome_basket": 2})
	assert_true(GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.PREPARE).ok)
	assert_eq(GameState.inventory.count(&"welcome_basket"), 1, "un seul panier consommé")
	for i in 5:  # taps répétés
		assert_false(GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.PREPARE).ok)
	assert_eq(GameState.inventory.count(&"welcome_basket"), 1)


func test_stay_ends_while_the_game_is_closed() -> void:
	GameState.accept_offer(_first_offer())
	_prepare()
	clock.advance(3 * 3600)  # aucune mise à jour pendant 3 h
	GameState.tick()
	assert_eq(_state(), Lodging.State.READY)
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.WELCOME_GUESTS)
	clock.advance(24 * 3600)
	GameState.tick()
	assert_eq(_state(), Lodging.State.STAY_COMPLETE)
	assert_eq(GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.COLLECT_COMMISSION).value, 120)


func test_offers_refill_over_time() -> void:
	assert_eq(GameState.bookings.offers.size(), 1)
	_advance(60)
	assert_eq(GameState.bookings.offers.size(), 2)
	assert_eq(GameState.bookings.offers[1].template.id, &"solo_lea")


func test_no_new_offer_while_no_lodging_can_host() -> void:
	GameState.accept_offer(_first_offer())
	_advance(3600)
	assert_eq(GameState.bookings.offers.size(), 0, "pas de demande impossible à honorer")
