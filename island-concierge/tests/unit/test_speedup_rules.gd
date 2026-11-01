## Barème des accélérations : 15 % de la commission pour un séjour entier,
## arrondi à l'entier supérieur, prix cumulatif (calcul pur).
extends GutTest

const NIGHT := 300
const PERCENT := 15
const T := SpeedupRules.Tier


func _price(commission: int, removed_before: int, reduction: int, total: int) -> int:
	return SpeedupRules.step_price(commission, PERCENT, removed_before, reduction, total)


func test_reduction_never_exceeds_the_remaining_time() -> void:
	assert_eq(SpeedupRules.stay_reduction(T.ONE_NIGHT, 600, NIGHT), 300)
	assert_eq(SpeedupRules.stay_reduction(T.ONE_NIGHT, 120, NIGHT), 120, "moins d'une nuit restante")
	assert_eq(SpeedupRules.stay_reduction(T.FINISH, 437, NIGHT), 437)
	assert_eq(SpeedupRules.stay_reduction(T.FINISH, 0, NIGHT), 0)
	assert_eq(SpeedupRules.stay_reduction(T.ONE_NIGHT, -5, NIGHT), 0)


## Tableau du plan 0.1.6 (taux 15 %).
func test_prices_of_the_three_offered_stays() -> void:
	# Léa : 1 nuit, commission 50 -> 7,5 arrondi à 8.
	assert_eq(_price(50, 0, 300, 300), 8, "Léa : une nuit = tout le séjour")
	# Camille et Noé : 2 nuits, commission 120.
	assert_eq(_price(120, 0, 300, 600), 9, "Camille : une nuit")
	assert_eq(_price(120, 0, 600, 600), 18, "Camille : terminer d'un coup")
	assert_eq(_price(120, 300, 300, 600), 9, "Camille : terminer après une nuit")
	# Amaru : 3 nuits, commission 168 -> 25,2 arrondi à 26.
	assert_eq(_price(168, 0, 300, 900), 9, "Amaru : une nuit (8,4 arrondi)")
	assert_eq(_price(168, 0, 900, 900), 26, "Amaru : terminer d'un coup")


func test_rounding_is_always_up() -> void:
	assert_eq(SpeedupRules.cumulative_price(50, 15, 300, 300), 8, "7,5 -> 8")
	assert_eq(SpeedupRules.cumulative_price(168, 15, 900, 900), 26, "25,2 -> 26")
	assert_eq(SpeedupRules.cumulative_price(120, 15, 600, 600), 18, "valeur exacte inchangée")
	assert_eq(SpeedupRules.cumulative_price(1, 15, 1, 900), 1, "une fraction de coquillage coûte 1")


## Plusieurs accélérations partielles ne coûtent jamais plus qu'une complète.
func test_chained_steps_cost_exactly_the_full_speedup() -> void:
	var first := _price(168, 0, 300, 900)
	var second := _price(168, 300, 300, 900)
	var third := _price(168, 600, 300, 900)
	assert_eq([first, second, third], [9, 8, 9])
	assert_eq(first + second + third, _price(168, 0, 900, 900), "même prix qu'en une fois")
	assert_eq(_price(120, 0, 300, 600) + _price(120, 300, 300, 600), 18)


func test_cumulative_property_holds_for_many_stays() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	for i in 500:
		var commission := rng.randi_range(1, 5000)
		var nights := rng.randi_range(1, 7)
		var total := nights * NIGHT
		var removed := 0
		var paid := 0
		while removed < total:
			var reduction := mini(rng.randi_range(1, total), total - removed)
			paid += _price(commission, removed, reduction, total)
			removed += reduction
		var full := SpeedupRules.cumulative_price(commission, PERCENT, total, total)
		assert_eq(paid, full, "commission %d, %d nuits" % [commission, nights])
		assert_lte(full * 100, commission * PERCENT + 99, "jamais plus de 15 % arrondi à l'entier supérieur")


func test_nothing_to_pay_without_commission_or_reduction() -> void:
	assert_eq(SpeedupRules.cumulative_price(0, 15, 300, 600), 0)
	assert_eq(SpeedupRules.cumulative_price(120, 0, 300, 600), 0)
	assert_eq(_price(120, 0, 0, 600), 0)
	assert_eq(SpeedupRules.cumulative_price(120, 15, 300, 0), 0)


func test_ledger_categories_use_the_longest_prefix() -> void:
	var prefixes := {"comfort:": &"comfort", "charge:": &"operating_charge", "commission:": &"revenue", "new_game": &"opening"}
	assert_eq(Ledger.category_of("comfort:speedup:bk_0003", prefixes), &"comfort")
	assert_eq(Ledger.category_of("charge:cleaning_help:hibiscus_1", prefixes), &"operating_charge")
	assert_eq(Ledger.category_of("commission:bk_0003", prefixes), &"revenue")
	assert_eq(Ledger.category_of("new_game", prefixes), &"opening")
	assert_eq(Ledger.category_of("mystery", prefixes), Ledger.UNCATEGORIZED)
	prefixes["comfort:refund:"] = &"comfort_refund"
	assert_eq(Ledger.category_of("comfort:refund:bk_1", prefixes), &"comfort_refund", "le plus long gagne")
