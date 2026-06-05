class_name UpgradePanel
extends VBoxContainer

signal character_level_upgrade_requested(mode: String)
signal hero_skill_popup_requested(skill_id: String, anchor_global_position: Vector2)
signal ability_skill_popup_requested(skill_id: String, anchor_global_position: Vector2)
signal ability_unlock_requested(ability_id: String)

const ABILITIES: Array[Dictionary] = [
	{"id": "autoclick", "name": "Autoclick", "name_key": "ability.autoclick.name"},
	{"id": "gold_bonus", "name": "Gold Bonus", "name_key": "ability.gold_bonus.name"},
	{"id": "focus_burst", "name": "Focus Burst", "name_key": "ability.focus_burst.name"},
	{"id": "rally", "name": "Rally", "name_key": "ability.rally.name"},
]

const BUY_MODES: Array[String] = ["x1", "x10", "x100", "max"]
const UPGRADE_IMAGE_SIZE: Vector2 = Vector2(136, 136)
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
var hero_level_row: Dictionary = {}
var ability_rows: Array[Dictionary] = []

@onready var rows_container: VBoxContainer = $RowsContainer


func _ready() -> void:
	hero_level_row = _create_hero_level_row()
	for ability_index in range(ABILITIES.size()):
		ability_rows.append(_create_ability_row(ability_index))


func update_view(state: ClickerState) -> void:
	current_state = state
	_update_hero_level_row(state)
	for ability_index in range(ability_rows.size()):
		_update_ability_row(state, ability_index, ability_rows[ability_index])


func set_buy_mode(mode: String) -> void:
	if not BUY_MODES.has(mode):
		return
	selected_buy_mode = mode


func _create_hero_level_row() -> Dictionary:
	var row := PanelContainer.new()
	row.name = "HeroLevelRow"
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_stylebox_override("panel", _create_row_stylebox())
	rows_container.add_child(row)

	var row_content: Dictionary = _add_card_content(row, "UpgradeButton")
	var button: Button = row_content["button"]
	button.pressed.connect(_on_hero_level_button_pressed)
	var skill_buttons: Array = row_content["skill_buttons"]
	for i in range(skill_buttons.size()):
		var skill_button: Button = skill_buttons[i]
		var captured_index: int = i
		skill_button.pressed.connect(func() -> void: _on_hero_skill_button_pressed(captured_index, skill_button))

	row_content["image_holder"].set_asset_key("upgrade.hero")
	var skill_holders: Array = row_content["skill_image_holders"]
	for i in range(skill_holders.size()):
		skill_holders[i].set_asset_key(GameAssetCatalog.hero_skill_key(i + 1), SKILL_ICON_COLORS["locked"])

	return row_content


func _update_hero_level_row(state: ClickerState) -> void:
	var name_status_label: Label = hero_level_row["name_status_label"]
	var purchase_gain_label: Label = hero_level_row["purchase_gain_label"]
	var effect_label: Label = hero_level_row["effect_label"]
	var milestone_label: Label = hero_level_row["milestone_label"]
	var button: Button = hero_level_row["button"]
	var skill_buttons: Array = hero_level_row["skill_buttons"]
	var skill_image_holders: Array = hero_level_row["skill_image_holders"]
	var bulk_count: int = state.get_character_level_bulk_display_count(selected_buy_mode)
	var bulk_cost: int = state.get_character_level_bulk_display_cost(selected_buy_mode)
	var damage_gain: int = state.get_character_level_bulk_damage_gain(selected_buy_mode)
	var next_milestone: int = state.get_next_milestone(state.character_level)

	name_status_label.text = LocalizationManager.tr_key("upgrade.hero.card.name")
	purchase_gain_label.text = LocalizationManager.format_key("upgrade.hero.card.level_gain", {
		"level": state.character_level,
		"gain": NumberFormatter.compact(damage_gain),
	})
	effect_label.text = LocalizationManager.format_key("upgrade.hero.card.damage", {
		"damage": NumberFormatter.compact(state.click_damage),
	})
	if next_milestone > 0:
		milestone_label.text = LocalizationManager.format_key("upgrade.hero.card.milestone_next", {
			"milestone": next_milestone,
		})
	else:
		milestone_label.text = LocalizationManager.tr_key("upgrade.hero.card.milestone_max")
	button.disabled = false
	button.text = LocalizationManager.format_key("upgrade.hero.button", {
		"count": bulk_count,
		"cost": NumberFormatter.compact(bulk_cost),
	})
	var skills: Array[Dictionary] = state.get_hero_skills()
	_update_skill_icon_row(skills, skill_buttons, skill_image_holders, state, true)


func _create_ability_row(ability_index: int) -> Dictionary:
	var ability: Dictionary = ABILITIES[ability_index]
	var ability_id: String = String(ability["id"])
	var row := PanelContainer.new()
	row.name = "%sRow" % String(ability["name"]).replace(" ", "")
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_stylebox_override("panel", _create_row_stylebox())
	rows_container.add_child(row)

	var row_content: Dictionary = _add_card_content(row, "BuyButton")
	var button: Button = row_content["button"]
	button.pressed.connect(func() -> void: ability_unlock_requested.emit(ability_id))
	var skill_buttons: Array = row_content["skill_buttons"]
	for i in range(skill_buttons.size()):
		var skill_button: Button = skill_buttons[i]
		var captured_index: int = i
		skill_button.pressed.connect(func() -> void: _on_ability_skill_button_pressed(ability_id, captured_index, skill_button))

	row_content["image_holder"].set_asset_key("upgrade.%s" % ability_id)
	var skill_holders: Array = row_content["skill_image_holders"]
	for i in range(skill_holders.size()):
		skill_holders[i].set_asset_key(GameAssetCatalog.ability_skill_key(ability_id, i + 1), SKILL_ICON_COLORS["locked"])

	return row_content


func _update_ability_row(state: ClickerState, ability_index: int, row: Dictionary) -> void:
	var ability: Dictionary = ABILITIES[ability_index]
	var ability_id: String = String(ability["id"])
	var name_key: String = String(ability.get("name_key", ""))
	var ability_name: String = LocalizationManager.tr_key(name_key) if name_key != "" else String(ability["name"])
	var name_status_label: Label = row["name_status_label"]
	var purchase_gain_label: Label = row["purchase_gain_label"]
	var effect_label: Label = row["effect_label"]
	var milestone_label: Label = row["milestone_label"]
	var button: Button = row["button"]
	var skill_buttons: Array = row["skill_buttons"]
	var skill_image_holders: Array = row["skill_image_holders"]

	var rank: int = state.get_ability_rank(ability_id)
	name_status_label.text = LocalizationManager.format_key("upgrade.ability.card.name", {
		"name": ability_name,
	})
	purchase_gain_label.text = LocalizationManager.format_key("upgrade.ability.card.rank", {
		"rank": rank,
		"max_rank": state.ability_max_rank,
	})
	effect_label.text = state.get_ability_description(ability_id)
	var status_hint: String = ""
	if state.is_ability_purchased(ability_id):
		status_hint = ""
	elif not state.is_ability_unlocked(ability_id):
		status_hint = LocalizationManager.format_key("upgrade.ability.requires_level", {
			"level": state.get_ability_unlock_level(ability_id),
		})
	else:
		status_hint = LocalizationManager.format_key("upgrade.ability.buy", {
			"cost": NumberFormatter.compact(state.get_ability_unlock_cost(ability_id)),
		})
	milestone_label.text = LocalizationManager.format_key("upgrade.ability.card.status", {
		"status": status_hint,
	})
	_update_ability_unlock_button(state, ability_id, button)
	var skills: Array[Dictionary] = state.get_ability_skills(ability_id)
	_update_skill_icon_row(skills, skill_buttons, skill_image_holders, state, false)


func _on_hero_level_button_pressed() -> void:
	character_level_upgrade_requested.emit(selected_buy_mode)


func _add_card_content(row: PanelContainer, button_name: String) -> Dictionary:
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
	image_holder.custom_minimum_size = UPGRADE_IMAGE_SIZE
	image_holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	content.add_child(image_holder)

	var info_container := VBoxContainer.new()
	info_container.name = "RightContent"
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_container.add_theme_constant_override("separation", 4)
	content.add_child(info_container)

	var name_status_label := Label.new()
	name_status_label.name = "NameStatusLabel"
	name_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	info_container.add_child(name_status_label)

	var purchase_gain_label := Label.new()
	purchase_gain_label.name = "PurchaseGainLabel"
	purchase_gain_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	purchase_gain_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	info_container.add_child(purchase_gain_label)

	var effect_label := Label.new()
	effect_label.name = "EffectLabel"
	effect_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	effect_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	info_container.add_child(effect_label)

	var milestone_label := Label.new()
	milestone_label.name = "MilestoneLabel"
	milestone_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	milestone_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	info_container.add_child(milestone_label)

	var skill_row := HBoxContainer.new()
	skill_row.name = "SkillRow"
	skill_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill_row.add_theme_constant_override("separation", 6)
	info_container.add_child(skill_row)

	var skill_buttons: Array[Button] = []
	var skill_image_holders: Array = []
	for i in range(SKILL_COUNT):
		var skill_button := Button.new()
		skill_button.name = "SkillButton%d" % (i + 1)
		skill_button.custom_minimum_size = SKILL_ICON_SIZE
		skill_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		skill_button.focus_mode = Control.FOCUS_NONE
		skill_button.text = ""
		skill_row.add_child(skill_button)

		var skill_image_holder = ImageSlotClass.new()
		skill_image_holder.name = "ImageHolder"
		skill_image_holder.fallback_color = SKILL_ICON_COLORS["locked"]
		skill_image_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		skill_image_holder.set_anchors_preset(Control.PRESET_FULL_RECT)
		skill_button.add_child(skill_image_holder)

		skill_buttons.append(skill_button)
		skill_image_holders.append(skill_image_holder)

	var skill_spacer := Control.new()
	skill_spacer.name = "SkillSpacer"
	skill_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill_row.add_child(skill_spacer)

	var button := Button.new()
	button.name = button_name
	button.custom_minimum_size = Vector2(210, 136)
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(button)

	UiFontConfig.apply_label_font_size(name_status_label, UiFontConfig.UPGRADE_NAME_FONT_SIZE)
	UiFontConfig.apply_label_font_size(purchase_gain_label, UiFontConfig.UPGRADE_GAIN_FONT_SIZE)
	UiFontConfig.apply_label_font_size(effect_label, UiFontConfig.UPGRADE_VALUE_FONT_SIZE)
	UiFontConfig.apply_label_font_size(milestone_label, UiFontConfig.UPGRADE_MILESTONE_FONT_SIZE)
	UiFontConfig.apply_button_font_size(button, UiFontConfig.UPGRADE_BUTTON_FONT_SIZE)

	return {
		"name_status_label": name_status_label,
		"purchase_gain_label": purchase_gain_label,
		"effect_label": effect_label,
		"milestone_label": milestone_label,
		"skill_buttons": skill_buttons,
		"skill_image_holders": skill_image_holders,
		"button": button,
		"image_holder": image_holder,
	}


func _update_ability_unlock_button(state: ClickerState, ability_id: String, button: Button) -> void:
	var cost: int = state.get_ability_unlock_cost(ability_id)
	if state.is_ability_purchased(ability_id):
		button.disabled = true
		button.text = LocalizationManager.tr_key("upgrade.ability.purchased")
	elif not state.is_ability_unlocked(ability_id):
		button.disabled = true
		button.text = LocalizationManager.format_key("upgrade.ability.requires_level", {
			"level": state.get_ability_unlock_level(ability_id),
		})
	else:
		button.text = LocalizationManager.format_key("upgrade.ability.buy", {
			"cost": NumberFormatter.compact(cost),
		})
		button.disabled = not state.can_buy_ability_unlock(ability_id)


func _update_skill_icon_row(skills: Array[Dictionary], skill_buttons: Array, skill_image_holders: Array, state: ClickerState, is_hero: bool) -> void:
	for i in range(skill_buttons.size()):
		var skill_button: Button = skill_buttons[i]
		var skill_image_holder = skill_image_holders[i]
		if i >= skills.size():
			skill_button.disabled = true
			skill_image_holder.set_fallback_color(SKILL_ICON_COLORS["locked"])
			continue

		skill_button.disabled = false
		var skill_id: String = String(skills[i].get("id", ""))
		var skill_state: String = state.get_hero_skill_state(skill_id) if is_hero else state.get_ability_skill_state(skill_id)
		skill_image_holder.set_fallback_color(SKILL_ICON_COLORS.get(skill_state, SKILL_ICON_COLORS["locked"]))


func _on_hero_skill_button_pressed(skill_index: int, skill_button: Button) -> void:
	if current_state == null:
		return
	var skills: Array[Dictionary] = current_state.get_hero_skills()
	if skill_index >= skills.size():
		return
	var skill_id: String = String(skills[skill_index].get("id", ""))
	if skill_id != "":
		hero_skill_popup_requested.emit(skill_id, skill_button.global_position)


func _on_ability_skill_button_pressed(ability_id: String, skill_index: int, skill_button: Button) -> void:
	if current_state == null:
		return
	var skills: Array[Dictionary] = current_state.get_ability_skills(ability_id)
	if skill_index >= skills.size():
		return
	var skill_id: String = String(skills[skill_index].get("id", ""))
	if skill_id != "":
		ability_skill_popup_requested.emit(skill_id, skill_button.global_position)


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
