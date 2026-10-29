## Instancie la scène de Mahana et vérifie le rendu des couches et les
## conversions écran ↔ cellule.
extends GutTest

var world: WorldMap


func before_each() -> void:
	world = load("res://scenes/world/mahana.tscn").instantiate()
	add_child_autofree(world)


func test_ground_has_one_tile_per_cell() -> void:
	assert_eq(world.ground.get_used_cells().size(), 32 * 32)


func test_ground_tiles_match_terrain() -> void:
	for cell in [Vector2i(0, 0), Vector2i(16, 10), Vector2i(12, 9), Vector2i(7, 24)]:
		var expected: Vector2i = WorldMap.TERRAIN_TILES[world.grid.terrain_at(cell)]
		assert_eq(world.ground.get_cell_atlas_coords(cell), expected, "cellule %s" % cell)


func test_tileset_is_isometric() -> void:
	assert_eq(world.ground.tile_set.tile_shape, TileSet.TILE_SHAPE_ISOMETRIC)
	assert_eq(world.ground.tile_set.tile_size, Vector2i(128, 64))


func test_cell_world_round_trip_for_every_cell() -> void:
	var failures := 0
	for y in 32:
		for x in 32:
			var cell := Vector2i(x, y)
			if world.cell_at(world.cell_center(cell)) != cell:
				failures += 1
	assert_eq(failures, 0)


func test_point_near_tile_corner_maps_to_that_tile() -> void:
	var c := world.cell_center(Vector2i(10, 10))
	assert_eq(world.cell_at(c + Vector2(50, 0)), Vector2i(10, 10))
	assert_eq(world.cell_at(c + Vector2(0, 24)), Vector2i(10, 10))


func test_world_bounds_contain_all_cell_centers() -> void:
	var bounds := world.world_bounds()
	for cell in [Vector2i(0, 0), Vector2i(31, 0), Vector2i(0, 31), Vector2i(31, 31)]:
		assert_true(bounds.has_point(world.cell_center(cell)))


func test_decor_only_on_vegetation_or_sand_and_is_stable() -> void:
	var used := world.decor.get_used_cells()
	assert_gt(used.size(), 0)
	for cell in used:
		assert_true(world.grid.terrain_at(cell) in WorldMap.DECOR_CHANCES, "décor sur %s" % cell)
	world.build()
	assert_eq(world.decor.get_used_cells(), used, "le décor change à la reconstruction")


func test_locked_zones_are_overlaid_on_land_only() -> void:
	for cell in world.zone_overlay.get_used_cells():
		assert_true(world.grid.is_land(cell), "voile sur l'eau : %s" % cell)
		assert_not_null(world.locked_zone_at(cell))


func test_unlocking_a_zone_removes_its_overlay() -> void:
	var zone: ZoneDef = world.map_def.zones[0]
	var inside := zone.rect.get_center()
	assert_not_null(world.locked_zone_at(inside))
	world.set_zone_locked(zone.id, false)
	assert_null(world.locked_zone_at(inside))
	for cell in world.zone_overlay.get_used_cells():
		assert_false(zone.rect.has_point(cell))
