extends GutTest

var inv: Inventory


func before_each() -> void:
	inv = Inventory.new([&"pineapple", &"welcome_basket"], 10)


func test_add_and_remove() -> void:
	assert_true(inv.add({&"pineapple": 3}).ok)
	assert_true(inv.remove({&"pineapple": 3}).ok)
	assert_eq(inv.count(&"pineapple"), 0)


func test_missing_items_changes_nothing() -> void:
	inv.add({&"pineapple": 2})
	var r := inv.remove({&"pineapple": 3})
	assert_false(r.ok)
	assert_eq(r.error, &"missing_items")
	assert_eq(inv.count(&"pineapple"), 2)


func test_multi_item_remove_is_atomic() -> void:
	inv.add({&"pineapple": 3})
	assert_false(inv.remove({&"pineapple": 3, &"welcome_basket": 1}).ok)
	assert_eq(inv.count(&"pineapple"), 3)


func test_capacity_is_respected_atomically() -> void:
	inv.add({&"pineapple": 8})
	var r := inv.add({&"pineapple": 1, &"welcome_basket": 2})
	assert_false(r.ok)
	assert_eq(r.error, &"inventory_full")
	assert_eq(inv.total(), 8)
	assert_true(inv.add({&"pineapple": 1, &"welcome_basket": 1}).ok)
	assert_eq(inv.free_space(), 0)


func test_invalid_requests() -> void:
	assert_eq(inv.add({&"coconut": 1}).error, &"unknown_item")
	assert_eq(inv.add({&"pineapple": 0}).error, &"invalid_amount")
	assert_eq(inv.add({&"pineapple": -1}).error, &"invalid_amount")
	assert_eq(inv.add({}).error, &"invalid_amount")
	assert_eq(inv.total(), 0)


func test_has_all() -> void:
	inv.add({&"pineapple": 3, &"welcome_basket": 1})
	assert_true(inv.has_all({&"pineapple": 3}))
	assert_true(inv.has_all({&"pineapple": 3, &"welcome_basket": 1}))
	assert_false(inv.has_all({&"pineapple": 4}))


func test_round_trip_and_sanitizing() -> void:
	inv.add({&"pineapple": 3, &"welcome_basket": 1})
	var copy := Inventory.from_dict(JSON.parse_string(JSON.stringify(inv.to_dict())), [&"pineapple", &"welcome_basket"])
	assert_eq(copy.count(&"pineapple"), 3)
	assert_eq(copy.count(&"welcome_basket"), 1)
	assert_eq(copy.capacity, 10)
	var bad := Inventory.from_dict({"capacity": 5, "counts": {"pineapple": 99, "welcome_basket": -2, "rock": 4}},
			[&"pineapple", &"welcome_basket"])
	assert_eq(bad.count(&"pineapple"), 5, "ramené à la capacité")
	assert_eq(bad.count(&"welcome_basket"), 0)
	assert_lte(bad.total(), bad.capacity)
