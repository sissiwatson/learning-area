## Paramètres d'un bâtiment de rôle OFFICE (bureau de conciergerie).
class_name OfficeDef
extends Resource

## Modèles proposés, dans l'ordre (rotation déterministe, aucun tirage).
@export var booking_templates: Array[BookingTemplateDef] = []
@export_range(1, 8) var max_offers := 2
