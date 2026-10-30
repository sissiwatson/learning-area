## L'expérience récompense le travail de concierge (données de Mahana).
extends GutTest

const FakeClock := preload("res://tests/helpers/fake_clock.gd")

var clock: FakeClock
var main: Node


func before_each() -> void:
	clock = FakeClock.new()
	GameState.clock = clock
	main = load("res://scenes/main.tscn").instantiate()
	add_child_autofree(main)


func after_each() -> void:
	GameState.clock = Clock.new()


func _advance(seconds: int) -> void:
	clock.advance(seconds)
	GameState.tick()


## Boucle du tutoriel V0.1 : réservation, récolte, panier, ménage, accueil, encaissement.
func _tutorial_loop() -> Array:
	var steps := []
	GameState.accept_offer(GameState.bookings.offers[0].id)
	steps.append(GameState.progression.xp)
	GameState.start_production(&"farm_1", &"harvest_pineapple")
	_advance(30)
	steps.append(GameState.progression.xp)
	GameState.start_production(&"workshop_1", &"craft_welcome_basket")
	_advance(60)
	steps.append(GameState.progression.xp)
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.PREPARE)
	steps.append(GameState.progression.xp)
	_advance(120)
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.WELCOME_GUESTS)
	steps.append(GameState.progression.xp)
	_advance(600)
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.COLLECT_COMMISSION)
	steps.append(GameState.progression.xp)
	return steps


func test_tutorial_loop_xp_matches_the_scenario() -> void:
	assert_eq(_tutorial_loop(), [5, 10, 20, 25, 30, 55], "SCENARIO_TUTORIEL.md, V0.1 : 55 XP")
	assert_eq(GameState.level(), 2, "niveau 2 requis pour le tiki bar")


func test_level_up_signal_hud_and_toast() -> void:
	watch_signals(EventBus)
	assert_eq(main.resource_bar.level_label.text, "Niv. 1")
	_tutorial_loop()
	assert_signal_emit_count(EventBus, "level_up", 1)
	assert_signal_emitted_with_parameters(EventBus, "level_up", [2])
	assert_eq(main.resource_bar.level_label.text, "Niv. 2")
	assert_eq(main.resource_bar.xp_bar.value, 5.0, "55 - 50 XP dans le niveau 2")
	assert_has(main.toasts.messages(), "Niveau 2 atteint !")


func test_failed_actions_give_no_xp() -> void:
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.WELCOME_GUESTS)
	GameState.start_production(&"workshop_1", &"craft_welcome_basket")
	GameState.accept_offer(&"offer_9999")
	assert_eq(GameState.progression.xp, 0)


func test_xp_is_saved() -> void:
	_tutorial_loop()
	var data := JSON.parse_string(JSON.stringify(GameState.to_save_dict()))
	GameState.new_game(main.map.map_def)
	assert_eq(GameState.progression.xp, 0)
	GameState.load_save_dict(data, main.map.map_def)
	assert_eq(GameState.progression.xp, 55)
	assert_eq(main.resource_bar.level_label.text, "Niv. 2")
