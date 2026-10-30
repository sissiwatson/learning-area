## Offres du bureau : rotation déterministe, rythme, anti-blocage.
extends GutTest

var templates: Array[BookingTemplateDef] = []
var sys: BookingSystem


func _tpl(id: StringName, guests: int) -> BookingTemplateDef:
	var t := BookingTemplateDef.new()
	t.id = id; t.guest_name = String(id); t.guests = guests
	return t


func before_each() -> void:
	templates = [_tpl(&"a", 2), _tpl(&"b", 1), _tpl(&"family", 4), _tpl(&"c", 2)]
	sys = BookingSystem.new(templates, 2, 60)


func _ids() -> Array:
	return sys.offers.map(func(o): return o.template.id)


func test_first_offer_appears_immediately_then_one_per_refresh() -> void:
	sys.update(1000, 2)
	assert_eq(_ids(), [&"a"])
	sys.update(1059, 2)
	assert_eq(_ids(), [&"a"])
	sys.update(1060, 2)
	assert_eq(_ids(), [&"a", &"b"])
	sys.update(5000, 2)
	assert_eq(sys.offers.size(), 2, "jamais plus que max_offers")


func test_rotation_skips_templates_without_a_suitable_lodging() -> void:
	sys.update(0, 2)
	sys.take_offer(sys.offers[0].id, 20, 0)
	sys.update(0, 2)
	sys.take_offer(sys.offers[0].id, 20, 0)
	sys.update(0, 2)
	assert_eq(_ids(), [&"c"], "« family » (4 voyageurs) est sauté")
	sys.take_offer(sys.offers[0].id, 20, 0)
	sys.update(0, 4)
	assert_eq(_ids(), [&"a"])


func test_same_inputs_give_same_offers() -> void:
	var other := BookingSystem.new(templates, 2, 60)
	for t in [0, 30, 60, 61, 500]:
		sys.update(t, 2)
		other.update(t, 2)
	assert_eq(sys.to_dict(), other.to_dict())


func test_never_empty_while_a_lodging_can_host() -> void:
	sys.update(0, 2)
	for i in 10:
		var r := sys.take_offer(sys.offers[0].id, 20, i)
		assert_true(r.ok)
		sys.update(i, 2)
		assert_gt(sys.offers.size(), 0, "anti-blocage : une offre réapparaît aussitôt")


func test_no_offer_when_no_lodging_can_host() -> void:
	sys.update(0, 0)
	assert_eq(sys.offers.size(), 0)
	sys.update(10, 2)
	assert_eq(sys.offers.size(), 1, "réapparaît dès qu'un logement se libère")


func test_take_offer_creates_frozen_booking_with_unique_ids() -> void:
	sys.update(0, 2)
	sys.update(60, 2)
	var first: Booking = sys.take_offer(sys.offers[0].id, 20, 5).value
	var second: Booking = sys.take_offer(sys.offers[0].id, 20, 6).value
	assert_ne(first.id, second.id)
	assert_eq(first.template_id, &"a")
	assert_eq(first.accepted_at, 5)
	assert_eq(sys.take_offer(&"offer_9999", 20, 7).error, &"unknown_offer")


func test_seconds_to_next_offer() -> void:
	sys.update(1000, 2)
	assert_eq(sys.seconds_to_next_offer(1010), 50)
	sys.update(1060, 2)
	assert_eq(sys.seconds_to_next_offer(1061), 0, "liste pleine")


func test_round_trip() -> void:
	sys.update(0, 2)
	sys.update(60, 2)
	var copy := BookingSystem.new(templates, 2, 60)
	copy.load_dict(JSON.parse_string(JSON.stringify(sys.to_dict())))
	assert_eq(copy.to_dict(), sys.to_dict())
	assert_eq(copy.offers[1].template, templates[1])
