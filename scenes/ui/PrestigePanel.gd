class_name PrestigePanel
extends VBoxContainer

signal prestige_requested
signal prestige_talent_purchase_requested(talent_index: int)

@onready var available_points_label: Label = $InfoGrid/AvailablePointsLabel
@onready var total_points_earned_label: Label = $InfoGrid/TotalPointsEarnedLabel
@onready var prestige_button: Button = $PrestigeButton
@onready var talent_1_label: Label = $Talent1Row/Talent1Label
@onready var talent_1_button: Button = $Talent1Row/Talent1Button
@onready var talent_2_label: Label = $Talent2Row/Talent2Label
@onready var talent_2_button: Button = $Talent2Row/Talent2Button
@onready var talent_3_label: Label = $Talent3Row/Talent3Label
@onready var talent_3_button: Button = $Talent3Row/Talent3Button


func _ready() -> void:
	prestige_button.pressed.connect(_on_prestige_button_pressed)
	talent_1_button.pressed.connect(func() -> void: prestige_talent_purchase_requested.emit(0))
	talent_2_button.pressed.connect(func() -> void: prestige_talent_purchase_requested.emit(1))
	talent_3_button.pressed.connect(func() -> void: prestige_talent_purchase_requested.emit(2))


func update_view(state: ClickerState) -> void:
	var stage_points: int = state.get_prestige_stage_points()
	var character_points: int = state.get_prestige_character_points()
	var total_reward: int = state.get_prestige_reward()

	available_points_label.text = "Available Points: %d" % state.prestige_points_available
	total_points_earned_label.text = "Total Earned: %d" % state.prestige_points_total_earned

	prestige_button.disabled = total_reward <= 0
	prestige_button.text = "Prestige - Gain %d Points" % total_reward
	_update_talent_row(state, 0, talent_1_label, talent_1_button)
	_update_talent_row(state, 1, talent_2_label, talent_2_button)
	_update_talent_row(state, 2, talent_3_label, talent_3_button)


func _on_prestige_button_pressed() -> void:
	prestige_requested.emit()


func _update_talent_row(state: ClickerState, talent_index: int, label: Label, button: Button) -> void:
	var level: int = state.prestige_talent_levels[talent_index]
	var total_bonus: int = level * state.prestige_talent_bonus_percent_per_level
	var cost: int = state.get_prestige_talent_cost(talent_index)
	label.text = "%s: Lv %d | +%d%% each | +%d%% total" % [
		state.prestige_talent_names[talent_index],
		level,
		state.prestige_talent_bonus_percent_per_level,
		total_bonus,
	]
	button.disabled = state.prestige_points_available < cost
	button.text = "Upgrade - Cost: %d" % cost
