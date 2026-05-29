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
var enemy_transition_locked: bool = false
var enemy_respawn_delay: float = 0.2
var enemy_transition_token: int = 0
var combo_meter_value: float = 0.0
var combo_meter_max: float = 100.0
var combo_gain_per_manual_click: float = 1.0
var combo_decay_per_second: float = 1.0
var combo_empowered_active: bool = false
var combo_empowered_time_left: float = 0.0
var combo_empowered_duration: float = 10.0
var combo_empowered_multiplier: float = 3.0

@onready var primary_stats_panel: PrimaryStatsPanel = $PrimaryStatsPanel
@onready var progress_info_panel: ProgressInfoPanel = $MainContent/VBoxContainer/ProgressInfoPanel
@onready var combo_panel: ComboPanel = $ComboPanel
@onready var tasks_button: Button = $TasksButton
@onready var tasks_window: TasksWindow = $TasksWindow
@onready var game_field: GameField = $GameField
@onready var ability_bar: AbilityBar = $AbilityBar
@onready var upgrades_button: Button = $BottomBar/MarginContainer/HBoxContainer/UpgradesButton
@onready var partners_button: Button = $BottomBar/MarginContainer/HBoxContainer/PartnersButton
@onready var settlement_button: Button = $BottomBar/MarginContainer/HBoxContainer/SettlementButton
@onready var prestige_button: Button = $BottomBar/MarginContainer/HBoxContainer/PrestigeButton
@onready var shop_button: Button = $BottomBar/MarginContainer/HBoxContainer/ShopButton
@onready var upgrade_sheet: UpgradeSheet = $UpgradeSheet
@onready var partner_sheet: PartnerSheet = $PartnerSheet
@onready var settlement_sheet: SettlementSheet = $SettlementSheet
@onready var prestige_sheet: PrestigeSheet = $PrestigeSheet
@onready var shop_sheet: ShopSheet = $ShopSheet
@onready var prestige_confirm_dialog: PrestigeConfirmDialog = $PrestigeSheet/PrestigeConfirmDialog


func _ready() -> void:
	game_field.attack_requested.connect(_on_attack_requested)
	ability_bar.autoclick_requested.connect(_on_autoclick_requested)
	ability_bar.gold_bonus_requested.connect(_on_gold_bonus_requested)
	ability_bar.focus_burst_requested.connect(_on_focus_burst_requested)
	ability_bar.rally_requested.connect(_on_rally_requested)
	primary_stats_panel.settings_requested.connect(_on_settings_requested)
	tasks_button.pressed.connect(_on_tasks_button_pressed)
	tasks_window.task_claim_requested.connect(_on_task_claim_requested)
	upgrades_button.pressed.connect(_on_upgrades_button_pressed)
	partners_button.pressed.connect(_on_partners_button_pressed)
	settlement_button.pressed.connect(_on_settlement_button_pressed)
	prestige_button.pressed.connect(_on_prestige_button_pressed)
	shop_button.pressed.connect(_on_shop_button_pressed)
	upgrade_sheet.character_level_upgrade_requested.connect(_on_character_level_upgrade_requested)
	upgrade_sheet.autoclick_purchase_requested.connect(_on_autoclick_purchase_requested)
	upgrade_sheet.gold_bonus_purchase_requested.connect(_on_gold_bonus_purchase_requested)
	upgrade_sheet.focus_burst_purchase_requested.connect(_on_focus_burst_purchase_requested)
	upgrade_sheet.rally_purchase_requested.connect(_on_rally_purchase_requested)
	partner_sheet.partner_purchase_requested.connect(_on_partner_purchase_requested)
	partner_sheet.skill_purchase_requested.connect(_on_partner_skill_purchase_requested)
	settlement_sheet.building_purchase_requested.connect(_on_building_purchase_requested)
	prestige_sheet.prestige_requested.connect(_on_prestige_requested)
	prestige_sheet.prestige_talent_purchase_requested.connect(_on_prestige_talent_purchase_requested)
	shop_sheet.product_purchase_requested.connect(_on_shop_product_purchase_requested)
	shop_sheet.test_gems_requested.connect(_on_test_gems_requested)
	prestige_confirm_dialog.confirmed.connect(_on_prestige_confirmed)
	prestige_confirm_dialog.cancelled.connect(_on_prestige_cancelled)
	upgrade_sheet.closed.connect(_on_sheet_closed)
	partner_sheet.closed.connect(_on_sheet_closed)
	settlement_sheet.closed.connect(_on_sheet_closed)
	prestige_sheet.closed.connect(_on_sheet_closed)
	shop_sheet.closed.connect(_on_sheet_closed)
	_update_ui()
	_sync_boss_timer()


func _process(delta: float) -> void:
	_process_combo_meter(delta)

	if boss_timer_active and not enemy_transition_locked:
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

	if state.get_base_partner_dps() > 0:
		partner_damage_accumulator += delta

		while partner_damage_accumulator + partner_damage_interval_epsilon >= partner_damage_interval:
			partner_damage_accumulator -= partner_damage_interval
			_run_partner_damage_tick()
	else:
		partner_damage_accumulator = 0.0


func _update_ui() -> void:
	_update_bottom_bar_view()
	primary_stats_panel.update_view(state)
	progress_info_panel.update_view(state)
	_update_combo_panel()
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
	shop_sheet.update_view(state)
	if tasks_window.visible:
		tasks_window.refresh_progress_only(state)


func _on_attack_requested() -> void:
	if tasks_window.visible:
		return

	if enemy_transition_locked:
		return

	if not combo_empowered_active:
		combo_meter_value = clampf(
			combo_meter_value + combo_gain_per_manual_click * state.get_partner_skill_bonus_multiplier("combo_gain"),
			0.0,
			combo_meter_max
		)
		if combo_meter_value >= combo_meter_max:
			combo_meter_value = combo_meter_max
			combo_empowered_active = true
			combo_empowered_time_left = combo_empowered_duration
			state.total_combo_empowered_activations += 1

	var manual_damage: int = maxi(1, int(state.get_current_click_damage() * _get_manual_combo_multiplier()))
	if state.rng.randf() < state.get_partner_skill_additive_bonus("critical_manual"):
		manual_damage *= 2
	var was_boss_level: bool = state.is_boss_level
	var result: Dictionary = state.attack_with_damage(manual_damage)
	state.total_manual_click_damage_dealt += int(result.get("damage_dealt", 0))
	_apply_attack_result(result, true, was_boss_level)


func _on_character_level_upgrade_requested(mode: String) -> void:
	var result: Dictionary = state.buy_character_level_upgrades(mode)
	_handle_status_text(result.get("status_text", ""))
	_update_ui()


func _on_autoclick_purchase_requested() -> void:
	var result: Dictionary = state.buy_or_upgrade_ability("autoclick")
	_handle_status_text(result.get("status_text", ""))
	_update_ui()


func _on_gold_bonus_purchase_requested() -> void:
	var result: Dictionary = state.buy_or_upgrade_ability("gold_bonus")
	_handle_status_text(result.get("status_text", ""))
	_update_ui()


func _on_focus_burst_purchase_requested() -> void:
	var result: Dictionary = state.buy_or_upgrade_ability("focus_burst")
	_handle_status_text(result.get("status_text", ""))
	_update_ui()


func _on_rally_purchase_requested() -> void:
	var result: Dictionary = state.buy_or_upgrade_ability("rally")
	_handle_status_text(result.get("status_text", ""))
	_update_ui()


func _on_settings_requested() -> void:
	_handle_status_text("Settings coming soon")


func _on_tasks_button_pressed() -> void:
	tasks_window.show_window(state)


func _on_task_claim_requested(task_id: String) -> void:
	var result: Dictionary = state.claim_task_reward(task_id)
	_handle_status_text(result.get("status_text", ""))
	_update_ui()
	if tasks_window.visible:
		tasks_window.request_full_rebuild(state)


func _on_partner_purchase_requested(partner_index: int, mode: String) -> void:
	var result: Dictionary = state.buy_partners(partner_index, mode)
	_handle_status_text(result.get("status_text", ""))
	_update_ui()


func _on_partner_skill_purchase_requested(skill_id: String) -> void:
	var result: Dictionary = state.buy_partner_skill(skill_id)
	_handle_status_text(result.get("status_text", ""))
	_update_ui()


func _on_building_purchase_requested(building_index: int, mode: String) -> void:
	var result: Dictionary = state.buy_buildings(building_index, mode)
	_handle_status_text(result.get("status_text", ""))
	_update_ui()


func _on_upgrades_button_pressed() -> void:
	_toggle_bottom_sheet("upgrades")


func _on_partners_button_pressed() -> void:
	_toggle_bottom_sheet("partners")


func _on_settlement_button_pressed() -> void:
	_toggle_bottom_sheet("settlement")


func _on_prestige_button_pressed() -> void:
	_toggle_bottom_sheet("prestige")


func _on_shop_button_pressed() -> void:
	_toggle_bottom_sheet("shop")


func _on_prestige_requested() -> void:
	prestige_sheet.show_prestige_confirm(state)


func _on_prestige_talent_purchase_requested(talent_index: int) -> void:
	var result: Dictionary = state.buy_prestige_talent(talent_index)
	_handle_status_text(result.get("status_text", ""))
	_update_ui()


func _on_shop_product_purchase_requested(product_id: String) -> void:
	var result: Dictionary = state.buy_shop_product(product_id)
	_handle_status_text(result.get("status_text", ""))
	if result.has("combo_fill"):
		_fill_combo_meter_from_shop(float(result.get("combo_fill", combo_meter_max)))
	_update_ui()


func _on_test_gems_requested() -> void:
	var result: Dictionary = state.grant_test_gems(50)
	_handle_status_text(result.get("status_text", ""))
	_update_ui()


func _on_prestige_confirmed() -> void:
	var result: Dictionary = state.perform_prestige()
	enemy_transition_locked = false
	enemy_transition_token += 1
	game_field.set_enemy_transition_locked(false)
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
	combo_meter_value = 0.0
	combo_empowered_active = false
	combo_empowered_time_left = 0.0
	_handle_status_text(result.get("status_text", ""))
	_update_ui()
	_sync_boss_timer()


func _on_prestige_cancelled() -> void:
	prestige_confirm_dialog.hide()


func _update_bottom_bar_view() -> void:
	upgrades_button.text = "[Upgrades]" if active_bottom_tab == "upgrades" else "Upgrades"
	partners_button.text = "[Partners]" if active_bottom_tab == "partners" else "Partners"
	settlement_button.text = "[Settlement]" if active_bottom_tab == "settlement" else "Settlement"
	prestige_button.text = "[Prestige]" if active_bottom_tab == "prestige" else "Prestige"
	shop_button.text = "[Shop]" if active_bottom_tab == "shop" else "Shop"


func _toggle_bottom_sheet(tab_name: String) -> void:
	if active_bottom_tab == tab_name:
		_hide_all_bottom_sheets()
		active_bottom_tab = ""
		_update_bottom_bar_view()
		return

	_hide_all_bottom_sheets()
	match tab_name:
		"upgrades":
			upgrade_sheet.show_sheet()
		"partners":
			partner_sheet.show_sheet()
		"settlement":
			settlement_sheet.show_sheet()
		"prestige":
			prestige_sheet.show_sheet()
		"shop":
			shop_sheet.show_sheet()

	active_bottom_tab = tab_name
	_update_bottom_bar_view()


func _hide_all_bottom_sheets() -> void:
	upgrade_sheet.hide_sheet()
	partner_sheet.hide_sheet()
	settlement_sheet.hide_sheet()
	prestige_sheet.hide_sheet()
	shop_sheet.hide_sheet()


func _on_sheet_closed() -> void:
	active_bottom_tab = ""
	_update_bottom_bar_view()


func _sync_boss_timer() -> void:
	if state.is_boss_level:
		if not boss_timer_active:
			boss_time_left = state.boss_time_limit * state.get_boss_timer_multiplier()
			boss_timer_active = true
	else:
		boss_timer_active = false
		boss_time_left = 0.0

	game_field.update_boss_timer(boss_time_left, boss_timer_active)


func _fail_boss_level() -> void:
	boss_timer_active = false
	var result: Dictionary = state.fail_boss_level()
	boss_time_left = 0.0
	_handle_status_text(result.get("status_text", ""))
	_update_ui()
	_sync_boss_timer()


func _apply_attack_result(result: Dictionary, show_hit_feedback: bool, was_boss_level: bool = false) -> void:
	if result.get("defeated", false):
		_handle_defeat_result(result, was_boss_level)
		return

	if show_hit_feedback:
		game_field.play_hit_feedback(result.get("damage_dealt", 0))
	_handle_status_text(result.get("status_text", ""))
	_update_ui()
	_sync_boss_timer()


func _run_autoclick_attack() -> void:
	if enemy_transition_locked:
		return

	var was_boss_level: bool = state.is_boss_level
	var result: Dictionary = state.attack_with_damage(state.get_autoclick_damage())
	_apply_attack_result(result, true, was_boss_level)


func _run_partner_damage_tick() -> void:
	if enemy_transition_locked:
		return

	var tick_damage: int = state.get_partner_tick_damage()
	if tick_damage <= 0:
		return

	var was_boss_level: bool = state.is_boss_level
	var result: Dictionary = state.attack_with_damage(tick_damage)
	_apply_attack_result(result, false, was_boss_level)


func _on_autoclick_requested() -> void:
	if not state.autoclick_purchased or state.autoclick_active or autoclick_cooldown_left > 0.0:
		return

	state.autoclick_active = true
	var rank_bonus_seconds: float = 2.0 * maxi(0, state.autoclick_rank - 1)
	autoclick_time_left = _get_scaled_duration(autoclick_duration + rank_bonus_seconds, false)
	autoclick_accumulator = 0.0
	state.total_autoclick_activations += 1
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
	return maxf(0.02, autoclick_interval / (state.get_quick_hands_multiplier() * state.get_autoclick_rank_rate_multiplier()))


func _get_scaled_duration(base_duration: float, uses_war_banner: bool) -> float:
	if not uses_war_banner:
		return base_duration

	return base_duration * state.get_ability_duration_multiplier()


func _get_scaled_cooldown(base_cooldown: float) -> float:
	return base_cooldown * state.get_ability_cooldown_multiplier()


func _process_combo_meter(delta: float) -> void:
	if combo_empowered_active:
		combo_empowered_time_left = maxf(combo_empowered_time_left - delta, 0.0)
		combo_meter_value = combo_meter_max
		if combo_empowered_time_left <= 0.0:
			combo_empowered_active = false
			combo_meter_value = 0.0
		_update_combo_panel()
		return

	if combo_meter_value > 0.0:
		combo_meter_value = maxf(combo_meter_value - combo_decay_per_second * delta, 0.0)
		_update_combo_panel()


func _get_manual_combo_multiplier() -> float:
	if combo_empowered_active:
		return combo_empowered_multiplier

	return 1.0 + combo_meter_value / 100.0


func _update_combo_panel() -> void:
	combo_panel.update_view(
		combo_meter_value,
		_get_manual_combo_multiplier(),
		combo_empowered_active,
		combo_empowered_time_left
	)


func _fill_combo_meter_from_shop(amount: float) -> void:
	combo_meter_value = clampf(amount, 0.0, combo_meter_max)
	if combo_meter_value >= combo_meter_max:
		combo_meter_value = combo_meter_max
		combo_empowered_active = true
		combo_empowered_time_left = combo_empowered_duration
		state.total_combo_empowered_activations += 1


func _handle_defeat_result(result: Dictionary, was_boss_level: bool) -> void:
	enemy_transition_locked = true
	enemy_transition_token += 1
	var transition_token: int = enemy_transition_token
	game_field.set_enemy_transition_locked(true)
	game_field.play_defeat_feedback(result.get("level_up", false), result.get("zone_changed", false))
	_handle_status_text(result.get("status_text", ""))

	if was_boss_level:
		boss_timer_active = false
		boss_time_left = 0.0
		game_field.update_boss_timer(boss_time_left, boss_timer_active)

	_update_ui()
	_finish_enemy_transition_after_delay(transition_token)


func _handle_status_text(_text: String) -> void:
	pass


func _finish_enemy_transition_after_delay(transition_token: int) -> void:
	await get_tree().create_timer(enemy_respawn_delay).timeout
	if transition_token != enemy_transition_token:
		return

	var result: Dictionary = state.resolve_defeated_target()
	_handle_status_text(result.get("status_text", ""))
	enemy_transition_locked = false
	game_field.set_enemy_transition_locked(false)
	_update_ui()
	_sync_boss_timer()
	game_field.update_view(state)
