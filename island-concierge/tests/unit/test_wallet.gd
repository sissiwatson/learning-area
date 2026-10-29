extends GutTest

var w: Wallet


func before_each() -> void:
	w = Wallet.new([&"shells", &"pearls"])


func test_starts_at_zero() -> void:
	assert_eq(w.balance(&"shells"), 0)
	assert_eq(w.balance(&"pearls"), 0)


func test_earn_and_spend() -> void:
	assert_true(w.earn(&"shells", 120, &"commission").ok)
	assert_true(w.spend({&"shells": 100}, &"tiki_bar").ok)
	assert_eq(w.balance(&"shells"), 20)


func test_spending_exact_balance_reaches_zero() -> void:
	w.earn(&"shells", 150)
	assert_true(w.spend({&"shells": 150}).ok)
	assert_eq(w.balance(&"shells"), 0)


func test_insufficient_funds_changes_nothing() -> void:
	w.earn(&"shells", 149)
	var r := w.spend({&"shells": 150})
	assert_false(r.ok)
	assert_eq(r.error, &"insufficient_funds")
	assert_eq(w.balance(&"shells"), 149)
	assert_eq(w.history.size(), 1, "aucun mouvement journalisé pour un refus")


func test_multi_currency_spend_is_atomic() -> void:
	w.earn(&"shells", 500)
	w.earn(&"pearls", 2)
	var r := w.spend({&"shells": 300, &"pearls": 3})
	assert_false(r.ok)
	assert_eq(w.balance(&"shells"), 500, "aucune monnaie débitée si l'une manque")
	assert_eq(w.balance(&"pearls"), 2)
	assert_true(w.spend({&"shells": 300, &"pearls": 2}).ok)
	assert_eq(w.balance(&"shells"), 200)
	assert_eq(w.balance(&"pearls"), 0)


func test_invalid_amounts_are_refused() -> void:
	for amount in [0, -5]:
		assert_eq(w.earn(&"shells", amount).error, &"invalid_amount")
		assert_eq(w.spend({&"shells": amount}).error, &"invalid_amount")
	assert_eq(w.spend({&"shells": 1.5}).error, &"invalid_amount", "les montants sont entiers")
	assert_eq(w.spend({}).error, &"invalid_amount")
	assert_eq(w.balance(&"shells"), 0)


func test_unknown_currency_is_refused() -> void:
	assert_eq(w.earn(&"gold", 10).error, &"unknown_currency")
	assert_false(w.can_afford({&"gold": 1}))


func test_balance_is_capped() -> void:
	w.earn(&"shells", Wallet.MAX_BALANCE)
	var r := w.earn(&"shells", 1)
	assert_false(r.ok)
	assert_eq(r.error, &"balance_overflow")
	assert_eq(w.balance(&"shells"), Wallet.MAX_BALANCE)


func test_history_records_each_movement() -> void:
	w.earn(&"shells", 50, &"new_game")
	w.earn(&"shells", 120, &"commission")
	w.spend({&"shells": 150}, &"tiki_bar")
	assert_eq(w.history.map(func(e): return e.delta), [50, 120, -150])
	assert_eq(w.history.map(func(e): return e.balance), [50, 170, 20])
	assert_eq(w.history[2].reason, &"tiki_bar")


func test_history_is_bounded() -> void:
	for i in Wallet.HISTORY_SIZE + 25:
		w.earn(&"shells", 1)
	assert_eq(w.history.size(), Wallet.HISTORY_SIZE)
	assert_eq(w.history[-1].balance, Wallet.HISTORY_SIZE + 25)


func test_round_trip() -> void:
	w.earn(&"shells", 170)
	w.spend({&"shells": 150})
	var copy := Wallet.from_dict(w.to_dict(), [&"shells", &"pearls"])
	assert_eq(copy.balance(&"shells"), 20)
	assert_eq(copy.history.size(), 2)


func test_round_trip_through_json() -> void:
	w.earn(&"shells", 1234)
	var json := JSON.stringify(w.to_dict())
	var copy := Wallet.from_dict(JSON.parse_string(json), [&"shells"])
	assert_eq(copy.balance(&"shells"), 1234)


func test_loading_sanitizes_invalid_data() -> void:
	var copy := Wallet.from_dict({"balances": {"shells": -40, "gold": 99, "pearls": "abc"}}, [&"shells", &"pearls"])
	assert_eq(copy.balance(&"shells"), 0)
	assert_eq(copy.balance(&"pearls"), 0)
	assert_false(copy.has_currency(&"gold"))


func test_new_currency_can_be_added_without_code_change() -> void:
	var extended := Wallet.from_dict(w.to_dict(), [&"shells", &"pearls", &"stars"])
	assert_true(extended.earn(&"stars", 3).ok)
