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
	info_label.text = (
		"Stage level: %d\n" % state.current_level
		+ "Character level: %d\n" % state.character_level
		+ "Stage points: +%d\n" % stage_points
		+ "Character points: +%d\n" % character_points
		+ "Points to gain: +%d\n" % reward
		+ "Available after: %d\n" % available_after
		+ "Total earned after: %d\n\n" % total_earned_after
		+ "All normal progress will reset.\n"
		+ "Purchased prestige talents remain."
	)
	show()


func _on_yes_pressed() -> void:
	hide()
	confirmed.emit()


func _on_no_pressed() -> void:
	hide()
	cancelled.emit()
