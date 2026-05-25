extends Control

var state: ClickerState = ClickerState.new()

@onready var stats_panel: StatsPanel = $MarginContainer/VBoxContainer/StatsPanel
@onready var game_field: GameField = $MarginContainer/VBoxContainer/GameField
@onready var upgrade_panel: UpgradePanel = $MarginContainer/VBoxContainer/UpgradePanel
@onready var status_label: Label = $MarginContainer/VBoxContainer/StatusLabel


func _ready() -> void:
	game_field.attack_requested.connect(_on_attack_requested)
	upgrade_panel.damage_upgrade_requested.connect(_on_damage_upgrade_requested)
	_update_ui()


func _update_ui() -> void:
	stats_panel.update_view(state)
	game_field.update_view(state)
	upgrade_panel.update_view(state)


func _on_attack_requested() -> void:
	var result: Dictionary = state.attack()
	status_label.text = result.get("status_text", "")
	_update_ui()


func _on_damage_upgrade_requested() -> void:
	var result: Dictionary = state.buy_damage_upgrade()
	status_label.text = result.get("status_text", "")
	_update_ui()
