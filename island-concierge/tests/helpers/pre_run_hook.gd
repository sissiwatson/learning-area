## Exécuté par GUT avant les tests : la sauvegarde automatique est coupée pour
## que les tests ne lisent ni n'écrivent la vraie sauvegarde du joueur.
## Les tests de sauvegarde la réactivent avec leur propre fichier.
extends GutHookScript


func run() -> void:
	var save_manager: Node = gut.get_tree().root.get_node("SaveManager")
	save_manager.enabled = false
	save_manager.save_path = "user://gut/save.json"
