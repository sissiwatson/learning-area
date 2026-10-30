## « +3 ananas » qui s'élève au-dessus d'un bâtiment puis s'efface.
class_name FloatingReward
extends Node2D

const RISE := 110.0
const SECONDS := 1.4

var label := Label.new()
var _tween: Tween


func setup(text: String, icon: Texture2D) -> void:
	z_index = 30
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 6)
	if icon:
		var texture := TextureRect.new()
		texture.texture = icon
		texture.custom_minimum_size = Vector2(52, 52)
		texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(texture)
	label.text = text
	label.add_theme_font_size_override(&"font_size", 40)
	label.add_theme_color_override(&"font_color", Color.WHITE)
	label.add_theme_color_override(&"font_outline_color", Color(0.1, 0.25, 0.3))
	label.add_theme_constant_override(&"outline_size", 10)
	row.add_child(label)
	add_child(row)
	row.position = Vector2(-60, -30)
	_tween = create_tween()
	_tween.tween_property(self, "position:y", position.y - RISE, SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.parallel().tween_property(self, "modulate:a", 0.0, SECONDS * 0.5).set_delay(SECONDS * 0.5)
	_tween.tween_callback(queue_free)


func fast_forward() -> void:
	if _tween and _tween.is_valid():
		_tween.custom_step(100.0)
