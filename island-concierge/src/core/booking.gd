## Réservation acceptée : instantané des conditions au moment de l'acceptation.
## Les montants ne changent plus ensuite, même si les données évoluent.
class_name Booking
extends RefCounted

var id := &""
var template_id := &""
var guest_name := ""
var guests := 1
var nights := 1
var nightly_price := 0
var commission_percent := 0
var accepted_at := 0


static func create(booking_id: StringName, template: BookingTemplateDef, percent: int, now: int) -> Booking:
	var b := Booking.new()
	b.id = booking_id
	b.template_id = template.id
	b.guest_name = template.guest_name
	b.guests = template.guests
	b.nights = template.nights
	b.nightly_price = template.nightly_price
	b.commission_percent = percent
	b.accepted_at = now
	return b


## Prix total du séjour payé par les voyageurs.
func revenue() -> int:
	return nights * nightly_price


## Part de la conciergerie, arrondie à l'entier inférieur.
func commission() -> int:
	return revenue() * commission_percent / 100


## Part reversée au propriétaire.
func owner_share() -> int:
	return revenue() - commission()


func to_dict() -> Dictionary:
	return {
		"id": id, "template_id": template_id, "guest_name": guest_name, "guests": guests,
		"nights": nights, "nightly_price": nightly_price,
		"commission_percent": commission_percent, "accepted_at": accepted_at,
	}


static func from_dict(data: Dictionary) -> Booking:
	var b := Booking.new()
	b.id = StringName(data.get("id", ""))
	b.template_id = StringName(data.get("template_id", ""))
	b.guest_name = str(data.get("guest_name", ""))
	b.guests = maxi(int(data.get("guests", 1)), 1)
	b.nights = maxi(int(data.get("nights", 1)), 1)
	b.nightly_price = maxi(int(data.get("nightly_price", 0)), 0)
	b.commission_percent = clampi(int(data.get("commission_percent", 0)), 0, 100)
	b.accepted_at = int(data.get("accepted_at", 0))
	return b
