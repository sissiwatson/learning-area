## Accélérations de séjour (0.1.6, lot 1) : devis avant confirmation, prix
## cumulatif à 15 %, accélération complète offerte une fois par partie,
## jamais de solde négatif ni de double paiement, réservation inchangée,
## sauvegarde. Horloge simulée.
extends GutTest

const FakeClock := preload("res://tests/helpers/fake_clock.gd")
const FIXTURE := "res://tests/fixtures/save_0_1_5.json"
const T := SpeedupRules.Tier

var clock: FakeClock
var map: MapDef


func before_each() -> void:
	clock = FakeClock.new()
	GameState.clock = clock
	map = load("res://data/maps/mahana.tres")
	GameState.new_game(map)


func after_each() -> void:
	GameState.clock = Clock.new()


func _advance(seconds: int) -> void:
	clock.advance(seconds)
	GameState.tick()


## Mène l'offre en tête (Camille et Noé : 2 nuits, commission 120) jusqu'au
## séjour en cours, sans rien dépenser.
func _start_stay() -> Lodging:
	assert_true(GameState.accept_offer(GameState.bookings.offers[0].id).ok)
	GameState.add_items({&"welcome_basket": 1})
	assert_true(GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.PREPARE).ok)
	_advance(GameState.timings.cleaning_seconds)
	assert_true(GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.WELCOME_GUESTS).ok)
	return GameState.get_lodging(&"hibiscus_1")


func _speed_up(tier: T) -> Result:
	var lodging := GameState.get_lodging(&"hibiscus_1")
	return GameState.speed_up_stay(&"hibiscus_1", tier, lodging.timer_end)


func _shells() -> int:
	return GameState.wallet.balance(&"shells")


func _use_free_speedup() -> void:
	GameState.free_speedups = 0


func test_quote_shows_the_price_before_confirmation_and_changes_nothing() -> void:
	var lodging := _start_stay()
	_use_free_speedup()
	var end := lodging.timer_end
	var quote := GameState.quote_stay_speedup(&"hibiscus_1", T.ONE_NIGHT)
	assert_true(quote.ok)
	assert_eq(quote.value.cost, 9)
	assert_eq(quote.value.seconds, 300)
	assert_eq(quote.value.currency, &"shells")
	assert_false(quote.value.free)
	assert_eq(quote.value.expected_end, end)
	assert_eq(GameState.quote_stay_speedup(&"hibiscus_1", T.FINISH).value.cost, 18)
	assert_eq(lodging.timer_end, end, "un devis ne modifie rien")
	assert_eq(_shells(), 50)


func test_first_full_speedup_is_offered_once_per_game() -> void:
	_start_stay()
	assert_eq(GameState.free_speedups, 1)
	var quote := GameState.quote_stay_speedup(&"hibiscus_1", T.FINISH)
	assert_true(quote.value.free)
	assert_eq(quote.value.cost, 0)
	assert_true(_speed_up(T.FINISH).ok)
	assert_eq(_shells(), 50, "offerte : rien n'est payé")
	assert_eq(GameState.free_speedups, 0)
	assert_eq(GameState.get_lodging(&"hibiscus_1").state, Lodging.State.STAY_COMPLETE, "séjour terminé tout de suite")
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.COLLECT_COMMISSION)
	_advance(60)
	_start_stay()
	var next := GameState.quote_stay_speedup(&"hibiscus_1", T.FINISH)
	assert_false(next.value.free, "une seule fois par partie")
	assert_gt(next.value.cost, 0)


func test_partial_speedup_is_paid_and_classified_as_comfort() -> void:
	var lodging := _start_stay()
	var remaining := lodging.remaining(GameState.now())
	assert_true(_speed_up(T.ONE_NIGHT).ok, "« Passer une nuit » ne consomme pas l'offerte")
	assert_eq(GameState.free_speedups, 1)
	assert_eq(_shells(), 41)
	assert_eq(lodging.remaining(GameState.now()), remaining - 300)
	var entry: Dictionary = GameState.wallet.history[-1]
	assert_eq(str(entry.reason), "comfort:speedup:" + String(lodging.booking.id))
	assert_eq(GameState.ledger_category(str(entry.reason)), &"comfort", "confort de jeu, hors exploitation")


func test_chained_partial_speedups_never_cost_more_than_a_full_one() -> void:
	_start_stay()
	_use_free_speedup()
	var full: int = GameState.quote_stay_speedup(&"hibiscus_1", T.FINISH).value.cost
	assert_true(_speed_up(T.ONE_NIGHT).ok)
	assert_true(_speed_up(T.ONE_NIGHT).ok)
	assert_eq(50 - _shells(), full, "deux nuits = terminer d'un coup (18)")
	assert_eq(GameState.get_lodging(&"hibiscus_1").state, Lodging.State.STAY_COMPLETE)


func test_a_double_tap_is_paid_only_once() -> void:
	var lodging := _start_stay()
	var shown_end := lodging.timer_end
	assert_true(GameState.speed_up_stay(&"hibiscus_1", T.ONE_NIGHT, shown_end).ok)
	var second := GameState.speed_up_stay(&"hibiscus_1", T.ONE_NIGHT, shown_end)
	assert_false(second.ok)
	assert_eq(second.error, &"stale_quote")
	assert_eq(_shells(), 41, "un seul paiement")
	assert_eq(lodging.removed_seconds(), 300, "une seule réduction")


func test_never_a_negative_balance() -> void:
	var lodging := _start_stay()
	_use_free_speedup()
	GameState.spend({&"shells": 45})
	var end := lodging.timer_end
	var result := _speed_up(T.ONE_NIGHT)
	assert_false(result.ok)
	assert_eq(result.error, &"insufficient_funds")
	assert_eq(_shells(), 5, "solde inchangé")
	assert_eq(lodging.timer_end, end, "minuteur inchangé")
	assert_eq(lodging.speedups.size(), 0)


func test_refused_outside_a_stay_without_any_effect() -> void:
	var history_size := GameState.wallet.history.size()
	for uid in [&"hibiscus_1", &"corail_1", &"ghost_9", &"office_1"]:
		assert_false(GameState.speed_up_stay(uid, T.FINISH, 0).ok, "logement libre, verrouillé ou inconnu : %s" % uid)
	GameState.accept_offer(GameState.bookings.offers[0].id)
	assert_eq(GameState.quote_stay_speedup(&"hibiscus_1", T.FINISH).error, &"invalid_action", "réservé")
	GameState.add_items({&"welcome_basket": 1})
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.PREPARE)
	assert_eq(GameState.quote_stay_speedup(&"hibiscus_1", T.FINISH).error, &"invalid_action", "ménage : pas une accélération de séjour")
	_advance(120)
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.WELCOME_GUESTS)
	_advance(600)
	assert_eq(GameState.quote_stay_speedup(&"hibiscus_1", T.FINISH).error, &"invalid_action", "séjour déjà terminé")
	assert_eq(GameState.wallet.history.size(), history_size, "aucun mouvement")
	assert_eq(GameState.free_speedups, 1, "l'offerte n'est pas consommée")


## Une accélération ne change ni la durée contractuelle, ni le prix payé par
## le voyageur, ni la commission, ni la part du propriétaire.
func test_contract_commission_and_owner_share_are_unchanged() -> void:
	var lodging := _start_stay()
	_use_free_speedup()
	var booking_before := lodging.booking.to_dict()
	_speed_up(T.ONE_NIGHT)
	_speed_up(T.FINISH)
	assert_eq(lodging.booking.to_dict(), booking_before)
	var before_collect := _shells()
	assert_true(GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.COLLECT_COMMISSION).ok)
	assert_eq(_shells() - before_collect, 120, "commission entière")
	var stay: Dictionary = GameState.stay_history[-1]
	assert_eq(stay.commission, 120)
	assert_eq(stay.owner_share, 480)
	assert_eq(stay.booking.nights, 2, "durée contractuelle")
	assert_eq(stay.speedups, {"count": 2, "seconds": 600, "cost": 18, "free": 0})
	assert_false(GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.COLLECT_COMMISSION).ok, "jamais deux fois")
	var commissions := GameState.wallet.history.filter(func(e): return str(e.reason).begins_with("commission:"))
	assert_eq(commissions.size(), 1)


func test_save_and_reload_keep_speedups_and_cumulative_pricing() -> void:
	_start_stay()
	_use_free_speedup()
	_speed_up(T.ONE_NIGHT)
	var text := JSON.stringify(GameState.to_save_dict())
	GameState.new_game(map)
	assert_true(GameState.load_save_dict(JSON.parse_string(text), map).ok)
	assert_eq(JSON.stringify(GameState.to_save_dict()), text, "aller-retour identique")
	var lodging := GameState.get_lodging(&"hibiscus_1")
	assert_eq(lodging.removed_seconds(), 300)
	assert_eq(lodging.stay_seconds(), 600)
	assert_eq(GameState.quote_stay_speedup(&"hibiscus_1", T.FINISH).value.cost, 9, "reste dû : 18 − 9")


func test_offered_speedup_is_not_given_back_by_a_reload() -> void:
	_start_stay()
	_speed_up(T.FINISH)
	assert_eq(GameState.free_speedups, 0)
	var data: Dictionary = JSON.parse_string(JSON.stringify(GameState.to_save_dict()))
	GameState.new_game(map)
	assert_eq(GameState.free_speedups, 1, "partie neuve : une offerte")
	GameState.load_save_dict(data, map)
	assert_eq(GameState.free_speedups, 0, "rechargement : pas de nouvelle offerte")
	data.free_speedups = 7
	GameState.load_save_dict(data, map)
	assert_eq(GameState.free_speedups, 1, "valeur incohérente bornée au barème")


func test_clock_moved_backwards_or_forwards_after_a_speedup() -> void:
	var lodging := _start_stay()
	_use_free_speedup()
	_speed_up(T.ONE_NIGHT)
	var shells := _shells()
	var end := lodging.timer_end
	clock.advance(-3600)
	GameState.tick()
	assert_eq(lodging.timer_end, end, "rien n'est rejoué")
	assert_eq(_shells(), shells, "rien n'est remboursé")
	assert_eq(lodging.state, Lodging.State.OCCUPIED)
	clock.advance(3600 + 3600)
	GameState.tick()
	assert_eq(lodging.state, Lodging.State.STAY_COMPLETE)
	assert_false(GameState.speed_up_stay(&"hibiscus_1", T.FINISH, lodging.timer_end).ok, "plus rien à accélérer")
	assert_true(GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.COLLECT_COMMISSION).ok)
	assert_eq(GameState.stay_history.size(), 1)


## Vraie sauvegarde produite par le code de l'APK 0.1.5 (avant ce lot).
func test_real_0_1_5_save_loads_and_receives_the_offered_speedup_once() -> void:
	var sm := get_tree().root.get_node("SaveManager")
	var path := "user://gut/speedups/save.json"
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var copy := FileAccess.open(path, FileAccess.WRITE)
	copy.store_string(FileAccess.get_file_as_string(FIXTURE))
	copy.close()
	var old_path: String = sm.save_path
	sm.save_path = path
	var read: Result = sm.read_save()
	sm.delete_save()
	sm.save_path = old_path
	assert_true(read.ok, "format 0.1.5 lu")
	assert_false(read.value.has("free_speedups"), "la 0.1.5 ne connaissait pas l'offerte")
	assert_true(GameState.load_save_dict(read.value, map).ok)
	var lodging := GameState.get_lodging(&"hibiscus_1")
	assert_eq(lodging.state, Lodging.State.OCCUPIED, "séjour de Léa en cours")
	assert_eq(String(lodging.booking.guest_name), "Léa")
	assert_eq(_shells(), 120)
	assert_eq(GameState.level(), 2)
	assert_eq(GameState.constructions[&"tiki_site_1"].state, ConstructionSite.State.BUILDING)
	assert_eq(GameState.free_speedups, 1, "ancienne sauvegarde : une offerte")
	assert_true(_speed_up(T.FINISH).ok)
	assert_eq(_shells(), 120, "offerte")
	assert_true(GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.COLLECT_COMMISSION).ok)
	assert_eq(_shells(), 170, "commission de Léa (50), une seule fois")
	var again := JSON.stringify(GameState.to_save_dict())
	GameState.new_game(map)
	GameState.load_save_dict(JSON.parse_string(again), map)
	assert_eq(GameState.free_speedups, 0, "pas réattribuée après rechargement")


func test_every_money_movement_of_the_game_has_a_category() -> void:
	# Séjour accéléré, encaissement, chantier, récompense de quête.
	_start_stay()
	_speed_up(T.ONE_NIGHT)
	_speed_up(T.FINISH)
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.COLLECT_COMMISSION)
	GameState.earn(&"shells", 200, &"quest:tutorial_test")
	GameState.gain_xp(500)
	assert_true(GameState.start_construction(&"tiki_site_1").ok)
	var categories := {}
	for entry in GameState.wallet.history:
		var category := GameState.ledger_category(str(entry.reason))
		assert_ne(category, Ledger.UNCATEGORIZED, "motif sans catégorie : %s" % entry.reason)
		categories[category] = true
	for expected in [&"opening", &"revenue", &"comfort", &"investment", &"reward"]:
		assert_true(categories.has(expected), String(expected))


func test_game_data_defines_the_scale_and_the_categories() -> void:
	var setup: NewGameDef = load("res://data/balance/new_game.tres")
	assert_not_null(setup.speedups)
	assert_eq(setup.speedups.stay_full_commission_percent, 15)
	assert_eq(setup.speedups.free_full_speedups, 1)
	assert_eq(setup.ledger_categories.prefixes["comfort:"], &"comfort")
	assert_eq(setup.ledger_categories.prefixes["charge:"], &"operating_charge")


func test_speedup_saves_immediately() -> void:
	var sm := get_tree().root.get_node("SaveManager")
	var old_path: String = sm.save_path
	sm.save_path = "user://gut/speedups/immediate.json"
	sm.delete_save()
	sm.enabled = true
	sm.load_into_game(map)
	GameState.new_game(map)
	_start_stay()
	sm.delete_save()
	assert_true(_speed_up(T.ONE_NIGHT).ok)
	assert_true(FileAccess.file_exists(sm.save_path), "sauvegarde sans attendre après une accélération")
	sm.delete_save()
	sm.enabled = false
	sm.save_path = old_path
