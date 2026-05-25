class_name GameField
extends Button

signal attack_requested

@onready var enemy_name_label: Label = $GameFieldContent/EnemyNameLabel
@onready var target_hp_label: Label = $GameFieldContent/TargetHpLabel
@onready var target_progress_bar: ProgressBar = $GameFieldContent/TargetProgressBar


func _ready() -> void:
	pressed.connect(_on_pressed)


func update_view(state: ClickerState) -> void:
	enemy_name_label.text = "Enemy"
	target_hp_label.text = "Enemy HP: %d / %d" % [state.target_hp, state.target_max_hp]
	target_progress_bar.max_value = state.target_max_hp
	target_progress_bar.value = state.target_hp


func _on_pressed() -> void:
	attack_requested.emit()
