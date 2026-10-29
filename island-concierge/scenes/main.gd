## Point d'entrée du jeu. À l'étape 0, affiche seulement un écran titre.
extends Control

@onready var _title: Label = %Title
@onready var _tagline: Label = %Tagline


func _ready() -> void:
	_title.text = tr("APP_TITLE")
	_tagline.text = tr("APP_TAGLINE")
