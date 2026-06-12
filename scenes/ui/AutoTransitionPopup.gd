class_name AutoTransitionPopup
extends Control

signal auto_button_pressed_through(anchor_global_position: Vector2, button_global_rect: Rect2)

const POPUP_WIDTH: float = 340.0
const POPUP_HEIGHT: float = 220.0
const POPUP_MARGIN: float = 6.0

const ImageSlotClass = preload("res://scripts/ui/ImageSlot.gd")

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
	_add_background_image_holder(_panel, "PopupBackgroundImageHolder", "ui.popup.auto_transition.background")
	_make_image_icon_button(_close_button, "ui.sheet.close_button")


func show_popup(state: ClickerState, anchor: Vector2, button_global_rect: Rect2 = Rect2()) -> void:
	_state = state
	_pending_anchor = anchor
	_auto_button_global_rect = button_global_rect
	refresh_view(state)
	mouse_filter = MOUSE_FILTER_STOP
	visible = true
	call_deferred("_deferred_resize_and_position_popup")


func refresh_view(state: ClickerState) -> void:
	if state.auto_stage_advance_enabled:
		_status_label.text = LocalizationManager.tr_key("auto_transition.status_on")
	else:
		_status_label.text = LocalizationManager.tr_key("auto_transition.status_off")


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
	_panel.size = Vector2(POPUP_WIDTH, POPUP_HEIGHT)
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


func _add_background_image_holder(container: Control, holder_name: String, asset_key: String) -> void:
	var holder = ImageSlotClass.new()
	holder.name = holder_name
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.fallback_color = Color.WHITE
	holder.show_fallback_behind_texture = false
	holder.stretch_mode = TextureRect.STRETCH_SCALE
	container.add_child(holder)
	container.move_child(holder, 0)
	holder.set_asset_key(asset_key, Color.WHITE)


func _make_image_icon_button(button: Button, asset_key: String) -> void:
	ButtonVisualUtils.clear_image_button_styles(button)
	button.text = ""
	var holder = ImageSlotClass.new()
	holder.name = "ButtonImageHolder"
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.fallback_color = Color.WHITE
	holder.show_fallback_behind_texture = false
	holder.stretch_mode = TextureRect.STRETCH_SCALE
	button.add_child(holder)
	holder.set_asset_key(asset_key, Color.WHITE)
