## Définition d'un territoire : plan des terrains, zones et décor.
##
## Le plan est un texte de `size.y` lignes de `size.x` caractères ; chaque
## caractère est un terrain (voir MapGrid.LEGEND). Il s'édite directement dans
## l'inspecteur ou dans le fichier .tres.
class_name MapDef
extends Resource

@export var id: StringName
@export var name_key: String
@export var size := Vector2i(32, 32)
@export_multiline var layout: String
@export var zones: Array[ZoneDef] = []
@export var placements: Array[PlacementDef] = []
## Graine du placement des palmiers et buissons (même graine = même décor).
@export var decor_seed := 1
