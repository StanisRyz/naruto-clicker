class_name CombatEffectsLayer
extends Control

const GOLD_PARTICLE_COUNT: int = 12
const GOLD_PARTICLE_SIZE: Vector2 = Vector2(18, 18)
const GOLD_PARTICLE_TRAVEL_DURATION: float = 0.55
const GOLD_TEXT_DURATION: float = 0.8
const SPAWN_SMOKE_PUFF_COUNT: int = 16


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_preset(PRESET_FULL_RECT)


func play_gold_reward_effect(origin_global: Vector2, target_global: Vector2, amount: int) -> void:
	if amount <= 0:
		return
	_spawn_gold_text(origin_global, amount)
	_spawn_gold_particles(origin_global, target_global)


func play_spawn_smoke_effect(enemy_global_rect: Rect2, duration: float = 0.3) -> void:
	var center: Vector2 = enemy_global_rect.get_center()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(SPAWN_SMOKE_PUFF_COUNT):
		_spawn_smoke_puff(center, enemy_global_rect.size, rng, duration)


func _spawn_gold_text(origin_global: Vector2, amount: int) -> void:
	var label := Label.new()
	var amount_str: String = NumberFormatter.compact(amount)
	label.text = LocalizationManager.format_key("ui.combat.gold_reward", {"amount": amount_str})
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	label.add_theme_font_size_override("font_size", 22)
	label.modulate.a = 0.0
	add_child(label)

	var start_pos: Vector2 = origin_global + Vector2(10.0, -20.0)
	label.global_position = start_pos

	var tween := create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.08)
	tween.parallel().tween_property(label, "scale", Vector2(1.05, 1.05), 0.08)
	tween.tween_property(label, "global_position:y", start_pos.y - 40.0, 0.55)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.17).set_delay(0.38)
	tween.tween_callback(label.queue_free)


func _spawn_gold_particles(origin_global: Vector2, target_global: Vector2) -> void:
	var gold_texture: Texture2D = GameAssetCatalog.load_texture("ui.gold")
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(GOLD_PARTICLE_COUNT):
		_spawn_one_gold_particle(origin_global, target_global, gold_texture, rng)


func _spawn_one_gold_particle(
	origin_global: Vector2,
	target_global: Vector2,
	texture: Texture2D,
	rng: RandomNumberGenerator
) -> void:
	var particle: Control
	if texture != null:
		var tex_rect := TextureRect.new()
		tex_rect.texture = texture
		tex_rect.custom_minimum_size = GOLD_PARTICLE_SIZE
		tex_rect.size = GOLD_PARTICLE_SIZE
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		particle = tex_rect
	else:
		var rect := ColorRect.new()
		rect.color = Color(1.0, 0.85, 0.1, 1.0)
		rect.custom_minimum_size = GOLD_PARTICLE_SIZE
		rect.size = GOLD_PARTICLE_SIZE
		particle = rect

	add_child(particle)
	particle.pivot_offset = GOLD_PARTICLE_SIZE * 0.5

	var scatter_offset := Vector2(
		rng.randf_range(-28.0, 28.0),
		rng.randf_range(-28.0, 28.0)
	)
	var start_pos: Vector2 = origin_global + scatter_offset - GOLD_PARTICLE_SIZE * 0.5
	particle.global_position = start_pos

	var scatter_dir: Vector2 = scatter_offset.normalized() if scatter_offset.length() > 1.0 \
		else Vector2(rng.randf_range(-1.0, 1.0), -1.0).normalized()
	var scatter_target: Vector2 = start_pos + scatter_dir * rng.randf_range(18.0, 40.0)

	var travel_duration: float = rng.randf_range(0.35, GOLD_PARTICLE_TRAVEL_DURATION)
	var flight_target: Vector2 = target_global - GOLD_PARTICLE_SIZE * 0.5

	var tween := create_tween()
	tween.tween_property(particle, "global_position", scatter_target, 0.12)
	tween.tween_property(particle, "global_position", flight_target, travel_duration)
	tween.parallel().tween_property(particle, "modulate:a", 0.0, travel_duration * 0.5) \
		.set_delay(travel_duration * 0.5)
	tween.tween_callback(particle.queue_free)


func _spawn_smoke_puff(
	center: Vector2,
	enemy_size: Vector2,
	rng: RandomNumberGenerator,
	duration: float
) -> void:
	var panel := Panel.new()
	var style := StyleBoxFlat.new()

	var puff_size: float = rng.randf_range(40.0, 120.0)
	var is_elongated: bool = rng.randf() < 0.25
	var puff_w: float = puff_size * (2.0 if is_elongated else 1.0)
	var puff_h: float = puff_size * (0.5 if is_elongated else 1.0)
	var corner_r: int = int(puff_size * 0.5)

	style.corner_radius_top_left = corner_r
	style.corner_radius_top_right = corner_r
	style.corner_radius_bottom_left = corner_r
	style.corner_radius_bottom_right = corner_r
	var gray: float = rng.randf_range(0.85, 1.0)
	style.bg_color = Color(gray, gray, gray, 1.0)
	style.border_width_left = 0
	style.border_width_right = 0
	style.border_width_top = 0
	style.border_width_bottom = 0
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(puff_w, puff_h)
	panel.size = Vector2(puff_w, puff_h)

	add_child(panel)
	panel.pivot_offset = Vector2(puff_w, puff_h) * 0.5

	var angle: float = rng.randf_range(0.0, TAU)
	var max_rx: float = maxf(enemy_size.x * 0.5 * 0.7, 40.0)
	var max_ry: float = maxf(enemy_size.y * 0.5 * 0.7, 30.0)
	var radius_x: float = rng.randf_range(0.0, max_rx)
	var radius_y: float = rng.randf_range(0.0, max_ry)
	var start_offset := Vector2(cos(angle) * radius_x, sin(angle) * radius_y)
	panel.global_position = center + start_offset - panel.pivot_offset
	panel.scale = Vector2(0.3, 0.3)
	panel.modulate.a = rng.randf_range(0.75, 0.95)

	var expand_dir: Vector2 = start_offset.normalized() if start_offset.length() > 1.0 \
		else Vector2(cos(angle), sin(angle))
	var expand_dist: float = rng.randf_range(
		maxf(enemy_size.x * 0.5 * 0.5, 50.0),
		maxf(enemy_size.x * 0.5 * 1.1, 90.0)
	)
	var end_pos: Vector2 = center + expand_dir * expand_dist - panel.pivot_offset
	var end_scale: float = rng.randf_range(1.0, 1.6)

	var tween := create_tween()
	tween.tween_property(panel, "global_position", end_pos, duration)
	tween.parallel().tween_property(panel, "scale", Vector2(end_scale, end_scale), duration)
	tween.parallel().tween_property(panel, "modulate:a", 0.0, duration)
	tween.tween_callback(panel.queue_free)
