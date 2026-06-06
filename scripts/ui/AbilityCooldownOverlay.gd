class_name AbilityCooldownOverlay
extends Control

enum OverlayMode { COOLDOWN, ACTIVE }

const DEFAULT_COOLDOWN_SOFT_FILTER_COLOR: Color = Color(0.4, 0.4, 0.4, 0.28)
const DEFAULT_COOLDOWN_SECTOR_COLOR: Color = Color(0.03, 0.03, 0.03, 0.72)
const DEFAULT_ACTIVE_SOFT_FILTER_COLOR: Color = Color(1.0, 1.0, 1.0, 0.06)
const DEFAULT_ACTIVE_SECTOR_COLOR: Color = Color(1.0, 1.0, 1.0, 0.22)
const DEFAULT_SEGMENT_COUNT: int = 48
const RADIAL_DIRECTION: float = -1.0

var overlay_mode: OverlayMode = OverlayMode.COOLDOWN
var radial_ratio: float = 0.0
var cooldown_soft_filter_color: Color = DEFAULT_COOLDOWN_SOFT_FILTER_COLOR
var cooldown_sector_color: Color = DEFAULT_COOLDOWN_SECTOR_COLOR
var active_soft_filter_color: Color = DEFAULT_ACTIVE_SOFT_FILTER_COLOR
var active_sector_color: Color = DEFAULT_ACTIVE_SECTOR_COLOR
var segment_count: int = DEFAULT_SEGMENT_COUNT


func set_cooldown_ratio(value: float) -> void:
	overlay_mode = OverlayMode.COOLDOWN
	_set_ratio(value)


func set_active_ratio(value: float) -> void:
	overlay_mode = OverlayMode.ACTIVE
	_set_ratio(value)


func clear() -> void:
	radial_ratio = 0.0
	visible = false
	queue_redraw()


func _set_ratio(value: float) -> void:
	radial_ratio = clampf(value, 0.0, 1.0)
	visible = radial_ratio > 0.0
	queue_redraw()


func _draw() -> void:
	if radial_ratio <= 0.0:
		return
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.5
	var soft_color: Color
	var sector_color: Color
	if overlay_mode == OverlayMode.ACTIVE:
		soft_color = active_soft_filter_color
		sector_color = active_sector_color
	else:
		soft_color = cooldown_soft_filter_color
		sector_color = cooldown_sector_color
	draw_circle(center, radius, soft_color)
	_draw_sector(center, radius, radial_ratio, sector_color)


func _draw_sector(center: Vector2, radius: float, ratio: float, color: Color) -> void:
	var points := PackedVector2Array()
	points.append(center)
	var start_angle: float = -PI / 2.0
	var sweep: float = TAU * ratio * RADIAL_DIRECTION
	for i in range(segment_count + 1):
		var t: float = float(i) / float(segment_count)
		var angle: float = start_angle + sweep * t
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, color)
