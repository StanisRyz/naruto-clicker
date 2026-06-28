class_name PartnerPanel
extends VBoxContainer

signal partner_purchase_requested(partner_index: int, mode: String)
signal skill_popup_requested(skill_id: String, anchor_global_position: Vector2)

const BUY_MODES: Array[String] = ["x1", "x10", "x100", "max"]
const PARTNER_IMAGE_SIZE: Vector2 = Vector2(136, 136)
const SKILL_ICON_SIZE: Vector2 = Vector2(32, 32)
const CARD_BUTTON_SLOT_SIZE: Vector2 = Vector2(210, 136)
const CARD_BUTTON_SIZE: Vector2 = Vector2(210, 72)
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
const SKILL_COUNT: int = 5
const SKILL_ICON_COLORS: Dictionary = {
	"locked": Color(0.35, 0.35, 0.35, 1.0),
	"available": Color(0.65, 1.0, 0.65, 1.0),
	"purchased": Color.WHITE,
}

const ImageSlotClass = preload("res://scripts/ui/ImageSlot.gd")

var selected_buy_mode: String = "x1"
var current_state: ClickerState = null
var partner_rows: Array[Dictionary] = []

@onready var rows_container: VBoxContainer = $RowsContainer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	rows_container.mouse_filter = Control.MOUSE_FILTER_PASS


func update_view(state: ClickerState) -> void:
	current_state = state
	state.refresh_partner_visibility_unlocks()
	_ensure_partner_rows(state)

	for partner_index in range(partner_rows.size()):
		var panel_row: Control = partner_rows[partner_index]["row"]
		var row_visible: bool = _should_show_partner_row(state, partner_index)
		panel_row.visible = row_visible
		if row_visible:
			_update_partner_row(state, partner_index, partner_rows[partner_index])


func _ensure_partner_rows(_state: ClickerState) -> void:
	while partner_rows.size() < PartnerConfig.PARTNER_NAMES.size():
		var partner_index: int = partner_rows.size()
		partner_rows.append(_create_partner_row(partner_index))


func _create_image_card_button(button_name: String) -> Dictionary:
	var button := Button.new()
	button.name = button_name
	button.custom_minimum_size = CARD_BUTTON_SIZE
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


func play_partner_purchase_feedback(partner_index: int) -> void:
	if partner_index < partner_rows.size():
		play_card_button_active_feedback(partner_rows[partner_index])


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
	slot.custom_minimum_size = CARD_BUTTON_SLOT_SIZE
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slot.mouse_filter = Control.MOUSE_FILTER_PASS

	button.custom_minimum_size = CARD_BUTTON_SIZE
	button.anchor_left = 0.0
	button.anchor_top = 0.0
	button.anchor_right = 1.0
	button.anchor_bottom = 0.0
	button.offset_left = 0.0
	button.offset_top = CARD_BUTTON_Y
	button.offset_right = 0.0
	button.offset_bottom = CARD_BUTTON_Y + int(CARD_BUTTON_SIZE.y)

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


func _create_partner_row(partner_index: int) -> Dictionary:
	var row: Control = _create_card_row("Partner%dRow" % (partner_index + 1))
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
	image_holder.custom_minimum_size = PARTNER_IMAGE_SIZE
	image_holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	image_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(image_holder)
	image_holder.set_asset_key(GameAssetCatalog.partner_icon_key(partner_index))

	var right_content := Control.new()
	right_content.name = "RightContent"
	right_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_content.custom_minimum_size = Vector2(0, CARD_INNER_HEIGHT)
	right_content.clip_contents = true
	right_content.mouse_filter = Control.MOUSE_FILTER_PASS
	content.add_child(right_content)

	var partner_name_label := Label.new()
	partner_name_label.name = "PartnerNameLabel"
	partner_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	partner_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	partner_name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	partner_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_card_row(partner_name_label, 0, CARD_ROW_1_HEIGHT)
	right_content.add_child(partner_name_label)

	var purchase_gain_label := Label.new()
	purchase_gain_label.name = "PurchaseGainLabel"
	purchase_gain_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	purchase_gain_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	purchase_gain_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	purchase_gain_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_card_row(purchase_gain_label, CARD_ROW_1_HEIGHT + CARD_ROW_GAP, CARD_ROW_2_HEIGHT)
	right_content.add_child(purchase_gain_label)

	var total_dps_label := Label.new()
	total_dps_label.name = "TotalDpsLabel"
	total_dps_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	total_dps_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	total_dps_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	total_dps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_card_row(total_dps_label, CARD_ROW_1_HEIGHT + CARD_ROW_2_HEIGHT + CARD_ROW_GAP * 2, CARD_ROW_3_HEIGHT)
	right_content.add_child(total_dps_label)

	var milestone_label := Label.new()
	milestone_label.name = "MilestoneLabel"
	milestone_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	milestone_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	milestone_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	milestone_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_card_row(milestone_label, CARD_ROW_1_HEIGHT + CARD_ROW_2_HEIGHT + CARD_ROW_3_HEIGHT + CARD_ROW_GAP * 3, CARD_ROW_4_HEIGHT)
	right_content.add_child(milestone_label)

	var skill_row := HBoxContainer.new()
	skill_row.name = "SkillRow"
	skill_row.add_theme_constant_override("separation", 6)
	skill_row.mouse_filter = Control.MOUSE_FILTER_PASS
	_place_card_row(skill_row, CARD_ROW_1_HEIGHT + CARD_ROW_2_HEIGHT + CARD_ROW_3_HEIGHT + CARD_ROW_4_HEIGHT + CARD_ROW_GAP * 4, CARD_ROW_5_HEIGHT)
	right_content.add_child(skill_row)

	var skill_buttons: Array[Button] = []
	var skill_image_holders: Array = []

	for i in range(SKILL_COUNT):
		var skill_button := Button.new()
		skill_button.name = "SkillButton%d" % (i + 1)
		skill_button.custom_minimum_size = SKILL_ICON_SIZE
		skill_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		skill_button.focus_mode = Control.FOCUS_NONE
		skill_button.text = ""
		ButtonVisualUtils.clear_image_button_styles(skill_button)
		var captured_index: int = i
		skill_button.pressed.connect(
			func() -> void: _on_skill_button_pressed(partner_index, captured_index, skill_button)
		)
		skill_row.add_child(skill_button)

		var skill_image_holder = ImageSlotClass.new()
		skill_image_holder.name = "ImageHolder"
		skill_image_holder.fallback_color = SKILL_ICON_COLORS["locked"]
		skill_image_holder.show_fallback_behind_texture = false
		skill_image_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		skill_image_holder.set_anchors_preset(Control.PRESET_FULL_RECT)
		skill_button.add_child(skill_image_holder)
		skill_image_holder.set_asset_key(GameAssetCatalog.partner_skill_key(partner_index, i + 1), SKILL_ICON_COLORS["locked"])

		skill_buttons.append(skill_button)
		skill_image_holders.append(skill_image_holder)

	var skill_spacer := Control.new()
	skill_spacer.name = "SkillSpacer"
	skill_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill_spacer.mouse_filter = Control.MOUSE_FILTER_PASS
	skill_row.add_child(skill_spacer)

	var btn_dict := _create_image_card_button("HireButton")
	var button: Button = btn_dict["button"]
	var button_label: Label = btn_dict["button_label"]
	var button_image_holder = btn_dict["button_image_holder"]
	button.pressed.connect(func() -> void: partner_purchase_requested.emit(partner_index, selected_buy_mode))
	var button_slot := _create_card_button_slot(button)
	content.add_child(button_slot)

	UiFontConfig.apply_label_font_size(partner_name_label, UiFontConfig.PARTNER_NAME_FONT_SIZE)
	UiFontConfig.apply_label_font_size(purchase_gain_label, UiFontConfig.PARTNER_COUNT_GAIN_FONT_SIZE)
	UiFontConfig.apply_label_font_size(total_dps_label, UiFontConfig.PARTNER_TOTAL_DPS_FONT_SIZE)
	UiFontConfig.apply_label_font_size(milestone_label, UiFontConfig.PARTNER_MILESTONE_FONT_SIZE)
	UiFontConfig.apply_label_font_size(button_label, UiFontConfig.PARTNER_BUTTON_FONT_SIZE)

	return {
		"row": row,
		"partner_name_label": partner_name_label,
		"purchase_gain_label": purchase_gain_label,
		"total_dps_label": total_dps_label,
		"milestone_label": milestone_label,
		"skill_buttons": skill_buttons,
		"skill_image_holders": skill_image_holders,
		"button": button,
		"button_label": button_label,
		"button_image_holder": button_image_holder,
	}


func _apply_skill_icon_visual(image_holder, skill_state: String) -> void:
	var tint: Color = SKILL_ICON_COLORS.get(skill_state, SKILL_ICON_COLORS["locked"])
	image_holder.modulate = tint
	image_holder.set_fallback_color(tint)


func _update_partner_row(state: ClickerState, partner_index: int, row: Dictionary) -> void:
	var partner_name_label: Label = row["partner_name_label"]
	var purchase_gain_label: Label = row["purchase_gain_label"]
	var total_dps_label: Label = row["total_dps_label"]
	var milestone_label: Label = row["milestone_label"]
	var skill_buttons: Array = row["skill_buttons"]
	var skill_image_holders: Array = row["skill_image_holders"]
	var partner_name: String = LocalizationManager.tr_key(PartnerConfig.get_name_key(partner_index))
	var partner_count: int = state.partner_counts[partner_index]
	var tier_total_dps: BigNumber = state.get_partner_tier_total_dps(partner_index)
	var preview: Dictionary = state.get_partner_bulk_preview(partner_index, selected_buy_mode)
	var dps_gain: BigNumber = preview["dps_gain"]
	var next_milestone: int = state.get_next_milestone(partner_count)
	partner_name_label.text = LocalizationManager.format_key("partner.card.name", {
		"name": partner_name,
	})
	purchase_gain_label.text = LocalizationManager.format_key("partner.card.count_gain", {
		"count": partner_count,
		"gain": NumberFormatter.compact(dps_gain),
	})
	total_dps_label.text = LocalizationManager.format_key("partner.card.total_dps", {
		"total": NumberFormatter.compact(tier_total_dps),
	})
	if next_milestone > 0:
		milestone_label.text = LocalizationManager.format_key("partner.card.milestone_next", {
			"milestone": next_milestone,
		})
	else:
		milestone_label.text = LocalizationManager.tr_key("partner.card.milestone_max")

	var skills: Array[Dictionary] = state.get_partner_skills_for_partner(partner_index)
	for i in range(skill_buttons.size()):
		var skill_button: Button = skill_buttons[i]
		var skill_image_holder = skill_image_holders[i]
		if i >= skills.size():
			skill_button.disabled = true
			_apply_skill_icon_visual(skill_image_holder, "locked")
		else:
			skill_button.disabled = false
			var skill_id: String = String(skills[i].get("id", ""))
			var skill_state: String = state.get_partner_skill_state(skill_id)
			_apply_skill_icon_visual(skill_image_holder, skill_state)

	var bulk_count: int = preview["count"]
	var bulk_cost: BigNumber = preview["cost"]
	var can_afford: bool = preview["can_afford"]
	row["button_label"].text = LocalizationManager.format_key("partner.hire_button", {
		"count": bulk_count,
		"cost": NumberFormatter.compact(bulk_cost),
	})
	_set_card_button_state(row, can_afford)


func set_buy_mode(mode: String) -> void:
	if not BUY_MODES.has(mode):
		return
	selected_buy_mode = mode


func _should_show_partner_row(state: ClickerState, partner_index: int) -> bool:
	return state.is_partner_visible(partner_index)


func _on_skill_button_pressed(partner_index: int, skill_index: int, skill_button: Button) -> void:
	if current_state == null:
		return

	var skills: Array[Dictionary] = current_state.get_partner_skills_for_partner(partner_index)
	if skill_index >= skills.size():
		return

	var skill_id: String = String(skills[skill_index].get("id", ""))
	if skill_id == "":
		return

	skill_popup_requested.emit(skill_id, skill_button.global_position)
