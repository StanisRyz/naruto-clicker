class_name ProgressInfoPanel
extends Control

@onready var level_label: Label = $VBoxContainer/LevelLabel
@onready var zone_name_label: Label = $VBoxContainer/ZoneNameLabel
@onready var enemies_label: Label = $VBoxContainer/EnemiesLabel


func update_view(state: ClickerState) -> void:
	level_label.text = "Level %d" % state.current_level
	zone_name_label.text = "%s" % state.zone_name
	enemies_label.text = "Enemies %d / %d" % [
		state.enemies_defeated_on_level,
		state.enemies_required_per_level,
	]
