class_name UiFontConfig
extends RefCounted

# Global/default
const DEFAULT_LABEL_FONT_SIZE: int = 22
const DEFAULT_BUTTON_FONT_SIZE: int = 22

# Top HUD
const HUD_VALUE_FONT_SIZE: int = 22

# Sheet headers
const SHEET_RESOURCE_VALUE_FONT_SIZE: int = 30

# Bottom tabs
const BOTTOM_TAB_FONT_SIZE: int = 18

# Partner cards
const PARTNER_NAME_FONT_SIZE: int = 22
const PARTNER_COUNT_GAIN_FONT_SIZE: int = 20
const PARTNER_TOTAL_DPS_FONT_SIZE: int = 20
const PARTNER_MILESTONE_FONT_SIZE: int = 18
const PARTNER_BUTTON_FONT_SIZE: int = 20

# Upgrade cards
const UPGRADE_NAME_FONT_SIZE: int = 22
const UPGRADE_GAIN_FONT_SIZE: int = 20
const UPGRADE_VALUE_FONT_SIZE: int = 20
const UPGRADE_MILESTONE_FONT_SIZE: int = 18
const UPGRADE_BUTTON_FONT_SIZE: int = 20

# Settlement cards
const SETTLEMENT_NAME_FONT_SIZE: int = 22
const SETTLEMENT_COUNT_FONT_SIZE: int = 20
const SETTLEMENT_PURCHASE_GAIN_FONT_SIZE: int = 20
const SETTLEMENT_TOTAL_BONUS_FONT_SIZE: int = 20
const SETTLEMENT_MILESTONE_FONT_SIZE: int = 18
const SETTLEMENT_BUTTON_FONT_SIZE: int = 20

# Prestige talent cards
const PRESTIGE_NAME_FONT_SIZE: int = 22
const PRESTIGE_COUNT_FONT_SIZE: int = 20
const PRESTIGE_PURCHASE_GAIN_FONT_SIZE: int = 20
const PRESTIGE_TOTAL_BONUS_FONT_SIZE: int = 20
const PRESTIGE_EMPTY_ROW_FONT_SIZE: int = 15
const PRESTIGE_BUTTON_FONT_SIZE: int = 20

# Prestige action card
const PRESTIGE_ACTION_TITLE_FONT_SIZE: int = 22
const PRESTIGE_ACTION_REWARD_FONT_SIZE: int = 20
const PRESTIGE_ACTION_RESET_FONT_SIZE: int = 20
const PRESTIGE_ACTION_GET_POINTS_FONT_SIZE: int = 20
const PRESTIGE_ACTION_BUTTON_FONT_SIZE: int = 20

# Ability bar
const ABILITY_BAR_COUNTDOWN_FONT_SIZE: int = 28

# Combat effects
const COMBAT_GOLD_REWARD_FONT_SIZE: int = 50

# Progress / enemy HUD
const PROGRESS_ZONE_FONT_SIZE: int = 28
const PROGRESS_ENEMIES_FONT_SIZE: int = 24
const PROGRESS_ENEMY_NAME_FONT_SIZE: int = 24
const PROGRESS_HP_TEXT_FONT_SIZE: int = 24
const PROGRESS_BOSS_TIMER_FONT_SIZE: int = 28

# Boss timer theme
const PROGRESS_BOSS_TIMER_FONT_PATH: String = "res://assets/fonts/boss_timer.ttf"
const PROGRESS_BOSS_TIMER_FONT_FALLBACK_PATH: String = "res://assets/fonts/boss_timer.otf"
const PROGRESS_BOSS_TIMER_FONT_COLOR: Color = Color(1.0, 0.18, 0.12, 1.0)
const PROGRESS_BOSS_TIMER_OUTLINE_COLOR: Color = Color(0.0, 0.0, 0.0, 1.0)
const PROGRESS_BOSS_TIMER_OUTLINE_SIZE: int = 8

# Combat damage numbers
const COMBAT_DAMAGE_NUMBER_FONT_SIZE: int = 34
const COMBAT_DAMAGE_NUMBER_FONT_PATH: String = PROGRESS_BOSS_TIMER_FONT_PATH
const COMBAT_DAMAGE_NUMBER_FONT_FALLBACK_PATH: String = PROGRESS_BOSS_TIMER_FONT_FALLBACK_PATH
const COMBAT_DAMAGE_NUMBER_FONT_COLOR: Color = PROGRESS_BOSS_TIMER_FONT_COLOR
const COMBAT_DAMAGE_NUMBER_OUTLINE_COLOR: Color = PROGRESS_BOSS_TIMER_OUTLINE_COLOR
const COMBAT_DAMAGE_NUMBER_OUTLINE_SIZE: int = PROGRESS_BOSS_TIMER_OUTLINE_SIZE

# Tasks window
const TASK_CONDITION_FONT_SIZE: int = 18
const TASK_PROGRESS_FONT_SIZE: int = 16
const TASK_REWARD_FONT_SIZE: int = 16
const TASK_BUTTON_FONT_SIZE: int = 14

# Stage navigator
const STAGE_NAV_STAGE_NUMBER_FONT_SIZE: int = 28
const STAGE_NAV_SIDE_BUTTON_FONT_SIZE: int = 28
const STAGE_NUMBER_FONT_SIZE: int = STAGE_NAV_STAGE_NUMBER_FONT_SIZE
const STAGE_SIDE_BUTTON_FONT_SIZE: int = STAGE_NAV_SIDE_BUTTON_FONT_SIZE

# Auto transition popup
const AUTO_TRANSITION_POPUP_FONT_SIZE: int = 20

# Settings window
const SETTINGS_ACTION_BUTTON_FONT_SIZE: int = 20
const SETTINGS_ROW_FONT_SIZE: int = 22

# Offline reward dialog
const OFFLINE_REWARD_TITLE_FONT_SIZE: int = 22
const OFFLINE_REWARD_TIME_FONT_SIZE: int = 20
const OFFLINE_REWARD_REWARD_FONT_SIZE: int = 20
const OFFLINE_REWARD_BUTTON_FONT_SIZE: int = 20


static func apply_boss_timer_theme(label: Label) -> void:
	if label == null:
		return
	apply_label_font_size(label, PROGRESS_BOSS_TIMER_FONT_SIZE)
	label.add_theme_color_override("font_color", PROGRESS_BOSS_TIMER_FONT_COLOR)
	label.add_theme_color_override("font_outline_color", PROGRESS_BOSS_TIMER_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", PROGRESS_BOSS_TIMER_OUTLINE_SIZE)
	var font_path: String = ""
	if ResourceLoader.exists(PROGRESS_BOSS_TIMER_FONT_PATH):
		font_path = PROGRESS_BOSS_TIMER_FONT_PATH
	elif ResourceLoader.exists(PROGRESS_BOSS_TIMER_FONT_FALLBACK_PATH):
		font_path = PROGRESS_BOSS_TIMER_FONT_FALLBACK_PATH
	if font_path != "":
		var font_resource: Resource = ResourceLoader.load(font_path)
		if font_resource is Font:
			label.add_theme_font_override("font", font_resource)


static func apply_damage_number_theme(label: Label) -> void:
	if label == null:
		return
	apply_label_font_size(label, COMBAT_DAMAGE_NUMBER_FONT_SIZE)
	label.add_theme_color_override("font_color", COMBAT_DAMAGE_NUMBER_FONT_COLOR)
	label.add_theme_color_override("font_outline_color", COMBAT_DAMAGE_NUMBER_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", COMBAT_DAMAGE_NUMBER_OUTLINE_SIZE)
	var font_path: String = ""
	if ResourceLoader.exists(COMBAT_DAMAGE_NUMBER_FONT_PATH):
		font_path = COMBAT_DAMAGE_NUMBER_FONT_PATH
	elif ResourceLoader.exists(COMBAT_DAMAGE_NUMBER_FONT_FALLBACK_PATH):
		font_path = COMBAT_DAMAGE_NUMBER_FONT_FALLBACK_PATH
	if font_path != "":
		var font_resource: Resource = ResourceLoader.load(font_path)
		if font_resource is Font:
			label.add_theme_font_override("font", font_resource)


static func apply_label_font_size(label: Label, size: int) -> void:
	if label == null:
		return
	label.add_theme_font_size_override("font_size", size)


static func apply_button_font_size(button: Button, size: int) -> void:
	if button == null:
		return
	button.add_theme_font_size_override("font_size", size)
