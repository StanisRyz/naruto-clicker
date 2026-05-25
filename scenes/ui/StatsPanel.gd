class_name StatsPanel
extends GridContainer

@onready var gold_label: Label = $GoldLabel
@onready var damage_label: Label = $DamageLabel
@onready var level_label: Label = $LevelLabel
@onready var enemies_defeated_label: Label = $EnemiesDefeatedLabel


func update_view(state: ClickerState) -> void:
	gold_label.text = "Gold: %d" % state.gold
	damage_label.text = "Damage: %d" % state.click_damage
	level_label.text = "Level: %d" % state.current_level
	enemies_defeated_label.text = "Enemies: %d / %d" % [
		state.enemies_defeated_on_level,
		state.enemies_required_per_level,
	]
