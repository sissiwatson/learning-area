## Emplacements de production d'un bâtiment (plantation, atelier).
##
## Un emplacement est libre, en cours (horodatages de début et de fin) ou
## terminé. Les entrées sont consommées au lancement par GameState ; les
## sorties sont livrées à l'inventaire quand le minuteur est écoulé.
class_name Producer
extends RefCounted

enum SlotState { IDLE, RUNNING, DONE }

## Un dictionnaire par emplacement : {} = libre, sinon
## { "recipe": StringName, "start": int, "end": int }.
var slots: Array[Dictionary] = []


func _init(slot_count := 1) -> void:
	for i in maxi(slot_count, 1):
		slots.append({})


func free_slot() -> int:
	for i in slots.size():
		if slots[i].is_empty():
			return i
	return -1


func slot_state(index: int, now: int) -> SlotState:
	var slot := slots[index]
	if slot.is_empty():
		return SlotState.IDLE
	return SlotState.DONE if now >= slot.end else SlotState.RUNNING


## Occupe un emplacement libre ; renvoie son indice.
func start(recipe: RecipeDef, now: int) -> Result:
	var index := free_slot()
	if index < 0:
		return Result.failure(&"producer_busy")
	slots[index] = {"recipe": recipe.id, "start": now, "end": now + recipe.duration_seconds}
	return Result.success(index)


func done_slots(now: int) -> Array[int]:
	var result: Array[int] = []
	for i in slots.size():
		if slot_state(i, now) == SlotState.DONE:
			result.append(i)
	return result


func clear(index: int) -> void:
	slots[index] = {}


func remaining(index: int, now: int) -> int:
	return 0 if slots[index].is_empty() else maxi(slots[index].end - now, 0)


func progress(index: int, now: int) -> float:
	var slot := slots[index]
	if slot.is_empty() or slot.end <= slot.start:
		return 0.0
	return clampf(float(now - slot.start) / (slot.end - slot.start), 0.0, 1.0)


func to_dict() -> Dictionary:
	return {"slots": slots.duplicate(true)}


## Restaure un état sauvegardé ; un emplacement à recette inconnue ou aux
## valeurs invalides redevient libre.
static func from_dict(data: Dictionary, slot_count: int, recipe_ids: Array) -> Producer:
	var p := Producer.new(slot_count)
	var saved: Array = data.get("slots", [])
	for i in mini(saved.size(), p.slots.size()):
		var slot: Variant = saved[i]
		if slot is Dictionary and not slot.is_empty() and StringName(slot.get("recipe", "")) in recipe_ids:
			var start := int(slot.get("start", 0))
			var end := int(slot.get("end", 0))
			if end >= start:
				p.slots[i] = {"recipe": StringName(slot.recipe), "start": start, "end": end}
	return p
