## Recette d'un bâtiment de production : entrées -> sorties en un temps donné.
class_name RecipeDef
extends Resource

@export var id: StringName
@export var name_key: String
## Objets consommés au lancement ({} = gratuit).
@export var inputs: Dictionary[StringName, int] = {}
## Objets produits à la fin.
@export var outputs: Dictionary[StringName, int] = {}
## Durée en temps réel (secondes) ; continue quand l'application est fermée.
@export_range(1, 86400) var duration_seconds := 30
@export var xp := 0
