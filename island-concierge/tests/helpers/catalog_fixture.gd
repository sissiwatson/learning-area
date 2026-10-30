## Petit catalogue valide construit en mémoire, que chaque test de
## DataValidator modifie pour introduire une seule erreur.
extends RefCounted

var shells := CurrencyDef.new()
var pineapple := ItemDef.new()
var basket := ItemDef.new()
var harvest := RecipeDef.new()
var craft := RecipeDef.new()
var hina := NpcDef.new()
var booking := BookingTemplateDef.new()
var office := BuildingDef.new()
var bungalow := BuildingDef.new()
var farm := BuildingDef.new()
var workshop := BuildingDef.new()
var bar := BuildingDef.new()
var site := BuildingDef.new()
var quest_a := QuestDef.new()
var quest_b := QuestDef.new()
var map := MapDef.new()
var new_game := NewGameDef.new()
var timings := TimingsDef.new()


func _init() -> void:
	var icon := PlaceholderTexture2D.new()
	shells.id = &"shells"; shells.name_key = "CURRENCY_SHELLS"; shells.icon = icon
	pineapple.id = &"pineapple"; pineapple.name_key = "ITEM_PINEAPPLE"; pineapple.icon = icon
	basket.id = &"welcome_basket"; basket.name_key = "ITEM_WELCOME_BASKET"; basket.icon = icon
	harvest.id = &"harvest_pineapple"; harvest.name_key = "RECIPE_HARVEST_PINEAPPLE"
	harvest.outputs = {&"pineapple": 3}
	craft.id = &"craft_welcome_basket"; craft.name_key = "RECIPE_CRAFT_WELCOME_BASKET"
	craft.inputs = {&"pineapple": 3}; craft.outputs = {&"welcome_basket": 1}
	hina.id = &"npc_hina"; hina.display_name = "Hina"; hina.job_key = "JOB_OWNER"
	booking.id = &"couple"; booking.guest_name = "Camille et Noé"
	_building(office, &"concierge_office", BuildingDef.Role.OFFICE, icon)
	office.office = OfficeDef.new(); office.office.booking_templates = [booking]
	_building(bungalow, &"bungalow_hibiscus", BuildingDef.Role.LODGING, icon)
	bungalow.lodging = LodgingDef.new(); bungalow.lodging.owner = hina
	_building(farm, &"pineapple_farm", BuildingDef.Role.PRODUCER, icon)
	farm.producer = ProducerDef.new(); farm.producer.recipes = [harvest]
	_building(workshop, &"amenities_workshop", BuildingDef.Role.PRODUCER, icon)
	workshop.producer = ProducerDef.new(); workshop.producer.recipes = [craft]
	_building(bar, &"tiki_bar", BuildingDef.Role.DECORATION, icon)
	_building(site, &"tiki_bar_site", BuildingDef.Role.CONSTRUCTION, icon)
	site.construction = ConstructionDef.new(); site.construction.cost = {&"shells": 150}
	site.construction.builds_into = bar
	quest_a.id = &"tutorial_01"; quest_a.title_key = "QUEST_TUTORIAL_01"; quest_a.giver = hina
	quest_a.objectives = [_objective(&"booking_accepted", &"")]
	quest_b.id = &"tutorial_02"; quest_b.title_key = "QUEST_TUTORIAL_02"; quest_b.giver = hina
	quest_b.prerequisites = [&"tutorial_01"]
	quest_b.objectives = [_objective(&"item_collected", &"pineapple")]
	map.id = &"mahana"; map.name_key = "MAP_MAHANA"; map.size = Vector2i(6, 4)
	map.layout = "~~~~~~\n~++++~\n~++++~\n~~~~~~"
	map.placements = [_placement(&"office_1", office, Vector2i(1, 1)), _placement(&"bungalow_1", bungalow, Vector2i(3, 1))]
	new_game.currencies = [shells]; new_game.items = [pineapple, basket]
	new_game.starting_balances = {&"shells": 50}; new_game.timings = timings


func catalog() -> Dictionary:
	return {
		"currencies": [shells], "items": [pineapple, basket], "recipes": [harvest, craft],
		"npcs": [hina], "bookings": [booking], "buildings": [office, bungalow, farm, workshop, bar, site],
		"quests": [quest_a, quest_b], "maps": [map], "new_games": [new_game], "timings": [timings],
	}


func _building(def: BuildingDef, id: StringName, role: BuildingDef.Role, icon: Texture2D) -> void:
	def.id = id
	def.name_key = "BUILDING_" + String(id).to_upper()
	def.role = role
	def.texture = icon


func _objective(event: StringName, target: StringName) -> ObjectiveDef:
	var o := ObjectiveDef.new()
	o.event = event
	o.target = target
	return o


func _placement(uid: StringName, building: BuildingDef, cell: Vector2i) -> PlacementDef:
	var p := PlacementDef.new()
	p.uid = uid
	p.building = building
	p.cell = cell
	return p
