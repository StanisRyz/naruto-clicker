class_name ClickerState
extends RefCounted

const ZONE_DATA: Array = [
	{
		"name": "Training Grounds",
		"level_start": 1,
		"level_end": 10,
		"enemy": "Rogue Ninja",
		"boss": "Training Master",
		"hp_multiplier": 1.0,
		"reward_multiplier": 1.0,
	},
	{
		"name": "Forest Path",
		"level_start": 11,
		"level_end": 20,
		"enemy": "Forest Bandit",
		"boss": "Forest Guardian",
		"hp_multiplier": 1.4,
		"reward_multiplier": 1.3,
	},
	{
		"name": "Stone Valley",
		"level_start": 21,
		"level_end": 30,
		"enemy": "Stone Warrior",
		"boss": "Valley Warlord",
		"hp_multiplier": 1.9,
		"reward_multiplier": 1.7,
	},
	{
		"name": "Shadow Camp",
		"level_start": 31,
		"level_end": 40,
		"enemy": "Shadow Fighter",
		"boss": "Shadow Commander",
		"hp_multiplier": 2.5,
		"reward_multiplier": 2.2,
	},
]

var gold: int = 0
var click_damage: int = 1
var character_level: int = 1
var character_level_upgrade_cost: int = 5
var current_level: int = 1
var enemies_defeated_on_level: int = 0
var enemies_required_per_level: int = 10
var target_hp: int = 10
var target_max_hp: int = 10
var reward_gold: int = 5
var is_boss_level: bool = false
var boss_time_limit: float = 30.0
var enemy_name: String = "Enemy"
var autoclick_unlocked: bool = false
var gold_bonus_unlocked: bool = false
var autoclick_active: bool = false
var gold_bonus_active: bool = false
var autoclick_purchased: bool = false
var gold_bonus_purchased: bool = false
var autoclick_unlock_level: int = 15
var gold_bonus_unlock_level: int = 30
var autoclick_purchase_cost: int = 50
var gold_bonus_purchase_cost: int = 150
var gold_bonus_multiplier: int = 2
var partner_counts: Array[int] = [0, 0, 0]
var partner_dps_values: Array[int] = [10, 30, 50]
var partner_purchase_costs: Array[int] = [10, 50, 150]

var current_zone_index: int = 0
var zone_name: String = "Training Grounds"
var zone_level_start: int = 1
var zone_level_end: int = 10
var zone_hp_multiplier: float = 1.0
var zone_reward_multiplier: float = 1.0

var prestige_points: int = 0
var total_prestiges: int = 0
var prestige_required_level: int = 50
var prestige_damage_bonus_per_point: float = 0.10
var prestige_gold_bonus_per_point: float = 0.10


func _init() -> void:
	_update_character_state()
	recalculate_character_level_cost()
	setup_current_level()


func can_prestige() -> bool:
	return get_prestige_reward() > 0


func get_prestige_stage_points() -> int:
	return int(current_level / float(prestige_required_level))


func get_prestige_character_points() -> int:
	return int(character_level / 100.0)


func get_prestige_reward() -> int:
	return get_prestige_stage_points() + get_prestige_character_points()


func get_prestige_damage_multiplier() -> float:
	return 1.0 + prestige_points * prestige_damage_bonus_per_point


func get_prestige_gold_multiplier() -> float:
	return 1.0 + prestige_points * prestige_gold_bonus_per_point


func perform_prestige() -> Dictionary:
	var reward: int = get_prestige_reward()
	if reward <= 0:
		return _make_purchase_result("Prestige requires stage level %d or character level 100" % prestige_required_level)

	prestige_points += reward
	total_prestiges += 1

	gold = 0
	character_level = 1
	current_level = 1
	enemies_defeated_on_level = 0
	autoclick_purchased = false
	autoclick_active = false
	gold_bonus_purchased = false
	gold_bonus_active = false

	for i in partner_counts.size():
		partner_counts[i] = 0
	partner_purchase_costs = [10, 50, 150]

	recalculate_character_level_cost()
	_update_character_state()
	setup_current_level()

	return {
		"defeated": false,
		"level_up": false,
		"reward_gold": 0,
		"damage_dealt": 0,
		"target_hp_before": target_hp,
		"target_hp_after": target_hp,
		"upgraded": true,
		"not_enough_gold": false,
		"status_text": "Prestige complete! +%d Prestige Points" % reward,
		"zone_changed": false,
		"zone_name": "",
	}


func attack() -> Dictionary:
	return attack_with_damage(click_damage)


func attack_with_damage(damage: int) -> Dictionary:
	if damage <= 0:
		return _make_attack_result(false, false, 0, 0, target_hp, target_hp, "Tap the field to attack!")

	var target_hp_before: int = target_hp
	target_hp = maxi(target_hp - damage, 0)
	var damage_dealt: int = target_hp_before - target_hp

	if target_hp > 0:
		return _make_attack_result(false, false, 0, damage_dealt, target_hp_before, target_hp, "Tap the field to attack!")

	var prestige_gold: int = int(reward_gold * get_prestige_gold_multiplier())
	var earned_gold: int = prestige_gold * gold_bonus_multiplier if gold_bonus_active else prestige_gold
	gold += earned_gold
	enemies_defeated_on_level += 1

	var did_level_up: bool = enemies_defeated_on_level >= enemies_required_per_level
	var defeated_boss: bool = is_boss_level
	var status_text: String = "Enemy defeated! +%d gold" % earned_gold
	var zone_changed: bool = false
	var new_zone_name: String = ""

	if did_level_up:
		var old_zone_index: int = current_zone_index
		current_level += 1
		enemies_defeated_on_level = 0
		setup_current_level()
		zone_changed = current_zone_index != old_zone_index
		new_zone_name = zone_name
		if zone_changed:
			status_text = "New zone: %s" % zone_name
		elif defeated_boss:
			status_text = "Boss defeated! +%d gold. Level %d" % [earned_gold, current_level]
		else:
			status_text = "Level up! Level %d" % current_level
	else:
		reset_target()

	return _make_attack_result(true, did_level_up, earned_gold, damage_dealt, target_hp_before, 0, status_text, zone_changed, new_zone_name)


func buy_character_level_upgrade() -> Dictionary:
	if gold < character_level_upgrade_cost:
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
			"zone_changed": false,
			"zone_name": "",
		}

	gold -= character_level_upgrade_cost
	character_level += 1
	_update_character_state()
	recalculate_character_level_cost()

	return {
		"defeated": false,
		"level_up": false,
		"reward_gold": 0,
		"damage_dealt": 0,
		"target_hp_before": target_hp,
		"target_hp_after": target_hp,
		"upgraded": true,
		"not_enough_gold": false,
		"status_text": "Character level upgraded!",
		"zone_changed": false,
		"zone_name": "",
	}


func buy_autoclick_ability() -> Dictionary:
	if autoclick_purchased:
		return _make_purchase_result("Already purchased")

	if not autoclick_unlocked:
		return _make_purchase_result("Requires character level %d" % autoclick_unlock_level)

	if gold < autoclick_purchase_cost:
		return _make_purchase_result("Not enough gold", true)

	gold -= autoclick_purchase_cost
	autoclick_purchased = true
	return _make_purchase_result("Autoclick purchased!", false, true)


func buy_gold_bonus_ability() -> Dictionary:
	if gold_bonus_purchased:
		return _make_purchase_result("Already purchased")

	if not gold_bonus_unlocked:
		return _make_purchase_result("Requires character level %d" % gold_bonus_unlock_level)

	if gold < gold_bonus_purchase_cost:
		return _make_purchase_result("Not enough gold", true)

	gold -= gold_bonus_purchase_cost
	gold_bonus_purchased = true
	return _make_purchase_result("Gold Bonus purchased!", false, true)


func get_total_partner_dps() -> int:
	var total_dps: int = 0

	for index in partner_counts.size():
		total_dps += partner_counts[index] * partner_dps_values[index]

	return total_dps


func get_partner_tick_damage() -> int:
	var total_dps: int = get_total_partner_dps()
	if total_dps <= 0:
		return 0

	var base_tick: int = int(total_dps / 10.0)
	if base_tick <= 0:
		return 0

	return maxi(1, int(base_tick * get_prestige_damage_multiplier()))


func buy_partner(partner_index: int) -> Dictionary:
	if partner_index < 0 or partner_index >= partner_counts.size():
		return _make_purchase_result("Invalid partner")

	if not can_buy_partner(partner_index):
		if partner_index == 1:
			return _make_purchase_result("Requires Partner 1")

		if partner_index == 2:
			return _make_purchase_result("Requires Partner 2")

	if partner_index == 1 and partner_counts[0] <= 0:
		return _make_purchase_result("Requires Partner 1")

	if partner_index == 2 and partner_counts[1] <= 0:
		return _make_purchase_result("Requires Partner 2")

	var purchase_cost: int = partner_purchase_costs[partner_index]
	if gold < purchase_cost:
		return _make_purchase_result("Not enough gold", true)

	gold -= purchase_cost
	partner_counts[partner_index] += 1
	recalculate_partner_cost(partner_index)
	return _make_purchase_result("Partner %d hired!" % (partner_index + 1), false, true)


func recalculate_character_level_cost() -> void:
	character_level_upgrade_cost = 5 + (character_level - 1) * 3


func recalculate_partner_cost(partner_index: int) -> void:
	if partner_index == 0:
		partner_purchase_costs[0] = 10 + partner_counts[0] * 10
	elif partner_index == 1:
		partner_purchase_costs[1] = 50 + partner_counts[1] * 30
	elif partner_index == 2:
		partner_purchase_costs[2] = 150 + partner_counts[2] * 50


func can_buy_partner(partner_index: int) -> bool:
	if partner_index == 0:
		return true

	if partner_index == 1:
		return partner_counts[0] > 0

	if partner_index == 2:
		return partner_counts[1] > 0

	return false


func is_current_level_boss() -> bool:
	return current_level % 5 == 0


func setup_current_level() -> void:
	is_boss_level = is_current_level_boss()
	_update_zone()
	recalculate_level_values()
	enemies_required_per_level = 1 if is_boss_level else 10
	var zone: Dictionary = ZONE_DATA[current_zone_index]
	enemy_name = zone.boss if is_boss_level else zone.enemy
	reset_target()


func update_ability_unlocks() -> void:
	autoclick_unlocked = character_level >= autoclick_unlock_level
	gold_bonus_unlocked = character_level >= gold_bonus_unlock_level

	if not autoclick_unlocked:
		autoclick_active = false
		autoclick_purchased = false

	if not gold_bonus_unlocked:
		gold_bonus_active = false
		gold_bonus_purchased = false


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
		"zone_changed": false,
		"zone_name": "",
	}


func reset_target() -> void:
	target_hp = target_max_hp


func recalculate_level_values() -> void:
	var zone: Dictionary = ZONE_DATA[current_zone_index]
	var base_hp: int = 10 + (current_level - 1) * 8
	var base_reward: int = 5 + (current_level - 1) * 3
	var scaled_hp: int = int(base_hp * zone.hp_multiplier)
	var scaled_reward: int = int(base_reward * zone.reward_multiplier)
	target_max_hp = scaled_hp * 5 if is_boss_level else scaled_hp
	reward_gold = scaled_reward * 5 if is_boss_level else scaled_reward


func _get_zone_index_for_level(level: int) -> int:
	for i in ZONE_DATA.size():
		if level <= ZONE_DATA[i].level_end:
			return i
	return ZONE_DATA.size() - 1


func _update_zone() -> void:
	var idx: int = _get_zone_index_for_level(current_level)
	var zone: Dictionary = ZONE_DATA[idx]
	current_zone_index = idx
	zone_name = zone.name
	zone_level_start = zone.level_start
	zone_level_end = zone.level_end
	zone_hp_multiplier = zone.hp_multiplier
	zone_reward_multiplier = zone.reward_multiplier


func _update_character_state() -> void:
	click_damage = maxi(1, int(character_level * get_prestige_damage_multiplier()))
	update_ability_unlocks()


func _make_purchase_result(status_text: String, not_enough_gold: bool = false, upgraded: bool = false) -> Dictionary:
	return {
		"defeated": false,
		"level_up": false,
		"reward_gold": 0,
		"damage_dealt": 0,
		"target_hp_before": target_hp,
		"target_hp_after": target_hp,
		"upgraded": upgraded,
		"not_enough_gold": not_enough_gold,
		"status_text": status_text,
		"zone_changed": false,
		"zone_name": "",
	}


func _make_attack_result(
	defeated: bool,
	level_up: bool,
	earned_gold: int,
	damage_dealt: int,
	target_hp_before: int,
	target_hp_after: int,
	status_text: String,
	zone_changed: bool = false,
	new_zone_name: String = ""
) -> Dictionary:
	return {
		"defeated": defeated,
		"level_up": level_up,
		"reward_gold": earned_gold,
		"damage_dealt": damage_dealt,
		"target_hp_before": target_hp_before,
		"target_hp_after": target_hp_after,
		"upgraded": false,
		"not_enough_gold": false,
		"status_text": status_text,
		"zone_changed": zone_changed,
		"zone_name": new_zone_name,
	}
