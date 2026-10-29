## Vérifie que les données de la carte de Mahana respectent le brief.
extends GutTest

var map: MapDef
var grid: MapGrid


func before_all() -> void:
	map = load("res://data/maps/mahana.tres")
	grid = MapGrid.from_layout(map.layout, map.size)


func test_map_is_32_by_32_and_valid() -> void:
	assert_eq(map.size, Vector2i(32, 32))
	assert_true(grid.is_valid(), str(grid.errors))


func test_island_is_surrounded_by_water() -> void:
	for i in 32:
		for cell in [Vector2i(i, 0), Vector2i(i, 31), Vector2i(0, i), Vector2i(31, i)]:
			assert_false(grid.is_land(cell), "bord de carte en terre : %s" % cell)


func test_all_required_terrains_are_present() -> void:
	for t in [MapGrid.Terrain.OCEAN, MapGrid.Terrain.LAGOON, MapGrid.Terrain.SAND,
			MapGrid.Terrain.GRASS, MapGrid.Terrain.JUNGLE, MapGrid.Terrain.PATH,
			MapGrid.Terrain.PLOT]:
		assert_gt(grid.cells_of(t).size(), 0, "terrain absent : %s" % MapGrid.Terrain.keys()[t])


func test_zones_are_inside_map_and_do_not_overlap() -> void:
	var map_rect := Rect2i(Vector2i.ZERO, map.size)
	assert_gt(map.zones.size(), 0)
	for i in map.zones.size():
		var a := map.zones[i]
		assert_true(map_rect.encloses(a.rect), "zone hors carte : %s" % a.id)
		for j in range(i + 1, map.zones.size()):
			assert_false(a.rect.intersects(map.zones[j].rect), "zones superposées : %s / %s" % [a.id, map.zones[j].id])


func test_zone_ids_are_unique_and_translated() -> void:
	var seen := {}
	for zone in map.zones:
		assert_false(seen.has(zone.id), "id en double : %s" % zone.id)
		seen[zone.id] = true
		assert_ne(TranslationServer.translate(zone.name_key), StringName(zone.name_key),
				"traduction manquante : %s" % zone.name_key)


func test_each_locked_zone_contains_a_plot() -> void:
	for zone in map.zones:
		var found := false
		for cell in grid.cells_of(MapGrid.Terrain.PLOT):
			found = found or zone.rect.has_point(cell)
		assert_true(found, "zone sans parcelle : %s" % zone.id)


func test_plots_exist_outside_locked_zones() -> void:
	var free := 0
	for cell in grid.cells_of(MapGrid.Terrain.PLOT):
		var in_zone := false
		for zone in map.zones:
			in_zone = in_zone or zone.rect.has_point(cell)
		if not in_zone:
			free += 1
	assert_gt(free, 0)
