## Événements de jeu utilisables comme objectifs de quête, avec le type de
## cible attendu (&"" = pas de cible, &"item" = objet, &"building" = bâtiment).
class_name GameEvents
extends RefCounted

const TARGETS := {
	&"camera_panned": &"",
	&"camera_zoomed": &"",
	&"booking_accepted": &"",
	&"item_collected": &"item",
	&"decoration_chosen": &"building",
	&"lodging_prepared": &"building",
	&"guests_welcomed": &"building",
	&"request_resolved": &"",
	&"stay_completed": &"building",
	&"commission_collected": &"",
	&"construction_started": &"building",
	&"building_built": &"building",
}
