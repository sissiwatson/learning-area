## Point d'entrée du jeu : affiche Mahana avec la caméra tactile.
extends Node

@onready var map: WorldMap = $Mahana
@onready var camera: MapCamera = $Camera
@onready var _title: Label = %Title


func _ready() -> void:
	_title.text = tr("APP_TITLE")
	var bounds := map.world_bounds()
	camera.setup(bounds, bounds.get_center())
