extends Control

var gold: int = 0
var click_damage: int = 1
var current_level: int = 1
var enemies_defeated_on_level: int = 0
var enemies_required_per_level: int = 10
var target_hp: int = 10
var target_max_hp: int = 10
var reward_gold: int = 5
var damage_upgrade_level: int = 0
var damage_upgrade_cost: int = 10

@onready var gold_label: Label = $MarginContainer/VBoxContainer/StatsContainer/GoldLabel
@onready var damage_label: Label = $MarginContainer/VBoxContainer/StatsContainer/DamageLabel
@onready var level_label: Label = $MarginContainer/VBoxContainer/StatsContainer/LevelLabel
@onready var enemies_defeated_label: Label = $MarginContainer/VBoxContainer/StatsContainer/EnemiesDefeatedLabel
@onready var game_field: Button = $MarginContainer/VBoxContainer/GameField
@onready var enemy_name_label: Label = $MarginContainer/VBoxContainer/GameField/GameFieldContent/EnemyNameLabel
@onready var target_hp_label: Label = $MarginContainer/VBoxContainer/GameField/GameFieldContent/TargetHpLabel
@onready var target_progress_bar: ProgressBar = $MarginContainer/VBoxContainer/GameField/GameFieldContent/TargetProgressBar
@onready var upgrade_damage_button: Button = $MarginContainer/VBoxContainer/UpgradeDamageButton
@onready var status_label: Label = $MarginContainer/VBoxContainer/StatusLabel


func _ready() -> void:
	game_field.pressed.connect(_attack_target)
	upgrade_damage_button.pressed.connect(_on_upgrade_damage_pressed)
	_update_ui()

	await get_tree().process_frame
	YandexBridge.game_ready()
	YandexBridge.gameplay_start()


func _update_ui() -> void:
	gold_label.text = "Gold: %d" % gold
	damage_label.text = "Damage: %d" % click_damage
	level_label.text = "Level: %d" % current_level
	enemies_defeated_label.text = "Enemies: %d / %d" % [enemies_defeated_on_level, enemies_required_per_level]
	enemy_name_label.text = "Enemy"
	target_hp_label.text = "Enemy HP: %d / %d" % [target_hp, target_max_hp]
	target_progress_bar.max_value = target_max_hp
	target_progress_bar.value = target_hp
	upgrade_damage_button.text = "Upgrade Damage - Cost: %d" % damage_upgrade_cost


func _attack_target() -> void:
	target_hp = maxi(target_hp - click_damage, 0)

	if target_hp == 0:
		_defeat_target()
	else:
		status_label.text = "Tap the field to attack!"

	_update_ui()


func _on_upgrade_damage_pressed() -> void:
	if gold < damage_upgrade_cost:
		status_label.text = "Not enough gold"
		return

	gold -= damage_upgrade_cost
	damage_upgrade_level += 1
	click_damage += 1
	damage_upgrade_cost = 10 + damage_upgrade_level * 8
	status_label.text = "Damage upgraded!"
	_update_ui()


func _defeat_target() -> void:
	gold += reward_gold
	enemies_defeated_on_level += 1
	status_label.text = "Enemy defeated! +%d gold" % reward_gold

	if enemies_defeated_on_level >= enemies_required_per_level:
		current_level += 1
		enemies_defeated_on_level = 0
		_recalculate_level_values()
		status_label.text = "Level up! Level %d" % current_level

	target_hp = target_max_hp


func _recalculate_level_values() -> void:
	target_max_hp = 10 + (current_level - 1) * 8
	reward_gold = 5 + (current_level - 1) * 3
