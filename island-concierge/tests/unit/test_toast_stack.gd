## Pile de messages : jamais plus de MAX_VISIBLE, et le plus ancien disparaît
## proprement même pendant son animation.
extends GutTest

var stack: ToastStack


func before_each() -> void:
	stack = ToastStack.new()
	add_child_autofree(stack)


func _one_more() -> void:
	stack.show_message("nouveau")


## Un 4e message retire le plus ancien pendant que son animation tourne :
## aucune erreur moteur (tools/run_tests.sh échouerait).
func test_oldest_message_is_dropped_cleanly_while_its_animation_runs() -> void:
	for i in 3:
		stack.show_message("message %d" % i)
	await wait_process_frames(3)  # les animations ont commencé
	get_tree().process_frame.connect(_one_more, CONNECT_ONE_SHOT)
	await wait_process_frames(3)
	assert_eq(stack.get_child_count(), ToastStack.MAX_VISIBLE)
	assert_eq(stack.messages()[0], "message 1")
	assert_eq(stack.messages()[2], "nouveau")
