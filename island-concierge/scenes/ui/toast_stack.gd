## Messages courts empilés en haut de l'écran (niveau atteint, quête
## terminée…). Chaque message apparaît, reste quelques secondes, puis s'efface.
class_name ToastStack
extends VBoxContainer

const VISIBLE_SECONDS := 2.6
const MAX_VISIBLE := 3


func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_BEGIN
	add_theme_constant_override(&"separation", 12)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_message(text: String, icon: Texture2D = null) -> PanelContainer:
	while get_child_count() >= MAX_VISIBLE:
		var oldest := get_child(0)
		remove_child(oldest)
		oldest.queue_free()
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"HudPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	if icon:
		var texture := TextureRect.new()
		texture.texture = icon
		texture.custom_minimum_size = Vector2(56, 56)
		texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(texture)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", 36)
	row.add_child(label)
	panel.add_child(row)
	add_child(panel)
	panel.modulate.a = 0.0
	var tween := panel.create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)
	tween.tween_interval(VISIBLE_SECONDS)
	tween.tween_property(panel, "modulate:a", 0.0, 0.4)
	tween.tween_callback(panel.queue_free)
	return panel


func messages() -> PackedStringArray:
	var texts := PackedStringArray()
	for panel in get_children():
		if not panel.is_queued_for_deletion():
			texts.append((panel.get_child(0).get_child(-1) as Label).text)
	return texts
