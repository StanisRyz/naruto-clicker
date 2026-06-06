class_name AbilityCooldownOverlay
extends Control

const DEFAULT_SOFT_FILTER_COLOR: Color = Color(0.4, 0.4, 0.4, 0.28)
const DEFAULT_COOLDOWN_SECTOR_COLOR: Color = Color(0.03, 0.03, 0.03, 0.72)
const DEFAULT_SEGMENT_COUNT: int = 48

var cooldown_ratio: float = 0.0
var soft_filter_color: Color = DEFAULT_SOFT_FILTER_COLOR
var cooldown_sector_color: Color = DEFAULT_COOLDOWN_SECTOR_COLOR
var segment_count: int = DEFAULT_SEGMENT_COUNT


func set_cooldown_ratio(value: float) -> void:
	cooldown_ratio = clampf(value, 0.0, 1.0)
	visible = cooldown_ratio > 0.0
	queue_redraw()


func _draw() -> void:
	if cooldown_ratio <= 0.0:
		return
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.5
	draw_circle(center, radius, soft_filter_color)
	_draw_cooldown_sector(center, radius, cooldown_ratio)


func _draw_cooldown_sector(center: Vector2, radius: float, ratio: float) -> void:
	var points := PackedVector2Array()
	points.append(center)
	var start_angle: float = -PI / 2.0
	var sweep: float = TAU * ratio
	for i in range(segment_count + 1):
		var t: float = float(i) / float(segment_count)
		var angle: float = start_angle + sweep * t
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, cooldown_sector_color)
