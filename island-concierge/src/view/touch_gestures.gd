## Reconnaissance des gestes tactiles : tap, glisser à un doigt, pincer à deux
## doigts, inertie au lâcher. Reçoit des événements bruts (index, position,
## instant) et émet des signaux ; ne touche à aucun nœud.
##
## Règles :
## - un tap n'émet aucun déplacement tant que le doigt reste dans `tap_slop` ;
## - au-delà, le glisser commence depuis la position courante (pas de saut) ;
## - poser un 2e doigt annule le tap et passe en pincement ; un 3e doigt est ignoré ;
## - lever un doigt pendant un pincement reprend le glisser avec le doigt
##   restant, sans saut, et ne produit jamais de tap ;
## - un geste commencé sur l'interface (over_ui) est ignoré.
class_name TouchGestures
extends RefCounted

signal panned(screen_delta: Vector2)
signal pinched(old_center: Vector2, new_center: Vector2, factor: float)
signal tapped(screen_pos: Vector2)
signal flung(screen_velocity: Vector2)

## Distance (pixels viewport) en dessous de laquelle un appui reste un tap.
var tap_slop := 24.0
## Durée maximale d'un tap.
var tap_max_ms := 450
## Au-delà de ce délai sans mouvement avant le lâcher, pas d'inertie.
var fling_max_idle_ms := 80

var _touches := {}  # index -> Vector2, ordre d'appui conservé
var _ignored := {}  # index -> true (doigts posés sur l'interface)
var _tap_candidate := false
var _tap_start := Vector2.ZERO
var _tap_start_ms := 0
var _velocity := Vector2.ZERO
var _last_move_ms := 0
var _single_finger_drag := false


func finger_count() -> int:
	return _touches.size()


func is_dragging() -> bool:
	return _single_finger_drag


func touch(index: int, pressed: bool, pos: Vector2, time_ms: int, over_ui := false) -> void:
	if pressed:
		_press(index, pos, time_ms, over_ui)
	else:
		_release(index, pos, time_ms)


func drag(index: int, pos: Vector2, time_ms: int) -> void:
	if not _touches.has(index):
		return
	if _touches.size() == 1:
		_drag_single(index, pos, time_ms)
		return
	var keys := _touches.keys()
	var a: int = keys[0]
	var b: int = keys[1]
	if index != a and index != b:
		_touches[index] = pos  # 3e doigt : suivi mais sans effet
		return
	var old_a: Vector2 = _touches[a]
	var old_b: Vector2 = _touches[b]
	_touches[index] = pos
	var new_a: Vector2 = _touches[a]
	var new_b: Vector2 = _touches[b]
	var old_dist := old_a.distance_to(old_b)
	var factor := 1.0 if old_dist < 1.0 else new_a.distance_to(new_b) / old_dist
	pinched.emit((old_a + old_b) / 2.0, (new_a + new_b) / 2.0, factor)


## Oublie tous les doigts (ex. événement annulé par le système).
func cancel() -> void:
	_touches.clear()
	_ignored.clear()
	_tap_candidate = false
	_single_finger_drag = false
	_velocity = Vector2.ZERO


func _press(index: int, pos: Vector2, time_ms: int, over_ui: bool) -> void:
	if over_ui and _touches.is_empty():
		_ignored[index] = true
		return
	_touches[index] = pos
	_velocity = Vector2.ZERO
	if _touches.size() == 1:
		_tap_candidate = true
		_tap_start = pos
		_tap_start_ms = time_ms
		_single_finger_drag = false
	else:
		_tap_candidate = false
		_single_finger_drag = false


func _release(index: int, pos: Vector2, time_ms: int) -> void:
	if _ignored.erase(index) or not _touches.has(index):
		return
	_touches.erase(index)
	if _touches.size() == 1:
		# Fin de pincement : le doigt restant continue à glisser.
		_single_finger_drag = true
		_last_move_ms = time_ms
		return
	if not _touches.is_empty():
		return
	if _tap_candidate and time_ms - _tap_start_ms <= tap_max_ms:
		tapped.emit(pos)
	elif _single_finger_drag and time_ms - _last_move_ms <= fling_max_idle_ms:
		flung.emit(_velocity)
	_tap_candidate = false
	_single_finger_drag = false


func _drag_single(index: int, pos: Vector2, time_ms: int) -> void:
	if _tap_candidate:
		if pos.distance_to(_tap_start) <= tap_slop:
			return  # micro-mouvement d'un tap : la carte ne bouge pas
		_tap_candidate = false
		_single_finger_drag = true
		_touches[index] = pos
		_last_move_ms = time_ms
		return
	var delta: Vector2 = pos - _touches[index]
	_touches[index] = pos
	var dt := (time_ms - _last_move_ms) / 1000.0
	if dt > 0.0:
		_velocity = _velocity.lerp(delta / dt, 0.6)
	_last_move_ms = time_ms
	panned.emit(delta)
