class_name GemPurchaseDialog
extends Control

signal gem_product_purchase_requested(product_id: String)

const ImageSlotClass = preload("res://scripts/ui/ImageSlot.gd")

const DIALOG_MIN_SIZE: Vector2 = Vector2(500, 360)
const PANEL_BG_COLOR: Color = Color(0.08, 0.085, 0.1, 1)
const PANEL_BORDER_COLOR: Color = Color(0.24, 0.25, 0.3, 1)

const ROW_HEIGHT: int = 90
const ROW_GAP: int = 8
const ICON_SIZE: Vector2 = Vector2(72, 72)

var _product_rows: Array[Dictionary] = []

@onready var _products_container: VBoxContainer = $CenterContainer/InnerPanel/MarginContainer/VBoxContainer/ProductsContainer
@onready var _title_label: Label = $CenterContainer/InnerPanel/MarginContainer/VBoxContainer/TitleLabel
@onready var _inner_panel: PanelContainer = $CenterContainer/InnerPanel


func _ready() -> void:
	_add_panel_background()
	_build_product_rows()
	_refresh_labels()
	hide()


func show_dialog() -> void:
	_refresh_labels()
	show()
	move_to_front()


func hide_dialog() -> void:
	hide()


func refresh_view() -> void:
	_refresh_labels()


func _refresh_labels() -> void:
	_title_label.text = LocalizationManager.tr_key("shop.gem_purchase.title")
	for row_data: Dictionary in _product_rows:
		var product: Dictionary = GemPurchaseConfig.get_by_id(String(row_data.get("product_id", "")))
		if product.is_empty():
			continue
		var name_label: Label = row_data.get("name_label")
		var desc_label: Label = row_data.get("desc_label")
		var amount_label: Label = row_data.get("amount_label")
		var buy_label: Label = row_data.get("buy_label")
		if name_label:
			name_label.text = LocalizationManager.tr_key(String(product.get("name_key", "")))
		if desc_label:
			desc_label.text = LocalizationManager.tr_key(String(product.get("description_key", "")))
		if amount_label:
			var gems: int = int(product.get("amount_gems", 0))
			amount_label.text = LocalizationManager.format_key("shop.gem_purchase.amount", {"amount": str(gems)})
		if buy_label:
			buy_label.text = LocalizationManager.tr_key("shop.gem_purchase.buy")


func _build_product_rows() -> void:
	for product: Dictionary in GemPurchaseConfig.GEM_PRODUCTS:
		var product_id: String = String(product.get("id", ""))
		if product_id == "":
			continue

		var row := _create_product_row(product_id, product)
		_product_rows.append(row)


func _create_product_row(product_id: String, product: Dictionary) -> Dictionary:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.12, 0.125, 0.145, 1.0)
	card_style.border_width_left = 1
	card_style.border_width_top = 1
	card_style.border_width_right = 1
	card_style.border_width_bottom = 1
	card_style.border_color = Color(0.20, 0.21, 0.26, 1.0)
	card.add_theme_stylebox_override("panel", card_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	margin.add_child(hbox)

	var icon_holder := ImageSlotClass.new()
	icon_holder.fallback_color = Color.WHITE
	icon_holder.show_fallback_behind_texture = false
	icon_holder.custom_minimum_size = ICON_SIZE
	icon_holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(icon_holder)
	icon_holder.set_asset_key(GameAssetCatalog.shop_product_icon_key(product_id))

	var text_vbox := VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(text_vbox)

	var name_label := Label.new()
	name_label.text = LocalizationManager.tr_key(String(product.get("name_key", "")))
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	UiFontConfig.apply_label_font_size(name_label, UiFontConfig.UPGRADE_NAME_FONT_SIZE)
	text_vbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = LocalizationManager.tr_key(String(product.get("description_key", "")))
	desc_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	desc_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	UiFontConfig.apply_label_font_size(desc_label, UiFontConfig.UPGRADE_GAIN_FONT_SIZE)
	text_vbox.add_child(desc_label)

	var amount_label := Label.new()
	var gems: int = int(product.get("amount_gems", 0))
	amount_label.text = LocalizationManager.format_key("shop.gem_purchase.amount", {"amount": str(gems)})
	amount_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	amount_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	UiFontConfig.apply_label_font_size(amount_label, UiFontConfig.UPGRADE_VALUE_FONT_SIZE)
	text_vbox.add_child(amount_label)

	var buy_button := Button.new()
	buy_button.custom_minimum_size = Vector2(100, 58)
	buy_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	buy_button.focus_mode = Control.FOCUS_NONE
	buy_button.text = ""
	buy_button.flat = true
	ButtonVisualUtils.clear_image_button_styles(buy_button)
	buy_button.pressed.connect(func() -> void: gem_product_purchase_requested.emit(product_id))
	hbox.add_child(buy_button)

	var btn_bg := ImageSlotClass.new()
	btn_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn_bg.fallback_color = Color.WHITE
	btn_bg.show_fallback_behind_texture = false
	btn_bg.stretch_mode = TextureRect.STRETCH_SCALE
	buy_button.add_child(btn_bg)
	btn_bg.set_asset_key("ui.card.button.default", Color.WHITE)

	var buy_label := Label.new()
	buy_label.name = "ButtonTextLabel"
	buy_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	buy_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	buy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	buy_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	buy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	buy_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	buy_label.text = LocalizationManager.tr_key("shop.gem_purchase.buy")
	buy_button.add_child(buy_label)
	UiFontConfig.apply_label_font_size(buy_label, UiFontConfig.UPGRADE_BUTTON_FONT_SIZE)

	_products_container.add_child(card)

	return {
		"product_id": product_id,
		"name_label": name_label,
		"desc_label": desc_label,
		"amount_label": amount_label,
		"buy_label": buy_label,
	}


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
		var center_panel: PanelContainer = $CenterContainer/InnerPanel
		if not center_panel.get_global_rect().has_point(event.global_position):
			hide_dialog()
