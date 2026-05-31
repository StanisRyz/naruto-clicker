class_name PrimaryStatsPanel
extends Control

signal settings_requested

@onready var gold_value_label: Label = $HBoxContainer/GoldCard/GoldValueLabel
@onready var gems_value_label: Label = $HBoxContainer/GemsCard/GemsValueLabel
@onready var character_level_value_label: Label = $HBoxContainer/CharacterLevelCard/CharacterLevelValueLabel
@onready var damage_value_label: Label = $HBoxContainer/DamageCard/DamageValueLabel
@onready var partner_dps_value_label: Label = $HBoxContainer/PartnerDpsCard/PartnerDpsValueLabel
@onready var settings_button: Button = $HBoxContainer/SettingsButton


func _ready() -> void:
	settings_button.pressed.connect(_on_settings_button_pressed)


func update_view(state: ClickerState) -> void:
	gold_value_label.text = _compact(state.gold)
	gems_value_label.text = _compact(state.gems)
	character_level_value_label.text = _compact(state.character_level)
	damage_value_label.text = _compact(state.click_damage)
	partner_dps_value_label.text = _compact(state.get_final_partner_dps(false))


func _on_settings_button_pressed() -> void:
	settings_requested.emit()


static func _compact(value: int) -> String:
	var abs_value: float = abs(float(value))
	var sign_str: String = "-" if value < 0 else ""
	if abs_value >= 1_000_000_000_000.0:
		return "%s%.1fT" % [sign_str, abs_value / 1_000_000_000_000.0]
	if abs_value >= 1_000_000_000.0:
		return "%s%.1fB" % [sign_str, abs_value / 1_000_000_000.0]
	if abs_value >= 1_000_000.0:
		return "%s%.1fM" % [sign_str, abs_value / 1_000_000.0]
	if abs_value >= 1_000.0:
		return "%s%.1fK" % [sign_str, abs_value / 1_000.0]
	return str(value)
