## Source du temps (secondes Unix). Le jeu utilise l'horloge système ; les
## tests la remplacent par une horloge simulée (tests/helpers/fake_clock.gd)
## pour vérifier minuteurs et progression hors-ligne de façon déterministe.
class_name Clock
extends RefCounted


func now() -> int:
	return int(Time.get_unix_time_from_system())
