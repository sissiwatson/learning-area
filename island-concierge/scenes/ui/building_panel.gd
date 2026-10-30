## Panneau d'interaction d'un bâtiment. Son contenu dépend du rôle :
## hébergement (propriétaire, état, actions), bureau, production, construction.
## Lit l'état dans GameState, lui envoie les commandes, se met à jour via EventBus.
class_name BuildingPanel
extends PanelContainer

signal closed

const STATE_KEYS := {
	Lodging.State.VACANT: "LODGING_STATE_VACANT",
	Lodging.State.BOOKED: "LODGING_STATE_BOOKED",
	Lodging.State.READY: "LODGING_STATE_READY",
	Lodging.State.OCCUPIED: "LODGING_STATE_OCCUPIED",
	Lodging.State.STAY_COMPLETE: "LODGING_STATE_STAY_COMPLETE",
}
const STATE_COLORS := {
	Lodging.State.VACANT: Color(0.3, 0.62, 0.32),
	Lodging.State.BOOKED: Color(0.2, 0.45, 0.75),
	Lodging.State.READY: Color(0.55, 0.38, 0.75),
	Lodging.State.OCCUPIED: Color(0.85, 0.5, 0.15),
	Lodging.State.STAY_COMPLETE: Color(0.75, 0.3, 0.35),
}
const LOCKED_COLOR := Color(0.45, 0.47, 0.5)
const ACTION_KEYS := {
	Lodging.Action.ACCEPT_BOOKING: "ACTION_ACCEPT_BOOKING",
	Lodging.Action.PREPARE: "ACTION_PREPARE",
	Lodging.Action.WELCOME_GUESTS: "ACTION_WELCOME_GUESTS",
	Lodging.Action.END_STAY: "ACTION_END_STAY",
	Lodging.Action.COLLECT_COMMISSION: "ACTION_COLLECT_COMMISSION",
}
const ACTION_BUTTON_HEIGHT := 104.0
const DETAIL_LABEL_COLOR := Color(0.4, 0.45, 0.5)

var placement: PlacementDef
## Clé de ligne de détail -> Label de valeur (pour l'affichage et les tests).
var detail_values := {}

@onready var title: Label = %Title
@onready var role: Label = %Role
@onready var details: GridContainer = %Details
@onready var state_chip: Label = %StateChip
@onready var info: Label = %Info
@onready var actions_title: Label = %ActionsTitle
@onready var actions: VBoxContainer = %Actions
@onready var no_action: Label = %NoAction
@onready var error_label: Label = %Error
@onready var close_button: Button = %Close


func _ready() -> void:
	hide()
	add_to_group(&"ui_blocker")
	%StateLabel.text = tr("PANEL_STATE")
	actions_title.text = tr("PANEL_ACTIONS")
	no_action.text = tr("PANEL_NO_ACTION")
	close_button.tooltip_text = tr("PANEL_CLOSE")
	close_button.pressed.connect(close_panel)
	EventBus.lodging_state_changed.connect(_on_lodging_state_changed)
	EventBus.action_failed.connect(_on_action_failed)


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
	state_chip.get_parent().visible = false
	info.text = ""
	match def.role:
		BuildingDef.Role.LODGING:
			_show_lodging(def)
		BuildingDef.Role.OFFICE:
			info.text = tr("PANEL_SOON_BOOKINGS")
		BuildingDef.Role.PRODUCER:
			_show_producer(def.producer)
		BuildingDef.Role.CONSTRUCTION:
			_show_construction(def.construction)
		BuildingDef.Role.DECORATION:
			info.text = tr("PANEL_DECORATION_INFO")
	info.visible = info.text != ""
	var has_actions := actions.get_child_count() > 0
	actions_title.visible = def.role == BuildingDef.Role.LODGING and not GameState.get_lodging(placement.uid).locked
	no_action.visible = actions_title.visible and not has_actions
	$Content/Separator2.visible = actions_title.visible


func _show_lodging(def: BuildingDef) -> void:
	var owner := def.lodging.owner
	_add_detail(&"owner", tr("PANEL_OWNER"), owner.display_name if owner else tr("OWNER_UNKNOWN"))
	_add_detail(&"capacity", tr("PANEL_CAPACITY"), tr("PANEL_GUESTS") % def.lodging.capacity)
	var lodging := GameState.get_lodging(placement.uid)
	state_chip.get_parent().visible = true
	if lodging.locked:
		_set_chip(tr("LODGING_STATE_LOCKED"), LOCKED_COLOR)
		var zone := GameState.zone_of(placement.uid)
		info.text = tr("PANEL_LOCKED_HINT") % (tr(zone.name_key) if zone else "?")
		return
	_set_chip(tr(STATE_KEYS[lodging.state]), STATE_COLORS[lodging.state])
	for action in lodging.available_actions():
		var button := Button.new()
		button.name = "Action_" + Lodging.Action.keys()[action]
		button.text = tr(ACTION_KEYS[action])
		button.custom_minimum_size.y = ACTION_BUTTON_HEIGHT
		button.pressed.connect(_on_action_pressed.bind(action))
		actions.add_child(button)


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


func _add_detail(key: StringName, label_text: String, value_text: String) -> void:
	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override(&"font_color", DETAIL_LABEL_COLOR)
	details.add_child(label)
	var value := Label.new()
	value.text = value_text
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


func _on_lodging_state_changed(uid: StringName, _state: int) -> void:
	if visible and placement and placement.uid == uid:
		_refresh()


func _on_action_failed(code: StringName, _params: Dictionary) -> void:
	if visible:
		error_label.text = tr("ERR_" + String(code).to_upper())
		error_label.show()
