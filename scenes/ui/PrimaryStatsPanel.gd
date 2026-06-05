class_name PrimaryStatsPanel
extends Control

signal settings_requested

const HUD_ICON_SIZE: float = 92.0
const HUD_ICON_COUNT: int = 4
const HUD_LABEL_GAP: float = 6.0
const HUD_LABEL_MAX_WIDTH: float = 100.0
const HUD_HEIGHT: float = 92.0

@onready var gold_item: Control = $HudLayer/GoldItem
@onready var gold_icon: ColorRect = $HudLayer/GoldItem/GoldIcon
@onready var gold_value_label: Label = $HudLayer/GoldItem/GoldValueLabel
@onready var gems_item: Control = $HudLayer/GemsItem
@onready var gems_icon: ColorRect = $HudLayer/GemsItem/GemsIcon
@onready var gems_value_label: Label = $HudLayer/GemsItem/GemsValueLabel
@onready var damage_item: Control = $HudLayer/DamageItem
@onready var damage_icon: ColorRect = $HudLayer/DamageItem/DamageIcon
@onready var damage_value_label: Label = $HudLayer/DamageItem/DamageValueLabel
@onready var partner_dps_item: Control = $HudLayer/PartnerDpsItem
@onready var partner_dps_icon: ColorRect = $HudLayer/PartnerDpsItem/PartnerDpsIcon
@onready var partner_dps_value_label: Label = $HudLayer/PartnerDpsItem/PartnerDpsValueLabel
@onready var settings_button: Button = $HudLayer/SettingsButton
@onready var settings_icon: ColorRect = $HudLayer/SettingsButton/SettingsIcon


func _ready() -> void:
	gems_item.visible = false
	settings_button.pressed.connect(_on_settings_button_pressed)
	_layout_hud_items()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_layout_hud_items()


func update_view(state: ClickerState) -> void:
	gold_value_label.text = NumberFormatter.compact(state.gold)
	damage_value_label.text = NumberFormatter.compact(state.click_damage)
	partner_dps_value_label.text = NumberFormatter.compact(state.get_final_partner_dps(false))


func _on_settings_button_pressed() -> void:
	settings_requested.emit()


func _layout_hud_items() -> void:
	var available_width: float = size.x
	if available_width <= 0.0:
		return

	var gap: float = 0.0
	if HUD_ICON_COUNT > 1:
		gap = (available_width - HUD_ICON_SIZE * float(HUD_ICON_COUNT)) / float(HUD_ICON_COUNT - 1)
	gap = maxf(gap, 0.0)

	_place_stat_item(gold_item, gold_icon, gold_value_label, 0, gap)
	_place_stat_item(damage_item, damage_icon, damage_value_label, 1, gap)
	_place_stat_item(partner_dps_item, partner_dps_icon, partner_dps_value_label, 2, gap)
	_place_settings_button(3, gap)


func _place_stat_item(item: Control, icon: ColorRect, label: Label, index: int, gap: float) -> void:
	var icon_x: float = float(index) * (HUD_ICON_SIZE + gap)

	item.position = Vector2(icon_x, 0.0)
	item.size = Vector2(HUD_ICON_SIZE + gap, HUD_HEIGHT)

	icon.position = Vector2.ZERO
	icon.size = Vector2(HUD_ICON_SIZE, HUD_ICON_SIZE)
	icon.custom_minimum_size = Vector2(HUD_ICON_SIZE, HUD_ICON_SIZE)

	var label_width: float = minf(HUD_LABEL_MAX_WIDTH, maxf(0.0, gap - HUD_LABEL_GAP - 4.0))
	label.position = Vector2(HUD_ICON_SIZE + HUD_LABEL_GAP, 0.0)
	label.size = Vector2(label_width, HUD_HEIGHT)
	label.custom_minimum_size = Vector2(label_width, HUD_HEIGHT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS


func _place_settings_button(index: int, gap: float) -> void:
	var icon_x: float = float(index) * (HUD_ICON_SIZE + gap)

	settings_button.position = Vector2(icon_x, 0.0)
	settings_button.size = Vector2(HUD_ICON_SIZE, HUD_ICON_SIZE)
	settings_button.custom_minimum_size = Vector2(HUD_ICON_SIZE, HUD_ICON_SIZE)

	settings_icon.position = Vector2.ZERO
	settings_icon.size = Vector2(HUD_ICON_SIZE, HUD_ICON_SIZE)
	settings_icon.custom_minimum_size = Vector2(HUD_ICON_SIZE, HUD_ICON_SIZE)
