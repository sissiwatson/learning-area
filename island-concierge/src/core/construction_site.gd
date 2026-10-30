## Chantier d'un emplacement constructible : IDLE -> BUILDING -> BUILT.
## Le minuteur est un horodatage de fin (avance application fermée).
class_name ConstructionSite
extends RefCounted

enum State { IDLE, BUILDING, BUILT }

var state := State.IDLE
var start_at := 0
var end_at := 0


func start(now: int, seconds: int) -> Result:
	if state != State.IDLE:
		return Result.failure(&"already_started")
	state = State.BUILDING
	start_at = now
	end_at = now + maxi(seconds, 0)
	return Result.success()


## Renvoie true si la construction vient de se terminer.
func update(now: int) -> bool:
	if state == State.BUILDING and now >= end_at:
		state = State.BUILT
		return true
	return false


func remaining(now: int) -> int:
	return maxi(end_at - now, 0) if state == State.BUILDING else 0


func progress(now: int) -> float:
	if state != State.BUILDING or end_at <= start_at:
		return 1.0 if state == State.BUILT else 0.0
	return clampf(float(now - start_at) / (end_at - start_at), 0.0, 1.0)


func to_dict() -> Dictionary:
	return {"state": State.keys()[state], "start_at": start_at, "end_at": end_at}


static func from_dict(data: Dictionary) -> ConstructionSite:
	var c := ConstructionSite.new()
	c.state = State.get(str(data.get("state", "IDLE")), State.IDLE)
	c.start_at = int(data.get("start_at", 0))
	c.end_at = int(data.get("end_at", 0))
	if c.state == State.BUILDING and c.end_at < c.start_at:
		c.state = State.IDLE
	return c
