## Zone rectangulaire d'une carte, verrouillée tant qu'elle n'est pas débloquée.
class_name ZoneDef
extends Resource

@export var id: StringName
## Clé de traduction du nom affiché (i18n/strings.csv).
@export var name_key: String
## Cellules couvertes : position = coin haut-gauche, size = largeur × hauteur.
@export var rect: Rect2i
@export var starts_locked := true
