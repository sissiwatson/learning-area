## État de la partie (autoload `GameState`) : compose les objets du cœur et
## expose les commandes appelées par l'interface. Chaque commande renvoie un
## Result et annonce les changements via EventBus.
extends Node

const DEFAULT_NEW_GAME := preload("res://data/balance/new_game.tres")
## Monnaie dans laquelle les commissions sont versées.
const COMMISSION_CURRENCY := &"shells"

## Source du temps ; remplacée par une horloge simulée dans les tests.
var clock: Clock = Clock.new()
var wallet := Wallet.new()
var inventory := Inventory.new()
## Définitions des monnaies et objets de la partie, par identifiant.
var currency_defs := {}
var item_defs := {}
## uid du placement -> Lodging
var lodgings := {}
## Carte de la partie en cours.
var map: MapDef
var timings: TimingsDef
var progression_def: ProgressionDef
var progression := Progression.new()
var quest_log := QuestLog.new()
var bookings: BookingSystem
## Réservations déjà payées (identifiant -> true) : garde-fou contre tout
## double versement, même avec une sauvegarde incohérente.
var paid_bookings := {}
## uid du placement -> Producer
var producers := {}
## uid de l'emplacement constructible -> ConstructionSite
var constructions := {}
## Recettes de la carte par identifiant.
var recipe_defs := {}
## Productions terminées mais en attente de place dans l'inventaire
## (uid -> true), pour l'affichage.
var blocked_producers := {}
## Réservations terminées et payées, de la plus ancienne à la plus récente.
var stay_history: Array[Dictionary] = []
var _placements := {}  # uid -> PlacementDef
## Instant le plus récent déjà vu (secondes Unix) : le temps de jeu ne recule
## jamais, même si l'horloge système est reculée.
var last_seen := 0

const HISTORY_LIMIT := 100


func _ready() -> void:
	EventBus.game_event.connect(_on_game_event)
	# Les minuteurs sont des horodatages : une vérification par seconde suffit.
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(tick)
	add_child(timer)


func _notification(what: int) -> void:
	# Retour au premier plan (Android) : rattraper le temps écoulé.
	if what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		tick()


## Démarre une partie neuve sur une carte. (La sauvegarde arrive à l'étape 10.)
func new_game(new_map: MapDef, setup: NewGameDef = DEFAULT_NEW_GAME) -> void:
	map = new_map
	last_seen = 0
	timings = setup.timings
	progression_def = setup.progression
	progression = Progression.new(progression_def.level_thresholds)
	quest_log = QuestLog.new(setup.quests)
	currency_defs.clear()
	for def in setup.currencies:
		currency_defs[def.id] = def
	item_defs.clear()
	for def in setup.items:
		item_defs[def.id] = def
	wallet = Wallet.new(currency_defs.keys())
	for id in setup.starting_balances:
		wallet.earn(id, setup.starting_balances[id], &"new_game")
	inventory = Inventory.new(item_defs.keys(), setup.inventory_capacity)
	if not setup.starting_items.is_empty():
		inventory.add(setup.starting_items)
	lodgings.clear()
	producers.clear()
	constructions.clear()
	recipe_defs.clear()
	blocked_producers.clear()
	_placements.clear()
	paid_bookings.clear()
	stay_history.clear()
	var office: OfficeDef = null
	for placement in map.placements:
		_placements[placement.uid] = placement
		var def := placement.building
		if def.role == BuildingDef.Role.LODGING:
			var lodging := Lodging.new()
			lodging.capacity = def.lodging.capacity
			var zone := map.zone_at(placement.cell)
			lodging.locked = zone != null and zone.starts_locked
			lodgings[placement.uid] = lodging
		elif def.role == BuildingDef.Role.PRODUCER:
			producers[placement.uid] = Producer.new(def.producer.slots)
			for recipe in def.producer.recipes:
				recipe_defs[recipe.id] = recipe
		elif def.role == BuildingDef.Role.CONSTRUCTION:
			constructions[placement.uid] = ConstructionSite.new()
		elif def.role == BuildingDef.Role.OFFICE and office == null:
			office = def.office
	var templates: Array[BookingTemplateDef] = []
	if office:
		templates = office.booking_templates
	bookings = BookingSystem.new(templates, office.max_offers if office else 1, timings.offer_refresh_seconds)
	_announce_everything()
	_refresh_quests()
	tick()


## Applique tout ce qui est dû à l'instant présent : fins de ménage et de
## séjour, nouvelles offres. Appelé chaque seconde et au retour au premier plan.
func tick() -> void:
	if map == null:
		return
	var at := now()
	for uid in lodgings:
		var lodging: Lodging = lodgings[uid]
		for reached in lodging.update(at):
			EventBus.lodging_state_changed.emit(uid, reached)
			if reached == Lodging.State.STAY_COMPLETE:
				EventBus.stay_completed.emit(uid, lodging.booking.id, lodging.booking.commission())
				EventBus.game_event.emit(&"stay_completed", get_placement(uid).building.id, 1)
	for uid in producers:
		_deliver(uid, at)
	for uid in constructions:
		if constructions[uid].update(at):
			_on_construction_finished(uid)
	if bookings.update(at, _max_free_capacity()):
		EventBus.offers_changed.emit()
	EventBus.ticked.emit()


# --- Sauvegarde ------------------------------------------------------------

## État complet de la partie, sérialisable en JSON.
func to_save_dict() -> Dictionary:
	var lodging_data := {}
	for uid in lodgings:
		lodging_data[uid] = lodgings[uid].to_dict()
	var producer_data := {}
	for uid in producers:
		producer_data[uid] = producers[uid].to_dict()
	return {
		"map": map.id,
		"last_seen": last_seen,
		"wallet": wallet.to_dict(),
		"progression": progression.to_dict(),
		"quests": quest_log.to_dict(),
		"inventory": {"counts": inventory.to_dict().counts},
		"lodgings": lodging_data,
		"producers": producer_data,
		"constructions": _constructions_dict(),
		"bookings": bookings.to_dict(),
		"paid_bookings": paid_bookings.keys(),
		"stay_history": stay_history.duplicate(true),
	}


## Restaure une partie sauvegardée sur `new_map`. Les définitions viennent
## toujours des données actuelles ; la sauvegarde n'apporte que l'état.
## Valeurs invalides corrigées, bâtiments inconnus ignorés, bâtiments absents
## de la sauvegarde à l'état initial. Le temps écoulé est rattrapé ensuite.
func load_save_dict(data: Dictionary, new_map: MapDef, setup: NewGameDef = DEFAULT_NEW_GAME) -> Result:
	if str(data.get("map", "")) != String(new_map.id):
		return Result.failure(&"save_map_mismatch")
	new_game(new_map, setup)
	last_seen = maxi(last_seen, int(data.get("last_seen", 0)))
	wallet = Wallet.from_dict(_dict(data, "wallet"), currency_defs.keys())
	progression = Progression.from_dict(_dict(data, "progression"), progression_def.level_thresholds)
	quest_log.load_dict(_dict(data, "quests"))
	inventory = Inventory.from_dict({"capacity": setup.inventory_capacity, "counts": _dict(data, "inventory").get("counts", {})},
			item_defs.keys(), setup.inventory_capacity)
	var saved_lodgings := _dict(data, "lodgings")
	for uid in lodgings:
		if saved_lodgings.get(uid) is Dictionary:
			var current: Lodging = lodgings[uid]
			lodgings[uid] = Lodging.from_dict(saved_lodgings[uid], current.capacity, current.locked)
	var saved_producers := _dict(data, "producers")
	for uid in producers:
		if saved_producers.get(uid) is Dictionary:
			var placement := get_placement(uid)
			var ids := recipes_of(uid).map(func(r): return r.id)
			producers[uid] = Producer.from_dict(saved_producers[uid], placement.building.producer.slots, ids)
	var saved_sites := _dict(data, "constructions")
	for uid in constructions:
		if saved_sites.get(uid) is Dictionary:
			constructions[uid] = ConstructionSite.from_dict(saved_sites[uid])
	bookings.load_dict(_dict(data, "bookings"))
	paid_bookings.clear()
	var paid: Variant = data.get("paid_bookings", [])
	for id in (paid if paid is Array else []):
		paid_bookings[StringName(str(id))] = true
	stay_history.clear()
	var history: Variant = data.get("stay_history", [])
	for entry in (history if history is Array else []):
		if entry is Dictionary and stay_history.size() < HISTORY_LIMIT:
			stay_history.append(entry)
	_announce_everything()
	_refresh_quests()
	tick()
	return Result.success()


func _dict(data: Dictionary, key: String) -> Dictionary:
	var value: Variant = data.get(key, {})
	return value if value is Dictionary else {}


## Signale à l'interface l'état complet (après un chargement).
func _announce_everything() -> void:
	EventBus.xp_changed.emit(progression.xp, progression.level())
	for id in currency_defs:
		EventBus.currency_changed.emit(id, wallet.balance(id))
	for id in item_defs:
		EventBus.inventory_changed.emit(id, inventory.count(id))
	for uid in lodgings:
		EventBus.lodging_state_changed.emit(uid, lodgings[uid].state)
	EventBus.offers_changed.emit()


# --- Progression -----------------------------------------------------------

func level() -> int:
	return progression.level()


## Ajoute de l'XP et annonce un éventuel passage de niveau.
func gain_xp(amount: int, reason := &"") -> void:
	if amount <= 0:
		return
	var result := progression.add_xp(amount)
	EventBus.xp_changed.emit(progression.xp, progression.level())
	EventBus.xp_gained.emit(amount, reason)
	if result.ok and result.value > 0:
		EventBus.level_up.emit(progression.level())


# --- Quêtes ------------------------------------------------------------------

## Démarre une quête disponible (à la fin de son dialogue d'introduction).
func start_quest(id: StringName) -> Result:
	var result := quest_log.start(id)
	if result.ok:
		EventBus.quest_started.emit(id)
	return result


func _on_game_event(event: StringName, target: StringName, amount: int) -> void:
	var completed := quest_log.record(event, target, amount)
	for q in quest_log.with_status(QuestLog.Status.ACTIVE):
		EventBus.quest_progressed.emit(q.id)
	for q in completed:
		_grant_quest_rewards(q)
		EventBus.quest_completed.emit(q.id)
	if not completed.is_empty():
		_refresh_quests()


## Récompenses d'une quête terminée, une seule fois (marquées dans le journal).
func _grant_quest_rewards(q: QuestDef) -> void:
	if not quest_log.claim_reward(q.id):
		return
	for id in q.reward_currencies:
		earn(id, q.reward_currencies[id], StringName("quest:" + q.id))
	if not q.reward_items.is_empty():
		add_items(q.reward_items)  # inventaire plein : la récompense d'objets est perdue, signalé par action_failed
	gain_xp(q.reward_xp, StringName("quest:" + q.id))


func _refresh_quests() -> void:
	for q in quest_log.refresh():
		EventBus.quest_available.emit(q.id)


# --- Économie -------------------------------------------------------------

func earn(currency_id: StringName, amount: int, reason := &"") -> Result:
	var result := wallet.earn(currency_id, amount, reason)
	return _report(result, func(): EventBus.currency_changed.emit(currency_id, wallet.balance(currency_id)))


func spend(cost: Dictionary, reason := &"") -> Result:
	var result := wallet.spend(cost, reason)
	return _report(result, func():
		for id in cost:
			EventBus.currency_changed.emit(id, wallet.balance(id)))


func add_items(items: Dictionary) -> Result:
	var result := inventory.add(items)
	return _report(result, _emit_items.bind(items))


func remove_items(items: Dictionary) -> Result:
	var result := inventory.remove(items)
	return _report(result, _emit_items.bind(items))


# --- Productions -----------------------------------------------------------

## Recettes proposées par un bâtiment de production.
func recipes_of(uid: StringName) -> Array[RecipeDef]:
	var placement := get_placement(uid)
	if placement == null or placement.building.producer == null:
		return []
	return placement.building.producer.recipes


## Lance une recette : consomme les entrées puis démarre le minuteur.
## Tout ou rien : si le bâtiment est occupé ou qu'il manque une entrée, rien
## n'est consommé (des taps répétés ne consomment donc qu'une fois).
func start_production(uid: StringName, recipe_id: StringName) -> Result:
	var producer: Producer = producers.get(uid)
	if producer == null:
		return _report(Result.failure(&"unknown_building"), Callable(), {"uid": uid})
	var recipe: RecipeDef = null
	for r in recipes_of(uid):
		if r.id == recipe_id:
			recipe = r
	if recipe == null:
		return _report(Result.failure(&"unknown_recipe"), Callable(), {"uid": uid})
	if producer.free_slot() < 0:
		return _report(Result.failure(&"producer_busy"), Callable(), {"uid": uid})
	if not recipe.inputs.is_empty():
		if not inventory.has_all(recipe.inputs):
			return _report(Result.failure(&"missing_items"), Callable(), {"uid": uid})
		remove_items(recipe.inputs)
	var result := producer.start(recipe, now())
	EventBus.production_started.emit(uid, recipe.id)
	return result


## Livre à l'inventaire les productions terminées ; si l'inventaire est
## plein, la production attend (rien n'est perdu) et repart au tick suivant.
func _deliver(uid: StringName, at: int) -> void:
	var producer: Producer = producers[uid]
	var blocked := false
	for index in producer.done_slots(at):
		var recipe: RecipeDef = recipe_defs.get(producer.slots[index].recipe)
		if inventory.add(recipe.outputs).ok:
			producer.clear(index)
			_emit_items(recipe.outputs)
			for id in recipe.outputs:
				EventBus.item_collected.emit(id, recipe.outputs[id])
				EventBus.game_event.emit(&"item_collected", id, recipe.outputs[id])
			EventBus.production_completed.emit(uid, recipe.id)
			gain_xp(recipe.xp, StringName("recipe:" + recipe.id))
		else:
			blocked = true
	if blocked != blocked_producers.has(uid):
		if blocked:
			blocked_producers[uid] = true
		else:
			blocked_producers.erase(uid)
		EventBus.production_blocked_changed.emit(uid, blocked)


# --- Constructions ---------------------------------------------------------

## Définition effective d'un placement : le bâtiment construit si le chantier
## est terminé, sinon le bâtiment posé sur la carte.
func building_def_of(uid: StringName) -> BuildingDef:
	var placement := get_placement(uid)
	if placement == null:
		return null
	var site: ConstructionSite = constructions.get(uid)
	if site and site.state == ConstructionSite.State.BUILT:
		return placement.building.construction.builds_into
	return placement.building


## Lance une construction : niveau requis, puis paiement, puis minuteur.
## Tout ou rien : aucun coquillage dépensé en cas de refus.
func start_construction(uid: StringName) -> Result:
	var site: ConstructionSite = constructions.get(uid)
	if site == null:
		return _report(Result.failure(&"unknown_building"), Callable(), {"uid": uid})
	if site.state != ConstructionSite.State.IDLE:
		return _report(Result.failure(&"already_started"), Callable(), {"uid": uid})
	var def := get_placement(uid).building.construction
	if level() < def.required_level:
		return _report(Result.failure(&"level_too_low"), Callable(), {"uid": uid, "level": def.required_level})
	var paid := spend(def.cost, StringName("construction:" + uid))
	if not paid.ok:
		return paid
	site.start(now(), def.build_seconds)
	EventBus.construction_started.emit(uid)
	EventBus.game_event.emit(&"construction_started", get_placement(uid).building.id, 1)
	tick()
	return Result.success()


func _on_construction_finished(uid: StringName) -> void:
	var def := get_placement(uid).building.construction
	EventBus.building_built.emit(uid, def.builds_into.id)
	EventBus.game_event.emit(&"building_built", def.builds_into.id, 1)
	gain_xp(def.xp, StringName("construction:" + uid))


func _constructions_dict() -> Dictionary:
	var out := {}
	for uid in constructions:
		out[uid] = constructions[uid].to_dict()
	return out


# --- Réservations et logements -----------------------------------------

func get_placement(uid: StringName) -> PlacementDef:
	return _placements.get(uid)


## Zone contenant un placement, ou null.
func zone_of(uid: StringName) -> ZoneDef:
	var placement := get_placement(uid)
	return map.zone_at(placement.cell) if placement else null


func get_lodging(uid: StringName) -> Lodging:
	return lodgings.get(uid)


## Premier logement libre et débloqué pouvant accueillir `guests` voyageurs
## (ordre de la carte), ou &"" s'il n'y en a aucun.
func find_lodging_for(guests: int) -> StringName:
	for uid in lodgings:
		if lodgings[uid].can_book(guests).ok:
			return uid
	return &""


## Taux de commission du logement qui accueillerait `guests` voyageurs :
## un logement libre adapté s'il y en a, sinon le premier logement adapté
## (pour afficher la commission même quand tout est occupé).
func commission_percent_for(guests: int) -> int:
	var uid := find_lodging_for(guests)
	if uid == &"":
		for candidate in lodgings:
			if lodgings[candidate].capacity >= guests and not lodgings[candidate].locked:
				uid = candidate
				break
	return get_placement(uid).building.lodging.commission_percent if uid != &"" else 0


## Accepte une offre du bureau. Sans `lodging_uid`, choisit le premier
## logement libre adapté.
func accept_offer(offer_id: StringName, lodging_uid := &"") -> Result:
	var offer := bookings.find_offer(offer_id)
	if offer.is_empty():
		return _report(Result.failure(&"unknown_offer"), Callable())
	var template: BookingTemplateDef = offer.template
	var uid := lodging_uid if lodging_uid != &"" else find_lodging_for(template.guests)
	if uid == &"":
		return _report(Result.failure(&"no_vacant_lodging"), Callable())
	var lodging := get_lodging(uid)
	if lodging == null:
		return _report(Result.failure(&"unknown_lodging"), Callable(), {"uid": uid})
	var check := lodging.can_book(template.guests)
	if not check.ok:
		return _report(check, Callable(), {"uid": uid})
	var percent: int = get_placement(uid).building.lodging.commission_percent
	var booking: Booking = bookings.take_offer(offer_id, percent, now()).value
	lodging.book(booking)
	EventBus.booking_accepted.emit(booking.id, uid)
	gain_xp(progression_def.xp_booking_accepted, &"booking_accepted")
	EventBus.game_event.emit(&"booking_accepted", &"", 1)
	EventBus.lodging_state_changed.emit(uid, lodging.state)
	tick()  # une offre peut réapparaître aussitôt (anti-blocage)
	EventBus.offers_changed.emit()
	return Result.success(booking)


func perform_lodging_action(uid: StringName, action: Lodging.Action) -> Result:
	var lodging := get_lodging(uid)
	if lodging == null:
		return _report(Result.failure(&"unknown_lodging"), Callable(), {"uid": uid})
	match action:
		Lodging.Action.PREPARE:
			return _prepare(uid, lodging)
		Lodging.Action.WELCOME_GUESTS:
			var result := lodging.welcome_guests(now(), timings.night_seconds)
			return _report(result, func():
				EventBus.lodging_state_changed.emit(uid, lodging.state)
				gain_xp(progression_def.xp_guests_welcomed, &"guests_welcomed")
				EventBus.game_event.emit(&"guests_welcomed", get_placement(uid).building.id, 1), {"uid": uid})
		Lodging.Action.COLLECT_COMMISSION:
			return _collect(uid, lodging)
	return _report(Result.failure(&"invalid_action"), Callable(), {"uid": uid})


## Ménage : consomme les objets de préparation (aucun en V0.1 avant les
## productions) puis lance le minuteur. Tout ou rien.
func _prepare(uid: StringName, lodging: Lodging) -> Result:
	if lodging.locked or lodging.state != Lodging.State.BOOKED:
		return _report(Result.failure(&"lodging_locked" if lodging.locked else &"invalid_action"), Callable(), {"uid": uid})
	var items: Dictionary = get_placement(uid).building.lodging.prepare_items
	if not items.is_empty():
		if not inventory.has_all(items):
			return _report(Result.failure(&"missing_items"), Callable(), {"uid": uid})
		remove_items(items)
	var result := lodging.start_preparing(now(), timings.cleaning_seconds)
	return _report(result, func():
		EventBus.lodging_state_changed.emit(uid, lodging.state)
		gain_xp(progression_def.xp_lodging_prepared, &"lodging_prepared")
		EventBus.game_event.emit(&"lodging_prepared", get_placement(uid).building.id, 1), {"uid": uid})


## Encaisse la commission d'un séjour terminé, une seule fois par réservation.
func _collect(uid: StringName, lodging: Lodging) -> Result:
	if lodging.booking and paid_bookings.has(lodging.booking.id):
		return _report(Result.failure(&"already_paid"), Callable(), {"uid": uid})
	if lodging.booking and wallet.balance(COMMISSION_CURRENCY) > Wallet.MAX_BALANCE - lodging.booking.commission():
		return _report(Result.failure(&"balance_overflow"), Callable(), {"uid": uid})
	var result := lodging.collect_commission()
	if not result.ok:
		return _report(result, Callable(), {"uid": uid})
	var booking: Booking = result.value
	paid_bookings[booking.id] = true
	var amount := booking.commission()
	if amount > 0:
		earn(COMMISSION_CURRENCY, amount, StringName("commission:" + booking.id))
	if stay_history.size() >= HISTORY_LIMIT:
		stay_history.pop_front()
	stay_history.append({
		"booking": booking.to_dict(), "lodging": uid, "commission": amount,
		"owner_share": booking.owner_share(), "paid_at": now(),
	})
	EventBus.commission_collected.emit(uid, booking.id, amount)
	gain_xp(progression_def.xp_stay_completed, &"stay_completed")
	EventBus.game_event.emit(&"commission_collected", &"", 1)
	EventBus.lodging_state_changed.emit(uid, lodging.state)
	tick()
	return Result.success(amount)


## Instant présent pour toutes les règles de jeu, monotone :
## - horloge reculée : le temps de jeu reste figé à `last_seen` jusqu'à ce que
##   l'horloge le dépasse (rien n'est annulé ni rejoué) ;
## - horloge avancée : les minuteurs se terminent, mais chacun ne produit
##   qu'une fois (pas de répétition, au plus `max_offers` offres).
func now() -> int:
	last_seen = maxi(last_seen, clock.now())
	return last_seen


func _max_free_capacity() -> int:
	var best := 0
	for uid in lodgings:
		var lodging: Lodging = lodgings[uid]
		if not lodging.locked and lodging.state == Lodging.State.VACANT:
			best = maxi(best, lodging.capacity)
	return best


## Annonce le résultat d'une commande : signal de changement si succès,
## `action_failed` sinon.
func _report(result: Result, on_success: Callable, params := {}) -> Result:
	if result.ok:
		if on_success.is_valid():
			on_success.call()
	else:
		EventBus.action_failed.emit(result.error, params)
	return result


func _emit_items(items: Dictionary) -> void:
	for id in items:
		EventBus.inventory_changed.emit(id, inventory.count(id))
