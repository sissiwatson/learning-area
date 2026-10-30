## Retours visuels des productions : stades de la plantation, anneau de
## progression, récompenses flottantes.
extends GutTest

const FakeClock := preload("res://tests/helpers/fake_clock.gd")

var main: Node
var clock: FakeClock


func before_each() -> void:
	clock = FakeClock.new()
	GameState.clock = clock
	main = load("res://scenes/main.tscn").instantiate()
	add_child_autofree(main)
	await get_tree().process_frame
	while main.dialogue_box.visible:
		main.dialogue_box.skip()


func after_each() -> void:
	GameState.clock = Clock.new()


func _advance(seconds: int) -> void:
	clock.advance(seconds)
	GameState.tick()


func _farm() -> BuildingView:
	return main.map.buildings[&"farm_1"]


func _floats() -> Array:
	return main.map.get_node("Objects").get_children().filter(func(n): return n is FloatingReward and not n.is_queued_for_deletion())


func test_farm_grows_through_its_stages() -> void:
	var stages: Array = _farm().placement.building.stage_textures
	assert_eq(stages.size(), 3)
	assert_eq(_farm().sprite.texture, stages[0], "au repos : jeunes pousses")
	assert_false(_farm().ring.visible)
	GameState.start_production(&"farm_1", &"harvest_pineapple")
	assert_eq(_farm().sprite.texture, stages[1], "début : plants")
	assert_true(_farm().ring.visible)
	_advance(14)
	assert_eq(_farm().sprite.texture, stages[1])
	_advance(1)
	assert_eq(_farm().sprite.texture, stages[2], "à mi-parcours : ananas")
	_advance(15)
	assert_eq(_farm().sprite.texture, stages[0], "récolté : retour aux pousses")
	assert_false(_farm().ring.visible)


func test_ring_follows_progress() -> void:
	GameState.start_production(&"workshop_1", &"craft_welcome_basket") # refusé : pas d'ananas
	assert_false(main.map.buildings[&"workshop_1"].ring.visible)
	GameState.add_items({&"pineapple": 3})
	GameState.start_production(&"workshop_1", &"craft_welcome_basket")
	_advance(30)
	var ring: Node2D = main.map.buildings[&"workshop_1"].ring
	assert_true(ring.visible)
	main.map.buildings[&"workshop_1"]._ring_tween.custom_step(2.0)  # fin du glissement, sans attendre
	assert_almost_eq(ring.value, 0.5, 0.01)
	var workshop: BuildingView = main.map.buildings[&"workshop_1"]
	assert_eq(workshop.sprite.texture, workshop.placement.building.texture, "sans stades : texture inchangée")


func test_floating_rewards() -> void:
	GameState.start_production(&"farm_1", &"harvest_pineapple")
	_advance(30)
	var floats := _floats()
	assert_eq(floats.size(), 1)
	assert_eq(floats[0].label.text, "+3")
	floats[0].fast_forward()
	await get_tree().process_frame
	assert_eq(_floats().size(), 0, "l'animation se retire d'elle-même")


func test_commission_floats_over_the_bungalow() -> void:
	GameState.accept_offer(GameState.bookings.offers[0].id)
	GameState.add_items({&"welcome_basket": 1})
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.PREPARE)
	_advance(120)
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.WELCOME_GUESTS)
	_advance(600)
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.COLLECT_COMMISSION)
	var texts := _floats().map(func(f): return f.label.text)
	assert_has(texts, "+120")
