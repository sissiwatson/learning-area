## Vérifie la cohérence des données de jeu (logique pure, sans fichiers).
##
## Entrée : un catalogue { "currencies": [...], "items": [...], "recipes": [...],
## "npcs": [...], "bookings": [...], "buildings": [...], "quests": [...],
## "maps": [...], "new_games": [...], "timings": [...] }.
## Sortie : liste de messages « type:id : problème » ; vide si tout est valide.
class_name DataValidator
extends RefCounted

const ID_PATTERN := "^[a-z][a-z0-9_]*$"

var errors := PackedStringArray()
var _ids := {}  # type -> { id: def }
var _id_regex := RegEx.create_from_string(ID_PATTERN)


static func validate(catalog: Dictionary) -> PackedStringArray:
	var v := DataValidator.new()
	v._run(catalog)
	return v.errors


func _run(catalog: Dictionary) -> void:
	for type in ["currencies", "items", "recipes", "npcs", "bookings", "buildings", "quests", "maps"]:
		_index(type, catalog.get(type, []))
	for def in catalog.get("currencies", []):
		_check_named("currencies", def, def.icon)
	for def in catalog.get("items", []):
		_check_named("items", def, def.icon)
	for def in catalog.get("npcs", []):
		if def.display_name.strip_edges() == "":
			_err("npcs", def.id, "nom affiché vide")
		_check_key("npcs", def.id, def.job_key)
	for def in catalog.get("recipes", []):
		_check_recipe(def)
	for def in catalog.get("bookings", []):
		_check_booking(def)
	for def in catalog.get("buildings", []):
		_check_building(def)
	for def in catalog.get("quests", []):
		_check_quest(def)
	_check_quest_cycles(catalog.get("quests", []))
	for def in catalog.get("maps", []):
		_check_map(def)
	for def in catalog.get("new_games", []):
		_check_new_game(def)
	for def in catalog.get("timings", []):
		_check_timings(def)
	_check_free_preparation(catalog.get("buildings", []))


# --- Index et identifiants ---------------------------------------------------

func _index(type: String, defs: Array) -> void:
	_ids[type] = {}
	for def in defs:
		if def == null:
			_err(type, &"?", "définition nulle")
			continue
		var id: StringName = def.id
		if not _id_regex.search(String(id)):
			_err(type, id, "identifiant invalide (attendu : %s)" % ID_PATTERN)
		if _ids[type].has(id):
			_err(type, id, "identifiant en double")
		_ids[type][id] = def


func _has(type: String, id: StringName) -> bool:
	return _ids.get(type, {}).has(id)


## Vrai si `def` est la définition indexée sous son identifiant (et pas une
## ressource hors catalogue portant le même nom).
func _known(type: String, def: Resource) -> bool:
	return def != null and _ids.get(type, {}).get(def.id) == def


# --- Règles par type -----------------------------------------------------------

func _check_named(type: String, def: Resource, icon: Texture2D) -> void:
	_check_key(type, def.id, def.name_key)
	if icon == null:
		_err(type, def.id, "icône manquante")


func _check_recipe(def: RecipeDef) -> void:
	_check_key("recipes", def.id, def.name_key)
	_check_amounts("recipes", def.id, "entrées", def.inputs, "items", true)
	_check_amounts("recipes", def.id, "sorties", def.outputs, "items", false)
	if def.duration_seconds <= 0:
		_err("recipes", def.id, "durée nulle ou négative")
	if def.xp < 0:
		_err("recipes", def.id, "XP négative")


func _check_booking(def: BookingTemplateDef) -> void:
	if def.guest_name.strip_edges() == "":
		_err("bookings", def.id, "nom des voyageurs vide")
	if def.guests <= 0 or def.nights <= 0 or def.nightly_price <= 0:
		_err("bookings", def.id, "voyageurs, nuits et prix doivent être positifs")


func _check_building(def: BuildingDef) -> void:
	var id := def.id
	_check_key("buildings", id, def.name_key)
	if def.texture == null:
		_err("buildings", id, "texture manquante")
	if def.footprint.x <= 0 or def.footprint.y <= 0:
		_err("buildings", id, "emprise invalide %s" % def.footprint)
	var expected := {
		BuildingDef.Role.LODGING: "lodging", BuildingDef.Role.OFFICE: "office",
		BuildingDef.Role.PRODUCER: "producer", BuildingDef.Role.CONSTRUCTION: "construction",
	}
	for role in expected:
		var field: String = expected[role]
		if def.role == role and def.get(field) == null:
			_err("buildings", id, "rôle %s sans paramètres « %s »" % [BuildingDef.Role.keys()[role], field])
		elif def.role != role and def.get(field) != null:
			_err("buildings", id, "paramètres « %s » incohérents avec le rôle %s" % [field, BuildingDef.Role.keys()[def.role]])
	if def.lodging:
		var l := def.lodging
		if l.owner != null and not _known("npcs", l.owner):
			_err("buildings", id, "propriétaire inconnu « %s »" % l.owner.id)
		if l.capacity <= 0:
			_err("buildings", id, "capacité nulle")
		if l.commission_percent <= 0 or l.commission_percent > 100:
			_err("buildings", id, "commission hors de 1..100 %")
		_check_amounts("buildings", id, "objets de préparation", l.prepare_items, "items", true)
	if def.office:
		if def.office.booking_templates.is_empty():
			_err("buildings", id, "bureau sans modèle de réservation")
		for tpl in def.office.booking_templates:
			if not _known("bookings", tpl):
				_err("buildings", id, "modèle de réservation inconnu « %s »" % (tpl.id if tpl else "null"))
	if def.producer:
		if def.producer.recipes.is_empty():
			_err("buildings", id, "production sans recette")
		for recipe in def.producer.recipes:
			if not _known("recipes", recipe):
				_err("buildings", id, "recette inconnue « %s »" % (recipe.id if recipe else "null"))
		if def.producer.operator != null and not _known("npcs", def.producer.operator):
			_err("buildings", id, "personnage inconnu « %s »" % def.producer.operator.id)
	if def.construction:
		var c := def.construction
		_check_amounts("buildings", id, "coût", c.cost, "currencies", true)
		if not _known("buildings", c.builds_into):
			_err("buildings", id, "bâtiment cible inconnu")
		elif c.builds_into == def:
			_err("buildings", id, "se construit en lui-même")
		elif c.builds_into.footprint != def.footprint:
			_err("buildings", id, "emprise différente du bâtiment cible")


func _check_quest(def: QuestDef) -> void:
	var id := def.id
	_check_key("quests", id, def.title_key)
	if not _known("npcs", def.giver):
		_err("quests", id, "donneur inconnu")
	for pre in def.prerequisites:
		if pre == id:
			_err("quests", id, "se requiert elle-même")
		elif not _has("quests", pre):
			_err("quests", id, "prérequis inconnu « %s »" % pre)
	if def.objectives.is_empty():
		_err("quests", id, "aucun objectif")
	for objective in def.objectives:
		if objective == null:
			_err("quests", id, "objectif nul")
			continue
		if not GameEvents.TARGETS.has(objective.event):
			_err("quests", id, "événement inconnu « %s »" % objective.event)
			continue
		var target_type: StringName = GameEvents.TARGETS[objective.event]
		if target_type == &"" and objective.target != &"":
			_err("quests", id, "l'événement « %s » n'a pas de cible" % objective.event)
		elif target_type == &"item" and not _has("items", objective.target):
			_err("quests", id, "objet cible inconnu « %s »" % objective.target)
		elif target_type == &"building" and not _has("buildings", objective.target):
			_err("quests", id, "bâtiment cible inconnu « %s »" % objective.target)
		if objective.amount <= 0:
			_err("quests", id, "quantité d'objectif invalide")
	if def.reward_xp < 0:
		_err("quests", id, "XP négative")
	_check_amounts("quests", id, "récompense", def.reward_currencies, "currencies", true)
	_check_amounts("quests", id, "récompense", def.reward_items, "items", true)


## Les prérequis ne doivent pas former de cycle (quête inatteignable).
func _check_quest_cycles(quests: Array) -> void:
	var state := {}  # id -> 1 en cours, 2 terminé
	for quest in quests:
		if quest != null:
			_visit_quest(quest.id, state, [])


func _visit_quest(id: StringName, state: Dictionary, path: Array) -> void:
	if state.get(id, 0) == 2 or not _has("quests", id):
		return
	if state.get(id, 0) == 1:
		_err("quests", id, "cycle de prérequis : %s" % " -> ".join(path + [id]))
		return
	state[id] = 1
	for pre in _ids["quests"][id].prerequisites:
		_visit_quest(pre, state, path + [id])
	state[id] = 2


func _check_map(def: MapDef) -> void:
	var id := def.id
	_check_key("maps", id, def.name_key)
	var grid := MapGrid.from_layout(def.layout, def.size)
	for e in grid.errors:
		_err("maps", id, "plan : " + e)
	var map_rect := Rect2i(Vector2i.ZERO, def.size)
	var zone_ids := {}
	for i in def.zones.size():
		var zone := def.zones[i]
		if zone_ids.has(zone.id):
			_err("maps", id, "zone en double « %s »" % zone.id)
		zone_ids[zone.id] = true
		_check_key("maps", id, zone.name_key)
		if not map_rect.encloses(zone.rect):
			_err("maps", id, "zone « %s » hors de la carte" % zone.id)
		if not zone.rect.has_point(zone.badge_position()):
			_err("maps", id, "cadenas de la zone « %s » hors de la zone" % zone.id)
		for j in range(i + 1, def.zones.size()):
			if zone.rect.intersects(def.zones[j].rect):
				_err("maps", id, "zones « %s » et « %s » superposées" % [zone.id, def.zones[j].id])
	var used := {}
	var uids := {}
	for placement in def.placements:
		if placement == null or not _known("buildings", placement.building):
			_err("maps", id, "placement « %s » : bâtiment inconnu" % (placement.uid if placement else "null"))
			continue
		if uids.has(placement.uid):
			_err("maps", id, "placement en double « %s »" % placement.uid)
		uids[placement.uid] = true
		var zone_of_first: ZoneDef = def.zone_at(placement.cell)
		for cell in placement.cells():
			if not grid.is_buildable(cell):
				_err("maps", id, "« %s » : cellule %s non constructible" % [placement.uid, cell])
			if used.has(cell):
				_err("maps", id, "« %s » chevauche « %s » en %s" % [placement.uid, used[cell], cell])
			used[cell] = placement.uid
			if def.zone_at(cell) != zone_of_first:
				_err("maps", id, "« %s » est à cheval sur une zone" % placement.uid)
	var builds := {}
	for placement in def.placements:
		if placement and placement.building:
			builds[placement.building.role] = true
	if not builds.has(BuildingDef.Role.OFFICE):
		_err("maps", id, "aucun bureau de conciergerie")


func _check_new_game(def: NewGameDef) -> void:
	for currency in def.currencies:
		if not _known("currencies", currency):
			_err("new_game", &"new_game", "monnaie hors catalogue")
	for item in def.items:
		if not _known("items", item):
			_err("new_game", &"new_game", "objet hors catalogue")
	for key in def.starting_balances:
		if not _has("currencies", key) or def.starting_balances[key] < 0:
			_err("new_game", &"new_game", "solde de départ invalide « %s »" % key)
	_check_amounts("new_game", &"new_game", "stock de départ", def.starting_items, "items", true)
	if def.timings == null:
		_err("new_game", &"new_game", "durées (timings) manquantes")


func _check_timings(def: TimingsDef) -> void:
	for field in ["night_seconds", "cleaning_seconds", "offer_refresh_seconds",
			"excursion_min_seconds", "excursion_max_seconds"]:
		if int(def.get(field)) <= 0:
			_err("timings", &"timings", "%s doit être positif" % field)
	if def.excursion_min_seconds > def.excursion_max_seconds:
		_err("timings", &"timings", "excursion : minimum supérieur au maximum")


## Anti-blocage : tout objet exigé pour préparer un logement doit pouvoir être
## produit gratuitement (recettes sans coût, entrées elles-mêmes gratuites).
func _check_free_preparation(buildings: Array) -> void:
	var producible := {}
	var recipes: Array = _ids.get("recipes", {}).values()
	var changed := true
	while changed:
		changed = false
		for recipe: RecipeDef in recipes:
			var ok := true
			for input in recipe.inputs:
				ok = ok and producible.has(input)
			if ok:
				for output in recipe.outputs:
					if not producible.has(output):
						producible[output] = true
						changed = true
	var produced_somewhere := {}
	for building in buildings:
		if building and building.producer:
			for recipe in building.producer.recipes:
				if recipe:
					for output in recipe.outputs:
						produced_somewhere[output] = true
	for building in buildings:
		if building and building.lodging:
			for item in building.lodging.prepare_items:
				if not producible.has(item) or not produced_somewhere.has(item):
					_err("buildings", building.id, "« %s » ne peut pas être produit gratuitement : risque de blocage" % item)


# --- Utilitaires -----------------------------------------------------------------

func _check_key(type: String, id: StringName, key: String) -> void:
	if key.strip_edges() == "":
		_err(type, id, "clé de traduction vide")
	elif TranslationServer.translate(key) == StringName(key):
		_err(type, id, "traduction manquante « %s »" % key)


func _check_amounts(type: String, id: StringName, what: String, amounts: Dictionary, ref_type: String, allow_empty: bool) -> void:
	if amounts.is_empty() and not allow_empty:
		_err(type, id, "%s vides" % what)
	for key in amounts:
		if not _has(ref_type, key):
			_err(type, id, "%s : « %s » inconnu" % [what, key])
		if amounts[key] <= 0:
			_err(type, id, "%s : quantité invalide pour « %s »" % [what, key])


func _err(type: String, id: StringName, message: String) -> void:
	errors.append("%s:%s : %s" % [type, id, message])
