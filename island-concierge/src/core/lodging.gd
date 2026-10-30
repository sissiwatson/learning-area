## Machine à états d'un logement, avec minuteurs en temps réel.
##
## VACANT --book--> BOOKED --prepare--> PREPARING --(ménage écoulé)--> READY
##   ^                                                                   |
##   |                                                            welcome_guests
##   +--collect_commission-- STAY_COMPLETE <--(nuits écoulées)-- OCCUPIED
##
## Les minuteurs sont des horodatages de fin : ils « continuent » pendant que
## le jeu est fermé ; `update(now)` applique les transitions automatiques.
## Toute transition invalide renvoie un échec et ne modifie rien.
class_name Lodging
extends RefCounted

enum State { VACANT, BOOKED, PREPARING, READY, OCCUPIED, STAY_COMPLETE }
## Actions du joueur sur le logement (la réservation se fait au bureau).
enum Action { PREPARE, WELCOME_GUESTS, COLLECT_COMMISSION }

const ACTION_STATES := {
	Action.PREPARE: State.BOOKED,
	Action.WELCOME_GUESTS: State.READY,
	Action.COLLECT_COMMISSION: State.STAY_COMPLETE,
}

var state := State.VACANT
## Logement dans une zone pas encore débloquée : aucune action possible.
var locked := false
var capacity := 2
var booking: Booking
## Début et fin du minuteur en cours (ménage ou séjour), en secondes Unix.
var timer_start := 0
var timer_end := 0


func available_actions() -> Array[Action]:
	var result: Array[Action] = []
	if not locked:
		for action in ACTION_STATES:
			if ACTION_STATES[action] == state:
				result.append(action)
	return result


func can_book(guests: int) -> Result:
	if locked:
		return Result.failure(&"lodging_locked")
	if state != State.VACANT:
		return Result.failure(&"lodging_not_vacant")
	if guests > capacity:
		return Result.failure(&"capacity_exceeded")
	return Result.success()


func book(new_booking: Booking) -> Result:
	var check := can_book(new_booking.guests)
	if not check.ok:
		return check
	booking = new_booking
	state = State.BOOKED
	return Result.success()


func start_preparing(now: int, cleaning_seconds: int) -> Result:
	var check := _expect(State.BOOKED)
	if not check.ok:
		return check
	state = State.PREPARING
	_start_timer(now, cleaning_seconds)
	return Result.success()


func welcome_guests(now: int, night_seconds: int) -> Result:
	var check := _expect(State.READY)
	if not check.ok:
		return check
	state = State.OCCUPIED
	_start_timer(now, booking.nights * night_seconds)
	return Result.success()


## Termine le séjour et rend le logement libre ; renvoie la réservation payée.
func collect_commission() -> Result:
	var check := _expect(State.STAY_COMPLETE)
	if not check.ok:
		return check
	var paid := booking
	booking = null
	state = State.VACANT
	timer_start = 0
	timer_end = 0
	return Result.success(paid)


## Applique les fins de minuteur. Renvoie les états atteints (souvent vide).
func update(now: int) -> Array[State]:
	var reached: Array[State] = []
	if state == State.PREPARING and now >= timer_end:
		state = State.READY
		reached.append(state)
	elif state == State.OCCUPIED and now >= timer_end:
		state = State.STAY_COMPLETE
		reached.append(state)
	return reached


func is_timing() -> bool:
	return state == State.PREPARING or state == State.OCCUPIED


func remaining(now: int) -> int:
	return maxi(timer_end - now, 0) if is_timing() else 0


## Avancement du minuteur en cours, de 0 à 1.
func progress(now: int) -> float:
	var total := timer_end - timer_start
	if not is_timing() or total <= 0:
		return 0.0
	return clampf(float(now - timer_start) / total, 0.0, 1.0)


func to_dict() -> Dictionary:
	return {
		"state": State.keys()[state], "timer_start": timer_start, "timer_end": timer_end,
		"booking": booking.to_dict() if booking else null,
	}


## Restaure un état sauvegardé ; un état incohérent (ex. séjour sans
## réservation) revient à VACANT plutôt que de bloquer le logement.
static func from_dict(data: Dictionary, lodging_capacity: int, is_locked: bool) -> Lodging:
	var l := Lodging.new()
	l.capacity = lodging_capacity
	l.locked = is_locked
	var state_name := str(data.get("state", "VACANT"))
	l.state = State.get(state_name, State.VACANT)
	l.timer_start = int(data.get("timer_start", 0))
	l.timer_end = int(data.get("timer_end", 0))
	var booking_data: Variant = data.get("booking")
	if booking_data is Dictionary:
		l.booking = Booking.from_dict(booking_data)
	if l.state != State.VACANT and l.booking == null:
		l.state = State.VACANT
	return l


func _expect(expected: State) -> Result:
	if locked:
		return Result.failure(&"lodging_locked")
	if state != expected:
		return Result.failure(&"invalid_action")
	return Result.success()


func _start_timer(now: int, duration: int) -> void:
	timer_start = now
	timer_end = now + maxi(duration, 0)
