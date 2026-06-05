class_name PartnerPanel
extends VBoxContainer

signal partner_purchase_requested(partner_index: int, mode: String)
signal skill_popup_requested(skill_id: String, anchor_global_position: Vector2)

const BUY_MODES: Array[String] = ["x1", "x10", "x100", "max"]
const PARTNER_IMAGE_SIZE: Vector2 = Vector2(136, 136)
const SKILL_ICON_SIZE: Vector2 = Vector2(32, 32)
const SKILL_COUNT: int = 5
const SKILL_ICON_COLORS: Dictionary = {
	"locked": Color(0.32, 0.32, 0.34, 1.0),
	"available": Color(0.18, 0.44, 0.95, 1.0),
	"purchased": Color.WHITE,
}

const ImageSlotClass = preload("res://scripts/ui/ImageSlot.gd")

var selected_buy_mode: String = "x1"
var current_state: ClickerState = null
var partner_rows: Array[Dictionary] = []

@onready var rows_container: VBoxContainer = $RowsContainer


func update_view(state: ClickerState) -> void:
	current_state = state
	state.refresh_partner_visibility_unlocks()
	_ensure_partner_rows(state)

	for partner_index in range(partner_rows.size()):
		var panel_row: PanelContainer = partner_rows[partner_index]["row"]
		panel_row.visible = _should_show_partner_row(state, partner_index)
		_update_partner_row(state, partner_index, partner_rows[partner_index])


func _ensure_partner_rows(_state: ClickerState) -> void:
	while partner_rows.size() < PartnerConfig.PARTNER_NAMES.size():
		var partner_index: int = partner_rows.size()
		partner_rows.append(_create_partner_row(partner_index))


func _create_partner_row(partner_index: int) -> Dictionary:
	var row := PanelContainer.new()
	row.name = "Partner%dRow" % (partner_index + 1)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_stylebox_override("panel", _create_row_stylebox())
	rows_container.add_child(row)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	row.add_child(margin)

	var content := HBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)

	var image_holder = ImageSlotClass.new()
	image_holder.name = "ImageHolder"
	image_holder.fallback_color = Color.WHITE
	image_holder.show_fallback_behind_texture = false
	image_holder.custom_minimum_size = PARTNER_IMAGE_SIZE
	image_holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	content.add_child(image_holder)
	image_holder.set_asset_key(GameAssetCatalog.partner_icon_key(partner_index))

	var right_content := VBoxContainer.new()
	right_content.name = "RightContent"
	right_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_content.add_theme_constant_override("separation", 4)
	content.add_child(right_content)

	var partner_name_label := Label.new()
	partner_name_label.name = "PartnerNameLabel"
	partner_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	partner_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	right_content.add_child(partner_name_label)

	var purchase_gain_label := Label.new()
	purchase_gain_label.name = "PurchaseGainLabel"
	purchase_gain_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	purchase_gain_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	right_content.add_child(purchase_gain_label)

	var total_dps_label := Label.new()
	total_dps_label.name = "TotalDpsLabel"
	total_dps_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	total_dps_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	right_content.add_child(total_dps_label)

	var milestone_label := Label.new()
	milestone_label.name = "MilestoneLabel"
	milestone_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	milestone_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	right_content.add_child(milestone_label)

	var skill_row := HBoxContainer.new()
	skill_row.name = "SkillRow"
	skill_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill_row.add_theme_constant_override("separation", 6)
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
		var captured_index: int = i
		skill_button.pressed.connect(
			func() -> void: _on_skill_button_pressed(partner_index, captured_index, skill_button)
		)
		skill_row.add_child(skill_button)

		var skill_image_holder = ImageSlotClass.new()
		skill_image_holder.name = "ImageHolder"
		skill_image_holder.fallback_color = SKILL_ICON_COLORS["locked"]
		skill_image_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		skill_image_holder.set_anchors_preset(Control.PRESET_FULL_RECT)
		skill_button.add_child(skill_image_holder)
		skill_image_holder.set_asset_key(GameAssetCatalog.partner_skill_key(partner_index, i + 1), SKILL_ICON_COLORS["locked"])

		skill_buttons.append(skill_button)
		skill_image_holders.append(skill_image_holder)

	var skill_spacer := Control.new()
	skill_spacer.name = "SkillSpacer"
	skill_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill_row.add_child(skill_spacer)

	var button := Button.new()
	button.name = "HireButton"
	button.custom_minimum_size = Vector2(210, 136)
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	button.pressed.connect(func() -> void: partner_purchase_requested.emit(partner_index, selected_buy_mode))
	content.add_child(button)

	UiFontConfig.apply_label_font_size(partner_name_label, UiFontConfig.PARTNER_NAME_FONT_SIZE)
	UiFontConfig.apply_label_font_size(purchase_gain_label, UiFontConfig.PARTNER_COUNT_GAIN_FONT_SIZE)
	UiFontConfig.apply_label_font_size(total_dps_label, UiFontConfig.PARTNER_TOTAL_DPS_FONT_SIZE)
	UiFontConfig.apply_label_font_size(milestone_label, UiFontConfig.PARTNER_MILESTONE_FONT_SIZE)
	UiFontConfig.apply_button_font_size(button, UiFontConfig.PARTNER_BUTTON_FONT_SIZE)

	return {
		"row": row,
		"partner_name_label": partner_name_label,
		"purchase_gain_label": purchase_gain_label,
		"total_dps_label": total_dps_label,
		"milestone_label": milestone_label,
		"skill_buttons": skill_buttons,
		"skill_image_holders": skill_image_holders,
		"button": button,
	}


func _update_partner_row(state: ClickerState, partner_index: int, row: Dictionary) -> void:
	var partner_name_label: Label = row["partner_name_label"]
	var purchase_gain_label: Label = row["purchase_gain_label"]
	var total_dps_label: Label = row["total_dps_label"]
	var milestone_label: Label = row["milestone_label"]
	var skill_buttons: Array = row["skill_buttons"]
	var skill_image_holders: Array = row["skill_image_holders"]
	var button: Button = row["button"]
	var partner_name: String = LocalizationManager.tr_key(PartnerConfig.get_name_key(partner_index))
	var partner_count: int = state.partner_counts[partner_index]
	var tier_total_dps: int = state.get_partner_tier_total_dps(partner_index)
	var dps_gain: int = state.get_partner_bulk_dps_gain(partner_index, selected_buy_mode)
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
			skill_image_holder.set_fallback_color(SKILL_ICON_COLORS["locked"])
		else:
			skill_button.disabled = false
			var skill_id: String = String(skills[i].get("id", ""))
			var skill_state: String = state.get_partner_skill_state(skill_id)
			skill_image_holder.set_fallback_color(SKILL_ICON_COLORS.get(skill_state, SKILL_ICON_COLORS["locked"]))

	var bulk_count: int = state.get_partner_bulk_display_count(partner_index, selected_buy_mode)
	var bulk_cost: int = state.get_partner_bulk_display_cost(partner_index, selected_buy_mode)
	var can_afford: bool = state.can_afford_partner_bulk(partner_index, selected_buy_mode)
	button.disabled = not can_afford
	button.text = LocalizationManager.format_key("partner.hire_button", {
		"count": bulk_count,
		"cost": NumberFormatter.compact(bulk_cost),
	})


func set_buy_mode(mode: String) -> void:
	if not BUY_MODES.has(mode):
		return
	selected_buy_mode = mode


func _should_show_partner_row(state: ClickerState, partner_index: int) -> bool:
	return state.is_partner_visible(partner_index)


func _create_row_stylebox() -> StyleBoxFlat:
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = Color(0.12, 0.125, 0.145, 1.0)
	stylebox.border_width_left = 1
	stylebox.border_width_top = 1
	stylebox.border_width_right = 1
	stylebox.border_width_bottom = 1
	stylebox.border_color = Color(0.22, 0.23, 0.26, 1.0)
	stylebox.corner_radius_top_left = 6
	stylebox.corner_radius_top_right = 6
	stylebox.corner_radius_bottom_left = 6
	stylebox.corner_radius_bottom_right = 6
	return stylebox


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
