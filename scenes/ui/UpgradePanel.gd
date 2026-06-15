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
var hero_level_row: Dictionary = {}
var ability_rows: Array[Dictionary] = []

@onready var rows_container: VBoxContainer = $RowsContainer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	rows_container.mouse_filter = Control.MOUSE_FILTER_PASS
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


func play_hero_purchase_feedback() -> void:
	play_card_button_active_feedback(hero_level_row)


func play_ability_purchase_feedback(ability_id: String) -> void:
	for i in range(ABILITIES.size()):
		if String(ABILITIES[i]["id"]) == ability_id:
			if i < ability_rows.size():
				play_card_button_active_feedback(ability_rows[i])
			return


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


func _create_hero_level_row() -> Dictionary:
	var row: Control = _create_card_row("HeroLevelRow")
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
	var button_label: Label = hero_level_row["button_label"]
	var skill_buttons: Array = hero_level_row["skill_buttons"]
	var skill_image_holders: Array = hero_level_row["skill_image_holders"]
	var bulk_count: int = state.get_character_level_bulk_display_count(selected_buy_mode)
	var bulk_cost: BigNumber = state.get_character_level_bulk_display_cost(selected_buy_mode)
	var damage_gain: BigNumber = state.get_character_level_bulk_damage_gain(selected_buy_mode)
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
	button_label.text = LocalizationManager.format_key("upgrade.hero.button", {
		"count": bulk_count,
		"cost": NumberFormatter.compact(bulk_cost),
	})
	_set_card_button_state(hero_level_row, state.can_afford_character_level_bulk(selected_buy_mode))
	var skills: Array[Dictionary] = state.get_hero_skills()
	_update_skill_icon_row(skills, skill_buttons, skill_image_holders, state, true)


func _create_ability_row(ability_index: int) -> Dictionary:
	var ability: Dictionary = ABILITIES[ability_index]
	var ability_id: String = String(ability["id"])
	var row: Control = _create_card_row("%sRow" % String(ability["name"]).replace(" ", ""))
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
	effect_label.text = ClickerStatePresentation.get_ability_effect_text(state, ability_id)
	var dur_text: String = ClickerStatePresentation.get_ability_duration_text(state, ability_id)
	if not state.is_ability_purchased(ability_id) and not state.is_ability_unlocked(ability_id):
		milestone_label.text = LocalizationManager.format_key("upgrade.ability.unlock_with_duration", {
			"level": state.get_ability_unlock_level(ability_id),
			"duration": dur_text,
		})
	else:
		milestone_label.text = dur_text
	_update_ability_unlock_button(state, ability_id, row)
	var skills: Array[Dictionary] = state.get_ability_skills(ability_id)
	_update_skill_icon_row(skills, skill_buttons, skill_image_holders, state, false)


func _on_hero_level_button_pressed() -> void:
	character_level_upgrade_requested.emit(selected_buy_mode)


func _place_card_row(control: Control, y: int, height: int) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 1.0
	control.anchor_bottom = 0.0
	control.offset_left = 0.0
	control.offset_top = y
	control.offset_right = 0.0
	control.offset_bottom = y + height


func _add_card_content(row: Control, button_name: String) -> Dictionary:
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
	image_holder.custom_minimum_size = UPGRADE_IMAGE_SIZE
	image_holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	image_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(image_holder)

	var right_content := Control.new()
	right_content.name = "RightContent"
	right_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_content.custom_minimum_size = Vector2(0, CARD_INNER_HEIGHT)
	right_content.clip_contents = true
	right_content.mouse_filter = Control.MOUSE_FILTER_PASS
	content.add_child(right_content)

	var name_status_label := Label.new()
	name_status_label.name = "NameStatusLabel"
	name_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_status_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_card_row(name_status_label, 0, CARD_ROW_1_HEIGHT)
	right_content.add_child(name_status_label)

	var purchase_gain_label := Label.new()
	purchase_gain_label.name = "PurchaseGainLabel"
	purchase_gain_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	purchase_gain_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	purchase_gain_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	purchase_gain_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_card_row(purchase_gain_label, CARD_ROW_1_HEIGHT + CARD_ROW_GAP, CARD_ROW_2_HEIGHT)
	right_content.add_child(purchase_gain_label)

	var effect_label := Label.new()
	effect_label.name = "EffectLabel"
	effect_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	effect_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	effect_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	effect_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_card_row(effect_label, CARD_ROW_1_HEIGHT + CARD_ROW_2_HEIGHT + CARD_ROW_GAP * 2, CARD_ROW_3_HEIGHT)
	right_content.add_child(effect_label)

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
		skill_row.add_child(skill_button)

		var skill_image_holder = ImageSlotClass.new()
		skill_image_holder.name = "ImageHolder"
		skill_image_holder.fallback_color = SKILL_ICON_COLORS["locked"]
		skill_image_holder.show_fallback_behind_texture = false
		skill_image_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		skill_image_holder.set_anchors_preset(Control.PRESET_FULL_RECT)
		skill_button.add_child(skill_image_holder)

		skill_buttons.append(skill_button)
		skill_image_holders.append(skill_image_holder)

	var skill_spacer := Control.new()
	skill_spacer.name = "SkillSpacer"
	skill_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill_spacer.mouse_filter = Control.MOUSE_FILTER_PASS
	skill_row.add_child(skill_spacer)

	var btn_dict := _create_image_card_button(button_name)
	var button: Button = btn_dict["button"]
	var button_label: Label = btn_dict["button_label"]
	var button_image_holder = btn_dict["button_image_holder"]
	var button_slot := _create_card_button_slot(button)
	content.add_child(button_slot)

	UiFontConfig.apply_label_font_size(name_status_label, UiFontConfig.UPGRADE_NAME_FONT_SIZE)
	UiFontConfig.apply_label_font_size(purchase_gain_label, UiFontConfig.UPGRADE_GAIN_FONT_SIZE)
	UiFontConfig.apply_label_font_size(effect_label, UiFontConfig.UPGRADE_VALUE_FONT_SIZE)
	UiFontConfig.apply_label_font_size(milestone_label, UiFontConfig.UPGRADE_MILESTONE_FONT_SIZE)
	UiFontConfig.apply_label_font_size(button_label, UiFontConfig.UPGRADE_BUTTON_FONT_SIZE)

	return {
		"name_status_label": name_status_label,
		"purchase_gain_label": purchase_gain_label,
		"effect_label": effect_label,
		"milestone_label": milestone_label,
		"skill_buttons": skill_buttons,
		"skill_image_holders": skill_image_holders,
		"button": button,
		"button_label": button_label,
		"button_image_holder": button_image_holder,
		"button_feedback_token": 0,
		"image_holder": image_holder,
	}


func _update_ability_unlock_button(state: ClickerState, ability_id: String, row: Dictionary) -> void:
	var button_label: Label = row["button_label"]
	var cost: BigNumber = state.get_ability_unlock_cost(ability_id)
	if state.is_ability_purchased(ability_id):
		button_label.text = LocalizationManager.tr_key("upgrade.ability.purchased")
		_set_card_button_state(row, false)
	elif not state.is_ability_unlocked(ability_id):
		button_label.text = LocalizationManager.format_key("upgrade.ability.requires_level", {
			"level": state.get_ability_unlock_level(ability_id),
		})
		_set_card_button_state(row, false)
	else:
		button_label.text = LocalizationManager.format_key("upgrade.ability.buy", {
			"cost": NumberFormatter.compact(cost),
		})
		_set_card_button_state(row, state.can_buy_ability_unlock(ability_id))


func _apply_skill_icon_visual(image_holder, skill_state: String) -> void:
	var tint: Color = SKILL_ICON_COLORS.get(skill_state, SKILL_ICON_COLORS["locked"])
	image_holder.modulate = tint
	image_holder.set_fallback_color(tint)


func _update_skill_icon_row(skills: Array[Dictionary], skill_buttons: Array, skill_image_holders: Array, state: ClickerState, is_hero: bool) -> void:
	for i in range(skill_buttons.size()):
		var skill_button: Button = skill_buttons[i]
		var skill_image_holder = skill_image_holders[i]
		if i >= skills.size():
			skill_button.disabled = true
			_apply_skill_icon_visual(skill_image_holder, "locked")
			continue

		skill_button.disabled = false
		var skill_id: String = String(skills[i].get("id", ""))
		var skill_state: String = state.get_hero_skill_state(skill_id) if is_hero else state.get_ability_skill_state(skill_id)
		_apply_skill_icon_visual(skill_image_holder, skill_state)


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
