## Règles sur les bâtiments posés sur Mahana.
extends GutTest

var map: MapDef
var grid: MapGrid


func before_all() -> void:
	map = load("res://data/maps/mahana.tres")
	grid = MapGrid.from_layout(map.layout, map.size)


func test_hibiscus_is_placed() -> void:
	var found: PlacementDef = null
	for p in map.placements:
		if p.building.id == &"bungalow_hibiscus":
			found = p
	assert_not_null(found)
	assert_eq(found.building.role, BuildingDef.Role.LODGING)
	assert_ne(found.building.lodging.owner_name, "")
	assert_not_null(found.building.texture)


func test_placements_stand_on_plots_outside_locked_zones() -> void:
	for p in map.placements:
		for cell in p.cells():
			assert_true(grid.is_buildable(cell), "%s : cellule %s non constructible" % [p.uid, cell])
			for zone in map.zones:
				if zone.starts_locked:
					assert_false(zone.rect.has_point(cell), "%s dans la zone verrouillée %s" % [p.uid, zone.id])


func test_placements_do_not_overlap_and_uids_are_unique() -> void:
	var used := {}
	var uids := {}
	for p in map.placements:
		assert_false(uids.has(p.uid), "uid en double : %s" % p.uid)
		uids[p.uid] = true
		for cell in p.cells():
			assert_false(used.has(cell), "chevauchement en %s" % cell)
			used[cell] = true


func test_building_names_are_translated() -> void:
	for p in map.placements:
		assert_ne(TranslationServer.translate(p.building.name_key), StringName(p.building.name_key))
