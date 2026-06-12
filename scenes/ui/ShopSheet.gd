class_name ShopSheet
extends Control

signal product_purchase_requested(product_id: String, mode: String)
signal closed

@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/Header/CloseButton
@onready var header_resource_value_label: Label = $PanelContainer/MarginContainer/VBoxContainer/Header/HeaderResourceContainer/ResourceValueLabel
@onready var shop_panel: ShopPanel = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/ShopPanel
@onready var buy_mode_selector: ShopBuyModeSelector = $PanelContainer/MarginContainer/VBoxContainer/ShopBuyModeSelector


func _ready() -> void:
	ButtonVisualUtils.setup_image_button(close_button, "ui.sheet.close_button", Color.WHITE)
	UiFontConfig.apply_label_font_size(header_resource_value_label, UiFontConfig.SHEET_RESOURCE_VALUE_FONT_SIZE)
	close_button.pressed.connect(_on_close_pressed)
	shop_panel.product_purchase_requested.connect(_on_panel_product_purchase_requested)
	buy_mode_selector.buy_mode_changed.connect(shop_panel.set_selected_buy_mode)
	hide()


func _on_close_pressed() -> void:
	ButtonVisualUtils.flash_button_image_holder(
		close_button.find_child("ButtonImageHolder", false, false),
		"ui.sheet.close_button"
	)
	hide_sheet()


func set_product_buy_button_modal_pressed(product_id: String, pressed: bool) -> void:
	shop_panel.set_product_buy_button_modal_pressed(product_id, pressed)


func show_sheet() -> void:
	show()


func hide_sheet() -> void:
	hide()
	closed.emit()


func update_view(state: ClickerState) -> void:
	header_resource_value_label.text = NumberFormatter.compact(state.gems)
	shop_panel.update_view(state)


func _on_panel_product_purchase_requested(product_id: String, mode: String) -> void:
	product_purchase_requested.emit(product_id, mode)


func play_product_purchase_feedback(product_id: String) -> void:
	shop_panel.play_product_purchase_feedback(product_id)
