## Panneaux de la plantation et de l'atelier, avec taps simulés.
extends GutTest

const FakeClock := preload("res://tests/helpers/fake_clock.gd")

var main: Node
var clock: FakeClock
var _t := 0


func before_each() -> void:
	clock = FakeClock.new()
	GameState.clock = clock
	main = load("res://scenes/main.tscn").instantiate()
	add_child_autofree(main)
	main.camera.setup(main.map.world_bounds(), main.map.world_bounds().get_center(), Vector2(1920, 1080))
	# Le dialogue d'ouverture démarre à la frame suivante et fermerait le panneau.
	await get_tree().process_frame
	while main.dialogue_box.visible:
		main.dialogue_box.skip()


func after_each() -> void:
	GameState.clock = Clock.new()


func _open(uid: StringName) -> BuildingPanel:
	var view: BuildingView = main.map.buildings[uid]
	main.camera.rig.center_on(view.global_position)
	var pos: Vector2 = main.camera.rig.world_to_screen(view.global_position)
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.index = 0; e.pressed = pressed; e.position = pos
		_t += 60
		main.camera.handle_input(e, _t)
	return main.panel


func _advance(seconds: int) -> void:
	clock.advance(seconds)
	GameState.tick()
	main.panel._on_second()


func test_farm_panel_harvest() -> void:
	var panel := _open(&"farm_1")
	assert_eq(panel.detail_values[&"inputs_harvest_pineapple"].text, "Gratuit")
	var button: Button = panel.actions.get_node("Start_harvest_pineapple")
	assert_eq(button.text, "Lancer (30 s)")
	button.pressed.emit()
	await get_tree().process_frame
	button = panel.actions.get_node("Start_harvest_pineapple")
	assert_true(button.disabled)
	assert_eq(button.text, "Production en cours")
	_advance(10)
	assert_eq(panel.progress_label.text, "Récolter des ananas : encore 20 s")
	_advance(20)
	assert_eq(main.resource_bar.amount_labels[&"pineapple"].text, "3")
	assert_false(panel.actions.get_node("Start_harvest_pineapple").disabled)


func test_workshop_panel_shows_missing_inputs() -> void:
	var panel := _open(&"workshop_1")
	var button: Button = panel.actions.get_node("Start_craft_welcome_basket")
	assert_true(button.disabled)
	assert_eq(button.text, "Il manque : 3 Ananas")
	GameState.add_items({&"pineapple": 3})
	button = panel.actions.get_node("Start_craft_welcome_basket")
	assert_false(button.disabled)
	assert_eq(button.text, "Lancer (1 min)")


func test_blocked_production_badge_and_message() -> void:
	GameState.add_items({&"pineapple": 49})
	GameState.start_production(&"farm_1", &"harvest_pineapple")
	_advance(30)
	assert_true(main.map.buildings[&"farm_1"].attention, "pastille : production en attente")
	var panel := _open(&"farm_1")
	assert_eq(panel.info.text, "Inventaire plein : la production attend qu'une place se libère.")


func test_panels_keep_their_width_while_producing() -> void:
	GameState.add_items({&"pineapple": 3})
	GameState.start_production(&"workshop_1", &"craft_welcome_basket")
	GameState.start_production(&"farm_1", &"harvest_pineapple")
	for uid in [&"workshop_1", &"farm_1"]:
		var panel := _open(uid)
		_advance(1)
		for i in 3:
			await get_tree().process_frame
		assert_eq(panel.size.x, 668.0, String(uid))


func test_disabled_button_text_is_readable() -> void:
	var theme: Theme = load("res://scenes/ui/theme.tres")
	var text := theme.get_color(&"font_disabled_color", &"Button")
	var bg := (theme.get_stylebox(&"disabled", &"Button") as StyleBoxFlat).bg_color
	# Rapport de contraste WCAG >= 4,5 pour du texte courant.
	var lum := func(c: Color) -> float:
		var f := func(v: float) -> float: return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
		return 0.2126 * f.call(c.r) + 0.7152 * f.call(c.g) + 0.0722 * f.call(c.b)
	var a: float = lum.call(text)
	var b: float = lum.call(bg)
	assert_gte((maxf(a, b) + 0.05) / (minf(a, b) + 0.05), 4.5)
