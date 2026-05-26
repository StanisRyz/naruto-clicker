class_name PrestigePanel
extends VBoxContainer

signal prestige_requested

@onready var current_points_label: Label = $InfoGrid/CurrentPointsLabel
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


func _ready() -> void:
	prestige_button.pressed.connect(_on_prestige_button_pressed)


func update_view(state: ClickerState) -> void:
	var stage_points: int = state.get_prestige_stage_points()
	var character_points: int = state.get_prestige_character_points()
	var total_reward: int = state.get_prestige_reward()
	var current_damage_bonus: int = int((state.get_prestige_damage_multiplier() - 1.0) * 100.0)
	var current_gold_bonus: int = int((state.get_prestige_gold_multiplier() - 1.0) * 100.0)
	var next_points: int = state.prestige_points + total_reward
	var next_damage_bonus: int = int(next_points * state.prestige_damage_bonus_per_point * 100.0)
	var next_gold_bonus: int = int(next_points * state.prestige_gold_bonus_per_point * 100.0)

	current_points_label.text = "Prestige Points: %d" % state.prestige_points
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


func _on_prestige_button_pressed() -> void:
	prestige_requested.emit()
