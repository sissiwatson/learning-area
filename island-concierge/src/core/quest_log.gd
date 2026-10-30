## Journal des quêtes (logique pure).
##
## LOCKED -> AVAILABLE (prérequis terminés) -> ACTIVE (après le dialogue
## d'introduction) -> COMPLETED (tous les objectifs atteints).
## Seuls les événements survenus pendant qu'une quête est ACTIVE comptent.
## Les récompenses sont marquées comme accordées : jamais deux fois.
class_name QuestLog
extends RefCounted

enum Status { LOCKED, AVAILABLE, ACTIVE, COMPLETED }

var quests: Array[QuestDef] = []
var status := {}  # id -> Status
var progress := {}  # id -> Array[int], un compteur par objectif
var rewarded := {}  # id -> true


func _init(new_quests: Array[QuestDef] = []) -> void:
	quests = new_quests
	for q in quests:
		status[q.id] = Status.LOCKED
		progress[q.id] = []
		for o in q.objectives:
			progress[q.id].append(0)


func get_quest(id: StringName) -> QuestDef:
	for q in quests:
		if q.id == id:
			return q
	return null


func get_status(id: StringName) -> Status:
	return status.get(id, Status.LOCKED)


func with_status(wanted: Status) -> Array[QuestDef]:
	var result: Array[QuestDef] = []
	for q in quests:
		if status[q.id] == wanted:
			result.append(q)
	return result


## Débloque les quêtes dont les prérequis sont terminés ; renvoie les nouvelles.
func refresh() -> Array[QuestDef]:
	var unlocked: Array[QuestDef] = []
	for q in quests:
		if status[q.id] != Status.LOCKED:
			continue
		var ready := true
		for pre in q.prerequisites:
			ready = ready and get_status(pre) == Status.COMPLETED
		if ready:
			status[q.id] = Status.AVAILABLE
			unlocked.append(q)
	return unlocked


func start(id: StringName) -> Result:
	if get_status(id) != Status.AVAILABLE:
		return Result.failure(&"quest_not_available")
	status[id] = Status.ACTIVE
	return Result.success()


## Compte un événement ; renvoie les quêtes terminées par celui-ci.
func record(event: StringName, target: StringName, amount := 1) -> Array[QuestDef]:
	var done: Array[QuestDef] = []
	if amount <= 0:
		return done
	for q in quests:
		if status[q.id] != Status.ACTIVE:
			continue
		var counters: Array = progress[q.id]
		for i in q.objectives.size():
			var o := q.objectives[i]
			if o.event == event and (o.target == &"" or o.target == target):
				counters[i] = mini(counters[i] + amount, o.amount)
		if is_satisfied(q):
			status[q.id] = Status.COMPLETED
			done.append(q)
	return done


func is_satisfied(q: QuestDef) -> bool:
	for i in q.objectives.size():
		if progress[q.id][i] < q.objectives[i].amount:
			return false
	return true


## Marque la récompense comme accordée ; false si elle l'était déjà.
func claim_reward(id: StringName) -> bool:
	if get_status(id) != Status.COMPLETED or rewarded.has(id):
		return false
	rewarded[id] = true
	return true


func to_dict() -> Dictionary:
	var out := {}
	for q in quests:
		out[q.id] = {"status": Status.keys()[status[q.id]], "progress": progress[q.id].duplicate(), "rewarded": rewarded.has(q.id)}
	return out


## Restaure l'état ; quêtes inconnues ignorées, compteurs bornés.
func load_dict(data: Dictionary) -> void:
	for q in quests:
		var entry: Variant = data.get(String(q.id), data.get(q.id))
		if not entry is Dictionary:
			continue
		status[q.id] = Status.get(str(entry.get("status", "LOCKED")), Status.LOCKED)
		var saved: Variant = entry.get("progress", [])
		for i in q.objectives.size():
			var v: Variant = saved[i] if saved is Array and i < saved.size() else 0
			progress[q.id][i] = clampi(int(v) if (v is int or v is float) else 0, 0, q.objectives[i].amount)
		if entry.get("rewarded", false) == true and status[q.id] == Status.COMPLETED:
			rewarded[q.id] = true
