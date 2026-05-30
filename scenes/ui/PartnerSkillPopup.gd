class_name PartnerSkillPopup
extends Control

signal skill_purchase_requested(skill_id: String)

const POPUP_WIDTH: float = 260.0
const POPUP_MARGIN: float = 8.0
const BOTTOM_SAFE_MARGIN: float = 112.0

@onready var panel_container: PanelContainer = $PanelContainer
@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/Header/CloseButton
@onready var name_label: Label = $PanelContainer/MarginContainer/VBoxContainer/Header/NameLabel
@onready var description_label: Label = $PanelContainer/MarginContainer/VBoxContainer/DescriptionLabel
@onready var requirement_label: Label = $PanelContainer/MarginContainer/VBoxContainer/RequirementLabel
@onready var current_label: Label = $PanelContainer/MarginContainer/VBoxContainer/CurrentLabel
@onready var cost_label: Label = $PanelContainer/MarginContainer/VBoxContainer/CostLabel
@onready var buy_button: Button = $PanelContainer/MarginContainer/VBoxContainer/BuyButton

var current_skill_id: String = ""
var current_anchor_global_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	panel_container.gui_input.connect(_on_panel_container_gui_input)
	close_button.pressed.connect(func() -> void: hide())
	buy_button.pressed.connect(_on_buy_button_pressed)
	hide()


func show_skill(state: ClickerState, skill_id: String, anchor_global_position: Vector2) -> void:
	current_skill_id = skill_id
	current_anchor_global_position = anchor_global_position
	_update_view(state)
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

	var cost: int = state.get_partner_skill_cost(current_skill_id)
	var skill_state: String = state.get_partner_skill_state(current_skill_id)

	name_label.text = String(skill.get("name", "Partner Skill"))
	description_label.text = String(skill.get("description", ""))
	requirement_label.text = "Requires: %d %s" % [unlock_count, partner_name]
	current_label.text = "Current: %d / %d" % [current_count, unlock_count]
	cost_label.text = "Cost: %d gold" % cost

	match skill_state:
		"purchased":
			buy_button.disabled = true
			buy_button.text = "Purchased"
		"locked":
			buy_button.disabled = true
			buy_button.text = "Locked"
		_:
			buy_button.text = "Buy: %d" % cost
			buy_button.disabled = not state.can_buy_partner_skill(current_skill_id)


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


func _deferred_resize_and_position_panel() -> void:
	panel_container.size = Vector2(POPUP_WIDTH, 0)
	panel_container.reset_size()
	await get_tree().process_frame
	var panel_height: float = panel_container.get_combined_minimum_size().y
	panel_container.size = Vector2(POPUP_WIDTH, panel_height)
	_position_panel(Vector2(POPUP_WIDTH, panel_height))


func _position_panel(panel_size: Vector2) -> void:
	var local_anchor: Vector2 = get_global_transform().affine_inverse() * current_anchor_global_position
	var desired_position := local_anchor + Vector2(-120.0, -panel_size.y - 12.0)
	var viewport_size: Vector2 = get_viewport_rect().size
	desired_position.x = clampf(desired_position.x, POPUP_MARGIN, maxf(POPUP_MARGIN, viewport_size.x - panel_size.x - POPUP_MARGIN))
	desired_position.y = clampf(desired_position.y, POPUP_MARGIN, maxf(POPUP_MARGIN, viewport_size.y - panel_size.y - BOTTOM_SAFE_MARGIN))
	panel_container.position = desired_position


func _on_buy_button_pressed() -> void:
	if current_skill_id != "":
		skill_purchase_requested.emit(current_skill_id)


func _on_panel_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		accept_event()
