## Point d'entrée du jeu : affiche Mahana avec la caméra tactile et gère la
## sélection des bâtiments.
extends Node

var selected: BuildingView

@onready var map: WorldMap = $Mahana
@onready var camera: MapCamera = $Camera
@onready var hud: CanvasLayer = $HUD
@onready var panel: BuildingPanel = %BuildingPanel
@onready var _title: Label = %Title


func _ready() -> void:
	# Partie neuve à chaque lancement tant que la sauvegarde n'existe pas (étape 9).
	GameState.new_game(map.map_def)
	_title.text = tr("APP_TITLE")
	var bounds := map.world_bounds()
	# Vue initiale entre le centre de l'île et le premier bungalow.
	var focus := bounds.get_center()
	if map.buildings.has(&"hibiscus_1"):
		focus = focus.lerp(map.buildings[&"hibiscus_1"].global_position, 0.5)
	camera.setup(bounds, focus)
	camera.ui_hit_test = hud.is_point_over_ui
	camera.tapped_world.connect(_on_map_tapped)
	panel.closed.connect(_clear_selection)


func select_building(view: BuildingView) -> void:
	if selected and selected != view:
		selected.selected = false
	selected = view
	view.selected = true
	panel.show_placement(view.placement)


func _on_map_tapped(world_pos: Vector2) -> void:
	var view := map.building_at(world_pos)
	if view:
		select_building(view)
	else:
		panel.close_panel()


func _clear_selection() -> void:
	if selected:
		selected.selected = false
	selected = null
