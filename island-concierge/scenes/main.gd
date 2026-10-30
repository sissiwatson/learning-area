## Point d'entrée du jeu : affiche Mahana avec la caméra tactile et gère la
## sélection des bâtiments.
extends Node

var selected: BuildingView

@onready var map: WorldMap = $Mahana
@onready var camera: MapCamera = $Camera
@onready var hud: CanvasLayer = $HUD
@onready var panel: BuildingPanel = %BuildingPanel
@onready var resource_bar: ResourceBar = %ResourceBar
@onready var toasts: ToastStack = %Toasts
@onready var dialogue_box: DialogueBox = %DialogueBox
@onready var quest_banner: QuestBanner = %QuestBanner
@onready var director: QuestDirector = $QuestDirector
## Dernier état connu de chaque logement (pour animer les arrivées réelles,
## pas celles rejouées au chargement d'une sauvegarde).
var _lodging_states := {}


func _ready() -> void:
	# Reprend la partie sauvegardée (minuteurs rattrapés), sinon partie neuve.
	if not SaveManager.load_into_game(map.map_def):
		GameState.new_game(map.map_def)
	resource_bar.rebuild()
	var bounds := map.world_bounds()
	camera.zoom_changed.connect(map.set_camera_zoom)
	frame_island()
	camera.ui_hit_test = hud.is_point_over_ui
	camera.tapped_world.connect(_on_map_tapped)
	panel.closed.connect(_clear_selection)
	panel.open_requested.connect(func(uid): select_building(map.buildings[uid]))
	for signal_ref in [EventBus.lodging_state_changed, EventBus.offers_changed,
			EventBus.production_blocked_changed, EventBus.inventory_changed,
			EventBus.currency_changed, EventBus.xp_changed, EventBus.construction_started]:
		signal_ref.connect(func(_a = null, _b = null): refresh_attention())
	refresh_attention()
	EventBus.level_up.connect(func(lvl): toasts.show_message(tr("TOAST_LEVEL_UP") % lvl, ResourceBar.LEVEL_ICON))
	camera.user_panned.connect(func(): EventBus.game_event.emit(&"camera_panned", &"", 1))
	camera.user_zoomed.connect(func(): EventBus.game_event.emit(&"camera_zoomed", &"", 1))
	quest_banner.go_requested.connect(focus_building)
	for uid in GameState.lodgings:
		_lodging_states[uid] = GameState.lodgings[uid].state
	EventBus.lodging_state_changed.connect(_on_lodging_state_changed)
	EventBus.commission_collected.connect(func(uid, _b, _c): map.play_arrival(uid, true))
	EventBus.ticked.connect(map.refresh_production_visuals)
	EventBus.production_started.connect(func(_u, _r): map.refresh_production_visuals())
	EventBus.production_completed.connect(_on_production_completed)
	EventBus.commission_collected.connect(func(uid, _b, amount):
		map.float_reward(uid, "+%s" % NumberFormat.thousands(amount), GameState.currency_defs[GameState.COMMISSION_CURRENCY].icon))
	EventBus.construction_started.connect(func(_u): map.refresh_production_visuals())
	EventBus.building_built.connect(_on_building_built)
	map.refresh_production_visuals()
	dialogue_box.started.connect(func(_id): panel.close_panel())
	director.setup(dialogue_box, toasts, map)
	quest_banner.refresh()


func select_building(view: BuildingView) -> void:
	if selected and selected != view:
		selected.selected = false
	selected = view
	view.selected = true
	panel.show_placement(view.placement)


## Cadrage initial : toute la terre ferme visible, centrée (quel que soit le
## format de l'écran : 16:9, 20:9, 4:3).
func frame_island(view_size := Vector2.ZERO) -> void:
	var land := map.land_bounds()
	camera.setup(map.world_bounds(), land.get_center(), view_size)
	var view := camera.rig.view_size
	camera.rig.set_zoom(minf(view.x / land.size.x, view.y / land.size.y) * 0.95)
	camera.rig.center_on(land.get_center())
	camera.position = camera.rig.position
	camera.zoom = Vector2.ONE * camera.rig.zoom
	map.set_camera_zoom(camera.rig.zoom)


## Centre la caméra sur le premier bâtiment de ce type et ouvre son panneau.
func focus_building(building_id: StringName) -> void:
	for uid in map.buildings:
		var view: BuildingView = map.buildings[uid]
		if view.placement.building.id == building_id:
			camera.rig.set_zoom(maxf(camera.rig.zoom, 1.0))
			camera.rig.center_on(view.global_position + Vector2(260, 0))
			camera.position = camera.rig.position
			camera.zoom = Vector2.ONE * camera.rig.zoom
			select_building(view)
			return


func _on_building_built(uid: StringName, _building_id: StringName) -> void:
	map.refresh_production_visuals()
	var def := GameState.building_def_of(uid)
	map.buildings[uid].bounce()
	toasts.show_message(tr("TOAST_BUILT") % tr(def.name_key))
	refresh_attention()


func _on_production_completed(uid: StringName, recipe_id: StringName) -> void:
	var recipe: RecipeDef = GameState.recipe_defs[recipe_id]
	for id in recipe.outputs:
		map.float_reward(uid, "+%d" % recipe.outputs[id], GameState.item_defs[id].icon)
	map.refresh_production_visuals()


func _on_lodging_state_changed(uid: StringName, state: int) -> void:
	var before: int = _lodging_states.get(uid, -1)
	_lodging_states[uid] = state
	if before == Lodging.State.READY and state == Lodging.State.OCCUPIED:
		map.play_arrival(uid)


func _on_map_tapped(world_pos: Vector2) -> void:
	# Un personnage est dessiné devant les bâtiments : il est prioritaire
	# (zone de toucher serrée autour de son dessin).
	var npc := map.npc_at(world_pos)
	if npc:
		panel.close_panel()
		if not director.play_for_npc(npc.npc.id):
			npc.say_next()
		return
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
		var def := GameState.building_def_of(uid)
		var needs := false
		if def.role == BuildingDef.Role.LODGING:
			needs = not GameState.get_lodging(uid).available_actions().is_empty()
		elif def.role == BuildingDef.Role.PRODUCER:
			needs = GameState.blocked_producers.has(uid)
		elif def.role == BuildingDef.Role.CONSTRUCTION:
			var c := def.construction
			needs = GameState.constructions[uid].state == ConstructionSite.State.IDLE \
					and GameState.level() >= c.required_level and GameState.wallet.can_afford(c.cost)
		elif def.role == BuildingDef.Role.OFFICE:
			for offer in GameState.bookings.offers:
				needs = needs or GameState.find_lodging_for(offer.template.guests) != &""
		view.attention = needs
