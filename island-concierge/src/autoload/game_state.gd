## État de la partie (autoload `GameState`) : compose les objets du cœur et
## expose les commandes appelées par l'interface. Chaque commande renvoie un
## Result et annonce les changements via EventBus.
extends Node

const DEFAULT_NEW_GAME := preload("res://data/balance/new_game.tres")

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


## Démarre une partie neuve sur une carte. (La sauvegarde arrive à l'étape 10.)
func new_game(new_map: MapDef, setup: NewGameDef = DEFAULT_NEW_GAME) -> void:
	map = new_map
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
	for placement in map.placements:
		if placement.building.role == BuildingDef.Role.LODGING:
			var lodging := Lodging.new()
			var zone := map.zone_at(placement.cell)
			lodging.locked = zone != null and zone.starts_locked
			lodgings[placement.uid] = lodging
	for id in currency_defs:
		EventBus.currency_changed.emit(id, wallet.balance(id))
	for id in item_defs:
		EventBus.inventory_changed.emit(id, inventory.count(id))


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


# --- Logements ------------------------------------------------------------

## Zone contenant un placement, ou null.
func zone_of(uid: StringName) -> ZoneDef:
	for placement in map.placements:
		if placement.uid == uid:
			return map.zone_at(placement.cell)
	return null


func get_lodging(uid: StringName) -> Lodging:
	return lodgings.get(uid)


func perform_lodging_action(uid: StringName, action: Lodging.Action) -> Result:
	var lodging := get_lodging(uid)
	if lodging == null:
		return _report(Result.failure(&"unknown_lodging"), Callable(), {"uid": uid})
	var result := lodging.perform(action)
	return _report(result, func(): EventBus.lodging_state_changed.emit(uid, lodging.state), {"uid": uid})


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
