extends GutTest


func _dialogue(n: int) -> DialogueDef:
	var d := DialogueDef.new()
	d.id = &"d"
	for i in n:
		var line := DialogueLineDef.new()
		line.text_key = "L%d" % i
		d.lines.append(line)
	return d


func test_lines_in_order() -> void:
	var r := DialogueRunner.new(_dialogue(3))
	assert_eq(r.current().text_key, "L0")
	assert_true(r.advance())
	assert_eq(r.current().text_key, "L1")
	assert_true(r.advance())
	assert_false(r.advance(), "fin après la dernière réplique")
	assert_true(r.is_finished())
	assert_null(r.current())
	assert_false(r.advance())


func test_skip_goes_to_the_end() -> void:
	var r := DialogueRunner.new(_dialogue(5))
	r.skip()
	assert_true(r.is_finished())
