## Restauration complète d'une partie, rattrapage des minuteurs, double
## encaissement, horloge système modifiée. Horloge simulée, aucune attente.
extends GutTest

const FakeClock := preload("res://tests/helpers/fake_clock.gd")
const DIR := "user://gut/save_restore"

var clock: FakeClock
var map: MapDef
var sm: Node


func before_each() -> void:
	clock = FakeClock.new()
	GameState.clock = clock
	map = load("res://data/maps/mahana.tres")
	GameState.new_game(map)
	sm = get_tree().root.get_node("SaveManager")
	sm.save_path = DIR.path_join("save.json")
	sm.delete_save()


func after_each() -> void:
	GameState.clock = Clock.new()
	sm.delete_save()
	sm.enabled = false


func _advance(seconds: int) -> void:
	clock.advance(seconds)
	GameState.tick()


## Sauvegarde, passage par JSON (comme le fichier), puis restauration.
func _save_and_reload() -> void:
	var text := JSON.stringify(GameState.to_save_dict())
	GameState.new_game(map)  # efface tout
	assert_true(GameState.load_save_dict(JSON.parse_string(text), map).ok)


func _busy_state() -> void:
	GameState.earn(&"shells", 1234, &"test")
	GameState.add_items({&"pineapple": 5})
	GameState.accept_offer(GameState.bookings.offers[0].id)
	GameState.add_items({&"welcome_basket": 1})
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.PREPARE)
	_advance(120)
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.WELCOME_GUESTS)
	GameState.start_production(&"farm_1", &"harvest_pineapple")
	GameState.start_production(&"workshop_1", &"craft_welcome_basket")
	_advance(10)


func test_everything_is_restored() -> void:
	_busy_state()
	var before := GameState.to_save_dict()
	_save_and_reload()
	var after := GameState.to_save_dict()
	assert_eq(JSON.stringify(after), JSON.stringify(before), "état identique après restauration")
	assert_eq(GameState.wallet.balance(&"shells"), 1284)
	assert_eq(GameState.inventory.count(&"pineapple"), 2)
	assert_eq(GameState.get_lodging(&"hibiscus_1").state, Lodging.State.OCCUPIED)
	assert_eq(GameState.get_lodging(&"hibiscus_1").booking.commission(), 120)
	assert_eq(GameState.producers[&"farm_1"].slot_state(0, GameState.now()), Producer.SlotState.RUNNING)
	assert_true(GameState.get_lodging(&"corail_1").locked, "verrouillage recalculé depuis la carte")


func test_timers_catch_up_after_the_app_was_closed() -> void:
	_busy_state()
	var text := JSON.stringify(GameState.to_save_dict())
	clock.advance(2 * 3600)  # application fermée 2 h
	GameState.new_game(map)
	GameState.load_save_dict(JSON.parse_string(text), map)
	assert_eq(GameState.get_lodging(&"hibiscus_1").state, Lodging.State.STAY_COMPLETE, "séjour terminé pendant l'absence")
	assert_eq(GameState.inventory.count(&"pineapple"), 5, "2 restants + 3 récoltés pendant l'absence")
	assert_eq(GameState.inventory.count(&"welcome_basket"), 1, "panier terminé pendant l'absence")
	assert_eq(GameState.bookings.offers.size(), 0, "aucune offre tant que le seul logement est occupé")
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.COLLECT_COMMISSION)
	assert_eq(GameState.bookings.offers.size(), 1, "une offre réapparaît dès que le logement se libère")


func test_no_double_collection_after_restore() -> void:
	_busy_state()
	_advance(600)
	assert_true(GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.COLLECT_COMMISSION).ok)
	var balance := GameState.wallet.balance(&"shells")
	_save_and_reload()
	assert_false(GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.COLLECT_COMMISSION).ok)
	assert_eq(GameState.wallet.balance(&"shells"), balance)
	assert_true(GameState.paid_bookings.has(GameState.stay_history[-1].booking.id))


func test_restoring_an_older_save_never_pays_twice_overall() -> void:
	_busy_state()
	_advance(600)
	var before_collect := JSON.stringify(GameState.to_save_dict())
	var balance_before: int = GameState.wallet.balance(&"shells")
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.COLLECT_COMMISSION)
	# Restauration d'une sauvegarde antérieure à l'encaissement (ex. coupure) :
	GameState.load_save_dict(JSON.parse_string(before_collect), map)
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.COLLECT_COMMISSION)
	assert_eq(GameState.wallet.balance(&"shells"), balance_before + 120, "une seule commission au total")


func test_clock_moved_backwards_never_rewinds_or_replays() -> void:
	GameState.start_production(&"farm_1", &"harvest_pineapple")
	_advance(20)
	var seen := GameState.now()
	clock.advance(-3600)  # horloge système reculée d'une heure
	GameState.tick()
	assert_eq(GameState.now(), seen, "le temps de jeu ne recule pas")
	assert_eq(GameState.producers[&"farm_1"].remaining(0, GameState.now()), 10, "la récolte n'a pas reculé")
	clock.advance(3600 + 9)
	GameState.tick()
	assert_eq(GameState.inventory.count(&"pineapple"), 0, "progression en pause tant que l'horloge est en retard")
	clock.advance(1)
	GameState.tick()
	assert_eq(GameState.inventory.count(&"pineapple"), 3, "une seule récolte")


func test_clock_moved_backwards_is_also_safe_across_a_restore() -> void:
	GameState.start_production(&"farm_1", &"harvest_pineapple")
	_advance(20)
	var text := JSON.stringify(GameState.to_save_dict())
	clock.advance(-86400)
	GameState.load_save_dict(JSON.parse_string(text), map)
	assert_eq(GameState.producers[&"farm_1"].slot_state(0, GameState.now()), Producer.SlotState.RUNNING)


func test_clock_jumping_forward_gives_each_timer_once() -> void:
	_busy_state()
	clock.advance(365 * 86400)  # un an d'avance
	GameState.tick()
	GameState.tick()
	assert_eq(GameState.inventory.count(&"pineapple"), 5)
	assert_eq(GameState.inventory.count(&"welcome_basket"), 1)
	assert_eq(GameState.bookings.offers.size(), 0, "aucune offre accumulée pendant un an")
	assert_true(GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.COLLECT_COMMISSION).ok)
	assert_false(GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.COLLECT_COMMISSION).ok)
	assert_lte(GameState.bookings.offers.size(), GameState.bookings.max_offers)


func test_invalid_or_foreign_data_is_sanitized() -> void:
	var data := GameState.to_save_dict()
	data.wallet = {"balances": {"shells": -500, "gold": 10}}
	data.inventory = {"counts": {"pineapple": 9999, "rock": 3}}
	data.lodgings = {"hibiscus_1": {"state": "OCCUPIED"}, "ghost_9": {"state": "BOOKED"}}
	data.producers = {"farm_1": {"slots": [{"recipe": "unknown", "start": 0, "end": 10}]}}
	data.paid_bookings = "not a list"
	assert_true(GameState.load_save_dict(data, map).ok)
	assert_eq(GameState.wallet.balance(&"shells"), 0)
	assert_eq(GameState.inventory.count(&"pineapple"), 50, "plafonné à la capacité")
	assert_eq(GameState.get_lodging(&"hibiscus_1").state, Lodging.State.VACANT, "séjour sans réservation : libéré")
	assert_false(GameState.lodgings.has(&"ghost_9"))
	assert_eq(GameState.producers[&"farm_1"].free_slot(), 0)
	assert_eq(GameState.paid_bookings.size(), 0, "liste invalide ignorée")


## Trouvé par la recette de stabilité : après un rechargement, l'historique
## des séjours gardait des flottants (120.0) et la sauvegarde suivante différait.
func test_stay_history_keeps_integers_across_several_reloads() -> void:
	_busy_state()
	_advance(30 * GameState.timings.night_seconds)
	assert_true(GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.COLLECT_COMMISSION).ok)
	_save_and_reload()
	var first := JSON.stringify(GameState.to_save_dict())
	_save_and_reload()
	assert_eq(JSON.stringify(GameState.to_save_dict()), first, "deuxième rechargement identique")
	assert_typeof(GameState.stay_history[0].commission, TYPE_INT)
	assert_typeof(GameState.stay_history[0].booking.guests, TYPE_INT)


## Sauvegarde au format de l'APK 0.1.3 (avant progression, quêtes et
## chantiers) : elle doit se charger sans perte de l'état existant.
func test_save_from_0_1_3_without_progression_quests_or_constructions_loads() -> void:
	_busy_state()
	var data: Dictionary = JSON.parse_string(JSON.stringify(GameState.to_save_dict()))
	data.erase("progression")
	data.erase("quests")
	data.erase("constructions")
	GameState.new_game(map)
	assert_true(GameState.load_save_dict(data, map).ok)
	assert_eq(GameState.wallet.balance(&"shells"), 1284, "solde conservé")
	assert_eq(GameState.inventory.count(&"pineapple"), 2, "inventaire conservé")
	assert_eq(GameState.get_lodging(&"hibiscus_1").state, Lodging.State.OCCUPIED, "séjour conservé")
	assert_eq(GameState.progression.xp, 0, "progression absente : départ à zéro")
	assert_eq(GameState.constructions[&"tiki_site_1"].state, ConstructionSite.State.IDLE, "chantier absent : non commencé")
	assert_gt(GameState.quest_log.with_status(QuestLog.Status.ACTIVE).size()
			+ GameState.quest_log.with_status(QuestLog.Status.AVAILABLE).size(), 0, "tutoriel disponible")
	var again := GameState.to_save_dict()
	assert_true(again.has("progression") and again.has("quests") and again.has("constructions"),
			"la sauvegarde suivante passe au format complet")


func test_save_of_another_map_is_refused() -> void:
	var data := GameState.to_save_dict()
	data.map = "zanzibar"
	assert_eq(GameState.load_save_dict(data, map).error, &"save_map_mismatch")


func test_save_manager_end_to_end() -> void:
	sm.enabled = true
	assert_false(sm.load_into_game(map), "aucune sauvegarde : nouvelle partie")
	GameState.new_game(map)
	_busy_state()
	assert_true(sm.save_now().ok)
	clock.advance(900)
	GameState.new_game(map)
	assert_true(sm.load_into_game(map))
	assert_eq(GameState.get_lodging(&"hibiscus_1").state, Lodging.State.STAY_COMPLETE)
	assert_eq(GameState.wallet.balance(&"shells"), 1284)


func test_going_to_background_saves_immediately() -> void:
	sm.enabled = true
	sm.load_into_game(map)
	GameState.new_game(map)
	GameState.earn(&"shells", 7)
	sm.propagate_notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_true(FileAccess.file_exists(sm.save_path))
	GameState.new_game(map)
	sm.load_into_game(map)
	assert_eq(GameState.wallet.balance(&"shells"), 57)


func test_collecting_a_commission_saves_immediately() -> void:
	sm.enabled = true
	sm.load_into_game(map)
	GameState.new_game(map)
	_busy_state()
	_advance(600)
	sm.delete_save()
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.COLLECT_COMMISSION)
	assert_true(FileAccess.file_exists(sm.save_path), "sauvegarde sans attendre après un encaissement")


func test_main_scene_resumes_a_saved_game() -> void:
	sm.enabled = true
	sm.load_into_game(map)
	GameState.new_game(map)
	GameState.earn(&"shells", 450)
	sm.save_now()
	GameState.new_game(map)
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child_autofree(main)
	assert_eq(main.resource_bar.amount_labels[&"shells"].text, "500")
