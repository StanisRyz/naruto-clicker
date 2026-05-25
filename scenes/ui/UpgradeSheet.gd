class_name UpgradeSheet
extends Control

signal damage_upgrade_requested

@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/Header/CloseButton
@onready var upgrade_panel: UpgradePanel = $PanelContainer/MarginContainer/VBoxContainer/UpgradePanel


func _ready() -> void:
	close_button.pressed.connect(hide_sheet)
	upgrade_panel.damage_upgrade_requested.connect(_on_damage_upgrade_requested)
	hide()


func show_sheet() -> void:
	show()


func hide_sheet() -> void:
	hide()


func update_view(state: ClickerState) -> void:
	upgrade_panel.update_view(state)


func _on_damage_upgrade_requested() -> void:
	damage_upgrade_requested.emit()
