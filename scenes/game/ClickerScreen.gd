extends Control

var state: ClickerState = ClickerState.new()
var boss_time_left: float = 0.0
var boss_timer_active: bool = false
var autoclick_accumulator: float = 0.0
var autoclick_time_left: float = 0.0
var gold_bonus_time_left: float = 0.0
var focus_burst_time_left: float = 0.0
var rally_time_left: float = 0.0
var autoclick_duration: float = 15.0
var autoclick_cooldown_duration: float = 60.0
var autoclick_cooldown_left: float = 0.0
var gold_bonus_duration: float = 45.0
var gold_bonus_cooldown_duration: float = 300.0
var gold_bonus_cooldown_left: float = 0.0
var focus_burst_duration: float = 20.0
var focus_burst_cooldown_duration: float = 120.0
var focus_burst_cooldown_left: float = 0.0
var rally_duration: float = 30.0
var rally_cooldown_duration: float = 180.0
var rally_cooldown_left: float = 0.0
var autoclick_interval: float = 0.05
var autoclick_interval_epsilon: float = 0.000001
var partner_damage_accumulator: float = 0.0
var partner_damage_interval: float = 0.1
var partner_damage_interval_epsilon: float = 0.000001
var active_bottom_tab: String = ""

@onready var stats_panel: StatsPanel = $MainContent/VBoxContainer/StatsPanel
@onready var game_field: GameField = $GameField
@onready var ability_bar: AbilityBar = $AbilityBar
@onready var status_label: Label = $MainContent/VBoxContainer/StatusLabel
@onready var upgrades_button: Button = $BottomBar/MarginContainer/HBoxContainer/UpgradesButton
@onready var partners_button: Button = $BottomBar/MarginContainer/HBoxContainer/PartnersButton
@onready var settlement_button: Button = $BottomBar/MarginContainer/HBoxContainer/SettlementButton
@onready var prestige_button: Button = $BottomBar/MarginContainer/HBoxContainer/PrestigeButton
@onready var upgrade_sheet: UpgradeSheet = $UpgradeSheet
@onready var partner_sheet: PartnerSheet = $PartnerSheet
@onready var settlement_sheet: SettlementSheet = $SettlementSheet
@onready var prestige_sheet: PrestigeSheet = $PrestigeSheet
@onready var prestige_confirm_dialog: PrestigeConfirmDialog = $PrestigeSheet/PrestigeConfirmDialog


func _ready() -> void:
	game_field.attack_requested.connect(_on_attack_requested)
	ability_bar.autoclick_requested.connect(_on_autoclick_requested)
	ability_bar.gold_bonus_requested.connect(_on_gold_bonus_requested)
	ability_bar.focus_burst_requested.connect(_on_focus_burst_requested)
	ability_bar.rally_requested.connect(_on_rally_requested)
	upgrades_button.pressed.connect(_on_upgrades_button_pressed)
	partners_button.pressed.connect(_on_partners_button_pressed)
	settlement_button.pressed.connect(_on_settlement_button_pressed)
	prestige_button.pressed.connect(_on_prestige_button_pressed)
	upgrade_sheet.character_level_upgrade_requested.connect(_on_character_level_upgrade_requested)
	upgrade_sheet.autoclick_purchase_requested.connect(_on_autoclick_purchase_requested)
	upgrade_sheet.gold_bonus_purchase_requested.connect(_on_gold_bonus_purchase_requested)
	upgrade_sheet.focus_burst_purchase_requested.connect(_on_focus_burst_purchase_requested)
	upgrade_sheet.rally_purchase_requested.connect(_on_rally_purchase_requested)
	partner_sheet.partner_purchase_requested.connect(_on_partner_purchase_requested)
	settlement_sheet.building_purchase_requested.connect(_on_building_purchase_requested)
	prestige_sheet.prestige_requested.connect(_on_prestige_requested)
	prestige_sheet.prestige_talent_purchase_requested.connect(_on_prestige_talent_purchase_requested)
	prestige_confirm_dialog.confirmed.connect(_on_prestige_confirmed)
	prestige_confirm_dialog.cancelled.connect(_on_prestige_cancelled)
	upgrade_sheet.closed.connect(_on_sheet_closed)
	partner_sheet.closed.connect(_on_sheet_closed)
	settlement_sheet.closed.connect(_on_sheet_closed)
	prestige_sheet.closed.connect(_on_sheet_closed)
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

		var current_autoclick_interval: float = _get_current_autoclick_interval()
		while autoclick_accumulator + autoclick_interval_epsilon >= current_autoclick_interval and state.autoclick_active:
			autoclick_accumulator -= current_autoclick_interval
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
	_update_bottom_bar_view()
	stats_panel.update_view(state)
	game_field.update_view(state)
	game_field.update_boss_timer(boss_time_left, boss_timer_active)
	ability_bar.update_view(
		state,
		autoclick_time_left,
		gold_bonus_time_left,
		autoclick_cooldown_left,
		gold_bonus_cooldown_left,
		focus_burst_time_left,
		rally_time_left,
		focus_burst_cooldown_left,
		rally_cooldown_left
	)
	upgrade_sheet.update_view(state)
	partner_sheet.update_view(state)
	settlement_sheet.update_view(state)
	prestige_sheet.update_view(state)


func _on_attack_requested() -> void:
	var result: Dictionary = state.attack()
	_apply_attack_result(result, true)


func _on_character_level_upgrade_requested(mode: String) -> void:
	var result: Dictionary = state.buy_character_level_upgrades(mode)
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


func _on_focus_burst_purchase_requested() -> void:
	var result: Dictionary = state.buy_focus_burst_ability()
	status_label.text = result.get("status_text", "")
	_update_ui()


func _on_rally_purchase_requested() -> void:
	var result: Dictionary = state.buy_rally_ability()
	status_label.text = result.get("status_text", "")
	_update_ui()


func _on_partner_purchase_requested(partner_index: int, mode: String) -> void:
	var result: Dictionary = state.buy_partners(partner_index, mode)
	status_label.text = result.get("status_text", "")
	_update_ui()


func _on_building_purchase_requested(building_index: int, mode: String) -> void:
	var result: Dictionary = state.buy_buildings(building_index, mode)
	status_label.text = result.get("status_text", "")
	_update_ui()


func _on_upgrades_button_pressed() -> void:
	partner_sheet.hide_sheet()
	settlement_sheet.hide_sheet()
	prestige_sheet.hide_sheet()
	upgrade_sheet.show_sheet()
	active_bottom_tab = "upgrades"
	_update_bottom_bar_view()


func _on_partners_button_pressed() -> void:
	upgrade_sheet.hide_sheet()
	settlement_sheet.hide_sheet()
	prestige_sheet.hide_sheet()
	partner_sheet.show_sheet()
	active_bottom_tab = "partners"
	_update_bottom_bar_view()


func _on_settlement_button_pressed() -> void:
	upgrade_sheet.hide_sheet()
	partner_sheet.hide_sheet()
	prestige_sheet.hide_sheet()
	settlement_sheet.show_sheet()
	active_bottom_tab = "settlement"
	_update_bottom_bar_view()


func _on_prestige_button_pressed() -> void:
	upgrade_sheet.hide_sheet()
	partner_sheet.hide_sheet()
	settlement_sheet.hide_sheet()
	prestige_sheet.show_sheet()
	active_bottom_tab = "prestige"
	_update_bottom_bar_view()


func _on_prestige_requested() -> void:
	prestige_sheet.show_prestige_confirm(state)


func _on_prestige_talent_purchase_requested(talent_index: int) -> void:
	var result: Dictionary = state.buy_prestige_talent(talent_index)
	status_label.text = result.get("status_text", "")
	_update_ui()


func _on_prestige_confirmed() -> void:
	var result: Dictionary = state.perform_prestige()
	boss_time_left = 0.0
	boss_timer_active = false
	autoclick_time_left = 0.0
	gold_bonus_time_left = 0.0
	focus_burst_time_left = 0.0
	rally_time_left = 0.0
	autoclick_cooldown_left = 0.0
	gold_bonus_cooldown_left = 0.0
	focus_burst_cooldown_left = 0.0
	rally_cooldown_left = 0.0
	autoclick_accumulator = 0.0
	partner_damage_accumulator = 0.0
	status_label.text = result.get("status_text", "")
	_update_ui()
	_sync_boss_timer()


func _on_prestige_cancelled() -> void:
	prestige_confirm_dialog.hide()


func _update_bottom_bar_view() -> void:
	upgrades_button.text = "[Upgrades]" if active_bottom_tab == "upgrades" else "Upgrades"
	partners_button.text = "[Partners]" if active_bottom_tab == "partners" else "Partners"
	settlement_button.text = "[Settlement]" if active_bottom_tab == "settlement" else "Settlement"
	prestige_button.text = "[Prestige]" if active_bottom_tab == "prestige" else "Prestige"


func _on_sheet_closed() -> void:
	active_bottom_tab = ""
	_update_bottom_bar_view()


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
		game_field.play_defeat_feedback(result.get("level_up", false), result.get("zone_changed", false))

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
	if not state.autoclick_purchased or state.autoclick_active or autoclick_cooldown_left > 0.0:
		return

	state.autoclick_active = true
	autoclick_time_left = _get_scaled_duration(autoclick_duration, false)
	autoclick_accumulator = 0.0
	_update_ui()


func _on_gold_bonus_requested() -> void:
	if not state.gold_bonus_purchased or state.gold_bonus_active or gold_bonus_cooldown_left > 0.0:
		return

	state.gold_bonus_active = true
	gold_bonus_time_left = _get_scaled_duration(gold_bonus_duration, false)
	_update_ui()


func _on_focus_burst_requested() -> void:
	if not state.focus_burst_purchased or state.focus_burst_active or focus_burst_cooldown_left > 0.0:
		return

	state.focus_burst_active = true
	focus_burst_time_left = _get_scaled_duration(focus_burst_duration, true)
	state.refresh_derived_stats()
	_update_ui()


func _on_rally_requested() -> void:
	if not state.rally_purchased or state.rally_active or rally_cooldown_left > 0.0:
		return

	state.rally_active = true
	rally_time_left = _get_scaled_duration(rally_duration, true)
	_update_ui()


func _process_ability_timers(delta: float) -> void:
	var needs_full_ui_update: bool = false

	if state.autoclick_active:
		autoclick_time_left = maxf(autoclick_time_left - delta, 0.0)
		if autoclick_time_left <= 0.0:
			state.autoclick_active = false
			autoclick_accumulator = 0.0
			autoclick_cooldown_left = _get_scaled_cooldown(autoclick_cooldown_duration)

	if state.gold_bonus_active:
		gold_bonus_time_left = maxf(gold_bonus_time_left - delta, 0.0)
		if gold_bonus_time_left <= 0.0:
			state.gold_bonus_active = false
			gold_bonus_cooldown_left = _get_scaled_cooldown(gold_bonus_cooldown_duration)

	if state.focus_burst_active:
		focus_burst_time_left = maxf(focus_burst_time_left - delta, 0.0)
		if focus_burst_time_left <= 0.0:
			state.focus_burst_active = false
			focus_burst_cooldown_left = _get_scaled_cooldown(focus_burst_cooldown_duration)
			state.refresh_derived_stats()
			needs_full_ui_update = true

	if state.rally_active:
		rally_time_left = maxf(rally_time_left - delta, 0.0)
		if rally_time_left <= 0.0:
			state.rally_active = false
			rally_cooldown_left = _get_scaled_cooldown(rally_cooldown_duration)

	if autoclick_cooldown_left > 0.0:
		autoclick_cooldown_left = maxf(autoclick_cooldown_left - delta, 0.0)

	if gold_bonus_cooldown_left > 0.0:
		gold_bonus_cooldown_left = maxf(gold_bonus_cooldown_left - delta, 0.0)

	if focus_burst_cooldown_left > 0.0:
		focus_burst_cooldown_left = maxf(focus_burst_cooldown_left - delta, 0.0)

	if rally_cooldown_left > 0.0:
		rally_cooldown_left = maxf(rally_cooldown_left - delta, 0.0)

	if needs_full_ui_update:
		_update_ui()
		return

	ability_bar.update_view(
		state,
		autoclick_time_left,
		gold_bonus_time_left,
		autoclick_cooldown_left,
		gold_bonus_cooldown_left,
		focus_burst_time_left,
		rally_time_left,
		focus_burst_cooldown_left,
		rally_cooldown_left
	)


func _get_current_autoclick_interval() -> float:
	return maxf(0.02, autoclick_interval / state.get_quick_hands_multiplier())


func _get_scaled_duration(base_duration: float, uses_war_banner: bool) -> float:
	if not uses_war_banner:
		return base_duration

	return base_duration * state.get_ability_duration_multiplier()


func _get_scaled_cooldown(base_cooldown: float) -> float:
	return base_cooldown * state.get_ability_cooldown_multiplier()


func _apply_passive_attack_result(result: Dictionary) -> void:
	if result.get("defeated", false):
		game_field.play_defeat_feedback(result.get("level_up", false), result.get("zone_changed", false))
		status_label.text = result.get("status_text", "")

	_update_ui()
	_sync_boss_timer()
