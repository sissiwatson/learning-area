## Paramètres d'un bâtiment de rôle LODGING (hébergement).
class_name LodgingDef
extends Resource

## Nom du propriétaire pour qui la conciergerie gère le logement (nom propre,
## non traduit).
@export var owner_name := ""
@export_range(1, 12) var capacity := 2
