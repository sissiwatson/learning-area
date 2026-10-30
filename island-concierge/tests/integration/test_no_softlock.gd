## Anti-blocage économique : après les dépenses obligatoires du tutoriel (ou
## même sans aucun coquillage), une suite d'actions gratuites permet toujours
## de regagner des ressources et de progresser.
extends GutTest

const FakeClock := preload("res://tests/helpers/fake_clock.gd")

var clock: FakeClock


func before_each() -> void:
	clock = FakeClock.new()
	GameState.clock = clock
	GameState.new_game(load("res://data/maps/mahana.tres"))


func after_each() -> void:
	GameState.clock = Clock.new()


## Joue une réservation complète avec uniquement des actions gratuites.
func _free_booking_cycle() -> int:
	var before := GameState.wallet.balance(&"shells")
	assert_gt(GameState.bookings.offers.size(), 0, "une offre est toujours disponible")
	assert_true(GameState.accept_offer(GameState.bookings.offers[0].id).ok)
	assert_true(GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.PREPARE).ok)
	clock.advance(GameState.timings.cleaning_seconds)
	GameState.tick()
	assert_true(GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.WELCOME_GUESTS).ok)
	clock.advance(30 * GameState.timings.night_seconds)
	GameState.tick()
	assert_true(GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.COLLECT_COMMISSION).ok)
	assert_eq(GameState.wallet.balance(&"shells") - before, GameState.wallet.history[-1].delta)
	return GameState.wallet.balance(&"shells") - before


func test_after_tutorial_mandatory_spending() -> void:
	assert_eq(_free_booking_cycle(), 120, "première commission du tutoriel")
	assert_eq(GameState.wallet.balance(&"shells"), 170)
	assert_true(GameState.spend({&"shells": 150}, &"tiki_bar").ok, "construction du tiki bar")
	assert_eq(GameState.wallet.balance(&"shells"), 20)
	var gained := _free_booking_cycle()
	assert_gt(gained, 0, "le joueur regagne des coquillages sans rien payer")
	assert_eq(GameState.wallet.balance(&"shells"), 20 + gained)


func test_even_with_zero_shells_and_empty_inventory() -> void:
	GameState.spend({&"shells": 50})
	assert_eq(GameState.wallet.balance(&"shells"), 0)
	assert_eq(GameState.inventory.total(), 0)
	assert_gt(_free_booking_cycle(), 0)


func test_many_cycles_always_possible() -> void:
	GameState.spend({&"shells": 50})
	var total := 0
	for i in 8:
		total += _free_booking_cycle()
	assert_eq(total, 120 + 50 + 168 + 120 + 50 + 168 + 120 + 50, "rotation déterministe des offres")


func test_booking_loop_never_requires_currency() -> void:
	for placement in GameState.map.placements:
		var lodging: LodgingDef = placement.building.lodging
		if lodging:
			for item in lodging.prepare_items:
				assert_false(GameState.currency_defs.has(item), "la préparation ne coûte pas de monnaie")
	assert_eq(Database.errors, PackedStringArray(), "règle de production gratuite vérifiée par DataValidator")
