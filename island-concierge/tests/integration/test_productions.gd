## Productions de Mahana via GameState, avec horloge simulée.
extends GutTest

const FakeClock := preload("res://tests/helpers/fake_clock.gd")

var clock: FakeClock


func before_each() -> void:
	clock = FakeClock.new()
	GameState.clock = clock
	GameState.new_game(load("res://data/maps/mahana.tres"))


func after_each() -> void:
	GameState.clock = Clock.new()


func _advance(seconds: int) -> void:
	clock.advance(seconds)
	GameState.tick()


func _count(id: StringName) -> int:
	return GameState.inventory.count(id)


func test_harvest_takes_30_seconds_and_gives_3_pineapples() -> void:
	watch_signals(EventBus)
	assert_true(GameState.start_production(&"farm_1", &"harvest_pineapple").ok)
	_advance(29)
	assert_eq(_count(&"pineapple"), 0)
	_advance(1)
	assert_eq(_count(&"pineapple"), 3, "inventaire mis à jour automatiquement")
	assert_signal_emitted_with_parameters(EventBus, "item_collected", [&"pineapple", 3])
	assert_signal_emitted_with_parameters(EventBus, "production_completed", [&"farm_1", &"harvest_pineapple"])
	_advance(3600)
	assert_eq(_count(&"pineapple"), 3, "pas de répétition automatique")


func test_basket_requires_three_pineapples() -> void:
	var r := GameState.start_production(&"workshop_1", &"craft_welcome_basket")
	assert_eq(r.error, &"missing_items")
	GameState.add_items({&"pineapple": 2})
	assert_eq(GameState.start_production(&"workshop_1", &"craft_welcome_basket").error, &"missing_items")
	assert_eq(_count(&"pineapple"), 2, "rien n'est consommé en cas de refus")
	GameState.add_items({&"pineapple": 1})
	assert_true(GameState.start_production(&"workshop_1", &"craft_welcome_basket").ok)
	assert_eq(_count(&"pineapple"), 0, "entrées consommées au lancement")
	_advance(59)
	assert_eq(_count(&"welcome_basket"), 0)
	_advance(1)
	assert_eq(_count(&"welcome_basket"), 1, "panier prêt après 1 min")


func test_repeated_taps_consume_once() -> void:
	GameState.add_items({&"pineapple": 9})
	var successes := 0
	for i in 5:
		if GameState.start_production(&"workshop_1", &"craft_welcome_basket").ok:
			successes += 1
	assert_eq(successes, 1)
	assert_eq(_count(&"pineapple"), 6)
	assert_eq(GameState.start_production(&"workshop_1", &"craft_welcome_basket").error, &"producer_busy")
	for i in 5:
		GameState.start_production(&"farm_1", &"harvest_pineapple")
	_advance(60)
	assert_eq(_count(&"pineapple"), 9, "une seule récolte malgré 5 taps")
	assert_eq(_count(&"welcome_basket"), 1)


func test_wrong_recipe_or_building() -> void:
	assert_eq(GameState.start_production(&"farm_1", &"craft_welcome_basket").error, &"unknown_recipe")
	assert_eq(GameState.start_production(&"hibiscus_1", &"harvest_pineapple").error, &"unknown_building")
	assert_eq(GameState.start_production(&"nowhere", &"harvest_pineapple").error, &"unknown_building")


func test_full_inventory_keeps_the_harvest_waiting() -> void:
	GameState.add_items({&"pineapple": 48})  # capacité 50
	watch_signals(EventBus)
	GameState.start_production(&"farm_1", &"harvest_pineapple")
	_advance(30)
	assert_eq(_count(&"pineapple"), 48, "3 ananas ne tiennent pas dans 2 places")
	assert_true(GameState.blocked_producers.has(&"farm_1"))
	assert_signal_emitted_with_parameters(EventBus, "production_blocked_changed", [&"farm_1", true])
	assert_eq(GameState.start_production(&"farm_1", &"harvest_pineapple").error, &"producer_busy",
			"la récolte en attente n'est pas perdue ni remplacée")
	GameState.remove_items({&"pineapple": 1})
	_advance(1)
	assert_eq(_count(&"pineapple"), 50, "livrée dès qu'il y a de la place")
	assert_false(GameState.blocked_producers.has(&"farm_1"))


func test_exact_fit_is_delivered() -> void:
	GameState.add_items({&"pineapple": 47})
	GameState.start_production(&"farm_1", &"harvest_pineapple")
	_advance(30)
	assert_eq(_count(&"pineapple"), 50)
	assert_eq(GameState.inventory.free_space(), 0)


func test_crafting_frees_space_so_a_full_inventory_never_softlocks() -> void:
	GameState.add_items({&"pineapple": 50})
	assert_true(GameState.start_production(&"workshop_1", &"craft_welcome_basket").ok, "consomme 3 places")
	_advance(60)
	assert_eq(GameState.inventory.total(), 48)


func test_production_completes_once_while_the_game_is_closed() -> void:
	GameState.start_production(&"farm_1", &"harvest_pineapple")
	clock.advance(5 * 3600)
	GameState.tick()
	GameState.tick()
	assert_eq(_count(&"pineapple"), 3)


func test_productions_continue_during_a_stay() -> void:
	GameState.accept_offer(GameState.bookings.offers[0].id)
	GameState.add_items({&"welcome_basket": 1})
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.PREPARE)
	_advance(120)
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.WELCOME_GUESTS)
	assert_eq(GameState.get_lodging(&"hibiscus_1").state, Lodging.State.OCCUPIED)
	assert_true(GameState.start_production(&"farm_1", &"harvest_pineapple").ok)
	_advance(30)
	assert_true(GameState.start_production(&"workshop_1", &"craft_welcome_basket").ok)
	_advance(60)
	assert_eq(_count(&"welcome_basket"), 1, "panier du prochain séjour prêt pendant le séjour en cours")
	assert_eq(GameState.get_lodging(&"hibiscus_1").state, Lodging.State.OCCUPIED)
	_advance(600)
	assert_eq(GameState.get_lodging(&"hibiscus_1").state, Lodging.State.STAY_COMPLETE)
