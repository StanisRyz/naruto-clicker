class_name SettlementPanel
extends VBoxContainer

signal building_purchase_requested(building_index: int, mode: String)

const BUY_MODES: Array[String] = ["x1", "x10", "x100", "max"]
const BUILDING_IMAGE_SIZE: Vector2 = Vector2(136, 136)
const BUILDING_BUTTON_SLOT_SIZE: Vector2 = Vector2(210, 136)
const BUILDING_BUTTON_SIZE: Vector2 = Vector2(210, 72)
const CARD_BUTTON_Y: int = 29
const CARD_BUTTON_DEFAULT_ASSET_KEY: String = "ui.card.button.default"
const CARD_BUTTON_ACTIVE_ASSET_KEY: String = "ui.card.button.active"
const CARD_BUTTON_ACTIVE_DURATION_SEC: float = 0.3
const CARD_BUTTON_FALLBACK_COLOR: Color = Color.WHITE
const CARD_ROW_LABEL_COUNT: int = 5
const CARD_BACKGROUND_ASSET_KEY: String = "ui.card.sheet"
const CARD_BACKGROUND_FALLBACK_COLOR: Color = Color(0.12, 0.125, 0.145, 1.0)
const CARD_HEIGHT: int = 156
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

const ImageSlotClass = preload("res://scripts/ui/ImageSlot.gd")

var selected_buy_mode: String = "x1"
var current_state: ClickerState = null
var building_rows: Array[Dictionary] = []

@onready var rows_container: VBoxContainer = $RowsContainer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	rows_container.mouse_filter = Control.MOUSE_FILTER_PASS


func update_view(state: ClickerState) -> void:
	current_state = state
	_ensure_building_rows(state)

	for building_index in range(building_rows.size()):
		var panel_row: Control = building_rows[building_index]["row"]
		panel_row.visible = _should_show_building_row(state, building_index)
		_update_building_row(state, building_index, building_rows[building_index])


func _ensure_building_rows(_state: ClickerState) -> void:
	while building_rows.size() < SettlementConfig.BUILDING_NAMES.size():
		var building_index: int = building_rows.size()
		building_rows.append(_create_building_row(building_index))


func _create_image_card_button(button_name: String) -> Dictionary:
	var button := Button.new()
	button.name = button_name
	button.custom_minimum_size = BUILDING_BUTTON_SIZE
	button.focus_mode = Control.FOCUS_NONE
	button.text = ""
	button.flat = true
	ButtonVisualUtils.clear_image_button_styles(button)

	var background = ImageSlotClass.new()
	background.name = "ButtonImageHolder"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.fallback_color = CARD_BUTTON_FALLBACK_COLOR
	background.show_fallback_behind_texture = false
	background.stretch_mode = TextureRect.STRETCH_SCALE
	button.add_child(background)
	background.set_asset_key(CARD_BUTTON_DEFAULT_ASSET_KEY, CARD_BUTTON_FALLBACK_COLOR)

	var label := Label.new()
	label.name = "ButtonTextLabel"
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.add_child(label)

	return {
		"button": button,
		"button_label": label,
		"button_image_holder": background,
		"button_feedback_token": 0,
	}


func play_card_button_active_feedback(row: Dictionary) -> void:
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


func play_building_purchase_feedback(building_index: int) -> void:
	if building_index < building_rows.size():
		play_card_button_active_feedback(building_rows[building_index])


func _set_card_button_state(row: Dictionary, enabled: bool) -> void:
	var button: Button = row["button"]
	var button_label: Label = row["button_label"]
	var button_image_holder = row["button_image_holder"]
	button.disabled = not enabled
	button_image_holder.modulate = Color.WHITE if enabled else Color(0.65, 0.65, 0.65, 1.0)
	button_label.modulate = Color.WHITE if enabled else Color(0.45, 0.45, 0.45, 1.0)


func _create_card_button_slot(button: Button) -> Control:
	var slot := Control.new()
	slot.name = "ButtonSlot"
	slot.custom_minimum_size = BUILDING_BUTTON_SLOT_SIZE
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slot.mouse_filter = Control.MOUSE_FILTER_PASS

	button.custom_minimum_size = BUILDING_BUTTON_SIZE
	button.anchor_left = 0.0
	button.anchor_top = 0.0
	button.anchor_right = 1.0
	button.anchor_bottom = 0.0
	button.offset_left = 0.0
	button.offset_top = CARD_BUTTON_Y
	button.offset_right = 0.0
	button.offset_bottom = CARD_BUTTON_Y + int(BUILDING_BUTTON_SIZE.y)

	slot.add_child(button)
	return slot


func _place_card_row(control: Control, y: int, height: int) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 1.0
	control.anchor_bottom = 0.0
	control.offset_left = 0.0
	control.offset_top = y
	control.offset_right = 0.0
	control.offset_bottom = y + height


func _create_card_row(row_name: String) -> Control:
	var row := Control.new()
	row.name = row_name
	row.custom_minimum_size = Vector2(0, CARD_OUTER_HEIGHT)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.clip_contents = true
	row.mouse_filter = Control.MOUSE_FILTER_PASS

	var background := ImageSlotClass.new()
	background.name = "CardBackgroundImageHolder"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.fallback_color = CARD_BACKGROUND_FALLBACK_COLOR
	background.show_fallback_behind_texture = false
	background.stretch_mode = TextureRect.STRETCH_SCALE
	row.add_child(background)
	background.set_asset_key(CARD_BACKGROUND_ASSET_KEY, CARD_BACKGROUND_FALLBACK_COLOR)

	return row


func _create_building_row(building_index: int) -> Dictionary:
	var row: Control = _create_card_row("Building%dRow" % (building_index + 1))
	rows_container.add_child(row)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", CARD_MARGIN_LEFT)
	margin.add_theme_constant_override("margin_top", CARD_MARGIN_TOP)
	margin.add_theme_constant_override("margin_right", CARD_MARGIN_RIGHT)
	margin.add_theme_constant_override("margin_bottom", CARD_MARGIN_BOTTOM)
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(margin)

	var content := HBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_child(content)

	var image_holder = ImageSlotClass.new()
	image_holder.name = "ImageHolder"
	image_holder.fallback_color = Color.WHITE
	image_holder.show_fallback_behind_texture = false
	image_holder.custom_minimum_size = BUILDING_IMAGE_SIZE
	image_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(image_holder)
	image_holder.set_asset_key(GameAssetCatalog.building_icon_key(building_index))

	var right_content := Control.new()
	right_content.name = "RightContent"
	right_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_content.custom_minimum_size = Vector2(0, CARD_INNER_HEIGHT)
	right_content.clip_contents = true
	right_content.mouse_filter = Control.MOUSE_FILTER_PASS
	content.add_child(right_content)

	var building_name_label := Label.new()
	building_name_label.name = "BuildingNameLabel"
	building_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	building_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	building_name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	building_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFontConfig.apply_label_font_size(building_name_label, UiFontConfig.SETTLEMENT_NAME_FONT_SIZE)
	_place_card_row(building_name_label, 0, CARD_ROW_1_HEIGHT)
	right_content.add_child(building_name_label)

	var building_count_label := Label.new()
	building_count_label.name = "BuildingCountLabel"
	building_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	building_count_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	building_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFontConfig.apply_label_font_size(building_count_label, UiFontConfig.SETTLEMENT_COUNT_FONT_SIZE)
	_place_card_row(building_count_label, CARD_ROW_1_HEIGHT + CARD_ROW_GAP, CARD_ROW_2_HEIGHT)
	right_content.add_child(building_count_label)

	var purchase_bonus_gain_label := Label.new()
	purchase_bonus_gain_label.name = "PurchaseBonusGainLabel"
	purchase_bonus_gain_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	purchase_bonus_gain_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	purchase_bonus_gain_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFontConfig.apply_label_font_size(purchase_bonus_gain_label, UiFontConfig.SETTLEMENT_PURCHASE_GAIN_FONT_SIZE)
	_place_card_row(purchase_bonus_gain_label, CARD_ROW_1_HEIGHT + CARD_ROW_2_HEIGHT + CARD_ROW_GAP * 2, CARD_ROW_3_HEIGHT)
	right_content.add_child(purchase_bonus_gain_label)

	var total_bonus_label := Label.new()
	total_bonus_label.name = "TotalBonusLabel"
	total_bonus_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	total_bonus_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	total_bonus_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFontConfig.apply_label_font_size(total_bonus_label, UiFontConfig.SETTLEMENT_TOTAL_BONUS_FONT_SIZE)
	_place_card_row(total_bonus_label, CARD_ROW_1_HEIGHT + CARD_ROW_2_HEIGHT + CARD_ROW_3_HEIGHT + CARD_ROW_GAP * 3, CARD_ROW_4_HEIGHT)
	right_content.add_child(total_bonus_label)

	var milestone_label := Label.new()
	milestone_label.name = "MilestoneLabel"
	milestone_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	milestone_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	milestone_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	milestone_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFontConfig.apply_label_font_size(milestone_label, UiFontConfig.SETTLEMENT_MILESTONE_FONT_SIZE)
	_place_card_row(milestone_label, CARD_ROW_1_HEIGHT + CARD_ROW_2_HEIGHT + CARD_ROW_3_HEIGHT + CARD_ROW_4_HEIGHT + CARD_ROW_GAP * 4, CARD_ROW_5_HEIGHT)
	right_content.add_child(milestone_label)

	var btn_dict := _create_image_card_button("BuyButton")
	var button: Button = btn_dict["button"]
	var button_label: Label = btn_dict["button_label"]
	var button_image_holder = btn_dict["button_image_holder"]
	button.pressed.connect(func() -> void: building_purchase_requested.emit(building_index, selected_buy_mode))
	UiFontConfig.apply_label_font_size(button_label, UiFontConfig.SETTLEMENT_BUTTON_FONT_SIZE)
	var button_slot := _create_card_button_slot(button)
	content.add_child(button_slot)

	return {
		"row": row,
		"building_name_label": building_name_label,
		"building_count_label": building_count_label,
		"purchase_bonus_gain_label": purchase_bonus_gain_label,
		"total_bonus_label": total_bonus_label,
		"milestone_label": milestone_label,
		"button": button,
		"button_label": button_label,
		"button_image_holder": button_image_holder,
	}


func _update_building_row(state: ClickerState, building_index: int, row: Dictionary) -> void:
	var building_name_label: Label = row["building_name_label"]
	var building_count_label: Label = row["building_count_label"]
	var purchase_bonus_gain_label: Label = row["purchase_bonus_gain_label"]
	var total_bonus_label: Label = row["total_bonus_label"]
	var milestone_label: Label = row["milestone_label"]

	var building_name: String = LocalizationManager.tr_key(SettlementConfig.get_name_key(building_index))
	var owned_count: int = state.building_counts[building_index]

	building_name_label.text = LocalizationManager.format_key("settlement.card.name", {"name": building_name})

	building_count_label.text = LocalizationManager.format_key("settlement.card.count", {"count": owned_count})

	purchase_bonus_gain_label.text = ClickerStatePresentation.get_building_purchase_bonus_gain_text(state, building_index, selected_buy_mode)

	total_bonus_label.text = ClickerStatePresentation.get_building_total_bonus_text(state, building_index)

	var next_milestone: int = state.get_next_milestone(owned_count)
	if next_milestone > 0:
		milestone_label.text = LocalizationManager.format_key("settlement.card.milestone_next", {"milestone": next_milestone})
	else:
		milestone_label.text = LocalizationManager.tr_key("settlement.card.milestone_max")

	var bulk_count: int = state.get_building_bulk_display_count(building_index, selected_buy_mode)
	var bulk_cost: int = state.get_building_bulk_display_cost(building_index, selected_buy_mode)
	var can_afford: bool = state.can_afford_building_bulk(building_index, selected_buy_mode)
	row["button_label"].text = LocalizationManager.format_key("settlement.build_button", {
		"count": bulk_count,
		"cost": NumberFormatter.compact(bulk_cost),
	})
	_set_card_button_state(row, can_afford)


func set_buy_mode(mode: String) -> void:
	if not BUY_MODES.has(mode):
		return
	selected_buy_mode = mode


func _should_show_building_row(_state: ClickerState, building_index: int) -> bool:
	return building_index >= 0 and building_index < SettlementConfig.BUILDING_NAMES.size()
