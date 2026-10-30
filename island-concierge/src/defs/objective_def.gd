## Objectif de quête : compter `amount` événements `event` (cible facultative).
## Les événements reconnus sont listés dans GameEvents.
class_name ObjectiveDef
extends Resource

@export var event: StringName
## Identifiant de la cible (objet ou bâtiment) selon l'événement ; vide sinon.
@export var target: StringName
@export_range(1, 999) var amount := 1
