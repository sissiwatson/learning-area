## Parcours du joueur par les panneaux : bureau -> bungalow -> encaissement,
## avec taps simulés et horloge simulée.
extends GutTest

const FakeClock := preload("res://tests/helpers/fake_clock.gd")

var main: Node
var cam: MapCamera
var clock: FakeClock
var _t := 0


func before_each() -> void:
	clock = FakeClock.new()
	GameState.clock = clock
	main = load("res://scenes/main.tscn").instantiate()
	add_child_autofree(main)
	var bounds: Rect2 = main.map.world_bounds()
	cam = main.camera
	cam.setup(bounds, bounds.get_center(), Vector2(1920, 1080))


func after_each() -> void:
	GameState.clock = Clock.new()


func _tap(screen_pos: Vector2) -> void:
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.index = 0; e.pressed = pressed; e.position = screen_pos
		_t += 60
		cam.handle_input(e, _t)


func _view(uid: StringName) -> BuildingView:
	return main.map.buildings[uid]


func _tap_building(uid: StringName, offset := Vector2.ZERO) -> BuildingPanel:
	cam.rig.center_on(_view(uid).global_position)
	_tap(cam.rig.world_to_screen(_view(uid).global_position + offset))
	return main.panel


func _advance(seconds: int) -> void:
	clock.advance(seconds)
	GameState.tick()


func _press(button_name: String) -> void:
	var button := main.panel.actions.get_node(button_name) as Button
	assert_not_null(button, "bouton %s" % button_name)
	button.pressed.emit()


func test_vacant_bungalow_panel() -> void:
	var panel := _tap_building(&"hibiscus_1")
	assert_true(panel.visible)
	assert_true(_view(&"hibiscus_1").selected)
	assert_eq(panel.title.text, "Bungalow Hibiscus")
	assert_eq(panel.detail_values[&"owner"].text, "Hina Tehani")
	assert_eq(panel.detail_values[&"capacity"].text, "2 voyageurs")
	assert_eq(panel.state_chip.text, "Libre")
	assert_eq(panel.action_buttons()[0].text, "Voir les réservations")
	assert_gte(panel.action_buttons()[0].custom_minimum_size.y, 96.0, "bouton assez grand pour le doigt")


func test_tap_on_roof_selects_building() -> void:
	_tap_building(&"hibiscus_1", Vector2(0, -110))
	assert_true(main.panel.visible)


func test_tap_next_to_building_selects_nothing() -> void:
	_tap_building(&"hibiscus_1", Vector2(0, -400))
	assert_false(main.panel.visible)


func test_full_loop_through_the_panels() -> void:
	var panel := _tap_building(&"hibiscus_1")
	_press("Action_OPEN_OFFICE")
	assert_eq(panel.title.text, "Bureau de conciergerie", "le bouton ouvre le bureau")
	assert_true(_view(&"office_1").attention, "pastille : une offre attend")
	panel.offer_buttons()[0].pressed.emit()
	assert_eq(GameState.get_lodging(&"hibiscus_1").state, Lodging.State.BOOKED)

	panel = _tap_building(&"hibiscus_1")
	assert_eq(panel.state_chip.text, "Réservé")
	assert_eq(panel.detail_values[&"guests"].text, "Camille et Noé (2)")
	assert_eq(panel.detail_values[&"stay"].text, "2 nuits · 600 coquillages")
	assert_eq(panel.detail_values[&"commission"].text, "120 coquillages (20 %)")
	assert_eq(panel.detail_values[&"owner_share"].text, "480")
	assert_true(panel.action_buttons()[0].disabled, "pas de panier : ménage impossible")
	assert_eq(panel.action_buttons()[0].text, "Il manque : 1 Panier d'accueil")
	assert_eq(panel.info.text, "Le ménage demande : 1 Panier d'accueil")
	GameState.add_items({&"welcome_basket": 1})
	assert_false(panel.action_buttons()[0].disabled, "le panneau se met à jour avec l'inventaire")
	assert_eq(panel.action_buttons()[0].text, "Faire le ménage (2 min)")
	assert_true(_view(&"hibiscus_1").attention)
	_press("Action_PREPARE")

	assert_eq(panel.state_chip.text, "Ménage en cours")
	assert_false(_view(&"hibiscus_1").attention, "rien à faire pendant le ménage")
	_advance(30)
	panel._on_second()
	assert_eq(panel.progress_label.text, "Ménage : encore 1 min 30 s")
	assert_almost_eq(panel.progress.value, 25.0, 0.01)
	_advance(90)
	assert_eq(panel.state_chip.text, "Prêt à accueillir")
	_press("Action_WELCOME_GUESTS")

	_advance(330)
	panel._on_second()
	assert_eq(panel.progress_label.text, "Nuit 2/2 : encore 4 min 30 s")
	_advance(270)
	assert_eq(panel.state_chip.text, "Séjour terminé")
	assert_true(_view(&"hibiscus_1").attention)
	assert_eq(panel.action_buttons()[0].text, "Encaisser 120 coquillages")
	_press("Action_COLLECT_COMMISSION")

	assert_eq(main.resource_bar.amount_labels[&"shells"].text, "170")
	assert_eq(panel.state_chip.text, "Libre")


func test_refused_action_shows_error() -> void:
	_tap_building(&"hibiscus_1")
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.WELCOME_GUESTS)
	assert_true(main.panel.error_label.visible)
	assert_eq(main.panel.error_label.text, "Action impossible dans l'état actuel")


func test_office_offer_without_free_lodging_is_disabled() -> void:
	_advance(60)  # deux offres
	GameState.accept_offer(GameState.bookings.offers[0].id)
	var panel := _tap_building(&"office_1")
	var buttons := panel.offer_buttons()
	assert_gt(buttons.size(), 0)
	assert_true(buttons[0].disabled)
	assert_eq(buttons[0].text, "Aucun logement libre adapté")
	assert_false(_view(&"office_1").attention)


func test_close_and_tap_elsewhere() -> void:
	_tap_building(&"hibiscus_1")
	main.panel.close_button.pressed.emit()
	assert_false(main.panel.visible)
	assert_false(_view(&"hibiscus_1").selected)
	_tap_building(&"hibiscus_1")
	_tap(Vector2(10, 1000))
	assert_false(main.panel.visible)


func test_touch_on_panel_does_not_reach_map() -> void:
	_tap_building(&"hibiscus_1")
	var start := cam.position
	var inside: Vector2 = main.panel.get_global_rect().get_center()
	var e := InputEventScreenTouch.new()
	e.index = 0; e.pressed = true; e.position = inside
	cam.handle_input(e, 10_000)
	var d := InputEventScreenDrag.new()
	d.index = 0
	for k in range(1, 11):
		d.position = inside + Vector2(-40 * k, 0)
		cam.handle_input(d, 10_000 + 16 * k)
	e.pressed = false; e.position = d.position
	cam.handle_input(e, 10_400)
	assert_eq(cam.position, start)
	assert_true(main.panel.visible)


func test_panel_always_fits_on_screen() -> void:
	GameState.accept_offer(GameState.bookings.offers[0].id)
	var panel := _tap_building(&"hibiscus_1")
	await get_tree().process_frame
	await get_tree().process_frame
	var screen := panel.get_viewport_rect()
	assert_true(screen.encloses(panel.get_global_rect()), "panneau %s dans l'écran %s" % [panel.get_global_rect(), screen])
	var button: Button = panel.action_buttons()[0]
	assert_true(screen.encloses(button.get_global_rect()), "bouton principal visible sans défiler")


func test_singular_and_plural() -> void:
	assert_eq(BuildingPanel._count("NIGHTS", 1), "1 nuit")
	assert_eq(BuildingPanel._count("NIGHTS", 3), "3 nuits")
	assert_eq(BuildingPanel._count("TRAVELERS", 1), "1 voyageur")
	_advance(60)
	var panel := _tap_building(&"office_1")
	var lines := []
	for card in panel.offers_box.get_children():
		if card is VBoxContainer:
			lines.append((card.get_child(0) as Label).text)
	assert_eq(lines, ["Camille et Noé · 2 voyageurs · 2 nuits", "Léa · 1 voyageur · 1 nuit"])


func test_panel_shrinks_back_after_a_long_content() -> void:
	GameState.accept_offer(GameState.bookings.offers[0].id)
	var panel := _tap_building(&"hibiscus_1")
	for i in 3:
		await get_tree().process_frame
	var tall := panel.size.y
	panel.close_button.pressed.emit()
	panel = _tap_building(&"tiki_site_1")
	for i in 3:
		await get_tree().process_frame
	assert_lt(panel.size.y, tall, "le panneau reprend une hauteur adaptée au contenu")
	assert_almost_eq(panel.size.y, panel.get_combined_minimum_size().y, 1.0)


func test_panel_keeps_its_width_in_every_state() -> void:
	var widths := []
	GameState.add_items({&"welcome_basket": 1})
	var panel := _tap_building(&"hibiscus_1")
	for step in 3:
		for i in 3:
			await get_tree().process_frame
		widths.append(panel.size.x)
		if step == 0:
			GameState.accept_offer(GameState.bookings.offers[0].id)
		else:
			GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.PREPARE)
	assert_eq(widths, [668.0, 668.0, 668.0])
	assert_false(panel._scroll.get_v_scroll_bar().visible, "pas de défilement quand tout tient à l'écran")
