## Personnage visible sur la carte : léger balancement, pastille quand il a
## quelque chose à dire, bulle de parole au toucher.
class_name NpcView
extends Node2D

const BUBBLE_SECONDS := 3.0
## Les personnages sont agrandis pour rester visibles sur un téléphone.
const SCALE := 1.5

var npc: NpcDef
var sprite := Sprite2D.new()
## Indice de la prochaine phrase d'ambiance (tour de rôle, déterministe).
var next_line := 0
var bubble: Label
var _marker := Node2D.new()
var _bob: Tween


func setup(def: NpcDef, local_position: Vector2) -> void:
	npc = def
	name = String(def.id)
	position = local_position
	sprite.texture = def.sprite
	sprite.centered = false
	sprite.offset = -def.sprite_anchor
	sprite.scale = Vector2.ONE * SCALE
	add_child(sprite)
	_marker.position = Vector2(0, -def.sprite_anchor.y * SCALE - 30)
	_marker.visible = false
	_marker.add_to_group(&"screen_sized")
	_marker.draw.connect(_draw_marker)
	add_child(_marker)
	# Balancement discret : une seule animation en boucle par personnage.
	_bob = create_tween().set_loops()
	_bob.tween_property(sprite, "position:y", -5.0, 0.9).set_trans(Tween.TRANS_SINE)
	_bob.tween_property(sprite, "position:y", 0.0, 0.9).set_trans(Tween.TRANS_SINE)


## Affiche la pastille « ! » (le personnage a un dialogue de quête).
func set_has_story(value: bool) -> void:
	_marker.visible = value
	_marker.queue_redraw()


func has_story() -> bool:
	return _marker.visible


func hit_test(world_pos: Vector2) -> bool:
	var local := to_local(world_pos)
	var rect := Rect2(sprite.offset * SCALE, sprite.texture.get_size() * SCALE)
	return rect.grow(8).has_point(local)


## Dit la phrase d'ambiance suivante dans une bulle ; renvoie son texte.
func say_next() -> String:
	if npc.ambient_keys.is_empty():
		return ""
	var text := tr(npc.ambient_keys[next_line % npc.ambient_keys.size()])
	next_line += 1
	show_bubble(text)
	return text


func show_bubble(text: String) -> void:
	if bubble:
		bubble.queue_free()
	bubble = Label.new()
	bubble.text = text
	bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.custom_minimum_size = Vector2(360, 0)
	bubble.add_theme_font_size_override(&"font_size", 26)
	bubble.add_theme_color_override(&"font_color", Color(0.13, 0.17, 0.22))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.95)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(14)
	bubble.add_theme_stylebox_override(&"normal", style)
	bubble.z_index = 20
	# La bulle garde la même taille à l'écran quel que soit le zoom.
	var holder := Node2D.new()
	holder.add_to_group(&"screen_sized")
	holder.position = Vector2(0, -npc.sprite_anchor.y * SCALE - 20)
	holder.scale = _marker.scale  # déjà à l'échelle écran (groupe screen_sized)
	add_child(holder)
	holder.add_child(bubble)
	bubble.reset_size()
	bubble.position = Vector2(-bubble.size.x / 2.0, -bubble.size.y)
	bubble.tree_exited.connect(holder.queue_free)
	var fade := bubble.create_tween()
	fade.tween_interval(BUBBLE_SECONDS)
	fade.tween_property(bubble, "modulate:a", 0.0, 0.4)
	fade.tween_callback(bubble.queue_free)



func _draw_marker() -> void:
	_marker.draw_circle(Vector2.ZERO, 22, Color(1.0, 0.8, 0.2))
	_marker.draw_circle(Vector2.ZERO, 22, Color(0.55, 0.35, 0.05), false, 3.0)
	_marker.draw_rect(Rect2(-4, -14, 8, 18), Color(0.3, 0.18, 0.02))
	_marker.draw_circle(Vector2(0, 10), 4.5, Color(0.3, 0.18, 0.02))
