class_name GemPurchaseDialog
extends Control

signal gem_product_purchase_requested(product_id: String)

const ImageSlotClass = preload("res://scripts/ui/ImageSlot.gd")

const ICON_SIZE: Vector2 = Vector2(160, 160)
const BUY_BUTTON_SIZE: Vector2 = Vector2(160, 52)

var _product_cells: Array[Dictionary] = []
var _payment_in_progress: bool = false
var _status_label: Label = null
var _catalog_requested: bool = false

@onready var _close_button: Button = $CenterContainer/InnerPanel/ContentLayer/CloseButton
@onready var _products_grid: GridContainer = $CenterContainer/InnerPanel/ContentLayer/GridCenterContainer/ProductsGrid
@onready var _inner_panel: PanelContainer = $CenterContainer/InnerPanel


func _ready() -> void:
	_add_panel_background()
	_add_status_label()
	ButtonVisualUtils.setup_image_button(_close_button, "ui.sheet.close_button", Color.WHITE)
	_close_button.pressed.connect(_on_close_pressed)
	_build_product_cells()
	Platform.payment_catalog_loaded.connect(_on_payment_catalog_loaded)
	Platform.payment_catalog_error.connect(_on_payment_catalog_error)
	hide()


func show_dialog() -> void:
	_payment_in_progress = false
	_set_all_buy_buttons_disabled(false)
	ButtonVisualUtils.set_image_button_asset(_close_button, "ui.sheet.close_button")
	clear_status_message()
	_refresh_prices()
	show()
	move_to_front()


func hide_dialog() -> void:
	_payment_in_progress = false
	clear_status_message()
	hide()


func refresh_view() -> void:
	pass


func set_payment_done() -> void:
	_payment_in_progress = false
	_set_all_buy_buttons_disabled(false)


func set_status_message(message: String, color: Color = Color.WHITE) -> void:
	if not is_instance_valid(_status_label):
		return
	_status_label.text = message
	_status_label.modulate = color
	_status_label.visible = message != ""


func clear_status_message() -> void:
	if not is_instance_valid(_status_label):
		return
	_status_label.text = ""
	_status_label.visible = false


func set_payment_failed(message: String) -> void:
	_payment_in_progress = false
	_set_all_buy_buttons_disabled(false)
	set_status_message(message, Color(1.0, 0.45, 0.35, 1.0))


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
	buy_button.disabled = Platform.get_platform_key() == "yandex"
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
	buy_label.text = _initial_price_text(price_rub)
	buy_button.add_child(buy_label)
	UiFontConfig.apply_label_font_size(buy_label, UiFontConfig.UPGRADE_BUTTON_FONT_SIZE)

	_products_grid.add_child(cell_bg)

	return {
		"product_id": product_id,
		"buy_button": buy_button,
		"btn_bg": btn_bg,
		"buy_label": buy_label,
		"price_rub": price_rub,
	}


# On Web/Yandex, the real price is not known until payments.getCatalog()
# resolves, so cells start in a loading state instead of showing price_rub
# (which is not a valid Yandex price — see Y4 audit).
func _initial_price_text(price_rub: int) -> String:
	if Platform.get_platform_key() == "yandex":
		return LocalizationManager.tr_key("shop.gem_purchase.loading_price")
	return LocalizationManager.format_key("shop.gem_purchase.price", {"price": str(price_rub)})


func _on_buy_pressed(product_id: String, buy_button: Button) -> void:
	if _payment_in_progress:
		return
	if Platform.get_platform_key() == "yandex" and Platform.get_catalog_product(product_id).is_empty():
		if BuildConfig.is_debug_features_enabled():
			var yandex_id: String = GemPurchaseConfig.get_platform_product_id(product_id, "yandex")
			push_warning("GemPurchaseDialog: blocked purchase, catalog product missing local='%s' yandex_id='%s'" % [product_id, yandex_id])
		set_status_message(LocalizationManager.tr_key("shop.gem_purchase.product_not_found"), Color(1.0, 0.45, 0.35, 1.0))
		return
	_payment_in_progress = true
	_set_all_buy_buttons_disabled(true)
	buy_button.disabled = false
	var cell: Dictionary = _find_cell_by_product(product_id)
	if not cell.is_empty() and cell.has("btn_bg"):
		cell["btn_bg"].set_asset_key("ui.card.button.active", Color.WHITE)
	set_status_message(LocalizationManager.tr_key("shop.gem_purchase.processing"))
	gem_product_purchase_requested.emit(product_id)


func _find_cell_by_product(product_id: String) -> Dictionary:
	for cell: Dictionary in _product_cells:
		if String(cell.get("product_id", "")) == product_id:
			return cell
	return {}


# When re-enabling (disabled == false) on Web/Yandex, a product missing from
# the catalog stays disabled — Web must never let the player start a
# purchase for a product id that Yandex doesn't recognize.
func _set_all_buy_buttons_disabled(disabled: bool) -> void:
	var is_yandex: bool = Platform.get_platform_key() == "yandex"
	for cell: Dictionary in _product_cells:
		var btn: Button = cell.get("buy_button")
		var bg = cell.get("btn_bg")
		var effective_disabled: bool = disabled
		if not disabled and is_yandex:
			var product_id: String = String(cell.get("product_id", ""))
			effective_disabled = Platform.get_catalog_product(product_id).is_empty()
		if btn:
			btn.disabled = effective_disabled
		if bg:
			bg.set_asset_key("ui.card.button.default", Color.WHITE)
			bg.modulate = Color(0.65, 0.65, 0.65, 1.0) if effective_disabled else Color.WHITE


func _add_status_label() -> void:
	var content_layer: Control = $CenterContainer/InnerPanel/ContentLayer
	_status_label = Label.new()
	_status_label.name = "PaymentStatusLabel"
	@warning_ignore("INT_AS_ENUM_WITHOUT_CAST", "INT_AS_ENUM_WITHOUT_MATCH")
	_status_label.layout_mode = 1
	_status_label.anchor_left = 0.0
	_status_label.anchor_top = 1.0
	_status_label.anchor_right = 1.0
	_status_label.anchor_bottom = 1.0
	_status_label.offset_left = 16.0
	_status_label.offset_top = -64.0
	_status_label.offset_right = -16.0
	_status_label.offset_bottom = -10.0
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFontConfig.apply_label_font_size(_status_label, UiFontConfig.UPGRADE_BUTTON_FONT_SIZE)
	content_layer.add_child(_status_label)
	_status_label.visible = false


# ── Yandex payment catalog ─────────────────────────────────────────────────────

# Requests the Yandex catalog once per dialog "open" (reset on error so a
# later show_dialog() can retry) and refreshes cell prices from whatever is
# already cached. Never touches Android/RuStore or debug price display.
func _refresh_prices() -> void:
	if Platform.get_platform_key() != "yandex":
		return
	var cache: Dictionary = Platform.get_cached_payment_catalog()
	if cache.is_empty():
		_set_all_prices_loading()
		if not _catalog_requested:
			_catalog_requested = true
			Platform.load_payment_catalog()
		return
	_apply_catalog_prices()


func _set_all_prices_loading() -> void:
	var loading_text: String = LocalizationManager.tr_key("shop.gem_purchase.loading_price")
	for cell: Dictionary in _product_cells:
		var label: Label = cell.get("buy_label")
		if label:
			label.text = loading_text


func _apply_catalog_prices() -> void:
	for cell: Dictionary in _product_cells:
		var product_id: String = String(cell.get("product_id", ""))
		var label: Label = cell.get("buy_label")
		var catalog_product: Dictionary = Platform.get_catalog_product(product_id)
		if catalog_product.is_empty():
			if label:
				label.text = LocalizationManager.tr_key("shop.gem_purchase.unavailable")
		elif label:
			label.text = str(catalog_product.get("price", ""))
	if not _payment_in_progress:
		_set_all_buy_buttons_disabled(false)


func _on_payment_catalog_loaded(_products: Array) -> void:
	if Platform.get_platform_key() != "yandex" or not visible:
		return
	_apply_catalog_prices()


func _on_payment_catalog_error(message: String) -> void:
	if Platform.get_platform_key() != "yandex":
		return
	# Always clear the request flag, even if the dialog was closed before the
	# response/timeout arrived — otherwise a later show_dialog() would see
	# _catalog_requested == true forever and never retry the catalog load.
	_catalog_requested = false
	if not visible:
		return
	var error_key: String = "yandex.catalog.timeout" if message.to_lower().begins_with("timeout") else "shop.gem_purchase.catalog_error"
	var error_text: String = LocalizationManager.tr_key(error_key)
	for cell: Dictionary in _product_cells:
		var label: Label = cell.get("buy_label")
		if label:
			label.text = error_text
	set_status_message(LocalizationManager.tr_key("yandex.catalog.unavailable"), Color(1.0, 0.45, 0.35, 1.0))
	_set_all_buy_buttons_disabled(true)


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
