## Point d'entrée du jeu : affiche Mahana avec la caméra tactile et gère la
## sélection des bâtiments.
extends Node

var selected: BuildingView

@onready var map: WorldMap = $Mahana
@onready var camera: MapCamera = $Camera
@onready var hud: CanvasLayer = $HUD
@onready var panel: BuildingPanel = %BuildingPanel
@onready var resource_bar: ResourceBar = %ResourceBar


func _ready() -> void:
	# Partie neuve à chaque lancement tant que la sauvegarde n'existe pas (étape 9).
	GameState.new_game(map.map_def)
	resource_bar.rebuild()
	var bounds := map.world_bounds()
	# Vue initiale entre le centre de l'île et le premier bungalow.
	var focus := bounds.get_center()
	if map.buildings.has(&"hibiscus_1"):
		focus = focus.lerp(map.buildings[&"hibiscus_1"].global_position, 0.5)
	camera.setup(bounds, focus)
	camera.ui_hit_test = hud.is_point_over_ui
	camera.tapped_world.connect(_on_map_tapped)
	panel.closed.connect(_clear_selection)
	panel.open_requested.connect(func(uid): select_building(map.buildings[uid]))
	for signal_ref in [EventBus.lodging_state_changed, EventBus.offers_changed]:
		signal_ref.connect(func(_a = null, _b = null): refresh_attention())
	refresh_attention()


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


## Pastilles « ! » : logements où le joueur doit agir, bureau quand une offre
## peut être acceptée.
func refresh_attention() -> void:
	for uid in map.buildings:
		var view: BuildingView = map.buildings[uid]
		var def := view.placement.building
		var needs := false
		if def.role == BuildingDef.Role.LODGING:
			needs = not GameState.get_lodging(uid).available_actions().is_empty()
		elif def.role == BuildingDef.Role.OFFICE:
			for offer in GameState.bookings.offers:
				needs = needs or GameState.find_lodging_for(offer.template.guests) != &""
		view.attention = needs
