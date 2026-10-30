## Quête (données seulement en V0.1 ; moteur de quêtes : lot N).
class_name QuestDef
extends Resource

@export var id: StringName
@export var title_key: String
@export var giver: NpcDef
## Identifiants des quêtes à terminer avant celle-ci.
@export var prerequisites: Array[StringName] = []
@export var objectives: Array[ObjectiveDef] = []
## Dialogue joué quand la quête devient disponible ; la quête démarre à sa fin.
@export var intro_dialogue: DialogueDef
## Dialogue joué quand la quête est terminée (facultatif).
@export var outro_dialogue: DialogueDef
## Bâtiment montré par le bouton « Y aller » (identifiant de BuildingDef).
@export var focus_building: StringName
@export var reward_xp := 0
@export var reward_currencies: Dictionary[StringName, int] = {}
@export var reward_items: Dictionary[StringName, int] = {}
