class_name GameField
extends Button

signal attack_requested

@onready var zone_name_label: Label = $GameFieldContent/ZoneNameLabel
@onready var enemy_name_label: Label = $GameFieldContent/EnemyNameLabel
@onready var target_hp_label: Label = $GameFieldContent/TargetHpLabel
@onready var target_progress_bar: ProgressBar = $GameFieldContent/TargetProgressBar
@onready var boss_timer_label: Label = $GameFieldContent/BossTimerLabel
@onready var feedback_layer: Control = $FeedbackLayer
@onready var defeat_feedback_label: Label = $FeedbackLayer/DefeatFeedbackLabel


func _ready() -> void:
	pressed.connect(_on_pressed)


func update_view(state: ClickerState) -> void:
	zone_name_label.text = state.zone_name
	enemy_name_label.text = state.enemy_name
	target_hp_label.text = "Enemy HP: %d / %d" % [state.target_hp, state.target_max_hp]
	target_progress_bar.max_value = state.target_max_hp
	target_progress_bar.value = state.target_hp


func update_boss_timer(time_left: float, is_active: bool) -> void:
	boss_timer_label.visible = is_active
	if is_active:
		boss_timer_label.text = "Boss Time: %.1fs" % maxf(time_left, 0.0)


func play_hit_feedback(damage: int) -> void:
	if damage <= 0:
		return

	pivot_offset = size * 0.5
	var pulse_tween: Tween = create_tween()
	pulse_tween.tween_property(self, "scale", Vector2(1.03, 1.03), 0.05)
	pulse_tween.tween_property(self, "scale", Vector2.ONE, 0.08)

	var popup_label: Label = Label.new()
	popup_label.text = "-%d" % damage
	popup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup_label.modulate = Color(1.0, 0.95, 0.45, 1.0)
	feedback_layer.add_child(popup_label)

	var popup_size := Vector2(96, 40)
	popup_label.size = popup_size
	popup_label.position = (feedback_layer.size - popup_size) * 0.5

	var popup_tween: Tween = create_tween()
	popup_tween.set_parallel(true)
	popup_tween.tween_property(popup_label, "position:y", popup_label.position.y - 54.0, 0.35)
	popup_tween.tween_property(popup_label, "modulate:a", 0.0, 0.35)
	popup_tween.chain().tween_callback(popup_label.queue_free)


func play_defeat_feedback(level_up: bool, zone_changed: bool = false) -> void:
	if zone_changed:
		defeat_feedback_label.text = "New Zone!"
	elif level_up:
		defeat_feedback_label.text = "Level Up!"
	else:
		defeat_feedback_label.text = "Defeated!"
	defeat_feedback_label.modulate.a = 1.0
	defeat_feedback_label.scale = Vector2.ONE

	var tween: Tween = create_tween()
	tween.tween_property(defeat_feedback_label, "scale", Vector2(1.08, 1.08), 0.08)
	tween.tween_interval(0.22)
	tween.tween_property(defeat_feedback_label, "modulate:a", 0.0, 0.18)


func _on_pressed() -> void:
	attack_requested.emit()
