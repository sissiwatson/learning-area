## Bandeau de la quête en cours : titre, objectifs avec progression, bouton
## « Y aller » qui montre le bâtiment concerné.
class_name QuestBanner
extends PanelContainer

signal go_requested(building_id: StringName)

var quest: QuestDef

@onready var title: Label = %QuestTitle
@onready var objectives: Label = %Objectives
@onready var go_button: Button = %Go


func _ready() -> void:
	hide()
	add_to_group(&"ui_blocker")
	go_button.text = tr("QUEST_GO")
	go_button.pressed.connect(func(): go_requested.emit(quest.focus_building))
	for sig in [EventBus.quest_started, EventBus.quest_progressed, EventBus.quest_completed]:
		sig.connect(func(_id): refresh())


## Affiche la première quête active, ou se masque.
func refresh() -> void:
	var active := GameState.quest_log.with_status(QuestLog.Status.ACTIVE)
	quest = active[0] if not active.is_empty() else null
	visible = quest != null
	if quest == null:
		return
	title.text = tr(quest.title_key)
	var lines := PackedStringArray()
	var counters: Array = GameState.quest_log.progress[quest.id]
	for i in quest.objectives.size():
		var o := quest.objectives[i]
		var check := "✓" if counters[i] >= o.amount else "•"
		var count := "" if o.amount == 1 else " %d/%d" % [counters[i], o.amount]
		lines.append("%s %s%s" % [check, tr(o.label_key), count])
	objectives.text = "\n".join(lines)
	go_button.visible = quest.focus_building != &""
