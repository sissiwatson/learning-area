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
var bookings: BookingSystem
## Réservations déjà payées (identifiant -> true) : garde-fou contre tout
## double versement, même avec une sauvegarde incohérente.
var paid_bookings := {}
## Réservations terminées et payées, de la plus ancienne à la plus récente.
var stay_history: Array[Dictionary] = []
var _placements := {}  # uid -> PlacementDef


func _ready() -> void:
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
	timings = setup.timings
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
		elif def.role == BuildingDef.Role.OFFICE and office == null:
			office = def.office
	var templates: Array[BookingTemplateDef] = []
	if office:
		templates = office.booking_templates
	bookings = BookingSystem.new(templates, office.max_offers if office else 1, timings.offer_refresh_seconds)
	for id in currency_defs:
		EventBus.currency_changed.emit(id, wallet.balance(id))
	for id in item_defs:
		EventBus.inventory_changed.emit(id, inventory.count(id))
	tick()


## Applique tout ce qui est dû à l'instant présent : fins de ménage et de
## séjour, nouvelles offres. Appelé chaque seconde et au retour au premier plan.
func tick() -> void:
	if map == null:
		return
	var now := clock.now()
	for uid in lodgings:
		var lodging: Lodging = lodgings[uid]
		for reached in lodging.update(now):
			EventBus.lodging_state_changed.emit(uid, reached)
			if reached == Lodging.State.STAY_COMPLETE:
				EventBus.stay_completed.emit(uid, lodging.booking.id, lodging.booking.commission())
	if bookings.update(now, _max_free_capacity()):
		EventBus.offers_changed.emit()


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
	var booking: Booking = bookings.take_offer(offer_id, percent, clock.now()).value
	lodging.book(booking)
	EventBus.booking_accepted.emit(booking.id, uid)
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
			var result := lodging.welcome_guests(clock.now(), timings.night_seconds)
			return _report(result, func(): EventBus.lodging_state_changed.emit(uid, lodging.state), {"uid": uid})
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
		var removed := remove_items(items)
		if not removed.ok:
			return removed
	var result := lodging.start_preparing(clock.now(), timings.cleaning_seconds)
	return _report(result, func(): EventBus.lodging_state_changed.emit(uid, lodging.state), {"uid": uid})


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
	stay_history.append({
		"booking": booking.to_dict(), "lodging": uid, "commission": amount,
		"owner_share": booking.owner_share(), "paid_at": clock.now(),
	})
	EventBus.commission_collected.emit(uid, booking.id, amount)
	EventBus.lodging_state_changed.emit(uid, lodging.state)
	tick()
	return Result.success(amount)


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
