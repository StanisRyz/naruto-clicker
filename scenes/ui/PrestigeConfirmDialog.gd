class_name PrestigeConfirmDialog
extends Control

signal confirmed
signal cancelled

@onready var info_label: Label = $PanelContainer/MarginContainer/InnerPanel/VBoxContainer/InfoLabel
@onready var yes_button: Button = $PanelContainer/MarginContainer/InnerPanel/VBoxContainer/ButtonRow/YesButton
@onready var no_button: Button = $PanelContainer/MarginContainer/InnerPanel/VBoxContainer/ButtonRow/NoButton


func _ready() -> void:
	yes_button.pressed.connect(_on_yes_pressed)
	no_button.pressed.connect(_on_no_pressed)
	hide()


func show_dialog(state: ClickerState) -> void:
	var stage_points: int = state.get_prestige_stage_points()
	var character_points: int = state.get_prestige_character_points()
	var reward: int = state.get_prestige_reward()
	var available_after: int = state.prestige_points_available + reward
	var total_earned_after: int = state.prestige_points_total_earned + reward
	var L := LocalizationManager
	var lines: PackedStringArray = []
	lines.append("%s: %d" % [L.tr_key("prestige.confirm.stage_level"), state.current_level])
	lines.append("%s: %d" % [L.tr_key("prestige.confirm.character_level"), state.character_level])
	lines.append("%s: +%s" % [L.tr_key("prestige.confirm.stage_points"), NumberFormatter.compact(stage_points)])
	lines.append("%s: +%s" % [L.tr_key("prestige.confirm.character_points"), NumberFormatter.compact(character_points)])
	lines.append("%s: +%s" % [L.tr_key("prestige.confirm.points_to_gain"), NumberFormatter.compact(reward)])
	lines.append("%s: %s" % [L.tr_key("prestige.confirm.available_after"), NumberFormatter.compact(available_after)])
	lines.append("%s: %s" % [L.tr_key("prestige.confirm.total_earned_after"), NumberFormatter.compact(total_earned_after)])
	lines.append("")
	lines.append(L.tr_key("prestige.confirm.warning"))
	lines.append(L.tr_key("prestige.confirm.talents_note"))
	info_label.text = "\n".join(lines)
	show()


func _on_yes_pressed() -> void:
	hide()
	confirmed.emit()


func _on_no_pressed() -> void:
	hide()
	cancelled.emit()
