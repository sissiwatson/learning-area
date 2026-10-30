## Mise en forme des nombres pour l'interface (convention française).
class_name NumberFormat
extends RefCounted

## Espace insécable entre les milliers : 1234567 -> "1 234 567".
const THOUSANDS_SEPARATOR := " "


static func thousands(value: int) -> String:
	var digits := str(absi(value))
	var groups := PackedStringArray()
	while digits.length() > 3:
		groups.insert(0, digits.right(3))
		digits = digits.left(digits.length() - 3)
	groups.insert(0, digits)
	return ("-" if value < 0 else "") + THOUSANDS_SEPARATOR.join(groups)


## Durée lisible : 45 -> "45 s", 90 -> "1 min 30 s", 3900 -> "1 h 05 min".
static func duration(seconds: int) -> String:
	var s := maxi(seconds, 0)
	if s < 60:
		return "%d s" % s
	if s < 3600:
		return "%d min" % (s / 60) if s % 60 == 0 else "%d min %02d s" % [s / 60, s % 60]
	var minutes := (s % 3600) / 60
	return "%d h" % (s / 3600) if minutes == 0 else "%d h %02d min" % [s / 3600, minutes]
