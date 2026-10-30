## Paramètres d'un bâtiment de rôle PRODUCER (production : étape 8).
class_name ProducerDef
extends Resource

@export var recipes: Array[RecipeDef] = []
@export_range(1, 8) var slots := 1
## Personnage qui tient le lieu (facultatif).
@export var operator: NpcDef
