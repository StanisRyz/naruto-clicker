class_name UiFontConfig
extends RefCounted

# Global/default
const DEFAULT_LABEL_FONT_SIZE: int = 22
const DEFAULT_BUTTON_FONT_SIZE: int = 22

# Top HUD
const HUD_VALUE_FONT_SIZE: int = 20

# Bottom tabs
const BOTTOM_TAB_FONT_SIZE: int = 15

# Partner cards
const PARTNER_NAME_FONT_SIZE: int = 16
const PARTNER_COUNT_GAIN_FONT_SIZE: int = 14
const PARTNER_TOTAL_DPS_FONT_SIZE: int = 14
const PARTNER_MILESTONE_FONT_SIZE: int = 13
const PARTNER_BUTTON_FONT_SIZE: int = 14

# Upgrade cards
const UPGRADE_NAME_FONT_SIZE: int = 16
const UPGRADE_GAIN_FONT_SIZE: int = 14
const UPGRADE_VALUE_FONT_SIZE: int = 14
const UPGRADE_MILESTONE_FONT_SIZE: int = 13
const UPGRADE_BUTTON_FONT_SIZE: int = 14

# Ability bar
const ABILITY_BAR_COUNTDOWN_FONT_SIZE: int = 24

# Stage navigator
const STAGE_NAV_STAGE_NUMBER_FONT_SIZE: int = 25
const STAGE_NAV_SIDE_BUTTON_FONT_SIZE: int = 16
const STAGE_NUMBER_FONT_SIZE: int = STAGE_NAV_STAGE_NUMBER_FONT_SIZE
const STAGE_SIDE_BUTTON_FONT_SIZE: int = STAGE_NAV_SIDE_BUTTON_FONT_SIZE


static func apply_label_font_size(label: Label, size: int) -> void:
	if label == null:
		return
	label.add_theme_font_size_override("font_size", size)


static func apply_button_font_size(button: Button, size: int) -> void:
	if button == null:
		return
	button.add_theme_font_size_override("font_size", size)
