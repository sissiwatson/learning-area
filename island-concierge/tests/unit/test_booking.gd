## Montants d'une réservation : prix, commission, part du propriétaire.
extends GutTest


func _tpl(nights: int, price: int, guests := 2) -> BookingTemplateDef:
	var t := BookingTemplateDef.new()
	t.id = &"t"; t.guest_name = "X"; t.nights = nights; t.nightly_price = price; t.guests = guests
	return t


func test_tutorial_commission() -> void:
	var b := Booking.create(&"bk_1", _tpl(2, 300), 20, 0)
	assert_eq(b.revenue(), 600)
	assert_eq(b.commission(), 120)
	assert_eq(b.owner_share(), 480)


func test_all_mahana_templates() -> void:
	var expected := {&"couple_camille_noe": [600, 120], &"solo_lea": [250, 50],
			&"friends_amaru": [840, 168], &"family_morel": [900, 180]}
	for tpl in Database.catalog["bookings"]:
		var b := Booking.create(&"x", tpl, 20, 0)
		assert_eq([b.revenue(), b.commission()], expected[tpl.id], String(tpl.id))


func test_commission_is_rounded_down() -> void:
	var b := Booking.create(&"bk", _tpl(1, 333), 15, 0)
	assert_eq(b.commission(), 49, "333 × 15 % = 49,95 -> 49")
	assert_eq(b.commission() + b.owner_share(), b.revenue(), "rien ne se perd")


func test_amounts_are_frozen_at_acceptance() -> void:
	var tpl := _tpl(2, 300)
	var b := Booking.create(&"bk", tpl, 20, 0)
	tpl.nightly_price = 1000
	tpl.nights = 9
	assert_eq(b.revenue(), 600)
	assert_eq(b.commission(), 120)


func test_round_trip_and_sanitizing() -> void:
	var b := Booking.create(&"bk_7", _tpl(3, 280), 20, 123)
	var copy := Booking.from_dict(JSON.parse_string(JSON.stringify(b.to_dict())))
	assert_eq(copy.to_dict(), b.to_dict())
	var bad := Booking.from_dict({"nights": -2, "nightly_price": -10, "commission_percent": 500})
	assert_eq(bad.nights, 1)
	assert_eq(bad.nightly_price, 0)
	assert_eq(bad.commission_percent, 100)
