## Boîte de dialogue en bas de l'écran : portrait, nom, texte qui s'écrit.
## Toucher la boîte : affiche tout le texte, puis passe à la réplique suivante.
## « Passer » : va à la fin ; le dialogue est alors considéré comme lu
## (ses effets s'appliquent de la même façon).
class_name DialogueBox
extends PanelContainer

signal finished(dialogue_id: StringName)

## Vitesse d'écriture (caractères par seconde).
@export var characters_per_second := 45.0

var runner: DialogueRunner
var _shown := 0.0

@onready var portrait: TextureRect = %Portrait
@onready var speaker_label: Label = %Speaker
@onready var text_label: Label = %Text
@onready var skip_button: Button = %Skip


func _ready() -> void:
	hide()
	add_to_group(&"ui_blocker")
	skip_button.text = tr("DIALOGUE_SKIP")
	skip_button.pressed.connect(skip)
	gui_input.connect(_on_gui_input)
	set_process(false)


func play(dialogue: DialogueDef) -> void:
	runner = DialogueRunner.new(dialogue)
	show()
	_show_line()


func is_playing() -> bool:
	return visible and runner != null and not runner.is_finished()


func is_typing() -> bool:
	return text_label.visible_characters >= 0 and text_label.visible_characters < text_label.get_total_character_count()


## Toucher : termine l'écriture, sinon réplique suivante.
func on_tap() -> void:
	if not is_playing():
		return
	if is_typing():
		text_label.visible_characters = -1
		set_process(false)
		return
	if runner.advance():
		_show_line()
	else:
		_finish()


func skip() -> void:
	if runner == null:
		return
	runner.skip()
	_finish()


func _show_line() -> void:
	var line := runner.current()
	var npc := line.speaker
	portrait.texture = npc.portrait if npc else null
	portrait.visible = npc != null
	speaker_label.text = npc.display_name if npc else ""
	text_label.text = tr(line.text_key)
	text_label.visible_characters = 0
	_shown = 0.0
	set_process(true)


func _process(delta: float) -> void:
	_shown += delta * characters_per_second
	text_label.visible_characters = int(_shown)
	if not is_typing():
		text_label.visible_characters = -1
		set_process(false)


func _finish() -> void:
	set_process(false)
	hide()
	var id := runner.dialogue.id
	runner = null
	finished.emit(id)


func _on_gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button and button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
		on_tap()
		accept_event()
