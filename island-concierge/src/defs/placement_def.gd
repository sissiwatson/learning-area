## Un bâtiment posé sur une carte.
class_name PlacementDef
extends Resource

## Identifiant unique de l'instance sur la carte (sert de clé de sauvegarde).
@export var uid: StringName
@export var building: BuildingDef
## Cellule du coin haut de l'emprise (plus petits x et y).
@export var cell := Vector2i.ZERO
## Chemin des voyageurs depuis le ponton jusqu'à la porte (cellules).
@export var arrival_path: Array[Vector2i] = []


func cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in building.footprint.y:
		for x in building.footprint.x:
			result.append(cell + Vector2i(x, y))
	return result
