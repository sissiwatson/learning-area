## Affichage d'un bâtiment posé : sprite, contour de sélection, test de tap.
class_name BuildingView
extends Node2D

const SELECT_COLOR := Color(1.0, 0.92, 0.4)
const SELECT_FILL := Color(1.0, 0.95, 0.6, 0.3)

var placement: PlacementDef
var selected := false: set = set_selected
## Contour de l'emprise au sol, en coordonnées locales.
var footprint_polygon := PackedVector2Array()
var sprite := Sprite2D.new()
var _badge := AttentionBadge.new()
var _hit_image: Image  # chargée au premier tap sur le dessin, puis réutilisée
## Pastille « une action vous attend » au-dessus du bâtiment.
var attention := false: set = set_attention


## Place le bâtiment sur la carte. `map_local` convertit une cellule en
## position locale du parent (centre de la cellule).
func setup(new_placement: PlacementDef, map_local: Callable) -> void:
	placement = new_placement
	name = String(placement.uid)
	var def := placement.building
	var first: Vector2 = map_local.call(placement.cell)
	var last: Vector2 = map_local.call(placement.cell + def.footprint - Vector2i.ONE)
	position = (first + last) / 2.0
	var right: Vector2 = map_local.call(placement.cell + Vector2i(def.footprint.x - 1, 0))
	var left: Vector2 = map_local.call(placement.cell + Vector2i(0, def.footprint.y - 1))
	footprint_polygon = PackedVector2Array([
		first + Vector2(0, -32) - position,
		right + Vector2(64, 0) - position,
		last + Vector2(0, 32) - position,
		left + Vector2(-64, 0) - position,
	])
	sprite.texture = def.texture
	_hit_image = null
	sprite.centered = false
	sprite.offset = -def.texture_anchor
	if sprite.get_parent() == null:
		add_child(sprite)
		_badge.position = Vector2(0, -def.texture_anchor.y + 24)
		add_child(_badge)


func set_attention(value: bool) -> void:
	attention = value
	_badge.visible = value


func set_selected(value: bool) -> void:
	selected = value
	sprite.modulate = Color(1.15, 1.15, 1.15) if value else Color.WHITE
	queue_redraw()


## Vrai si la position (monde) est sur l'emprise au sol du bâtiment.
func footprint_hit(world_pos: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(to_local(world_pos), footprint_polygon)


## Vrai si la position (monde) touche l'emprise au sol ou le dessin du bâtiment.
func hit_test(world_pos: Vector2) -> bool:
	var local := to_local(world_pos)
	if Geometry2D.is_point_in_polygon(local, footprint_polygon):
		return true
	return sprite.get_rect().has_point(local) and _opaque_at(local)


func _opaque_at(local: Vector2) -> bool:
	var px := Vector2i(local - sprite.offset)
	if _hit_image == null:
		_hit_image = sprite.texture.get_image()
	var image := _hit_image
	if image == null or not Rect2i(Vector2i.ZERO, image.get_size()).has_point(px):
		return false
	return image.get_pixelv(px).a > 0.1


func _draw() -> void:
	if selected:
		draw_colored_polygon(footprint_polygon, SELECT_FILL)
		var closed := footprint_polygon.duplicate()
		closed.append(footprint_polygon[0])
		draw_polyline(closed, SELECT_COLOR, 6.0, true)



## Pastille ronde avec un point d'exclamation.
class AttentionBadge:
	extends Node2D

	func _init() -> void:
		visible = false
		z_index = 5

	func _draw() -> void:
		draw_circle(Vector2.ZERO, 30, Color(0.1, 0.1, 0.1, 0.25))
		draw_circle(Vector2(0, -3), 28, Color(1.0, 0.8, 0.2))
		draw_circle(Vector2(0, -3), 28, Color(0.55, 0.35, 0.05), false, 4.0)
		draw_rect(Rect2(-5, -22, 10, 26), Color(0.3, 0.18, 0.02))
		draw_circle(Vector2(0, 12), 6, Color(0.3, 0.18, 0.02))
