## État de la partie (autoload `GameState`) : compose les objets du cœur et
## expose les commandes appelées par l'interface. Chaque commande renvoie un
## Result et annonce les changements via EventBus.
extends Node

## uid du placement -> Lodging
var lodgings := {}


## Démarre une partie neuve sur une carte. (La sauvegarde arrive à l'étape 9.)
func new_game(map: MapDef) -> void:
	lodgings.clear()
	for placement in map.placements:
		if placement.building.role == BuildingDef.Role.LODGING:
			lodgings[placement.uid] = Lodging.new()


func get_lodging(uid: StringName) -> Lodging:
	return lodgings.get(uid)


func perform_lodging_action(uid: StringName, action: Lodging.Action) -> Result:
	var lodging := get_lodging(uid)
	if lodging == null:
		return _fail(&"unknown_lodging")
	var result := lodging.perform(action)
	if result.ok:
		EventBus.lodging_state_changed.emit(uid, lodging.state)
	else:
		EventBus.action_failed.emit(result.error, {"uid": uid})
	return result


func _fail(code: StringName) -> Result:
	EventBus.action_failed.emit(code, {})
	return Result.failure(code)
