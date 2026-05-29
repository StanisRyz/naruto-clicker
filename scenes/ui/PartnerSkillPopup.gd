class_name PartnerSkillPopup
extends Control

signal skill_purchase_requested(skill_id: String)

@onready var outside_click_area: ColorRect = $OutsideClickArea
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
	outside_click_area.gui_input.connect(_on_outside_click_area_gui_input)
	panel_container.gui_input.connect(_on_panel_container_gui_input)
	close_button.pressed.connect(func() -> void: hide())
	buy_button.pressed.connect(_on_buy_button_pressed)
	hide()


func show_skill(state: ClickerState, skill_id: String, anchor_global_position: Vector2) -> void:
	current_skill_id = skill_id
	current_anchor_global_position = anchor_global_position
	_update_view(state)
	show()
	panel_container.reset_size()
	call_deferred("_position_panel")


func refresh_view(state: ClickerState) -> void:
	if visible and current_skill_id != "":
		_update_view(state)


func _update_view(state: ClickerState) -> void:
	var skill: Dictionary = state.get_partner_skill(current_skill_id)
	if skill.is_empty():
		hide()
		return

	var partner_index: int = int(skill.get("partner_index", -1))
	var unlock_count: int = int(skill.get("unlock_count", 0))
	var partner_name: String = "Partner"
	if partner_index >= 0 and partner_index < state.partner_names.size():
		partner_name = state.partner_names[partner_index]
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

	panel_container.reset_size()


func _position_panel() -> void:
	var local_anchor: Vector2 = get_global_transform().affine_inverse() * current_anchor_global_position
	panel_container.reset_size()
	var panel_size: Vector2 = panel_container.get_combined_minimum_size()
	panel_container.size = panel_size
	var desired_position := local_anchor + Vector2(-120.0, -panel_size.y - 12.0)
	var viewport_size: Vector2 = get_viewport_rect().size
	desired_position.x = clampf(desired_position.x, 8.0, maxf(8.0, viewport_size.x - panel_size.x - 8.0))
	desired_position.y = clampf(desired_position.y, 8.0, maxf(8.0, viewport_size.y - panel_size.y - 112.0))
	panel_container.position = desired_position


func _on_buy_button_pressed() -> void:
	if current_skill_id != "":
		skill_purchase_requested.emit(current_skill_id)


func _on_outside_click_area_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			accept_event()
			hide()
	elif event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
		if touch_event.pressed:
			accept_event()
			hide()


func _on_panel_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		accept_event()
