class_name StatsPanel
extends GridContainer

@onready var gold_label: Label = $GoldLabel
@onready var character_level_label: Label = $CharacterLevelLabel
@onready var damage_label: Label = $DamageLabel
@onready var partner_dps_label: Label = $PartnerDpsLabel
@onready var level_label: Label = $LevelLabel
@onready var enemies_defeated_label: Label = $EnemiesDefeatedLabel
@onready var zone_label: Label = $ZoneLabel
@onready var zone_range_label: Label = $ZoneRangeLabel


func update_view(state: ClickerState) -> void:
	gold_label.text = "Gold: %d" % state.gold
	character_level_label.text = "Character Level: %d" % state.character_level
	damage_label.text = "Damage: %d" % state.click_damage
	partner_dps_label.text = "Partner DPS: %d" % state.get_total_partner_dps()
	level_label.text = "Level: %d" % state.current_level
	enemies_defeated_label.text = "Enemies: %d / %d" % [
		state.enemies_defeated_on_level,
		state.enemies_required_per_level,
	]
	zone_label.text = "Zone: %s" % state.zone_name
	zone_range_label.text = "Lv %d-%d" % [state.zone_level_start, state.zone_level_end]
