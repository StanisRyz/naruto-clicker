extends Control

var state: ClickerState = ClickerState.new()
var boss_time_left: float = 0.0
var boss_timer_active: bool = false

@onready var stats_panel: StatsPanel = $MarginContainer/VBoxContainer/StatsPanel
@onready var game_field: GameField = $MarginContainer/VBoxContainer/GameField
@onready var upgrade_panel: UpgradePanel = $MarginContainer/VBoxContainer/UpgradePanel
@onready var status_label: Label = $MarginContainer/VBoxContainer/StatusLabel


func _ready() -> void:
	game_field.attack_requested.connect(_on_attack_requested)
	upgrade_panel.damage_upgrade_requested.connect(_on_damage_upgrade_requested)
	_update_ui()
	_sync_boss_timer()


func _process(delta: float) -> void:
	if not boss_timer_active:
		return

	boss_time_left = maxf(boss_time_left - delta, 0.0)
	game_field.update_boss_timer(boss_time_left, boss_timer_active)

	if boss_time_left <= 0.0:
		_fail_boss_level()


func _update_ui() -> void:
	stats_panel.update_view(state)
	game_field.update_view(state)
	game_field.update_boss_timer(boss_time_left, boss_timer_active)
	upgrade_panel.update_view(state)


func _on_attack_requested() -> void:
	var result: Dictionary = state.attack()
	game_field.play_hit_feedback(result.get("damage_dealt", 0))
	if result.get("defeated", false):
		game_field.play_defeat_feedback(result.get("level_up", false))
	status_label.text = result.get("status_text", "")
	_update_ui()
	_sync_boss_timer()


func _on_damage_upgrade_requested() -> void:
	var result: Dictionary = state.buy_damage_upgrade()
	status_label.text = result.get("status_text", "")
	_update_ui()


func _sync_boss_timer() -> void:
	if state.is_boss_level:
		if not boss_timer_active:
			boss_time_left = state.boss_time_limit
			boss_timer_active = true
	else:
		boss_timer_active = false
		boss_time_left = 0.0

	game_field.update_boss_timer(boss_time_left, boss_timer_active)


func _fail_boss_level() -> void:
	boss_timer_active = false
	var result: Dictionary = state.fail_boss_level()
	boss_time_left = 0.0
	status_label.text = result.get("status_text", "")
	_update_ui()
