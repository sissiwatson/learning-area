## Tutoriel V0.1 joué uniquement par des commandes de jeu (sans interface).
extends GutTest

const FakeClock := preload("res://tests/helpers/fake_clock.gd")

var clock: FakeClock
var map: MapDef


func before_each() -> void:
	clock = FakeClock.new()
	GameState.clock = clock
	map = load("res://data/maps/mahana.tres")
	GameState.new_game(map)
	EventBus.quest_available.connect(_auto_start)
	for q in GameState.quest_log.with_status(QuestLog.Status.AVAILABLE):
		GameState.start_quest(q.id)


func after_each() -> void:
	EventBus.quest_available.disconnect(_auto_start)
	GameState.clock = Clock.new()


## Comme le metteur en scène quand le dialogue d'introduction est lu (ou passé).
func _auto_start(id: StringName) -> void:
	GameState.start_quest(id)


func _advance(seconds: int) -> void:
	clock.advance(seconds)
	GameState.tick()


func _active() -> StringName:
	var active := GameState.quest_log.with_status(QuestLog.Status.ACTIVE)
	return active[0].id if not active.is_empty() else &""


func test_whole_tutorial_chain() -> void:
	watch_signals(EventBus)
	assert_eq(_active(), &"tutorial_01")
	EventBus.game_event.emit(&"camera_panned", &"", 1)
	assert_eq(_active(), &"tutorial_01", "il faut aussi zoomer")
	EventBus.game_event.emit(&"camera_zoomed", &"", 1)
	assert_eq(_active(), &"tutorial_02")
	GameState.accept_offer(GameState.bookings.offers[0].id)
	assert_eq(_active(), &"tutorial_03")
	GameState.start_production(&"farm_1", &"harvest_pineapple")
	_advance(30)
	assert_eq(_active(), &"tutorial_04")
	GameState.start_production(&"workshop_1", &"craft_welcome_basket")
	_advance(60)
	assert_eq(_active(), &"tutorial_06")
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.PREPARE)
	assert_eq(_active(), &"tutorial_07")
	_advance(120)
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.WELCOME_GUESTS)
	assert_eq(_active(), &"tutorial_09")
	_advance(600)
	assert_eq(_active(), &"tutorial_09", "il faut encore encaisser")
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.COLLECT_COMMISSION)
	assert_eq(_active(), &"tutorial_10", "tiki bar (étape 11)")
	assert_signal_emit_count(EventBus, "quest_completed", 7)
	assert_eq(GameState.wallet.balance(&"shells"), 170)
	assert_eq(GameState.level(), 2)


func test_quest_progress_survives_a_restore() -> void:
	EventBus.game_event.emit(&"camera_panned", &"", 1)
	EventBus.game_event.emit(&"camera_zoomed", &"", 1)
	GameState.accept_offer(GameState.bookings.offers[0].id)
	GameState.start_production(&"farm_1", &"harvest_pineapple")
	var data := JSON.parse_string(JSON.stringify(GameState.to_save_dict()))
	GameState.new_game(map)
	GameState.load_save_dict(data, map)
	assert_eq(_active(), &"tutorial_03")
	_advance(30)
	assert_eq(_active(), &"tutorial_04", "la récolte en cours au moment de la sauvegarde compte")
	assert_eq(GameState.quest_log.get_status(&"tutorial_01"), QuestLog.Status.COMPLETED)


func test_rewards_granted_once_even_if_events_repeat() -> void:
	var q: QuestDef = GameState.quest_log.get_quest(&"tutorial_02")
	q.reward_currencies = {&"shells": 10}
	EventBus.game_event.emit(&"camera_panned", &"", 1)
	EventBus.game_event.emit(&"camera_zoomed", &"", 1)
	GameState.accept_offer(GameState.bookings.offers[0].id)
	assert_eq(GameState.wallet.balance(&"shells"), 60)
	for i in 3:
		EventBus.game_event.emit(&"booking_accepted", &"", 1)
	var data := JSON.parse_string(JSON.stringify(GameState.to_save_dict()))
	GameState.load_save_dict(data, map)
	EventBus.game_event.emit(&"booking_accepted", &"", 1)
	assert_eq(GameState.wallet.balance(&"shells"), 60, "récompense unique")
	q.reward_currencies = {}
