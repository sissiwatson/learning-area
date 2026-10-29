## Économie branchée sur GameState, EventBus et le HUD.
extends GutTest

var main: Node


func before_each() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child_autofree(main)


func test_new_game_data() -> void:
	var setup: NewGameDef = load("res://data/balance/new_game.tres")
	assert_eq(setup.starting_balances, {&"shells": 50})
	assert_eq(setup.currencies.size(), 1, "V0.1 : coquillages uniquement")
	var item_ids := setup.items.map(func(d): return d.id)
	assert_has(item_ids, &"pineapple")
	assert_has(item_ids, &"welcome_basket")
	for def in setup.currencies + setup.items:
		assert_not_null(def.icon, "icône manquante : %s" % def.id)
		assert_ne(TranslationServer.translate(def.name_key), StringName(def.name_key))


func test_new_game_starts_with_50_shells_and_empty_inventory() -> void:
	assert_eq(GameState.wallet.balance(&"shells"), 50)
	assert_eq(GameState.inventory.total(), 0)
	assert_eq(GameState.inventory.capacity, 50)


func test_hud_shows_balance_and_items() -> void:
	var bar: ResourceBar = main.resource_bar
	assert_eq(bar.amount_labels[&"shells"].text, "50")
	assert_eq(bar.amount_labels[&"pineapple"].text, "0")
	assert_eq(bar.amount_labels[&"welcome_basket"].text, "0")


func test_hud_follows_game_state_commands() -> void:
	var bar: ResourceBar = main.resource_bar
	GameState.earn(&"shells", 1200, &"test")
	assert_eq(bar.amount_labels[&"shells"].text, "1 250")
	GameState.add_items({&"pineapple": 3})
	assert_eq(bar.amount_labels[&"pineapple"].text, "3")
	GameState.remove_items({&"pineapple": 3})
	assert_eq(bar.amount_labels[&"pineapple"].text, "0")


func test_failed_command_reports_error_and_keeps_display() -> void:
	watch_signals(EventBus)
	var r := GameState.spend({&"shells": 51})
	assert_false(r.ok)
	assert_signal_emitted_with_parameters(EventBus, "action_failed", [&"insufficient_funds", {}])
	assert_eq(main.resource_bar.amount_labels[&"shells"].text, "50")


func test_every_error_code_is_translated() -> void:
	for code in [&"insufficient_funds", &"balance_overflow", &"unknown_currency", &"invalid_amount",
			&"inventory_full", &"missing_items", &"unknown_item", &"invalid_action", &"unknown_lodging"]:
		var key := "ERR_" + String(code).to_upper()
		assert_ne(TranslationServer.translate(key), StringName(key), "traduction manquante : %s" % key)


func test_resource_bar_blocks_map_touches() -> void:
	var bar: ResourceBar = main.resource_bar
	assert_true(main.hud.is_point_over_ui(bar.get_global_rect().get_center()))


func test_new_game_resets_economy() -> void:
	GameState.earn(&"shells", 500)
	GameState.add_items({&"pineapple": 2})
	GameState.new_game(main.map.map_def)
	assert_eq(GameState.wallet.balance(&"shells"), 50)
	assert_eq(GameState.inventory.total(), 0)
	assert_eq(main.resource_bar.amount_labels[&"shells"].text, "50")
