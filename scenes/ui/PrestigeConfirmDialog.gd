class_name PrestigeConfirmDialog
extends Control

signal confirmed
signal cancelled

@onready var info_label: Label = $PanelContainer/MarginContainer/VBoxContainer/InfoLabel
@onready var yes_button: Button = $PanelContainer/MarginContainer/VBoxContainer/ButtonRow/YesButton
@onready var no_button: Button = $PanelContainer/MarginContainer/VBoxContainer/ButtonRow/NoButton


func _ready() -> void:
	yes_button.pressed.connect(_on_yes_pressed)
	no_button.pressed.connect(_on_no_pressed)
	hide()


func show_dialog(current_level: int, reward: int, dmg_mult: float, gold_mult: float) -> void:
	var dmg_pct: int = int((dmg_mult - 1.0) * 100.0)
	var gold_pct: int = int((gold_mult - 1.0) * 100.0)
	info_label.text = (
		"Current level: %d\n" % current_level
		+ "Points to gain: +%d\n" % reward
		+ "Damage bonus after: +%d%%\n" % dmg_pct
		+ "Gold bonus after: +%d%%\n\n" % gold_pct
		+ "All normal progress will reset!"
	)
	show()


func _on_yes_pressed() -> void:
	hide()
	confirmed.emit()


func _on_no_pressed() -> void:
	hide()
	cancelled.emit()
