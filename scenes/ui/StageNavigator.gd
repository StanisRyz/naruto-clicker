class_name StageNavigator
extends Control

signal stage_selected(level: int)

const DISPLAY_COUNT: int = 7
const SIDE_COUNT: int = 3
const BUTTON_SIZE: int = 40
const SCROLL_BUTTON_WIDTH: int = 28

const COLOR_CURRENT: Color = Color(0.2, 0.4, 0.9, 1.0)
const COLOR_UNLOCKED: Color = Color(1.0, 1.0, 1.0, 1.0)
const COLOR_LOCKED: Color = Color(0.35, 0.35, 0.35, 1.0)

# visible_center_level is the stage shown in the center button.
# minimum: SIDE_COUNT + 1 = 4 (so leftmost visible stage is always >= 1)
# maximum: max_unlocked_level (so rightmost visible stage is max_unlocked + SIDE_COUNT)
var visible_center_level: int = SIDE_COUNT + 1

var _current_level: int = 1
var _max_unlocked_level: int = 1

var _stage_buttons: Array = []
var _stage_rects: Array = []
var _stage_labels: Array = []
var _left_button: Button
var _right_button: Button


func _ready() -> void:
	custom_minimum_size = Vector2(0, BUTTON_SIZE + 8)
	mouse_filter = MOUSE_FILTER_STOP
	_build_ui()
	_refresh_buttons()


func _build_ui() -> void:
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 4)
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.mouse_filter = MOUSE_FILTER_PASS
	add_child(hbox)

	_left_button = _make_scroll_button("<")
	_left_button.pressed.connect(_on_scroll_left)
	hbox.add_child(_left_button)

	for i: int in DISPLAY_COUNT:
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
		btn.flat = true
		btn.mouse_filter = MOUSE_FILTER_STOP

		var rect: ColorRect = ColorRect.new()
		rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		rect.mouse_filter = MOUSE_FILTER_IGNORE
		btn.add_child(rect)

		var label: Label = Label.new()
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 10)
		label.mouse_filter = MOUSE_FILTER_IGNORE
		btn.add_child(label)

		var captured_index: int = i
		btn.pressed.connect(func() -> void: _on_stage_button_pressed(captured_index))
		hbox.add_child(btn)

		_stage_buttons.append(btn)
		_stage_rects.append(rect)
		_stage_labels.append(label)

	_right_button = _make_scroll_button(">")
	_right_button.pressed.connect(_on_scroll_right)
	hbox.add_child(_right_button)


func _make_scroll_button(label_text: String) -> Button:
	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(SCROLL_BUTTON_WIDTH, BUTTON_SIZE)
	btn.text = label_text
	btn.mouse_filter = MOUSE_FILTER_STOP
	return btn


func update_view(current_level: int, max_unlocked_level: int) -> void:
	_current_level = current_level
	_max_unlocked_level = max_unlocked_level

	# Snap center to show current_level if outside current visible range.
	var visible_min: int = visible_center_level - SIDE_COUNT
	var visible_max: int = visible_center_level + SIDE_COUNT
	if current_level < visible_min or current_level > visible_max:
		visible_center_level = current_level

	_clamp_center()
	_refresh_buttons()


func _clamp_center() -> void:
	var min_center: int = SIDE_COUNT + 1
	var max_center: int = maxi(_max_unlocked_level, min_center)
	visible_center_level = clampi(visible_center_level, min_center, max_center)


func _refresh_buttons() -> void:
	for i: int in DISPLAY_COUNT:
		var stage_level: int = visible_center_level - SIDE_COUNT + i
		var btn: Button = _stage_buttons[i]
		var rect: ColorRect = _stage_rects[i]
		var label: Label = _stage_labels[i]

		label.text = str(stage_level)

		var is_current: bool = stage_level == _current_level
		var is_unlocked: bool = stage_level <= _max_unlocked_level

		if is_current:
			rect.color = COLOR_CURRENT
			btn.disabled = false
		elif is_unlocked:
			rect.color = COLOR_UNLOCKED
			btn.disabled = false
		else:
			rect.color = COLOR_LOCKED
			btn.disabled = true

	_update_scroll_buttons()


func _update_scroll_buttons() -> void:
	var leftmost: int = visible_center_level - SIDE_COUNT
	_left_button.disabled = leftmost <= 1

	var rightmost: int = visible_center_level + SIDE_COUNT
	var farthest_allowed: int = _max_unlocked_level + SIDE_COUNT
	_right_button.disabled = rightmost >= farthest_allowed


func _on_stage_button_pressed(button_index: int) -> void:
	var stage_level: int = visible_center_level - SIDE_COUNT + button_index
	if stage_level < 1 or stage_level > _max_unlocked_level:
		return
	if stage_level == _current_level:
		return
	stage_selected.emit(stage_level)


func _on_scroll_left() -> void:
	visible_center_level -= 1
	_clamp_center()
	_refresh_buttons()


func _on_scroll_right() -> void:
	visible_center_level += 1
	_clamp_center()
	_refresh_buttons()
