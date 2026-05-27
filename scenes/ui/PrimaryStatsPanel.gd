class_name PrimaryStatsPanel
extends Control

@onready var gold_value_label: Label = $VBoxContainer/GoldCard/Content/GoldValueLabel
@onready var character_level_value_label: Label = $VBoxContainer/CharacterLevelCard/Content/CharacterLevelValueLabel
@onready var damage_value_label: Label = $VBoxContainer/DamageCard/Content/DamageValueLabel
@onready var partner_dps_value_label: Label = $VBoxContainer/PartnerDpsCard/Content/PartnerDpsValueLabel


func update_view(state: ClickerState) -> void:
	gold_value_label.text = "%d" % state.gold
	character_level_value_label.text = "%d" % state.character_level
	damage_value_label.text = "%d" % state.click_damage
	partner_dps_value_label.text = "%d" % state.get_total_partner_dps()
