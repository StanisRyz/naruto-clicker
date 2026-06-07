class_name PrestigePanel
extends VBoxContainer

signal prestige_requested
signal prestige_talent_purchase_requested(talent_index: int, mode: String)

const BUY_MODES: Array[String] = ["x1", "x10", "x100", "max"]
const TALENT_IMAGE_SIZE: Vector2 = Vector2(136, 136)
const TALENT_BUTTON_SIZE: Vector2 = Vector2(210, 136)

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
	button.pressed.connect(_on_prestige_button_pressed)
	ButtonVisualUtils.disable_focus_artifact(button)
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

	name_gain_label.text = LocalizationManager.format_key("prestige.gain", {
		"points": NumberFormatter.compact(total_reward),
	})
	effect_label.text = LocalizationManager.tr_key("prestige.description")
	button.disabled = total_reward <= 0
	button.text = LocalizationManager.tr_key("prestige.action")


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
	image_holder.custom_minimum_size = TALENT_IMAGE_SIZE
	content.add_child(image_holder)
	image_holder.set_asset_key(GameAssetCatalog.prestige_talent_icon_key(talent_id))

	var right_content := VBoxContainer.new()
	right_content.name = "RightContent"
	right_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_content.add_theme_constant_override("separation", 4)
	content.add_child(right_content)

	var talent_name_label := Label.new()
	talent_name_label.name = "TalentNameLabel"
	talent_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	talent_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	UiFontConfig.apply_label_font_size(talent_name_label, UiFontConfig.PRESTIGE_NAME_FONT_SIZE)
	right_content.add_child(talent_name_label)

	var talent_count_label := Label.new()
	talent_count_label.name = "TalentCountLabel"
	talent_count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiFontConfig.apply_label_font_size(talent_count_label, UiFontConfig.PRESTIGE_COUNT_FONT_SIZE)
	right_content.add_child(talent_count_label)

	var purchase_bonus_gain_label := Label.new()
	purchase_bonus_gain_label.name = "PurchaseBonusGainLabel"
	purchase_bonus_gain_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiFontConfig.apply_label_font_size(purchase_bonus_gain_label, UiFontConfig.PRESTIGE_PURCHASE_GAIN_FONT_SIZE)
	right_content.add_child(purchase_bonus_gain_label)

	var total_bonus_label := Label.new()
	total_bonus_label.name = "TotalBonusLabel"
	total_bonus_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiFontConfig.apply_label_font_size(total_bonus_label, UiFontConfig.PRESTIGE_TOTAL_BONUS_FONT_SIZE)
	right_content.add_child(total_bonus_label)

	var empty_row_label := Label.new()
	empty_row_label.name = "EmptyRowLabel"
	empty_row_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	empty_row_label.text = " "
	UiFontConfig.apply_label_font_size(empty_row_label, UiFontConfig.PRESTIGE_EMPTY_ROW_FONT_SIZE)
	right_content.add_child(empty_row_label)

	var button := Button.new()
	button.name = "UpgradeButton"
	button.custom_minimum_size = TALENT_BUTTON_SIZE
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(func() -> void: prestige_talent_purchase_requested.emit(talent_index, selected_buy_mode))
	ButtonVisualUtils.disable_focus_artifact(button)
	UiFontConfig.apply_button_font_size(button, UiFontConfig.PRESTIGE_BUTTON_FONT_SIZE)
	content.add_child(button)

	return {
		"talent_name_label": talent_name_label,
		"talent_count_label": talent_count_label,
		"purchase_bonus_gain_label": purchase_bonus_gain_label,
		"total_bonus_label": total_bonus_label,
		"empty_row_label": empty_row_label,
		"button": button,
	}


func _on_prestige_button_pressed() -> void:
	prestige_requested.emit()


func _update_talent_row(state: ClickerState, talent_index: int, row: Dictionary) -> void:
	var talent_name_label: Label = row["talent_name_label"]
	var talent_count_label: Label = row["talent_count_label"]
	var purchase_bonus_gain_label: Label = row["purchase_bonus_gain_label"]
	var total_bonus_label: Label = row["total_bonus_label"]
	var button: Button = row["button"]

	var level: int = state.prestige_talent_levels[talent_index]
	var talent_name: String = LocalizationManager.tr_key(PrestigeConfig.get_name_key(talent_index))

	talent_name_label.text = LocalizationManager.format_key("prestige.card.name", {"name": talent_name})

	talent_count_label.text = LocalizationManager.format_key("prestige.card.count", {"count": level})

	var bonus_gain: int = state.get_prestige_talent_bulk_bonus_gain(talent_index, selected_buy_mode)
	purchase_bonus_gain_label.text = LocalizationManager.format_key("prestige.card.purchase_bonus_gain", {"bonus": bonus_gain})

	var total_bonus: int = state.get_prestige_talent_total_bonus_percent(talent_index)
	total_bonus_label.text = LocalizationManager.format_key("prestige.card.total_bonus", {"bonus": total_bonus})

	var bulk_count: int = state.get_prestige_talent_bulk_display_count(talent_index, selected_buy_mode)
	var bulk_cost: int = state.get_prestige_talent_bulk_display_cost(talent_index, selected_buy_mode)
	var can_afford: bool = state.get_prestige_talent_bulk_count(talent_index, selected_buy_mode) > 0
	button.disabled = not can_afford
	button.text = LocalizationManager.format_key("prestige.talent_upgrade_bulk", {
		"count": bulk_count,
		"cost": NumberFormatter.compact(bulk_cost),
	})


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
