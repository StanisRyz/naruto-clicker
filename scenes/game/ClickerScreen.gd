extends Control

signal startup_completed

const GemPurchaseDialogClass = preload("res://scenes/ui/GemPurchaseDialog.gd")
const GemPurchaseConfigClass = preload("res://scripts/game/config/GemPurchaseConfig.gd")

const TASK_BUTTON_DEFAULT_ASSET_KEY: String = "task.window_button.default"
const TASK_BUTTON_COMPLETED_ASSET_KEY: String = "task.window_button.completed"
const DEBUG_VISUAL_TEST_GEMS: int = 999

var state: ClickerState = ClickerState.new()
var boss_time_left: float = 0.0
var boss_timer_active: bool = false
var autoclick_accumulator: float = 0.0
var autoclick_time_left: float = 0.0
var gold_bonus_time_left: float = 0.0
var focus_burst_time_left: float = 0.0
var rally_time_left: float = 0.0
var autoclick_duration: float = BalanceConfig.AUTOCLICK_BASE_DURATION_SEC
var autoclick_cooldown_duration: float = BalanceConfig.AUTOCLICK_COOLDOWN_SEC
var autoclick_cooldown_left: float = 0.0
var gold_bonus_duration: float = BalanceConfig.GOLD_BONUS_BASE_DURATION_SEC
var gold_bonus_cooldown_duration: float = BalanceConfig.GOLD_BONUS_COOLDOWN_SEC
var gold_bonus_cooldown_left: float = 0.0
var focus_burst_duration: float = BalanceConfig.FOCUS_BURST_BASE_DURATION_SEC
var focus_burst_cooldown_duration: float = BalanceConfig.FOCUS_BURST_COOLDOWN_SEC
var focus_burst_cooldown_left: float = 0.0
var rally_duration: float = BalanceConfig.RALLY_BASE_DURATION_SEC
var rally_cooldown_duration: float = BalanceConfig.RALLY_COOLDOWN_SEC
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
const ENEMY_SPAWN_SMOKE_DURATION: float = 0.3
const ENEMY_SPAWN_INVULNERABILITY_DURATION: float = 0.1
const BOTTOM_TAB_BUTTON_FALLBACK_COLOR: Color = Color(1, 1, 1, 1)
const HIT_EFFECT_ASSET_KEYS: Array[String] = [
	"combat.hit_effect.1",
	"combat.hit_effect.2",
	"combat.hit_effect.3",
]
const HIT_EFFECT_SIZE: Vector2 = Vector2(128, 128)
const HIT_EFFECT_DURATION_SEC: float = 0.1
var _autosave_timer: float = 0.0
const _AUTOSAVE_INTERVAL: float = 10.0
var _debug_pause_log_timer: float = 0.0
const _DEBUG_PAUSE_LOG_INTERVAL: float = 3.0
var _rewarded_ad_reward_granted_for_current_request: bool = false
var _rewarded_ad_damage_buff_was_active: bool = false
var _rewarded_ad_gold_buff_was_active: bool = false
var _rewarded_ad_request_context: String = ""
var _rewarded_ad_shop_product_id: String = ""
var balance_logger: BalancePlaytestLogger = null
var _is_initialized: bool = false
var _debug_visual_test_previous_gems: int = 0
var _pending_shop_product_id: String = ""
var _pending_payment_product_id: String = ""
var _payment_reward_granted_for_current_request: bool = false
var _unprocessed_purchase_check_requested: bool = false
var _runtime_pause_reasons: Dictionary = {}
var _runtime_pause_started_unix_time: int = 0
var _yandex_game_ready_notified: bool = false

const FULLSCREEN_AD_COOLDOWN_SECONDS: float = 300.0
const FULLSCREEN_AD_INITIAL_COOLDOWN_SECONDS: float = 300.0
const FULLSCREEN_AD_SAFE_INTERACTION_GAP_SECONDS: float = 2.5
const YANDEX_PURCHASE_RECOVERY_MAX_READY_ATTEMPTS: int = 20
const YANDEX_PURCHASE_RECOVERY_RETRY_DELAY_SEC: float = 0.5
var _fullscreen_ad_cooldown_left: float = FULLSCREEN_AD_INITIAL_COOLDOWN_SECONDS
var _last_user_interaction_time: float = -999.0
var _fullscreen_ad_overlay: Control = null

@onready var top_interface_image_holder = $TopInterfaceImageHolder
@onready var combat_effects_layer: CombatEffectsLayer = $CombatEffectsLayer
@onready var primary_stats_panel: PrimaryStatsPanel = $PrimaryStatsPanel
@onready var stage_navigator: Control = $MainContent/VBoxContainer/StageNavigator
@onready var auto_transition_popup: Control = $AutoTransitionPopup
@onready var progress_info_panel: ProgressInfoPanel = $MainContent/VBoxContainer/ProgressInfoPanel
@onready var tasks_button: Button = $TasksButton
@onready var tasks_button_image_holder = $TasksButton/ImageHolder
@onready var tasks_window: TasksWindow = $TasksWindow
@onready var settings_window: SettingsWindow = $SettingsWindow
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
@onready var prestige_confirm_dialog: PrestigeConfirmDialog = $PrestigeConfirmDialog
@onready var shop_purchase_confirm_dialog: ShopPurchaseConfirmDialog = $ShopPurchaseConfirmDialog
@onready var gem_purchase_dialog: GemPurchaseDialogClass = $GemPurchaseDialog
@onready var upgrades_button_image = $BottomBar/MarginContainer/HBoxContainer/UpgradesButton/ImageHolder
@onready var partners_button_image = $BottomBar/MarginContainer/HBoxContainer/PartnersButton/ImageHolder
@onready var settlement_button_image = $BottomBar/MarginContainer/HBoxContainer/SettlementButton/ImageHolder
@onready var prestige_button_image = $BottomBar/MarginContainer/HBoxContainer/PrestigeButton/ImageHolder
@onready var shop_button_image = $BottomBar/MarginContainer/HBoxContainer/ShopButton/ImageHolder
@onready var bottom_tabs_backdrop = $BottomTabsBackdrop
@onready var rewarded_ad_banner: Control = $RewardedAdBanner
@onready var hit_effect_layer: Control = $HitEffectLayer
@onready var offline_reward_dialog: OfflineRewardDialog = $OfflineRewardDialog


func _ready() -> void:
	stage_navigator.stage_selected.connect(_on_stage_selected)
	stage_navigator.latest_requested.connect(_on_stage_latest_requested)
	stage_navigator.auto_transition_popup_requested.connect(_on_auto_transition_popup_requested)
	auto_transition_popup.auto_button_pressed_through.connect(_toggle_auto_transition_and_show_popup)
	game_field.attack_requested.connect(_on_attack_requested)
	ability_bar.autoclick_requested.connect(_on_autoclick_requested)
	ability_bar.gold_bonus_requested.connect(_on_gold_bonus_requested)
	ability_bar.focus_burst_requested.connect(_on_focus_burst_requested)
	ability_bar.rally_requested.connect(_on_rally_requested)
	primary_stats_panel.settings_requested.connect(_on_settings_requested)
	tasks_button.pressed.connect(_on_tasks_button_pressed)
	tasks_window.task_claim_requested.connect(_on_task_claim_requested)
	settings_window.sound_toggled.connect(_on_settings_sound_toggled)
	settings_window.music_toggled.connect(_on_settings_music_toggled)
	settings_window.save_requested.connect(_on_settings_save_requested)
	settings_window.reset_requested.connect(_on_settings_reset_confirmed)
	settings_window.language_manually_changed.connect(_on_language_manually_changed)
	settings_window.account_auth_requested.connect(_on_settings_account_auth_requested)
	settings_window.cloud_save_upload_requested.connect(_on_settings_cloud_save_upload_requested)
	settings_window.cloud_save_download_requested.connect(_on_settings_cloud_save_download_requested)
	Platform.backend_operation_succeeded.connect(_on_backend_cloud_op_succeeded)
	Platform.backend_operation_failed.connect(_on_backend_cloud_op_failed)
	upgrades_button.pressed.connect(_on_upgrades_button_pressed)
	partners_button.pressed.connect(_on_partners_button_pressed)
	settlement_button.pressed.connect(_on_settlement_button_pressed)
	prestige_button.pressed.connect(_on_prestige_button_pressed)
	shop_button.pressed.connect(_on_shop_button_pressed)
	upgrade_sheet.character_level_upgrade_requested.connect(_on_character_level_upgrade_requested)
	upgrade_sheet.hero_skill_purchase_requested.connect(_on_hero_skill_purchase_requested)
	upgrade_sheet.ability_skill_purchase_requested.connect(_on_ability_skill_purchase_requested)
	upgrade_sheet.ability_unlock_requested.connect(_on_ability_unlock_requested)
	partner_sheet.partner_purchase_requested.connect(_on_partner_purchase_requested)
	partner_sheet.skill_purchase_requested.connect(_on_partner_skill_purchase_requested)
	settlement_sheet.building_purchase_requested.connect(_on_building_purchase_requested)
	prestige_sheet.prestige_requested.connect(_on_prestige_requested)
	prestige_sheet.prestige_talent_purchase_requested.connect(_on_prestige_talent_purchase_requested)
	shop_sheet.product_purchase_requested.connect(_on_shop_product_purchase_requested)
	shop_purchase_confirm_dialog.confirmed.connect(_on_shop_purchase_confirmed)
	shop_purchase_confirm_dialog.cancelled.connect(_on_shop_purchase_cancelled)
	gem_purchase_dialog.gem_product_purchase_requested.connect(_on_gem_product_purchase_requested)
	Platform.payment_purchase_success.connect(_on_payment_purchase_success)
	Platform.payment_purchase_cancelled.connect(_on_payment_purchase_cancelled)
	Platform.payment_purchase_error.connect(_on_payment_purchase_error)
	Platform.unprocessed_purchase_found.connect(_on_unprocessed_purchase_found)
	Platform.unprocessed_purchase_check_error.connect(_on_unprocessed_purchase_check_error)
	prestige_confirm_dialog.confirmed.connect(_on_prestige_confirmed)
	prestige_confirm_dialog.cancelled.connect(_on_prestige_cancelled)
	upgrade_sheet.closed.connect(_on_sheet_closed)
	partner_sheet.closed.connect(_on_sheet_closed)
	settlement_sheet.closed.connect(_on_sheet_closed)
	prestige_sheet.closed.connect(_on_sheet_closed)
	shop_sheet.closed.connect(_on_sheet_closed)
	rewarded_ad_banner.reward_ad_requested.connect(_on_rewarded_ad_banner_pressed)
	Platform.rewarded_ad_opened.connect(_on_rewarded_ad_opened)
	Platform.rewarded_ad_rewarded.connect(_on_rewarded_ad_rewarded)
	Platform.rewarded_ad_closed.connect(_on_rewarded_ad_closed)
	Platform.rewarded_ad_error.connect(_on_rewarded_ad_error)
	offline_reward_dialog.claim_requested.connect(_on_offline_reward_claim_requested)
	offline_reward_dialog.claim_ad_requested.connect(_on_offline_reward_claim_ad_requested)
	LocalizationManager.language_changed.connect(_on_language_changed)
	Platform.fullscreen_ad_opened.connect(_on_fullscreen_ad_opened)
	Platform.fullscreen_ad_closed.connect(_on_fullscreen_ad_closed)
	Platform.fullscreen_ad_error.connect(_on_fullscreen_ad_error)
	Platform.platform_pause_requested.connect(_on_yandex_platform_pause_requested)
	Platform.platform_resume_requested.connect(_on_yandex_platform_resume_requested)
	AudioManager.page_visibility_changed.connect(_on_page_visibility_changed)
	_create_fullscreen_ad_overlay()
	_apply_ui_font_sizes()
	_apply_button_visual_cleanup()
	bottom_tabs_backdrop.set_asset_key("ui.bottom_tabs.backdrop", Color.TRANSPARENT)
	await _load_game_on_start_async()
	_request_unprocessed_purchase_check_when_ready()
	AudioManager.set_music_enabled(state.music_enabled)
	AudioManager.set_sound_enabled(state.sound_enabled)
	AudioManager.play_main_music()
	AudioManager.bind_buttons_in_tree(self)
	_apply_startup_language()
	if not LocalizationManager.has_loaded_translations():
		push_warning("No localization translations loaded. UI will display keys. " + LocalizationManager.get_localization_source_status())
	_is_initialized = true
	_update_ui()
	ButtonVisualUtils.disable_focus_artifacts_in_tree(self)
	_sync_boss_timer()
	if BuildConfig.IS_DEBUG_BUILD:
		balance_logger = BalancePlaytestLogger.new()
		balance_logger.start_session(state)
		balance_logger.mark_enemy_spawned(state)
	startup_completed.emit()
	notify_yandex_game_ready()


func _process(delta: float) -> void:
	_autosave_timer += delta
	if _autosave_timer >= _AUTOSAVE_INTERVAL:
		_autosave_timer = 0.0
		_save_game_now()

	if _is_runtime_paused():
		if BuildConfig.IS_DEBUG_BUILD:
			_debug_pause_log_timer += delta
			if _debug_pause_log_timer >= _DEBUG_PAUSE_LOG_INTERVAL:
				_debug_pause_log_timer = 0.0
				print("ClickerScreen: _process paused. Reasons: %s" % str(_runtime_pause_reasons.keys()))
		return
	_debug_pause_log_timer = 0.0

	if _fullscreen_ad_cooldown_left > 0.0:
		_fullscreen_ad_cooldown_left = maxf(_fullscreen_ad_cooldown_left - delta, 0.0)
	elif _is_initialized:
		_try_show_fullscreen_ad_if_safe()

	if boss_timer_active and not enemy_transition_locked:
		if not state.is_debug_visual_test_mode_enabled():
			boss_time_left = maxf(boss_time_left - delta, 0.0)
		progress_info_panel.update_boss_timer(boss_time_left, boss_timer_active)

		if boss_time_left <= 0.0 and not state.is_debug_visual_test_mode_enabled():
			_fail_boss_level()
			return

	_process_ability_timers(delta)
	_process_rewarded_ad_buff_expiry()

	if state.autoclick_active:
		autoclick_accumulator += delta

		var current_autoclick_interval: float = _get_current_autoclick_interval()
		while autoclick_accumulator + autoclick_interval_epsilon >= current_autoclick_interval and state.autoclick_active:
			autoclick_accumulator -= current_autoclick_interval
			_run_autoclick_attack()
	else:
		autoclick_accumulator = 0.0

	if state.get_base_partner_dps().is_positive():
		partner_damage_accumulator += delta

		while partner_damage_accumulator + partner_damage_interval_epsilon >= partner_damage_interval:
			partner_damage_accumulator -= partner_damage_interval
			_run_partner_damage_tick()
	else:
		partner_damage_accumulator = 0.0


func _update_ui() -> void:
	_sync_debug_visual_test_gems()
	_update_bottom_bar_view()
	_update_main_hud()
	_update_stage_ui()
	_update_combat_ui()
	_update_ability_bar()
	_update_active_sheet()
	_update_tasks_button_image()
	_update_tasks_if_visible()
	_update_settings_if_visible()
	_update_rewarded_ad_banner()


func _update_main_hud() -> void:
	primary_stats_panel.update_view(state)
	progress_info_panel.update_view(state)


func _update_stage_ui() -> void:
	stage_navigator.update_view(state.current_level, state.max_unlocked_level)
	stage_navigator.set_auto_transition_enabled(state.auto_stage_advance_enabled)


func _update_combat_ui() -> void:
	game_field.update_view(state)
	progress_info_panel.update_boss_timer(boss_time_left, boss_timer_active)


func _update_ability_bar() -> void:
	ability_bar.update_view(
		state,
		autoclick_time_left,
		gold_bonus_time_left,
		autoclick_cooldown_left,
		gold_bonus_cooldown_left,
		focus_burst_time_left,
		rally_time_left,
		focus_burst_cooldown_left,
		rally_cooldown_left,
		autoclick_cooldown_duration,
		gold_bonus_cooldown_duration,
		focus_burst_cooldown_duration,
		rally_cooldown_duration,
		_get_autoclick_active_duration(),
		_get_gold_bonus_active_duration(),
		_get_focus_burst_active_duration(),
		_get_rally_active_duration()
	)


func _update_active_sheet() -> void:
	match active_bottom_tab:
		"upgrades":
			upgrade_sheet.update_view(state)
		"partners":
			partner_sheet.update_view(state)
		"settlement":
			settlement_sheet.update_view(state)
		"prestige":
			prestige_sheet.update_view(state)
		"shop":
			shop_sheet.update_view(state)


func _update_tasks_button_image() -> void:
	var asset_key: String = TASK_BUTTON_COMPLETED_ASSET_KEY if state.has_claimable_tasks() else TASK_BUTTON_DEFAULT_ASSET_KEY
	tasks_button_image_holder.set_asset_key(asset_key, Color.WHITE)


func _update_tasks_if_visible() -> void:
	if tasks_window.visible:
		tasks_window.refresh_progress_only(state)


func _update_settings_if_visible() -> void:
	if settings_window.visible:
		settings_window.refresh_view(state)


func _on_attack_requested(click_global_position: Vector2) -> void:
	_mark_user_interaction()
	if _is_runtime_paused():
		return
	if tasks_window.visible:
		return

	if settings_window.visible:
		return

	if enemy_transition_locked:
		return

	var manual_damage: BigNumber = state.get_current_click_damage()
	if manual_damage.is_zero():
		manual_damage = BigNumber.one()
	if state.rng.randf() < state.get_partner_skill_additive_bonus("critical_manual"):
		manual_damage = manual_damage.multiply_int(2)
	var was_boss_level: bool = state.is_boss_level
	var result: Dictionary = state.attack_with_damage(manual_damage)
	var damage_dealt_val = result.get("damage_dealt", 0)
	var damage_dealt: BigNumber = damage_dealt_val if damage_dealt_val is BigNumber else BigNumber.zero()
	state.total_manual_click_damage_dealt += damage_dealt.floor_to_int_safe()
	_apply_attack_result(result, true, was_boss_level)
	if damage_dealt.is_positive():
		game_field.spawn_damage_number(damage_dealt, click_global_position)
		_spawn_hit_effect(click_global_position)


func _on_character_level_upgrade_requested(mode: String) -> void:
	var gold_before: BigNumber = state.gold.clone()
	var result: Dictionary = state.buy_character_level_upgrades(mode)
	_handle_status_text(result.get("status_text", ""))
	if balance_logger:
		balance_logger.log_purchase(state, "hero_level", "hero_level_x%s" % mode, gold_before.subtract(state.gold).floor_to_int_safe(), result)
	_update_ui()
	if result.get("upgraded", false):
		AudioManager.play_purchase_success()
		upgrade_sheet.play_hero_purchase_feedback()
		_save_game_now()
	else:
		AudioManager.play_purchase_error()


func _on_hero_skill_purchase_requested(skill_id: String) -> void:
	var gold_before: BigNumber = state.gold.clone()
	var result: Dictionary = state.buy_hero_skill(skill_id)
	_handle_status_text(result.get("status_text", ""))
	if balance_logger:
		balance_logger.log_purchase(state, "hero_skill", skill_id, gold_before.subtract(state.gold).floor_to_int_safe(), result)
	_update_ui()
	if result.get("upgraded", false):
		AudioManager.play_purchase_success()
		_save_game_now()
	else:
		AudioManager.play_purchase_error()


func _on_ability_skill_purchase_requested(skill_id: String) -> void:
	var gold_before: BigNumber = state.gold.clone()
	var result: Dictionary = state.buy_ability_skill(skill_id)
	_handle_status_text(result.get("status_text", ""))
	if balance_logger:
		balance_logger.log_purchase(state, "ability_rank", skill_id, gold_before.subtract(state.gold).floor_to_int_safe(), result)
	_update_ui()
	if result.get("upgraded", false):
		AudioManager.play_purchase_success()
		_save_game_now()
	else:
		AudioManager.play_purchase_error()


func _on_ability_unlock_requested(ability_id: String) -> void:
	var gold_before: BigNumber = state.gold.clone()
	var result: Dictionary = state.buy_ability_unlock(ability_id)
	_handle_status_text(result.get("status_text", ""))
	if balance_logger:
		balance_logger.log_purchase(state, "ability_unlock", ability_id, gold_before.subtract(state.gold).floor_to_int_safe(), result)
	_update_ui()
	if result.get("upgraded", false):
		AudioManager.play_purchase_success()
		upgrade_sheet.play_ability_purchase_feedback(ability_id)
		_save_game_now()
	else:
		AudioManager.play_purchase_error()


func _on_settings_requested() -> void:
	settings_window.show_window(state)
	_update_rewarded_ad_banner()


func _on_settings_account_auth_requested() -> void:
	var main := get_tree().current_scene
	if main != null and main.has_method("show_auth_gate_overlay"):
		main.show_auth_gate_overlay()


func _on_settings_sound_toggled(enabled: bool) -> void:
	state.sound_enabled = enabled
	AudioManager.set_sound_enabled(enabled)
	_save_game_now()
	settings_window.refresh_view(state)


func _on_settings_music_toggled(enabled: bool) -> void:
	state.music_enabled = enabled
	AudioManager.set_music_enabled(enabled)
	_save_game_now()
	settings_window.refresh_view(state)


func _on_settings_save_requested() -> void:
	if _save_game_now():
		settings_window.show_status(LocalizationManager.tr_key("settings.saved"))
	else:
		settings_window.show_status(LocalizationManager.tr_key("settings.save_failed"))


func _on_settings_reset_confirmed() -> void:
	var preserved: Dictionary = state.get_reset_progress_preserved_snapshot()
	SaveManager.delete_save()
	state.reset_to_new_game()
	state.apply_reset_progress_preserved_snapshot(preserved)
	AudioManager.set_sound_enabled(state.sound_enabled)
	AudioManager.set_music_enabled(state.music_enabled)
	LocalizationManager.set_language(state.language)
	_reset_runtime_state_for_new_game()
	_hide_all_bottom_sheets()
	active_bottom_tab = ""
	if tasks_window.visible:
		tasks_window.hide_window()
	settings_window.refresh_view(state)
	settings_window.show_status(LocalizationManager.tr_key("settings.progress_reset"))
	_update_ui()
	stage_navigator.center_on_level(1)
	_sync_boss_timer()
	if balance_logger:
		balance_logger.start_session(state)
		balance_logger.mark_enemy_spawned(state)
	_save_game_now()
	SaveManager.flush_cloud_save_now()


func _on_tasks_button_pressed() -> void:
	tasks_window.show_window(state)
	tasks_button.release_focus()
	_update_rewarded_ad_banner()


func _on_task_claim_requested(task_id: String) -> void:
	var reward_gold: BigNumber = BigNumber.zero()
	if balance_logger and state.is_task_completed(task_id):
		reward_gold = state.get_task_reward_gold(task_id)
	var result: Dictionary = state.claim_task_reward(task_id)
	_handle_status_text(result.get("status_text", ""))
	if balance_logger and result.get("upgraded", false):
		var log_result: Dictionary = {"reward_gold": reward_gold.floor_to_int_safe()}
		balance_logger.log_task_claimed(state, task_id, log_result)
	_update_ui()
	if tasks_window.visible:
		tasks_window.request_full_rebuild(state)
	if result.get("upgraded", false):
		AudioManager.play_reward_received()
		_save_game_now()


func _on_partner_purchase_requested(partner_index: int, mode: String) -> void:
	var gold_before: BigNumber = state.gold.clone()
	var result: Dictionary = state.buy_partners(partner_index, mode)
	_handle_status_text(result.get("status_text", ""))
	if balance_logger:
		balance_logger.log_purchase(state, "partner", "partner_%d_x%s" % [partner_index, mode], gold_before.subtract(state.gold).floor_to_int_safe(), result)
	_update_ui()
	if result.get("upgraded", false):
		AudioManager.play_purchase_success()
		partner_sheet.play_partner_purchase_feedback(partner_index)
		_save_game_now()
	else:
		AudioManager.play_purchase_error()


func _on_partner_skill_purchase_requested(skill_id: String) -> void:
	var gold_before: BigNumber = state.gold.clone()
	var result: Dictionary = state.buy_partner_skill(skill_id)
	_handle_status_text(result.get("status_text", ""))
	if balance_logger:
		balance_logger.log_purchase(state, "partner_skill", skill_id, gold_before.subtract(state.gold).floor_to_int_safe(), result)
	_update_ui()
	if result.get("upgraded", false):
		AudioManager.play_purchase_success()
		_save_game_now()
	else:
		AudioManager.play_purchase_error()


func _on_building_purchase_requested(building_index: int, mode: String) -> void:
	var gold_before: BigNumber = state.gold.clone()
	var result: Dictionary = state.buy_buildings(building_index, mode)
	_handle_status_text(result.get("status_text", ""))
	if balance_logger:
		balance_logger.log_purchase(state, "building", "building_%d_x%s" % [building_index, mode], gold_before.subtract(state.gold).floor_to_int_safe(), result)
	_update_ui()
	if result.get("upgraded", false):
		AudioManager.play_purchase_success()
		settlement_sheet.play_building_purchase_feedback(building_index)
		_save_game_now()
	else:
		AudioManager.play_purchase_error()


func _on_upgrades_button_pressed() -> void:
	_toggle_bottom_sheet("upgrades")
	upgrades_button.release_focus()


func _on_partners_button_pressed() -> void:
	_toggle_bottom_sheet("partners")
	partners_button.release_focus()


func _on_settlement_button_pressed() -> void:
	_toggle_bottom_sheet("settlement")
	settlement_button.release_focus()


func _on_prestige_button_pressed() -> void:
	_toggle_bottom_sheet("prestige")
	prestige_button.release_focus()


func _on_shop_button_pressed() -> void:
	_toggle_bottom_sheet("shop")
	shop_button.release_focus()


func _on_prestige_requested() -> void:
	prestige_sheet.set_prestige_button_modal_pressed(true)
	prestige_confirm_dialog.show_dialog(state)
	_update_rewarded_ad_banner()


func _on_prestige_talent_purchase_requested(talent_index: int, mode: String) -> void:
	var pp_before: int = state.prestige_points_available
	var result: Dictionary = state.buy_prestige_talents(talent_index, mode)
	_handle_status_text(result.get("status_text", ""))
	if balance_logger:
		balance_logger.log_purchase(state, "prestige_talent", "talent_%d_x%s" % [talent_index, mode], pp_before - state.prestige_points_available, result)
	_update_ui()
	if result.get("upgraded", false):
		AudioManager.play_purchase_success()
		prestige_sheet.play_prestige_talent_purchase_feedback(talent_index)
		_save_game_now()
	else:
		AudioManager.play_purchase_error()


func _on_shop_product_purchase_requested(product_id: String, mode: String) -> void:
	var product: Dictionary = state.get_shop_product(product_id)
	var product_type: String = String(product.get("product_type", ""))
	if product_type == "donation_entry":
		gem_purchase_dialog.show_dialog()
		_update_rewarded_ad_banner()
		return
	if product_type == "rewarded_ad":
		_request_shop_rewarded_gems_ad(product_id)
		return
	_pending_shop_product_id = product_id
	shop_sheet.set_product_buy_button_modal_pressed(product_id, true)
	var product_name: String = _get_shop_product_display_name(product_id)
	shop_purchase_confirm_dialog.show_dialog(product_id, mode, product_name)
	_update_rewarded_ad_banner()


func _on_gem_product_purchase_requested(product_id: String) -> void:
	var product: Dictionary = GemPurchaseConfigClass.get_by_id(product_id)
	if product.is_empty():
		return
	var platform_key: String = Platform.get_platform_key()
	var platform_product_id: String = GemPurchaseConfigClass.get_platform_product_id(product_id, platform_key)
	_pending_payment_product_id = product_id
	_payment_reward_granted_for_current_request = false
	_set_runtime_pause_reason("payment", true)
	AudioManager.set_audio_pause_reason("payment", true)
	Platform.gameplay_stop()
	Platform.purchase_product(platform_product_id, product_id)


func _on_payment_purchase_success(local_product_id: String, purchase_token: String) -> void:
	if purchase_token == "":
		push_warning("Platform: purchase success for '%s' without purchase id, ignoring" % local_product_id)
		AudioManager.play_purchase_error()
		_handle_status_text(LocalizationManager.tr_key("shop.gem_purchase.error"))
		_clear_payment_request_state()
		return
	if _payment_reward_granted_for_current_request:
		_clear_payment_request_state()
		return
	if state.is_purchase_processed(purchase_token):
		_clear_payment_request_state()
		return
	if local_product_id != _pending_payment_product_id:
		push_warning("Platform: success for unexpected product '%s' (pending '%s'), ignoring" % [local_product_id, _pending_payment_product_id])
		_clear_payment_request_state()
		return
	_payment_reward_granted_for_current_request = true
	state.mark_purchase_processed(purchase_token)
	var result: Dictionary = state.grant_paid_gem_purchase(local_product_id)
	_handle_status_text(result.get("status_text", ""))
	AudioManager.play_purchase_success()
	_update_ui()
	_save_game_and_flush_cloud_now()
	Platform.consume_purchase(purchase_token)
	_pending_payment_product_id = ""
	gem_purchase_dialog.hide_dialog()
	_clear_payment_pause_and_try_resume()


func _on_unprocessed_purchase_found(product_id: String, purchase_token: String) -> void:
	if state.is_purchase_processed(purchase_token):
		return
	var product: Dictionary = _find_gem_product_by_any_id(product_id)
	if product.is_empty():
		push_warning("Platform: unknown unprocessed purchase product '%s', ignoring" % product_id)
		return
	state.mark_purchase_processed(purchase_token)
	var local_product_id: String = String(product.get("id", ""))
	var result: Dictionary = state.grant_paid_gem_purchase(local_product_id)
	_handle_status_text(result.get("status_text", ""))
	AudioManager.play_purchase_success()
	_update_ui()
	_save_game_and_flush_cloud_now()
	Platform.consume_purchase(purchase_token)


func _on_unprocessed_purchase_check_error(message: String) -> void:
	if message != "Yandex SDK is not ready":
		push_warning("YandexBridge: unprocessed purchase check failed: %s" % message)


func _find_gem_product_by_any_id(product_id: String) -> Dictionary:
	var product: Dictionary = GemPurchaseConfigClass.get_by_id(product_id)
	if not product.is_empty():
		return product
	for candidate: Dictionary in GemPurchaseConfigClass.get_all():
		if String(candidate.get("yandex_product_id", "")) == product_id:
			return candidate
		if String(candidate.get("rustore_product_id", "")) == product_id:
			return candidate
	return {}


func _on_payment_purchase_cancelled(_local_product_id: String) -> void:
	_pending_payment_product_id = ""
	_payment_reward_granted_for_current_request = false
	var localized: String = LocalizationManager.tr_key("shop.gem_purchase.cancelled")
	gem_purchase_dialog.set_payment_failed(localized)
	_handle_status_text(localized)
	_clear_payment_pause_and_try_resume()


func _on_payment_purchase_error(_local_product_id: String, _message: String) -> void:
	_pending_payment_product_id = ""
	_payment_reward_granted_for_current_request = false
	AudioManager.play_purchase_error()
	var key: String = "shop.gem_purchase.unavailable" if _message == "payment_unavailable" else "shop.gem_purchase.error"
	var localized: String = LocalizationManager.tr_key(key)
	gem_purchase_dialog.set_payment_failed(localized)
	_handle_status_text(localized)
	_clear_payment_pause_and_try_resume()


func _request_shop_rewarded_gems_ad(product_id: String) -> void:
	if _rewarded_ad_request_context != "":
		return
	_rewarded_ad_request_context = "shop_gems"
	_rewarded_ad_shop_product_id = product_id
	_rewarded_ad_reward_granted_for_current_request = false
	shop_sheet.set_product_buy_button_modal_pressed(product_id, true)
	_set_runtime_pause_reason("rewarded_ad", true)
	AudioManager.pause_for_ad()
	Platform.gameplay_stop()
	Platform.show_rewarded_ad("rewarded_shop_gems")


func _get_shop_product_display_name(product_id: String) -> String:
	var product: Dictionary = state.get_shop_product(product_id)
	var name_key: String = String(product.get("name_key", ""))
	if name_key != "":
		return LocalizationManager.tr_key(name_key)
	var fallback_name: String = String(product.get("name", ""))
	return fallback_name if fallback_name != "" else product_id


func _execute_shop_product_purchase(product_id: String, mode: String) -> void:
	var gems_before: int = state.gems
	var result: Dictionary = state.buy_shop_products(product_id, mode)
	_handle_status_text(result.get("status_text", ""))
	if balance_logger:
		balance_logger.log_purchase(state, "shop", product_id, gems_before - state.gems, result)
	_update_ui()
	if result.get("upgraded", false):
		AudioManager.play_purchase_success()
		shop_sheet.play_product_purchase_feedback(product_id)
		_save_game_now()
	else:
		AudioManager.play_purchase_error()


func _on_shop_purchase_confirmed(product_id: String, mode: String) -> void:
	shop_sheet.set_product_buy_button_modal_pressed(_pending_shop_product_id, false)
	_pending_shop_product_id = ""
	_execute_shop_product_purchase(product_id, mode)


func _on_shop_purchase_cancelled() -> void:
	shop_sheet.set_product_buy_button_modal_pressed(_pending_shop_product_id, false)
	_pending_shop_product_id = ""
	_update_rewarded_ad_banner()


func _on_prestige_confirmed() -> void:
	prestige_sheet.set_prestige_button_modal_pressed(false)
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
	_handle_status_text(result.get("status_text", ""))
	stage_navigator.center_on_level(1)
	_update_ui()
	_sync_boss_timer()
	if balance_logger:
		balance_logger.mark_level_started(state)
		balance_logger.mark_enemy_spawned(state)
	_save_game_now()


func _on_prestige_cancelled() -> void:
	prestige_sheet.set_prestige_button_modal_pressed(false)
	prestige_confirm_dialog.hide()
	_update_rewarded_ad_banner()


func _reset_runtime_state_for_new_game() -> void:
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
	_autosave_timer = 0.0


func _apply_ui_font_sizes() -> void:
	var bottom_buttons: Array[Button] = [
		upgrades_button,
		partners_button,
		settlement_button,
		prestige_button,
		shop_button,
	]
	for button: Button in bottom_buttons:
		UiFontConfig.apply_button_font_size(button, UiFontConfig.BOTTOM_TAB_FONT_SIZE)


func _apply_button_visual_cleanup() -> void:
	ButtonVisualUtils.clear_image_button_styles(tasks_button)
	ButtonVisualUtils.clear_image_button_styles(upgrades_button)
	ButtonVisualUtils.clear_image_button_styles(partners_button)
	ButtonVisualUtils.clear_image_button_styles(settlement_button)
	ButtonVisualUtils.clear_image_button_styles(prestige_button)
	ButtonVisualUtils.clear_image_button_styles(shop_button)


func _clear_button_visual_styles(button: Button) -> void:
	ButtonVisualUtils.clear_image_button_styles(button)


func _set_bottom_tab_image(image_holder, tab_name: String, is_active: bool) -> void:
	var state_name: String = "active" if is_active else "default"
	var asset_key: String = "ui.bottom_tab.%s.%s" % [tab_name, state_name]
	image_holder.set_asset_key(asset_key, BOTTOM_TAB_BUTTON_FALLBACK_COLOR)


func _update_bottom_bar_view() -> void:
	upgrades_button.text = ""
	partners_button.text = ""
	settlement_button.text = ""
	prestige_button.text = ""
	shop_button.text = ""
	_set_bottom_tab_image(upgrades_button_image, "upgrades", active_bottom_tab == "upgrades")
	_set_bottom_tab_image(partners_button_image, "partners", active_bottom_tab == "partners")
	_set_bottom_tab_image(settlement_button_image, "settlement", active_bottom_tab == "settlement")
	_set_bottom_tab_image(prestige_button_image, "prestige", active_bottom_tab == "prestige")
	_set_bottom_tab_image(shop_button_image, "shop", active_bottom_tab == "shop")


func _on_language_changed() -> void:
	if not _is_initialized:
		return
	state.language = LocalizationManager.get_language()
	_update_ui()
	if tasks_window.visible:
		tasks_window.request_full_rebuild(state)
	_save_game_now()


func _toggle_bottom_sheet(tab_name: String) -> void:
	if active_bottom_tab == tab_name:
		_hide_all_bottom_sheets()
		active_bottom_tab = ""
		_update_bottom_bar_view()
		_update_rewarded_ad_banner()
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
	_update_active_sheet()
	_update_bottom_bar_view()
	_update_rewarded_ad_banner()


func _hide_all_bottom_sheets() -> void:
	upgrade_sheet.hide_sheet()
	partner_sheet.hide_sheet()
	settlement_sheet.hide_sheet()
	prestige_sheet.hide_sheet()
	shop_sheet.hide_sheet()


func _on_sheet_closed() -> void:
	active_bottom_tab = ""
	_update_bottom_bar_view()
	_update_rewarded_ad_banner()


func _sync_boss_timer() -> void:
	if state.is_boss_level:
		if not boss_timer_active:
			boss_time_left = state.boss_time_limit * state.get_boss_timer_multiplier()
			boss_timer_active = true
	else:
		boss_timer_active = false
		boss_time_left = 0.0

	progress_info_panel.update_boss_timer(boss_time_left, boss_timer_active)


func _fail_boss_level() -> void:
	boss_timer_active = false
	if balance_logger:
		balance_logger.log_boss_failed(state)
	var result: Dictionary = state.fail_boss_level()
	boss_time_left = 0.0
	_handle_status_text(result.get("status_text", ""))
	_update_ui()
	_sync_boss_timer()
	if auto_transition_popup.visible:
		auto_transition_popup.refresh_view(state)
	_save_game_now()


func _apply_attack_result(result: Dictionary, show_hit_feedback: bool, was_boss_level: bool = false) -> void:
	if result.get("defeated", false):
		_handle_defeat_result(result, was_boss_level)
		return

	if show_hit_feedback:
		game_field.play_hit_feedback(result.get("damage_dealt", 0))
	_handle_status_text(result.get("status_text", ""))
	progress_info_panel.update_view(state)
	game_field.update_view(state)
	_sync_boss_timer()


func _spawn_hit_effect(global_hit_position: Vector2 = Vector2.ZERO) -> void:
	AudioManager.play_random_hit()
	var effect := TextureRect.new()
	effect.custom_minimum_size = HIT_EFFECT_SIZE
	effect.size = HIT_EFFECT_SIZE
	effect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	effect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var asset_key: String = HIT_EFFECT_ASSET_KEYS[randi() % HIT_EFFECT_ASSET_KEYS.size()]
	effect.texture = GameAssetCatalog.load_texture(asset_key)
	hit_effect_layer.add_child(effect)
	var local_pos: Vector2
	if global_hit_position != Vector2.ZERO:
		local_pos = hit_effect_layer.get_global_transform().affine_inverse() * global_hit_position
	else:
		local_pos = _get_default_hit_effect_position()
	effect.position = local_pos - HIT_EFFECT_SIZE * 0.5
	await get_tree().create_timer(HIT_EFFECT_DURATION_SEC).timeout
	if is_instance_valid(effect):
		effect.queue_free()


func _get_default_hit_effect_position() -> Vector2:
	var enemy_rect: Rect2 = game_field.get_enemy_global_rect()
	var center_global: Vector2 = enemy_rect.get_center()
	var local: Vector2 = hit_effect_layer.get_global_transform().affine_inverse() * center_global
	return local + Vector2(randf_range(-12.0, 12.0), randf_range(-12.0, 12.0))


func _run_autoclick_attack() -> void:
	if enemy_transition_locked:
		return

	var was_boss_level: bool = state.is_boss_level
	var result: Dictionary = state.attack_with_damage(state.get_autoclick_damage())
	_apply_attack_result(result, true, was_boss_level)


func _run_partner_damage_tick() -> void:
	if enemy_transition_locked:
		return

	var tick_damage: BigNumber = state.get_partner_tick_damage()
	if not tick_damage.is_positive():
		return

	var was_boss_level: bool = state.is_boss_level
	var result: Dictionary = state.attack_with_damage(tick_damage)
	_apply_attack_result(result, false, was_boss_level)


func _on_autoclick_requested() -> void:
	if _is_runtime_paused():
		return
	var rank: int = state.get_ability_rank("autoclick")
	if not state.is_ability_purchased("autoclick") or state.autoclick_active or autoclick_cooldown_left > 0.0:
		return

	state.autoclick_active = true
	var rank_bonus_seconds: float = float(BalanceConfig.AUTOCLICK_RANK_DURATION_BONUS_SEC) * rank
	autoclick_time_left = _get_scaled_duration(autoclick_duration + rank_bonus_seconds, false)
	autoclick_accumulator = 0.0
	state.total_autoclick_activations += 1
	if balance_logger:
		balance_logger.log_ability_used(state, "autoclick")
	_update_ui()


func _on_gold_bonus_requested() -> void:
	if _is_runtime_paused():
		return
	if not state.is_ability_purchased("gold_bonus") or state.gold_bonus_active or gold_bonus_cooldown_left > 0.0:
		return

	state.gold_bonus_active = true
	gold_bonus_time_left = _get_scaled_duration(gold_bonus_duration, false)
	if balance_logger:
		balance_logger.log_ability_used(state, "gold_bonus")
	_update_ui()


func _on_focus_burst_requested() -> void:
	if _is_runtime_paused():
		return
	if not state.is_ability_purchased("focus_burst") or state.focus_burst_active or focus_burst_cooldown_left > 0.0:
		return

	state.focus_burst_active = true
	focus_burst_time_left = _get_scaled_duration(focus_burst_duration, true)
	state.refresh_derived_stats()
	if balance_logger:
		balance_logger.log_ability_used(state, "focus_burst")
	_update_ui()


func _on_rally_requested() -> void:
	if _is_runtime_paused():
		return
	if not state.is_ability_purchased("rally") or state.rally_active or rally_cooldown_left > 0.0:
		return

	state.rally_active = true
	rally_time_left = _get_scaled_duration(rally_duration, true)
	state.refresh_derived_stats()
	if balance_logger:
		balance_logger.log_ability_used(state, "rally")
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
			state.refresh_derived_stats()
			needs_full_ui_update = true

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
		rally_cooldown_left,
		autoclick_cooldown_duration,
		gold_bonus_cooldown_duration,
		focus_burst_cooldown_duration,
		rally_cooldown_duration,
		_get_autoclick_active_duration(),
		_get_gold_bonus_active_duration(),
		_get_focus_burst_active_duration(),
		_get_rally_active_duration()
	)


func _process_rewarded_ad_buff_expiry() -> void:
	var damage_active: bool = state.is_rewarded_ad_all_damage_active()
	var gold_active: bool = state.is_rewarded_ad_gold_active()

	var damage_just_expired: bool = _rewarded_ad_damage_buff_was_active and not damage_active
	var gold_just_expired: bool = _rewarded_ad_gold_buff_was_active and not gold_active

	_rewarded_ad_damage_buff_was_active = damage_active
	_rewarded_ad_gold_buff_was_active = gold_active

	if damage_just_expired:
		state.refresh_derived_stats()
		_update_ui()
	elif gold_just_expired:
		_update_ui()

	if state.expire_rewarded_ad_banner_if_needed():
		_save_game_now()

	_update_rewarded_ad_banner()


func _get_current_autoclick_interval() -> float:
	return maxf(0.02, autoclick_interval / (state.get_quick_hands_multiplier() * state.get_autoclick_rank_rate_multiplier()))


func _get_scaled_duration(base_duration: float, uses_war_banner: bool) -> float:
	if not uses_war_banner:
		return base_duration

	return base_duration * state.get_ability_duration_multiplier()


func _get_scaled_cooldown(base_cooldown: float) -> float:
	return base_cooldown * state.get_ability_cooldown_multiplier()


func _get_autoclick_active_duration() -> float:
	var rank: int = state.get_ability_rank("autoclick")
	return _get_scaled_duration(autoclick_duration + float(BalanceConfig.AUTOCLICK_RANK_DURATION_BONUS_SEC) * rank, false)


func _get_gold_bonus_active_duration() -> float:
	return _get_scaled_duration(gold_bonus_duration, false)


func _get_focus_burst_active_duration() -> float:
	return _get_scaled_duration(focus_burst_duration, true)


func _get_rally_active_duration() -> float:
	return _get_scaled_duration(rally_duration, true)


func _handle_defeat_result(result: Dictionary, was_boss_level: bool) -> void:
	enemy_transition_locked = true
	enemy_transition_token += 1
	var transition_token: int = enemy_transition_token
	game_field.set_enemy_transition_locked(true)
	game_field.play_defeat_feedback(result.get("level_up", false), result.get("zone_changed", false))
	_handle_status_text(result.get("status_text", ""))

	var reward_gold: BigNumber = state.get_current_target_reward_gold_preview()
	combat_effects_layer.play_gold_reward_effect(
		game_field.get_enemy_global_rect(),
		primary_stats_panel.get_gold_icon_global_center(),
		reward_gold
	)
	AudioManager.play_gold_received()

	if was_boss_level:
		boss_timer_active = false
		boss_time_left = 0.0
		progress_info_panel.update_boss_timer(boss_time_left, boss_timer_active)

	_update_ui()
	_finish_enemy_transition_after_delay(transition_token)


func _begin_level_change_transition() -> int:
	enemy_transition_token += 1
	var current_token: int = enemy_transition_token
	enemy_transition_locked = true
	game_field.set_enemy_transition_locked(false)
	partner_damage_accumulator = 0.0
	autoclick_accumulator = 0.0
	return current_token


func _on_stage_selected(level: int) -> void:
	if level == state.current_level:
		return
	var result: Dictionary = state.travel_to_level(level)
	if not result.get("travelled", false):
		return
	var current_token: int = _begin_level_change_transition()
	if balance_logger:
		balance_logger.mark_level_started(state)
		balance_logger.mark_enemy_spawned(state)
	_update_ui()
	_save_game_now()

	await _play_spawn_smoke_and_unlock_after_invulnerability(current_token)


func _on_stage_latest_requested() -> void:
	stage_navigator.center_on_latest_level()


func _on_auto_transition_popup_requested(anchor_global_position: Vector2, button_global_rect: Rect2) -> void:
	_toggle_auto_transition_and_show_popup(anchor_global_position, button_global_rect)


func _toggle_auto_transition_and_show_popup(anchor: Vector2, button_global_rect: Rect2) -> void:
	var was_open: bool = auto_transition_popup.is_open()
	if state.auto_stage_advance_enabled:
		state.set_auto_stage_advance_enabled(false)
	else:
		var jump_result: Dictionary = state.enable_auto_stage_advance_and_jump_if_needed()
		if jump_result.get("moved_to_latest", false):
			var current_token: int = _begin_level_change_transition()
			if balance_logger:
				balance_logger.mark_level_started(state)
				balance_logger.mark_enemy_spawned(state)
			_sync_boss_timer()
			stage_navigator.center_on_level(state.current_level)
			stage_navigator.set_auto_transition_enabled(state.auto_stage_advance_enabled)
			_update_ui()
			if was_open:
				auto_transition_popup.hide_popup()
			else:
				auto_transition_popup.show_popup(state, anchor, button_global_rect)
			_save_game_now()
			await _play_spawn_smoke_and_unlock_after_invulnerability(current_token)
			return
	stage_navigator.set_auto_transition_enabled(state.auto_stage_advance_enabled)
	_update_ui()
	if was_open:
		auto_transition_popup.hide_popup()
	else:
		auto_transition_popup.show_popup(state, anchor, button_global_rect)
	_save_game_now()


func _create_fullscreen_ad_overlay() -> void:
	_fullscreen_ad_overlay = Control.new()
	_fullscreen_ad_overlay.name = "FullscreenAdOverlay"
	_fullscreen_ad_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fullscreen_ad_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_fullscreen_ad_overlay.visible = false
	add_child(_fullscreen_ad_overlay)


func _mark_user_interaction() -> void:
	_last_user_interaction_time = Time.get_ticks_msec() / 1000.0


func _is_safe_for_fullscreen_ad() -> bool:
	if Platform.is_ad_in_progress():
		return false
	if _pending_payment_product_id != "":
		return false
	if _pending_shop_product_id != "":
		return false
	if _rewarded_ad_request_context != "":
		return false
	if prestige_confirm_dialog.visible:
		return false
	if shop_purchase_confirm_dialog.visible:
		return false
	if gem_purchase_dialog.visible:
		return false
	if offline_reward_dialog.visible:
		return false
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - _last_user_interaction_time < FULLSCREEN_AD_SAFE_INTERACTION_GAP_SECONDS:
		return false
	return true


func _try_show_fullscreen_ad_if_safe() -> void:
	if not _is_safe_for_fullscreen_ad():
		return
	_fullscreen_ad_cooldown_left = FULLSCREEN_AD_COOLDOWN_SECONDS
	_set_runtime_pause_reason("fullscreen_ad", true)
	AudioManager.pause_for_ad()
	Platform.gameplay_stop()
	Platform.show_fullscreen_ad("fullscreen_auto_interstitial")


func _on_fullscreen_ad_opened() -> void:
	if is_instance_valid(_fullscreen_ad_overlay):
		_fullscreen_ad_overlay.visible = true
	_set_runtime_pause_reason("fullscreen_ad", true)
	AudioManager.pause_for_ad()
	Platform.gameplay_stop()


func _on_fullscreen_ad_closed(_was_shown: bool) -> void:
	if is_instance_valid(_fullscreen_ad_overlay):
		_fullscreen_ad_overlay.visible = false
	_set_runtime_pause_reason("fullscreen_ad", false)
	AudioManager.resume_after_ad()
	_try_resume_yandex_gameplay()
	_fullscreen_ad_cooldown_left = FULLSCREEN_AD_COOLDOWN_SECONDS


func _on_fullscreen_ad_error(_message: String) -> void:
	if is_instance_valid(_fullscreen_ad_overlay):
		_fullscreen_ad_overlay.visible = false
	_set_runtime_pause_reason("fullscreen_ad", false)
	AudioManager.resume_after_ad()
	_try_resume_yandex_gameplay()
	_fullscreen_ad_cooldown_left = FULLSCREEN_AD_COOLDOWN_SECONDS


func _handle_status_text(_text: String) -> void:
	pass


func _set_runtime_pause_reason(reason: String, paused: bool) -> void:
	var was_paused: bool = not _runtime_pause_reasons.is_empty()
	if paused:
		_runtime_pause_reasons[reason] = true
		if not was_paused:
			_runtime_pause_started_unix_time = int(Time.get_unix_time_from_system())
	else:
		_runtime_pause_reasons.erase(reason)
		if was_paused and _runtime_pause_reasons.is_empty() and _runtime_pause_started_unix_time > 0:
			var paused_seconds: int = int(Time.get_unix_time_from_system()) - _runtime_pause_started_unix_time
			if paused_seconds > 0 and _is_initialized:
				state.extend_rewarded_ad_buff_expirations(paused_seconds, _runtime_pause_started_unix_time)
			_runtime_pause_started_unix_time = 0


func _is_runtime_paused() -> bool:
	return not _runtime_pause_reasons.is_empty()


func _can_resume_yandex_gameplay() -> bool:
	if not _is_initialized:
		return false
	if _is_runtime_paused():
		return false
	if Platform.is_ad_in_progress():
		return false
	return true


func is_startup_completed() -> bool:
	return _is_initialized


func notify_yandex_game_ready() -> void:
	if _yandex_game_ready_notified:
		return
	_yandex_game_ready_notified = true
	print("ClickerScreen: notify_yandex_game_ready called")
	Platform.game_ready()
	_try_resume_yandex_gameplay()


func _request_yandex_gameplay_stop() -> void:
	Platform.gameplay_stop()


func _try_resume_yandex_gameplay() -> void:
	if _can_resume_yandex_gameplay():
		Platform.gameplay_start()


func _on_yandex_platform_pause_requested() -> void:
	if BuildConfig.IS_DEBUG_BUILD:
		print("ClickerScreen: platform_pause_requested — pausing gameplay. Bridge state: %s" % str(Platform.get_platform_event_debug_state()))
	_set_runtime_pause_reason("platform", true)
	AudioManager.set_audio_pause_reason("platform", true)
	_request_yandex_gameplay_stop()
	if BuildConfig.IS_DEBUG_BUILD:
		print("ClickerScreen: runtime pause reasons after platform pause: %s" % str(_runtime_pause_reasons.keys()))


func _on_yandex_platform_resume_requested() -> void:
	if BuildConfig.IS_DEBUG_BUILD:
		print("ClickerScreen: platform_resume_requested — clearing platform pause. Bridge state: %s" % str(Platform.get_platform_event_debug_state()))
	_set_runtime_pause_reason("platform", false)
	AudioManager.set_audio_pause_reason("platform", false)
	_try_resume_yandex_gameplay()
	if BuildConfig.IS_DEBUG_BUILD:
		print("ClickerScreen: runtime pause reasons after platform resume: %s" % str(_runtime_pause_reasons.keys()))


func _on_page_visibility_changed(page_visible: bool) -> void:
	_set_runtime_pause_reason("hidden", not page_visible)
	if page_visible:
		_try_resume_yandex_gameplay()


func _clear_payment_pause_and_try_resume() -> void:
	_set_runtime_pause_reason("payment", false)
	AudioManager.set_audio_pause_reason("payment", false)
	_try_resume_yandex_gameplay()


func _clear_payment_request_state() -> void:
	_pending_payment_product_id = ""
	_payment_reward_granted_for_current_request = false
	if is_instance_valid(gem_purchase_dialog):
		gem_purchase_dialog.set_payment_done()
	_clear_payment_pause_and_try_resume()


func _wait_runtime_seconds(seconds: float) -> void:
	var remaining := seconds
	while remaining > 0.0:
		await get_tree().process_frame
		if _is_runtime_paused():
			continue
		var delta := get_process_delta_time()
		remaining = maxf(remaining - delta, 0.0)


func _play_spawn_smoke_and_unlock_after_invulnerability(transition_token: int) -> void:
	combat_effects_layer.play_spawn_smoke_effect(
		game_field.get_enemy_global_rect(),
		ENEMY_SPAWN_SMOKE_DURATION
	)
	await _wait_runtime_seconds(ENEMY_SPAWN_INVULNERABILITY_DURATION)
	if transition_token != enemy_transition_token:
		return
	enemy_transition_locked = false
	_update_ui()
	_sync_boss_timer()


func _finish_enemy_transition_after_delay(transition_token: int) -> void:
	await _wait_runtime_seconds(enemy_respawn_delay)
	if transition_token != enemy_transition_token:
		return

	var prev_level: int = state.current_level
	var result: Dictionary = state.resolve_defeated_target()
	_handle_status_text(result.get("status_text", ""))
	if balance_logger and result.get("defeated", false):
		var log_result: Dictionary = result.duplicate()
		log_result["defeated_on_level"] = prev_level
		balance_logger.log_enemy_defeated(state, log_result)
		if result.get("advanced_to_next_level", false):
			balance_logger.log_level_changed(state, prev_level, state.current_level)
		balance_logger.mark_enemy_spawned(state)

	# Show new enemy (clear defeated texture) while keeping ClickerScreen locked
	game_field.set_enemy_transition_locked(false)
	if result.get("advanced_to_next_level", false):
		stage_navigator.center_on_level(state.current_level)
	_update_ui()

	await _play_spawn_smoke_and_unlock_after_invulnerability(transition_token)
	if transition_token != enemy_transition_token:
		return
	if result.get("level_unlocked", false):
		_save_game_now()


func _save_game_now() -> bool:
	state.save_current_level_progress()
	return SaveManager.save_data(state.get_save_data())


func _save_game_and_flush_cloud_now() -> bool:
	state.save_current_level_progress()
	var data: Dictionary = state.get_save_data()
	var saved: bool = SaveManager.save_data(data)
	if saved:
		SaveManager.queue_cloud_save(data, true)
	return saved


func _request_unprocessed_purchase_check_when_ready(attempt: int = 0) -> void:
	if _unprocessed_purchase_check_requested:
		return
	if Platform.refresh_platform_ready():
		_unprocessed_purchase_check_requested = true
		Platform.check_unprocessed_purchases()
		return
	if attempt >= YANDEX_PURCHASE_RECOVERY_MAX_READY_ATTEMPTS:
		return
	await get_tree().create_timer(YANDEX_PURCHASE_RECOVERY_RETRY_DELAY_SEC).timeout
	_request_unprocessed_purchase_check_when_ready(attempt + 1)


func _apply_startup_language() -> void:
	if not state.language_manually_selected:
		var platform_lang: String = Platform.get_platform_language()
		var resolved: String = LocalizationManager.normalize_supported_language(platform_lang)
		if resolved != state.language:
			state.language = resolved
			_save_game_now()
	LocalizationManager.set_language(state.language)


func _on_language_manually_changed(_language_code: String) -> void:
	state.language_manually_selected = true
	_save_game_now()


func _load_game_on_start_async() -> void:
	var now: int = int(Time.get_unix_time_from_system())
	var local_data: Dictionary = SaveManager.load_data()
	var cloud_data: Dictionary = await SaveManager.load_cloud_data_async()

	var local_valid: bool = not local_data.is_empty()
	var cloud_valid: bool = not cloud_data.is_empty()

	var chosen: Dictionary = {}

	if local_valid and cloud_valid:
		var local_time: int = int(local_data.get("last_save_unix_time", 0))
		var cloud_time: int = int(cloud_data.get("last_save_unix_time", 0))
		if cloud_time > local_time:
			chosen = cloud_data
			print("ClickerScreen: cloud save is newer (%d > %d), using cloud" % [cloud_time, local_time])
		else:
			chosen = local_data
	elif local_valid:
		chosen = local_data
	elif cloud_valid:
		chosen = cloud_data
		print("ClickerScreen: no valid local save, using cloud save")

	if chosen.is_empty():
		state.last_save_unix_time = now
		state.start_rewarded_ad_initial_cooldown_if_needed()
		_save_game_now()
		return

	state.apply_save_data(chosen)
	LocalizationManager.set_language(state.language)

	if state.has_pending_offline_gold_reward():
		pass
	else:
		var previous_time: int = state.last_save_unix_time
		if previous_time > 0 and now > previous_time:
			state.queue_offline_gold_reward(now - previous_time)

	state.last_save_unix_time = now
	state.start_rewarded_ad_initial_cooldown_if_needed()
	_save_game_now()

	if state.has_pending_offline_gold_reward():
		offline_reward_dialog.show_reward(
			state.pending_offline_elapsed_seconds,
			state.pending_offline_gold_reward
		)


func _sync_debug_visual_test_gems() -> void:
	if not BuildConfig.IS_DEBUG_BUILD:
		return
	if state.is_debug_visual_test_mode_enabled():
		state.gems = DEBUG_VISUAL_TEST_GEMS


func _toggle_debug_visual_test_mode() -> void:
	var enabled: bool = not state.is_debug_visual_test_mode_enabled()

	if enabled:
		_debug_visual_test_previous_gems = state.gems

	state.set_debug_visual_test_mode_enabled(enabled)

	if enabled:
		state.gems = DEBUG_VISUAL_TEST_GEMS
		state.clear_rewarded_ad_banner_cooldown_for_debug()
		state.clear_pending_offline_gold_reward()
		state.queue_offline_gold_reward(3600)
		if state.has_pending_offline_gold_reward():
			offline_reward_dialog.show_reward(
				state.pending_offline_elapsed_seconds,
				state.pending_offline_gold_reward
			)
	else:
		state.gems = _debug_visual_test_previous_gems

	enemy_transition_locked = false
	enemy_transition_token += 1
	game_field.set_enemy_transition_locked(false)
	partner_damage_accumulator = 0.0
	autoclick_accumulator = 0.0
	_sync_boss_timer()
	_update_ui()
	if balance_logger:
		balance_logger.mark_enemy_spawned(state)
	print("Debug visual test mode: %s" % ("ON (HP=100000, purchases=1 gold, gems=999, unlock restrictions bypassed)" if enabled else "OFF"))


func _debug_visual_damage_51_percent() -> void:
	if not state.is_debug_visual_test_mode_enabled():
		print("Debug visual test mode is OFF")
		return
	if enemy_transition_locked:
		return
	var was_boss_level: bool = state.is_boss_level
	var result: Dictionary = state.debug_damage_current_target_by_percent(0.51)
	_apply_attack_result(result, true, was_boss_level)
	_update_ui()
	print("Debug visual damage: current HP %s/%s" % [state.target_hp.to_debug_string(), state.target_max_hp.to_debug_string()])


func _debug_visual_clear_level() -> void:
	if not state.is_debug_visual_test_mode_enabled():
		print("Debug visual test mode is OFF")
		return
	if enemy_transition_locked:
		return
	var previous_level: int = state.current_level
	var result: Dictionary = state.debug_clear_current_level_for_visual_test()
	enemy_transition_token += 1
	var current_token: int = enemy_transition_token
	enemy_transition_locked = true
	game_field.set_enemy_transition_locked(false)
	partner_damage_accumulator = 0.0
	autoclick_accumulator = 0.0
	_handle_status_text(result.get("status_text", ""))
	if result.get("advanced_to_next_level", false):
		stage_navigator.center_on_level(state.current_level)
		if balance_logger:
			balance_logger.log_level_changed(state, previous_level, state.current_level)
			balance_logger.mark_enemy_spawned(state)
	_update_ui()
	print("Debug visual clear: level %d -> %d" % [previous_level, state.current_level])

	await _play_spawn_smoke_and_unlock_after_invulnerability(current_token)


func _run_balance_simulation() -> void:
	var sim := ProgressionSimulator.new()
	var minute_marks: Array = [5, 15, 30, 60, 180, 1440]
	var profiles: Array = [
		ProgressionSimulator.F2P_CASUAL,
		ProgressionSimulator.AD_WATCHER,
		ProgressionSimulator.LIGHT_SPENDER,
	]
	var all_rows: Array = []
	print("=== BALANCE SIMULATION ===")
	for profile in profiles:
		print("--- %s ---" % profile.to_upper())
		var rows: Array = sim.build_progression_table(minute_marks, profile)
		all_rows.append_array(rows)
		for row in rows:
			print("  %4.0fmin | Lv%-3d | Hero%-4d | Dmg%-6d | PDPS%-7d | EHP%-8d | +%-6d g/min | %.1fs/lvl | %d pp" % [
				float(row.get("minutes", 0)),
				int(row.get("level", 0)),
				int(row.get("hero_level", 0)),
				int(row.get("click_damage", 0)),
				int(row.get("partner_dps", 0)),
				int(row.get("enemy_hp", 0)),
				int(row.get("gold_per_minute", 0)),
				float(row.get("time_to_clear_level", 0.0)),
				int(row.get("prestige_points", 0)),
			])
	var csv_path: String = "user://balance_simulation.csv"
	if sim.export_csv(csv_path, all_rows):
		print("CSV exported to %s" % csv_path)
	print("=== SIMULATION COMPLETE ===")


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		_mark_user_interaction()
		AudioManager.unlock_audio_if_needed()
	elif event is InputEventKey and event.pressed and not event.echo:
		AudioManager.unlock_audio_if_needed()

	if not BuildConfig.IS_DEBUG_BUILD:
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_F5:
			_save_game_now()
			print("Debug: game saved")
		KEY_F6:
			if balance_logger:
				if balance_logger.export_csv():
					print("Balance playtest CSV exported to user://balance_playtest.csv (%d rows)" % balance_logger.rows.size())
				else:
					print("Balance playtest: export failed or no data")
		KEY_F7:
			if balance_logger:
				var summary: Dictionary = balance_logger.get_summary()
				print("=== BALANCE PLAYTEST SUMMARY ===")
				print("  Session:  %.1fs (%.1f min)" % [summary.session_duration_sec, summary.session_duration_sec / 60.0])
				print("  Level:    %d reached" % summary.highest_level_reached)
				print("  Enemies:  %d defeated (%d bosses, %d boss fails)" % [summary.enemies_defeated, summary.bosses_defeated, summary.boss_fails])
				print("  Gold:     kills=%d  tasks=%d  shop=%d  spent=%d" % [summary.total_gold_earned_from_kills, summary.total_task_rewards, summary.total_shop_rewards, summary.total_gold_spent])
				print("  TTK:      avg=%.2fs  boss_avg=%.2fs" % [summary.average_enemy_ttk_sec, summary.average_boss_ttk_sec])
				print("  Actions:  purchases=%d  tasks=%d  abilities=%d" % [summary.purchases_count, summary.tasks_claimed_count, summary.abilities_used_count])
				print("================================")
		KEY_F8:
			_run_balance_simulation()
		KEY_F9:
			var data: Dictionary = SaveManager.load_data()
			if not data.is_empty():
				state.apply_save_data(data)
				_update_ui()
				_sync_boss_timer()
				print("Debug: game loaded")
		KEY_F10:
			SaveManager.delete_save()
			print("Debug: save deleted")
		KEY_F11:
			if balance_logger:
				balance_logger.clear()
				balance_logger.start_session(state)
				balance_logger.mark_enemy_spawned(state)
				print("Balance playtest logger cleared and session restarted")
		KEY_F12:
			_toggle_debug_visual_test_mode()
		KEY_L:
			_debug_visual_damage_51_percent()
		KEY_K:
			_debug_visual_clear_level()


func _on_offline_reward_claim_requested() -> void:
	if not state.has_pending_offline_gold_reward():
		offline_reward_dialog.hide_dialog()
		return
	state.claim_pending_offline_gold(1)
	offline_reward_dialog.hide_dialog()
	AudioManager.play_reward_received()
	_update_ui()
	_save_game_now()


func _on_offline_reward_claim_ad_requested() -> void:
	if not state.has_pending_offline_gold_reward():
		offline_reward_dialog.hide_dialog()
		return
	_rewarded_ad_request_context = "offline_gold_x3"
	_rewarded_ad_shop_product_id = ""
	_rewarded_ad_reward_granted_for_current_request = false
	offline_reward_dialog.set_buttons_loading(true)
	_set_runtime_pause_reason("rewarded_ad", true)
	AudioManager.pause_for_ad()
	Platform.gameplay_stop()
	Platform.show_rewarded_ad("rewarded_offline_gold_x3")


func _on_rewarded_ad_banner_pressed() -> void:
	if not state.is_rewarded_ad_banner_available():
		rewarded_ad_banner.set_banner_state(rewarded_ad_banner.BannerState.COOLDOWN)
		return
	_rewarded_ad_request_context = "bonus_banner"
	_rewarded_ad_shop_product_id = ""
	_rewarded_ad_reward_granted_for_current_request = false
	rewarded_ad_banner.set_banner_state(rewarded_ad_banner.BannerState.LOADING)
	_set_runtime_pause_reason("rewarded_ad", true)
	AudioManager.pause_for_ad()
	Platform.gameplay_stop()
	Platform.show_rewarded_ad("rewarded_bonus_banner")


func _on_rewarded_ad_opened() -> void:
	_set_runtime_pause_reason("rewarded_ad", true)
	AudioManager.pause_for_ad()
	Platform.gameplay_stop()


func _on_rewarded_ad_rewarded() -> void:
	if _rewarded_ad_reward_granted_for_current_request:
		return
	_rewarded_ad_reward_granted_for_current_request = true
	match _rewarded_ad_request_context:
		"bonus_banner":
			state.ensure_rewarded_ad_current_reward_selected()
			var banner_result: Dictionary = state.grant_rewarded_ad_bonus(state.get_rewarded_ad_current_reward_id())
			_handle_status_text(banner_result.get("status_text", ""))
			AudioManager.play_reward_received()
			state.refresh_derived_stats()
			_update_ui()
			_save_game_now()
			state.reroll_rewarded_ad_current_reward()
		"shop_gems":
			var shop_result: Dictionary = state.grant_shop_rewarded_gems()
			_handle_status_text(shop_result.get("status_text", ""))
			AudioManager.play_reward_received()
			state.refresh_derived_stats()
			_update_ui()
			_save_game_now()
		"offline_gold_x3":
			state.claim_pending_offline_gold(BalanceConfig.OFFLINE_GOLD_AD_MULTIPLIER)
			offline_reward_dialog.hide_dialog()
			AudioManager.play_reward_received()
			_update_ui()
			_save_game_now()
		_:
			pass


func _on_rewarded_ad_closed(_was_shown: bool) -> void:
	_set_runtime_pause_reason("rewarded_ad", false)
	AudioManager.resume_after_ad()
	_try_resume_yandex_gameplay()
	if _rewarded_ad_request_context == "shop_gems":
		shop_sheet.set_product_buy_button_modal_pressed(_rewarded_ad_shop_product_id, false)
	if _rewarded_ad_request_context == "offline_gold_x3" and not _rewarded_ad_reward_granted_for_current_request:
		offline_reward_dialog.set_buttons_loading(false)
	_rewarded_ad_request_context = ""
	_rewarded_ad_shop_product_id = ""
	_rewarded_ad_reward_granted_for_current_request = false
	_update_rewarded_ad_banner()


func _on_rewarded_ad_error(_message: String) -> void:
	_set_runtime_pause_reason("rewarded_ad", false)
	AudioManager.resume_after_ad()
	_try_resume_yandex_gameplay()
	if _rewarded_ad_request_context == "shop_gems":
		shop_sheet.set_product_buy_button_modal_pressed(_rewarded_ad_shop_product_id, false)
	if _rewarded_ad_request_context == "offline_gold_x3":
		offline_reward_dialog.set_buttons_loading(false)
	_rewarded_ad_request_context = ""
	_rewarded_ad_shop_product_id = ""
	_rewarded_ad_reward_granted_for_current_request = false
	_update_rewarded_ad_banner()


func _is_main_screen_clear_for_rewarded_banner() -> bool:
	return (
		not upgrade_sheet.visible
		and not partner_sheet.visible
		and not settlement_sheet.visible
		and not prestige_sheet.visible
		and not shop_sheet.visible
		and not tasks_window.visible
		and not settings_window.visible
		and not auto_transition_popup.visible
		and not prestige_confirm_dialog.visible
		and not shop_purchase_confirm_dialog.visible
		and not gem_purchase_dialog.visible
		and not offline_reward_dialog.visible
	)


func _update_rewarded_ad_banner() -> void:
	if not _is_main_screen_clear_for_rewarded_banner():
		rewarded_ad_banner.visible = false
		rewarded_ad_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return

	if state.expire_rewarded_ad_banner_if_needed():
		_save_game_now()
	state.spawn_rewarded_ad_banner_if_needed()

	if state.is_rewarded_ad_banner_available():
		rewarded_ad_banner.visible = true
		rewarded_ad_banner.mouse_filter = Control.MOUSE_FILTER_STOP
		rewarded_ad_banner.set_reward_id(state.get_rewarded_ad_current_reward_id())
		rewarded_ad_banner.set_banner_state(rewarded_ad_banner.BannerState.AVAILABLE)
	else:
		rewarded_ad_banner.visible = false
		rewarded_ad_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE


# ── Backend cloud save (manual upload / download) ─────────────────────────────

func _on_settings_cloud_save_upload_requested() -> void:
	if not OS.has_feature("android") or not Platform.backend_has_session():
		settings_window.set_cloud_save_status(
			LocalizationManager.tr_key("settings.cloud.upload_failed"), true
		)
		return
	_save_game_now()
	var payload := SaveManager.get_cloud_save_payload()
	if payload.is_empty():
		settings_window.set_cloud_save_status(
			LocalizationManager.tr_key("settings.cloud.upload_failed"), true
		)
		return
	Platform.backend_save_save(payload)


func _on_settings_cloud_save_download_requested() -> void:
	if not OS.has_feature("android") or not Platform.backend_has_session():
		settings_window.set_cloud_save_status(
			LocalizationManager.tr_key("settings.cloud.download_failed"), true
		)
		return
	Platform.backend_load_save()


func _on_backend_cloud_op_succeeded(operation: String, response: Dictionary) -> void:
	match operation:
		"load_save":
			var has_save: bool = bool(response.get("has_save", false))
			if not has_save:
				settings_window.set_cloud_save_status(
					LocalizationManager.tr_key("settings.cloud.no_cloud_save")
				)
				return
			var save_data: Dictionary = response.get("save_data", {})
			var ok: bool = SaveManager.apply_cloud_save_payload(save_data)
			if ok:
				var loaded: Dictionary = SaveManager.load_data()
				if not loaded.is_empty():
					state.apply_save_data(loaded)
					_reset_runtime_state_for_new_game()
					_sync_boss_timer()
					_update_ui()
					stage_navigator.center_on_level(state.current_level)
				settings_window.set_cloud_save_status(
					LocalizationManager.tr_key("settings.cloud.download_success")
				)
			else:
				settings_window.set_cloud_save_status(
					LocalizationManager.tr_key("settings.cloud.invalid_cloud_save"), true
				)


func _on_backend_cloud_op_failed(operation: String, error_code: String, _status_code: int, _response: Dictionary) -> void:
	match operation:
		"load_save":
			settings_window.set_cloud_save_status(
				LocalizationManager.format_key("settings.account.backend_error", {"error": error_code}),
				true
			)
