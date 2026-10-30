## Affiche un territoire (MapDef) en isométrique et convertit les positions
## écran ↔ cellules. Ne contient aucune règle de jeu : l'état verrouillé des
## zones lui est donné de l'extérieur (set_zone_locked).
class_name WorldMap
extends Node2D

const TERRAIN_SOURCE := 0
const DECOR_SOURCE := 1
const TERRAIN_TILES := {
	MapGrid.Terrain.OCEAN: Vector2i(0, 0),
	MapGrid.Terrain.LAGOON: Vector2i(1, 0),
	MapGrid.Terrain.SAND: Vector2i(2, 0),
	MapGrid.Terrain.GRASS: Vector2i(3, 0),
	MapGrid.Terrain.JUNGLE: Vector2i(0, 1),
	MapGrid.Terrain.PATH: Vector2i(1, 1),
	MapGrid.Terrain.PLOT: Vector2i(2, 1),
}
const LOCKED_TILE := Vector2i(3, 1)
const PALM_TILE := Vector2i(0, 0)
const BUSH_TILE := Vector2i(1, 0)
## Probabilités (palmier, buisson) de décor par terrain.
const DECOR_CHANCES := {
	MapGrid.Terrain.JUNGLE: Vector2(0.65, 0.25),
	MapGrid.Terrain.GRASS: Vector2(0.05, 0.06),
	MapGrid.Terrain.SAND: Vector2(0.06, 0.0),
}
const LockBadge := preload("res://scenes/world/lock_badge.gd")

@export var map_def: MapDef

var grid: MapGrid
var _locked := {}  # StringName (id de zone) -> bool
var _badges := {}  # StringName -> LockBadge
## uid du placement -> BuildingView
var buildings := {}
## id du PNJ -> NpcView
var npcs := {}

@onready var ground: TileMapLayer = $Ground
@onready var decor: TileMapLayer = $Objects/Decor
@onready var zone_overlay: TileMapLayer = $ZoneOverlay
@onready var _badge_root: Node2D = $LockBadges
@onready var _objects: Node2D = $Objects


func _ready() -> void:
	build()


## (Re)construit toutes les couches à partir de map_def.
func build() -> void:
	grid = MapGrid.from_layout(map_def.layout, map_def.size)
	for e in grid.errors:
		push_error("Carte %s : %s" % [map_def.id, e])
	ground.clear()
	for y in grid.size.y:
		for x in grid.size.x:
			var cell := Vector2i(x, y)
			ground.set_cell(cell, TERRAIN_SOURCE, TERRAIN_TILES[grid.terrain_at(cell)])
	_build_decor()
	_spawn_buildings()
	_spawn_npcs()
	_locked.clear()
	for zone in map_def.zones:
		_locked[zone.id] = zone.starts_locked
	_refresh_zones()


func cell_at(world_pos: Vector2) -> Vector2i:
	return ground.local_to_map(ground.to_local(world_pos))


func cell_center(cell: Vector2i) -> Vector2:
	return ground.to_global(ground.map_to_local(cell))


## Rectangle (coordonnées monde) englobant toute la carte.
func world_bounds() -> Rect2:
	var half := Vector2(ground.tile_set.tile_size) / 2.0
	var last := grid.size - Vector2i.ONE
	var rect := Rect2(cell_center(Vector2i.ZERO), Vector2.ZERO)
	for corner in [Vector2i(last.x, 0), Vector2i(0, last.y), last]:
		rect = rect.expand(cell_center(corner))
	return rect.grow_individual(half.x, half.y, half.x, half.y)


## Taille à l'écran des étiquettes, bulles, pastilles et anneaux (1 = taille
## de conception à zoom 1). Ils restent lisibles quel que soit le zoom.
const OVERLAY_SCREEN_SCALE := 0.9
var overlay_scale := 1.0


func set_camera_zoom(zoom: float) -> void:
	overlay_scale = OVERLAY_SCREEN_SCALE / maxf(zoom, 0.01)
	for node in get_tree().get_nodes_in_group(&"screen_sized"):
		if is_ancestor_of(node):
			node.scale = Vector2.ONE * overlay_scale


## Bâtiment touché par une position monde (le plus en avant), ou null.
func building_at(world_pos: Vector2) -> BuildingView:
	var best: BuildingView = null
	for view: BuildingView in buildings.values():
		if view.hit_test(world_pos) and (best == null or view.position.y > best.position.y):
			best = view
	return best


## Rectangle (monde) englobant la terre ferme de l'île.
func land_bounds() -> Rect2:
	var rect := Rect2()
	var first := true
	for y in grid.size.y:
		for x in grid.size.x:
			var cell := Vector2i(x, y)
			if grid.is_land(cell):
				var c := cell_center(cell)
				rect = Rect2(c, Vector2.ZERO) if first else rect.expand(c)
				first = false
	return rect.grow_individual(64, 32, 64, 32)


func is_zone_locked(zone_id: StringName) -> bool:
	return _locked.get(zone_id, false)


func set_zone_locked(zone_id: StringName, locked: bool) -> void:
	_locked[zone_id] = locked
	_refresh_zones()


## Zone verrouillée contenant la cellule, ou null.
func locked_zone_at(cell: Vector2i) -> ZoneDef:
	for zone in map_def.zones:
		if is_zone_locked(zone.id) and zone.rect.has_point(cell):
			return zone
	return null


func _spawn_buildings() -> void:
	for view in buildings.values():
		view.free()
	buildings.clear()
	var map_local := func(cell: Vector2i) -> Vector2: return ground.map_to_local(cell)
	for placement in map_def.placements:
		var view := BuildingView.new()
		_objects.add_child(view)
		view.setup(placement, map_local)
		buildings[placement.uid] = view


func _spawn_npcs() -> void:
	for view in npcs.values():
		view.free()
	npcs.clear()
	for spot in map_def.npc_spots:
		var view := NpcView.new()
		_objects.add_child(view)
		view.setup(spot.npc, ground.map_to_local(spot.cell))
		npcs[spot.npc.id] = view


## Personnage touché par une position monde, ou null.
func npc_at(world_pos: Vector2) -> NpcView:
	for view: NpcView in npcs.values():
		if view.hit_test(world_pos):
			return view
	return null


## Anneaux et stades des bâtiments de production.
func refresh_production_visuals() -> void:
	var at := GameState.now()
	for uid in GameState.producers:
		if not buildings.has(uid):
			continue
		var producer: Producer = GameState.producers[uid]
		var state := producer.slot_state(0, at)
		buildings[uid].show_progress(producer.progress(0, at) if state == Producer.SlotState.RUNNING else -1.0)
	for uid in GameState.constructions:
		if not buildings.has(uid):
			continue
		var site: ConstructionSite = GameState.constructions[uid]
		var view: BuildingView = buildings[uid]
		view.set_def(GameState.building_def_of(uid))
		view.show_progress(site.progress(at) if site.state == ConstructionSite.State.BUILDING else -1.0)


## Fait monter « +texte » au-dessus d'un bâtiment.
func float_reward(uid: StringName, text: String, icon: Texture2D) -> FloatingReward:
	if not buildings.has(uid):
		return null
	var view: BuildingView = buildings[uid]
	var reward := FloatingReward.new()
	reward.add_to_group(&"screen_sized")
	reward.scale = Vector2.ONE * overlay_scale
	reward.position = view.position + Vector2(0, view.top_y())
	_objects.add_child(reward)
	reward.setup(text, icon)
	view.bounce()
	return reward


## Lance l'arrivée (ou le départ) des voyageurs d'un logement.
func play_arrival(uid: StringName, reverse := false) -> ArrivalAnimation:
	var placement: PlacementDef = buildings[uid].placement if buildings.has(uid) else null
	if placement == null or placement.arrival_path.size() < 2:
		return null
	var points := PackedVector2Array()
	for cell in placement.arrival_path:
		points.append(ground.map_to_local(cell))
	var anim := ArrivalAnimation.new()
	_objects.add_child(anim)
	anim.play(points, reverse)
	return anim


func _build_decor() -> void:
	decor.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = map_def.decor_seed
	for y in grid.size.y:
		for x in grid.size.x:
			var cell := Vector2i(x, y)
			var roll := rng.randf()  # tiré pour chaque cellule : décor stable
			var chances: Vector2 = DECOR_CHANCES.get(grid.terrain_at(cell), Vector2.ZERO)
			if roll < chances.x:
				decor.set_cell(cell, DECOR_SOURCE, PALM_TILE)
			elif roll < chances.x + chances.y:
				decor.set_cell(cell, DECOR_SOURCE, BUSH_TILE)


func _refresh_zones() -> void:
	zone_overlay.clear()
	for badge in _badges.values():
		badge.queue_free()
	_badges.clear()
	for zone in map_def.zones:
		if not is_zone_locked(zone.id):
			continue
		for y in range(zone.rect.position.y, zone.rect.end.y):
			for x in range(zone.rect.position.x, zone.rect.end.x):
				if grid.is_land(Vector2i(x, y)):
					zone_overlay.set_cell(Vector2i(x, y), TERRAIN_SOURCE, LOCKED_TILE)
		var badge := LockBadge.new()
		badge.add_to_group(&"screen_sized")
		badge.scale = Vector2.ONE * overlay_scale
		badge.text = tr(zone.name_key)
		badge.position = to_local(cell_center(zone.badge_position()))
		_badge_root.add_child(badge)
		_badges[zone.id] = badge
