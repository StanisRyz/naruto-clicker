class_name ProgressInfoPanel
extends Control

@onready var zone_label: Label = $VBoxContainer/ZoneLabel
@onready var enemies_label: Label = $VBoxContainer/EnemiesLabel
@onready var enemy_name_label: Label = $VBoxContainer/EnemyNameLabel
@onready var enemy_hp_progress_bar: ProgressBar = $VBoxContainer/EnemyHpProgressBar
@onready var enemy_hp_text_label: Label = $VBoxContainer/EnemyHpProgressBar/HpTextLabel
@onready var boss_timer_label: Label = $VBoxContainer/BossTimerSlot/BossTimerLabel


func _ready() -> void:
	_apply_font_sizes()
	_apply_hp_bar_style()


func _apply_font_sizes() -> void:
	UiFontConfig.apply_label_font_size(zone_label, UiFontConfig.PROGRESS_ZONE_FONT_SIZE)
	UiFontConfig.apply_label_font_size(enemies_label, UiFontConfig.PROGRESS_ENEMIES_FONT_SIZE)
	UiFontConfig.apply_label_font_size(enemy_name_label, UiFontConfig.PROGRESS_ENEMY_NAME_FONT_SIZE)
	UiFontConfig.apply_label_font_size(enemy_hp_text_label, UiFontConfig.PROGRESS_HP_TEXT_FONT_SIZE)
	UiFontConfig.apply_boss_timer_theme(boss_timer_label)


func update_view(state: ClickerState) -> void:
	zone_label.text = LocalizationManager.tr_key(ZoneConfig.get_name_key_for_level(state.current_level))
	if state.is_level_cleared(state.current_level):
		enemies_label.text = LocalizationManager.tr_key("ui.common.cleared")
	else:
		enemies_label.text = LocalizationManager.format_key("ui.progress.enemies_count", {
			"current": state.enemies_defeated_on_level,
			"required": state.enemies_required_per_level,
		})
	enemy_name_label.text = _get_localized_enemy_name(state)
	enemy_hp_text_label.text = LocalizationManager.format_key("ui.progress.hp_bar_value", {
		"current": NumberFormatter.compact(state.target_hp),
		"max": NumberFormatter.compact(state.target_max_hp),
	})
	enemy_hp_progress_bar.max_value = maxf(state.target_max_hp.to_float_approx(), 1.0)
	enemy_hp_progress_bar.value = clampf(state.target_hp.to_float_approx(), 0.0, enemy_hp_progress_bar.max_value)


func _get_localized_enemy_name(state: ClickerState) -> String:
	if state.enemy_name_key != "":
		var localized_name: String = LocalizationManager.tr_key(state.enemy_name_key)
		if localized_name != state.enemy_name_key:
			return localized_name
	return state.enemy_name


func update_boss_timer(time_left: float, is_active: bool) -> void:
	boss_timer_label.visible = true
	if is_active:
		boss_timer_label.modulate.a = 1.0
		boss_timer_label.text = LocalizationManager.format_key("ui.progress.boss_time", {
			"time": "%.1f" % maxf(time_left, 0.0),
		})
	else:
		boss_timer_label.modulate.a = 0.0
		boss_timer_label.text = ""


func _apply_hp_bar_style() -> void:
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0, 0, 0, 1)
	background.corner_radius_top_left = 6
	background.corner_radius_top_right = 6
	background.corner_radius_bottom_left = 6
	background.corner_radius_bottom_right = 6

	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.85, 0.05, 0.05, 1)
	fill.corner_radius_top_left = 6
	fill.corner_radius_top_right = 6
	fill.corner_radius_bottom_left = 6
	fill.corner_radius_bottom_right = 6

	enemy_hp_progress_bar.add_theme_stylebox_override("background", background)
	enemy_hp_progress_bar.add_theme_stylebox_override("fill", fill)
