class_name SettlementSheet
extends Control

signal building_purchase_requested(building_index: int, mode: String)
signal closed

@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/Header/CloseButton
@onready var header_resource_value_label: Label = $PanelContainer/MarginContainer/VBoxContainer/Header/HeaderResourceContainer/ResourceValueLabel
@onready var buy_mode_selector: BuyModeSelector = $PanelContainer/MarginContainer/VBoxContainer/BuyModeSelector
@onready var settlement_panel: SettlementPanel = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/SettlementPanel

var current_state: ClickerState = null


func _ready() -> void:
	ButtonVisualUtils.setup_image_button(close_button, "ui.sheet.close_button", Color.WHITE)
	UiFontConfig.apply_label_font_size(header_resource_value_label, UiFontConfig.SHEET_RESOURCE_VALUE_FONT_SIZE)
	close_button.pressed.connect(_on_close_pressed)
	buy_mode_selector.buy_mode_changed.connect(_on_buy_mode_changed)
	settlement_panel.set_buy_mode(buy_mode_selector.get_selected_mode())
	settlement_panel.building_purchase_requested.connect(_on_building_purchase_requested)
	hide()


func _on_close_pressed() -> void:
	ButtonVisualUtils.flash_button_image_holder(
		close_button.find_child("ButtonImageHolder", false, false),
		"ui.sheet.close_button"
	)
	hide_sheet()


func show_sheet() -> void:
	show()


func hide_sheet() -> void:
	hide()
	closed.emit()


func update_view(state: ClickerState) -> void:
	current_state = state
	header_resource_value_label.text = NumberFormatter.compact(state.gold)
	settlement_panel.update_view(state)


func _on_buy_mode_changed(mode: String) -> void:
	settlement_panel.set_buy_mode(mode)
	if current_state != null:
		update_view(current_state)


func _on_building_purchase_requested(building_index: int, mode: String) -> void:
	building_purchase_requested.emit(building_index, mode)


func play_building_purchase_feedback(building_index: int) -> void:
	settlement_panel.play_building_purchase_feedback(building_index)
