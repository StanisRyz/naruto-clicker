class_name StageNavigator
extends Control

signal stage_selected(level: int)
signal latest_requested
signal auto_transition_popup_requested(anchor_global_position: Vector2, button_global_rect: Rect2)

const DISPLAY_COUNT: int = 5
const SIDE_COUNT: int = 2
const BUTTON_SIZE: int = 80
const SIDE_BUTTON_SIZE: int = 80
const DRAG_STAGE_THRESHOLD: float = 60.0
const DRAG_MOVED_THRESHOLD: float = 8.0
const STAGE_NUMBER_LABEL_HEIGHT: int = 28
const STAGE_NUMBER_LABEL_OUTSIDE_OFFSET: int = 14
const STAGE_NAVIGATOR_EXTRA_BOTTOM_SPACE: int = 18

const COLOR_CURRENT: Color = Color(0.2, 0.4, 0.9, 1.0)
const COLOR_UNLOCKED: Color = Color(1.0, 1.0, 1.0, 1.0)
const COLOR_LOCKED: Color = Color(0.35, 0.35, 0.35, 1.0)
const LOCKED_STAGE_MODULATE: Color = Color(0.35, 0.35, 0.35, 1.0)
const NORMAL_STAGE_MODULATE: Color = Color(1.0, 1.0, 1.0, 1.0)
const COLOR_LATEST: Color = Color(0.8, 0.7, 0.1, 1.0)
const COLOR_AUTO_ON: Color = Color(0.2, 0.75, 0.2, 1.0)
const COLOR_AUTO_OFF: Color = Color(0.45, 0.45, 0.45, 1.0)

const ImageSlotClass = preload("res://scripts/ui/ImageSlot.gd")
const StageNavigationAssetCatalogClass = preload("res://scripts/ui/StageNavigationAssetCatalog.gd")

var visible_center_level: int = SIDE_COUNT + 1
var _current_level: int = 1
var _max_unlocked_level: int = 1
var _has_initialized_view: bool = false
var _last_centered_current_level: int = -1
var _auto_transition_enabled: bool = true

var _stage_buttons: Array = []
var _stage_rects: Array = []
var _stage_labels: Array = []
var _stage_current_overlays: Array = []
var _stage_locked_overlays: Array = []
var _latest_button: Button
var _auto_btn: Button
var _auto_btn_rect = null


var _is_dragging: bool = false
var _drag_start_x: float = 0.0
var _drag_last_x: float = 0.0
var _drag_accumulator: float = 0.0
var _drag_moved: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2(0, BUTTON_SIZE + STAGE_NAVIGATOR_EXTRA_BOTTOM_SPACE)
	mouse_filter = MOUSE_FILTER_STOP
	_build_ui()
	_refresh_buttons()


func _build_ui() -> void:
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 10)
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.mouse_filter = MOUSE_FILTER_PASS
	add_child(hbox)

	_auto_btn = _make_side_button(COLOR_AUTO_ON)
	_auto_btn.size_flags_vertical = 0
	_auto_btn_rect = _auto_btn.get_child(0)
	_auto_btn.pressed.connect(_on_auto_transition_button_pressed)
	_clear_button_visual_styles(_auto_btn)
	hbox.add_child(_auto_btn)
	_auto_btn_rect.set_asset_key("stage.auto_on", COLOR_AUTO_ON)

	for i: int in DISPLAY_COUNT:
		var slot: Control = Control.new()
		slot.custom_minimum_size = Vector2(BUTTON_SIZE, BUTTON_SIZE + STAGE_NAVIGATOR_EXTRA_BOTTOM_SPACE)
		slot.mouse_filter = MOUSE_FILTER_PASS

		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
		btn.offset_left = 0
		btn.offset_top = 0
		btn.offset_right = BUTTON_SIZE
		btn.offset_bottom = BUTTON_SIZE
		btn.flat = true
		btn.mouse_filter = MOUSE_FILTER_STOP

		var rect = ImageSlotClass.new()
		rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		rect.mouse_filter = MOUSE_FILTER_IGNORE
		rect.fallback_color = COLOR_LOCKED
		rect.show_fallback_behind_texture = false
		btn.add_child(rect)

		var current_overlay = ImageSlotClass.new()
		current_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		current_overlay.mouse_filter = MOUSE_FILTER_IGNORE
		current_overlay.fallback_color = Color.TRANSPARENT
		current_overlay.show_fallback_behind_texture = false
		current_overlay.visible = false
		btn.add_child(current_overlay)

		var locked_overlay = ImageSlotClass.new()
		locked_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		locked_overlay.mouse_filter = MOUSE_FILTER_IGNORE
		locked_overlay.fallback_color = Color.TRANSPARENT
		locked_overlay.show_fallback_behind_texture = false
		locked_overlay.visible = false
		btn.add_child(locked_overlay)

		_clear_button_visual_styles(btn)
		slot.add_child(btn)

		var label_y: int = BUTTON_SIZE - (STAGE_NUMBER_LABEL_HEIGHT >> 1)
		var label: Label = Label.new()
		label.offset_left = 0
		label.offset_top = label_y
		label.offset_right = BUTTON_SIZE
		label.offset_bottom = label_y + STAGE_NUMBER_LABEL_HEIGHT
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", UiFontConfig.STAGE_NAV_STAGE_NUMBER_FONT_SIZE)
		label.mouse_filter = MOUSE_FILTER_IGNORE
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		slot.add_child(label)

		var captured_index: int = i
		btn.pressed.connect(func() -> void: _on_stage_button_pressed(captured_index))
		hbox.add_child(slot)

		_stage_buttons.append(btn)
		_stage_rects.append(rect)
		_stage_labels.append(label)
		_stage_current_overlays.append(current_overlay)
		_stage_locked_overlays.append(locked_overlay)

	_latest_button = _make_side_button(COLOR_LATEST)
	_latest_button.size_flags_vertical = 0
	_latest_button.pressed.connect(_on_latest_button_pressed)
	_clear_button_visual_styles(_latest_button)
	hbox.add_child(_latest_button)
	_latest_button.get_child(0).set_asset_key("stage.latest", COLOR_LATEST)



func _make_side_button(bg_color: Color) -> Button:
	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(SIDE_BUTTON_SIZE, BUTTON_SIZE)
	btn.flat = true
	btn.mouse_filter = MOUSE_FILTER_STOP

	var rect = ImageSlotClass.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = MOUSE_FILTER_IGNORE
	rect.fallback_color = bg_color
	rect.show_fallback_behind_texture = false
	btn.add_child(rect)

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
		_last_centered_current_level = current_level
		_has_initialized_view = true
	elif current_level != _last_centered_current_level:
		visible_center_level = current_level
		_last_centered_current_level = current_level
	_clamp_center()
	_refresh_buttons()


func center_on_level(level: int) -> void:
	visible_center_level = level
	_clamp_center()
	_refresh_buttons()


func center_on_latest_level() -> void:
	visible_center_level = _max_unlocked_level
	_clamp_center()
	_refresh_buttons()


func set_auto_transition_enabled(enabled: bool) -> void:
	_auto_transition_enabled = enabled
	if _auto_btn_rect != null:
		if enabled:
			_auto_btn_rect.set_asset_key("stage.auto_on", COLOR_AUTO_ON)
		else:
			_auto_btn_rect.set_asset_key("stage.auto_off", COLOR_AUTO_OFF)


func _clear_button_visual_styles(button: Button) -> void:
	var empty_style := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty_style)
	button.add_theme_stylebox_override("hover", empty_style)
	button.add_theme_stylebox_override("pressed", empty_style)
	button.add_theme_stylebox_override("disabled", empty_style)
	button.add_theme_stylebox_override("focus", empty_style)
	button.focus_mode = Control.FOCUS_NONE


func _clear_stage_button_focuses() -> void:
	for button: Button in _stage_buttons:
		button.release_focus()
	if _latest_button != null:
		_latest_button.release_focus()
	if _auto_btn != null:
		_auto_btn.release_focus()


func _clamp_center() -> void:
	var min_center: int = SIDE_COUNT + 1
	var max_center: int = maxi(_max_unlocked_level, min_center)
	visible_center_level = clampi(visible_center_level, min_center, max_center)


func _scroll_by(delta_levels: int) -> void:
	visible_center_level += delta_levels
	_clamp_center()
	_refresh_buttons()


func _refresh_buttons() -> void:
	var locked_overlay_texture: Texture2D = StageNavigationAssetCatalogClass.load_locked_overlay_texture()
	var current_overlay_texture: Texture2D = StageNavigationAssetCatalogClass.load_current_overlay_texture()
	for i: int in DISPLAY_COUNT:
		var stage_level: int = visible_center_level - SIDE_COUNT + i
		var btn: Button = _stage_buttons[i]
		var rect = _stage_rects[i]
		var label: Label = _stage_labels[i]
		var current_overlay = _stage_current_overlays[i]
		var locked_overlay = _stage_locked_overlays[i]

		label.text = str(stage_level)

		var is_current: bool = stage_level == _current_level
		var is_unlocked: bool = stage_level <= _max_unlocked_level
		var is_locked: bool = not is_unlocked and not is_current

		var fallback_color: Color = COLOR_LOCKED
		if is_current:
			fallback_color = COLOR_CURRENT
		elif is_unlocked:
			fallback_color = COLOR_UNLOCKED

		var stage_texture: Texture2D = StageNavigationAssetCatalogClass.load_stage_texture_for_level(stage_level)
		rect.set_direct_texture(stage_texture, fallback_color, false)
		rect.modulate = LOCKED_STAGE_MODULATE if is_locked else NORMAL_STAGE_MODULATE

		if is_current and current_overlay_texture != null:
			current_overlay.set_direct_texture(current_overlay_texture, Color.TRANSPARENT, false)
			current_overlay.visible = true
		else:
			current_overlay.visible = false

		if is_locked and locked_overlay_texture != null:
			locked_overlay.set_direct_texture(locked_overlay_texture, Color.TRANSPARENT, false)
			locked_overlay.visible = true
		else:
			locked_overlay.visible = false

		btn.disabled = is_locked


func _on_stage_button_pressed(button_index: int) -> void:
	if _drag_moved:
		return
	var stage_level: int = visible_center_level - SIDE_COUNT + button_index
	if stage_level < 1 or stage_level > _max_unlocked_level:
		return
	if stage_level == _current_level:
		return
	_clear_stage_button_focuses()
	stage_selected.emit(stage_level)


func _on_latest_button_pressed() -> void:
	latest_requested.emit()


func _on_auto_transition_button_pressed() -> void:
	var btn_rect: Rect2 = _auto_btn.get_global_rect()
	auto_transition_popup_requested.emit(Vector2(btn_rect.get_center().x, btn_rect.end.y), btn_rect)
