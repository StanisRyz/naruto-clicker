class_name AutoTransitionPopup
extends Control

signal auto_button_pressed_through(anchor_global_position: Vector2, button_global_rect: Rect2)

const POPUP_WIDTH: float = 300.0
const POPUP_MARGIN: float = 6.0

var _state: ClickerState = null
var _pending_anchor: Vector2 = Vector2.ZERO
var _auto_button_global_rect: Rect2 = Rect2()

@onready var _panel: PanelContainer = $PanelContainer
@onready var _status_label: Label = $PanelContainer/MarginContainer/VBoxContainer/StatusLabel
@onready var _close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/TitleRow/CloseButton


func _ready() -> void:
	visible = false
	mouse_filter = MOUSE_FILTER_PASS
	_close_button.pressed.connect(hide_popup)


func show_popup(state: ClickerState, anchor: Vector2, button_global_rect: Rect2 = Rect2()) -> void:
	_state = state
	_pending_anchor = anchor
	_auto_button_global_rect = button_global_rect
	refresh_view(state)
	mouse_filter = MOUSE_FILTER_STOP
	visible = true
	call_deferred("_deferred_resize_and_position_popup")


func refresh_view(state: ClickerState) -> void:
	_status_label.text = "Status: ON" if state.auto_stage_advance_enabled else "Status: OFF"


func hide_popup() -> void:
	visible = false
	mouse_filter = MOUSE_FILTER_PASS
	_state = null


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		accept_event()
		if not _panel.get_global_rect().has_point(event.global_position):
			if _auto_button_global_rect != Rect2() and _auto_button_global_rect.has_point(event.global_position):
				auto_button_pressed_through.emit(_pending_anchor, _auto_button_global_rect)
			else:
				hide_popup()


func _deferred_resize_and_position_popup() -> void:
	if not visible:
		return
	_panel.reset_size()
	var minimum_size: Vector2 = _panel.get_combined_minimum_size()
	_panel.size = Vector2(POPUP_WIDTH, minimum_size.y)
	_position_popup(_pending_anchor)


func _position_popup(anchor: Vector2) -> void:
	var panel_size: Vector2 = _panel.size
	var viewport_size: Vector2 = get_viewport_rect().size
	var x: float = clampf(anchor.x - panel_size.x * 0.5, POPUP_MARGIN, viewport_size.x - panel_size.x - POPUP_MARGIN)
	var y: float = anchor.y + POPUP_MARGIN
	if y + panel_size.y > viewport_size.y - POPUP_MARGIN:
		y = anchor.y - panel_size.y - POPUP_MARGIN
	y = maxf(POPUP_MARGIN, y)
	_panel.position = Vector2(x, y)
