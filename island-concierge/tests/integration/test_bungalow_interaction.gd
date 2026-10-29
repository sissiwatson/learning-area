## Sélection du Bungalow Hibiscus par un tap simulé et utilisation du panneau.
extends GutTest

var main: Node
var cam: MapCamera
var _t := 0


func before_each() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child_autofree(main)
	var bounds: Rect2 = main.map.world_bounds()
	cam = main.camera
	cam.setup(bounds, bounds.get_center(), Vector2(1920, 1080))


func _tap(screen_pos: Vector2) -> void:
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.index = 0; e.pressed = pressed; e.position = screen_pos
		_t += 60
		cam.handle_input(e, _t)


func _hibiscus() -> BuildingView:
	return main.map.buildings[&"hibiscus_1"]


func _screen_of(world: Vector2) -> Vector2:
	return cam.rig.world_to_screen(world)


func test_tap_on_footprint_opens_panel() -> void:
	_tap(_screen_of(_hibiscus().global_position))
	var panel: BuildingPanel = main.panel
	assert_true(panel.visible)
	assert_true(_hibiscus().selected)
	assert_eq(panel.title.text, "Bungalow Hibiscus")
	assert_eq(panel.owner_value.text, "Hina Tehani")
	assert_eq(panel.capacity_value.text, "2 voyageurs")
	assert_eq(panel.state_chip.text, "Libre")
	var buttons := panel.action_buttons()
	assert_eq(buttons.size(), 1)
	assert_eq(buttons[0].text, "Accepter une réservation")
	assert_gte(buttons[0].custom_minimum_size.y, 96.0, "bouton assez grand pour le doigt")


func test_tap_on_roof_selects_building() -> void:
	# Le toit dépasse au-dessus de l'emprise : 110 px au-dessus du pied.
	_tap(_screen_of(_hibiscus().global_position + Vector2(0, -110)))
	assert_true(main.panel.visible)


func test_tap_next_to_building_selects_nothing() -> void:
	_tap(_screen_of(_hibiscus().global_position + Vector2(0, -400)))
	assert_false(main.panel.visible)
	assert_false(_hibiscus().selected)


func test_action_updates_state_and_panel() -> void:
	_tap(_screen_of(_hibiscus().global_position))
	var panel: BuildingPanel = main.panel
	panel.action_buttons()[0].pressed.emit()
	assert_eq(GameState.get_lodging(&"hibiscus_1").state, Lodging.State.BOOKED)
	assert_eq(panel.state_chip.text, "Réservé")
	assert_eq(panel.action_buttons()[0].text, "Préparer le bungalow")


func test_full_cycle_through_panel() -> void:
	_tap(_screen_of(_hibiscus().global_position))
	var panel: BuildingPanel = main.panel
	for i in 5:
		panel.action_buttons()[0].pressed.emit()
	assert_eq(GameState.get_lodging(&"hibiscus_1").state, Lodging.State.VACANT)
	assert_eq(panel.state_chip.text, "Libre")


func test_refused_action_shows_error() -> void:
	_tap(_screen_of(_hibiscus().global_position))
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.WELCOME_GUESTS)
	assert_true(main.panel.error_label.visible)
	assert_eq(main.panel.error_label.text, "Action impossible dans l'état actuel")


func test_tap_elsewhere_closes_panel_and_deselects() -> void:
	_tap(_screen_of(_hibiscus().global_position))
	_tap(Vector2(400, 300) if not main.map.building_at(cam.rig.screen_to_world(Vector2(400, 300))) else Vector2(10, 1000))
	assert_false(main.panel.visible)
	assert_false(_hibiscus().selected)


func test_close_button_deselects() -> void:
	_tap(_screen_of(_hibiscus().global_position))
	main.panel.close_button.pressed.emit()
	assert_false(main.panel.visible)
	assert_false(_hibiscus().selected)


func test_touch_on_panel_does_not_reach_map() -> void:
	_tap(_screen_of(_hibiscus().global_position))
	var panel_rect: Rect2 = main.panel.get_global_rect()
	var start := cam.position
	var inside := panel_rect.get_center()
	var e := InputEventScreenTouch.new()
	e.index = 0; e.pressed = true; e.position = inside
	cam.handle_input(e, 1000)
	var d := InputEventScreenDrag.new()
	d.index = 0
	for k in range(1, 11):
		d.position = inside + Vector2(-40 * k, 0)
		cam.handle_input(d, 1000 + 16 * k)
	e.pressed = false; e.position = d.position
	cam.handle_input(e, 1400)
	assert_eq(cam.position, start, "glisser sur le panneau ne déplace pas la carte")
	assert_true(main.panel.visible, "toucher le panneau ne le ferme pas")
