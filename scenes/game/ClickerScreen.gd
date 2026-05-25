extends Control

var state: ClickerState = ClickerState.new()
var boss_time_left: float = 0.0
var boss_timer_active: bool = false
var autoclick_accumulator: float = 0.0
var autoclick_time_left: float = 0.0
var gold_bonus_time_left: float = 0.0
var ability_duration: float = 30.0
var autoclick_interval: float = 0.05
var autoclick_interval_epsilon: float = 0.000001
var partner_damage_accumulator: float = 0.0
var partner_damage_interval: float = 0.1
var partner_damage_interval_epsilon: float = 0.000001

@onready var stats_panel: StatsPanel = $MainContent/VBoxContainer/StatsPanel
@onready var game_field: GameField = $GameField
@onready var ability_bar: AbilityBar = $AbilityBar
@onready var status_label: Label = $MainContent/VBoxContainer/StatusLabel
@onready var upgrades_button: Button = $BottomBar/MarginContainer/HBoxContainer/UpgradesButton
@onready var partners_button: Button = $BottomBar/MarginContainer/HBoxContainer/PartnersButton
@onready var upgrade_sheet: UpgradeSheet = $UpgradeSheet
@onready var partner_sheet: PartnerSheet = $PartnerSheet


func _ready() -> void:
	game_field.attack_requested.connect(_on_attack_requested)
	ability_bar.autoclick_requested.connect(_on_autoclick_requested)
	ability_bar.gold_bonus_requested.connect(_on_gold_bonus_requested)
	upgrades_button.pressed.connect(_on_upgrades_button_pressed)
	partners_button.pressed.connect(_on_partners_button_pressed)
	upgrade_sheet.character_level_upgrade_requested.connect(_on_character_level_upgrade_requested)
	upgrade_sheet.autoclick_purchase_requested.connect(_on_autoclick_purchase_requested)
	upgrade_sheet.gold_bonus_purchase_requested.connect(_on_gold_bonus_purchase_requested)
	partner_sheet.partner_purchase_requested.connect(_on_partner_purchase_requested)
	_update_ui()
	_sync_boss_timer()


func _process(delta: float) -> void:
	if boss_timer_active:
		boss_time_left = maxf(boss_time_left - delta, 0.0)
		game_field.update_boss_timer(boss_time_left, boss_timer_active)

		if boss_time_left <= 0.0:
			_fail_boss_level()
			return

	_process_ability_timers(delta)

	if state.autoclick_active:
		autoclick_accumulator += delta

		while autoclick_accumulator + autoclick_interval_epsilon >= autoclick_interval and state.autoclick_active:
			autoclick_accumulator -= autoclick_interval
			_run_autoclick_attack()
	else:
		autoclick_accumulator = 0.0

	if state.get_total_partner_dps() > 0:
		partner_damage_accumulator += delta

		while partner_damage_accumulator + partner_damage_interval_epsilon >= partner_damage_interval:
			partner_damage_accumulator -= partner_damage_interval
			_run_partner_damage_tick()
	else:
		partner_damage_accumulator = 0.0


func _update_ui() -> void:
	stats_panel.update_view(state)
	game_field.update_view(state)
	game_field.update_boss_timer(boss_time_left, boss_timer_active)
	ability_bar.update_view(state, autoclick_time_left, gold_bonus_time_left)
	upgrade_sheet.update_view(state)
	partner_sheet.update_view(state)


func _on_attack_requested() -> void:
	var result: Dictionary = state.attack()
	_apply_attack_result(result, true)


func _on_character_level_upgrade_requested() -> void:
	var result: Dictionary = state.buy_character_level_upgrade()
	status_label.text = result.get("status_text", "")
	_update_ui()


func _on_autoclick_purchase_requested() -> void:
	var result: Dictionary = state.buy_autoclick_ability()
	status_label.text = result.get("status_text", "")
	_update_ui()


func _on_gold_bonus_purchase_requested() -> void:
	var result: Dictionary = state.buy_gold_bonus_ability()
	status_label.text = result.get("status_text", "")
	_update_ui()


func _on_partner_purchase_requested(partner_index: int) -> void:
	var result: Dictionary = state.buy_partner(partner_index)
	status_label.text = result.get("status_text", "")
	_update_ui()


func _on_upgrades_button_pressed() -> void:
	upgrade_sheet.show_sheet()


func _on_partners_button_pressed() -> void:
	partner_sheet.show_sheet()


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


func _run_autoclick_attack() -> void:
	var result: Dictionary = state.attack()
	_apply_attack_result(result, false)


func _run_partner_damage_tick() -> void:
	var tick_damage: int = state.get_partner_tick_damage()
	if tick_damage <= 0:
		return

	var result: Dictionary = state.attack_with_damage(tick_damage)
	_apply_passive_attack_result(result)


func _on_autoclick_requested() -> void:
	if not state.autoclick_purchased:
		return

	state.autoclick_active = true
	autoclick_time_left = ability_duration
	autoclick_accumulator = 0.0
	_update_ui()


func _on_gold_bonus_requested() -> void:
	if not state.gold_bonus_purchased:
		return

	state.gold_bonus_active = true
	gold_bonus_time_left = ability_duration
	_update_ui()


func _process_ability_timers(delta: float) -> void:
	if state.autoclick_active:
		autoclick_time_left = maxf(autoclick_time_left - delta, 0.0)
		if autoclick_time_left <= 0.0:
			state.autoclick_active = false
			autoclick_accumulator = 0.0

	if state.gold_bonus_active:
		gold_bonus_time_left = maxf(gold_bonus_time_left - delta, 0.0)
		if gold_bonus_time_left <= 0.0:
			state.gold_bonus_active = false

	ability_bar.update_view(state, autoclick_time_left, gold_bonus_time_left)


func _apply_passive_attack_result(result: Dictionary) -> void:
	if result.get("defeated", false):
		game_field.play_defeat_feedback(result.get("level_up", false))
		status_label.text = result.get("status_text", "")

	_update_ui()
	_sync_boss_timer()
