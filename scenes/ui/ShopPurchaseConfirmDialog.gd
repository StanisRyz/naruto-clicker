class_name ShopPurchaseConfirmDialog
extends Control

signal confirmed(product_id: String, mode: String)
signal cancelled

const ImageSlotClass = preload("res://scripts/ui/ImageSlot.gd")

var _pending_product_id: String = ""
var _pending_mode: String = ""
var _confirm_label: Label = null
var _cancel_label: Label = null

@onready var _title_label: Label = $CenterContainer/InnerPanel/MarginContainer/VBoxContainer/TitleLabel
@onready var _product_name_label: Label = $CenterContainer/InnerPanel/MarginContainer/VBoxContainer/ProductNameLabel
@onready var _confirm_button: Button = $CenterContainer/InnerPanel/MarginContainer/VBoxContainer/ButtonRow/ConfirmButton
@onready var _cancel_button: Button = $CenterContainer/InnerPanel/MarginContainer/VBoxContainer/ButtonRow/CancelButton


func _ready() -> void:
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_cancel_button.pressed.connect(_on_cancel_pressed)
	var inner_panel: PanelContainer = $CenterContainer/InnerPanel
	_add_background_image_holder(inner_panel, "ShopPurchaseConfirmBackgroundImageHolder", "ui.popup.shop_confirm.background")
	_confirm_label = _make_image_button_label(_confirm_button, "ui.popup.button.default", LocalizationManager.tr_key("shop.confirm.confirm"))
	_cancel_label = _make_image_button_label(_cancel_button, "ui.popup.button.default", LocalizationManager.tr_key("shop.confirm.cancel"))
	hide()


func show_dialog(product_id: String, mode: String, product_name: String) -> void:
	_pending_product_id = product_id
	_pending_mode = mode
	_title_label.text = LocalizationManager.tr_key("shop.confirm.title")
	_product_name_label.text = product_name
	if _confirm_label:
		_confirm_label.text = LocalizationManager.tr_key("shop.confirm.confirm")
	if _cancel_label:
		_cancel_label.text = LocalizationManager.tr_key("shop.confirm.cancel")
	show()
	move_to_front()


func hide_dialog() -> void:
	hide()


func _on_confirm_pressed() -> void:
	hide()
	confirmed.emit(_pending_product_id, _pending_mode)


func _on_cancel_pressed() -> void:
	hide()
	cancelled.emit()


func _add_background_image_holder(container: Control, holder_name: String, asset_key: String) -> void:
	var holder = ImageSlotClass.new()
	holder.name = holder_name
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.fallback_color = Color.WHITE
	holder.show_fallback_behind_texture = false
	holder.stretch_mode = TextureRect.STRETCH_SCALE
	container.add_child(holder)
	container.move_child(holder, 0)
	holder.set_asset_key(asset_key, Color.WHITE)


func _make_image_icon_button(button: Button, asset_key: String) -> void:
	ButtonVisualUtils.clear_image_button_styles(button)
	button.text = ""
	var holder = ImageSlotClass.new()
	holder.name = "ButtonImageHolder"
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.fallback_color = Color.WHITE
	holder.show_fallback_behind_texture = false
	holder.stretch_mode = TextureRect.STRETCH_SCALE
	button.add_child(holder)
	holder.set_asset_key(asset_key, Color.WHITE)


func _make_image_button_label(button: Button, asset_key: String, initial_text: String) -> Label:
	_make_image_icon_button(button, asset_key)
	var label := Label.new()
	label.name = "ButtonTextLabel"
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.text = initial_text
	button.add_child(label)
	return label
