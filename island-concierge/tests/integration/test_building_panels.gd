## Panneau de chaque rôle de bâtiment, ouvert par un tap simulé.
extends GutTest

var main: Node
var _t := 0


func before_each() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child_autofree(main)
	var bounds: Rect2 = main.map.world_bounds()
	main.camera.setup(bounds, bounds.get_center(), Vector2(1920, 1080))


func _open(uid: StringName) -> BuildingPanel:
	var view: BuildingView = main.map.buildings[uid]
	main.camera.rig.center_on(view.global_position)
	main.camera.rig.set_zoom(1.0)
	var pos: Vector2 = main.camera.rig.world_to_screen(view.global_position)
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.index = 0; e.pressed = pressed; e.position = pos
		_t += 60
		main.camera.handle_input(e, _t)
	return main.panel


func test_every_placement_is_shown_on_the_map() -> void:
	assert_eq(main.map.buildings.size(), main.map.map_def.placements.size())


func test_every_building_opens_its_own_panel() -> void:
	for placement in main.map.map_def.placements:
		var panel := _open(placement.uid)
		assert_true(panel.visible, String(placement.uid))
		assert_eq(panel.title.text, tr(placement.building.name_key))


func test_office_panel() -> void:
	var panel := _open(&"office_1")
	assert_eq(panel.role.text, "Conciergerie")


func test_producer_panel_lists_recipe_and_operator() -> void:
	var panel := _open(&"workshop_1")
	assert_eq(panel.detail_values[&"operator"].text, "Kimo")
	assert_eq(panel.detail_values[&"recipe_craft_welcome_basket"].text,
			"Tresser un panier d'accueil : 1 Panier d'accueil en 1 min")
	assert_eq(_open(&"farm_1").detail_values[&"recipe_harvest_pineapple"].text,
			"Récolter des ananas : 3 Ananas en 30 s")


func test_construction_panel() -> void:
	var panel := _open(&"tiki_site_1")
	assert_eq(panel.detail_values[&"cost"].text, "150 coquillages")
	assert_eq(panel.detail_values[&"level"].text, "2")
	assert_eq(panel.detail_values[&"build_time"].text, "5 min")


func test_locked_corail() -> void:
	var panel := _open(&"corail_1")
	assert_eq(panel.state_chip.text, "Verrouillé")
	assert_eq(panel.detail_values[&"owner"].text, "À découvrir")
	assert_eq(panel.detail_values[&"capacity"].text, "4 voyageurs")
	assert_string_contains(panel.info.text, "Côte Est")
	assert_eq(panel.action_buttons().size(), 0)
	assert_false(panel.actions_title.visible, "pas de section Actions pour un logement verrouillé")
	var r := GameState.perform_lodging_action(&"corail_1", Lodging.Action.ACCEPT_BOOKING)
	assert_eq(r.error, &"lodging_locked")
