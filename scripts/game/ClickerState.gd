class_name ClickerState
extends RefCounted

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
var is_boss_level: bool = false
var boss_time_limit: float = 30.0
var enemy_name: String = "Enemy"


func _init() -> void:
	setup_current_level()


func attack() -> Dictionary:
	var target_hp_before: int = target_hp
	target_hp = maxi(target_hp - click_damage, 0)
	var damage_dealt: int = target_hp_before - target_hp

	if target_hp > 0:
		return {
			"defeated": false,
			"level_up": false,
			"reward_gold": 0,
			"damage_dealt": damage_dealt,
			"target_hp_before": target_hp_before,
			"target_hp_after": target_hp,
			"upgraded": false,
			"not_enough_gold": false,
			"status_text": "Tap the field to attack!",
		}

	var earned_gold: int = reward_gold
	gold += earned_gold
	enemies_defeated_on_level += 1

	var did_level_up: bool = enemies_defeated_on_level >= enemies_required_per_level
	var defeated_boss: bool = is_boss_level
	var status_text: String = "Enemy defeated! +%d gold" % earned_gold

	if did_level_up:
		current_level += 1
		enemies_defeated_on_level = 0
		setup_current_level()
		status_text = "Boss defeated! Level %d" % current_level if defeated_boss else "Level up! Level %d" % current_level
	else:
		reset_target()

	return {
		"defeated": true,
		"level_up": did_level_up,
		"reward_gold": earned_gold,
		"damage_dealt": damage_dealt,
		"target_hp_before": target_hp_before,
		"target_hp_after": 0,
		"upgraded": false,
		"not_enough_gold": false,
		"status_text": status_text,
	}


func buy_damage_upgrade() -> Dictionary:
	if gold < damage_upgrade_cost:
		return {
			"defeated": false,
			"level_up": false,
			"reward_gold": 0,
			"damage_dealt": 0,
			"target_hp_before": target_hp,
			"target_hp_after": target_hp,
			"upgraded": false,
			"not_enough_gold": true,
			"status_text": "Not enough gold",
		}

	gold -= damage_upgrade_cost
	damage_upgrade_level += 1
	click_damage += 1
	damage_upgrade_cost = 10 + damage_upgrade_level * 8

	return {
		"defeated": false,
		"level_up": false,
		"reward_gold": 0,
		"damage_dealt": 0,
		"target_hp_before": target_hp,
		"target_hp_after": target_hp,
		"upgraded": true,
		"not_enough_gold": false,
		"status_text": "Damage upgraded!",
	}


func is_current_level_boss() -> bool:
	return current_level % 5 == 0


func setup_current_level() -> void:
	is_boss_level = is_current_level_boss()
	recalculate_level_values()
	enemies_required_per_level = 1 if is_boss_level else 10
	enemy_name = "Boss" if is_boss_level else "Enemy"
	reset_target()


func fail_boss_level() -> Dictionary:
	current_level = maxi(1, current_level - 1)
	enemies_defeated_on_level = 0
	setup_current_level()

	return {
		"defeated": false,
		"level_up": false,
		"reward_gold": 0,
		"damage_dealt": 0,
		"target_hp_before": target_hp,
		"target_hp_after": target_hp,
		"upgraded": false,
		"not_enough_gold": false,
		"boss_failed": true,
		"status_text": "Boss failed! Returned to Level %d" % current_level,
	}


func reset_target() -> void:
	target_hp = target_max_hp


func recalculate_level_values() -> void:
	var base_hp: int = 10 + (current_level - 1) * 8
	var base_reward: int = 5 + (current_level - 1) * 3
	target_max_hp = base_hp * 5 if is_boss_level else base_hp
	reward_gold = base_reward * 5 if is_boss_level else base_reward
