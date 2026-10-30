## Définition d'un type de bâtiment. Ajouter un bâtiment d'un rôle existant
## = créer un fichier .tres dans data/buildings/, sans code.
class_name BuildingDef
extends Resource

enum Role { OFFICE, LODGING, PRODUCER, CONSTRUCTION, DECORATION }

const ROLE_KEYS := {
	Role.OFFICE: "ROLE_OFFICE",
	Role.LODGING: "ROLE_LODGING",
	Role.PRODUCER: "ROLE_PRODUCER",
	Role.CONSTRUCTION: "ROLE_CONSTRUCTION",
	Role.DECORATION: "ROLE_DECORATION",
}

@export var id: StringName
@export var name_key: String
## Description affichée dans le panneau (clé i18n, facultative).
@export var description_key: String
@export var role := Role.LODGING
## Emprise en cellules (x, y).
@export var footprint := Vector2i(2, 2)
@export var texture: Texture2D
## Stades visuels d'une production en cours (ex. pousses, plants, fruits) ;
## vide = la texture principale ne change pas.
@export var stage_textures: Array[Texture2D] = []
## Pixel de la texture placé au centre de l'emprise au sol.
@export var texture_anchor := Vector2(128, 192)
## Paramètres propres au rôle (un seul renseigné, selon `role`).
@export var lodging: LodgingDef
@export var office: OfficeDef
@export var producer: ProducerDef
@export var construction: ConstructionDef
