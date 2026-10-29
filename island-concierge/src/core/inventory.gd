## Inventaire : quantités entières par objet, capacité totale limitée.
##
## Ajouts et retraits sont atomiques : une opération sur plusieurs objets
## réussit entièrement ou ne change rien.
class_name Inventory
extends RefCounted

var capacity := 50
var _counts := {}  # StringName -> int


func _init(item_ids: Array = [], new_capacity := 50) -> void:
	capacity = new_capacity
	for id in item_ids:
		_counts[StringName(id)] = 0


func has_item_type(id: StringName) -> bool:
	return _counts.has(id)


func item_ids() -> Array:
	return _counts.keys()


func count(id: StringName) -> int:
	return _counts.get(id, 0)


func total() -> int:
	var sum := 0
	for id in _counts:
		sum += _counts[id]
	return sum


func free_space() -> int:
	return capacity - total()


## `items` : { id d'objet: quantité }.
func has_all(items: Dictionary) -> bool:
	if _validate(items) != &"":
		return false
	for id in items:
		if count(id) < items[id]:
			return false
	return true


func add(items: Dictionary) -> Result:
	var error := _validate(items)
	if error != &"":
		return Result.failure(error)
	var added := 0
	for id in items:
		added += items[id]
	if added > free_space():
		return Result.failure(&"inventory_full")
	for id in items:
		_counts[id] += items[id]
	return Result.success()


func remove(items: Dictionary) -> Result:
	var error := _validate(items)
	if error != &"":
		return Result.failure(error)
	if not has_all(items):
		return Result.failure(&"missing_items")
	for id in items:
		_counts[id] -= items[id]
	return Result.success()


func to_dict() -> Dictionary:
	return {"capacity": capacity, "counts": _counts.duplicate()}


## Restaure un état sauvegardé ; objets inconnus ignorés, quantités invalides
## corrigées, total ramené sous la capacité si nécessaire.
static func from_dict(data: Dictionary, item_ids: Array, default_capacity := 50) -> Inventory:
	var cap: Variant = data.get("capacity", default_capacity)
	var inventory := Inventory.new(item_ids, maxi(int(cap) if (cap is int or cap is float) else default_capacity, 1))
	var counts: Dictionary = data.get("counts", {})
	for key in counts:
		var id := StringName(key)
		var value: Variant = counts[key]
		if inventory.has_item_type(id) and (value is int or value is float):
			inventory._counts[id] = clampi(int(value), 0, inventory.free_space())
	return inventory


func _validate(items: Dictionary) -> StringName:
	if items.is_empty():
		return &"invalid_amount"
	for id in items:
		if not has_item_type(id):
			return &"unknown_item"
		if typeof(items[id]) != TYPE_INT or items[id] <= 0:
			return &"invalid_amount"
	return &""
