## Construction du tiki bar : niveau, coût, minuteur, fin du tutoriel.
extends GutTest

const FakeClock := preload("res://tests/helpers/fake_clock.gd")

var clock: FakeClock
var main: Node


func before_each() -> void:
	clock = FakeClock.new()
	GameState.clock = clock
	main = load("res://scenes/main.tscn").instantiate()
	add_child_autofree(main)
	await get_tree().process_frame
	await _skip_dialogues()


func after_each() -> void:
	GameState.clock = Clock.new()


## Passe les dialogues (le metteur en scène les lance à la frame suivante).
func _skip_dialogues() -> void:
	for i in 3:
		await get_tree().process_frame
		while main.dialogue_box.visible:
			main.dialogue_box.skip()


func _advance(seconds: int) -> void:
	clock.advance(seconds)
	GameState.tick()


## Boucle complète du tutoriel V0.1 jusqu'à la commission (170 coquillages, niveau 2).
func _tutorial_until_commission() -> void:
	EventBus.game_event.emit(&"camera_panned", &"", 1)
	EventBus.game_event.emit(&"camera_zoomed", &"", 1)
	await _skip_dialogues()
	GameState.accept_offer(GameState.bookings.offers[0].id)
	await _skip_dialogues()
	GameState.start_production(&"farm_1", &"harvest_pineapple")
	_advance(30)
	await _skip_dialogues()
	GameState.start_production(&"workshop_1", &"craft_welcome_basket")
	_advance(60)
	await _skip_dialogues()
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.PREPARE)
	await _skip_dialogues()
	_advance(120)
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.WELCOME_GUESTS)
	await _skip_dialogues()
	_advance(600)
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.COLLECT_COMMISSION)
	await _skip_dialogues()


func test_level_is_required() -> void:
	GameState.earn(&"shells", 500)
	var r := GameState.start_construction(&"tiki_site_1")
	assert_eq(r.error, &"level_too_low")
	assert_eq(GameState.wallet.balance(&"shells"), 550, "rien dépensé")


func test_funds_are_required() -> void:
	GameState.gain_xp(50)
	GameState.spend({&"shells": 1})
	assert_eq(GameState.start_construction(&"tiki_site_1").error, &"insufficient_funds")
	assert_eq(GameState.wallet.balance(&"shells"), 49)
	assert_eq(GameState.constructions[&"tiki_site_1"].state, ConstructionSite.State.IDLE)


func test_tutorial_economy_and_ending() -> void:
	await _tutorial_until_commission()
	assert_eq(GameState.wallet.balance(&"shells"), 170)
	assert_eq(GameState.level(), 2)
	assert_true(main.map.buildings[&"tiki_site_1"].attention, "pastille : construction possible")
	assert_true(GameState.start_construction(&"tiki_site_1").ok)
	assert_eq(GameState.wallet.balance(&"shells"), 20, "50 → 170 → 20")
	for i in 5:
		assert_eq(GameState.start_construction(&"tiki_site_1").error, &"already_started")
	assert_eq(GameState.wallet.balance(&"shells"), 20, "taps répétés : un seul paiement")
	assert_eq(GameState.quest_log.get_status(&"tutorial_10"), QuestLog.Status.COMPLETED, "fin du tutoriel")
	assert_eq(GameState.quest_log.with_status(QuestLog.Status.COMPLETED).size(), 8)


func test_construction_takes_five_minutes_then_becomes_a_tiki_bar() -> void:
	GameState.gain_xp(50)
	GameState.earn(&"shells", 100)
	watch_signals(EventBus)
	GameState.start_construction(&"tiki_site_1")
	var view: BuildingView = main.map.buildings[&"tiki_site_1"]
	assert_true(view.ring.visible)
	_advance(299)
	assert_eq(GameState.building_def_of(&"tiki_site_1").id, &"tiki_bar_site")
	_advance(1)
	assert_signal_emitted_with_parameters(EventBus, "building_built", [&"tiki_site_1", &"tiki_bar"])
	assert_eq(GameState.building_def_of(&"tiki_site_1").id, &"tiki_bar")
	assert_eq(view.sprite.texture, GameState.building_def_of(&"tiki_site_1").texture, "le chantier devient le tiki bar")
	assert_false(view.ring.visible)
	assert_eq(GameState.progression.xp, 70, "50 + 20 XP de construction")
	assert_has(main.toasts.messages(), "Construction terminée : Tiki bar")


func test_panel_states() -> void:
	main.select_building(main.map.buildings[&"tiki_site_1"])
	var panel: BuildingPanel = main.panel
	var build: Button = panel.actions.get_node("Build")
	assert_true(build.disabled)
	assert_eq(build.text, "Niveau 2 requis")
	GameState.gain_xp(50)
	build = panel.actions.get_node("Build")
	assert_eq(build.text, "Il manque 100 coquillages")
	GameState.earn(&"shells", 100)
	build = panel.actions.get_node("Build")
	assert_false(build.disabled)
	assert_eq(build.text, "Construire (150 coquillages)")
	build.pressed.emit()
	_advance(60)
	panel._on_second()
	assert_eq(panel.progress_label.text, "Construction : encore 4 min")
	_advance(240)
	assert_eq(panel.title.text, "Tiki bar")
	assert_string_starts_with(panel.info.text, "Le tiki bar est ouvert !")


func test_construction_is_saved_and_finishes_while_closed() -> void:
	GameState.gain_xp(50)
	GameState.earn(&"shells", 100)
	GameState.start_construction(&"tiki_site_1")
	_advance(100)
	var data := JSON.parse_string(JSON.stringify(GameState.to_save_dict()))
	clock.advance(3600)
	GameState.new_game(main.map.map_def)
	GameState.load_save_dict(data, main.map.map_def)
	assert_eq(GameState.building_def_of(&"tiki_site_1").id, &"tiki_bar")
	assert_eq(GameState.wallet.balance(&"shells"), 0, "150 dépensés une seule fois")
	main.map.refresh_production_visuals()
	assert_eq(main.map.buildings[&"tiki_site_1"].sprite.texture.resource_path, "res://assets/buildings/tiki_bar.png")
	assert_eq(GameState.start_construction(&"tiki_site_1").error, &"already_started", "pas de seconde construction")
