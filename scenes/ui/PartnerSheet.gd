class_name PartnerSheet
extends Control

signal partner_purchase_requested(partner_index: int, mode: String)
signal closed

@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/Header/CloseButton
@onready var header_resource_value_label: Label = $PanelContainer/MarginContainer/VBoxContainer/Header/HeaderResourceContainer/ResourceValueLabel
@onready var buy_mode_selector: BuyModeSelector = $PanelContainer/MarginContainer/VBoxContainer/BuyModeSelector
@onready var partner_panel: PartnerPanel = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/PartnerPanel

var current_state: ClickerState = null


func _ready() -> void:
	close_button.pressed.connect(hide_sheet)
	buy_mode_selector.buy_mode_changed.connect(_on_buy_mode_changed)
	partner_panel.set_buy_mode(buy_mode_selector.get_selected_mode())
	partner_panel.partner_purchase_requested.connect(_on_partner_purchase_requested)
	hide()


func show_sheet() -> void:
	show()


func hide_sheet() -> void:
	hide()
	closed.emit()


func update_view(state: ClickerState) -> void:
	current_state = state
	header_resource_value_label.text = "%d" % state.gold
	partner_panel.update_view(state)


func _on_buy_mode_changed(mode: String) -> void:
	partner_panel.set_buy_mode(mode)
	if current_state != null:
		update_view(current_state)


func _on_partner_purchase_requested(partner_index: int, mode: String) -> void:
	partner_purchase_requested.emit(partner_index, mode)
