class_name GameField
extends Control

signal attack_requested

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

@onready var background_image_holder = $BackgroundImageHolder  # ImageSlot (ColorRect subclass)
@onready var enemy_image_holder = $EnemyImageHolder  # ImageSlot (ColorRect subclass)
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


func play_hit_feedback(damage: int) -> void:
	if damage <= 0 or enemy_transition_locked:
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
	if state.target_hp <= 0:
		return DEFEATED_COLOR

	var hp_ratio: float = float(state.target_hp) / maxf(float(state.target_max_hp), 1.0)
	return WOUNDED_COLOR if hp_ratio <= 0.5 else HEALTHY_COLOR


func _get_health_asset_key(state: ClickerState) -> String:
	if state.target_hp <= 0:
		return "enemy.default.defeated"

	var hp_ratio: float = float(state.target_hp) / maxf(float(state.target_max_hp), 1.0)
	return "enemy.default.wounded" if hp_ratio <= 0.5 else "enemy.default.healthy"
