class_name PrimaryStatsPanel
extends Control

signal settings_requested

@onready var gold_value_label: Label = $HBoxContainer/GoldCard/GoldValueLabel
@onready var character_level_value_label: Label = $HBoxContainer/CharacterLevelCard/CharacterLevelValueLabel
@onready var damage_value_label: Label = $HBoxContainer/DamageCard/DamageValueLabel
@onready var partner_dps_value_label: Label = $HBoxContainer/PartnerDpsCard/PartnerDpsValueLabel
@onready var settings_button: Button = $HBoxContainer/SettingsButton


func _ready() -> void:
	settings_button.pressed.connect(_on_settings_button_pressed)


func update_view(state: ClickerState) -> void:
	gold_value_label.text = "%d" % state.gold
	character_level_value_label.text = "%d" % state.character_level
	damage_value_label.text = "%d" % state.click_damage
	partner_dps_value_label.text = "%d" % state.get_final_partner_dps(false)


func _on_settings_button_pressed() -> void:
	settings_requested.emit()
