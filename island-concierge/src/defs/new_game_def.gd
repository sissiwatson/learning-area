## Paramètres d'une nouvelle partie : monnaies et objets existants, soldes et
## stock de départ, capacité de l'inventaire.
class_name NewGameDef
extends Resource

@export var currencies: Array[CurrencyDef] = []
@export var items: Array[ItemDef] = []
@export var starting_balances: Dictionary[StringName, int] = {}
@export var starting_items: Dictionary[StringName, int] = {}
@export_range(1, 9999) var inventory_capacity := 50
@export var timings: TimingsDef
@export var progression: ProgressionDef
