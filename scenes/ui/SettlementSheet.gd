class_name SettlementSheet
extends Control

signal building_purchase_requested(building_index: int, mode: String)

@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/Header/CloseButton
@onready var settlement_panel: SettlementPanel = $PanelContainer/MarginContainer/VBoxContainer/SettlementPanel


func _ready() -> void:
	close_button.pressed.connect(hide_sheet)
	settlement_panel.building_purchase_requested.connect(_on_building_purchase_requested)
	hide()


func show_sheet() -> void:
	show()


func hide_sheet() -> void:
	hide()


func update_view(state: ClickerState) -> void:
	settlement_panel.update_view(state)


func _on_building_purchase_requested(building_index: int, mode: String) -> void:
	building_purchase_requested.emit(building_index, mode)
