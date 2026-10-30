## Expérience et niveau du joueur (logique pure).
class_name Progression
extends RefCounted

var xp := 0
var thresholds: Array[int] = [0]


func _init(level_thresholds: Array[int] = [0]) -> void:
	thresholds = level_thresholds


func level() -> int:
	var lvl := 1
	for i in range(1, thresholds.size()):
		if xp >= thresholds[i]:
			lvl = i + 1
	return lvl


func max_level() -> int:
	return thresholds.size()


## XP du niveau courant et XP nécessaire pour le suivant (0 au niveau max).
func progress_in_level() -> Vector2i:
	var lvl := level()
	if lvl >= max_level():
		return Vector2i(0, 0)
	var floor_xp := thresholds[lvl - 1]
	return Vector2i(xp - floor_xp, thresholds[lvl] - floor_xp)


## Ajoute de l'XP ; renvoie le nombre de niveaux gagnés.
func add_xp(amount: int) -> Result:
	if amount <= 0:
		return Result.failure(&"invalid_amount")
	var before := level()
	xp = mini(xp + amount, Wallet.MAX_BALANCE)
	return Result.success(level() - before)


func to_dict() -> Dictionary:
	return {"xp": xp}


static func from_dict(data: Dictionary, level_thresholds: Array[int]) -> Progression:
	var p := Progression.new(level_thresholds)
	var value: Variant = data.get("xp", 0)
	p.xp = clampi(int(value) if (value is int or value is float) else 0, 0, Wallet.MAX_BALANCE)
	return p
