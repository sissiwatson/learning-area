## Cadenas et nom d'une zone verrouillée, dessinés au-dessus de la carte.
extends Node2D

var text := ""


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var size := 40
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	# Cartouche
	var box := Rect2(-w / 2 - 24, 20, w + 48, 64)
	draw_rect(box, Color(0.08, 0.08, 0.14, 0.75))
	draw_string(font, Vector2(-w / 2, 66), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color.WHITE)
	# Cadenas
	draw_arc(Vector2(0, -24), 22, PI, TAU, 24, Color(0.92, 0.92, 0.95), 9)
	draw_rect(Rect2(-34, -26, 68, 52), Color(0.95, 0.75, 0.25))
	draw_circle(Vector2(0, -4), 8, Color(0.3, 0.2, 0.1))
	draw_rect(Rect2(-3, -2, 6, 16), Color(0.3, 0.2, 0.1))
