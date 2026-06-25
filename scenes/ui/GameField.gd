class_name GameField
extends Control

signal attack_requested(global_position: Vector2)

const HEALTHY_COLOR: Color = Color.WHITE
const HIT_COLOR: Color = Color(0.15, 0.45, 1.0, 1.0)
const WOUNDED_COLOR: Color = Color(1.0, 0.1, 0.1, 1.0)
const DEFEATED_COLOR: Color = Color.BLACK
const HIT_STATE_DURATION: float = 0.3
const BACKGROUND_FALLBACK_COLOR: Color = Color(0.25, 0.42, 0.25, 1.0)

var hit_tween: Tween = null
var defeat_tween: Tween = null
var enemy_transition_locked: bool = false
var current_health_color: Color = HEALTHY_COLOR
var current_asset_key: String = "enemy.default.healthy"

var _cached_background_zone_index: int = -1
var _cached_zone_index: int = -1
var _cached_enemy_slot: String = ""
var _tex_healthy: Texture2D = null
var _tex_hit: Texture2D = null
var _tex_wounded: Texture2D = null
var _tex_defeated: Texture2D = null
var _current_tex: Texture2D = null

const DAMAGE_NUMBER_DURATION: float = 0.55
const DAMAGE_NUMBER_RISE_DISTANCE: float = 44.0
const DAMAGE_NUMBER_RANDOM_X: float = 14.0
const MAX_FLOATING_DAMAGE_LABELS: int = 20

const TOUCH_MOUSE_DEDUP_WINDOW_SEC: float = 0.30
const TOUCH_MOUSE_DEDUP_MAX_DISTANCE_PX: float = 36.0

var _last_touch_time: float = -999.0
var _last_touch_position: Vector2 = Vector2.ZERO

@onready var background_image_holder = $BackgroundImageHolder  # ImageSlot (ColorRect subclass)
@onready var enemy_image_holder = $EnemyImageHolder  # ImageSlot (ColorRect subclass)
@onready var defeat_feedback_label: Label = $FeedbackLayer/DefeatFeedbackLabel
@onready var floating_damage_layer: Control = $FeedbackLayer/FloatingDamageLayer


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
		if touch_event.pressed:
			_last_touch_time = Time.get_ticks_msec() / 1000.0
			_last_touch_position = touch_event.position
			accept_event()
			attack_requested.emit(touch_event.position)
	elif event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			var now: float = Time.get_ticks_msec() / 1000.0
			var dt: float = now - _last_touch_time
			var dist: float = mouse_event.global_position.distance_to(_last_touch_position)
			if dt < TOUCH_MOUSE_DEDUP_WINDOW_SEC and dist < TOUCH_MOUSE_DEDUP_MAX_DISTANCE_PX:
				accept_event()
				return
			accept_event()
			attack_requested.emit(mouse_event.global_position)


func update_view(state: ClickerState) -> void:
	_update_background_visual(state)
	update_enemy_visual_state(state)


func _update_background_visual(state: ClickerState) -> void:
	var zone_index: int = state.get_current_background_zone_index()
	if zone_index == _cached_background_zone_index:
		return
	_cached_background_zone_index = zone_index
	var texture: Texture2D = BackgroundAssetCatalog.load_zone_background(zone_index)
	background_image_holder.set_direct_texture(texture, BACKGROUND_FALLBACK_COLOR, false)


func update_enemy_visual_state(state: ClickerState) -> void:
	_refresh_enemy_textures(state.current_enemy_zone_index, state.current_enemy_slot)
	current_health_color = _get_health_color(state)
	current_asset_key = _get_health_asset_key(state)

	var is_wounded: bool = current_asset_key.ends_with("wounded")
	_current_tex = _tex_wounded if is_wounded else _tex_healthy

	if enemy_transition_locked:
		enemy_image_holder.set_direct_texture(_tex_defeated, DEFEATED_COLOR, false)
		return

	if hit_tween != null and hit_tween.is_running():
		return

	enemy_image_holder.set_direct_texture(_current_tex, current_health_color, false)


func play_hit_feedback(damage) -> void:
	var has_damage: bool = (damage is BigNumber and damage.is_positive()) or (not damage is BigNumber and damage > 0)
	if not has_damage or enemy_transition_locked:
		return

	if hit_tween != null:
		hit_tween.kill()

	enemy_image_holder.set_direct_texture(_tex_hit, HIT_COLOR, false)
	hit_tween = create_tween()
	hit_tween.tween_interval(HIT_STATE_DURATION)
	hit_tween.tween_callback(func() -> void:
		hit_tween = null
		if not enemy_transition_locked:
			enemy_image_holder.set_direct_texture(_current_tex, current_health_color, false)
	)


func play_defeat_feedback(level_up: bool, zone_changed: bool = false) -> void:
	if hit_tween != null:
		hit_tween.kill()
		hit_tween = null

	enemy_image_holder.set_direct_texture(_tex_defeated, DEFEATED_COLOR, false)

	if defeat_tween != null:
		defeat_tween.kill()
		defeat_tween = null

	var feedback_text: String = ""
	if zone_changed:
		feedback_text = LocalizationManager.tr_key("ui.gameplay.new_zone")
	elif level_up:
		feedback_text = LocalizationManager.tr_key("ui.gameplay.level_up")

	if feedback_text.is_empty():
		defeat_feedback_label.modulate.a = 0.0
		return

	defeat_feedback_label.text = feedback_text
	defeat_feedback_label.modulate.a = 1.0
	defeat_feedback_label.scale = Vector2.ONE

	defeat_tween = create_tween()
	defeat_tween.tween_property(defeat_feedback_label, "scale", Vector2(1.08, 1.08), 0.08)
	defeat_tween.tween_interval(0.22)
	defeat_tween.tween_property(defeat_feedback_label, "modulate:a", 0.0, 0.18)


func get_enemy_global_center() -> Vector2:
	return enemy_image_holder.get_global_rect().get_center()


func get_enemy_global_rect() -> Rect2:
	return enemy_image_holder.get_global_rect()


func get_enemy_reward_origin_global() -> Vector2:
	var rect: Rect2 = enemy_image_holder.get_global_rect()
	return rect.get_center() + Vector2(0, -rect.size.y * 0.15)


func set_enemy_transition_locked(is_locked: bool) -> void:
	enemy_transition_locked = is_locked
	if enemy_transition_locked:
		if hit_tween != null:
			hit_tween.kill()
			hit_tween = null
		enemy_image_holder.set_direct_texture(_tex_defeated, DEFEATED_COLOR, false)
	else:
		enemy_image_holder.set_direct_texture(_current_tex, current_health_color, false)


func _refresh_enemy_textures(zone_index: int, enemy_slot: String) -> void:
	if zone_index == _cached_zone_index and enemy_slot == _cached_enemy_slot:
		return
	_cached_zone_index = zone_index
	_cached_enemy_slot = enemy_slot
	_tex_healthy = _load_enemy_tex_with_fallback(zone_index, enemy_slot, "healthy")
	_tex_hit = _load_enemy_tex_with_fallback(zone_index, enemy_slot, "hit")
	_tex_wounded = _load_enemy_tex_with_fallback(zone_index, enemy_slot, "wounded")
	_tex_defeated = _load_enemy_tex_with_fallback(zone_index, enemy_slot, "defeated")


func _load_enemy_tex_with_fallback(zone_index: int, enemy_slot: String, state: String) -> Texture2D:
	var tex: Texture2D = EnemyAssetCatalog.load_enemy_texture(zone_index, enemy_slot, state)
	if tex != null:
		return tex
	return GameAssetCatalog.load_texture("enemy.default." + state)


func _get_health_color(state: ClickerState) -> Color:
	if state.target_hp.is_zero():
		return DEFEATED_COLOR

	var hp_ratio: float = state.target_hp.to_float_approx() / maxf(state.target_max_hp.to_float_approx(), 1.0)
	return WOUNDED_COLOR if hp_ratio <= 0.5 else HEALTHY_COLOR


func _get_health_asset_key(state: ClickerState) -> String:
	if state.target_hp.is_zero():
		return "enemy.default.defeated"

	var hp_ratio: float = state.target_hp.to_float_approx() / maxf(state.target_max_hp.to_float_approx(), 1.0)
	return "enemy.default.wounded" if hp_ratio <= 0.5 else "enemy.default.healthy"


func spawn_damage_number(damage, click_global_position: Vector2) -> void:
	var has_damage: bool = (damage is BigNumber and damage.is_positive()) or (not damage is BigNumber and damage > 0)
	if not has_damage:
		return

	if floating_damage_layer.get_child_count() >= MAX_FLOATING_DAMAGE_LABELS:
		floating_damage_layer.get_child(0).queue_free()

	var label := Label.new()
	label.text = NumberFormatter.compact(damage)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.z_index = 100

	UiFontConfig.apply_damage_number_theme(label)
	floating_damage_layer.add_child(label)

	var local_pos: Vector2 = floating_damage_layer.get_global_transform().affine_inverse() * click_global_position
	var start_offset := Vector2(randf_range(-DAMAGE_NUMBER_RANDOM_X, DAMAGE_NUMBER_RANDOM_X), -12.0)
	var start_pos := local_pos + start_offset

	label.position = start_pos
	label.modulate.a = 1.0
	label.scale = Vector2.ONE

	await get_tree().process_frame
	if not is_instance_valid(label):
		return
	label.pivot_offset = label.size * 0.5
	label.position = start_pos - label.size * 0.5

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - DAMAGE_NUMBER_RISE_DISTANCE, DAMAGE_NUMBER_DURATION)
	tween.tween_property(label, "modulate:a", 0.0, DAMAGE_NUMBER_DURATION)
	tween.tween_property(label, "scale", Vector2(1.12, 1.12), 0.12)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)
