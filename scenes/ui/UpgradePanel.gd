class_name UpgradePanel
extends Control

signal character_level_upgrade_requested(mode: String)
signal autoclick_purchase_requested
signal gold_bonus_purchase_requested
signal focus_burst_purchase_requested
signal rally_purchase_requested

const ABILITIES: Array[Dictionary] = [
	{"id": "autoclick", "name": "Autoclick"},
	{"id": "gold_bonus", "name": "Gold Bonus"},
	{"id": "focus_burst", "name": "Focus Burst"},
	{"id": "rally", "name": "Rally"},
]

var ability_rows: Array[Dictionary] = []

@onready var rows_container: VBoxContainer = $VBoxContainer/RowsContainer


func _ready() -> void:
	for ability_index in range(ABILITIES.size()):
		ability_rows.append(_create_ability_row(ability_index))


func update_view(state: ClickerState) -> void:
	for ability_index in range(ability_rows.size()):
		_update_ability_row(state, ability_index, ability_rows[ability_index])


func _create_ability_row(ability_index: int) -> Dictionary:
	var ability: Dictionary = ABILITIES[ability_index]
	var row := PanelContainer.new()
	row.name = "%sRow" % String(ability["name"]).replace(" ", "")
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

	var name_status_label := Label.new()
	name_status_label.name = "NameStatusLabel"
	name_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	info_container.add_child(name_status_label)

	var effect_label := Label.new()
	effect_label.name = "EffectLabel"
	effect_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_container.add_child(effect_label)

	var button := Button.new()
	button.name = "BuyButton"
	button.custom_minimum_size = Vector2(220, 64)
	button.pressed.connect(func() -> void: _emit_ability_purchase(String(ability["id"])))
	content.add_child(button)

	return {
		"name_status_label": name_status_label,
		"effect_label": effect_label,
		"button": button,
	}


func _update_ability_row(state: ClickerState, ability_index: int, row: Dictionary) -> void:
	var ability: Dictionary = ABILITIES[ability_index]
	var ability_id: String = String(ability["id"])
	var ability_name: String = String(ability["name"])
	var name_status_label: Label = row["name_status_label"]
	var effect_label: Label = row["effect_label"]
	var button: Button = row["button"]

	var status: String = _get_ability_status(state, ability_id)
	name_status_label.text = "%s | %s" % [ability_name, status]
	effect_label.text = state.get_ability_description(ability_id)

	if status == "Purchased":
		button.disabled = true
		button.text = "Purchased"
	elif status == "Locked":
		button.disabled = true
		button.text = "Requires Level %d" % _get_ability_unlock_level(state, ability_id)
	else:
		button.disabled = false
		button.text = "Buy - Cost: %d" % _get_ability_cost(state, ability_id)


func _get_ability_status(state: ClickerState, ability_id: String) -> String:
	match ability_id:
		"autoclick":
			if state.autoclick_purchased:
				return "Purchased"
			return "Available" if state.autoclick_unlocked else "Locked"
		"gold_bonus":
			if state.gold_bonus_purchased:
				return "Purchased"
			return "Available" if state.gold_bonus_unlocked else "Locked"
		"focus_burst":
			if state.focus_burst_purchased:
				return "Purchased"
			return "Available" if state.focus_burst_unlocked else "Locked"
		"rally":
			if state.rally_purchased:
				return "Purchased"
			return "Available" if state.rally_unlocked else "Locked"

	return "Locked"


func _get_ability_unlock_level(state: ClickerState, ability_id: String) -> int:
	match ability_id:
		"autoclick":
			return state.autoclick_unlock_level
		"gold_bonus":
			return state.gold_bonus_unlock_level
		"focus_burst":
			return state.focus_burst_unlock_level
		"rally":
			return state.rally_unlock_level

	return 0


func _get_ability_cost(state: ClickerState, ability_id: String) -> int:
	match ability_id:
		"autoclick":
			return state.autoclick_purchase_cost
		"gold_bonus":
			return state.gold_bonus_purchase_cost
		"focus_burst":
			return state.focus_burst_purchase_cost
		"rally":
			return state.rally_purchase_cost

	return 0


func _emit_ability_purchase(ability_id: String) -> void:
	match ability_id:
		"autoclick":
			autoclick_purchase_requested.emit()
		"gold_bonus":
			gold_bonus_purchase_requested.emit()
		"focus_burst":
			focus_burst_purchase_requested.emit()
		"rally":
			rally_purchase_requested.emit()


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
