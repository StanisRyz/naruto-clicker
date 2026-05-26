class_name UpgradeSheet
extends Control

signal character_level_upgrade_requested(mode: String)
signal autoclick_purchase_requested
signal gold_bonus_purchase_requested
signal focus_burst_purchase_requested
signal rally_purchase_requested
signal closed

@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/Header/CloseButton
@onready var upgrade_panel: UpgradePanel = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/UpgradePanel


func _ready() -> void:
	close_button.pressed.connect(hide_sheet)
	upgrade_panel.character_level_upgrade_requested.connect(_on_character_level_upgrade_requested)
	upgrade_panel.autoclick_purchase_requested.connect(_on_autoclick_purchase_requested)
	upgrade_panel.gold_bonus_purchase_requested.connect(_on_gold_bonus_purchase_requested)
	upgrade_panel.focus_burst_purchase_requested.connect(_on_focus_burst_purchase_requested)
	upgrade_panel.rally_purchase_requested.connect(_on_rally_purchase_requested)
	hide()


func show_sheet() -> void:
	show()


func hide_sheet() -> void:
	hide()
	closed.emit()


func update_view(state: ClickerState) -> void:
	upgrade_panel.update_view(state)


func _on_character_level_upgrade_requested(mode: String) -> void:
	character_level_upgrade_requested.emit(mode)


func _on_autoclick_purchase_requested() -> void:
	autoclick_purchase_requested.emit()


func _on_gold_bonus_purchase_requested() -> void:
	gold_bonus_purchase_requested.emit()


func _on_focus_burst_purchase_requested() -> void:
	focus_burst_purchase_requested.emit()


func _on_rally_purchase_requested() -> void:
	rally_purchase_requested.emit()
