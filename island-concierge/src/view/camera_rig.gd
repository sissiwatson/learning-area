## État et calculs de la caméra de carte : déplacement, zoom centré sur un
## point, limites, inertie. Aucune dépendance aux nœuds : tout est testable.
##
## Conventions : coordonnées « écran » = pixels du viewport (base 1920×1080),
## coordonnées « monde » = pixels de la carte. zoom > 1 = rapproché.
class_name CameraRig
extends RefCounted

## Vitesse (monde/s) sous laquelle l'inertie s'arrête.
const STOP_SPEED := 8.0

var view_size := Vector2(1920, 1080)
var bounds := Rect2()
var min_zoom := 0.5
var max_zoom := 2.0
var position := Vector2.ZERO
var zoom := 1.0
## Vitesse d'inertie, en unités monde par seconde.
var velocity := Vector2.ZERO
## Amortissement exponentiel de l'inertie (par seconde).
var friction := 5.0


## Définit la zone navigable. Le zoom minimum fait tenir toute la carte à l'écran.
func configure(new_view_size: Vector2, new_bounds: Rect2, new_max_zoom: float) -> void:
	view_size = new_view_size
	bounds = new_bounds
	min_zoom = fit_zoom()
	max_zoom = maxf(new_max_zoom, min_zoom)
	set_zoom(zoom)


func fit_zoom() -> float:
	return minf(view_size.x / bounds.size.x, view_size.y / bounds.size.y)


func set_zoom(value: float) -> void:
	zoom = clampf(value, min_zoom, max_zoom)
	clamp_position()


func center_on(world_pos: Vector2) -> void:
	position = world_pos
	clamp_position()


func screen_to_world(screen_pos: Vector2) -> Vector2:
	return position + (screen_pos - view_size / 2.0) / zoom


func world_to_screen(world_pos: Vector2) -> Vector2:
	return (world_pos - position) * zoom + view_size / 2.0


## Rectangle du monde actuellement visible.
func visible_rect() -> Rect2:
	var size := view_size / zoom
	return Rect2(position - size / 2.0, size)


## Déplace la vue pour que le contenu suive le doigt de `screen_delta`.
func pan_screen(screen_delta: Vector2) -> void:
	position -= screen_delta / zoom
	clamp_position()


## Zoom d'un facteur en gardant fixe le point du monde sous `screen_point`.
func zoom_at(screen_point: Vector2, factor: float) -> void:
	pinch(screen_point, screen_point, factor)


## Pincement : le point du monde sous `old_center` se retrouve sous
## `new_center` (zoom et déplacement à deux doigts simultanés).
func pinch(old_center: Vector2, new_center: Vector2, factor: float) -> void:
	var anchor := screen_to_world(old_center)
	zoom = clampf(zoom * factor, min_zoom, max_zoom)
	position = anchor - (new_center - view_size / 2.0) / zoom
	clamp_position()


## Garde la vue dans les limites ; si la carte est plus petite que la vue sur
## un axe, la centre sur cet axe.
func clamp_position() -> void:
	var half := view_size / 2.0 / zoom
	for axis in 2:
		var lo := bounds.position[axis] + half[axis]
		var hi := bounds.end[axis] - half[axis]
		position[axis] = (lo + hi) / 2.0 if lo > hi else clampf(position[axis], lo, hi)


## Lance l'inertie avec une vitesse de doigt en pixels écran par seconde.
func fling(screen_velocity: Vector2) -> void:
	velocity = -screen_velocity / zoom


func stop() -> void:
	velocity = Vector2.ZERO


## Avance l'inertie de `delta` secondes. Renvoie false quand elle est terminée.
func step(delta: float) -> bool:
	if velocity.length() < STOP_SPEED:
		velocity = Vector2.ZERO
		return false
	var before := position + velocity * delta
	position = before
	clamp_position()
	# Butée contre une limite : la vitesse sur cet axe s'annule.
	for axis in 2:
		if not is_equal_approx(position[axis], before[axis]):
			velocity[axis] = 0.0
	velocity *= exp(-friction * delta)
	return true
