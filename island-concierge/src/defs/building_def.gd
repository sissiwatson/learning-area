## Définition d'un type de bâtiment. Ajouter un bâtiment d'un rôle existant
## = créer un fichier .tres dans data/buildings/, sans code.
class_name BuildingDef
extends Resource

enum Role { OFFICE, LODGING, PRODUCER, CONSTRUCTION, DECORATION }

@export var id: StringName
@export var name_key: String
@export var role := Role.LODGING
## Emprise en cellules (x, y).
@export var footprint := Vector2i(2, 2)
@export var texture: Texture2D
## Pixel de la texture placé au centre de l'emprise au sol.
@export var texture_anchor := Vector2(128, 192)
## Paramètres d'hébergement (rôle LODGING uniquement).
@export var lodging: LodgingDef
