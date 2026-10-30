## Durées en temps réel du prototype (secondes). Les recettes et les
## constructions portent leur propre durée ; ici, les durées communes.
class_name TimingsDef
extends Resource

## Une nuit touristique.
@export_range(1, 86400) var night_seconds := 300
## Ménage avant l'arrivée des voyageurs.
@export_range(1, 86400) var cleaning_seconds := 120
## Délai d'apparition d'une nouvelle offre de réservation.
@export_range(1, 86400) var offer_refresh_seconds := 60
## Excursion courte (activités futures).
@export_range(1, 86400) var excursion_min_seconds := 180
@export_range(1, 86400) var excursion_max_seconds := 300
