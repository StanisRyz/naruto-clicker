class_name AutoTransitionPopup
extends Control

signal auto_transition_toggled(enabled: bool)

var _state: ClickerState = null

@onready var _panel: PanelContainer = $PanelContainer
@onready var _status_label: Label = $PanelContainer/MarginContainer/VBoxContainer/StatusLabel
@onready var _toggle_button: Button = $PanelContainer/MarginContainer/VBoxContainer/ToggleButton
@onready var _close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/TitleRow/CloseButton


func _ready() -> void:
	visible = false
	mouse_filter = MOUSE_FILTER_PASS
	_close_button.pressed.connect(hide_popup)
	_toggle_button.pressed.connect(_on_toggle_pressed)


func show_popup(state: ClickerState, _anchor_global_position: Vector2) -> void:
	_state = state
	refresh_view(state)
	mouse_filter = MOUSE_FILTER_STOP
	visible = true


func refresh_view(state: ClickerState) -> void:
	if state.auto_stage_advance_enabled:
		_status_label.text = "Status: ON"
		_toggle_button.text = "Turn OFF"
	else:
		_status_label.text = "Status: OFF"
		_toggle_button.text = "Turn ON"


func hide_popup() -> void:
	visible = false
	mouse_filter = MOUSE_FILTER_PASS
	_state = null


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if not _panel.get_global_rect().has_point(event.global_position):
			hide_popup()
		accept_event()


func _on_toggle_pressed() -> void:
	if _state == null:
		return
	auto_transition_toggled.emit(not _state.auto_stage_advance_enabled)
