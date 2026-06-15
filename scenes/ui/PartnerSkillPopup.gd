class_name PartnerSkillPopup
extends Control

signal skill_purchase_requested(skill_id: String)

const POPUP_WIDTH: float = 350.0
const POPUP_HEIGHT: float = 270.0
const POPUP_SIZE: Vector2 = Vector2(POPUP_WIDTH, POPUP_HEIGHT)
const POPUP_MARGIN: float = 8.0
const BOTTOM_SAFE_MARGIN: float = 112.0

const MARGIN_LEFT: int = 17
const MARGIN_TOP: int = 25
const MARGIN_RIGHT: int = 17
const CONTENT_WIDTH: int = 316

const ImageSlotClass = preload("res://scripts/ui/ImageSlot.gd")

@onready var panel_container: PanelContainer = $PanelContainer
@onready var name_label: Label = $PanelContainer/ContentRoot/Header/NameLabel
@onready var effect_label: Label = $PanelContainer/ContentRoot/EffectLabel
@onready var requirement_label: Label = $PanelContainer/ContentRoot/RequirementLabel
@onready var current_state_label: Label = $PanelContainer/ContentRoot/CurrentStateLabel
@onready var buy_button: Button = $PanelContainer/ContentRoot/BuyButton

var current_skill_id: String = ""
var current_anchor_global_position: Vector2 = Vector2.ZERO

var _buy_button_label: Label = null
var _buy_button_disabled_overlay: ColorRect = null


func _ready() -> void:
	panel_container.gui_input.connect(_on_panel_container_gui_input)
	buy_button.pressed.connect(_on_buy_button_pressed)
	_add_background_image_holder(panel_container, "PopupBackgroundImageHolder", "ui.popup.skill.background")
	_buy_button_label = _make_image_button_label(buy_button, "ui.popup.button.default", "")
	_buy_button_disabled_overlay = _ensure_disabled_button_overlay(buy_button)
	_apply_fixed_panel_size()
	_apply_fixed_row_layout()
	hide()


func is_showing_skill(skill_id: String) -> bool:
	return visible and current_skill_id == skill_id


func show_skill(state: ClickerState, skill_id: String, anchor_global_position: Vector2) -> void:
	current_skill_id = skill_id
	current_anchor_global_position = anchor_global_position
	_apply_fixed_panel_size()
	_apply_fixed_row_layout()
	_update_view(state)
	_apply_fixed_panel_size()
	_apply_fixed_row_layout()
	_position_panel(POPUP_SIZE)
	show()
	call_deferred("_deferred_resize_and_position_panel")


func refresh_view(state: ClickerState) -> void:
	if visible and current_skill_id != "":
		_update_view(state)
		call_deferred("_deferred_resize_and_position_panel")


func _update_view(state: ClickerState) -> void:
	var skill: Dictionary = state.get_partner_skill(current_skill_id)
	if skill.is_empty():
		hide()
		return

	var partner_index: int = int(skill.get("partner_index", -1))
	var unlock_count: int = int(skill.get("unlock_count", 0))
	var partner_name: String = "Partner"
	if partner_index >= 0 and partner_index < PartnerConfig.PARTNER_NAMES.size():
		partner_name = PartnerConfig.PARTNER_NAMES[partner_index]
	var current_count: int = 0
	if partner_index >= 0 and partner_index < state.partner_counts.size():
		current_count = state.partner_counts[partner_index]

	var cost: BigNumber = state.get_partner_skill_cost(current_skill_id)
	var skill_state: String = state.get_partner_skill_state(current_skill_id)

	var L := LocalizationManager
	name_label.text = String(skill.get("name", L.tr_key("skill_popup.partner.title")))
	effect_label.text = String(skill.get("description", ""))
	requirement_label.text = L.format_key("skill_popup.requirement.partner_count", {"count": unlock_count, "partner": partner_name})

	if current_count >= unlock_count:
		current_state_label.text = L.tr_key("skill_popup.current.unlocked")
	else:
		current_state_label.text = L.format_key("skill_popup.current.partner_count", {"current": current_count, "required": unlock_count})

	match skill_state:
		"purchased":
			buy_button.disabled = true
			_buy_button_label.text = L.tr_key("skill_popup.button.purchased")
		"locked":
			buy_button.disabled = true
			_buy_button_label.text = L.tr_key("skill_popup.button.locked")
		_:
			_buy_button_label.text = L.format_key("skill_popup.button.buy", {"cost": NumberFormatter.compact(cost)})
			buy_button.disabled = not state.can_buy_partner_skill(current_skill_id)
	_update_buy_button_disabled_overlay()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	var press_pos: Vector2 = Vector2.INF
	if event is InputEventMouseButton:
		var me := event as InputEventMouseButton
		if me.button_index == MOUSE_BUTTON_LEFT and me.pressed:
			press_pos = me.global_position
	elif event is InputEventScreenTouch:
		var te := event as InputEventScreenTouch
		if te.pressed:
			press_pos = te.position
	if press_pos == Vector2.INF:
		return
	if panel_container.get_global_rect().has_point(press_pos):
		return
	# Outside panel: hide without consuming so skill icon buttons still receive the event.
	# PanelContainer (STOP) already prevents click-through for inside-panel clicks.
	hide()


func _apply_fixed_panel_size() -> void:
	panel_container.custom_minimum_size = POPUP_SIZE
	panel_container.size = POPUP_SIZE
	panel_container.offset_right = panel_container.offset_left + POPUP_SIZE.x
	panel_container.offset_bottom = panel_container.offset_top + POPUP_SIZE.y
	panel_container.clip_contents = true


func _apply_fixed_row_layout() -> void:
	var header: HBoxContainer = $PanelContainer/ContentRoot/Header
	_place_control(header, MARGIN_LEFT, MARGIN_TOP, CONTENT_WIDTH, 36)
	_place_control(effect_label, MARGIN_LEFT, 67, CONTENT_WIDTH, 34)
	_place_control(requirement_label, MARGIN_LEFT, 107, CONTENT_WIDTH, 34)
	_place_control(current_state_label, MARGIN_LEFT, 147, CONTENT_WIDTH, 34)
	_place_control(buy_button, 93, 187, 163, 56)


func _place_control(control: Control, x: int, y: int, w: int, h: int) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = x
	control.offset_top = y
	control.offset_right = x + w
	control.offset_bottom = y + h
	control.custom_minimum_size = Vector2(w, h)
	control.size = Vector2(w, h)


func _deferred_resize_and_position_panel() -> void:
	_apply_fixed_panel_size()
	_apply_fixed_row_layout()
	_position_panel(POPUP_SIZE)


func _position_panel(panel_size: Vector2) -> void:
	var local_anchor: Vector2 = get_global_transform().affine_inverse() * current_anchor_global_position
	var desired_position := local_anchor + Vector2(-120.0, -panel_size.y - 12.0)
	var viewport_size: Vector2 = get_viewport_rect().size
	desired_position.x = clampf(desired_position.x, POPUP_MARGIN, maxf(POPUP_MARGIN, viewport_size.x - panel_size.x - POPUP_MARGIN))
	desired_position.y = clampf(desired_position.y, POPUP_MARGIN, maxf(POPUP_MARGIN, viewport_size.y - panel_size.y - BOTTOM_SAFE_MARGIN))
	panel_container.position = desired_position


func _ensure_disabled_button_overlay(button: Button) -> ColorRect:
	var existing := button.find_child("DisabledOverlay", false, false)
	if existing != null and existing is ColorRect:
		return existing as ColorRect
	var overlay := ColorRect.new()
	overlay.name = "DisabledOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.color = Color(0, 0, 0, 0.45)
	overlay.visible = false
	button.add_child(overlay)
	var label := button.find_child("ButtonTextLabel", false, false)
	if label != null:
		button.move_child(label, button.get_child_count() - 1)
	return overlay


func _update_buy_button_disabled_overlay() -> void:
	if _buy_button_disabled_overlay == null:
		return
	_buy_button_disabled_overlay.visible = buy_button.disabled


func _on_buy_button_pressed() -> void:
	if current_skill_id == "":
		return
	ButtonVisualUtils.flash_button_image_holder(
		buy_button.find_child("ButtonImageHolder", false, false),
		"ui.popup.button.default"
	)
	skill_purchase_requested.emit(current_skill_id)


func _on_panel_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		accept_event()


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


func _make_image_button_label(button: Button, asset_key: String, initial_text: String) -> Label:
	_make_image_icon_button(button, asset_key)
	var label := Label.new()
	label.name = "ButtonTextLabel"
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.text = initial_text
	button.add_child(label)
	return label
