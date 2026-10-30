## Arrivée des voyageurs : le bateau de Tao accoste au ponton, deux voyageurs
## débarquent et marchent jusqu'au logement en suivant le chemin des données.
## Purement visuel : n'influence aucune règle de jeu.
class_name ArrivalAnimation
extends Node2D

signal finished

const BOAT := preload("res://assets/characters/boat_tao.png")
const GUESTS := [preload("res://assets/characters/guest_a.png"), preload("res://assets/characters/guest_b.png")]
const BOAT_SECONDS := 2.5
const WALK_SPEED := 160.0  # pixels monde par seconde

var boat := Sprite2D.new()
var walkers: Array[Sprite2D] = []
var _tweens: Array[Tween] = []


## `path` : positions locales du ponton à la porte ; `reverse` = départ.
func play(path: PackedVector2Array, reverse := false) -> void:
	var points := path.duplicate()
	if reverse:
		points.reverse()
	var pier := path[0]
	boat.texture = BOAT
	boat.offset = Vector2(0, -40)
	boat.scale = Vector2.ONE * 1.4
	add_child(boat)
	var sea := pier + Vector2(260, 220)
	var dock := pier + Vector2(90, 70)
	var boat_tween := create_tween()
	_tweens.append(boat_tween)
	if reverse:
		boat.position = dock
		boat_tween.tween_interval(_walk_time(points) + 0.3)
		boat_tween.tween_property(boat, "position", sea, BOAT_SECONDS).set_trans(Tween.TRANS_SINE)
		boat_tween.parallel().tween_property(boat, "modulate:a", 0.0, BOAT_SECONDS)
	else:
		boat.position = sea
		boat.modulate.a = 0.0
		boat_tween.tween_property(boat, "position", dock, BOAT_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		boat_tween.parallel().tween_property(boat, "modulate:a", 1.0, 0.6)
		boat_tween.tween_interval(_walk_time(points) + 0.3)
		boat_tween.tween_property(boat, "position", sea, BOAT_SECONDS)
		boat_tween.parallel().tween_property(boat, "modulate:a", 0.0, BOAT_SECONDS)
	for i in GUESTS.size():
		var walker := Sprite2D.new()
		walker.texture = GUESTS[i]
		walker.centered = false
		walker.offset = -Vector2(32, 118)
		walker.scale = Vector2.ONE * NpcView.SCALE
		walker.position = points[0] + Vector2(i * 22, i * 8)
		walker.modulate.a = 0.0
		add_child(walker)
		walkers.append(walker)
		var t := create_tween()
		_tweens.append(t)
		t.tween_interval((0.0 if reverse else BOAT_SECONDS) + i * 0.4)
		t.tween_property(walker, "modulate:a", 1.0, 0.3)
		for k in range(1, points.size()):
			var target := points[k] + Vector2(i * 22, i * 8)
			t.tween_property(walker, "position", target, points[k - 1].distance_to(points[k]) / WALK_SPEED)
		t.tween_property(walker, "modulate:a", 0.0, 0.3)
	boat_tween.finished.connect(_on_done)


## Termine immédiatement l'animation (tests, ou si le joueur quitte la vue).
func fast_forward() -> void:
	for t in _tweens:
		if t.is_valid():
			t.custom_step(1000.0)


func _walk_time(points: PackedVector2Array) -> float:
	var length := 0.0
	for k in range(1, points.size()):
		length += points[k - 1].distance_to(points[k])
	return length / WALK_SPEED + GUESTS.size() * 0.4 + 0.6


func _on_done() -> void:
	finished.emit()
	queue_free()
