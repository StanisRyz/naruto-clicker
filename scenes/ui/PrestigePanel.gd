class_name PrestigePanel
extends VBoxContainer

signal prestige_requested
signal prestige_talent_purchase_requested(talent_index: int)

const ImageSlotClass = preload("res://scripts/ui/ImageSlot.gd")

var prestige_action_row: Dictionary = {}
var talent_rows: Array[Dictionary] = []

@onready var action_container: VBoxContainer = $ActionContainer
@onready var talents_container: VBoxContainer = $TalentsContainer


func _ready() -> void:
	prestige_action_row = _create_prestige_action_row()


func update_view(state: ClickerState) -> void:
	_ensure_talent_rows(state)
	var total_reward: int = state.get_prestige_reward()

	_update_prestige_action_row(total_reward)

	for talent_index in range(talent_rows.size()):
		_update_talent_row(state, talent_index, talent_rows[talent_index])


func _create_prestige_action_row() -> Dictionary:
	var row := PanelContainer.new()
	row.name = "PrestigeActionRow"
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_stylebox_override("panel", _create_row_stylebox())
	action_container.add_child(row)

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
	image_holder.custom_minimum_size = Vector2(72, 72)
	content.add_child(image_holder)
	image_holder.set_asset_key("prestige.action")

	var info_container := VBoxContainer.new()
	info_container.name = "InfoContainer"
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_container.add_theme_constant_override("separation", 4)
	content.add_child(info_container)

	var name_gain_label := Label.new()
	name_gain_label.name = "NameGainLabel"
	name_gain_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_gain_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	info_container.add_child(name_gain_label)

	var effect_label := Label.new()
	effect_label.name = "EffectLabel"
	effect_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_container.add_child(effect_label)

	var button := Button.new()
	button.name = "PrestigeButton"
	button.custom_minimum_size = Vector2(180, 64)
	button.text = "Prestige"
	button.pressed.connect(_on_prestige_button_pressed)
	content.add_child(button)

	return {
		"name_gain_label": name_gain_label,
		"effect_label": effect_label,
		"button": button,
	}


func _update_prestige_action_row(total_reward: int) -> void:
	var name_gain_label: Label = prestige_action_row["name_gain_label"]
	var effect_label: Label = prestige_action_row["effect_label"]
	var button: Button = prestige_action_row["button"]

	name_gain_label.text = "Prestige | Gain %s" % NumberFormatter.compact(total_reward)
	effect_label.text = "Reset progress for permanent points"
	button.disabled = total_reward <= 0
	button.text = "Prestige"


func _ensure_talent_rows(_state: ClickerState) -> void:
	while talent_rows.size() < PrestigeConfig.TALENT_NAMES.size():
		var talent_index: int = talent_rows.size()
		var talent_name: String = PrestigeConfig.TALENT_NAMES[talent_index]
		var talent_id: String = talent_name.to_lower().replace(" ", "_")
		talent_rows.append(_create_talent_row(talent_index, talent_id))


func _create_talent_row(talent_index: int, talent_id: String) -> Dictionary:
	var row := PanelContainer.new()
	row.name = "Talent%dRow" % (talent_index + 1)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_stylebox_override("panel", _create_row_stylebox())
	talents_container.add_child(row)

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
	image_holder.custom_minimum_size = Vector2(72, 72)
	content.add_child(image_holder)
	image_holder.set_asset_key(GameAssetCatalog.prestige_talent_icon_key(talent_id))

	var info_container := VBoxContainer.new()
	info_container.name = "InfoContainer"
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_container.add_theme_constant_override("separation", 4)
	content.add_child(info_container)

	var name_level_label := Label.new()
	name_level_label.name = "NameLevelLabel"
	name_level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_level_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	info_container.add_child(name_level_label)

	var effect_label := Label.new()
	effect_label.name = "EffectLabel"
	effect_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_container.add_child(effect_label)

	var button := Button.new()
	button.name = "UpgradeButton"
	button.custom_minimum_size = Vector2(180, 64)
	button.pressed.connect(func() -> void: prestige_talent_purchase_requested.emit(talent_index))
	content.add_child(button)

	return {
		"name_level_label": name_level_label,
		"effect_label": effect_label,
		"button": button,
	}


func _on_prestige_button_pressed() -> void:
	prestige_requested.emit()


func _update_talent_row(state: ClickerState, talent_index: int, row: Dictionary) -> void:
	var name_level_label: Label = row["name_level_label"]
	var effect_label: Label = row["effect_label"]
	var button: Button = row["button"]
	var level: int = state.prestige_talent_levels[talent_index]
	var cost: int = state.get_prestige_talent_cost(talent_index)

	name_level_label.text = "%s | Lv %d" % [PrestigeConfig.TALENT_NAMES[talent_index], level]
	effect_label.text = state.get_prestige_talent_description(talent_index)
	button.disabled = state.prestige_points_available < cost
	button.text = "Upgrade - Cost: %s" % NumberFormatter.compact(cost)


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
