## Paramètres d'un emplacement de rôle CONSTRUCTION (construction : étape 11).
class_name ConstructionDef
extends Resource

@export var cost: Dictionary[StringName, int] = {}
@export_range(1, 99) var required_level := 1
@export_range(1, 604800) var build_seconds := 300
## Bâtiment obtenu une fois la construction terminée.
@export var builds_into: BuildingDef
