extends Control

var state: ClickerState = ClickerState.new()
var boss_time_left: float = 0.0
var boss_timer_active: bool = false
var autoclick_accumulator: float = 0.0

@onready var stats_panel: StatsPanel = $MainContent/VBoxContainer/StatsPanel
@onready var game_field: GameField = $MainContent/VBoxContainer/GameField
@onready var status_label: Label = $MainContent/VBoxContainer/StatusLabel
@onready var upgrades_button: Button = $BottomBar/MarginContainer/UpgradesButton
@onready var upgrade_sheet: UpgradeSheet = $UpgradeSheet


func _ready() -> void:
	game_field.attack_requested.connect(_on_attack_requested)
	game_field.autoclick_requested.connect(_on_autoclick_requested)
	game_field.gold_bonus_requested.connect(_on_gold_bonus_requested)
	upgrades_button.pressed.connect(_on_upgrades_button_pressed)
	upgrade_sheet.character_level_upgrade_requested.connect(_on_character_level_upgrade_requested)
	_update_ui()
	_sync_boss_timer()


func _process(delta: float) -> void:
	if boss_timer_active:
		boss_time_left = maxf(boss_time_left - delta, 0.0)
		game_field.update_boss_timer(boss_time_left, boss_timer_active)

		if boss_time_left <= 0.0:
			_fail_boss_level()
			return

	if state.autoclick_active:
		autoclick_accumulator += delta

		while autoclick_accumulator >= 1.0:
			autoclick_accumulator -= 1.0
			_run_autoclick_batch()
	else:
		autoclick_accumulator = 0.0


func _update_ui() -> void:
	stats_panel.update_view(state)
	game_field.update_view(state)
	game_field.update_boss_timer(boss_time_left, boss_timer_active)
	upgrade_sheet.update_view(state)


func _on_attack_requested() -> void:
	var result: Dictionary = state.attack()
	_apply_attack_result(result, true)


func _on_character_level_upgrade_requested() -> void:
	var result: Dictionary = state.buy_character_level_upgrade()
	status_label.text = result.get("status_text", "")
	_update_ui()


func _on_upgrades_button_pressed() -> void:
	upgrade_sheet.show_sheet()


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


func _apply_attack_result(result: Dictionary, show_hit_feedback: bool) -> void:
	if show_hit_feedback:
		game_field.play_hit_feedback(result.get("damage_dealt", 0))

	if result.get("defeated", false):
		game_field.play_defeat_feedback(result.get("level_up", false))

	status_label.text = result.get("status_text", "")
	_update_ui()
	_sync_boss_timer()


func _run_autoclick_batch() -> void:
	var total_damage: int = 0
	var last_result: Dictionary = {}

	for index in range(20):
		last_result = state.attack()
		total_damage += int(last_result.get("damage_dealt", 0))

		if last_result.get("level_up", false):
			_sync_boss_timer()

	if not last_result.is_empty():
		last_result["damage_dealt"] = total_damage
		_apply_attack_result(last_result, total_damage > 0)


func _on_autoclick_requested() -> void:
	if not state.autoclick_unlocked:
		return

	state.autoclick_active = not state.autoclick_active
	autoclick_accumulator = 0.0
	_update_ui()


func _on_gold_bonus_requested() -> void:
	if not state.gold_bonus_unlocked:
		return

	state.gold_bonus_active = not state.gold_bonus_active
	_update_ui()
