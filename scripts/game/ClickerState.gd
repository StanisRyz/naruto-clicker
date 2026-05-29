class_name ClickerState
extends RefCounted

const ZONE_DATA: Array = [
	{
		"name": "Training Grounds",
		"level_start": 1,
		"level_end": 10,
		"enemies": ["Rogue Ninja", "Novice Bandit", "Training Outcast"],
		"elite_enemy": "Elite Rogue Ninja",
		"boss": "Training Master",
		"hp_multiplier": 1.0,
		"reward_multiplier": 1.0,
	},
	{
		"name": "Forest Path",
		"level_start": 11,
		"level_end": 20,
		"enemies": ["Forest Bandit", "Wild Scout", "Hidden Archer"],
		"elite_enemy": "Elite Forest Bandit",
		"boss": "Forest Guardian",
		"hp_multiplier": 1.4,
		"reward_multiplier": 1.3,
	},
	{
		"name": "Stone Valley",
		"level_start": 21,
		"level_end": 30,
		"enemies": ["Stone Warrior", "Valley Raider", "Rock Sentinel"],
		"elite_enemy": "Elite Stone Warrior",
		"boss": "Valley Warlord",
		"hp_multiplier": 1.9,
		"reward_multiplier": 1.7,
	},
	{
		"name": "Shadow Camp",
		"level_start": 31,
		"level_end": 40,
		"enemies": ["Shadow Fighter", "Camp Assassin", "Dark Scout"],
		"elite_enemy": "Elite Shadow Fighter",
		"boss": "Shadow Commander",
		"hp_multiplier": 2.5,
		"reward_multiplier": 2.2,
	},
]

var gold: int = 0
var gems: int = 0
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
var is_elite_enemy: bool = false
var elite_spawn_chance: float = 0.07
var elite_hp_multiplier: int = 3
var elite_reward_multiplier: int = 5
var boss_time_limit: float = 30.0
var enemy_name: String = "Enemy"
var autoclick_unlocked: bool = false
var gold_bonus_unlocked: bool = false
var focus_burst_unlocked: bool = false
var rally_unlocked: bool = false
var autoclick_active: bool = false
var gold_bonus_active: bool = false
var focus_burst_active: bool = false
var rally_active: bool = false
var autoclick_purchased: bool = false
var gold_bonus_purchased: bool = false
var focus_burst_purchased: bool = false
var rally_purchased: bool = false
var autoclick_unlock_level: int = 15
var gold_bonus_unlock_level: int = 30
var focus_burst_unlock_level: int = 60
var rally_unlock_level: int = 80
var autoclick_purchase_cost: int = 50
var gold_bonus_purchase_cost: int = 150
var focus_burst_purchase_cost: int = 500
var rally_purchase_cost: int = 1000
var gold_bonus_multiplier: int = 2
var partner_names: Array[String] = [
	"Partner 1",
	"Partner 2",
	"Partner 3",
	"Field Scout",
	"Spear Guard",
	"Iron Defender",
	"Battle Monk",
	"Elite Samurai",
	"Shadow Captain",
	"War Sage",
	"Beast Tamer",
	"Blade Master",
	"Legendary Commander",
]
# Partner DPS tiers are prototype balance values tuned around milestone x2 spikes.
var partner_dps_values: Array[int] = [10, 20, 35, 65, 120, 220, 410, 750, 1400, 2600, 4800, 9000, 16500]
var partner_base_costs: Array[int] = [10, 50, 150, 400, 900, 1800, 3500, 7000, 14000, 28000, 56000, 110000, 220000]
var partner_cost_steps: Array[int] = [10, 30, 50, 100, 180, 300, 500, 900, 1600, 2800, 5000, 9000, 16000]
var partner_counts: Array[int] = []
var partner_purchase_costs: Array[int] = []
var milestone_levels: Array[int] = [10, 25, 50, 100, 250, 500]
var milestone_multiplier_per_reached: int = 2
var milestone_cost_multiplier: int = 3
var character_cost_base: int = 5
var character_cost_linear: float = 2.2
var character_cost_curve: float = 0.18
var character_cost_power: float = 2.35
var partner_cost_curve_multiplier: float = 0.015
var partner_cost_power: float = 2.15
var enemy_hp_base: int = 10
var enemy_hp_linear: float = 8.0
var enemy_hp_curve: float = 1.15
var enemy_hp_power: float = 2.10
var enemy_reward_base: int = 5
var enemy_reward_linear: float = 3.0
var enemy_reward_curve: float = 0.22
var enemy_reward_power: float = 1.80
var building_names: Array[String] = ["Training Camp", "Market", "Knight Hut", "War Banner", "Clock Tower", "Boss Shrine"]
var building_bonus_types: Array[String] = ["partner_dps", "gold", "click_damage", "ability_duration", "ability_cooldown", "boss_gold"]
var building_base_costs: Array[int] = [25, 75, 150, 500, 1200, 3000]
var building_cost_steps: Array[int] = [25, 50, 100, 250, 600, 1500]
var building_counts: Array[int] = []
var building_bonus_percent_per_level: int = 1
var building_purchase_costs: Array[int] = []
var boss_retry_tokens: int = 0
var task_reward_boost_multiplier: float = 1.0
var shop_product_definitions: Array[Dictionary] = [
	{
		"id": "gold_pack_small",
		"name": "Small Gold Pack",
		"description": "Gain stage-scaled gold",
		"cost_gems": 10,
		"reward_type": "gold",
		"reward_scale": 120,
	},
	{
		"id": "gold_pack_large",
		"name": "Large Gold Pack",
		"description": "Gain a large stage-scaled gold reward",
		"cost_gems": 25,
		"reward_type": "gold",
		"reward_scale": 350,
	},
	{
		"id": "instant_combo",
		"name": "Instant Combo",
		"description": "Fill Combo Meter to 100%",
		"cost_gems": 15,
		"reward_type": "combo_fill",
		"reward_amount": 100,
	},
	{
		"id": "boss_retry_token",
		"name": "Boss Retry",
		"description": "Return to the failed boss level",
		"cost_gems": 20,
		"reward_type": "boss_retry_token",
		"reward_amount": 1,
	},
	{
		"id": "task_boost",
		"name": "Task Reward Boost",
		"description": "Next claimed task gives x2 gold",
		"cost_gems": 30,
		"reward_type": "task_reward_boost",
		"reward_multiplier": 2.0,
	},
]

var current_zone_index: int = 0
var zone_name: String = "Training Grounds"
var zone_level_start: int = 1
var zone_level_end: int = 10
var zone_hp_multiplier: float = 1.0
var zone_reward_multiplier: float = 1.0

var prestige_points_available: int = 0
var prestige_points_total_earned: int = 0
var total_prestiges: int = 0
var prestige_required_level: int = 50
var prestige_talent_levels: Array[int] = [0, 0, 0, 0, 0, 0]
var prestige_talent_names: Array[String] = ["Focus Training", "Trade Routes", "Command Aura", "Quick Hands", "Builder Wisdom", "Boss Hunter"]
var prestige_talent_bonus_types: Array[String] = ["click_damage", "gold", "partner_dps", "autoclick_rate", "settlement_effect", "boss_damage"]
var prestige_talent_bonus_percent_per_level: int = 5
var task_definitions: Array[Dictionary] = [
	{"id": "manual_damage_500", "title": "Deal 500 manual damage", "goal_type": "manual_damage_delta", "target_delta": 500, "reward_scale": 20},
	{"id": "defeat_25_enemies", "title": "Defeat 25 enemies", "goal_type": "enemies_defeated_delta", "target_delta": 25, "reward_scale": 30},
	{"id": "defeat_2_elites", "title": "Defeat 2 elite enemies", "goal_type": "elite_enemies_defeated_delta", "target_delta": 2, "reward_scale": 60},
	{"id": "defeat_1_boss", "title": "Defeat 1 boss", "goal_type": "bosses_defeated_delta", "target_delta": 1, "reward_scale": 100},
	{"id": "gain_10_hero_levels", "title": "Gain 10 Hero Levels", "goal_type": "hero_level_delta", "target_delta": 10, "reward_scale": 50},
	{"id": "hire_10_partners", "title": "Hire 10 partners", "goal_type": "partners_total_delta", "target_delta": 10, "reward_scale": 70},
	{"id": "build_5_buildings", "title": "Build 5 settlement buildings", "goal_type": "buildings_total_delta", "target_delta": 5, "reward_scale": 80},
	{"id": "activate_autoclick_1", "title": "Activate Autoclick 1 time", "goal_type": "autoclick_activations_delta", "target_delta": 1, "reward_scale": 40},
	{"id": "combo_empowered_1", "title": "Fill Combo Meter to 100%", "goal_type": "combo_empowered_delta", "target_delta": 1, "reward_scale": 90},
	{"id": "gain_10_game_levels", "title": "Reach 10 more levels", "goal_type": "game_level_delta", "target_delta": 10, "reward_scale": 120},
]
var active_task_ids: Array[String] = []
var inactive_task_ids: Array[String] = []
var active_task_states: Dictionary = {}
var total_manual_click_damage_dealt: int = 0
var total_enemies_defeated: int = 0
var total_elite_enemies_defeated: int = 0
var total_bosses_defeated: int = 0
var total_autoclick_activations: int = 0
var total_combo_empowered_activations: int = 0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var prestige_points: int:
	get:
		return prestige_points_available
	set(value):
		prestige_points_available = value
		prestige_points_total_earned = maxi(prestige_points_total_earned, value)


func _init() -> void:
	rng.randomize()
	initialize_tasks()
	_reset_partner_state()
	_reset_building_state()
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


func initialize_tasks() -> void:
	active_task_ids.clear()
	inactive_task_ids.clear()
	active_task_states.clear()

	var task_ids: Array[String] = []
	for task: Dictionary in task_definitions:
		var task_id: String = String(task.get("id", ""))
		if task_id != "":
			task_ids.append(task_id)

	_shuffle_task_ids(task_ids)
	for i in range(task_ids.size()):
		var active_or_inactive_id: String = task_ids[i]
		if i < 5:
			active_task_ids.append(active_or_inactive_id)
			_initialize_active_task_state(active_or_inactive_id)
		else:
			inactive_task_ids.append(active_or_inactive_id)


func _shuffle_task_ids(task_ids: Array[String]) -> void:
	if task_ids.size() < 2:
		return

	for i in range(task_ids.size() - 1, 0, -1):
		var swap_index: int = rng.randi_range(0, i)
		var original_id: String = task_ids[i]
		task_ids[i] = task_ids[swap_index]
		task_ids[swap_index] = original_id


func _initialize_active_task_state(task_id: String) -> void:
	var task: Dictionary = get_task_definition(task_id)
	if task.is_empty():
		return

	var start_value: int = _get_task_current_value(task_id)
	var target_delta: int = int(task.get("target_delta", 0))
	active_task_states[task_id] = {
		"start_value": start_value,
		"target_delta": target_delta,
		"target_value": start_value + target_delta,
	}


func _get_task_current_value(task_id: String) -> int:
	var task: Dictionary = get_task_definition(task_id)
	var goal_type: String = String(task.get("goal_type", ""))
	match goal_type:
		"manual_damage_delta":
			return total_manual_click_damage_dealt
		"enemies_defeated_delta":
			return total_enemies_defeated
		"elite_enemies_defeated_delta":
			return total_elite_enemies_defeated
		"bosses_defeated_delta":
			return total_bosses_defeated
		"hero_level_delta":
			return character_level
		"partners_total_delta":
			return _get_total_partner_count()
		"buildings_total_delta":
			return _get_total_building_count()
		"autoclick_activations_delta":
			return total_autoclick_activations
		"combo_empowered_delta":
			return total_combo_empowered_activations
		"game_level_delta":
			return current_level

	return 0


func get_task_definition(task_id: String) -> Dictionary:
	for task: Dictionary in task_definitions:
		if String(task.get("id", "")) == task_id:
			return task

	return {}


func get_task_progress(task_id: String) -> int:
	if not active_task_ids.has(task_id) or not active_task_states.has(task_id):
		return 0

	var task_state: Dictionary = active_task_states[task_id]
	var start_value: int = int(task_state.get("start_value", 0))
	var target_delta: int = int(task_state.get("target_delta", 0))
	var progress: int = _get_task_current_value(task_id) - start_value
	return clampi(progress, 0, target_delta)


func get_task_target(task_id: String) -> int:
	if not active_task_ids.has(task_id) or not active_task_states.has(task_id):
		return 0

	var task_state: Dictionary = active_task_states[task_id]
	return int(task_state.get("target_delta", 0))


func get_current_task_reward_unit() -> int:
	var base_reward: int = get_base_enemy_reward_for_level(current_level)
	var zone_scaled_reward: int = ceili(base_reward * zone_reward_multiplier)
	return maxi(1, zone_scaled_reward)


func get_task_reward_gold(task_id: String) -> int:
	var task: Dictionary = get_task_definition(task_id)
	if task.is_empty():
		return 0

	var reward_scale: int = int(task.get("reward_scale", 0))
	if reward_scale <= 0:
		return 0

	return maxi(1, get_current_task_reward_unit() * reward_scale)


func is_task_completed(task_id: String) -> bool:
	if not active_task_ids.has(task_id):
		return false

	return get_task_progress(task_id) >= get_task_target(task_id)


func get_active_task_view_data() -> Array[Dictionary]:
	var task_view_data: Array[Dictionary] = []
	for task_id in active_task_ids:
		var task: Dictionary = get_task_definition(task_id)
		if task.is_empty():
			continue

		task_view_data.append({
			"id": task_id,
			"title": String(task.get("title", "")),
			"progress": get_task_progress(task_id),
			"target": get_task_target(task_id),
			"reward_gold": get_task_reward_gold(task_id),
			"completed": is_task_completed(task_id),
		})

	return task_view_data


func claim_task_reward(task_id: String) -> Dictionary:
	if not active_task_ids.has(task_id):
		return _make_purchase_result("Task is not active")

	if not is_task_completed(task_id):
		return _make_purchase_result("Task is not complete")

	var reward: int = get_task_reward_gold(task_id)
	if task_reward_boost_multiplier > 1.0:
		reward = int(reward * task_reward_boost_multiplier)
		task_reward_boost_multiplier = 1.0

	gold += reward
	active_task_ids.erase(task_id)
	active_task_states.erase(task_id)

	if inactive_task_ids.is_empty():
		inactive_task_ids.append(task_id)
		return _make_purchase_result("Task complete! +%d gold" % reward, false, true)

	var replacement_index: int = rng.randi_range(0, inactive_task_ids.size() - 1)
	var replacement_id: String = inactive_task_ids[replacement_index]
	inactive_task_ids.remove_at(replacement_index)
	active_task_ids.append(replacement_id)
	_initialize_active_task_state(replacement_id)
	inactive_task_ids.append(task_id)

	return _make_purchase_result("Task complete! +%d gold" % reward, false, true)


func get_focus_training_multiplier() -> float:
	return 1.0 + get_focus_training_bonus_percent() / 100.0


func get_trade_routes_multiplier() -> float:
	return 1.0 + get_trade_routes_bonus_percent() / 100.0


func get_command_aura_multiplier() -> float:
	return 1.0 + get_command_aura_bonus_percent() / 100.0


func get_focus_training_bonus_percent() -> int:
	return prestige_talent_levels[0] * prestige_talent_bonus_percent_per_level


func get_trade_routes_bonus_percent() -> int:
	return prestige_talent_levels[1] * prestige_talent_bonus_percent_per_level


func get_command_aura_bonus_percent() -> int:
	return prestige_talent_levels[2] * prestige_talent_bonus_percent_per_level


func get_quick_hands_bonus_percent() -> int:
	return prestige_talent_levels[3] * prestige_talent_bonus_percent_per_level


func get_builder_wisdom_bonus_percent() -> int:
	return prestige_talent_levels[4] * prestige_talent_bonus_percent_per_level


func get_boss_hunter_bonus_percent() -> int:
	return prestige_talent_levels[5] * prestige_talent_bonus_percent_per_level


func get_quick_hands_multiplier() -> float:
	return 1.0 + get_quick_hands_bonus_percent() / 100.0


func get_boss_hunter_multiplier() -> float:
	return 1.0 + get_boss_hunter_bonus_percent() / 100.0


func get_settlement_effectiveness_multiplier() -> float:
	return 1.0 + get_builder_wisdom_bonus_percent() / 100.0


func get_focus_burst_multiplier() -> float:
	return 2.0 if focus_burst_active else 1.0


func get_rally_multiplier() -> float:
	return 2.0 if rally_active else 1.0


func get_boss_damage_multiplier() -> float:
	return get_boss_hunter_multiplier() if is_boss_level else 1.0


func get_current_enemy_type() -> String:
	if is_boss_level:
		return "boss"

	return "elite" if is_elite_enemy else "normal"


func get_prestige_talent_cost(talent_index: int) -> int:
	if talent_index < 0 or talent_index >= prestige_talent_levels.size():
		return 0

	return 1 + prestige_talent_levels[talent_index]


func buy_prestige_talent(talent_index: int) -> Dictionary:
	if talent_index < 0 or talent_index >= prestige_talent_levels.size():
		return _make_purchase_result("Invalid prestige talent")

	var cost: int = get_prestige_talent_cost(talent_index)
	if prestige_points_available < cost:
		return _make_purchase_result("Not enough Prestige Points")

	prestige_points_available -= cost
	prestige_talent_levels[talent_index] += 1
	_update_character_state()
	return _make_purchase_result("Prestige talent upgraded!", false, true)


func add_gems(amount: int) -> void:
	gems = maxi(0, gems + amount)


func grant_test_gems(amount: int = 50) -> Dictionary:
	add_gems(amount)
	return _make_purchase_result("Prototype test grant: +%d Gems" % amount, false, true)


func get_shop_product(product_id: String) -> Dictionary:
	for product: Dictionary in shop_product_definitions:
		if String(product.get("id", "")) == product_id:
			return product

	return {}


func get_shop_product_view_data() -> Array[Dictionary]:
	var product_view_data: Array[Dictionary] = []
	for product: Dictionary in shop_product_definitions:
		var cost_gems: int = int(product.get("cost_gems", 0))
		product_view_data.append({
			"id": String(product.get("id", "")),
			"name": String(product.get("name", "")),
			"description": String(product.get("description", "")),
			"cost_gems": cost_gems,
			"can_buy": gems >= cost_gems,
		})

	return product_view_data


func buy_shop_product(product_id: String) -> Dictionary:
	var product: Dictionary = get_shop_product(product_id)
	if product.is_empty():
		return _make_purchase_result("Invalid shop product")

	var cost_gems: int = int(product.get("cost_gems", 0))
	if gems < cost_gems:
		return _make_purchase_result("Not enough Gems")

	gems -= cost_gems
	var product_name: String = String(product.get("name", "Shop product"))
	var reward_type: String = String(product.get("reward_type", ""))
	var result: Dictionary = _make_purchase_result("%s purchased!" % product_name, false, true)

	match reward_type:
		"gold":
			var reward_scale: int = int(product.get("reward_scale", 0))
			var reward_gold: int = maxi(1, get_current_task_reward_unit() * reward_scale)
			gold += reward_gold
			result["reward_gold"] = reward_gold
			result["status_text"] = "%s purchased! +%d gold" % [product_name, reward_gold]
		"combo_fill":
			var combo_reward_amount: int = int(product.get("reward_amount", 100))
			result["combo_fill"] = combo_reward_amount
			result["status_text"] = "%s purchased! Combo filled" % product_name
		"boss_retry_token":
			var boss_retry_reward_amount: int = int(product.get("reward_amount", 1))
			boss_retry_tokens += boss_retry_reward_amount
			result["status_text"] = "%s purchased! +%d Boss Retry" % [product_name, boss_retry_reward_amount]
		"task_reward_boost":
			var reward_multiplier: float = float(product.get("reward_multiplier", 1.0))
			task_reward_boost_multiplier = maxf(task_reward_boost_multiplier, reward_multiplier)
			result["status_text"] = "%s purchased! Next task reward x%.1f" % [product_name, task_reward_boost_multiplier]
		_:
			result["status_text"] = "Unknown shop reward"

	return result


func perform_prestige() -> Dictionary:
	var reward: int = get_prestige_reward()
	if reward <= 0:
		return _make_purchase_result("Prestige requires stage level %d or character level 100" % prestige_required_level)

	prestige_points_available += reward
	prestige_points_total_earned += reward
	total_prestiges += 1

	gold = 0
	character_level = 1
	current_level = 1
	enemies_defeated_on_level = 0
	autoclick_purchased = false
	autoclick_active = false
	gold_bonus_purchased = false
	gold_bonus_active = false
	focus_burst_purchased = false
	focus_burst_active = false
	rally_purchased = false
	rally_active = false

	_reset_partner_state()
	_reset_building_state()

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
	return attack_with_damage(get_current_click_damage())


func attack_with_damage(damage: int) -> Dictionary:
	if damage <= 0:
		return _make_attack_result(false, false, 0, 0, target_hp, target_hp, "Tap the field to attack!")

	var target_hp_before: int = target_hp
	target_hp = maxi(target_hp - damage, 0)
	var damage_dealt: int = target_hp_before - target_hp

	if target_hp > 0:
		return _make_attack_result(false, false, 0, damage_dealt, target_hp_before, target_hp, "Tap the field to attack!")

	var did_level_up: bool = enemies_defeated_on_level + 1 >= enemies_required_per_level
	var zone_changed: bool = false
	var new_zone_name: String = ""
	if did_level_up:
		var next_level: int = current_level + 1
		var next_zone_index: int = _get_zone_index_for_level(next_level)
		zone_changed = next_zone_index != current_zone_index
		if zone_changed:
			var next_zone: Dictionary = ZONE_DATA[next_zone_index]
			new_zone_name = next_zone.name

	return _make_attack_result(true, did_level_up, 0, damage_dealt, target_hp_before, 0, "Enemy defeated!", zone_changed, new_zone_name)


func resolve_defeated_target() -> Dictionary:
	if target_hp > 0:
		return _make_attack_result(false, false, 0, 0, target_hp, target_hp, "")

	var target_hp_before: int = target_hp
	var damage_dealt: int = 0
	var defeated_boss: bool = is_boss_level
	var defeated_elite: bool = is_elite_enemy
	var boss_reward: int = int(reward_gold * get_boss_reward_multiplier()) if defeated_boss else reward_gold
	var talent_gold: int = int(boss_reward * get_trade_routes_multiplier())
	var settlement_gold: int = int(talent_gold * get_settlement_gold_multiplier())
	var earned_gold: int = settlement_gold * gold_bonus_multiplier if gold_bonus_active else settlement_gold
	gold += earned_gold
	enemies_defeated_on_level += 1
	total_enemies_defeated += 1
	if defeated_elite:
		total_elite_enemies_defeated += 1
	if defeated_boss:
		total_bosses_defeated += 1

	var did_level_up: bool = enemies_defeated_on_level >= enemies_required_per_level
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
	return buy_character_level_upgrades("x1")


func buy_character_level_upgrades(mode: String) -> Dictionary:
	var bought: int = get_character_level_bulk_count(mode)
	var total_cost: int = get_character_level_bulk_cost(mode)

	if bought <= 0 or total_cost <= 0 or gold < total_cost:
		return _make_purchase_result("Not enough gold", true)

	gold -= total_cost
	character_level += bought
	recalculate_character_level_cost()
	_update_character_state()
	return _make_purchase_result("Character level upgraded x%d!" % bought, false, true)


func get_character_level_bulk_count(mode: String) -> int:
	var fixed_count: int = _get_fixed_buy_count(mode)
	if fixed_count > 0:
		return fixed_count

	var simulated_gold: int = gold
	var simulated_level: int = character_level
	var simulated_cost: int = character_level_upgrade_cost
	var count: int = 0

	while simulated_gold >= simulated_cost:
		simulated_gold -= simulated_cost
		simulated_level += 1
		count += 1
		simulated_cost = _get_character_level_cost_for_level(simulated_level)

	return count


func get_character_level_bulk_cost(mode: String) -> int:
	var count: int = get_character_level_bulk_count(mode)
	if count <= 0:
		return 0

	return _get_character_level_bulk_cost_for_count(count)


func get_character_level_bulk_display_count(mode: String) -> int:
	if mode == "max":
		return get_character_level_bulk_count(mode)

	return _get_fixed_buy_count(mode)


func get_character_level_bulk_display_cost(mode: String) -> int:
	var display_count: int = get_character_level_bulk_display_count(mode)
	if display_count > 0:
		return _get_character_level_bulk_cost_for_count(display_count)

	return character_level_upgrade_cost


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


func buy_focus_burst_ability() -> Dictionary:
	if focus_burst_purchased:
		return _make_purchase_result("Already purchased")

	if not focus_burst_unlocked:
		return _make_purchase_result("Requires character level %d" % focus_burst_unlock_level)

	if gold < focus_burst_purchase_cost:
		return _make_purchase_result("Not enough gold", true)

	gold -= focus_burst_purchase_cost
	focus_burst_purchased = true
	return _make_purchase_result("Focus Burst purchased!", false, true)


func buy_rally_ability() -> Dictionary:
	if rally_purchased:
		return _make_purchase_result("Already purchased")

	if not rally_unlocked:
		return _make_purchase_result("Requires character level %d" % rally_unlock_level)

	if gold < rally_purchase_cost:
		return _make_purchase_result("Not enough gold", true)

	gold -= rally_purchase_cost
	rally_purchased = true
	return _make_purchase_result("Rally purchased!", false, true)


func get_base_partner_dps() -> int:
	var total_dps: int = 0

	for index in range(partner_counts.size()):
		total_dps += get_partner_tier_total_dps(index)

	return total_dps


func get_total_partner_dps() -> int:
	return get_base_partner_dps()


func get_final_partner_dps(include_contextual_boss_multiplier: bool = false) -> int:
	var base_dps: int = get_base_partner_dps()
	if base_dps <= 0:
		return 0

	var final_dps: int = int(
		base_dps
		* get_command_aura_multiplier()
		* get_settlement_partner_dps_multiplier()
		* get_rally_multiplier()
	)

	if include_contextual_boss_multiplier:
		final_dps = int(final_dps * get_boss_damage_multiplier())

	return final_dps


func get_partner_tick_damage() -> int:
	var final_dps: int = get_final_partner_dps(true)
	if final_dps <= 0:
		return 0

	var final_tick: int = int(final_dps / 10.0)
	return maxi(1, final_tick)


func buy_partner(partner_index: int) -> Dictionary:
	return buy_partners(partner_index, "x1")


func buy_partners(partner_index: int, mode: String) -> Dictionary:
	if partner_index < 0 or partner_index >= partner_counts.size():
		return _make_purchase_result("Invalid partner")

	if not can_buy_partner(partner_index):
		return _make_purchase_result("Requires %s" % partner_names[partner_index - 1])

	var bought: int = get_partner_bulk_count(partner_index, mode)
	var total_cost: int = get_partner_bulk_cost(partner_index, mode)

	if bought <= 0 or total_cost <= 0 or gold < total_cost:
		return _make_purchase_result("Not enough gold", true)

	gold -= total_cost
	partner_counts[partner_index] += bought
	recalculate_partner_cost(partner_index)
	return _make_purchase_result("%s hired x%d!" % [partner_names[partner_index], bought], false, true)


func get_partner_bulk_count(partner_index: int, mode: String) -> int:
	if partner_index < 0 or partner_index >= partner_counts.size():
		return 0

	if not can_buy_partner(partner_index):
		return 0

	var fixed_count: int = _get_fixed_buy_count(mode)
	if fixed_count > 0:
		var fixed_cost: int = _get_partner_bulk_cost_for_count(partner_index, fixed_count)
		return fixed_count if gold >= fixed_cost else 0

	var simulated_gold: int = gold
	var simulated_count: int = partner_counts[partner_index]
	var count: int = 0
	var simulated_cost: int = partner_purchase_costs[partner_index]

	while simulated_gold >= simulated_cost:
		simulated_gold -= simulated_cost
		simulated_count += 1
		count += 1
		simulated_cost = _get_partner_cost_for_count(partner_index, simulated_count)

	return count


func get_partner_bulk_cost(partner_index: int, mode: String) -> int:
	var count: int = get_partner_bulk_count(partner_index, mode)
	if count <= 0:
		return 0

	return _get_partner_bulk_cost_for_count(partner_index, count)


func get_partner_bulk_display_count(partner_index: int, mode: String) -> int:
	if partner_index < 0 or partner_index >= partner_counts.size():
		return 0

	if not can_buy_partner(partner_index):
		return 0

	if mode == "max":
		return get_partner_bulk_count(partner_index, mode)

	return _get_fixed_buy_count(mode)


func get_partner_bulk_display_cost(partner_index: int, mode: String) -> int:
	if partner_index < 0 or partner_index >= partner_counts.size():
		return 0

	if not can_buy_partner(partner_index):
		return 0

	var display_count: int = get_partner_bulk_display_count(partner_index, mode)
	if display_count > 0:
		return _get_partner_bulk_cost_for_count(partner_index, display_count)

	return partner_purchase_costs[partner_index]


func can_buy_building(building_index: int) -> bool:
	if building_index == 0:
		return true

	if building_index > 0 and building_index < building_counts.size():
		return building_counts[building_index - 1] > 0

	return false


func buy_building(building_index: int) -> Dictionary:
	return buy_buildings(building_index, "x1")


func buy_buildings(building_index: int, mode: String) -> Dictionary:
	if building_index < 0 or building_index >= building_counts.size():
		return _make_purchase_result("Invalid building")

	if not can_buy_building(building_index):
		return _make_purchase_result("Requires %s" % building_names[building_index - 1])

	var bought: int = get_building_bulk_count(building_index, mode)
	var total_cost: int = get_building_bulk_cost(building_index, mode)

	if bought <= 0 or total_cost <= 0 or gold < total_cost:
		return _make_purchase_result("Not enough gold", true)

	gold -= total_cost
	building_counts[building_index] += bought
	recalculate_building_cost(building_index)
	_update_character_state()
	return _make_purchase_result("%s built x%d!" % [building_names[building_index], bought], false, true)


func get_building_bulk_count(building_index: int, mode: String) -> int:
	if building_index < 0 or building_index >= building_counts.size():
		return 0

	if not can_buy_building(building_index):
		return 0

	var fixed_count: int = _get_fixed_buy_count(mode)
	if fixed_count > 0:
		var fixed_cost: int = _get_building_bulk_cost_for_count(building_index, fixed_count)
		return fixed_count if gold >= fixed_cost else 0

	var simulated_gold: int = gold
	var simulated_count: int = building_counts[building_index]
	var count: int = 0
	var simulated_cost: int = building_purchase_costs[building_index]

	while simulated_gold >= simulated_cost:
		simulated_gold -= simulated_cost
		simulated_count += 1
		count += 1
		simulated_cost = _get_building_cost_for_count(building_index, simulated_count)

	return count


func get_building_bulk_cost(building_index: int, mode: String) -> int:
	var count: int = get_building_bulk_count(building_index, mode)
	if count <= 0:
		return 0

	return _get_building_bulk_cost_for_count(building_index, count)


func get_building_bulk_display_count(building_index: int, mode: String) -> int:
	if building_index < 0 or building_index >= building_counts.size():
		return 0

	if not can_buy_building(building_index):
		return 0

	if mode == "max":
		return get_building_bulk_count(building_index, mode)

	return _get_fixed_buy_count(mode)


func get_building_bulk_display_cost(building_index: int, mode: String) -> int:
	if building_index < 0 or building_index >= building_counts.size():
		return 0

	if not can_buy_building(building_index):
		return 0

	var display_count: int = get_building_bulk_display_count(building_index, mode)
	if display_count > 0:
		return _get_building_bulk_cost_for_count(building_index, display_count)

	return building_purchase_costs[building_index]


func get_building_effect_description(building_index: int) -> String:
	return get_building_short_effect_description(building_index)


func get_building_short_effect_description(building_index: int) -> String:
	if building_index < 0 or building_index >= building_names.size():
		return ""

	var amount: int = building_bonus_percent_per_level
	if building_index >= building_bonus_types.size():
		return "+%d%% Bonus" % amount

	match building_bonus_types[building_index]:
		"partner_dps":
			return "+%d%% DPS" % amount
		"gold":
			return "+%d%% Gold" % amount
		"click_damage":
			return "+%d%% Click Damage" % amount
		"ability_duration":
			return "+%d%% Focus/Rally Duration" % amount
		"ability_cooldown":
			return "+%d%% Cooldown Efficiency" % amount
		"boss_gold":
			return "+%d%% Boss Gold" % amount
		_:
			return "+%d%% Bonus" % amount


func get_partner_description(partner_index: int) -> String:
	if partner_index < 0 or partner_index >= partner_dps_values.size():
		return ""

	return "%d DPS" % partner_dps_values[partner_index]


func get_milestone_multiplier(level: int) -> int:
	var multiplier: int = 1
	for milestone in milestone_levels:
		if level >= milestone:
			multiplier *= milestone_multiplier_per_reached

	return multiplier


func get_next_milestone(level: int) -> int:
	for milestone in milestone_levels:
		if level < milestone:
			return milestone

	return 0


func is_milestone_target(target_level_or_count: int) -> bool:
	return milestone_levels.has(target_level_or_count)


func apply_milestone_cost_multiplier(cost: int, target_level_or_count: int) -> int:
	if is_milestone_target(target_level_or_count):
		return cost * milestone_cost_multiplier

	return cost


func get_character_milestone_multiplier() -> int:
	return get_milestone_multiplier(character_level)


func get_partner_milestone_multiplier(partner_index: int) -> int:
	if partner_index < 0 or partner_index >= partner_counts.size():
		return 1

	return get_milestone_multiplier(partner_counts[partner_index])


func get_partner_tier_total_dps(partner_index: int) -> int:
	if partner_index < 0 or partner_index >= partner_counts.size() or partner_index >= partner_dps_values.size():
		return 0

	return partner_counts[partner_index] * partner_dps_values[partner_index] * get_partner_milestone_multiplier(partner_index)


func get_ability_description(ability_id: String) -> String:
	match ability_id:
		"autoclick":
			return "20 attacks/sec for 15s"
		"gold_bonus":
			return "Gold rewards x2 for 45s"
		"focus_burst":
			return "Click/autoclick damage x2 for 20s"
		"rally":
			return "Partner DPS x2 for 30s"
		_:
			return ""


func get_prestige_talent_description(talent_index: int) -> String:
	if talent_index < 0 or talent_index >= prestige_talent_bonus_types.size():
		return ""

	var amount: int = prestige_talent_bonus_percent_per_level
	match prestige_talent_bonus_types[talent_index]:
		"click_damage":
			return "+%d%% Click Damage per level" % amount
		"gold":
			return "+%d%% Gold Gain per level" % amount
		"partner_dps":
			return "+%d%% Partner DPS per level" % amount
		"autoclick_rate":
			return "+%d%% Autoclick Rate per level" % amount
		"settlement_effect":
			return "+%d%% Settlement Bonus per level" % amount
		"boss_damage":
			return "+%d%% Boss Damage per level" % amount
		_:
			return "+%d%% Bonus per level" % amount


func recalculate_building_cost(building_index: int) -> void:
	building_purchase_costs[building_index] = _get_building_cost_for_count(
		building_index,
		building_counts[building_index]
	)


func get_settlement_partner_dps_bonus_percent() -> int:
	return get_building_bonus_percent(0)


func get_settlement_gold_bonus_percent() -> int:
	return get_building_bonus_percent(1)


func get_settlement_click_damage_bonus_percent() -> int:
	return get_building_bonus_percent(2)


func get_settlement_ability_duration_bonus_percent() -> int:
	return get_building_bonus_percent(3)


func get_settlement_cooldown_reduction_percent() -> int:
	return int((1.0 - get_ability_cooldown_multiplier()) * 100.0)


func get_settlement_boss_gold_bonus_percent() -> int:
	return get_building_bonus_percent(5)


func get_building_bonus_percent(building_index: int) -> int:
	return get_building_raw_bonus_percent(building_index)


func get_building_raw_bonus_percent(building_index: int) -> int:
	if building_index < 0 or building_index >= building_counts.size():
		return 0

	var building_count: int = building_counts[building_index]
	if building_count <= 0:
		return 0

	var base_bonus: int = building_count * building_bonus_percent_per_level
	var milestone_bonus: int = base_bonus * get_milestone_multiplier(building_count)
	return int(milestone_bonus * get_settlement_effectiveness_multiplier())


func get_diminishing_reduction_multiplier(raw_bonus_percent: int) -> float:
	# Positive settlement effects can use additive percent bonuses.
	# Reduction effects must use diminishing returns; never implement direct 100% cost/cooldown reduction.
	# Future cost-reduction buildings should use this helper.
	return 100.0 / (100.0 + float(maxi(0, raw_bonus_percent)))


func get_settlement_partner_dps_multiplier() -> float:
	return 1.0 + get_settlement_partner_dps_bonus_percent() / 100.0


func get_settlement_gold_multiplier() -> float:
	return 1.0 + get_settlement_gold_bonus_percent() / 100.0


func get_settlement_click_damage_multiplier() -> float:
	return 1.0 + get_settlement_click_damage_bonus_percent() / 100.0


func get_ability_duration_multiplier() -> float:
	return 1.0 + get_settlement_ability_duration_bonus_percent() / 100.0


func get_ability_cooldown_multiplier() -> float:
	return get_diminishing_reduction_multiplier(get_building_raw_bonus_percent(4))


func get_boss_reward_multiplier() -> float:
	return 1.0 + get_settlement_boss_gold_bonus_percent() / 100.0


func recalculate_character_level_cost() -> void:
	character_level_upgrade_cost = _get_character_level_cost_for_level(character_level)


func recalculate_partner_cost(partner_index: int) -> void:
	if partner_index < 0 or partner_index >= partner_purchase_costs.size():
		return

	partner_purchase_costs[partner_index] = _get_partner_cost_for_count(
		partner_index,
		partner_counts[partner_index]
	)


func can_buy_partner(partner_index: int) -> bool:
	if partner_index == 0:
		return true

	if partner_index > 0 and partner_index < partner_counts.size():
		return partner_counts[partner_index - 1] > 0

	return false


func _get_fixed_buy_count(mode: String) -> int:
	if mode == "max":
		return 0

	if mode == "x10":
		return 10

	if mode == "x100":
		return 100

	return 1


func _get_character_level_bulk_cost_for_count(count: int) -> int:
	var simulated_level: int = character_level
	var simulated_cost: int = character_level_upgrade_cost
	var total_cost: int = 0

	for i in range(count):
		total_cost += simulated_cost
		simulated_level += 1
		simulated_cost = _get_character_level_cost_for_level(simulated_level)

	return total_cost


func _get_character_level_cost_for_level(level: int) -> int:
	# Non-linear, not exponential: target level is current + 1, and milestone targets cost x3.
	var current_hero_level: int = maxi(1, level)
	var target_level: int = current_hero_level + 1
	var progress: float = float(current_hero_level - 1)
	var raw_cost: float = (
		float(character_cost_base)
		+ character_cost_linear * progress
		+ character_cost_curve * pow(progress, character_cost_power)
	)
	var cost: int = maxi(1, ceili(raw_cost))
	return apply_milestone_cost_multiplier(cost, target_level)


func _get_partner_bulk_cost_for_count(partner_index: int, count: int) -> int:
	var simulated_count: int = partner_counts[partner_index]
	var simulated_cost: int = partner_purchase_costs[partner_index]
	var total_cost: int = 0

	for i in range(count):
		total_cost += simulated_cost
		simulated_count += 1
		simulated_cost = _get_partner_cost_for_count(partner_index, simulated_count)

	return total_cost


func _get_partner_cost_for_count(partner_index: int, count: int) -> int:
	if partner_index >= 0 and partner_index < partner_base_costs.size():
		# Non-linear, not exponential: target count is current + 1, and milestone targets cost x3.
		var current_count: int = maxi(0, count)
		var target_count: int = current_count + 1
		var base: int = partner_base_costs[partner_index]
		var step: int = partner_cost_steps[partner_index]
		var raw_cost: float = (
			float(base)
			+ float(step * current_count)
			+ float(base) * partner_cost_curve_multiplier * pow(float(current_count), partner_cost_power)
		)
		var cost: int = maxi(1, ceili(raw_cost))
		return apply_milestone_cost_multiplier(cost, target_count)

	return 0


func _get_total_partner_count() -> int:
	var total_count: int = 0
	for count in partner_counts:
		total_count += count

	return total_count


func _get_total_building_count() -> int:
	var total_count: int = 0
	for count in building_counts:
		total_count += count

	return total_count


func _get_building_bulk_cost_for_count(building_index: int, count: int) -> int:
	var simulated_count: int = building_counts[building_index]
	var simulated_cost: int = building_purchase_costs[building_index]
	var total_cost: int = 0

	for i in range(count):
		total_cost += simulated_cost
		simulated_count += 1
		simulated_cost = _get_building_cost_for_count(building_index, simulated_count)

	return total_cost


func _get_building_cost_for_count(building_index: int, count: int) -> int:
	if building_index >= 0 and building_index < building_base_costs.size():
		return building_base_costs[building_index] + count * building_cost_steps[building_index]

	return 0


func _reset_partner_state() -> void:
	partner_counts.clear()
	partner_purchase_costs.clear()
	for i in range(partner_base_costs.size()):
		partner_counts.append(0)
		partner_purchase_costs.append(partner_base_costs[i])


func _reset_building_state() -> void:
	building_counts.clear()
	building_purchase_costs.clear()
	for i in range(building_base_costs.size()):
		building_counts.append(0)
		building_purchase_costs.append(building_base_costs[i])


func is_current_level_boss() -> bool:
	return current_level % 10 == 0


func setup_current_level() -> void:
	is_boss_level = is_current_level_boss()
	_update_zone()
	enemies_required_per_level = 1 if is_boss_level else 10
	reset_target()


func update_ability_unlocks() -> void:
	autoclick_unlocked = character_level >= autoclick_unlock_level
	gold_bonus_unlocked = character_level >= gold_bonus_unlock_level
	focus_burst_unlocked = character_level >= focus_burst_unlock_level
	rally_unlocked = character_level >= rally_unlock_level

	if not autoclick_unlocked:
		autoclick_active = false
		autoclick_purchased = false

	if not gold_bonus_unlocked:
		gold_bonus_active = false
		gold_bonus_purchased = false

	if not focus_burst_unlocked:
		focus_burst_active = false
		focus_burst_purchased = false

	if not rally_unlocked:
		rally_active = false
		rally_purchased = false


func fail_boss_level() -> Dictionary:
	if is_boss_level and boss_retry_tokens > 0:
		boss_retry_tokens -= 1
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
			"boss_retry_used": true,
			"status_text": "Boss Retry used! Try Level %d again" % current_level,
			"zone_changed": false,
			"zone_name": "",
		}

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
	choose_enemy_for_current_level()
	recalculate_level_values()
	target_hp = target_max_hp


func choose_enemy_for_current_level() -> void:
	var zone: Dictionary = ZONE_DATA[current_zone_index]
	if is_boss_level:
		is_elite_enemy = false
		enemy_name = zone.boss
		return

	if rng.randf() < elite_spawn_chance:
		is_elite_enemy = true
		enemy_name = zone.elite_enemy
		return

	is_elite_enemy = false
	var enemies: Array = zone.enemies
	if enemies.is_empty():
		enemy_name = "Enemy"
		return

	enemy_name = enemies[rng.randi_range(0, enemies.size() - 1)]


func recalculate_level_values() -> void:
	var zone: Dictionary = ZONE_DATA[current_zone_index]
	var base_hp: int = get_base_enemy_hp_for_level(current_level)
	var base_reward: int = get_base_enemy_reward_for_level(current_level)
	var scaled_hp: int = ceili(base_hp * zone.hp_multiplier)
	var scaled_reward: int = ceili(base_reward * zone.reward_multiplier)
	if is_boss_level:
		target_max_hp = scaled_hp * 5
		reward_gold = scaled_reward * 5
	elif is_elite_enemy:
		target_max_hp = scaled_hp * elite_hp_multiplier
		reward_gold = scaled_reward * elite_reward_multiplier
	else:
		target_max_hp = scaled_hp
		reward_gold = scaled_reward


func get_base_enemy_hp_for_level(level: int) -> int:
	# HP uses the stronger curve; rewards grow slower so progression increasingly needs power spikes.
	var stage: float = float(maxi(0, level - 1))
	var base_hp: float = (
		float(enemy_hp_base)
		+ enemy_hp_linear * stage
		+ enemy_hp_curve * pow(stage, enemy_hp_power)
	)
	return maxi(1, ceili(base_hp))


func get_base_enemy_reward_for_level(level: int) -> int:
	# Prototype balance values: tune these alongside partner DPS and milestone x2 spikes.
	var stage: float = float(maxi(0, level - 1))
	var base_reward: float = (
		float(enemy_reward_base)
		+ enemy_reward_linear * stage
		+ enemy_reward_curve * pow(stage, enemy_reward_power)
	)
	return maxi(1, ceili(base_reward))


func _get_zone_index_for_level(level: int) -> int:
	for i in range(ZONE_DATA.size()):
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
	var base_damage: int = character_level * get_character_milestone_multiplier()
	click_damage = maxi(
		1,
		int(
			base_damage
			* get_focus_training_multiplier()
			* get_focus_burst_multiplier()
			* get_settlement_click_damage_multiplier()
		)
	)
	update_ability_unlocks()


func get_current_click_damage() -> int:
	var base_damage: int = click_damage
	if base_damage <= 0:
		return 0

	return maxi(1, int(base_damage * get_boss_damage_multiplier()))


func refresh_derived_stats() -> void:
	_update_character_state()


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
