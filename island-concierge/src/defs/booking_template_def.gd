## Modèle de réservation proposé par le bureau de conciergerie.
class_name BookingTemplateDef
extends Resource

@export var id: StringName
## Nom des voyageurs (noms propres, non traduits).
@export var guest_name := ""
@export_range(1, 12) var guests := 2
@export_range(1, 30) var nights := 2
## Prix d'une nuit payé par les voyageurs au propriétaire.
@export_range(1, 100000) var nightly_price := 300
