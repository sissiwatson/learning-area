## Machine à états d'un logement (docs/ARCHITECTURE.md §3).
##
## VACANT → BOOKED → READY → OCCUPIED → STAY_COMPLETE → VACANT
##
## Étape 3 : seules les transitions sont modélisées. Les coûts (panier
## d'accueil), la durée du séjour et la commission seront branchés aux
## étapes Économie, Réservations et Productions.
class_name Lodging
extends RefCounted

enum State { VACANT, BOOKED, READY, OCCUPIED, STAY_COMPLETE }
enum Action { ACCEPT_BOOKING, PREPARE, WELCOME_GUESTS, END_STAY, COLLECT_COMMISSION }

## Action -> [état de départ, état d'arrivée]
const TRANSITIONS := {
	Action.ACCEPT_BOOKING: [State.VACANT, State.BOOKED],
	Action.PREPARE: [State.BOOKED, State.READY],
	Action.WELCOME_GUESTS: [State.READY, State.OCCUPIED],
	Action.END_STAY: [State.OCCUPIED, State.STAY_COMPLETE],
	Action.COLLECT_COMMISSION: [State.STAY_COMPLETE, State.VACANT],
}

var state := State.VACANT
## Logement dans une zone pas encore débloquée : aucune action possible.
var locked := false


func can_perform(action: Action) -> bool:
	return not locked and TRANSITIONS.has(action) and TRANSITIONS[action][0] == state


func available_actions() -> Array[Action]:
	var result: Array[Action] = []
	for action in TRANSITIONS:
		if can_perform(action):
			result.append(action)
	return result


## Applique l'action si elle est permise ; sinon ne change rien.
func perform(action: Action) -> Result:
	if locked:
		return Result.failure(&"lodging_locked")
	if not can_perform(action):
		return Result.failure(&"invalid_action")
	state = TRANSITIONS[action][1]
	return Result.success(state)
