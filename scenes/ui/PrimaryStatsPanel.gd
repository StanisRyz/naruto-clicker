class_name PrimaryStatsPanel
extends Control

@onready var gold_value_label: Label = $VBoxContainer/GoldRow/GoldValueLabel
@onready var character_level_value_label: Label = $VBoxContainer/CharacterLevelRow/CharacterLevelValueLabel
@onready var damage_value_label: Label = $VBoxContainer/DamageRow/DamageValueLabel
@onready var partner_dps_value_label: Label = $VBoxContainer/PartnerDpsRow/PartnerDpsValueLabel


func update_view(state: ClickerState) -> void:
	gold_value_label.text = "%d" % state.gold
	character_level_value_label.text = "%d" % state.character_level
	damage_value_label.text = "%d" % state.click_damage
	partner_dps_value_label.text = "%d" % state.get_total_partner_dps()
