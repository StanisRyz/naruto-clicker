class_name StageNavigator
extends Control

signal stage_selected(level: int)

const DISPLAY_COUNT: int = 7
const SIDE_COUNT: int = 3
const BUTTON_SIZE: int = 40
const SCROLL_BUTTON_WIDTH: int = 28
const DRAG_STAGE_THRESHOLD: float = 36.0
const DRAG_MOVED_THRESHOLD: float = 8.0

const COLOR_CURRENT: Color = Color(0.2, 0.4, 0.9, 1.0)
const COLOR_UNLOCKED: Color = Color(1.0, 1.0, 1.0, 1.0)
const COLOR_LOCKED: Color = Color(0.35, 0.35, 0.35, 1.0)

var visible_center_level: int = SIDE_COUNT + 1
var _current_level: int = 1
var _max_unlocked_level: int = 1
var _has_initialized_view: bool = false

var _stage_buttons: Array = []
var _stage_rects: Array = []
var _stage_labels: Array = []
var _left_button: Button
var _right_button: Button

var _is_dragging: bool = false
var _drag_start_x: float = 0.0
var _drag_last_x: float = 0.0
var _drag_accumulator: float = 0.0
var _drag_moved: bool = false


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


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_LEFT:
				_scroll_by(-1)
				accept_event()
			MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_RIGHT:
				_scroll_by(1)
				accept_event()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if get_global_rect().has_point(event.global_position):
				_is_dragging = true
				_drag_start_x = event.global_position.x
				_drag_last_x = event.global_position.x
				_drag_accumulator = 0.0
				_drag_moved = false
		elif _is_dragging:
			_is_dragging = false
			_drag_accumulator = 0.0
	elif event is InputEventMouseMotion and _is_dragging:
		var delta_x: float = event.global_position.x - _drag_last_x
		_drag_last_x = event.global_position.x
		_drag_accumulator += delta_x
		if abs(event.global_position.x - _drag_start_x) >= DRAG_MOVED_THRESHOLD:
			_drag_moved = true
		while _drag_accumulator >= DRAG_STAGE_THRESHOLD:
			_scroll_by(-1)
			_drag_accumulator -= DRAG_STAGE_THRESHOLD
		while _drag_accumulator <= -DRAG_STAGE_THRESHOLD:
			_scroll_by(1)
			_drag_accumulator += DRAG_STAGE_THRESHOLD
	elif event is InputEventScreenTouch:
		if event.pressed:
			if get_global_rect().has_point(event.position):
				_is_dragging = true
				_drag_start_x = event.position.x
				_drag_last_x = event.position.x
				_drag_accumulator = 0.0
				_drag_moved = false
		elif _is_dragging:
			_is_dragging = false
			_drag_accumulator = 0.0
	elif event is InputEventScreenDrag and _is_dragging:
		_drag_accumulator += event.relative.x
		if abs(event.position.x - _drag_start_x) >= DRAG_MOVED_THRESHOLD:
			_drag_moved = true
		while _drag_accumulator >= DRAG_STAGE_THRESHOLD:
			_scroll_by(-1)
			_drag_accumulator -= DRAG_STAGE_THRESHOLD
		while _drag_accumulator <= -DRAG_STAGE_THRESHOLD:
			_scroll_by(1)
			_drag_accumulator += DRAG_STAGE_THRESHOLD


func update_view(current_level: int, max_unlocked_level: int) -> void:
	_current_level = current_level
	_max_unlocked_level = max_unlocked_level
	if not _has_initialized_view:
		visible_center_level = current_level
		_has_initialized_view = true
	_clamp_center()
	_refresh_buttons()


func center_on_level(level: int) -> void:
	visible_center_level = level
	_clamp_center()
	_refresh_buttons()


func _clamp_center() -> void:
	var min_center: int = SIDE_COUNT + 1
	var max_center: int = maxi(_max_unlocked_level, min_center)
	visible_center_level = clampi(visible_center_level, min_center, max_center)


func _scroll_by(delta_levels: int) -> void:
	visible_center_level += delta_levels
	_clamp_center()
	_refresh_buttons()


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
	if _drag_moved:
		return
	var stage_level: int = visible_center_level - SIDE_COUNT + button_index
	if stage_level < 1 or stage_level > _max_unlocked_level:
		return
	if stage_level == _current_level:
		return
	stage_selected.emit(stage_level)


func _on_scroll_left() -> void:
	_scroll_by(-1)


func _on_scroll_right() -> void:
	_scroll_by(1)
