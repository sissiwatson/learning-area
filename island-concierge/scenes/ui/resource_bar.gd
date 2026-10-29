## Barre de ressources du HUD : soldes des monnaies et stock des objets.
## Construite à partir des définitions de la partie ; mise à jour par EventBus.
class_name ResourceBar
extends PanelContainer

const ICON_SIZE := Vector2(64, 64)

## id -> Label de la quantité affichée
var amount_labels := {}

@onready var _row: HBoxContainer = %Row


func _ready() -> void:
	add_to_group(&"ui_blocker")
	EventBus.currency_changed.connect(_on_amount_changed)
	EventBus.inventory_changed.connect(_on_amount_changed)
	rebuild()


## Recrée les pastilles d'après GameState (à appeler après new_game).
func rebuild() -> void:
	for child in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	amount_labels.clear()
	for def: CurrencyDef in GameState.currency_defs.values():
		_add_entry(def.id, def.icon, tr(def.name_key), GameState.wallet.balance(def.id), 44)
	if not GameState.item_defs.is_empty():
		_row.add_child(VSeparator.new())
	for def: ItemDef in GameState.item_defs.values():
		_add_entry(def.id, def.icon, tr(def.name_key), GameState.inventory.count(def.id), 36)


func _add_entry(id: StringName, icon: Texture2D, tooltip: String, amount: int, font_size: int) -> void:
	var box := HBoxContainer.new()
	box.name = String(id)
	box.tooltip_text = tooltip
	box.add_theme_constant_override(&"separation", 8)
	var texture := TextureRect.new()
	texture.texture = icon
	texture.custom_minimum_size = ICON_SIZE * (1.0 if font_size >= 44 else 0.8)
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(texture)
	var label := Label.new()
	label.add_theme_font_size_override(&"font_size", font_size)
	label.text = NumberFormat.thousands(amount)
	box.add_child(label)
	_row.add_child(box)
	amount_labels[id] = label


func _on_amount_changed(id: StringName, amount: int) -> void:
	if amount_labels.has(id):
		amount_labels[id].text = NumberFormat.thousands(amount)
