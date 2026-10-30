## Catalogue des données de jeu (autoload `Database`) : charge tous les
## fichiers de data/, les indexe par identifiant et les fait valider par
## DataValidator. En développement, chaque problème est signalé au lancement.
extends Node

const DATA_ROOT := "res://data"
## Dossier -> clé du catalogue.
const FOLDERS := {
	"currencies": "currencies", "items": "items", "recipes": "recipes", "npcs": "npcs",
	"bookings": "bookings", "buildings": "buildings", "quests": "quests", "maps": "maps",
	"dialogues": "dialogues",
}

var catalog := {}
var errors := PackedStringArray()


func _ready() -> void:
	reload()
	if OS.is_debug_build():
		for e in errors:
			push_error("Données : " + e)


func reload() -> void:
	catalog = {}
	for folder in FOLDERS:
		catalog[FOLDERS[folder]] = load_folder(DATA_ROOT.path_join(folder))
	catalog["new_games"] = [load(DATA_ROOT.path_join("balance/new_game.tres"))]
	catalog["timings"] = [load(DATA_ROOT.path_join("balance/timings.tres"))]
	errors = DataValidator.validate(catalog)


func get_def(type: String, id: StringName) -> Resource:
	for def in catalog.get(type, []):
		if def.id == id:
			return def
	return null


## Charge toutes les ressources d'un dossier, triées par nom de fichier.
## Gère les fichiers convertis à l'export (« .tres.remap »).
static func load_folder(path: String) -> Array:
	var result := []
	var names := PackedStringArray()
	for file in DirAccess.get_files_at(path):
		var name := file.trim_suffix(".remap")
		if name.ends_with(".tres") or name.ends_with(".res"):
			names.append(name)
	names.sort()
	for name in names:
		var res := load(path.path_join(name))
		if res:
			result.append(res)
	return result
