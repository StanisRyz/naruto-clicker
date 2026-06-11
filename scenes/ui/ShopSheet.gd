class_name ShopSheet
extends Control

signal product_purchase_requested(product_id: String)
signal test_gems_requested
signal closed

@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/Header/CloseButton
@onready var header_resource_value_label: Label = $PanelContainer/MarginContainer/VBoxContainer/Header/HeaderResourceContainer/ResourceValueLabel
@onready var shop_panel: ShopPanel = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/ShopPanel


func _ready() -> void:
	ButtonVisualUtils.setup_image_button(close_button, "ui.sheet.close_button", Color.WHITE)
	UiFontConfig.apply_label_font_size(header_resource_value_label, UiFontConfig.SHEET_RESOURCE_VALUE_FONT_SIZE)
	close_button.pressed.connect(hide_sheet)
	shop_panel.product_purchase_requested.connect(_on_panel_product_purchase_requested)
	shop_panel.test_gems_requested.connect(_on_panel_test_gems_requested)
	hide()


func show_sheet() -> void:
	show()


func hide_sheet() -> void:
	hide()
	closed.emit()


func update_view(state: ClickerState) -> void:
	header_resource_value_label.text = NumberFormatter.compact(state.gems)
	shop_panel.update_view(state)


func _on_panel_product_purchase_requested(product_id: String) -> void:
	product_purchase_requested.emit(product_id)


func play_product_purchase_feedback(product_id: String) -> void:
	shop_panel.play_product_purchase_feedback(product_id)


func _on_panel_test_gems_requested() -> void:
	test_gems_requested.emit()
