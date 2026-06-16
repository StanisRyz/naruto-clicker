class_name GemPurchaseDialog
extends Control

signal gem_product_purchase_requested(product_id: String)

const ImageSlotClass = preload("res://scripts/ui/ImageSlot.gd")

const ICON_SIZE: Vector2 = Vector2(160, 160)
const BUY_BUTTON_SIZE: Vector2 = Vector2(160, 52)

var _product_cells: Array[Dictionary] = []
var _payment_in_progress: bool = false

@onready var _close_button: Button = $CenterContainer/InnerPanel/ContentLayer/CloseButton
@onready var _products_grid: GridContainer = $CenterContainer/InnerPanel/ContentLayer/GridCenterContainer/ProductsGrid
@onready var _inner_panel: PanelContainer = $CenterContainer/InnerPanel


func _ready() -> void:
	_add_panel_background()
	ButtonVisualUtils.setup_image_button(_close_button, "ui.sheet.close_button", Color.WHITE)
	_close_button.pressed.connect(_on_close_pressed)
	_build_product_cells()
	hide()


func show_dialog() -> void:
	_payment_in_progress = false
	_set_all_buy_buttons_disabled(false)
	ButtonVisualUtils.set_image_button_asset(_close_button, "ui.sheet.close_button")
	show()
	move_to_front()


func hide_dialog() -> void:
	_payment_in_progress = false
	hide()


func refresh_view() -> void:
	pass


func set_payment_done() -> void:
	_payment_in_progress = false
	_set_all_buy_buttons_disabled(false)


func _on_close_pressed() -> void:
	if _payment_in_progress:
		return
	ButtonVisualUtils.play_pressed_then_call(
		_close_button,
		Callable(self, "hide_dialog"),
		"ui.sheet.close_button",
		"ui.sheet.close_button.pressed",
		0.2,
		Color.WHITE
	)


func _build_product_cells() -> void:
	for product: Dictionary in GemPurchaseConfig.GEM_PRODUCTS:
		var product_id: String = String(product.get("id", ""))
		if product_id == "":
			continue
		_product_cells.append(_create_product_cell(product_id, product))


func _create_product_cell(product_id: String, product: Dictionary) -> Dictionary:
	var cell_bg := MarginContainer.new()
	cell_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell_bg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cell_bg.add_theme_constant_override("margin_left", 12)
	cell_bg.add_theme_constant_override("margin_top", 12)
	cell_bg.add_theme_constant_override("margin_right", 12)
	cell_bg.add_theme_constant_override("margin_bottom", 12)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	cell_bg.add_child(vbox)

	var icon_key: String = String(product.get("icon_key", "shop.%s" % product_id))
	var icon_holder := ImageSlotClass.new()
	icon_holder.fallback_color = Color(0.25, 0.27, 0.32, 1.0)
	icon_holder.show_fallback_behind_texture = false
	icon_holder.custom_minimum_size = ICON_SIZE
	icon_holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(icon_holder)
	icon_holder.set_asset_key(icon_key)

	var price_rub: int = int(product.get("price_rub", 0))

	var buy_button := Button.new()
	buy_button.custom_minimum_size = BUY_BUTTON_SIZE
	buy_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	buy_button.focus_mode = Control.FOCUS_NONE
	buy_button.text = ""
	buy_button.flat = true
	ButtonVisualUtils.clear_image_button_styles(buy_button)
	buy_button.pressed.connect(func() -> void: _on_buy_pressed(product_id, buy_button))
	vbox.add_child(buy_button)

	var btn_bg := ImageSlotClass.new()
	btn_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn_bg.fallback_color = Color.WHITE
	btn_bg.show_fallback_behind_texture = false
	btn_bg.stretch_mode = TextureRect.STRETCH_SCALE
	buy_button.add_child(btn_bg)
	btn_bg.set_asset_key("ui.card.button.default", Color.WHITE)

	var buy_label := Label.new()
	buy_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	buy_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	buy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	buy_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	buy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	buy_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	buy_label.text = LocalizationManager.format_key("shop.gem_purchase.price", {"price": str(price_rub)})
	buy_button.add_child(buy_label)
	UiFontConfig.apply_label_font_size(buy_label, UiFontConfig.UPGRADE_BUTTON_FONT_SIZE)

	_products_grid.add_child(cell_bg)

	return {
		"product_id": product_id,
		"buy_button": buy_button,
		"btn_bg": btn_bg,
	}


func _on_buy_pressed(product_id: String, buy_button: Button) -> void:
	if _payment_in_progress:
		return
	_payment_in_progress = true
	_set_all_buy_buttons_disabled(true)
	buy_button.disabled = false
	var cell: Dictionary = _find_cell_by_product(product_id)
	if not cell.is_empty() and cell.has("btn_bg"):
		cell["btn_bg"].set_asset_key("ui.card.button.active", Color.WHITE)
	gem_product_purchase_requested.emit(product_id)


func _find_cell_by_product(product_id: String) -> Dictionary:
	for cell: Dictionary in _product_cells:
		if String(cell.get("product_id", "")) == product_id:
			return cell
	return {}


func _set_all_buy_buttons_disabled(disabled: bool) -> void:
	for cell: Dictionary in _product_cells:
		var btn: Button = cell.get("buy_button")
		var bg = cell.get("btn_bg")
		if btn:
			btn.disabled = disabled
		if bg:
			bg.set_asset_key("ui.card.button.default", Color.WHITE)
			bg.modulate = Color(0.65, 0.65, 0.65, 1.0) if disabled else Color.WHITE


func _add_panel_background() -> void:
	var holder := ImageSlotClass.new()
	holder.name = "BackgroundImageHolder"
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.fallback_color = Color.WHITE
	holder.show_fallback_behind_texture = false
	holder.stretch_mode = TextureRect.STRETCH_SCALE
	_inner_panel.add_child(holder)
	_inner_panel.move_child(holder, 0)
	holder.set_asset_key("ui.dialog.gem_purchase.background", Color.WHITE)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not _inner_panel.get_global_rect().has_point(event.global_position):
			if _payment_in_progress:
				return
			hide_dialog()
