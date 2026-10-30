## DataValidator : chaque test introduit une seule erreur dans un catalogue
## valide et vérifie qu'elle est signalée avec un message explicite.
extends GutTest

const Fixture := preload("res://tests/helpers/catalog_fixture.gd")

var f: Fixture


func before_each() -> void:
	f = Fixture.new()


func _errors() -> PackedStringArray:
	return DataValidator.validate(f.catalog())


func _assert_error(fragment: String) -> void:
	var errors := _errors()
	var found := false
	for e in errors:
		found = found or fragment in e
	assert_true(found, "erreur attendue contenant « %s », reçu : %s" % [fragment, errors])


func test_valid_fixture_has_no_error() -> void:
	assert_eq(_errors(), PackedStringArray())


# --- Données manquantes -------------------------------------------------------

func test_missing_icon() -> void:
	f.pineapple.icon = null
	_assert_error("items:pineapple : icône manquante")


func test_missing_translation() -> void:
	f.harvest.name_key = "RECIPE_DOES_NOT_EXIST"
	_assert_error("traduction manquante « RECIPE_DOES_NOT_EXIST »")


func test_lodging_without_parameters() -> void:
	f.bungalow.lodging = null
	_assert_error("rôle LODGING sans paramètres")


func test_producer_without_recipe() -> void:
	f.farm.producer.recipes = []
	_assert_error("production sans recette")


func test_office_without_booking_template() -> void:
	f.office.office.booking_templates = []
	_assert_error("bureau sans modèle de réservation")


func test_map_without_office() -> void:
	f.map.placements = [f.map.placements[1]]
	_assert_error("aucun bureau de conciergerie")


func test_quest_without_objective() -> void:
	f.quest_a.objectives = []
	_assert_error("quests:tutorial_01 : aucun objectif")


func test_missing_timings() -> void:
	f.new_game.timings = null
	_assert_error("durées (timings) manquantes")


# --- Références cassées -------------------------------------------------------

func test_recipe_references_unknown_item() -> void:
	f.harvest.outputs = {&"coconut": 2}
	_assert_error("« coconut » inconnu")


func test_building_references_recipe_outside_catalog() -> void:
	var stray := RecipeDef.new()
	stray.id = &"stray"
	f.farm.producer.recipes = [stray]
	_assert_error("recette inconnue « stray »")


func test_resource_with_same_id_but_not_in_catalog() -> void:
	var impostor := NpcDef.new()
	impostor.id = &"npc_hina"
	impostor.display_name = "Autre"
	f.bungalow.lodging.owner = impostor
	_assert_error("propriétaire inconnu « npc_hina »")


func test_construction_cost_in_unknown_currency() -> void:
	f.site.construction.cost = {&"pearls": 10}
	_assert_error("coût : « pearls » inconnu")


func test_quest_unknown_prerequisite() -> void:
	f.quest_b.prerequisites = [&"tutorial_99"]
	_assert_error("prérequis inconnu « tutorial_99 »")


func test_quest_unknown_event() -> void:
	f.quest_a.objectives[0].event = &"won_lottery"
	_assert_error("événement inconnu « won_lottery »")


func test_quest_unknown_target() -> void:
	f.quest_b.objectives[0].target = &"mango"
	_assert_error("objet cible inconnu « mango »")


func test_placement_of_unknown_building() -> void:
	f.map.placements[1].building = BuildingDef.new()
	_assert_error("bâtiment inconnu")


# --- Valeurs invalides --------------------------------------------------------

func test_duplicate_id() -> void:
	var twin := ItemDef.new()
	twin.id = &"pineapple"; twin.name_key = "ITEM_PINEAPPLE"; twin.icon = f.pineapple.icon
	var c: Dictionary = f.catalog()
	c["items"].append(twin)
	var errors := DataValidator.validate(c)
	assert_true(errors.has("items:pineapple : identifiant en double"), str(errors))


func test_badly_formed_id() -> void:
	f.basket.id = &"Welcome Basket"
	_assert_error("identifiant invalide")


func test_negative_and_zero_amounts() -> void:
	f.craft.inputs = {&"pineapple": 0}
	f.site.construction.cost = {&"shells": -5}
	_assert_error("entrées : quantité invalide pour « pineapple »")
	_assert_error("coût : quantité invalide pour « shells »")


func test_recipe_without_output() -> void:
	f.harvest.outputs = {}
	_assert_error("sorties vides")


func test_invalid_booking_values() -> void:
	f.booking.nights = 0
	_assert_error("voyageurs, nuits et prix doivent être positifs")


func test_commission_out_of_range() -> void:
	f.bungalow.lodging.commission_percent = 150
	_assert_error("commission hors de 1..100")


func test_invalid_map_layout() -> void:
	f.map.layout = "~~~~~~\n~++X+~\n~++++~\n~~~~~~"
	_assert_error("caractère inconnu 'X'")


func test_negative_timing() -> void:
	f.timings.night_seconds = 0
	_assert_error("night_seconds doit être positif")


# --- Incohérences -------------------------------------------------------------

func test_role_parameters_mismatch() -> void:
	f.office.producer = ProducerDef.new()
	_assert_error("paramètres « producer » incohérents avec le rôle OFFICE")


func test_placement_on_non_buildable_cell() -> void:
	f.map.placements[1].cell = Vector2i(4, 1)  # déborde sur l'océan
	_assert_error("non constructible")


func test_overlapping_placements() -> void:
	f.map.placements[1].cell = Vector2i(2, 1)
	_assert_error("chevauche")


func test_placement_straddling_a_zone() -> void:
	var zone := ZoneDef.new()
	zone.id = &"east"; zone.name_key = "ZONE_EAST_COAST"; zone.rect = Rect2i(4, 0, 2, 4)
	f.map.zones = [zone]
	_assert_error("à cheval sur une zone")


func test_quest_prerequisite_cycle() -> void:
	f.quest_a.prerequisites = [&"tutorial_02"]
	_assert_error("cycle de prérequis")


func test_event_without_target_given_a_target() -> void:
	f.quest_a.objectives[0].target = &"pineapple"
	_assert_error("n'a pas de cible")


func test_construction_footprint_mismatch() -> void:
	f.bar.footprint = Vector2i(3, 3)
	_assert_error("emprise différente du bâtiment cible")


func test_preparation_item_not_freely_producible_is_a_softlock() -> void:
	f.bungalow.lodging.prepare_items = {&"welcome_basket": 1}
	assert_eq(_errors(), PackedStringArray(), "panier produit gratuitement : ananas -> panier")
	f.harvest.inputs = {&"welcome_basket": 1}  # boucle : plus rien n'est gratuit
	_assert_error("ne peut pas être produit gratuitement")


func test_zone_badge_outside_zone() -> void:
	var zone := ZoneDef.new()
	zone.id = &"east"; zone.name_key = "ZONE_EAST_COAST"; zone.rect = Rect2i(0, 0, 1, 1)
	zone.badge_cell = Vector2i(5, 3)
	f.map.zones = [zone]
	_assert_error("cadenas de la zone « east » hors de la zone")


func test_no_booking_fits_an_available_lodging_is_a_softlock() -> void:
	f.booking.guests = 6
	_assert_error("aucune réservation possible au départ")


func test_level_thresholds_must_increase_from_zero() -> void:
	f.new_game.progression.level_thresholds = [0, 50, 50]
	_assert_error("paliers non strictement croissants")
	f.new_game.progression.level_thresholds = [10, 50]
	_assert_error("le niveau 1 doit commencer à 0 XP")


func test_unreachable_required_level() -> void:
	f.new_game.progression.level_thresholds = [0, 50]
	f.site.construction.required_level = 3
	_assert_error("niveau requis 3 inatteignable (max 2)")


func test_missing_progression() -> void:
	f.new_game.progression = null
	_assert_error("progression manquante")


func test_dialogue_with_unknown_text_or_speaker() -> void:
	f.dialogue.lines[0].text_key = "DLG_DOES_NOT_EXIST"
	_assert_error("traduction manquante « DLG_DOES_NOT_EXIST »")
	var stranger := NpcDef.new()
	stranger.id = &"npc_stranger"
	f.dialogue.lines[0].speaker = stranger
	_assert_error("personnage inconnu « npc_stranger »")


func test_quest_dialogue_outside_catalog() -> void:
	var other := DialogueDef.new()
	other.id = &"dlg_lost"
	f.quest_b.intro_dialogue = other
	_assert_error("dialogue hors catalogue « dlg_lost »")


func test_quest_focus_on_unknown_building() -> void:
	f.quest_a.focus_building = &"casino"
	_assert_error("bâtiment « Y aller » inconnu « casino »")


func test_npc_placed_in_the_sea() -> void:
	var spot := NpcSpotDef.new()
	spot.npc = f.hina
	spot.cell = Vector2i(0, 0)
	f.map.npc_spots = [spot]
	_assert_error("placé hors de la terre ferme")


func test_arrival_path_through_the_sea() -> void:
	f.map.placements[1].arrival_path = [Vector2i(1, 1), Vector2i(0, 0)]
	_assert_error("chemin des voyageurs de « bungalow_1 » hors de la terre")


func test_npc_without_portrait() -> void:
	f.hina.portrait = null
	_assert_error("sprite ou portrait manquant")
