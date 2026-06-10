class_name PrestigePanel
extends VBoxContainer

signal prestige_requested
signal prestige_talent_purchase_requested(talent_index: int, mode: String)

const BUY_MODES: Array[String] = ["x1", "x10", "x100", "max"]
const TALENT_IMAGE_SIZE: Vector2 = Vector2(136, 136)
const TALENT_BUTTON_SLOT_SIZE: Vector2 = Vector2(210, 136)
const TALENT_BUTTON_SIZE: Vector2 = Vector2(210, 72)
const CARD_BUTTON_Y: int = 29
const CARD_BUTTON_DEFAULT_ASSET_KEY: String = "ui.card.button.default"
const CARD_BUTTON_ACTIVE_ASSET_KEY: String = "ui.card.button.active"
const CARD_BUTTON_ACTIVE_DURATION_SEC: float = 0.3
const CARD_BUTTON_FALLBACK_COLOR: Color = Color.WHITE
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
var prestige_action_row: Dictionary = {}
var talent_rows: Array[Dictionary] = []

@onready var action_container: VBoxContainer = $ActionContainer
@onready var talents_container: VBoxContainer = $TalentsContainer


func _ready() -> void:
	prestige_action_row = _create_prestige_action_row()


func set_buy_mode(mode: String) -> void:
	if not BUY_MODES.has(mode):
		return
	selected_buy_mode = mode


func update_view(state: ClickerState) -> void:
	_ensure_talent_rows(state)
	var total_reward: int = state.get_prestige_reward()

	_update_prestige_action_row(total_reward)

	for talent_index in range(talent_rows.size()):
		_update_talent_row(state, talent_index, talent_rows[talent_index])


func _create_image_card_button(button_name: String) -> Dictionary:
	var button := Button.new()
	button.name = button_name
	button.custom_minimum_size = TALENT_BUTTON_SIZE
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


func play_prestige_talent_purchase_feedback(talent_index: int) -> void:
	if talent_index < talent_rows.size():
		play_card_button_active_feedback(talent_rows[talent_index])


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
	slot.custom_minimum_size = TALENT_BUTTON_SLOT_SIZE
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	button.custom_minimum_size = TALENT_BUTTON_SIZE
	button.anchor_left = 0.0
	button.anchor_top = 0.0
	button.anchor_right = 1.0
	button.anchor_bottom = 0.0
	button.offset_left = 0.0
	button.offset_top = CARD_BUTTON_Y
	button.offset_right = 0.0
	button.offset_bottom = CARD_BUTTON_Y + int(TALENT_BUTTON_SIZE.y)

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


func _create_prestige_action_row() -> Dictionary:
	var row: Control = _create_card_row("PrestigeActionRow")
	action_container.add_child(row)

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

	var image_holder = ImageSlotClass.new()
	image_holder.name = "ImageHolder"
	image_holder.fallback_color = Color.WHITE
	image_holder.show_fallback_behind_texture = false
	image_holder.custom_minimum_size = TALENT_IMAGE_SIZE
	content.add_child(image_holder)
	image_holder.set_asset_key("prestige.action")

	var right_content := Control.new()
	right_content.name = "RightContent"
	right_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_content.custom_minimum_size = Vector2(0, CARD_INNER_HEIGHT)
	right_content.clip_contents = true
	content.add_child(right_content)

	var prestige_title_label := Label.new()
	prestige_title_label.name = "PrestigeTitleLabel"
	prestige_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prestige_title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	prestige_title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	UiFontConfig.apply_label_font_size(prestige_title_label, UiFontConfig.PRESTIGE_ACTION_TITLE_FONT_SIZE)
	_place_card_row(prestige_title_label, 0, CARD_ROW_1_HEIGHT)
	right_content.add_child(prestige_title_label)

	var prestige_reward_label := Label.new()
	prestige_reward_label.name = "PrestigeRewardLabel"
	prestige_reward_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prestige_reward_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	UiFontConfig.apply_label_font_size(prestige_reward_label, UiFontConfig.PRESTIGE_ACTION_REWARD_FONT_SIZE)
	_place_card_row(prestige_reward_label, CARD_ROW_1_HEIGHT + CARD_ROW_GAP, CARD_ROW_2_HEIGHT)
	right_content.add_child(prestige_reward_label)

	var reset_progress_label := Label.new()
	reset_progress_label.name = "ResetProgressLabel"
	reset_progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reset_progress_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	UiFontConfig.apply_label_font_size(reset_progress_label, UiFontConfig.PRESTIGE_ACTION_RESET_FONT_SIZE)
	_place_card_row(reset_progress_label, CARD_ROW_1_HEIGHT + CARD_ROW_2_HEIGHT + CARD_ROW_GAP * 2, CARD_ROW_3_HEIGHT)
	right_content.add_child(reset_progress_label)

	var get_points_label := Label.new()
	get_points_label.name = "GetPointsLabel"
	get_points_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	get_points_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	UiFontConfig.apply_label_font_size(get_points_label, UiFontConfig.PRESTIGE_ACTION_GET_POINTS_FONT_SIZE)
	_place_card_row(get_points_label, CARD_ROW_1_HEIGHT + CARD_ROW_2_HEIGHT + CARD_ROW_3_HEIGHT + CARD_ROW_GAP * 3, CARD_ROW_4_HEIGHT)
	right_content.add_child(get_points_label)

	var btn_dict := _create_image_card_button("PrestigeButton")
	var button: Button = btn_dict["button"]
	var button_label: Label = btn_dict["button_label"]
	var button_image_holder = btn_dict["button_image_holder"]
	button.pressed.connect(_on_prestige_button_pressed)
	UiFontConfig.apply_label_font_size(button_label, UiFontConfig.PRESTIGE_ACTION_BUTTON_FONT_SIZE)
	var button_slot := _create_card_button_slot(button)
	content.add_child(button_slot)

	return {
		"prestige_title_label": prestige_title_label,
		"prestige_reward_label": prestige_reward_label,
		"reset_progress_label": reset_progress_label,
		"get_points_label": get_points_label,
		"button": button,
		"button_label": button_label,
		"button_image_holder": button_image_holder,
	}


func _update_prestige_action_row(total_reward: int) -> void:
	var prestige_title_label: Label = prestige_action_row["prestige_title_label"]
	var prestige_reward_label: Label = prestige_action_row["prestige_reward_label"]
	var reset_progress_label: Label = prestige_action_row["reset_progress_label"]
	var get_points_label: Label = prestige_action_row["get_points_label"]
	var button_label: Label = prestige_action_row["button_label"]

	prestige_title_label.text = LocalizationManager.tr_key("prestige.action_card.title")
	prestige_reward_label.text = LocalizationManager.format_key("prestige.action_card.reward", {
		"points": NumberFormatter.compact(total_reward),
	})
	reset_progress_label.text = LocalizationManager.tr_key("prestige.action_card.reset_progress")
	get_points_label.text = LocalizationManager.tr_key("prestige.action_card.get_points")

	button_label.text = LocalizationManager.tr_key("prestige.action")
	_set_card_button_state(prestige_action_row, total_reward > 0)


func _ensure_talent_rows(_state: ClickerState) -> void:
	while talent_rows.size() < PrestigeConfig.TALENT_NAMES.size():
		var talent_index: int = talent_rows.size()
		var talent_name: String = PrestigeConfig.TALENT_NAMES[talent_index]
		var talent_id: String = talent_name.to_lower().replace(" ", "_")
		talent_rows.append(_create_talent_row(talent_index, talent_id))


func _create_talent_row(talent_index: int, talent_id: String) -> Dictionary:
	var row: Control = _create_card_row("Talent%dRow" % (talent_index + 1))
	talents_container.add_child(row)

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

	var image_holder = ImageSlotClass.new()
	image_holder.name = "ImageHolder"
	image_holder.fallback_color = Color.WHITE
	image_holder.show_fallback_behind_texture = false
	image_holder.custom_minimum_size = TALENT_IMAGE_SIZE
	content.add_child(image_holder)
	image_holder.set_asset_key(GameAssetCatalog.prestige_talent_icon_key(talent_id))

	var right_content := Control.new()
	right_content.name = "RightContent"
	right_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_content.custom_minimum_size = Vector2(0, CARD_INNER_HEIGHT)
	right_content.clip_contents = true
	content.add_child(right_content)

	var talent_name_label := Label.new()
	talent_name_label.name = "TalentNameLabel"
	talent_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	talent_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	talent_name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	UiFontConfig.apply_label_font_size(talent_name_label, UiFontConfig.PRESTIGE_NAME_FONT_SIZE)
	_place_card_row(talent_name_label, 0, CARD_ROW_1_HEIGHT)
	right_content.add_child(talent_name_label)

	var talent_count_label := Label.new()
	talent_count_label.name = "TalentCountLabel"
	talent_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	talent_count_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	UiFontConfig.apply_label_font_size(talent_count_label, UiFontConfig.PRESTIGE_COUNT_FONT_SIZE)
	_place_card_row(talent_count_label, CARD_ROW_1_HEIGHT + CARD_ROW_GAP, CARD_ROW_2_HEIGHT)
	right_content.add_child(talent_count_label)

	var purchase_bonus_gain_label := Label.new()
	purchase_bonus_gain_label.name = "PurchaseBonusGainLabel"
	purchase_bonus_gain_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	purchase_bonus_gain_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	UiFontConfig.apply_label_font_size(purchase_bonus_gain_label, UiFontConfig.PRESTIGE_PURCHASE_GAIN_FONT_SIZE)
	_place_card_row(purchase_bonus_gain_label, CARD_ROW_1_HEIGHT + CARD_ROW_2_HEIGHT + CARD_ROW_GAP * 2, CARD_ROW_3_HEIGHT)
	right_content.add_child(purchase_bonus_gain_label)

	var total_bonus_label := Label.new()
	total_bonus_label.name = "TotalBonusLabel"
	total_bonus_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	total_bonus_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	UiFontConfig.apply_label_font_size(total_bonus_label, UiFontConfig.PRESTIGE_TOTAL_BONUS_FONT_SIZE)
	_place_card_row(total_bonus_label, CARD_ROW_1_HEIGHT + CARD_ROW_2_HEIGHT + CARD_ROW_3_HEIGHT + CARD_ROW_GAP * 3, CARD_ROW_4_HEIGHT)
	right_content.add_child(total_bonus_label)

	var empty_row_label := Label.new()
	empty_row_label.name = "EmptyRowLabel"
	empty_row_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty_row_label.text = " "
	UiFontConfig.apply_label_font_size(empty_row_label, UiFontConfig.PRESTIGE_EMPTY_ROW_FONT_SIZE)
	_place_card_row(empty_row_label, CARD_ROW_1_HEIGHT + CARD_ROW_2_HEIGHT + CARD_ROW_3_HEIGHT + CARD_ROW_4_HEIGHT + CARD_ROW_GAP * 4, CARD_ROW_5_HEIGHT)
	right_content.add_child(empty_row_label)

	var btn_dict := _create_image_card_button("UpgradeButton")
	var button: Button = btn_dict["button"]
	var button_label: Label = btn_dict["button_label"]
	var button_image_holder = btn_dict["button_image_holder"]
	button.pressed.connect(func() -> void: prestige_talent_purchase_requested.emit(talent_index, selected_buy_mode))
	UiFontConfig.apply_label_font_size(button_label, UiFontConfig.PRESTIGE_BUTTON_FONT_SIZE)
	var button_slot := _create_card_button_slot(button)
	content.add_child(button_slot)

	return {
		"talent_name_label": talent_name_label,
		"talent_count_label": talent_count_label,
		"purchase_bonus_gain_label": purchase_bonus_gain_label,
		"total_bonus_label": total_bonus_label,
		"empty_row_label": empty_row_label,
		"button": button,
		"button_label": button_label,
		"button_image_holder": button_image_holder,
	}


func _on_prestige_button_pressed() -> void:
	prestige_requested.emit()


func _update_talent_row(state: ClickerState, talent_index: int, row: Dictionary) -> void:
	var talent_name_label: Label = row["talent_name_label"]
	var talent_count_label: Label = row["talent_count_label"]
	var purchase_bonus_gain_label: Label = row["purchase_bonus_gain_label"]
	var total_bonus_label: Label = row["total_bonus_label"]

	var level: int = state.prestige_talent_levels[talent_index]
	var talent_name: String = LocalizationManager.tr_key(PrestigeConfig.get_name_key(talent_index))

	talent_name_label.text = LocalizationManager.format_key("prestige.card.name", {"name": talent_name})

	talent_count_label.text = LocalizationManager.format_key("prestige.card.count", {"count": level})

	purchase_bonus_gain_label.text = ClickerStatePresentation.get_prestige_talent_purchase_bonus_gain_text(state, talent_index, selected_buy_mode)

	total_bonus_label.text = ClickerStatePresentation.get_prestige_talent_total_bonus_text(state, talent_index)

	var bulk_count: int = state.get_prestige_talent_bulk_display_count(talent_index, selected_buy_mode)
	var bulk_cost: int = state.get_prestige_talent_bulk_display_cost(talent_index, selected_buy_mode)
	var can_afford: bool = state.get_prestige_talent_bulk_count(talent_index, selected_buy_mode) > 0
	row["button_label"].text = LocalizationManager.format_key("prestige.talent_upgrade_bulk", {
		"count": bulk_count,
		"cost": NumberFormatter.compact(bulk_cost),
	})
	_set_card_button_state(row, can_afford)
