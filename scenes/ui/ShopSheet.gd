class_name ShopSheet
extends Control

signal product_purchase_requested(product_id: String, mode: String)
signal closed

@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/Header/CloseButton
@onready var header_resource_value_label: Label = $PanelContainer/MarginContainer/VBoxContainer/Header/HeaderResourceContainer/ResourceValueLabel
@onready var shop_panel: ShopPanel = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/ShopPanel
@onready var buy_mode_selector: ShopBuyModeSelector = $PanelContainer/MarginContainer/VBoxContainer/ShopBuyModeSelector

var _locked_status_label: Label = null


func _ready() -> void:
	ButtonVisualUtils.setup_image_button(close_button, "ui.sheet.close_button", Color.WHITE)
	UiFontConfig.apply_label_font_size(header_resource_value_label, UiFontConfig.SHEET_RESOURCE_VALUE_FONT_SIZE)
	close_button.pressed.connect(_on_close_pressed)
	shop_panel.product_purchase_requested.connect(_on_panel_product_purchase_requested)
	buy_mode_selector.buy_mode_changed.connect(shop_panel.set_selected_buy_mode)
	_create_locked_status_label()
	hide()


func _create_locked_status_label() -> void:
	var vbox: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer
	var lbl := Label.new()
	lbl.name = "LockedStatusLabel"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.75, 0.35, 1.0))
	lbl.visible = false
	vbox.add_child(lbl)
	vbox.move_child(lbl, buy_mode_selector.get_index() + 1)
	_locked_status_label = lbl


func _on_close_pressed() -> void:
	ButtonVisualUtils.play_pressed_then_call(
		close_button,
		Callable(self, "hide_sheet"),
		"ui.sheet.close_button",
		"ui.sheet.close_button.pressed",
		0.2,
		Color.WHITE
	)


func set_product_buy_button_modal_pressed(product_id: String, pressed: bool) -> void:
	shop_panel.set_product_buy_button_modal_pressed(product_id, pressed)


func set_paid_shop_available(is_available: bool) -> void:
	shop_panel.set_paid_shop_available(is_available)


func show_status(text: String) -> void:
	if _locked_status_label == null:
		return
	_locked_status_label.text = text
	_locked_status_label.visible = (text != "")


func show_sheet() -> void:
	ButtonVisualUtils.set_image_button_asset(close_button, "ui.sheet.close_button")
	show_status("")
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
