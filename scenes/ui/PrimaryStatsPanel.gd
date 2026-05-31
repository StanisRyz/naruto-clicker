class_name PrimaryStatsPanel
extends Control

signal settings_requested

@onready var gold_value_label: Label = $HBoxContainer/GoldCard/GoldValueLabel
@onready var gems_value_label: Label = $HBoxContainer/GemsCard/GemsValueLabel
@onready var damage_value_label: Label = $HBoxContainer/DamageCard/DamageValueLabel
@onready var partner_dps_value_label: Label = $HBoxContainer/PartnerDpsCard/PartnerDpsValueLabel
@onready var settings_button: Button = $HBoxContainer/SettingsCard/SettingsButton


func _ready() -> void:
	settings_button.pressed.connect(_on_settings_button_pressed)


func update_view(state: ClickerState) -> void:
	gold_value_label.text = NumberFormatter.compact(state.gold)
	gems_value_label.text = NumberFormatter.compact(state.gems)
	damage_value_label.text = NumberFormatter.compact(state.click_damage)
	partner_dps_value_label.text = NumberFormatter.compact(state.get_final_partner_dps(false))


func _on_settings_button_pressed() -> void:
	settings_requested.emit()
