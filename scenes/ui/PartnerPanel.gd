class_name PartnerPanel
extends VBoxContainer

signal partner_purchase_requested(partner_index: int, mode: String)

const BUY_MODES: Array[String] = ["x1", "x10", "x100", "max"]

var selected_buy_mode: String = "x1"
var current_state: ClickerState = null
var partner_rows: Array[Dictionary] = []

@onready var rows_container: VBoxContainer = $RowsContainer


func update_view(state: ClickerState) -> void:
	current_state = state
	_ensure_partner_rows(state)

	for partner_index in range(partner_rows.size()):
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
	image_holder.custom_minimum_size = Vector2(72, 72)
	content.add_child(image_holder)

	var info_container := VBoxContainer.new()
	info_container.name = "InfoContainer"
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_container.add_theme_constant_override("separation", 4)
	content.add_child(info_container)

	var name_count_label := Label.new()
	name_count_label.name = "NameCountLabel"
	name_count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_count_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	info_container.add_child(name_count_label)

	var effect_label := Label.new()
	effect_label.name = "EffectLabel"
	effect_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_container.add_child(effect_label)

	var button := Button.new()
	button.name = "HireButton"
	button.custom_minimum_size = Vector2(220, 64)
	button.pressed.connect(func() -> void: partner_purchase_requested.emit(partner_index, selected_buy_mode))
	content.add_child(button)

	return {
		"name_count_label": name_count_label,
		"effect_label": effect_label,
		"button": button,
	}


func _update_partner_row(state: ClickerState, partner_index: int, row: Dictionary) -> void:
	var name_count_label: Label = row["name_count_label"]
	var effect_label: Label = row["effect_label"]
	var button: Button = row["button"]
	var partner_name: String = state.partner_names[partner_index]
	var partner_count: int = state.partner_counts[partner_index]
	var next_milestone: int = state.get_next_milestone(partner_count)
	name_count_label.text = "%s | %d" % [partner_name, partner_count]
	if next_milestone > 0:
		effect_label.text = "DPS %d | Next x2 at %d" % [
			state.get_partner_tier_total_dps(partner_index),
			next_milestone,
		]
	else:
		effect_label.text = "DPS %d | Max milestones" % state.get_partner_tier_total_dps(partner_index)

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
