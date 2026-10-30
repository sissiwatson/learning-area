## Personnage non joueur (fiche minimale ; relations et dialogues : lot N).
class_name NpcDef
extends Resource

@export var id: StringName
## Nom propre affiché (non traduit).
@export var display_name := ""
@export var job_key: String
## Personnage sur la carte (pied au pixel `sprite_anchor`).
@export var sprite: Texture2D
@export var sprite_anchor := Vector2(32, 118)
## Portrait des dialogues.
@export var portrait: Texture2D
## Phrases d'ambiance (clés i18n), dites à tour de rôle quand on touche le personnage.
@export var ambient_keys: Array[String] = []
