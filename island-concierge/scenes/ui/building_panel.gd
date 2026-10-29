## Panneau d'interaction d'un bâtiment : nom, propriétaire, état, actions.
## Lit l'état dans GameState et lui envoie les commandes ; se met à jour via
## EventBus.
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
const ACTION_KEYS := {
	Lodging.Action.ACCEPT_BOOKING: "ACTION_ACCEPT_BOOKING",
	Lodging.Action.PREPARE: "ACTION_PREPARE",
	Lodging.Action.WELCOME_GUESTS: "ACTION_WELCOME_GUESTS",
	Lodging.Action.END_STAY: "ACTION_END_STAY",
	Lodging.Action.COLLECT_COMMISSION: "ACTION_COLLECT_COMMISSION",
}
const ACTION_BUTTON_HEIGHT := 104.0

var placement: PlacementDef

@onready var title: Label = %Title
@onready var role: Label = %Role
@onready var owner_value: Label = %OwnerValue
@onready var capacity_value: Label = %CapacityValue
@onready var state_chip: Label = %StateChip
@onready var actions: VBoxContainer = %Actions
@onready var no_action: Label = %NoAction
@onready var error_label: Label = %Error
@onready var close_button: Button = %Close


func _ready() -> void:
	hide()
	add_to_group(&"ui_blocker")
	%OwnerLabel.text = tr("PANEL_OWNER")
	%CapacityLabel.text = tr("PANEL_CAPACITY")
	%StateLabel.text = tr("PANEL_STATE")
	%ActionsTitle.text = tr("PANEL_ACTIONS")
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
	role.text = tr("ROLE_LODGING")
	owner_value.text = def.lodging.owner_name
	capacity_value.text = tr("PANEL_GUESTS") % def.lodging.capacity
	var lodging := GameState.get_lodging(placement.uid)
	state_chip.text = tr(STATE_KEYS[lodging.state])
	var chip := state_chip.get_theme_stylebox(&"normal").duplicate() as StyleBoxFlat
	chip.bg_color = STATE_COLORS[lodging.state]
	state_chip.add_theme_stylebox_override(&"normal", chip)
	for child in actions.get_children():
		actions.remove_child(child)
		child.queue_free()
	for action in lodging.available_actions():
		var button := Button.new()
		button.name = "Action_" + Lodging.Action.keys()[action]
		button.text = tr(ACTION_KEYS[action])
		button.custom_minimum_size.y = ACTION_BUTTON_HEIGHT
		button.pressed.connect(_on_action_pressed.bind(action))
		actions.add_child(button)
	no_action.visible = actions.get_child_count() == 0


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
