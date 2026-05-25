extends Control

var gold: int = 0
var click_damage: int = 1
var target_hp: int = 10
var target_max_hp: int = 10
var target_level: int = 1
var reward_gold: int = 5
var damage_upgrade_level: int = 0
var damage_upgrade_cost: int = 10

@onready var gold_label: Label = $MarginContainer/VBoxContainer/GoldLabel
@onready var damage_label: Label = $MarginContainer/VBoxContainer/DamageLabel
@onready var target_hp_label: Label = $MarginContainer/VBoxContainer/TargetHpLabel
@onready var target_progress_bar: ProgressBar = $MarginContainer/VBoxContainer/TargetProgressBar
@onready var attack_button: Button = $MarginContainer/VBoxContainer/AttackButton
@onready var upgrade_damage_button: Button = $MarginContainer/VBoxContainer/UpgradeDamageButton
@onready var status_label: Label = $MarginContainer/VBoxContainer/StatusLabel


func _ready() -> void:
	attack_button.pressed.connect(_on_attack_pressed)
	upgrade_damage_button.pressed.connect(_on_upgrade_damage_pressed)
	_update_ui()

	await get_tree().process_frame
	YandexBridge.game_ready()
	YandexBridge.gameplay_start()


func _update_ui() -> void:
	gold_label.text = "Gold: %d" % gold
	damage_label.text = "Damage: %d" % click_damage
	target_hp_label.text = "Target HP: %d / %d" % [target_hp, target_max_hp]
	target_progress_bar.max_value = target_max_hp
	target_progress_bar.value = target_hp
	upgrade_damage_button.text = "Upgrade Damage - Cost: %d" % damage_upgrade_cost


func _on_attack_pressed() -> void:
	target_hp = maxi(target_hp - click_damage, 0)

	if target_hp == 0:
		_defeat_target()
	else:
		status_label.text = "Attack the target!"

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
	status_label.text = "Target defeated! +%d gold" % reward_gold
	target_level += 1
	target_max_hp = 10 + (target_level - 1) * 5
	target_hp = target_max_hp
	reward_gold = 5 + (target_level - 1) * 2
