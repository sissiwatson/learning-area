## Niveaux et gains d'expérience. L'expérience récompense le travail de
## concierge (réserver, préparer, accueillir, terminer un séjour, produire,
## construire) ; les quêtes guident sans donner d'XP en double.
class_name ProgressionDef
extends Resource

## XP cumulée nécessaire pour chaque niveau : [0, 50, 150, ...] = niveau 1
## dès 0 XP, niveau 2 à 50 XP, etc. Strictement croissante.
@export var level_thresholds: Array[int] = [0, 50, 150, 300, 500, 800]
@export var xp_booking_accepted := 5
@export var xp_lodging_prepared := 5
@export var xp_guests_welcomed := 5
@export var xp_stay_completed := 25
