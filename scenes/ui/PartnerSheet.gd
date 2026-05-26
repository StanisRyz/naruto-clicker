class_name PartnerSheet
extends Control

signal partner_purchase_requested(partner_index: int, mode: String)

@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/Header/CloseButton
@onready var partner_panel: PartnerPanel = $PanelContainer/MarginContainer/VBoxContainer/PartnerPanel


func _ready() -> void:
	close_button.pressed.connect(hide_sheet)
	partner_panel.partner_purchase_requested.connect(_on_partner_purchase_requested)
	hide()


func show_sheet() -> void:
	show()


func hide_sheet() -> void:
	hide()


func update_view(state: ClickerState) -> void:
	partner_panel.update_view(state)


func _on_partner_purchase_requested(partner_index: int, mode: String) -> void:
	partner_purchase_requested.emit(partner_index, mode)
