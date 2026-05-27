class_name GameField
extends Control

signal attack_requested

const HEALTHY_COLOR: Color = Color.WHITE
const HIT_COLOR: Color = Color(0.15, 0.45, 1.0, 1.0)
const WOUNDED_COLOR: Color = Color(1.0, 0.1, 0.1, 1.0)
const DEFEATED_COLOR: Color = Color.BLACK
const HIT_STATE_DURATION: float = 0.3

var hit_tween: Tween = null
var defeat_tween: Tween = null
var enemy_transition_locked: bool = false
var current_health_color: Color = HEALTHY_COLOR

@onready var enemy_image_holder: ColorRect = $EnemyImageHolder
@onready var boss_timer_label: Label = $GameFieldContent/BossTimerLabel
@onready var defeat_feedback_label: Label = $FeedbackLayer/DefeatFeedbackLabel


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			accept_event()
			attack_requested.emit()
	elif event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
		if touch_event.pressed:
			accept_event()
			attack_requested.emit()


func update_view(state: ClickerState) -> void:
	update_enemy_visual_state(state)


func update_enemy_visual_state(state: ClickerState) -> void:
	current_health_color = _get_health_color(state)
	if enemy_transition_locked:
		enemy_image_holder.color = DEFEATED_COLOR
		return

	if hit_tween != null and hit_tween.is_running():
		return

	enemy_image_holder.color = current_health_color


func update_boss_timer(time_left: float, is_active: bool) -> void:
	boss_timer_label.visible = is_active
	if is_active:
		boss_timer_label.text = "Boss Time: %.1fs" % maxf(time_left, 0.0)


func play_hit_feedback(damage: int) -> void:
	if damage <= 0 or enemy_transition_locked:
		return

	if hit_tween != null:
		hit_tween.kill()

	enemy_image_holder.color = HIT_COLOR
	hit_tween = create_tween()
	hit_tween.tween_interval(HIT_STATE_DURATION)
	hit_tween.tween_callback(func() -> void:
		hit_tween = null
		if not enemy_transition_locked:
			enemy_image_holder.color = current_health_color
	)


func play_defeat_feedback(level_up: bool, zone_changed: bool = false) -> void:
	if hit_tween != null:
		hit_tween.kill()
		hit_tween = null

	enemy_image_holder.color = DEFEATED_COLOR

	if zone_changed:
		defeat_feedback_label.text = "New Zone!"
	elif level_up:
		defeat_feedback_label.text = "Level Up!"
	else:
		defeat_feedback_label.text = "Defeated!"
	defeat_feedback_label.modulate.a = 1.0
	defeat_feedback_label.scale = Vector2.ONE

	if defeat_tween != null:
		defeat_tween.kill()
	defeat_tween = create_tween()
	defeat_tween.tween_property(defeat_feedback_label, "scale", Vector2(1.08, 1.08), 0.08)
	defeat_tween.tween_interval(0.22)
	defeat_tween.tween_property(defeat_feedback_label, "modulate:a", 0.0, 0.18)


func set_enemy_transition_locked(is_locked: bool) -> void:
	enemy_transition_locked = is_locked
	if enemy_transition_locked:
		if hit_tween != null:
			hit_tween.kill()
			hit_tween = null
		enemy_image_holder.color = DEFEATED_COLOR
	else:
		enemy_image_holder.color = current_health_color


func _get_health_color(state: ClickerState) -> Color:
	if state.target_hp <= 0:
		return DEFEATED_COLOR

	var hp_ratio: float = float(state.target_hp) / maxf(float(state.target_max_hp), 1.0)
	return WOUNDED_COLOR if hp_ratio <= 0.5 else HEALTHY_COLOR
