class_name PartnerPanel
extends VBoxContainer

signal partner_purchase_requested(partner_index: int, mode: String)
signal skill_popup_requested(skill_id: String, anchor_global_position: Vector2)

const BUY_MODES: Array[String] = ["x1", "x10", "x100", "max"]
const PARTNER_IMAGE_SIZE: Vector2 = Vector2(104, 104)
const SKILL_ICON_SIZE: Vector2 = Vector2(36, 36)
const SKILL_ICON_COLORS: Dictionary = {
	"locked": Color(0.32, 0.32, 0.34, 1.0),
	"available": Color(0.18, 0.44, 0.95, 1.0),
	"purchased": Color.WHITE,
}

var selected_buy_mode: String = "x1"
var current_state: ClickerState = null
var partner_rows: Array[Dictionary] = []

@onready var rows_container: VBoxContainer = $RowsContainer


func update_view(state: ClickerState) -> void:
	current_state = state
	_ensure_partner_rows(state)

	for partner_index in range(partner_rows.size()):
		var panel_row: PanelContainer = partner_rows[partner_index]["row"]
		panel_row.visible = _should_show_partner_row(state, partner_index)
		_update_partner_row(state, partner_index, partner_rows[partner_index])


func _ensure_partner_rows(state: ClickerState) -> void:
	while partner_rows.size() < state.partner_names.size():
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

	var image_holder := ColorRect.new()
	image_holder.name = "ImageHolder"
	image_holder.color = Color.WHITE
	image_holder.custom_minimum_size = PARTNER_IMAGE_SIZE
	image_holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	content.add_child(image_holder)

	var right_content := VBoxContainer.new()
	right_content.name = "RightContent"
	right_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_content.add_theme_constant_override("separation", 6)
	content.add_child(right_content)

	var name_count_label := Label.new()
	name_count_label.name = "NameCountLabel"
	name_count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_count_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	right_content.add_child(name_count_label)

	var effect_label := Label.new()
	effect_label.name = "EffectLabel"
	effect_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right_content.add_child(effect_label)

	var skill_row := HBoxContainer.new()
	skill_row.name = "SkillRow"
	skill_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill_row.add_theme_constant_override("separation", 10)
	right_content.add_child(skill_row)

	var skill_button := Button.new()
	skill_button.name = "SkillButton"
	skill_button.custom_minimum_size = SKILL_ICON_SIZE
	skill_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	skill_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	skill_button.focus_mode = Control.FOCUS_NONE
	skill_button.text = ""
	skill_button.pressed.connect(func() -> void: _on_skill_button_pressed(partner_index, skill_button))
	skill_row.add_child(skill_button)

	var skill_image_holder := ColorRect.new()
	skill_image_holder.name = "ImageHolder"
	skill_image_holder.color = SKILL_ICON_COLORS["locked"]
	skill_image_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skill_image_holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	skill_button.add_child(skill_image_holder)

	var skill_spacer := Control.new()
	skill_spacer.name = "SkillSpacer"
	skill_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill_row.add_child(skill_spacer)

	var button := Button.new()
	button.name = "HireButton"
	button.custom_minimum_size = Vector2(210, 48)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(func() -> void: partner_purchase_requested.emit(partner_index, selected_buy_mode))
	skill_row.add_child(button)

	return {
		"row": row,
		"name_count_label": name_count_label,
		"effect_label": effect_label,
		"skill_button": skill_button,
		"skill_image_holder": skill_image_holder,
		"button": button,
	}


func _update_partner_row(state: ClickerState, partner_index: int, row: Dictionary) -> void:
	var name_count_label: Label = row["name_count_label"]
	var effect_label: Label = row["effect_label"]
	var skill_button: Button = row["skill_button"]
	var skill_image_holder: ColorRect = row["skill_image_holder"]
	var button: Button = row["button"]
	var partner_name: String = state.partner_names[partner_index]
	var partner_count: int = state.partner_counts[partner_index]
	var next_milestone: int = state.get_next_milestone(partner_count)
	name_count_label.text = "%s | %d" % [partner_name, partner_count]
	if next_milestone > 0:
		effect_label.text = "+%d DPS | Next x2 at %d" % [
			state.partner_dps_values[partner_index],
			next_milestone,
		]
	else:
		effect_label.text = "+%d DPS | Max milestones" % state.partner_dps_values[partner_index]

	var skill: Dictionary = state.get_partner_skill_for_partner(partner_index)
	var skill_state: String = "locked"
	if skill.is_empty():
		skill_button.disabled = true
	else:
		skill_button.disabled = false
		skill_state = state.get_partner_skill_state(String(skill.get("id", "")))
	skill_image_holder.color = SKILL_ICON_COLORS.get(skill_state, SKILL_ICON_COLORS["locked"])

	if not state.can_buy_partner(partner_index):
		button.disabled = true
		button.text = "Requires Previous Partner"
		return

	var bulk_count: int = state.get_partner_bulk_display_count(partner_index, selected_buy_mode)
	var bulk_cost: int = state.get_partner_bulk_display_cost(partner_index, selected_buy_mode)
	button.disabled = false
	button.text = "Hire x%d - Cost: %d" % [bulk_count, bulk_cost]


func set_buy_mode(mode: String) -> void:
	if not BUY_MODES.has(mode):
		return
	selected_buy_mode = mode


func _should_show_partner_row(state: ClickerState, partner_index: int) -> bool:
	if partner_index == 0:
		return true

	if state.can_buy_partner(partner_index):
		return true

	return partner_index > 0 and state.can_buy_partner(partner_index - 1)


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


func _on_skill_button_pressed(partner_index: int, skill_button: Button) -> void:
	if current_state == null:
		return

	var skill: Dictionary = current_state.get_partner_skill_for_partner(partner_index)
	if skill.is_empty():
		return

	var skill_id: String = String(skill.get("id", ""))
	if skill_id == "":
		return

	skill_popup_requested.emit(skill_id, skill_button.global_position)
