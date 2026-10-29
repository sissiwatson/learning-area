## Porte-monnaie : soldes entiers par monnaie, jamais négatifs.
##
## Règles :
## - montants entiers strictement positifs ; tout autre montant est refusé ;
## - une dépense est atomique : si une seule monnaie manque, rien n'est débité ;
## - solde plafonné à MAX_BALANCE (refus plutôt que dépassement) ;
## - chaque mouvement est journalisé (HISTORY_SIZE derniers mouvements).
class_name Wallet
extends RefCounted

const MAX_BALANCE := 999_999_999
const HISTORY_SIZE := 200

## Mouvements récents : { currency, delta, balance, reason }.
var history: Array[Dictionary] = []
var _balances := {}  # StringName -> int


func _init(currency_ids: Array = []) -> void:
	for id in currency_ids:
		_balances[StringName(id)] = 0


func has_currency(id: StringName) -> bool:
	return _balances.has(id)


func currency_ids() -> Array:
	return _balances.keys()


func balance(id: StringName) -> int:
	return _balances.get(id, 0)


## `cost` : { id de monnaie: montant }.
func can_afford(cost: Dictionary) -> bool:
	if _validate(cost) != &"":
		return false
	for id in cost:
		if balance(id) < cost[id]:
			return false
	return true


func earn(id: StringName, amount: int, reason := &"") -> Result:
	var error := _validate({id: amount})
	if error != &"":
		return Result.failure(error)
	if balance(id) > MAX_BALANCE - amount:
		return Result.failure(&"balance_overflow")
	_apply(id, amount, reason)
	return Result.success(balance(id))


func spend(cost: Dictionary, reason := &"") -> Result:
	var error := _validate(cost)
	if error != &"":
		return Result.failure(error)
	if not can_afford(cost):
		return Result.failure(&"insufficient_funds")
	for id in cost:
		_apply(id, -cost[id], reason)
	return Result.success()


func to_dict() -> Dictionary:
	return {"balances": _balances.duplicate(), "history": history.duplicate(true)}


## Restaure un état sauvegardé en ignorant les monnaies inconnues et en
## corrigeant les valeurs invalides (jamais de solde négatif).
static func from_dict(data: Dictionary, currency_ids: Array) -> Wallet:
	var wallet := Wallet.new(currency_ids)
	var balances: Dictionary = data.get("balances", {})
	for key in balances:
		var id := StringName(key)
		var value: Variant = balances[key]
		if wallet.has_currency(id) and (value is int or value is float):
			wallet._balances[id] = clampi(int(value), 0, MAX_BALANCE)
	for entry in data.get("history", []):
		if entry is Dictionary:
			wallet.history.append(entry)
	return wallet


func _validate(amounts: Dictionary) -> StringName:
	if amounts.is_empty():
		return &"invalid_amount"
	for id in amounts:
		if not has_currency(id):
			return &"unknown_currency"
		if typeof(amounts[id]) != TYPE_INT or amounts[id] <= 0:
			return &"invalid_amount"
	return &""


func _apply(id: StringName, delta: int, reason: StringName) -> void:
	_balances[id] += delta
	history.append({"currency": id, "delta": delta, "balance": _balances[id], "reason": reason})
	if history.size() > HISTORY_SIZE:
		history.pop_front()
