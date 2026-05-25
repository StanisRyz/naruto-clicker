class_name UpgradeSheet
extends Control

signal character_level_upgrade_requested
signal autoclick_purchase_requested
signal gold_bonus_purchase_requested

@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/Header/CloseButton
@onready var upgrade_panel: UpgradePanel = $PanelContainer/MarginContainer/VBoxContainer/UpgradePanel


func _ready() -> void:
	close_button.pressed.connect(hide_sheet)
	upgrade_panel.character_level_upgrade_requested.connect(_on_character_level_upgrade_requested)
	upgrade_panel.autoclick_purchase_requested.connect(_on_autoclick_purchase_requested)
	upgrade_panel.gold_bonus_purchase_requested.connect(_on_gold_bonus_purchase_requested)
	hide()


func show_sheet() -> void:
	show()


func hide_sheet() -> void:
	hide()


func update_view(state: ClickerState) -> void:
	upgrade_panel.update_view(state)


func _on_character_level_upgrade_requested() -> void:
	character_level_upgrade_requested.emit()


func _on_autoclick_purchase_requested() -> void:
	autoclick_purchase_requested.emit()


func _on_gold_bonus_purchase_requested() -> void:
	gold_bonus_purchase_requested.emit()
