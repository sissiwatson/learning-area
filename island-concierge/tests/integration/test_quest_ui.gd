## Dialogues, bandeau d'objectif, personnages et arrivée des voyageurs.
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
	await get_tree().process_frame


func after_each() -> void:
	GameState.clock = Clock.new()


func _box() -> DialogueBox:
	return main.dialogue_box


func _tap_world(world: Vector2) -> void:
	main.camera.rig.center_on(world)
	var pos: Vector2 = main.camera.rig.world_to_screen(world)
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.index = 0; e.pressed = pressed; e.position = pos
		_t += 60
		main.camera.handle_input(e, _t)


func _finish_tutorial_01() -> void:
	_box().skip()
	EventBus.game_event.emit(&"camera_panned", &"", 1)
	EventBus.game_event.emit(&"camera_zoomed", &"", 1)
	await get_tree().process_frame


func test_game_opens_on_tao_dialogue() -> void:
	assert_true(_box().visible)
	assert_eq(_box().speaker_label.text, "Tao")
	assert_string_starts_with(_box().text_label.text, "On y est. Mahana.")
	assert_not_null(_box().portrait.texture)
	assert_false(main.quest_banner.visible, "la quête démarre à la fin du dialogue")


func test_tap_completes_text_then_advances_then_finishes() -> void:
	assert_true(_box().is_typing())
	_box().on_tap()
	assert_false(_box().is_typing(), "1er toucher : texte complet")
	assert_string_starts_with(_box().text_label.text, "On y est")
	_box().on_tap()
	assert_string_starts_with(_box().text_label.text, "Glisse ton doigt")
	_box().on_tap()
	_box().on_tap()
	assert_false(_box().visible)
	assert_eq(GameState.quest_log.get_status(&"tutorial_01"), QuestLog.Status.ACTIVE)


func test_skip_has_the_same_effect_as_reading() -> void:
	_box().skip()
	assert_false(_box().visible)
	assert_eq(GameState.quest_log.get_status(&"tutorial_01"), QuestLog.Status.ACTIVE)
	assert_true(main.quest_banner.visible)
	assert_eq(main.quest_banner.title.text, "Arrivée au quai")
	assert_eq(main.quest_banner.objectives.text, "• Faire glisser la carte\n• Pincer pour zoomer")
	assert_false(main.quest_banner.go_button.visible, "rien à montrer pour cette quête")


func test_real_camera_gestures_complete_the_first_quest() -> void:
	_box().skip()
	var cam: MapCamera = main.camera
	var e := InputEventScreenTouch.new()
	e.index = 0; e.pressed = true; e.position = Vector2(900, 400)
	cam.handle_input(e, 1000)
	var d := InputEventScreenDrag.new()
	d.index = 0
	for k in range(1, 6):
		d.position = Vector2(900 + 40 * k, 400)
		cam.handle_input(d, 1000 + 16 * k)
	e.pressed = false; e.position = d.position
	cam.handle_input(e, 1200)
	assert_eq(main.quest_banner.objectives.text, "✓ Faire glisser la carte\n• Pincer pour zoomer")
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP; wheel.pressed = true; wheel.position = Vector2(900, 500)
	cam.handle_input(wheel, 1300)
	assert_eq(GameState.quest_log.get_status(&"tutorial_01"), QuestLog.Status.COMPLETED)
	assert_has(main.toasts.messages(), "Quête terminée : Arrivée au quai")


func test_next_dialogue_and_npc_marker() -> void:
	await _finish_tutorial_01()
	assert_true(_box().visible, "Hina enchaîne")
	assert_eq(_box().speaker_label.text, "Hina Tehani")
	_box().skip()
	assert_eq(main.quest_banner.title.text, "Les clés du bungalow")
	assert_false(main.map.npcs[&"npc_hina"].has_story())


func test_go_button_shows_the_office() -> void:
	await _finish_tutorial_01()
	_box().skip()
	main.quest_banner.go_button.pressed.emit()
	assert_true(main.panel.visible)
	assert_eq(main.panel.title.text, "Bureau de conciergerie")


func test_tapping_an_npc_says_ambient_lines_in_turn() -> void:
	_box().skip()
	var kimo: NpcView = main.map.npcs[&"npc_kimo"]
	_tap_world(kimo.global_position + Vector2(0, -50))
	assert_eq(kimo.bubble.text, "Chaque brin passe sous deux, puis sur deux…")
	_tap_world(kimo.global_position + Vector2(0, -50))
	assert_eq(kimo.bubble.text, "Le bois flotté raconte toujours un voyage.")


func test_npcs_are_on_the_map() -> void:
	assert_eq(main.map.npcs.keys(), [&"npc_hina", &"npc_tao", &"npc_malia", &"npc_kimo"])


func test_guests_arrive_by_boat_when_welcomed() -> void:
	GameState.accept_offer(GameState.bookings.offers[0].id)
	GameState.add_items({&"welcome_basket": 1})
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.PREPARE)
	clock.advance(120)
	GameState.tick()
	var before := _arrivals().size()
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.WELCOME_GUESTS)
	var arrivals := _arrivals()
	assert_eq(arrivals.size(), before + 1, "bateau et voyageurs en route")
	var anim: ArrivalAnimation = arrivals[-1]
	assert_eq(anim.walkers.size(), 2)
	anim.fast_forward()
	await get_tree().process_frame
	assert_eq(_arrivals().size(), before, "animation terminée et retirée")


func test_restoring_a_save_does_not_replay_arrivals() -> void:
	GameState.accept_offer(GameState.bookings.offers[0].id)
	GameState.add_items({&"welcome_basket": 1})
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.PREPARE)
	clock.advance(120)
	GameState.tick()
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.WELCOME_GUESTS)
	for a in _arrivals():
		a.fast_forward()
	await get_tree().process_frame
	var data := JSON.parse_string(JSON.stringify(GameState.to_save_dict()))
	GameState.load_save_dict(data, main.map.map_def)
	assert_eq(_arrivals().size(), 0)


func _arrivals() -> Array:
	return main.map.get_node("Objects").get_children().filter(func(n): return n is ArrivalAnimation and not n.is_queued_for_deletion())


func test_building_footprint_wins_over_a_nearby_npc() -> void:
	_box().skip()
	var workshop: BuildingView = main.map.buildings[&"workshop_1"]
	_tap_world(workshop.global_position)
	assert_true(main.panel.visible)
	assert_eq(main.panel.title.text, "Atelier de produits d'accueil")


func test_toasts_never_cover_the_building_panel_or_dialogue() -> void:
	main.toasts.show_message("Quête terminée : Les clés du bungalow")
	main.select_building(main.map.buildings[&"office_1"])
	await get_tree().process_frame
	await get_tree().process_frame
	var toast_rect: Rect2 = main.toasts.get_child(0).get_global_rect()
	assert_false(toast_rect.intersects(main.panel.get_global_rect()), "toast %s / panneau %s" % [toast_rect, main.panel.get_global_rect()])
	assert_false(toast_rect.intersects(main.dialogue_box.get_global_rect()))


func test_a_starting_dialogue_closes_the_building_panel() -> void:
	_box().skip()
	main.select_building(main.map.buildings[&"office_1"])
	assert_true(main.panel.visible)
	EventBus.game_event.emit(&"camera_panned", &"", 1)
	EventBus.game_event.emit(&"camera_zoomed", &"", 1)
	await get_tree().process_frame
	assert_true(_box().visible, "Hina enchaîne")
	assert_false(main.panel.visible, "le dialogue prend la main : pas de superposition")


func test_overlays_keep_their_screen_size() -> void:
	var cam: MapCamera = main.camera
	var badge: Node2D = main.map.get_node("LockBadges").get_child(0)
	cam.rig.set_zoom(cam.rig.min_zoom)
	cam._apply()
	var small_zoom_scale := badge.scale.x * cam.rig.zoom
	cam.rig.set_zoom(2.0)
	cam._apply()
	assert_almost_eq(badge.scale.x * cam.rig.zoom, small_zoom_scale, 0.001, "taille à l'écran identique")
	assert_almost_eq(badge.scale.x * cam.rig.zoom, WorldMap.OVERLAY_SCREEN_SCALE, 0.001)
	var ring: Node2D = main.map.buildings[&"farm_1"].ring
	assert_almost_eq(ring.scale.x * cam.rig.zoom, WorldMap.OVERLAY_SCREEN_SCALE, 0.001)


func test_initial_framing_shows_the_whole_island_on_every_screen_shape() -> void:
	for view in [Vector2(1920, 1080), Vector2(2400, 1080), Vector2(1920, 1440)]:
		main.frame_island(view)
		var visible: Rect2 = main.camera.rig.visible_rect()
		assert_true(visible.grow(1).encloses(main.map.land_bounds()), "toute l'île visible en %s" % view)
		assert_true(visible.has_point(main.map.buildings[&"hibiscus_1"].global_position))
