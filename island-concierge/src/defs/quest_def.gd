## Quête (données seulement en V0.1 ; moteur de quêtes : lot N).
class_name QuestDef
extends Resource

@export var id: StringName
@export var title_key: String
@export var giver: NpcDef
## Identifiants des quêtes à terminer avant celle-ci.
@export var prerequisites: Array[StringName] = []
@export var objectives: Array[ObjectiveDef] = []
@export var reward_xp := 0
@export var reward_currencies: Dictionary[StringName, int] = {}
@export var reward_items: Dictionary[StringName, int] = {}
