## Offres de réservation du bureau de conciergerie.
##
## Règles déterministes (aucun tirage) :
## - les modèles sont proposés à tour de rôle, dans l'ordre des données ;
## - un modèle est sauté si aucun logement disponible ne peut l'accueillir ;
## - une nouvelle offre apparaît toutes les `refresh_seconds` jusqu'à `max_offers` ;
## - anti-blocage : s'il n'y a plus aucune offre, une offre apparaît aussitôt.
class_name BookingSystem
extends RefCounted

## Offre : { "id": StringName, "template": BookingTemplateDef }.
var offers: Array[Dictionary] = []
var templates: Array[BookingTemplateDef] = []
var max_offers := 2
var refresh_seconds := 60
var next_template_index := 0
var next_offer_at := 0
## Compteur des identifiants (offres et réservations).
var sequence := 0


func _init(new_templates: Array[BookingTemplateDef] = [], new_max := 2, new_refresh := 60) -> void:
	templates = new_templates
	max_offers = new_max
	refresh_seconds = new_refresh


## Ajoute les offres dues à l'instant `now`. `max_capacity` = plus grande
## capacité parmi les logements disponibles (0 s'il n'y en a aucun).
## Renvoie true si la liste a changé.
func update(now: int, max_capacity: int) -> bool:
	var changed := false
	if offers.is_empty():
		changed = _add_offer(max_capacity) or changed
		next_offer_at = now + refresh_seconds
	while offers.size() < max_offers and now >= next_offer_at:
		if not _add_offer(max_capacity):
			break
		changed = true
		next_offer_at += refresh_seconds
	if offers.size() >= max_offers and now >= next_offer_at:
		next_offer_at = now + refresh_seconds
	return changed


func find_offer(offer_id: StringName) -> Dictionary:
	for offer in offers:
		if offer.id == offer_id:
			return offer
	return {}


## Retire l'offre et renvoie une réservation figée.
func take_offer(offer_id: StringName, commission_percent: int, now: int) -> Result:
	var offer := find_offer(offer_id)
	if offer.is_empty():
		return Result.failure(&"unknown_offer")
	offers.erase(offer)
	sequence += 1
	return Result.success(Booking.create(StringName("bk_%04d" % sequence), offer.template, commission_percent, now))


## Secondes avant la prochaine offre (0 si la liste est pleine ou si une offre est due).
func seconds_to_next_offer(now: int) -> int:
	return 0 if offers.size() >= max_offers else maxi(next_offer_at - now, 0)


func to_dict() -> Dictionary:
	return {
		"offers": offers.map(func(o): return {"id": o.id, "template": o.template.id}),
		"next_template_index": next_template_index, "next_offer_at": next_offer_at, "sequence": sequence,
	}


## Restaure l'état ; les offres dont le modèle n'existe plus sont ignorées.
func load_dict(data: Dictionary) -> void:
	offers.clear()
	for entry in data.get("offers", []):
		for template in templates:
			if entry is Dictionary and template.id == StringName(entry.get("template", "")):
				offers.append({"id": StringName(entry.get("id", "")), "template": template})
	next_template_index = int(data.get("next_template_index", 0))
	next_offer_at = int(data.get("next_offer_at", 0))
	sequence = int(data.get("sequence", 0))


func _add_offer(max_capacity: int) -> bool:
	for attempt in templates.size():
		var template := templates[next_template_index % templates.size()]
		next_template_index = (next_template_index + 1) % templates.size()
		if template.guests <= max_capacity:
			sequence += 1
			offers.append({"id": StringName("offer_%04d" % sequence), "template": template})
			return true
	return false
