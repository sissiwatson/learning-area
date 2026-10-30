extends GutTest

const S := QuestLog.Status

var log: QuestLog
var a := QuestDef.new()
var b := QuestDef.new()


func _objective(event: StringName, target: StringName, amount: int) -> ObjectiveDef:
	var o := ObjectiveDef.new()
	o.event = event; o.target = target; o.amount = amount
	return o


func before_each() -> void:
	a = QuestDef.new(); a.id = &"a"; a.objectives = [_objective(&"booking_accepted", &"", 1)]
	b = QuestDef.new(); b.id = &"b"; b.prerequisites = [&"a"]
	b.objectives = [_objective(&"item_collected", &"pineapple", 3), _objective(&"booking_accepted", &"", 1)]
	log = QuestLog.new([a, b] as Array[QuestDef])


func test_prerequisites_unlock_in_order() -> void:
	assert_eq(log.refresh(), [a] as Array[QuestDef])
	assert_eq(log.get_status(&"b"), S.LOCKED)
	log.start(&"a")
	log.record(&"booking_accepted", &"", 1)
	assert_eq(log.get_status(&"a"), S.COMPLETED)
	assert_eq(log.refresh(), [b] as Array[QuestDef])
	assert_eq(log.refresh(), [] as Array[QuestDef], "jamais deux fois disponible")


func test_only_available_quests_can_start() -> void:
	assert_eq(log.start(&"a").error, &"quest_not_available")
	log.refresh()
	assert_true(log.start(&"a").ok)
	assert_eq(log.start(&"a").error, &"quest_not_available", "pas de double démarrage")


func test_events_before_activation_do_not_count() -> void:
	log.refresh()
	log.record(&"booking_accepted", &"", 1)
	assert_eq(log.get_status(&"a"), S.AVAILABLE)
	log.start(&"a")
	assert_eq(log.progress[&"a"], [0])


func test_targets_amounts_and_caps() -> void:
	log.refresh(); log.start(&"a"); log.record(&"booking_accepted", &"", 1)
	log.refresh(); log.start(&"b")
	log.record(&"item_collected", &"mango", 3)
	assert_eq(log.progress[&"b"], [0, 0], "mauvaise cible")
	log.record(&"item_collected", &"pineapple", 2)
	log.record(&"item_collected", &"pineapple", 5)
	assert_eq(log.progress[&"b"], [3, 0], "plafonné à l'objectif")
	assert_eq(log.get_status(&"b"), S.ACTIVE, "tous les objectifs sont nécessaires")
	assert_eq(log.record(&"booking_accepted", &"", 1), [b] as Array[QuestDef])


func test_reward_claimed_once() -> void:
	log.refresh(); log.start(&"a")
	assert_false(log.claim_reward(&"a"), "pas avant la fin")
	log.record(&"booking_accepted", &"", 1)
	assert_true(log.claim_reward(&"a"))
	assert_false(log.claim_reward(&"a"))
	log.record(&"booking_accepted", &"", 1)
	assert_false(log.claim_reward(&"a"))


func test_round_trip_and_sanitizing() -> void:
	log.refresh(); log.start(&"a"); log.record(&"booking_accepted", &"", 1); log.claim_reward(&"a")
	log.refresh(); log.start(&"b"); log.record(&"item_collected", &"pineapple", 2)
	var copy := QuestLog.new([a, b] as Array[QuestDef])
	copy.load_dict(JSON.parse_string(JSON.stringify(log.to_dict())))
	assert_eq(copy.to_dict(), log.to_dict())
	assert_false(copy.claim_reward(&"a"), "récompense déjà accordée avant la sauvegarde")
	var bad := QuestLog.new([a, b] as Array[QuestDef])
	bad.load_dict({"b": {"status": "ACTIVE", "progress": [99, "x"], "rewarded": true}, "zzz": {}})
	assert_eq(bad.progress[&"b"], [3, 0])
	assert_false(bad.rewarded.has(&"b"), "récompense marquée seulement si terminée")
