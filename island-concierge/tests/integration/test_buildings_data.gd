## Règles de conception sur les bâtiments posés sur Mahana.
extends GutTest

var map: MapDef


func before_all() -> void:
	map = load("res://data/maps/mahana.tres")


func _placement(building_id: StringName) -> PlacementDef:
	for p in map.placements:
		if p.building.id == building_id:
			return p
	return null


func test_all_brief_buildings_are_on_mahana() -> void:
	for id in [&"concierge_office", &"bungalow_hibiscus", &"bungalow_corail", &"pineapple_farm",
			&"amenities_workshop", &"tiki_bar_site"]:
		assert_not_null(_placement(id), "absent de la carte : %s" % id)


func test_hibiscus_is_available_and_owned_by_hina() -> void:
	var p := _placement(&"bungalow_hibiscus")
	assert_null(map.zone_at(p.cell), "le Bungalow Hibiscus doit être disponible dès le départ")
	assert_eq(p.building.lodging.owner.id, &"npc_hina")


func test_corail_is_in_a_locked_zone() -> void:
	var zone := map.zone_at(_placement(&"bungalow_corail").cell)
	assert_not_null(zone)
	assert_true(zone.starts_locked)


func test_core_loop_buildings_are_not_locked() -> void:
	for id in [&"concierge_office", &"pineapple_farm", &"amenities_workshop", &"tiki_bar_site"]:
		assert_null(map.zone_at(_placement(id).cell), "%s ne doit pas être verrouillé" % id)


func test_tiki_site_matches_tutorial_economy() -> void:
	var c := _placement(&"tiki_bar_site").building.construction
	assert_eq(c.cost, {&"shells": 150})
	assert_eq(c.required_level, 2)
	assert_eq(c.builds_into.id, &"tiki_bar")
