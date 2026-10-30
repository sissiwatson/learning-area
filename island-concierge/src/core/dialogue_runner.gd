## Lecture d'un dialogue linéaire (logique pure).
class_name DialogueRunner
extends RefCounted

var dialogue: DialogueDef
var index := 0


func _init(new_dialogue: DialogueDef) -> void:
	dialogue = new_dialogue


func current() -> DialogueLineDef:
	return dialogue.lines[index] if not is_finished() else null


func is_finished() -> bool:
	return index >= dialogue.lines.size()


## Passe à la réplique suivante ; renvoie false quand le dialogue est fini.
func advance() -> bool:
	if not is_finished():
		index += 1
	return not is_finished()


## Va directement à la fin (les effets du dialogue s'appliquent quand même).
func skip() -> void:
	index = dialogue.lines.size()
