## Paramètres d'un bâtiment de rôle LODGING (hébergement).
class_name LodgingDef
extends Resource

## Propriétaire pour qui la conciergerie gère le logement ; vide = « à découvrir ».
@export var owner: NpcDef
@export_range(1, 12) var capacity := 2
## Part du prix du séjour revenant à la conciergerie.
@export_range(1, 100) var commission_percent := 20
## Objets consommés par la préparation (le panier d'accueil arrive avec les
## productions, étape 8).
@export var prepare_items: Dictionary[StringName, int] = {}
