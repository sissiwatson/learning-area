## Panneau d'interaction d'un bâtiment. Son contenu dépend du rôle :
## hébergement (propriétaire, état, actions), bureau, production, construction.
## Lit l'état dans GameState, lui envoie les commandes, se met à jour via EventBus.
class_name BuildingPanel
extends PanelContainer

signal closed
## Le joueur demande à ouvrir un autre bâtiment (ex. le bureau depuis un logement).
signal open_requested(uid: StringName)
## « Avancer le temps » : la confirmation (prix, temps gagné, solde après)
## est affichée par la scène principale.
signal speedup_requested(uid: StringName, tier: SpeedupRules.Tier)

const STATE_KEYS := {
	Lodging.State.VACANT: "LODGING_STATE_VACANT",
	Lodging.State.BOOKED: "LODGING_STATE_BOOKED",
	Lodging.State.PREPARING: "LODGING_STATE_PREPARING",
	Lodging.State.READY: "LODGING_STATE_READY",
	Lodging.State.OCCUPIED: "LODGING_STATE_OCCUPIED",
	Lodging.State.STAY_COMPLETE: "LODGING_STATE_STAY_COMPLETE",
}
const STATE_COLORS := {
	Lodging.State.VACANT: Color(0.3, 0.62, 0.32),
	Lodging.State.BOOKED: Color(0.2, 0.45, 0.75),
	Lodging.State.PREPARING: Color(0.25, 0.55, 0.6),
	Lodging.State.READY: Color(0.55, 0.38, 0.75),
	Lodging.State.OCCUPIED: Color(0.85, 0.5, 0.15),
	Lodging.State.STAY_COMPLETE: Color(0.75, 0.3, 0.35),
}
const LOCKED_COLOR := Color(0.45, 0.47, 0.5)
const ACTION_KEYS := {
	Lodging.Action.PREPARE: "ACTION_PREPARE",
	Lodging.Action.WELCOME_GUESTS: "ACTION_WELCOME_GUESTS",
	Lodging.Action.COLLECT_COMMISSION: "ACTION_COLLECT_COMMISSION",
}
const ACTION_BUTTON_HEIGHT := 104.0
const DETAIL_LABEL_COLOR := Color(0.4, 0.45, 0.5)
const DETAIL_FONT_SIZE := 30
## Largeur minimale des valeurs renvoyées à la ligne : un libellé tout juste
## créé (largeur 1) annoncerait sinon une hauteur immense le temps d'une mise
## en page. La boucle de mise en page trouvée par la recette « singe » est
## corrigée par la barre de défilement réservée (Scroll, mode « Reserve »).
const DETAIL_VALUE_MIN_WIDTH := 200.0
## Marge gardée libre au-dessus et au-dessous du panneau.
const SCREEN_MARGIN := 32.0
const SPEEDUP_BUTTON_HEIGHT := 96.0
const SPEEDUP_TIERS := [SpeedupRules.Tier.ONE_NIGHT, SpeedupRules.Tier.FINISH]
const SPEEDUP_NAME_KEYS := {
	SpeedupRules.Tier.ONE_NIGHT: "SPEEDUP_ONE_NIGHT",
	SpeedupRules.Tier.FINISH: "SPEEDUP_FINISH",
}

var placement: PlacementDef
## Clé de ligne de détail -> Label de valeur (pour l'affichage et les tests).
var detail_values := {}

@onready var title: Label = %Title
@onready var role: Label = %Role
@onready var details: GridContainer = %Details
@onready var state_chip: Label = %StateChip
@onready var info: Label = %Info
@onready var progress: ProgressBar = %Progress
@onready var progress_label: Label = %ProgressLabel
@onready var offers_box: VBoxContainer = %Offers
@onready var actions_title: Label = %ActionsTitle
@onready var actions: VBoxContainer = %Actions
@onready var no_action: Label = %NoAction
@onready var error_label: Label = %Error
@onready var close_button: Button = %Close
@onready var _scroll: ScrollContainer = %Scroll
@onready var _content: VBoxContainer = %Content
## Section « Avancer le temps » (séjour en cours seulement), sous les actions.
var speedup_box := VBoxContainer.new()


func _ready() -> void:
	hide()
	add_to_group(&"ui_blocker")
	%StateLabel.text = tr("PANEL_STATE")
	actions_title.text = tr("PANEL_ACTIONS")
	no_action.text = tr("PANEL_NO_ACTION")
	close_button.tooltip_text = tr("PANEL_CLOSE")
	close_button.pressed.connect(close_panel)
	EventBus.lodging_state_changed.connect(_on_lodging_state_changed)
	EventBus.offers_changed.connect(_on_offers_changed)
	EventBus.inventory_changed.connect(_on_inventory_changed)
	EventBus.production_started.connect(_on_production_changed)
	EventBus.production_completed.connect(_on_production_changed)
	EventBus.production_blocked_changed.connect(_on_production_changed)
	EventBus.construction_started.connect(_on_production_changed)
	EventBus.building_built.connect(_on_production_changed)
	EventBus.currency_changed.connect(func(_id, _v): if visible and placement and _def().role == BuildingDef.Role.CONSTRUCTION: _refresh())
	EventBus.level_up.connect(func(_l): if visible and placement: _refresh())
	EventBus.action_failed.connect(_on_action_failed)
	EventBus.stay_sped_up.connect(func(uid, _seconds, _cost):
		if visible and placement and placement.uid == uid:
			_refresh())
	EventBus.currency_changed.connect(func(_id, _v): _update_speedup_buttons())
	speedup_box.name = "Speedups"
	speedup_box.add_theme_constant_override(&"separation", 12)
	_content.add_child(speedup_box)
	_content.move_child(speedup_box, actions.get_index() + 1)
	# Rafraîchit les comptes à rebours une fois par seconde, panneau ouvert seulement.
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_on_second)
	add_child(timer)


func show_placement(new_placement: PlacementDef) -> void:
	placement = new_placement
	error_label.hide()
	_refresh()
	show()


func close_panel() -> void:
	if not visible:
		return
	hide()
	placement = null
	closed.emit()


func action_buttons() -> Array[Button]:
	var result: Array[Button] = []
	for child in actions.get_children():
		result.append(child as Button)
	return result


## Définition effective (le tiki bar remplace son chantier une fois construit).
func _def() -> BuildingDef:
	return GameState.building_def_of(placement.uid)


func _refresh() -> void:
	var def := _def()
	title.text = tr(def.name_key)
	role.text = tr(BuildingDef.ROLE_KEYS[def.role])
	_clear(details)
	detail_values.clear()
	_clear(actions)
	_clear(offers_box)
	_clear(speedup_box)
	speedup_box.visible = false
	%StateRow.visible = false
	%ProgressRow.visible = false
	info.text = ""
	match def.role:
		BuildingDef.Role.LODGING:
			_show_lodging(def)
		BuildingDef.Role.OFFICE:
			_show_office()
		BuildingDef.Role.PRODUCER:
			_show_producer(def.producer)
		BuildingDef.Role.CONSTRUCTION:
			_show_construction(def.construction)
		BuildingDef.Role.DECORATION:
			info.text = tr(def.description_key if def.description_key != "" else "PANEL_DECORATION_INFO")
	info.visible = info.text != ""
	var has_actions := actions.get_child_count() > 0
	info.visible = info.text != ""
	actions_title.visible = has_actions
	offers_box.visible = def.role == BuildingDef.Role.OFFICE
	no_action.visible = false
	%DetailsSeparator.visible = details.get_child_count() > 0
	_fit_height.call_deferred()


func _show_lodging(def: BuildingDef) -> void:
	var owner := def.lodging.owner
	_add_detail(&"owner", tr("PANEL_OWNER"), owner.display_name if owner else tr("OWNER_UNKNOWN"))
	_add_detail(&"capacity", tr("PANEL_CAPACITY"), tr("PANEL_GUESTS") % def.lodging.capacity)
	var lodging := GameState.get_lodging(placement.uid)
	%StateRow.visible = true
	if lodging.locked:
		_set_chip(tr("LODGING_STATE_LOCKED"), LOCKED_COLOR)
		var zone := GameState.zone_of(placement.uid)
		info.text = tr("PANEL_LOCKED_HINT") % (tr(zone.name_key) if zone else "?")
		return
	_set_chip(tr(STATE_KEYS[lodging.state]), STATE_COLORS[lodging.state])
	var booking := lodging.booking
	if booking:
		_add_detail(&"guests", tr("PANEL_TRAVELERS"), tr("PANEL_GUESTS_NAMED") % [booking.guest_name, booking.guests])
		_add_detail(&"stay", tr("PANEL_STAY"), tr("PANEL_STAY_VALUE") % [_count("NIGHTS", booking.nights), NumberFormat.thousands(booking.revenue())])
		_add_detail(&"commission", tr("PANEL_COMMISSION"),
				tr("PANEL_COMMISSION_VALUE") % [NumberFormat.thousands(booking.commission()), booking.commission_percent])
		_add_detail(&"owner_share", tr("PANEL_OWNER_SHARE"), NumberFormat.thousands(booking.owner_share()))
	match lodging.state:
		Lodging.State.VACANT:
			info.text = tr("PANEL_VACANT_HINT")
			_add_button(&"Action_OPEN_OFFICE", tr("ACTION_OPEN_OFFICE"), _on_open_office)
		Lodging.State.READY:
			info.text = tr("PANEL_READY_HINT")
		Lodging.State.STAY_COMPLETE:
			info.text = tr("PANEL_COMPLETE_HINT")
	var prepare_items := def.lodging.prepare_items
	for action in lodging.available_actions():
		var text := tr(ACTION_KEYS[action])
		var enabled := true
		if action == Lodging.Action.PREPARE:
			text = tr("ACTION_PREPARE_TIMED") % NumberFormat.duration(GameState.timings.cleaning_seconds)
			if not prepare_items.is_empty():
				info.text = tr("PANEL_PREPARE_NEEDS") % _items_text(prepare_items)
				var missing := _missing(prepare_items)
				if not missing.is_empty():
					text = tr("PANEL_MISSING") % _items_text(missing)
					enabled = false
		elif action == Lodging.Action.COLLECT_COMMISSION:
			text = tr("ACTION_COLLECT_AMOUNT") % NumberFormat.thousands(booking.commission())
		var button := _add_button(StringName("Action_" + Lodging.Action.keys()[action]), text, _on_action_pressed.bind(placement.uid, action))
		button.disabled = not enabled
	if lodging.state == Lodging.State.OCCUPIED:
		_show_speedups()
	_update_progress()


## Section discrète « Avancer le temps » : deux boutons secondaires avec leur
## prix (ou l'offre unique), et le rappel que c'est facultatif.
func _show_speedups() -> void:
	var heading := _make_label(tr("SPEEDUP_TITLE"), DETAIL_FONT_SIZE)
	heading.add_theme_color_override(&"font_color", DETAIL_LABEL_COLOR)
	speedup_box.add_child(heading)
	for tier in SPEEDUP_TIERS:
		var button := Button.new()
		button.name = "Speedup_" + SpeedupRules.Tier.keys()[tier]
		button.theme_type_variation = &"SecondaryButton"
		button.custom_minimum_size.y = SPEEDUP_BUTTON_HEIGHT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		# Différé, comme les actions : la confirmation s'ouvre après le toucher.
		button.pressed.connect(_on_speedup_pressed.bind(placement.uid, tier), CONNECT_DEFERRED)
		speedup_box.add_child(button)
	var hint := _make_label(tr("SPEEDUP_HINT"), 26)
	hint.add_theme_color_override(&"font_color", DETAIL_LABEL_COLOR)
	speedup_box.add_child(hint)
	speedup_box.visible = true
	_update_speedup_buttons()


## Prix à jour (celui de « Terminer le séjour » baisse avec le temps).
func _update_speedup_buttons() -> void:
	if not speedup_box.visible or placement == null:
		return
	for tier in SPEEDUP_TIERS:
		var button := speedup_box.get_node_or_null("Speedup_" + SpeedupRules.Tier.keys()[tier]) as Button
		if button == null:
			continue
		var name_text := tr(SPEEDUP_NAME_KEYS[tier])
		var quote := GameState.quote_stay_speedup(placement.uid, tier)
		if not quote.ok:
			button.text = name_text
			button.disabled = true
			continue
		var q: Dictionary = quote.value
		var missing: int = q.cost - GameState.wallet.balance(q.currency)
		if q.free:
			button.text = tr("SPEEDUP_BUTTON_FREE") % name_text
		elif missing > 0:
			button.text = tr("SPEEDUP_BUTTON_SHORT") % [name_text, NumberFormat.thousands(missing)]
		else:
			button.text = tr("SPEEDUP_BUTTON_PRICE") % [name_text, NumberFormat.thousands(q.cost)]
		button.disabled = missing > 0


## Boutons « Avancer le temps » visibles (tests et captures).
func speedup_buttons() -> Array[Button]:
	var result: Array[Button] = []
	for child in speedup_box.get_children():
		if child is Button:
			result.append(child)
	return result


func _on_speedup_pressed(uid: StringName, tier: SpeedupRules.Tier) -> void:
	speedup_requested.emit(uid, tier)


func _update_producer_progress() -> void:
	var state: Producer = GameState.producers[placement.uid]
	var at := GameState.now()
	var running := state.slot_state(0, at) == Producer.SlotState.RUNNING
	%ProgressRow.visible = running
	if running:
		var recipe: RecipeDef = GameState.recipe_defs[state.slots[0].recipe]
		progress.value = state.progress(0, at) * 100.0
		progress_label.text = tr("PANEL_PRODUCTION_PROGRESS") % [tr(recipe.name_key), NumberFormat.duration(state.remaining(0, at))]


func _show_office() -> void:
	var now := GameState.now()
	var system := GameState.bookings
	offers_box.add_child(_make_label(tr("PANEL_OFFERS"), 38))
	if system.offers.is_empty():
		offers_box.add_child(_make_label(tr("PANEL_NO_OFFER"), 32))
	for offer in system.offers:
		offers_box.add_child(_make_offer_card(offer))
	var wait := system.seconds_to_next_offer(now)
	if wait > 0:
		info.text = tr("PANEL_NEXT_OFFER") % NumberFormat.duration(wait)


func _make_offer_card(offer: Dictionary) -> Control:
	var template: BookingTemplateDef = offer.template
	var card := VBoxContainer.new()
	card.name = "Offer_" + String(offer.id)
	card.add_theme_constant_override(&"separation", 6)
	var revenue := template.nights * template.nightly_price
	var target := GameState.find_lodging_for(template.guests)
	var percent := GameState.commission_percent_for(template.guests)
	card.add_child(_make_label(tr("PANEL_OFFER_LINE") % [template.guest_name,
			_count("TRAVELERS", template.guests), _count("NIGHTS", template.nights)], 32))
	card.add_child(_make_label(tr("PANEL_OFFER_AMOUNTS") % [NumberFormat.thousands(revenue),
			NumberFormat.thousands(revenue * percent / 100)], 28))
	var button := Button.new()
	button.name = "Accept"
	button.custom_minimum_size.y = ACTION_BUTTON_HEIGHT
	if target == &"":
		button.text = tr("PANEL_OFFER_NO_LODGING")
		button.disabled = true
	else:
		card.add_child(_make_label(tr("PANEL_OFFER_TARGET") % tr(GameState.get_placement(target).building.name_key), 28))
		button.text = tr("ACTION_ACCEPT")
		button.pressed.connect(_on_accept_pressed.bind(offer.id), CONNECT_DEFERRED)
	card.add_child(button)
	return card


## Boutons « Accepter » des offres affichées (pour les tests).
func offer_buttons() -> Array[Button]:
	var result: Array[Button] = []
	for card in offers_box.get_children():
		var button := card.get_node_or_null("Accept") as Button
		if button:
			result.append(button)
	return result


func _update_progress() -> void:
	if placement == null:
		return
	var role := _def().role
	if role == BuildingDef.Role.PRODUCER:
		_update_producer_progress()
		return
	if role == BuildingDef.Role.CONSTRUCTION:
		var site: ConstructionSite = GameState.constructions[placement.uid]
		var at := GameState.now()
		%ProgressRow.visible = site.state == ConstructionSite.State.BUILDING
		progress.value = site.progress(at) * 100.0
		progress_label.text = tr("PANEL_BUILD_PROGRESS") % NumberFormat.duration(site.remaining(at))
		return
	if role != BuildingDef.Role.LODGING:
		return
	var lodging := GameState.get_lodging(placement.uid)
	var now := GameState.now()
	%ProgressRow.visible = lodging.is_timing()
	if not lodging.is_timing():
		return
	progress.value = lodging.progress(now) * 100.0
	var left := NumberFormat.duration(lodging.remaining(now))
	if lodging.state == Lodging.State.PREPARING:
		progress_label.text = tr("PANEL_CLEANING_PROGRESS") % left
	else:
		var night_seconds := GameState.timings.night_seconds
		var night := mini(lodging.elapsed_stay_seconds(now) / night_seconds + 1, lodging.booking.nights)
		progress_label.text = tr("PANEL_STAY_PROGRESS") % [night, lodging.booking.nights, left]


func _show_producer(producer: ProducerDef) -> void:
	if producer.operator:
		_add_detail(&"operator", tr("PANEL_OPERATOR"), producer.operator.display_name)
	var state: Producer = GameState.producers[placement.uid]
	var busy := state.free_slot() < 0
	if GameState.blocked_producers.has(placement.uid):
		info.text = tr("PANEL_PRODUCTION_BLOCKED")
	for recipe in producer.recipes:
		var inputs := _items_text(recipe.inputs) if not recipe.inputs.is_empty() else tr("PANEL_FREE")
		_add_detail(StringName("recipe_" + recipe.id), tr("PANEL_RECIPE"),
				tr("PANEL_RECIPE_LINE") % [tr(recipe.name_key), _items_text(recipe.outputs), NumberFormat.duration(recipe.duration_seconds)])
		_add_detail(StringName("inputs_" + recipe.id), tr("PANEL_INPUTS"), inputs)
		var button_text := tr("ACTION_START_RECIPE") % NumberFormat.duration(recipe.duration_seconds)
		var missing := _missing(recipe.inputs)
		var enabled := not busy and missing.is_empty()
		if busy:
			button_text = tr("PANEL_PRODUCTION_BUSY")
		elif not missing.is_empty():
			button_text = tr("PANEL_MISSING") % _items_text(missing)
		var button := _add_button(StringName("Start_" + recipe.id), button_text, _on_start_pressed.bind(placement.uid, recipe.id))
		button.disabled = not enabled
	_update_progress()


## « 3 Ananas, 1 Panier d'accueil ».
func _items_text(items: Dictionary) -> String:
	var parts := PackedStringArray()
	for id in items:
		parts.append("%d %s" % [items[id], tr(GameState.item_defs[id].name_key)])
	return ", ".join(parts)


## Objets manquants dans l'inventaire pour `items`.
func _missing(items: Dictionary) -> Dictionary:
	var missing := {}
	for id in items:
		var lack: int = items[id] - GameState.inventory.count(id)
		if lack > 0:
			missing[id] = lack
	return missing


func _show_construction(construction: ConstructionDef) -> void:
	var costs := PackedStringArray()
	for id in construction.cost:
		costs.append("%s %s" % [NumberFormat.thousands(construction.cost[id]), tr(GameState.currency_defs[id].name_key).to_lower()])
	_add_detail(&"cost", tr("PANEL_COST"), ", ".join(costs))
	_add_detail(&"level", tr("PANEL_LEVEL"), str(construction.required_level))
	_add_detail(&"build_time", tr("PANEL_BUILD_TIME"), NumberFormat.duration(construction.build_seconds))
	var site: ConstructionSite = GameState.constructions[placement.uid]
	if site.state == ConstructionSite.State.BUILDING:
		_add_button(&"Build", tr("PANEL_BUILDING_UNDERWAY"), func(): pass).disabled = true
		_update_progress()
		return
	var price: int = construction.cost.get(GameState.COMMISSION_CURRENCY, 0)
	var text := tr("ACTION_BUILD") % NumberFormat.thousands(price)
	var enabled := true
	if GameState.level() < construction.required_level:
		text = tr("PANEL_LEVEL_REQUIRED") % construction.required_level
		enabled = false
	elif not GameState.wallet.can_afford(construction.cost):
		var lack: int = price - GameState.wallet.balance(GameState.COMMISSION_CURRENCY)
		text = tr("PANEL_MISSING_COINS") % NumberFormat.thousands(lack)
		enabled = false
	_add_button(&"Build", text, _on_build_pressed.bind(placement.uid)).disabled = not enabled


## Le panneau ne dépasse jamais de l'écran : au-delà, son contenu défile.
func _fit_height() -> void:
	_scroll.custom_minimum_size.y = 0.0
	# Laisse le contenu recalculer sa taille ; la connexion disparaît d'elle-même
	# si le panneau est détruit entre-temps.
	if not get_tree().process_frame.is_connected(_fit_height_now):
		get_tree().process_frame.connect(_fit_height_now, CONNECT_ONE_SHOT)


func _fit_height_now() -> void:
	var style := get_theme_stylebox(&"panel")
	var chrome := style.get_minimum_size().y if style else 0.0
	var available := get_viewport_rect().size.y - 2.0 * SCREEN_MARGIN - chrome
	_scroll.custom_minimum_size.y = minf(_content.get_combined_minimum_size().y, available)
	reset_size()  # reprend la hauteur minimale, plus grande ou plus petite


func _add_button(button_name: StringName, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.name = String(button_name)
	button.text = text
	button.custom_minimum_size.y = ACTION_BUTTON_HEIGHT
	# Différé : l'action reconstruit le panneau et retire ce bouton ; le faire
	# pendant le toucher laisserait le moteur livrer la fin du toucher à un
	# bouton sorti de l'arbre (erreur moteur, trouvée par l'endurance).
	button.pressed.connect(callback, CONNECT_DEFERRED)
	actions.add_child(button)
	return button


## Singulier ou pluriel : clés <PREFIXE>_ONE et <PREFIXE>_MANY.
static func _count(prefix: String, n: int) -> String:
	return TranslationServer.translate(prefix + "_ONE") if n == 1 else TranslationServer.translate(prefix + "_MANY") % n


func _make_label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _add_detail(key: StringName, label_text: String, value_text: String) -> void:
	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override(&"font_color", DETAIL_LABEL_COLOR)
	label.add_theme_font_size_override(&"font_size", DETAIL_FONT_SIZE)
	details.add_child(label)
	var value := Label.new()
	value.text = value_text
	value.add_theme_font_size_override(&"font_size", DETAIL_FONT_SIZE)
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.custom_minimum_size.x = DETAIL_VALUE_MIN_WIDTH
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(value)
	detail_values[key] = value


func _set_chip(text: String, color: Color) -> void:
	state_chip.text = text
	var chip := state_chip.get_theme_stylebox(&"normal").duplicate() as StyleBoxFlat
	chip.bg_color = color
	state_chip.add_theme_stylebox_override(&"normal", chip)


func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


# Les boutons gardent le bâtiment pour lequel ils ont été créés : l'action,
# différée, s'applique même si le panneau a été fermé entre-temps.
func _on_action_pressed(uid: StringName, action: Lodging.Action) -> void:
	error_label.hide()
	GameState.perform_lodging_action(uid, action)


func _on_build_pressed(uid: StringName) -> void:
	error_label.hide()
	GameState.start_construction(uid)


func _on_start_pressed(uid: StringName, recipe_id: StringName) -> void:
	error_label.hide()
	GameState.start_production(uid, recipe_id)


func _on_inventory_changed(_id: StringName, _count: int) -> void:
	if visible and placement and _def().role in [BuildingDef.Role.PRODUCER, BuildingDef.Role.LODGING]:
		_refresh()


func _on_production_changed(uid: StringName, _detail: Variant = null) -> void:
	if visible and placement and placement.uid == uid:
		_refresh()


func _on_accept_pressed(offer_id: StringName) -> void:
	error_label.hide()
	GameState.accept_offer(offer_id)


func _on_open_office() -> void:
	for p in GameState.map.placements:
		if p.building.role == BuildingDef.Role.OFFICE:
			open_requested.emit(p.uid)
			return


func _on_lodging_state_changed(uid: StringName, _state: int) -> void:
	if visible and placement and (placement.uid == uid or _def().role == BuildingDef.Role.OFFICE):
		_refresh()


func _on_offers_changed() -> void:
	if visible and placement and _def().role == BuildingDef.Role.OFFICE:
		_refresh()


func _on_second() -> void:
	if not visible or placement == null:
		return
	if _def().role == BuildingDef.Role.OFFICE:
		var wait := GameState.bookings.seconds_to_next_offer(GameState.now())
		if wait > 0:
			info.text = tr("PANEL_NEXT_OFFER") % NumberFormat.duration(wait)
	else:
		_update_progress()
		_update_speedup_buttons()


func _on_action_failed(code: StringName, _params: Dictionary) -> void:
	if visible:
		error_label.text = tr("ERR_" + String(code).to_upper())
		error_label.show()
