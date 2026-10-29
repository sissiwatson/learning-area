## Résultat d'une commande de jeu : succès (avec une valeur éventuelle) ou
## échec avec un code d'erreur traduisible (clé i18n "ERR_<CODE>").
class_name Result
extends RefCounted

var ok := false
var error := &""
var value: Variant = null


static func success(result_value: Variant = null) -> Result:
	var r := Result.new()
	r.ok = true
	r.value = result_value
	return r


static func failure(code: StringName) -> Result:
	var r := Result.new()
	r.error = code
	return r
