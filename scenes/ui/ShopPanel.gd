class_name ShopPanel
extends VBoxContainer

signal product_purchase_requested(product_id: String, mode: String)

const ImageSlotClass = preload("res://scripts/ui/ImageSlot.gd")

const CARD_BACKGROUND_ASSET_KEY: String = "ui.card.sheet"
const CARD_BACKGROUND_FALLBACK_COLOR: Color = Color(0.12, 0.125, 0.145, 1.0)
const CARD_OUTER_HEIGHT: int = 156
const CARD_INNER_HEIGHT: int = 136
const CARD_MARGIN_LEFT: int = 12
const CARD_MARGIN_TOP: int = 10
const CARD_MARGIN_RIGHT: int = 12
const CARD_MARGIN_BOTTOM: int = 10
const CARD_ROW_GAP: int = 3
const CARD_ROW_1_HEIGHT: int = 26
const CARD_ROW_2_HEIGHT: int = 22
const CARD_ROW_3_HEIGHT: int = 22
const CARD_ROW_4_HEIGHT: int = 22
const CARD_ROW_5_HEIGHT: int = 32

const SHOP_IMAGE_SIZE: Vector2 = Vector2(136, 136)

const CARD_BUTTON_SLOT_SIZE: Vector2 = Vector2(210, 136)
const CARD_BUTTON_SIZE: Vector2 = Vector2(210, 72)
const CARD_BUTTON_Y: int = 29

const CARD_BUTTON_DEFAULT_ASSET_KEY: String = "ui.card.button.default"
const CARD_BUTTON_ACTIVE_ASSET_KEY: String = "ui.card.button.active"
const CARD_BUTTON_FALLBACK_COLOR: Color = Color.WHITE
const CARD_BUTTON_ACTIVE_DURATION_SEC: float = 0.3

var product_rows: Dictionary = {}
var selected_buy_mode: String = "x1"
var latest_state: ClickerState = null

@onready var products_container: VBoxContainer = $ProductsContainer


func set_selected_buy_mode(mode: String) -> void:
	selected_buy_mode = mode
	if latest_state != null:
		_refresh_view()


func update_view(state: ClickerState) -> void:
	latest_state = state
	_ensure_product_rows(state)
	_refresh_view()


func _refresh_view() -> void:
	if latest_state == null:
		return
	for product_data: Dictionary in latest_state.get_shop_product_view_data(selected_buy_mode):
		var product_id: String = String(product_data.get("id", ""))
		if product_rows.has(product_id):
			_update_product_row(product_data, product_rows[product_id])


func _ensure_product_rows(state: ClickerState) -> void:
	for product_data: Dictionary in state.get_shop_product_view_data():
		var product_id: String = String(product_data.get("id", ""))
		if product_id != "" and not product_rows.has(product_id):
			product_rows[product_id] = _create_product_row(product_id)


func _create_product_row(product_id: String) -> Dictionary:
	var row := Control.new()
	row.name = "%sRow" % product_id
	row.custom_minimum_size = Vector2(0, CARD_OUTER_HEIGHT)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.clip_contents = true
	products_container.add_child(row)

	var background := ImageSlotClass.new()
	background.name = "CardBackgroundImageHolder"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.fallback_color = CARD_BACKGROUND_FALLBACK_COLOR
	background.show_fallback_behind_texture = false
	background.stretch_mode = TextureRect.STRETCH_SCALE
	row.add_child(background)
	background.set_asset_key(CARD_BACKGROUND_ASSET_KEY, CARD_BACKGROUND_FALLBACK_COLOR)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", CARD_MARGIN_LEFT)
	margin.add_theme_constant_override("margin_top", CARD_MARGIN_TOP)
	margin.add_theme_constant_override("margin_right", CARD_MARGIN_RIGHT)
	margin.add_theme_constant_override("margin_bottom", CARD_MARGIN_BOTTOM)
	row.add_child(margin)

	var content := HBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)

	var image_holder := ImageSlotClass.new()
	image_holder.name = "ImageHolder"
	image_holder.fallback_color = Color.WHITE
	image_holder.show_fallback_behind_texture = false
	image_holder.custom_minimum_size = SHOP_IMAGE_SIZE
	image_holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	content.add_child(image_holder)
	image_holder.set_asset_key(GameAssetCatalog.shop_product_icon_key(product_id))

	var right_content := Control.new()
	right_content.name = "RightContent"
	right_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_content.custom_minimum_size = Vector2(0, CARD_INNER_HEIGHT)
	right_content.clip_contents = true
	content.add_child(right_content)

	var name_label := Label.new()
	name_label.name = "ProductNameLabel"
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_place_card_row(name_label, 0, CARD_ROW_1_HEIGHT)
	right_content.add_child(name_label)
	UiFontConfig.apply_label_font_size(name_label, UiFontConfig.UPGRADE_NAME_FONT_SIZE)

	var description_label := Label.new()
	description_label.name = "ProductDescriptionLabel"
	description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	description_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	description_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_place_card_row(description_label, CARD_ROW_1_HEIGHT + CARD_ROW_GAP, CARD_ROW_2_HEIGHT)
	right_content.add_child(description_label)
	UiFontConfig.apply_label_font_size(description_label, UiFontConfig.UPGRADE_GAIN_FONT_SIZE)

	var effect_label := Label.new()
	effect_label.name = "ProductEffectLabel"
	effect_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	effect_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	effect_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_place_card_row(effect_label, CARD_ROW_1_HEIGHT + CARD_ROW_2_HEIGHT + CARD_ROW_GAP * 2, CARD_ROW_3_HEIGHT)
	right_content.add_child(effect_label)
	UiFontConfig.apply_label_font_size(effect_label, UiFontConfig.UPGRADE_VALUE_FONT_SIZE)

	var owned_label := Label.new()
	owned_label.name = "ProductOwnedLabel"
	owned_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	owned_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	owned_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_place_card_row(owned_label, CARD_ROW_1_HEIGHT + CARD_ROW_2_HEIGHT + CARD_ROW_3_HEIGHT + CARD_ROW_GAP * 3, CARD_ROW_4_HEIGHT)
	right_content.add_child(owned_label)
	UiFontConfig.apply_label_font_size(owned_label, UiFontConfig.UPGRADE_VALUE_FONT_SIZE)

	var total_bonus_label := Label.new()
	total_bonus_label.name = "ProductTotalBonusLabel"
	total_bonus_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	total_bonus_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	total_bonus_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_place_card_row(total_bonus_label, CARD_ROW_1_HEIGHT + CARD_ROW_2_HEIGHT + CARD_ROW_3_HEIGHT + CARD_ROW_4_HEIGHT + CARD_ROW_GAP * 4, CARD_ROW_5_HEIGHT)
	right_content.add_child(total_bonus_label)
	UiFontConfig.apply_label_font_size(total_bonus_label, UiFontConfig.UPGRADE_MILESTONE_FONT_SIZE)

	var button := Button.new()
	button.name = "BuyButton"
	button.custom_minimum_size = CARD_BUTTON_SIZE
	button.focus_mode = Control.FOCUS_NONE
	button.text = ""
	button.flat = true
	ButtonVisualUtils.clear_image_button_styles(button)
	button.pressed.connect(func() -> void: product_purchase_requested.emit(product_id, selected_buy_mode))

	var button_image_holder := ImageSlotClass.new()
	button_image_holder.name = "ButtonImageHolder"
	button_image_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button_image_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button_image_holder.fallback_color = CARD_BUTTON_FALLBACK_COLOR
	button_image_holder.show_fallback_behind_texture = false
	button_image_holder.stretch_mode = TextureRect.STRETCH_SCALE
	button.add_child(button_image_holder)
	button_image_holder.set_asset_key(CARD_BUTTON_DEFAULT_ASSET_KEY, CARD_BUTTON_FALLBACK_COLOR)

	var button_label := Label.new()
	button_label.name = "ButtonTextLabel"
	button_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	button_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.add_child(button_label)
	UiFontConfig.apply_label_font_size(button_label, UiFontConfig.UPGRADE_BUTTON_FONT_SIZE)

	var button_slot := Control.new()
	button_slot.name = "ButtonSlot"
	button_slot.custom_minimum_size = CARD_BUTTON_SLOT_SIZE
	button_slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	button.anchor_left = 0.0
	button.anchor_top = 0.0
	button.anchor_right = 1.0
	button.anchor_bottom = 0.0
	button.offset_left = 0.0
	button.offset_top = CARD_BUTTON_Y
	button.offset_right = 0.0
	button.offset_bottom = CARD_BUTTON_Y + int(CARD_BUTTON_SIZE.y)

	button_slot.add_child(button)
	content.add_child(button_slot)

	return {
		"name_label": name_label,
		"description_label": description_label,
		"effect_label": effect_label,
		"owned_label": owned_label,
		"total_bonus_label": total_bonus_label,
		"button": button,
		"button_label": button_label,
		"button_image_holder": button_image_holder,
		"image_holder": image_holder,
		"button_feedback_token": 0,
	}


func _update_product_row(product_data: Dictionary, row: Dictionary) -> void:
	var name_label: Label = row["name_label"]
	var description_label: Label = row["description_label"]
	var effect_label: Label = row["effect_label"]
	var owned_label: Label = row["owned_label"]
	var total_bonus_label: Label = row["total_bonus_label"]
	var button: Button = row["button"]
	var button_label: Label = row["button_label"]
	var button_image_holder = row["button_image_holder"]

	var name_key: String = String(product_data.get("name_key", ""))
	var display_name: String = LocalizationManager.tr_key(name_key) if name_key != "" else String(product_data.get("name", ""))
	var desc_key: String = String(product_data.get("description_key", ""))
	var display_desc: String = LocalizationManager.tr_key(desc_key) if desc_key != "" else String(product_data.get("description", ""))

	var cost_gems: int = int(product_data.get("cost_gems", 0))
	var buy_count: int = int(product_data.get("buy_count", 1))
	var owned_count: int = int(product_data.get("owned_count", -1))
	var total_multiplier: int = int(product_data.get("total_multiplier", -1))
	var product_type: String = String(product_data.get("product_type", "consumable"))
	var effect_key: String = String(product_data.get("effect_key", ""))
	var effect_params: Dictionary = product_data.get("effect_params", {})

	name_label.text = display_name
	description_label.text = display_desc
	effect_label.text = LocalizationManager.format_key(effect_key, effect_params) if effect_key != "" else ""

	if product_type == "permanent_multiplier":
		owned_label.text = LocalizationManager.format_key("shop.card.owned", {"count": str(owned_count)})
		total_bonus_label.text = LocalizationManager.format_key("shop.card.total_multiplier", {"multiplier": str(total_multiplier)})
	else:
		owned_label.text = ""
		total_bonus_label.text = ""

	var can_buy: bool = bool(product_data.get("can_buy", false))
	button.disabled = not can_buy
	if product_type == "rewarded_ad":
		button_label.text = LocalizationManager.tr_key("shop.button.watch_ad")
		owned_label.text = ""
		total_bonus_label.text = ""
	else:
		button_label.text = LocalizationManager.format_key(
			"shop.buy_button_count",
			{"count": str(buy_count), "cost": NumberFormatter.compact(cost_gems)}
		)
	button_image_holder.modulate = Color.WHITE if can_buy else Color(0.65, 0.65, 0.65, 1.0)
	button_label.modulate = Color.WHITE if can_buy else Color(0.45, 0.45, 0.45, 1.0)


func set_product_buy_button_modal_pressed(product_id: String, pressed: bool) -> void:
	if not product_rows.has(product_id):
		return
	var row: Dictionary = product_rows[product_id]
	if not row.has("button_image_holder"):
		return
	var key: String = CARD_BUTTON_ACTIVE_ASSET_KEY if pressed else CARD_BUTTON_DEFAULT_ASSET_KEY
	row["button_image_holder"].set_asset_key(key, CARD_BUTTON_FALLBACK_COLOR)


func play_product_purchase_feedback(product_id: String) -> void:
	if not product_rows.has(product_id):
		return
	var row: Dictionary = product_rows[product_id]
	if not row.has("button_image_holder"):
		return
	var button_image_holder = row["button_image_holder"]
	var token: int = int(row.get("button_feedback_token", 0)) + 1
	row["button_feedback_token"] = token
	button_image_holder.set_asset_key(CARD_BUTTON_ACTIVE_ASSET_KEY, CARD_BUTTON_FALLBACK_COLOR)
	await get_tree().create_timer(CARD_BUTTON_ACTIVE_DURATION_SEC).timeout
	if int(row.get("button_feedback_token", 0)) != token:
		return
	button_image_holder.set_asset_key(CARD_BUTTON_DEFAULT_ASSET_KEY, CARD_BUTTON_FALLBACK_COLOR)


func _place_card_row(control: Control, y: int, height: int) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 1.0
	control.anchor_bottom = 0.0
	control.offset_left = 0.0
	control.offset_top = y
	control.offset_right = 0.0
	control.offset_bottom = y + height
