## Caméra de la carte : traduit les événements d'entrée en gestes
## (TouchGestures) puis en mouvements de caméra (CameraRig).
##
## Performances : aucun traitement par image hors inertie (_process désactivé
## dès que la caméra est immobile).
class_name MapCamera
extends Camera2D

## Émis lors d'un tap sur la carte (hors interface), en coordonnées monde.
signal tapped_world(world_pos: Vector2)
## Émis une fois par geste du joueur (quêtes de prise en main).
signal user_panned
signal user_zoomed
## Le niveau de zoom a changé (éléments à taille constante à l'écran).
signal zoom_changed(zoom: float)

@export var max_zoom_level := 2.0
@export var initial_zoom_level := 0.8
## Facteur appliqué par cran de molette.
@export var wheel_step := 1.15

var rig := CameraRig.new()
var gestures := TouchGestures.new()
## Callable(screen_pos: Vector2) -> bool : vrai si la position est sur l'interface.
var ui_hit_test := Callable()
var _reported := {}  # gestes déjà signalés pendant le contact en cours


func _ready() -> void:
	gestures.panned.connect(_on_panned)
	gestures.pinched.connect(_on_pinched)
	gestures.tapped.connect(_on_tapped)
	gestures.flung.connect(_on_flung)
	get_viewport().size_changed.connect(_on_viewport_resized)
	set_process(false)


## À appeler une fois la carte construite. `view_size` permet d'imposer une
## taille de vue (tests) ; par défaut, celle du viewport.
func setup(world_bounds: Rect2, focus: Vector2, view_size := Vector2.ZERO) -> void:
	var size := view_size if view_size != Vector2.ZERO else get_viewport_rect().size
	rig.configure(size, world_bounds, max_zoom_level)
	rig.set_zoom(initial_zoom_level)
	rig.center_on(focus)
	_apply()


func _unhandled_input(event: InputEvent) -> void:
	if handle_input(event):
		get_viewport().set_input_as_handled()


## Traite un événement ; renvoie true s'il a été consommé. `time_ms` permet
## aux tests de rejouer des gestes à des instants précis.
func handle_input(event: InputEvent, time_ms := -1) -> bool:
	var t := Time.get_ticks_msec() if time_ms < 0 else time_ms
	var touch := event as InputEventScreenTouch
	if touch:
		if not touch.pressed and gestures.finger_count() <= 1:
			_reported.clear()
		if touch.canceled:
			gestures.cancel()
		else:
			var over_ui := touch.pressed and _is_over_ui(touch.position)
			gestures.touch(touch.index, touch.pressed, touch.position, t, over_ui)
		return true
	var drag := event as InputEventScreenDrag
	if drag:
		gestures.drag(drag.index, drag.position, t)
		return true
	var button := event as InputEventMouseButton
	if button and button.pressed:
		if button.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at(button.position, wheel_step)
			return true
		if button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at(button.position, 1.0 / wheel_step)
			return true
	var magnify := event as InputEventMagnifyGesture
	if magnify:
		_zoom_at(magnify.position, magnify.factor)
		return true
	return false


func _process(delta: float) -> void:
	if not rig.step(delta):
		set_process(false)
	_apply()


## Applique tout de suite la position et le zoom du modèle (cadrages
## programmés) ; prévient les abonnés si le zoom change.
func apply_now() -> void:
	_apply()


func _apply() -> void:
	position = rig.position
	if not is_equal_approx(zoom.x, rig.zoom):
		zoom = Vector2.ONE * rig.zoom
		zoom_changed.emit(rig.zoom)


func _zoom_at(screen_pos: Vector2, factor: float) -> void:
	_report(&"zoom")
	_reported.erase(&"zoom")  # molette : chaque cran est un geste
	rig.stop()
	rig.zoom_at(screen_pos, factor)
	_apply()


func _is_over_ui(screen_pos: Vector2) -> bool:
	return ui_hit_test.is_valid() and bool(ui_hit_test.call(screen_pos))


func _report(kind: StringName) -> void:
	if _reported.has(kind):
		return
	_reported[kind] = true
	if kind == &"pan":
		user_panned.emit()
	else:
		user_zoomed.emit()


func _on_panned(delta: Vector2) -> void:
	_report(&"pan")
	rig.stop()
	rig.pan_screen(delta)
	_apply()


func _on_pinched(old_center: Vector2, new_center: Vector2, factor: float) -> void:
	if not is_equal_approx(factor, 1.0):
		_report(&"zoom")
	rig.stop()
	rig.pinch(old_center, new_center, factor)
	_apply()


func _on_tapped(screen_pos: Vector2) -> void:
	rig.stop()
	tapped_world.emit(rig.screen_to_world(screen_pos))


func _on_flung(screen_velocity: Vector2) -> void:
	rig.fling(screen_velocity)
	set_process(true)


func _on_viewport_resized() -> void:
	if rig.bounds.has_area():
		rig.configure(get_viewport_rect().size, rig.bounds, max_zoom_level)
		_apply()
