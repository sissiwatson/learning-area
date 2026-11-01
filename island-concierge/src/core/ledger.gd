## Classement comptable des motifs du porte-monnaie (pur).
class_name Ledger
extends RefCounted

const UNCATEGORIZED := &"uncategorized"


## Catégorie d'un motif : préfixe le plus long qui correspond, sinon
## UNCATEGORIZED.
static func category_of(reason: String, prefixes: Dictionary) -> StringName:
	var best := ""
	for prefix: String in prefixes:
		if reason.begins_with(prefix) and prefix.length() > best.length():
			best = prefix
	return prefixes[best] if best != "" else UNCATEGORIZED
