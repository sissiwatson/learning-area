## Point d'entrée du jeu : affiche Mahana. Étape 1 : caméra fixe cadrant
## toute l'île (la caméra tactile arrive à l'étape 2).
extends Node

@onready var _map: WorldMap = $Mahana
@onready var _camera: Camera2D = $Camera
@onready var _title: Label = %Title


func _ready() -> void:
	_title.text = tr("APP_TITLE")
	var bounds := _map.world_bounds()
	_camera.position = bounds.get_center()
	var view := get_viewport().get_visible_rect().size
	var fit := minf(view.x / bounds.size.x, view.y / bounds.size.y)
	_camera.zoom = Vector2.ONE * fit
