## Couche d'interface au-dessus de la carte.
extends CanvasLayer


## Vrai si la position écran est sur un élément d'interface visible
## (groupe "ui_blocker") : la carte ignore alors le geste.
func is_point_over_ui(screen_pos: Vector2) -> bool:
	for node in get_tree().get_nodes_in_group(&"ui_blocker"):
		var control := node as Control
		if control and control.is_visible_in_tree() and control.get_global_rect().has_point(screen_pos):
			return true
	return false
