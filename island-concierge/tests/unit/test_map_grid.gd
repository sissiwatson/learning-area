extends GutTest

const SMALL := """
~~~~
~.,~
~#+~
~~~~
"""


func test_parses_valid_layout() -> void:
	var grid := MapGrid.from_layout(SMALL, Vector2i(4, 4))
	assert_true(grid.is_valid(), str(grid.errors))
	assert_eq(grid.terrain_at(Vector2i(0, 0)), MapGrid.Terrain.OCEAN)
	assert_eq(grid.terrain_at(Vector2i(1, 1)), MapGrid.Terrain.SAND)
	assert_eq(grid.terrain_at(Vector2i(2, 1)), MapGrid.Terrain.GRASS)
	assert_eq(grid.terrain_at(Vector2i(1, 2)), MapGrid.Terrain.PATH)
	assert_eq(grid.terrain_at(Vector2i(2, 2)), MapGrid.Terrain.PLOT)


func test_outside_of_map_is_ocean() -> void:
	var grid := MapGrid.from_layout(SMALL, Vector2i(4, 4))
	assert_false(grid.has_cell(Vector2i(-1, 0)))
	assert_false(grid.has_cell(Vector2i(4, 0)))
	assert_eq(grid.terrain_at(Vector2i(10, 10)), MapGrid.Terrain.OCEAN)


func test_only_plots_are_buildable() -> void:
	var grid := MapGrid.from_layout(SMALL, Vector2i(4, 4))
	assert_true(grid.is_buildable(Vector2i(2, 2)))
	assert_false(grid.is_buildable(Vector2i(1, 1)))
	assert_false(grid.is_buildable(Vector2i(0, 0)))


func test_land_excludes_water() -> void:
	var grid := MapGrid.from_layout("~-.T", Vector2i(4, 1))
	assert_false(grid.is_land(Vector2i(0, 0)))
	assert_false(grid.is_land(Vector2i(1, 0)))
	assert_true(grid.is_land(Vector2i(2, 0)))
	assert_true(grid.is_land(Vector2i(3, 0)))


func test_windows_line_endings_are_accepted() -> void:
	var grid := MapGrid.from_layout("~.\r\n,~\r\n", Vector2i(2, 2))
	assert_true(grid.is_valid(), str(grid.errors))


func test_wrong_row_count_is_reported() -> void:
	var grid := MapGrid.from_layout("~~\n~~", Vector2i(2, 3))
	assert_false(grid.is_valid())


func test_wrong_row_length_is_reported() -> void:
	var grid := MapGrid.from_layout("~~\n~", Vector2i(2, 2))
	assert_false(grid.is_valid())


func test_unknown_character_is_reported() -> void:
	var grid := MapGrid.from_layout("~X", Vector2i(2, 1))
	assert_false(grid.is_valid())
	assert_string_contains(grid.errors[0], "'X'")


func test_cells_of_terrain() -> void:
	var grid := MapGrid.from_layout(SMALL, Vector2i(4, 4))
	assert_eq(grid.cells_of(MapGrid.Terrain.PLOT), [Vector2i(2, 2)] as Array[Vector2i])
	assert_eq(grid.cells_of(MapGrid.Terrain.OCEAN).size(), 12)
