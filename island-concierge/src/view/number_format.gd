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
