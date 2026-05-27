class_name ProgressInfoPanel
extends Control

@onready var level_label: Label = $VBoxContainer/LevelLabel
@onready var zone_label: Label = $VBoxContainer/ZoneLabel
@onready var enemies_label: Label = $VBoxContainer/EnemiesLabel
@onready var enemy_name_label: Label = $VBoxContainer/EnemyNameLabel
@onready var enemy_hp_label: Label = $VBoxContainer/EnemyHpLabel
@onready var enemy_hp_progress_bar: ProgressBar = $VBoxContainer/EnemyHpProgressBar


func update_view(state: ClickerState) -> void:
	level_label.text = "Level %d" % state.current_level
	zone_label.text = "%s" % state.zone_name
	enemies_label.text = "Enemies %d / %d" % [
		state.enemies_defeated_on_level,
		state.enemies_required_per_level,
	]
	enemy_name_label.text = "%s" % state.enemy_name
	enemy_hp_label.text = "HP %d / %d" % [state.target_hp, state.target_max_hp]
	enemy_hp_progress_bar.max_value = maxf(float(state.target_max_hp), 1.0)
	enemy_hp_progress_bar.value = clampf(float(state.target_hp), 0.0, enemy_hp_progress_bar.max_value)
