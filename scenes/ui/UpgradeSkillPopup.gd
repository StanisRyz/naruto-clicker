class_name UpgradeSkillPopup
extends Control

signal hero_skill_purchase_requested(skill_id: String)
signal ability_skill_purchase_requested(skill_id: String)

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
var current_owner_type: String = ""
var current_anchor_global_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	panel_container.gui_input.connect(_on_panel_container_gui_input)
	close_button.pressed.connect(func() -> void: hide())
	buy_button.pressed.connect(_on_buy_button_pressed)
	hide()


func show_skill(state: ClickerState, owner_type: String, skill_id: String, anchor_global_position: Vector2) -> void:
	current_owner_type = owner_type
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
	var skill: Dictionary = state.get_hero_skill(current_skill_id) if current_owner_type == "hero" else state.get_ability_skill(current_skill_id)
	if skill.is_empty():
		hide()
		return

	var unlock_level: int = int(skill.get("unlock_character_level", 0))
	var cost: int = state.get_hero_skill_cost(current_skill_id) if current_owner_type == "hero" else state.get_ability_skill_cost(current_skill_id)
	var skill_state: String = state.get_hero_skill_state(current_skill_id) if current_owner_type == "hero" else state.get_ability_skill_state(current_skill_id)
	var ability_id: String = String(skill.get("ability_id", ""))

	name_label.text = String(skill.get("name", "Upgrade Skill"))
	description_label.text = String(skill.get("description", ""))
	if current_owner_type == "ability" and not state.is_ability_purchased(ability_id):
		requirement_label.text = "Requires: Buy %s first" % _get_ability_display_name(ability_id)
	else:
		requirement_label.text = "Requires: Hero Level %d" % unlock_level
	current_label.text = "Current: %d / %d" % [state.character_level, unlock_level]
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
			buy_button.disabled = not _can_buy_current_skill(state)


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


func _can_buy_current_skill(state: ClickerState) -> bool:
	return state.can_buy_hero_skill(current_skill_id) if current_owner_type == "hero" else state.can_buy_ability_skill(current_skill_id)


func _get_ability_display_name(ability_id: String) -> String:
	match ability_id:
		"autoclick": return "Autoclick"
		"gold_bonus": return "Gold Bonus"
		"focus_burst": return "Focus Burst"
		"rally": return "Rally"
	return "Ability"


func _on_buy_button_pressed() -> void:
	if current_skill_id == "":
		return
	if current_owner_type == "hero":
		hero_skill_purchase_requested.emit(current_skill_id)
	else:
		ability_skill_purchase_requested.emit(current_skill_id)


func _on_panel_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		accept_event()
