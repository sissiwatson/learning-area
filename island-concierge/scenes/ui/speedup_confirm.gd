## Confirmation d'une accélération de séjour : temps gagné, prix, solde après
## paiement, mention de l'offre unique. Rien n'est payé avant « Confirmer ».
## Le devis est refait chaque seconde et à chaque changement de solde, puis
## une dernière fois au moment de valider (fin de séjour entre-temps, offre
## déjà utilisée, solde insuffisant : refus sans débit).
## Annuler, toucher le fond ou Échap : aucun effet.
class_name SpeedupConfirm
extends Control

signal closed(confirmed: bool)

const THEME := preload("res://scenes/ui/theme.tres")
const PANEL_WIDTH := 720.0
const BUTTON_HEIGHT := 104.0
const VALUE_FONT_SIZE := 32
const NOTE_COLOR := Color(0.4, 0.45, 0.5)
const OFFER_COLOR := Color(0.62, 0.19, 0.27)

var uid: StringName
var tier := SpeedupRules.Tier.ONE_NIGHT
## Dernier devis affiché (vide si rien à accélérer).
var quote := {}
## Dernier refus du jeu au moment de valider (affiché jusqu'à la fermeture).
var _last_error := ""

var title := Label.new()
var gain_value := Label.new()
var price_value := Label.new()
var balance_value := Label.new()
var offer_note := Label.new()
var note := Label.new()
var status := Label.new()
var cancel_button := Button.new()
var confirm_button := Button.new()
var backdrop := ColorRect.new()


func _init() -> void:
	name = "SpeedupConfirm"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group(&"ui_blocker")


func _ready() -> void:
	theme = THEME
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.05, 0.12, 0.16, 0.45)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.gui_input.connect(_on_backdrop_input)
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = PANEL_WIDTH
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 16)
	panel.add_child(column)
	title.add_theme_font_size_override(&"font_size", 40)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", 28)
	grid.add_theme_constant_override(&"v_separation", 8)
	column.add_child(grid)
	for row in [["SPEEDUP_CONFIRM_GAIN", gain_value], ["SPEEDUP_CONFIRM_PRICE", price_value],
			["SPEEDUP_CONFIRM_BALANCE", balance_value]]:
		var label := Label.new()
		label.text = tr(row[0])
		label.add_theme_color_override(&"font_color", NOTE_COLOR)
		label.add_theme_font_size_override(&"font_size", VALUE_FONT_SIZE)
		grid.add_child(label)
		var value: Label = row[1]
		value.add_theme_font_size_override(&"font_size", VALUE_FONT_SIZE)
		grid.add_child(value)
	for label in [offer_note, note, status]:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override(&"font_size", 28)
		column.add_child(label)
	offer_note.text = tr("SPEEDUP_CONFIRM_FREE_NOTE")
	offer_note.add_theme_color_override(&"font_color", OFFER_COLOR)
	note.text = tr("SPEEDUP_CONFIRM_NOTE")
	note.add_theme_color_override(&"font_color", NOTE_COLOR)
	status.add_theme_color_override(&"font_color", OFFER_COLOR)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override(&"separation", 20)
	column.add_child(buttons)
	for button in [cancel_button, confirm_button]:
		button.custom_minimum_size.y = BUTTON_HEIGHT
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buttons.add_child(button)
	cancel_button.name = "Cancel"
	cancel_button.text = tr("SPEEDUP_CANCEL")
	cancel_button.theme_type_variation = &"SecondaryButton"
	cancel_button.pressed.connect(cancel)
	confirm_button.name = "Confirm"
	# Différé : comme les actions du panneau, l'effet suit la fin du toucher.
	confirm_button.pressed.connect(confirm, CONNECT_DEFERRED)
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_refresh_if_open)
	add_child(timer)
	EventBus.currency_changed.connect(func(_id, _v): _refresh_if_open())
	EventBus.lodging_state_changed.connect(func(_u, _s): _refresh_if_open())


func open(lodging_uid: StringName, speedup_tier: SpeedupRules.Tier) -> void:
	uid = lodging_uid
	tier = speedup_tier
	_last_error = ""
	refresh()
	show()


## Recalcule le devis et l'affichage ; « Confirmer » n'est actif que si
## l'accélération est possible et payable maintenant.
func refresh() -> void:
	title.text = tr("SPEEDUP_CONFIRM_TITLE_FINISH" if tier == SpeedupRules.Tier.FINISH else "SPEEDUP_CONFIRM_TITLE_ONE_NIGHT")
	var result := GameState.quote_stay_speedup(uid, tier)
	quote = result.value if result.ok else {}
	var availability := ""
	if quote.is_empty():
		gain_value.text = "—"
		price_value.text = "—"
		balance_value.text = "—"
		offer_note.visible = false
		confirm_button.text = tr("SPEEDUP_CONFIRM_OK")
		availability = tr("SPEEDUP_ENDED")
	else:
		var balance := GameState.wallet.balance(quote.currency)
		gain_value.text = NumberFormat.duration(quote.seconds)
		price_value.text = tr("SPEEDUP_CONFIRM_FREE") if quote.free else tr("SPEEDUP_CONFIRM_SHELLS") % NumberFormat.thousands(quote.cost)
		balance_value.text = tr("SPEEDUP_CONFIRM_SHELLS") % NumberFormat.thousands(maxi(balance - quote.cost, 0))
		offer_note.visible = quote.free
		confirm_button.text = tr("SPEEDUP_CONFIRM_USE_OFFER" if quote.free else "SPEEDUP_CONFIRM_OK")
		if balance < quote.cost:
			balance_value.text = "—"
			availability = tr("SPEEDUP_SHORT") % NumberFormat.thousands(quote.cost - balance)
	confirm_button.disabled = availability != ""
	status.text = availability if availability != "" else _last_error
	status.visible = status.text != ""


## Valide avec le prix et la fin de séjour affichés ; le jeu refait le devis
## et refuse sans débit si quelque chose a changé.
func confirm() -> void:
	if not visible or quote.is_empty():
		return
	var result := GameState.speed_up_stay(uid, tier, quote.expected_end, quote.cost)
	if result.ok:
		hide()
		closed.emit(true)
		return
	_last_error = tr("ERR_" + String(result.error).to_upper())
	refresh()


func cancel() -> void:
	if not visible:
		return
	hide()
	closed.emit(false)


func _refresh_if_open() -> void:
	if visible:
		refresh()


func _on_backdrop_input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	var click := event as InputEventMouseButton
	if (touch and not touch.pressed) or (click and click.button_index == MOUSE_BUTTON_LEFT and not click.pressed):
		cancel()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		cancel()
		get_viewport().set_input_as_handled()

