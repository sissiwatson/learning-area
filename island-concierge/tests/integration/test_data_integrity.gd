## Les vraies données du jeu (data/) sont complètes et cohérentes.
extends GutTest


func test_game_data_has_no_error() -> void:
	Database.reload()
	assert_eq(Database.errors, PackedStringArray(), "\n".join(Database.errors))


func test_every_data_file_is_loaded() -> void:
	var expected := {
		"currencies": 1, "items": 2, "recipes": 2, "npcs": 4, "bookings": 4,
		"buildings": 7, "quests": 8, "maps": 1, "dialogues": 10,
	}
	for type in expected:
		assert_eq(Database.catalog[type].size(), expected[type], "nombre de « %s »" % type)


func test_lookup_by_id() -> void:
	var office: BuildingDef = Database.get_def("buildings", &"concierge_office")
	assert_not_null(office)
	assert_eq(office.role, BuildingDef.Role.OFFICE)
	assert_null(Database.get_def("buildings", &"casino"))


func test_new_game_uses_catalog_definitions() -> void:
	var new_game: NewGameDef = Database.catalog["new_games"][0]
	for currency in new_game.currencies:
		assert_eq(Database.get_def("currencies", currency.id), currency)


func test_quests_give_no_xp_twice() -> void:
	for quest in Database.catalog["quests"]:
		assert_eq(quest.reward_xp, 0, "l'XP vient des actions, pas des quêtes du tutoriel : %s" % quest.id)


func test_tutorial_quests_form_a_single_chain() -> void:
	var quests: Array = Database.catalog["quests"]
	for i in quests.size():
		var expected: Array[StringName] = []
		if i > 0:
			expected.append(quests[i - 1].id)
		assert_eq(quests[i].prerequisites, expected, quests[i].id)
