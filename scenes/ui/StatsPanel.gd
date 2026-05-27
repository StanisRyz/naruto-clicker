class_name StatsPanel
extends Control

@onready var gold_value_label: Label = $VBoxContainer/PrimaryStatsContainer/GoldCard/Content/GoldValueLabel
@onready var character_level_value_label: Label = $VBoxContainer/PrimaryStatsContainer/CharacterLevelCard/Content/CharacterLevelValueLabel
@onready var damage_value_label: Label = $VBoxContainer/PrimaryStatsContainer/DamageCard/Content/DamageValueLabel
@onready var partner_dps_value_label: Label = $VBoxContainer/PrimaryStatsContainer/PartnerDpsCard/Content/PartnerDpsValueLabel
@onready var level_label: Label = $VBoxContainer/ProgressInfoContainer/LevelLabel
@onready var zone_name_label: Label = $VBoxContainer/ProgressInfoContainer/ZoneNameLabel
@onready var enemies_label: Label = $VBoxContainer/ProgressInfoContainer/EnemiesLabel


func update_view(state: ClickerState) -> void:
	gold_value_label.text = "%d" % state.gold
	character_level_value_label.text = "%d" % state.character_level
	damage_value_label.text = "%d" % state.click_damage
	partner_dps_value_label.text = "%d" % state.get_total_partner_dps()
	level_label.text = "Level %d" % state.current_level
	zone_name_label.text = "%s" % state.zone_name
	enemies_label.text = "Enemies %d / %d" % [
		state.enemies_defeated_on_level,
		state.enemies_required_per_level,
	]
