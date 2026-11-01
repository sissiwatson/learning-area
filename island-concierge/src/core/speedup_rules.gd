## Calcul pur des accélérations de séjour (confort de jeu).
##
## Prix cumulatif : après des accélérations ayant retiré au total `removed`
## secondes d'un séjour de `total` secondes, le joueur a payé au plus
## plafond(pourcentage × commission × removed / total). Chaque palier coûte la
## différence entre ce plafond après et avant lui : plusieurs accélérations
## partielles ne coûtent jamais plus qu'une accélération complète.
## Calcul en entiers pour éviter les erreurs d'arrondi des flottants.
class_name SpeedupRules
extends RefCounted

enum Tier { ONE_NIGHT, FINISH }


## Secondes retirées par un palier, jamais plus que le temps restant.
static func stay_reduction(tier: Tier, remaining: int, night_seconds: int) -> int:
	if remaining <= 0:
		return 0
	match tier:
		Tier.ONE_NIGHT:
			return mini(maxi(night_seconds, 0), remaining)
		Tier.FINISH:
			return remaining
	return 0


## Total payé (au plus) quand `removed` secondes sur `total` ont été retirées.
static func cumulative_price(commission: int, percent: int, removed: int, total: int) -> int:
	if commission <= 0 or percent <= 0 or total <= 0 or removed <= 0:
		return 0
	var numerator := commission * percent * mini(removed, total)
	var denominator := 100 * total
	return (numerator + denominator - 1) / denominator


## Prix d'un palier : différence des prix cumulés après et avant lui.
static func step_price(commission: int, percent: int, removed_before: int, reduction: int, total: int) -> int:
	return cumulative_price(commission, percent, removed_before + reduction, total) \
			- cumulative_price(commission, percent, removed_before, total)
