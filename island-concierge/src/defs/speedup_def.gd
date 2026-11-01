## Barème des accélérations facultatives (confort de jeu). Une accélération
## ne fait que terminer plus tôt le minuteur : durée contractuelle, prix payé
## par le voyageur, commission et revenus du propriétaire ne changent pas.
class_name SpeedupDef
extends Resource

## Prix d'un séjour terminé d'un coup, en pourcentage de sa commission
## (arrondi à l'entier supérieur). Les accélérations partielles sont payées
## en cumulé : leur somme ne dépasse jamais ce prix.
@export_range(0, 100) var stay_full_commission_percent := 15
## Accélérations complètes offertes une seule fois par partie (y compris aux
## sauvegardes qui n'en ont jamais reçu).
@export_range(0, 10) var free_full_speedups := 1
