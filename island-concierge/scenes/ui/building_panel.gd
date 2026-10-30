## Panneau d'interaction d'un bâtiment. Son contenu dépend du rôle :
## hébergement (propriétaire, état, actions), bureau, production, construction.
## Lit l'état dans GameState, lui envoie les commandes, se met à jour via EventBus.
class_name BuildingPanel
extends PanelContainer

signal closed
## Le joueur demande à ouvrir un autre bâtiment (ex. le bureau depuis un logement).
signal open_requested(uid: StringName)

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
## Marge gardée libre au-dessus et au-dessous du panneau.
const SCREEN_MARGIN := 32.0

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
	EventBus.action_failed.connect(_on_action_failed)
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


func _refresh() -> void:
	var def := placement.building
	title.text = tr(def.name_key)
	role.text = tr(BuildingDef.ROLE_KEYS[def.role])
	_clear(details)
	detail_values.clear()
	_clear(actions)
	_clear(offers_box)
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
			info.text = tr("PANEL_DECORATION_INFO")
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
	for action in lodging.available_actions():
		var text := tr(ACTION_KEYS[action])
		if action == Lodging.Action.PREPARE:
			text = tr("ACTION_PREPARE_TIMED") % NumberFormat.duration(GameState.timings.cleaning_seconds)
		elif action == Lodging.Action.COLLECT_COMMISSION:
			text = tr("ACTION_COLLECT_AMOUNT") % NumberFormat.thousands(booking.commission())
		_add_button(StringName("Action_" + Lodging.Action.keys()[action]), text, _on_action_pressed.bind(action))
	_update_progress()


func _show_office() -> void:
	var now := GameState.clock.now()
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
	var percent := 0
	if target != &"":
		percent = GameState.get_placement(target).building.lodging.commission_percent
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
		button.pressed.connect(_on_accept_pressed.bind(offer.id))
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
	if placement == null or placement.building.role != BuildingDef.Role.LODGING:
		return
	var lodging := GameState.get_lodging(placement.uid)
	var now := GameState.clock.now()
	%ProgressRow.visible = lodging.is_timing()
	if not lodging.is_timing():
		return
	progress.value = lodging.progress(now) * 100.0
	var left := NumberFormat.duration(lodging.remaining(now))
	if lodging.state == Lodging.State.PREPARING:
		progress_label.text = tr("PANEL_CLEANING_PROGRESS") % left
	else:
		var night_seconds := GameState.timings.night_seconds
		var night := mini((now - lodging.timer_start) / night_seconds + 1, lodging.booking.nights)
		progress_label.text = tr("PANEL_STAY_PROGRESS") % [night, lodging.booking.nights, left]


func _show_producer(producer: ProducerDef) -> void:
	if producer.operator:
		_add_detail(&"operator", tr("PANEL_OPERATOR"), producer.operator.display_name)
	for recipe in producer.recipes:
		var outputs := PackedStringArray()
		for id in recipe.outputs:
			outputs.append("%d %s" % [recipe.outputs[id], tr(GameState.item_defs[id].name_key)])
		_add_detail(StringName("recipe_" + recipe.id), tr("PANEL_RECIPE"),
				tr("PANEL_RECIPE_LINE") % [tr(recipe.name_key), ", ".join(outputs), NumberFormat.duration(recipe.duration_seconds)])
	info.text = tr("PANEL_SOON_PRODUCTION")


func _show_construction(construction: ConstructionDef) -> void:
	var costs := PackedStringArray()
	for id in construction.cost:
		costs.append("%s %s" % [NumberFormat.thousands(construction.cost[id]), tr(GameState.currency_defs[id].name_key).to_lower()])
	_add_detail(&"cost", tr("PANEL_COST"), ", ".join(costs))
	_add_detail(&"level", tr("PANEL_LEVEL"), str(construction.required_level))
	_add_detail(&"build_time", tr("PANEL_BUILD_TIME"), NumberFormat.duration(construction.build_seconds))
	info.text = tr("PANEL_SOON_CONSTRUCTION")


## Le panneau ne dépasse jamais de l'écran : au-delà, son contenu défile.
func _fit_height() -> void:
	_scroll.custom_minimum_size.y = 0.0
	await get_tree().process_frame  # laisse le contenu recalculer sa taille
	if not is_inside_tree():
		return
	var style := get_theme_stylebox(&"panel")
	var chrome := style.get_minimum_size().y if style else 0.0
	var available := get_viewport_rect().size.y - 2.0 * SCREEN_MARGIN - chrome
	_scroll.custom_minimum_size.y = minf(_content.get_combined_minimum_size().y, available)
	reset_size()  # reprend la hauteur minimale, plus grande ou plus petite


func _add_button(button_name: StringName, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.name = String(button_name)
	button.text = text
	button.custom_minimum_size.y = ACTION_BUTTON_HEIGHT
	button.pressed.connect(callback)
	actions.add_child(button)


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


func _on_action_pressed(action: Lodging.Action) -> void:
	error_label.hide()
	GameState.perform_lodging_action(placement.uid, action)


func _on_accept_pressed(offer_id: StringName) -> void:
	error_label.hide()
	GameState.accept_offer(offer_id)


func _on_open_office() -> void:
	for p in GameState.map.placements:
		if p.building.role == BuildingDef.Role.OFFICE:
			open_requested.emit(p.uid)
			return


func _on_lodging_state_changed(uid: StringName, _state: int) -> void:
	if visible and placement and (placement.uid == uid or placement.building.role == BuildingDef.Role.OFFICE):
		_refresh()


func _on_offers_changed() -> void:
	if visible and placement and placement.building.role == BuildingDef.Role.OFFICE:
		_refresh()


func _on_second() -> void:
	if not visible or placement == null:
		return
	if placement.building.role == BuildingDef.Role.OFFICE:
		var wait := GameState.bookings.seconds_to_next_offer(GameState.clock.now())
		if wait > 0:
			info.text = tr("PANEL_NEXT_OFFER") % NumberFormat.duration(wait)
	else:
		_update_progress()


func _on_action_failed(code: StringName, _params: Dictionary) -> void:
	if visible:
		error_label.text = tr("ERR_" + String(code).to_upper())
		error_label.show()
