## Vérifications visuelles : lance la scène principale, rejoue des gestes
## simulés (mêmes InputEvent que sur un écran tactile) et enregistre une
## capture par scénario. Voir tools/visual_checks.sh.
##
## godot --path . -s tools/visual_checks.gd -- <dossier_sortie> [scénario...]
extends SceneTree

const SCENARIOS := [
	"zoom_initial", "zoom_min", "zoom_max", "pan_after_drag",
	"bungalow_overview", "bungalow_selected", "bungalow_booked",
	"buildings_overview", "corail_locked", "workshop_panel",
	"office_offers", "hibiscus_booked", "hibiscus_cleaning", "hibiscus_stay",
	"hibiscus_complete", "hibiscus_collected",
	"farm_running", "workshop_missing", "workshop_crafting", "hibiscus_needs_basket",
	"story_start", "story_banner", "story_hina", "story_arrival",
	"farm_growing", "farm_harvested",
	"tiki_ready", "tiki_building", "tiki_built",
	"audit_panel_and_dialogue", "touch_panel_action",
	"speedup_panel", "speedup_confirm_offer", "speedup_confirm_paid", "speedup_confirm_short",
	"touch_speedup_confirm",
]
const FakeClock := preload("res://tests/helpers/fake_clock.gd")

var fake_clock

var main: Node
var cam: MapCamera
var out_dir := ""
var _t := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("Usage : -- <dossier_sortie> [scénario...]")
		quit(2)
		return
	out_dir = args[0]
	# Les captures ne lisent ni n'écrivent jamais la sauvegarde du joueur.
	root.get_node("SaveManager").enabled = false
	DirAccess.make_dir_recursive_absolute(out_dir)
	var wanted: Array = args.slice(1) if args.size() > 1 else SCENARIOS
	for name in wanted:
		await _reset(String(name).begins_with("story_"))
		await call("_scenario_" + name)
		await _capture(name)
	quit()


## `keep_story` : garder les dialogues du tutoriel (sinon ils sont passés pour
## que les captures montrent la carte et les panneaux).
func _reset(keep_story := false) -> void:
	fake_clock = FakeClock.new()
	_game_state().clock = fake_clock
	if main:
		main.queue_free()
		await process_frame
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	cam = main.camera
	if not keep_story:
		while main.dialogue_box.visible:
			main.dialogue_box.skip()
			await process_frame


func _capture(name: String) -> void:
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var path := out_dir.path_join(name + ".png")
	root.get_texture().get_image().save_png(path)
	print("capture : %s (zoom %.3f)" % [path, cam.rig.zoom])


func _touch(i: int, pressed: bool, pos: Vector2) -> void:
	var e := InputEventScreenTouch.new()
	e.index = i; e.pressed = pressed; e.position = pos
	_t += 16
	cam.handle_input(e, _t)


func _drag(i: int, pos: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = i; e.position = pos
	_t += 16
	cam.handle_input(e, _t)


## Pincement simulé autour de `center`, écart des doigts de `from` à `to` px.
func _pinch(center: Vector2, from: float, to: float) -> void:
	_touch(0, true, center - Vector2(from / 2, 0))
	_touch(1, true, center + Vector2(from / 2, 0))
	for k in range(1, 11):
		var gap := lerpf(from, to, k / 10.0)
		_drag(0, center - Vector2(gap / 2, 0))
		_drag(1, center + Vector2(gap / 2, 0))
	_touch(0, false, center - Vector2(to / 2, 0))
	_touch(1, false, center + Vector2(to / 2, 0))


func _scenario_zoom_initial() -> void:
	pass


func _scenario_zoom_min() -> void:
	_pinch(Vector2(960, 540), 900, 60)


func _scenario_zoom_max() -> void:
	# Pincement écartant centré sur le bureau de conciergerie (parcelle 14,14).
	var target: Vector2 = cam.rig.world_to_screen(main.map.cell_center(Vector2i(15, 15)) - Vector2(0, 32))
	_pinch(target, 100, 1400)
	_pinch(target, 100, 1400)


func _scenario_pan_after_drag() -> void:
	_touch(0, true, Vector2(1400, 700))
	for k in range(1, 21):
		_drag(0, Vector2(1400 - 30 * k, 700 - 12 * k))
	_t += 400  # pause avant le lâcher : pas d'inertie
	_touch(0, false, Vector2(800, 460))


func _focus_hibiscus(zoom: float) -> BuildingView:
	var view: BuildingView = main.map.buildings[&"hibiscus_1"]
	cam.rig.set_zoom(zoom)
	# décalé vers la gauche pour laisser la place au panneau
	cam.rig.center_on(view.global_position + Vector2(260, -60))
	cam.position = cam.rig.position
	cam.zoom = Vector2.ONE * cam.rig.zoom
	return view


func _tap(screen_pos: Vector2) -> void:
	_touch(0, true, screen_pos)
	_t += 60
	_touch(0, false, screen_pos)


func _scenario_bungalow_overview() -> void:
	_focus_hibiscus(1.3)


func _scenario_bungalow_selected() -> void:
	var view := _focus_hibiscus(1.3)
	_tap(cam.rig.world_to_screen(view.global_position + Vector2(0, -60)))


func _scenario_bungalow_booked() -> void:
	var view := _focus_hibiscus(1.3)
	_tap(cam.rig.world_to_screen(view.global_position + Vector2(0, -60)))
	main.panel.action_buttons()[0].pressed.emit()


func _tap_building(uid: StringName, zoom := 1.2) -> void:
	var view: BuildingView = main.map.buildings[uid]
	cam.rig.set_zoom(zoom)
	cam.rig.center_on(view.global_position + Vector2(240, -40))
	cam.position = cam.rig.position
	cam.zoom = Vector2.ONE * cam.rig.zoom
	_tap(cam.rig.world_to_screen(view.global_position))


func _scenario_buildings_overview() -> void:
	cam.rig.set_zoom(0.62)
	cam.rig.center_on(main.map.cell_center(Vector2i(15, 17)))
	cam.position = cam.rig.position
	cam.zoom = Vector2.ONE * cam.rig.zoom


func _scenario_corail_locked() -> void:
	_tap_building(&"corail_1")


func _scenario_workshop_panel() -> void:
	_tap_building(&"workshop_1")


func _advance(seconds: int) -> void:
	fake_clock.advance(seconds)
	_game_state().tick()
	main.panel._on_second()


func _to_hibiscus_state(step: int) -> void:
	_advance(60)  # deux offres au bureau
	if step == 0:
		_tap_building(&"office_1")
		return
	_game_state().accept_offer(_game_state().bookings.offers[0].id)
	if step >= 2:
		_game_state().add_items({&"welcome_basket": 1})
		_game_state().perform_lodging_action(&"hibiscus_1", Lodging.Action.PREPARE)
		_advance(45)
	if step >= 3:
		_advance(75)
		_game_state().perform_lodging_action(&"hibiscus_1", Lodging.Action.WELCOME_GUESTS)
		_advance(400)
	if step >= 4:
		_advance(200)
	if step >= 5:
		_game_state().perform_lodging_action(&"hibiscus_1", Lodging.Action.COLLECT_COMMISSION)
	_tap_building(&"hibiscus_1", 1.3)
	_advance(0)


func _scenario_office_offers() -> void:
	_to_hibiscus_state(0)


func _scenario_hibiscus_booked() -> void:
	_to_hibiscus_state(1)


func _scenario_hibiscus_cleaning() -> void:
	_to_hibiscus_state(2)


func _scenario_hibiscus_stay() -> void:
	_to_hibiscus_state(3)


func _scenario_hibiscus_complete() -> void:
	_to_hibiscus_state(4)


func _scenario_hibiscus_collected() -> void:
	_to_hibiscus_state(5)


## Autoload GameState (pas d'accès direct par son nom dans un script -s).
func _game_state() -> Node:
	return root.get_node("GameState")


func _scenario_farm_running() -> void:
	_game_state().start_production(&"farm_1", &"harvest_pineapple")
	_advance(12)
	_tap_building(&"farm_1", 1.1)
	_advance(0)


func _scenario_workshop_missing() -> void:
	_game_state().add_items({&"pineapple": 2})
	_tap_building(&"workshop_1", 1.2)


func _scenario_workshop_crafting() -> void:
	_game_state().add_items({&"pineapple": 3})
	_game_state().start_production(&"workshop_1", &"craft_welcome_basket")
	_advance(25)
	_tap_building(&"workshop_1", 1.2)
	_advance(0)


func _scenario_hibiscus_needs_basket() -> void:
	_game_state().accept_offer(_game_state().bookings.offers[0].id)
	_tap_building(&"hibiscus_1", 1.3)


func _scenario_story_start() -> void:
	main.dialogue_box.on_tap()  # texte complet


func _scenario_story_banner() -> void:
	main.dialogue_box.skip()
	var kimo: NpcView = main.map.npcs[&"npc_kimo"]
	cam.rig.set_zoom(1.2)
	cam.rig.center_on(kimo.global_position + Vector2(200, 60))
	cam.position = cam.rig.position
	cam.zoom = Vector2.ONE * cam.rig.zoom
	_tap(cam.rig.world_to_screen(kimo.global_position + Vector2(0, -50)))


func _scenario_story_hina() -> void:
	main.dialogue_box.skip()
	root.get_node("EventBus").game_event.emit(&"camera_panned", &"", 1)
	root.get_node("EventBus").game_event.emit(&"camera_zoomed", &"", 1)
	await process_frame
	var hina: NpcView = main.map.npcs[&"npc_hina"]
	cam.rig.set_zoom(1.3)
	cam.rig.center_on(hina.global_position + Vector2(0, 120))
	cam.position = cam.rig.position
	cam.zoom = Vector2.ONE * cam.rig.zoom
	main.dialogue_box.on_tap()


func _scenario_story_arrival() -> void:
	while main.dialogue_box.visible:
		main.dialogue_box.skip()
		await process_frame
	var gs := _game_state()
	gs.accept_offer(gs.bookings.offers[0].id)
	gs.add_items({&"welcome_basket": 1})
	gs.perform_lodging_action(&"hibiscus_1", Lodging.Action.PREPARE)
	_advance(120)
	gs.perform_lodging_action(&"hibiscus_1", Lodging.Action.WELCOME_GUESTS)
	var anim: ArrivalAnimation = main.map.get_node("Objects").get_children().filter(func(n): return n is ArrivalAnimation)[0]
	for t in anim._tweens:
		t.custom_step(4.6)
	cam.rig.set_zoom(1.0)
	cam.rig.center_on(main.map.cell_center(Vector2i(13, 24)))
	cam.position = cam.rig.position
	cam.zoom = Vector2.ONE * cam.rig.zoom
	main.panel.close_panel()


func _show_farm() -> void:
	var farm: BuildingView = main.map.buildings[&"farm_1"]
	cam.rig.set_zoom(1.3)
	cam.rig.center_on(farm.global_position + Vector2(0, -60))
	cam.position = cam.rig.position
	cam.zoom = Vector2.ONE * cam.rig.zoom


func _scenario_farm_growing() -> void:
	_game_state().start_production(&"farm_1", &"harvest_pineapple")
	_advance(18)
	_show_farm()
	for i in 70:  # laisse l'anneau glisser jusqu'à sa valeur
		await process_frame


func _scenario_farm_harvested() -> void:
	_game_state().start_production(&"farm_1", &"harvest_pineapple")
	_advance(30)
	_show_farm()
	for f in main.map.get_node("Objects").get_children():
		if f is FloatingReward:
			f._tween.custom_step(0.45)


func _tiki_setup(step: int) -> void:
	var gs := _game_state()
	gs.gain_xp(55)
	gs.earn(&"shells", 120)
	if step >= 1:
		gs.start_construction(&"tiki_site_1")
		_advance(130)
	if step >= 2:
		_advance(200)
	_tap_building(&"tiki_site_1", 1.3)
	_advance(0)
	for i in 70:
		await process_frame


func _scenario_tiki_ready() -> void:
	await _tiki_setup(0)


func _scenario_tiki_building() -> void:
	await _tiki_setup(1)


func _scenario_tiki_built() -> void:
	await _tiki_setup(2)


## Audit : une quête se termine depuis un panneau et le dialogue suivant s'ouvre.
func _scenario_audit_panel_and_dialogue() -> void:
	main.dialogue_box.skip()
	root.get_node("EventBus").game_event.emit(&"camera_panned", &"", 1)
	root.get_node("EventBus").game_event.emit(&"camera_zoomed", &"", 1)
	for i in 3:
		await process_frame
	while main.dialogue_box.visible:
		main.dialogue_box.skip()
		await process_frame
	_tap_building(&"office_1", 1.0)
	_advance(60)
	main.panel.offer_buttons()[0].pressed.emit()
	for i in 3:
		await process_frame
	main.dialogue_box.on_tap()


## Vrai toucher (souris émulée puis toucher, comme Android) sur un bouton du
## panneau qui reconstruit le panneau : aucune erreur moteur (le script
## visual_checks.sh échoue sinon) et l'action est bien faite.
func _scenario_touch_panel_action() -> void:
	_game_state().accept_offer(_game_state().bookings.offers[0].id)
	_game_state().add_items({&"welcome_basket": 1})
	_tap_building(&"hibiscus_1", 1.0)
	for i in 3:
		await process_frame
	var button: Button = main.panel.actions.get_node("Action_PREPARE")
	var pos := root.get_final_transform() * button.get_global_rect().get_center()
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.index = 0; e.pressed = pressed; e.position = pos
		Input.parse_input_event(e)
		Input.flush_buffered_events()
	for i in 3:
		await process_frame
	var state: int = _game_state().get_lodging(&"hibiscus_1").state
	if state != Lodging.State.PREPARING:
		push_error("le toucher sur « Faire le ménage » n'a pas lancé le ménage")


## Séjour en cours (2 nuits, 400 s écoulées) avec la section « Avancer le temps ».
func _to_stay_with_speedups() -> void:
	_to_hibiscus_state(3)
	for i in 3:
		await process_frame


func _scenario_speedup_panel() -> void:
	await _to_stay_with_speedups()


func _scenario_speedup_confirm_offer() -> void:
	await _to_stay_with_speedups()
	main.speedup_confirm.open(&"hibiscus_1", SpeedupRules.Tier.FINISH)


func _scenario_speedup_confirm_paid() -> void:
	_game_state().free_speedups = 0
	await _to_stay_with_speedups()
	main.speedup_confirm.open(&"hibiscus_1", SpeedupRules.Tier.ONE_NIGHT)


func _scenario_speedup_confirm_short() -> void:
	_game_state().free_speedups = 0
	_game_state().spend({&"shells": 46})
	await _to_stay_with_speedups()
	main.speedup_confirm.open(&"hibiscus_1", SpeedupRules.Tier.FINISH)


## Vrais touchers (souris émulée puis toucher) : « Passer une nuit » puis
## « Confirmer ». Aucune erreur moteur ; le prix payé est celui affiché.
func _scenario_touch_speedup_confirm() -> void:
	_game_state().free_speedups = 0
	await _to_stay_with_speedups()
	var before: int = _game_state().wallet.balance(&"shells")
	var shown: int = _game_state().quote_stay_speedup(&"hibiscus_1", SpeedupRules.Tier.ONE_NIGHT).value.cost
	await _real_tap(main.panel.speedup_box.get_node("Speedup_ONE_NIGHT"))
	if not main.speedup_confirm.visible:
		push_error("la confirmation ne s'est pas ouverte")
		return
	await _real_tap(main.speedup_confirm.confirm_button)
	var paid: int = before - _game_state().wallet.balance(&"shells")
	if main.speedup_confirm.visible or paid != shown or shown <= 0:
		push_error("accélération par vrais touchers : payé %d (affiché %d)" % [paid, shown])


func _real_tap(control: Control) -> void:
	var pos := root.get_final_transform() * control.get_global_rect().get_center()
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.index = 0; e.pressed = pressed; e.position = pos
		Input.parse_input_event(e)
		Input.flush_buffered_events()
	for i in 3:
		await process_frame
