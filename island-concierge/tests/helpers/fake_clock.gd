## Horloge simulée pour les tests : le temps n'avance que sur demande.
extends Clock

var current := 1_800_000_000


func now() -> int:
	return current


func advance(seconds: int) -> void:
	current += seconds
