## Recette de stabilité : un joueur aléatoire (graine fixe, donc rejouable)
## enchaîne des milliers d'actions — valides ou non — avec des sauts
## d'horloge en avant et en arrière et des sauvegardes / restaurations.
## Après chaque action, les invariants de la partie doivent tenir.
extends GutTest

const FakeClock := preload("res://tests/helpers/fake_clock.gd")
const STEPS := 1500
const ACTIONS := [Lodging.Action.PREPARE, Lodging.Action.WELCOME_GUESTS, Lodging.Action.COLLECT_COMMISSION]
const WAITS := [1, 5, 30, 60, 120, 300, 900, 3600, 6 * 3600]

var clock: FakeClock
var map: MapDef
var rng := RandomNumberGenerator.new()
var stats := {}
var _last_now := 0
var _last_xp := 0


func before_each() -> void:
	clock = FakeClock.new()
	GameState.clock = clock
	map = load("res://data/maps/mahana.tres")
	GameState.new_game(map)
	stats = {"collected": 0, "built": 0, "reloads": 0, "refused": 0, "quests_completed": 0, "speedups": 0}
	_last_now = GameState.now()
	_last_xp = 0


func after_each() -> void:
	GameState.clock = Clock.new()


func _pick(values: Array) -> Variant:
	return values[rng.randi_range(0, values.size() - 1)]


## Une action au hasard ; les refus sont normaux et comptés.
func _random_step() -> void:
	var roll := rng.randf()
	var result: Result = null
	if roll < 0.15 and not GameState.bookings.offers.is_empty():
		var lodging_uid: StringName = _pick([&"", &"hibiscus_1", &"corail_1"])
		result = GameState.accept_offer(_pick(GameState.bookings.offers).id, lodging_uid)
	elif roll < 0.40:
		var uid: StringName = _pick(GameState.producers.keys())
		var recipes := GameState.recipes_of(uid)
		if not recipes.is_empty():
			result = GameState.start_production(uid, _pick(recipes).id)
	elif roll < 0.65:
		var uid: StringName = _pick(GameState.lodgings.keys())
		result = GameState.perform_lodging_action(uid, _pick(ACTIONS))
		if result.ok and GameState.get_lodging(uid).state == Lodging.State.VACANT:
			stats.collected += 1
	elif roll < 0.68:
		result = GameState.start_construction(_pick(GameState.constructions.keys()))
		if result.ok:
			stats.built += 1
	elif roll < 0.72:
		var available := GameState.quest_log.with_status(QuestLog.Status.AVAILABLE)
		if not available.is_empty():
			result = GameState.start_quest(_pick(available).id)
	elif roll < 0.78:
		# Accélération : parfois avec une fin affichée périmée (double toucher).
		var occupied := GameState.lodgings.keys().filter(func(id): return GameState.lodgings[id].state == Lodging.State.OCCUPIED)
		var uid: StringName = _pick(occupied if not occupied.is_empty() and rng.randf() < 0.8 else GameState.lodgings.keys())
		var lodging: Lodging = GameState.lodgings[uid]
		var shown_end := lodging.timer_end if rng.randf() < 0.8 else lodging.timer_end + 7
		result = GameState.speed_up_stay(uid, _pick([SpeedupRules.Tier.ONE_NIGHT, SpeedupRules.Tier.FINISH]), shown_end)
		if result.ok:
			stats.speedups += 1
	elif roll < 0.93:
		clock.advance(_pick(WAITS))
		GameState.tick()
	elif roll < 0.95:
		clock.advance(-rng.randi_range(1, 7200))  # horloge système reculée
		GameState.tick()
	else:
		_save_and_reload()
	if result and not result.ok:
		stats.refused += 1


## Passage par JSON comme le vrai fichier ; l'état doit être identique.
func _save_and_reload() -> void:
	GameState.tick()  # comme le jeu, qui avance en continu : livraisons en attente faites
	var before := JSON.stringify(GameState.to_save_dict())
	GameState.new_game(map)
	assert_true(GameState.load_save_dict(JSON.parse_string(before), map).ok, "restauration acceptée")
	var after := JSON.stringify(GameState.to_save_dict())
	if after != before:
		assert_eq(after, before, "aller-retour de sauvegarde identique")
	stats.reloads += 1


var _broken: Array[String] = []


func _expect(condition: bool, label: String) -> void:
	if not condition and not _broken.has(label):
		_broken.append(label)


## Liste des invariants rompus (vide si tout va bien).
func _violations() -> Array[String]:
	_broken = []
	# Temps de jeu monotone.
	var now := GameState.now()
	_expect(now >= _last_now, "now >= _last_now")
	_last_now = now
	# Monnaie : jamais négative, journal cohérent maillon par maillon.
	for id in GameState.currency_defs:
		_expect(GameState.wallet.balance(id) >= 0, "GameState.wallet.balance(id) >= 0")
	var history := GameState.wallet.history
	for i in range(1, history.size()):
		if history[i].currency == history[i - 1].currency:
			_expect(history[i].balance == history[i - 1].balance + history[i].delta, "history[i].balance == history[i - 1].balance + history[i].delta")
	var last_by_currency := {}
	for entry in history:
		last_by_currency[entry.currency] = entry.balance
	for id in last_by_currency:
		_expect(last_by_currency[id] == GameState.wallet.balance(id), "last_by_currency[id] == GameState.wallet.balance(id)")
	# Inventaire : quantités positives, capacité respectée.
	_expect(GameState.inventory.total() <= GameState.inventory.capacity, "GameState.inventory.total() <= GameState.inventory.capacity")
	for id in GameState.item_defs:
		_expect(GameState.inventory.count(id) >= 0, "GameState.inventory.count(id) >= 0")
	# Logements : verrouillé => libre ; occupé => une réservation.
	for uid in GameState.lodgings:
		var lodging: Lodging = GameState.lodgings[uid]
		if lodging.locked:
			_expect(lodging.state == Lodging.State.VACANT, "lodging.state == Lodging.State.VACANT")
		if lodging.state != Lodging.State.VACANT:
			_expect(lodging.booking != null, "lodging.booking != null")
			_expect(lodging.booking.guests <= lodging.capacity, "lodging.booking.guests <= lodging.capacity")
	# Aucune commission encaissée deux fois.
	var paid := {}
	for entry in GameState.stay_history:
		var id: String = str(entry.booking.id)
		_expect(not paid.has(id), "not paid.has(id)")
		paid[id] = true
		_expect(GameState.paid_bookings.has(StringName(id)), "GameState.paid_bookings.has(StringName(id))")
	var commission_reasons := {}
	for entry in history:
		var reason := str(entry.reason)
		if reason.begins_with("commission:"):
			_expect(not commission_reasons.has(reason), "not commission_reasons.has(reason)")
			commission_reasons[reason] = true
	# Offres bornées, XP croissante, quêtes récompensées = quêtes terminées.
	_expect(GameState.bookings.offers.size() <= GameState.bookings.max_offers, "GameState.bookings.offers.size() <= GameState.bookings.max_offers")
	_expect(GameState.progression.xp >= _last_xp, "GameState.progression.xp >= _last_xp")
	_last_xp = GameState.progression.xp
	for id in GameState.quest_log.rewarded:
		_expect(GameState.quest_log.get_status(id) == QuestLog.Status.COMPLETED, "GameState.quest_log.get_status(id) == QuestLog.Status.COMPLETED")
	# Producteurs : jamais plus de créneaux que la définition.
	for uid in GameState.producers:
		var def := GameState.get_placement(uid).building.producer
		_expect(GameState.producers[uid].slots.size() <= def.slots, "GameState.producers[uid].slots.size() <= def.slots")
	# Accélérations : réservation inchangée, jamais plus que 15 % arrondi.
	var percent := GameState.speedup_def.stay_full_commission_percent
	var templates := {}
	for template in GameState.bookings.templates:
		templates[template.id] = template
	for uid in GameState.lodgings:
		var lodging: Lodging = GameState.lodgings[uid]
		if lodging.booking and templates.has(lodging.booking.template_id):
			_expect(lodging.booking.nights == templates[lodging.booking.template_id].nights, "durée contractuelle inchangée")
		if lodging.state in [Lodging.State.OCCUPIED, Lodging.State.STAY_COMPLETE]:
			var speedup_paid := 0
			for entry in lodging.speedups:
				speedup_paid += int(entry.cost)
			var full := SpeedupRules.cumulative_price(lodging.booking.commission(), percent, lodging.stay_seconds(), lodging.stay_seconds())
			_expect(speedup_paid <= full, "accélérations d'un séjour <= accélération complète")
			_expect(lodging.removed_seconds() <= lodging.stay_seconds(), "temps retiré <= durée du séjour")
	for entry in GameState.stay_history:
		if entry.has("speedups"):
			_expect(int(entry.speedups.cost) <= (int(entry.commission) * percent + 99) / 100, "historique : accélérations <= 15 % de la commission")
	_expect(GameState.free_speedups >= 0 and GameState.free_speedups <= GameState.speedup_def.free_full_speedups, "offerte bornée")
	for entry in history:
		_expect(GameState.ledger_category(str(entry.reason)) != Ledger.UNCATEGORIZED, "motif de dépense catégorisé")
	return _broken


func _soak(seed_value: int) -> void:
	rng.seed = seed_value
	for step in STEPS:
		_random_step()
		var broken := _violations()
		if not broken.is_empty():
			fail_test("pas %d, invariants rompus : %s\n%s" % [step, broken, JSON.stringify(GameState.to_save_dict())])
			return
	stats.quests_completed = GameState.quest_log.with_status(QuestLog.Status.COMPLETED).size()
	gut.p("graine %d : %s, solde %d, niveau %d" % [seed_value, stats, GameState.wallet.balance(&"shells"), GameState.level()])
	# Le joueur aléatoire a vraiment joué : la recette n'est pas vide.
	assert_gt(stats.collected, 3, "plusieurs séjours menés à terme")
	assert_gt(stats.reloads, 20, "nombreuses restaurations")
	assert_gt(stats.refused, 0, "des actions invalides ont été tentées et refusées")
	assert_gte(stats.speedups, 3, "des accélérations ont réellement eu lieu")


func test_soak_seed_1() -> void:
	_soak(1)


func test_soak_seed_42() -> void:
	_soak(42)


func test_soak_seed_2026() -> void:
	_soak(2026)


## Contre-épreuves : le contrôle d'invariants détecte bien une corruption.
func test_invariant_check_detects_a_double_payment() -> void:
	assert_eq(_violations(), [] as Array[String], "partie neuve saine")
	GameState.stay_history.append({"booking": {"id": "dup"}, "commission": 1})
	GameState.stay_history.append({"booking": {"id": "dup"}, "commission": 1})
	GameState.paid_bookings[&"dup"] = true
	assert_eq(_violations().size(), 1, "double encaissement détecté")


func test_invariant_check_detects_a_broken_ledger_and_overfull_inventory() -> void:
	GameState.wallet.history.append({"currency": &"shells", "delta": 10, "balance": 999, "reason": &"quest:x"})
	GameState.inventory._counts[&"pineapple"] = GameState.inventory.capacity + 1
	assert_eq(_violations().size(), 3, "journal incohérent, solde final faux, inventaire trop plein")
