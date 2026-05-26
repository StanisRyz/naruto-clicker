class_name PrestigePanel
extends VBoxContainer

signal prestige_requested
signal prestige_talent_purchase_requested(talent_index: int)

@onready var available_points_label: Label = $InfoGrid/AvailablePointsLabel
@onready var total_points_earned_label: Label = $InfoGrid/TotalPointsEarnedLabel
@onready var total_prestiges_label: Label = $InfoGrid/TotalPrestigesLabel
@onready var current_level_label: Label = $InfoGrid/CurrentLevelLabel
@onready var character_level_label: Label = $InfoGrid/CharacterLevelLabel
@onready var stage_points_label: Label = $InfoGrid/StagePointsLabel
@onready var character_points_label: Label = $InfoGrid/CharacterPointsLabel
@onready var total_points_label: Label = $InfoGrid/TotalPointsLabel
@onready var damage_bonus_label: Label = $InfoGrid/DamageBonusLabel
@onready var gold_bonus_label: Label = $InfoGrid/GoldBonusLabel
@onready var next_bonus_label: Label = $NextBonusLabel
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
	var current_damage_bonus: int = int((state.get_prestige_damage_multiplier() - 1.0) * 100.0)
	var current_gold_bonus: int = int((state.get_prestige_gold_multiplier() - 1.0) * 100.0)
	var next_points: int = state.prestige_points_total_earned + total_reward
	var next_damage_bonus: int = int(next_points * state.prestige_damage_bonus_per_point * 100.0)
	var next_gold_bonus: int = int(next_points * state.prestige_gold_bonus_per_point * 100.0)

	available_points_label.text = "Available Points: %d" % state.prestige_points_available
	total_points_earned_label.text = "Total Earned: %d" % state.prestige_points_total_earned
	total_prestiges_label.text = "Total Prestiges: %d" % state.total_prestiges
	current_level_label.text = "Stage Level: %d" % state.current_level
	character_level_label.text = "Character Level: %d" % state.character_level
	stage_points_label.text = "Stage Points: +%d" % stage_points
	character_points_label.text = "Character Points: +%d" % character_points
	total_points_label.text = "Total Points: +%d" % total_reward
	damage_bonus_label.text = "Damage Bonus: +%d%%" % current_damage_bonus
	gold_bonus_label.text = "Gold Bonus: +%d%%" % current_gold_bonus
	next_bonus_label.text = "After Prestige: Damage +%d%% | Gold +%d%%" % [
		next_damage_bonus,
		next_gold_bonus,
	]

	prestige_button.disabled = total_reward <= 0
	prestige_button.text = "Prestige" if total_reward <= 0 else "Prestige - Gain %d Points" % total_reward
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
