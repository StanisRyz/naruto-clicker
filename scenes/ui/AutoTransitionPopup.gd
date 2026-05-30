class_name AutoTransitionPopup
extends Control

var _state: ClickerState = null
var _pending_anchor: Vector2 = Vector2.ZERO

@onready var _panel: PanelContainer = $PanelContainer
@onready var _status_label: Label = $PanelContainer/MarginContainer/VBoxContainer/StatusLabel
@onready var _close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/TitleRow/CloseButton


func _ready() -> void:
	visible = false
	mouse_filter = MOUSE_FILTER_PASS
	_close_button.pressed.connect(hide_popup)


func show_popup(state: ClickerState, anchor: Vector2) -> void:
	_state = state
	_pending_anchor = anchor
	refresh_view(state)
	mouse_filter = MOUSE_FILTER_STOP
	visible = true
	await get_tree().process_frame
	if visible:
		_position_popup(_pending_anchor)


func refresh_view(state: ClickerState) -> void:
	_status_label.text = "Status: ON" if state.auto_stage_advance_enabled else "Status: OFF"


func hide_popup() -> void:
	visible = false
	mouse_filter = MOUSE_FILTER_PASS
	_state = null


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if not _panel.get_global_rect().has_point(event.global_position):
			hide_popup()
		accept_event()


func _position_popup(anchor: Vector2) -> void:
	var panel_size: Vector2 = _panel.size
	var viewport_size: Vector2 = get_viewport_rect().size
	const MARGIN: float = 6.0
	var x: float = clampf(anchor.x - panel_size.x * 0.5, MARGIN, viewport_size.x - panel_size.x - MARGIN)
	var y: float = anchor.y + MARGIN
	if y + panel_size.y > viewport_size.y - MARGIN:
		y = anchor.y - panel_size.y - MARGIN
	y = maxf(MARGIN, y)
	_panel.position = Vector2(x, y)
