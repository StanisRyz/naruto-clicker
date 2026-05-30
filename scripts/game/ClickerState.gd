class_name ClickerState
extends RefCounted

const SaveAdapter = preload("res://scripts/game/save/ClickerStateSaveAdapter.gd")
const MilestoneCalc = preload("res://scripts/game/calculators/MilestoneCalculator.gd")
const CostCalc = preload("res://scripts/game/calculators/CostCalculator.gd")
const EnemyCalc = preload("res://scripts/game/calculators/EnemyScalingCalculator.gd")


var gold: int = 0
var gems: int = 0
var click_damage: int = 1
var character_level: int = 1
var character_level_upgrade_cost: int = 5
var current_level: int = 1
var max_unlocked_level: int = 1
var auto_stage_advance_enabled: bool = true
var cleared_level_ids: Dictionary = {}
var level_enemy_progress: Dictionary = {}
var enemies_defeated_on_level: int = 0
var enemies_required_per_level: int = 10
var target_hp: int = 10
var target_max_hp: int = 10
var reward_gold: int = 5
var is_boss_level: bool = false
var is_elite_enemy: bool = false
var elite_spawn_chance: float = BalanceConfig.ELITE_SPAWN_CHANCE
var elite_hp_multiplier: int = BalanceConfig.ELITE_HP_MULTIPLIER
var elite_reward_multiplier: int = BalanceConfig.ELITE_REWARD_MULTIPLIER
var boss_time_limit: float = BalanceConfig.BOSS_TIME_LIMIT
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
var autoclick_rank: int = 0
var gold_bonus_rank: int = 0
var focus_burst_rank: int = 0
var rally_rank: int = 0
var ability_max_rank: int = BalanceConfig.ABILITY_MAX_RANK
var autoclick_unlock_level: int = BalanceConfig.AUTOCLICK_UNLOCK_LEVEL
var gold_bonus_unlock_level: int = BalanceConfig.GOLD_BONUS_UNLOCK_LEVEL
var focus_burst_unlock_level: int = BalanceConfig.FOCUS_BURST_UNLOCK_LEVEL
var rally_unlock_level: int = BalanceConfig.RALLY_UNLOCK_LEVEL
var autoclick_purchase_cost: int = BalanceConfig.AUTOCLICK_PURCHASE_COST
var gold_bonus_purchase_cost: int = BalanceConfig.GOLD_BONUS_PURCHASE_COST
var focus_burst_purchase_cost: int = BalanceConfig.FOCUS_BURST_PURCHASE_COST
var rally_purchase_cost: int = BalanceConfig.RALLY_PURCHASE_COST
var gold_bonus_multiplier: int = 2  # kept literal; see BalanceConfig for rank-based formula
var partner_counts: Array[int] = []
var partner_purchase_costs: Array[int] = []
var purchased_partner_skill_ids: Array[String] = []
var purchased_hero_skill_ids: Array[String] = []
var purchased_ability_skill_ids: Array[String] = []
var milestone_multiplier_per_reached: int = BalanceConfig.MILESTONE_MULTIPLIER_PER_REACHED
var milestone_cost_multiplier: int = BalanceConfig.MILESTONE_COST_MULTIPLIER
var character_cost_base: int = BalanceConfig.HERO_COST_BASE
var character_cost_linear: float = BalanceConfig.HERO_COST_LINEAR
var character_cost_curve: float = BalanceConfig.HERO_COST_CURVE
var character_cost_power: float = BalanceConfig.HERO_COST_POWER
var partner_cost_curve_multiplier: float = BalanceConfig.PARTNER_COST_CURVE_MULT
var partner_cost_power: float = BalanceConfig.PARTNER_COST_POWER
var enemy_hp_base: int = BalanceConfig.ENEMY_HP_BASE
var enemy_hp_linear: float = BalanceConfig.ENEMY_HP_LINEAR
var enemy_hp_curve: float = BalanceConfig.ENEMY_HP_CURVE
var enemy_hp_power: float = BalanceConfig.ENEMY_HP_POWER
var enemy_reward_base: int = BalanceConfig.ENEMY_REWARD_BASE
var enemy_reward_linear: float = BalanceConfig.ENEMY_REWARD_LINEAR
var enemy_reward_curve: float = BalanceConfig.ENEMY_REWARD_CURVE
var enemy_reward_power: float = BalanceConfig.ENEMY_REWARD_POWER
var building_counts: Array[int] = []
var building_bonus_percent_per_level: int = BalanceConfig.BUILDING_BONUS_PERCENT_PER_LEVEL
var building_purchase_costs: Array[int] = []
var boss_retry_tokens: int = 0
var task_reward_boost_multiplier: float = 1.0

var current_zone_index: int = 0
var current_enemy_zone_index: int = 0
var current_enemy_slot: String = "enemy_01"
var zone_name: String = "Training Grounds"
var zone_level_start: int = 1
var zone_level_end: int = 10
var zone_hp_multiplier: float = 1.0
var zone_reward_multiplier: float = 1.0
var sound_enabled: bool = true
var music_enabled: bool = true

var prestige_points_available: int = 0
var prestige_points_total_earned: int = 0
var total_prestiges: int = 0
var prestige_required_level: int = BalanceConfig.PRESTIGE_REQUIRED_LEVEL
var prestige_talent_levels: Array[int] = [0, 0, 0, 0, 0, 0]
var prestige_talent_bonus_percent_per_level: int = BalanceConfig.PRESTIGE_TALENT_BONUS_PERCENT_PER_LEVEL
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
	for task: Dictionary in TaskConfig.TASK_DEFINITIONS:
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
	for task: Dictionary in TaskConfig.TASK_DEFINITIONS:
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

	return maxi(1, int(get_current_task_reward_unit() * reward_scale * get_partner_skill_bonus_multiplier("task_reward")))


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


func get_partner_skill_gold_multiplier() -> float:
	return get_partner_skill_bonus_multiplier("gold")


func get_hero_skill_gold_multiplier() -> float:
	return get_hero_skill_bonus_multiplier("gold")


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
	return (1.0 + get_boss_hunter_bonus_percent() / 100.0) * get_partner_skill_bonus_multiplier("boss_damage")


func get_settlement_effectiveness_multiplier() -> float:
	return (1.0 + get_builder_wisdom_bonus_percent() / 100.0) * get_partner_skill_bonus_multiplier("settlement_effect")


func get_boss_timer_multiplier() -> float:
	return get_partner_skill_bonus_multiplier("boss_timer")


func get_focus_burst_multiplier() -> float:
	var rank: int = get_ability_rank("focus_burst")
	return 2.0 + 0.25 * rank if focus_burst_active and is_ability_purchased("focus_burst") else 1.0


func get_rally_multiplier() -> float:
	var rank: int = get_ability_rank("rally")
	return 2.0 + 0.25 * rank if rally_active and is_ability_purchased("rally") else 1.0


func get_gold_bonus_multiplier() -> float:
	var rank: int = get_ability_rank("gold_bonus")
	return 2.0 + 0.25 * rank if gold_bonus_active and is_ability_purchased("gold_bonus") else 1.0


func get_autoclick_rank_rate_multiplier() -> float:
	var rank: int = get_ability_rank("autoclick")
	return 1.0 + 0.15 * rank


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
	for product: Dictionary in ShopConfig.SHOP_PRODUCTS:
		if String(product.get("id", "")) == product_id:
			return product

	return {}


func get_shop_product_view_data() -> Array[Dictionary]:
	var product_view_data: Array[Dictionary] = []
	for product: Dictionary in ShopConfig.SHOP_PRODUCTS:
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
			var shop_gold: int = maxi(1, get_current_task_reward_unit() * reward_scale)
			gold += shop_gold
			result["reward_gold"] = shop_gold
			result["status_text"] = "%s purchased! +%d gold" % [product_name, shop_gold]
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
	max_unlocked_level = 1
	enemies_defeated_on_level = 0
	clear_cleared_levels()
	clear_all_level_progress()
	auto_stage_advance_enabled = true
	autoclick_purchased = false
	autoclick_rank = 0
	autoclick_active = false
	gold_bonus_purchased = false
	gold_bonus_rank = 0
	gold_bonus_active = false
	focus_burst_purchased = false
	focus_burst_rank = 0
	focus_burst_active = false
	rally_purchased = false
	rally_rank = 0
	rally_active = false
	purchased_partner_skill_ids.clear()
	purchased_hero_skill_ids.clear()
	purchased_ability_skill_ids.clear()

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
			var next_zone: Dictionary = ZoneConfig.ZONE_DATA[next_zone_index]
			new_zone_name = next_zone.name

	return _make_attack_result(true, did_level_up, 0, damage_dealt, target_hp_before, 0, "Enemy defeated!", zone_changed, new_zone_name)


func resolve_defeated_target() -> Dictionary:
	if target_hp > 0:
		return _make_attack_result(false, false, 0, 0, target_hp, target_hp, "")

	var target_hp_before: int = target_hp
	var damage_dealt: int = 0
	var defeated_boss: bool = is_boss_level
	var defeated_elite: bool = is_elite_enemy
	var source_reward: int = reward_gold
	if defeated_boss:
		source_reward = int(source_reward * get_boss_reward_multiplier())
	if defeated_elite:
		source_reward = int(source_reward * get_partner_skill_bonus_multiplier("elite_reward"))
	var talent_gold: int = int(
		source_reward
		* get_trade_routes_multiplier()
		* get_partner_skill_gold_multiplier()
		* get_hero_skill_bonus_multiplier("gold")
	)
	var settlement_gold: int = int(talent_gold * get_settlement_gold_multiplier())
	var earned_gold: int = int(settlement_gold * get_gold_bonus_multiplier()) if gold_bonus_active else settlement_gold
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
	var advanced_to_next_level: bool = false
	var level_unlocked: bool = false
	var unlocked_level: int = max_unlocked_level

	if is_level_cleared(current_level):
		# Farming a previously cleared level
		if auto_stage_advance_enabled:
			# Auto ON: advance to current_level + 1 on this kill
			save_current_level_progress()
			var old_zone_index: int = current_zone_index
			current_level += 1
			enemies_defeated_on_level = 0
			setup_current_level()
			zone_changed = current_zone_index != old_zone_index
			new_zone_name = zone_name
			advanced_to_next_level = true
			if zone_changed:
				status_text = "New zone: %s" % zone_name
			elif defeated_boss:
				status_text = "Boss defeated! +%d gold. Level %d" % [earned_gold, current_level]
			else:
				status_text = "Level up! Level %d" % current_level
		else:
			# Stay farming; no new stage unlock
			enemies_defeated_on_level = enemies_required_per_level
			reset_target()
			save_current_level_progress()
			if defeated_boss:
				status_text = "Boss defeated! +%d gold. Farming stage %d." % [earned_gold, current_level]
			else:
				status_text = "+%d gold. Farming stage %d." % [earned_gold, current_level]
	elif did_level_up:
		mark_level_cleared(current_level)
		var next_level: int = current_level + 1
		level_unlocked = max_unlocked_level < next_level
		max_unlocked_level = maxi(max_unlocked_level, next_level)
		unlocked_level = max_unlocked_level

		if auto_stage_advance_enabled:
			save_current_level_progress()
			var old_zone_index: int = current_zone_index
			current_level += 1
			enemies_defeated_on_level = 0
			setup_current_level()
			zone_changed = current_zone_index != old_zone_index
			new_zone_name = zone_name
			advanced_to_next_level = true
			if zone_changed:
				status_text = "New zone: %s" % zone_name
			elif defeated_boss:
				status_text = "Boss defeated! +%d gold. Level %d" % [earned_gold, current_level]
			else:
				status_text = "Level up! Level %d" % current_level
		else:
			enemies_defeated_on_level = enemies_required_per_level
			reset_target()
			save_current_level_progress()
			if defeated_boss:
				status_text = "Boss defeated! +%d gold. Stage %d unlocked." % [earned_gold, next_level]
			else:
				status_text = "+%d gold. Stage %d unlocked." % [earned_gold, next_level]
	else:
		reset_target()
		save_current_level_progress()

	var base_result: Dictionary = _make_attack_result(true, did_level_up, earned_gold, damage_dealt, target_hp_before, 0, status_text, zone_changed, new_zone_name)
	base_result["advanced_to_next_level"] = advanced_to_next_level
	base_result["level_unlocked"] = level_unlocked
	base_result["unlocked_level"] = unlocked_level
	return base_result


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
	return buy_ability_unlock("autoclick")


func buy_gold_bonus_ability() -> Dictionary:
	return buy_ability_unlock("gold_bonus")


func buy_focus_burst_ability() -> Dictionary:
	return buy_ability_unlock("focus_burst")


func buy_rally_ability() -> Dictionary:
	return buy_ability_unlock("rally")


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
		* get_partner_skill_bonus_multiplier("partner_dps")
		* get_hero_skill_bonus_multiplier("partner_dps")
		* get_partner_skill_bonus_multiplier("all_damage")
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


func get_autoclick_damage() -> int:
	return maxi(1, int(get_current_click_damage() * get_partner_skill_bonus_multiplier("autoclick_damage")))


func buy_partner(partner_index: int) -> Dictionary:
	return buy_partners(partner_index, "x1")


func buy_partners(partner_index: int, mode: String) -> Dictionary:
	if partner_index < 0 or partner_index >= partner_counts.size():
		return _make_purchase_result("Invalid partner")

	if not can_buy_partner(partner_index):
		return _make_purchase_result("Requires %s" % PartnerConfig.PARTNER_NAMES[partner_index - 1])

	var bought: int = get_partner_bulk_count(partner_index, mode)
	var total_cost: int = get_partner_bulk_cost(partner_index, mode)

	if bought <= 0 or total_cost <= 0 or gold < total_cost:
		return _make_purchase_result("Not enough gold", true)

	gold -= total_cost
	partner_counts[partner_index] += bought
	recalculate_partner_cost(partner_index)
	_update_character_state()
	return _make_purchase_result("%s hired x%d!" % [PartnerConfig.PARTNER_NAMES[partner_index], bought], false, true)


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
		return _make_purchase_result("Requires %s" % SettlementConfig.BUILDING_NAMES[building_index - 1])

	var bought: int = get_building_bulk_count(building_index, mode)
	var total_cost: int = get_building_bulk_cost(building_index, mode)

	if bought <= 0 or total_cost <= 0 or gold < total_cost:
		return _make_purchase_result("Not enough gold", true)

	gold -= total_cost
	building_counts[building_index] += bought
	recalculate_building_cost(building_index)
	_update_character_state()
	return _make_purchase_result("%s built x%d!" % [SettlementConfig.BUILDING_NAMES[building_index], bought], false, true)


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
	if building_index < 0 or building_index >= SettlementConfig.BUILDING_NAMES.size():
		return ""

	var amount: int = building_bonus_percent_per_level
	if building_index >= SettlementConfig.BUILDING_BONUS_TYPES.size():
		return "+%d%% Bonus" % amount

	match SettlementConfig.BUILDING_BONUS_TYPES[building_index]:
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
	if partner_index < 0 or partner_index >= BalanceConfig.PARTNER_DPS_VALUES.size():
		return ""

	return "%d DPS" % BalanceConfig.PARTNER_DPS_VALUES[partner_index]


func get_milestone_multiplier(level: int) -> int:
	return MilestoneCalc.get_milestone_multiplier(level, BalanceConfig.MILESTONE_LEVELS, milestone_multiplier_per_reached)


func get_next_milestone(level: int) -> int:
	return MilestoneCalc.get_next_milestone(level, BalanceConfig.MILESTONE_LEVELS)


func is_milestone_target(target_level_or_count: int) -> bool:
	return MilestoneCalc.is_milestone_target(target_level_or_count, BalanceConfig.MILESTONE_LEVELS)


func apply_milestone_cost_multiplier(cost: int, target_level_or_count: int) -> int:
	return MilestoneCalc.apply_milestone_cost_multiplier(cost, target_level_or_count, BalanceConfig.MILESTONE_LEVELS, milestone_cost_multiplier)


func get_character_milestone_multiplier() -> int:
	return get_milestone_multiplier(character_level)


func get_partner_milestone_multiplier(partner_index: int) -> int:
	if partner_index < 0 or partner_index >= partner_counts.size():
		return 1

	return get_milestone_multiplier(partner_counts[partner_index])


func get_partner_skills_for_partner(partner_index: int) -> Array[Dictionary]:
	var skills: Array[Dictionary] = []
	for skill: Dictionary in PartnerSkillConfig.SKILL_DEFINITIONS:
		if int(skill.get("partner_index", -1)) == partner_index:
			skills.append(skill)
	return skills


func get_partner_skill(skill_id: String) -> Dictionary:
	for skill: Dictionary in PartnerSkillConfig.SKILL_DEFINITIONS:
		if String(skill.get("id", "")) == skill_id:
			return skill

	return {}


func get_hero_skills() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for s in HeroSkillConfig.SKILL_DEFINITIONS:
		result.append(s)
	return result


func get_hero_skill(skill_id: String) -> Dictionary:
	for skill: Dictionary in HeroSkillConfig.SKILL_DEFINITIONS:
		if String(skill.get("id", "")) == skill_id:
			return skill
	return {}


func is_hero_skill_unlocked(skill_id: String) -> bool:
	var skill: Dictionary = get_hero_skill(skill_id)
	if skill.is_empty():
		return false
	return character_level >= int(skill.get("unlock_character_level", 0))


func is_hero_skill_purchased(skill_id: String) -> bool:
	return purchased_hero_skill_ids.has(skill_id)


func can_buy_hero_skill(skill_id: String) -> bool:
	if is_hero_skill_purchased(skill_id) or not is_hero_skill_unlocked(skill_id):
		return false
	var cost: int = get_hero_skill_cost(skill_id)
	return cost > 0 and gold >= cost


func get_hero_skill_state(skill_id: String) -> String:
	if is_hero_skill_purchased(skill_id):
		return "purchased"
	if is_hero_skill_unlocked(skill_id):
		return "available"
	return "locked"


func get_hero_skill_cost(skill_id: String) -> int:
	var skill: Dictionary = get_hero_skill(skill_id)
	if skill.is_empty():
		return 0
	var skill_level: int = int(skill.get("skill_level", 0))
	var unlock_level: int = int(skill.get("unlock_character_level", 0))
	if skill_level < 1 or skill_level > BalanceConfig.HERO_SKILL_COST_MULTIPLIERS.size() or unlock_level <= 1:
		return 0
	var base_cost: int = _get_character_level_cost_for_level(unlock_level - 1)
	return base_cost * BalanceConfig.HERO_SKILL_COST_MULTIPLIERS[skill_level - 1]


func buy_hero_skill(skill_id: String) -> Dictionary:
	var skill: Dictionary = get_hero_skill(skill_id)
	if skill.is_empty():
		return _make_purchase_result("Invalid hero skill")
	if is_hero_skill_purchased(skill_id):
		return _make_purchase_result("Hero skill already purchased")
	if not is_hero_skill_unlocked(skill_id):
		return _make_purchase_result("Requires Hero Level %d" % int(skill.get("unlock_character_level", 0)))
	var cost: int = get_hero_skill_cost(skill_id)
	if cost <= 0 or gold < cost:
		return _make_purchase_result("Not enough gold", true)
	gold -= cost
	purchased_hero_skill_ids.append(skill_id)
	_update_character_state()
	return _make_purchase_result("%s purchased!" % String(skill.get("name", "Hero skill")), false, true)


func get_ability_skills(ability_id: String) -> Array[Dictionary]:
	var skills: Array[Dictionary] = []
	for skill: Dictionary in AbilityConfig.SKILL_DEFINITIONS:
		if String(skill.get("ability_id", "")) == ability_id:
			skills.append(skill)
	return skills


func get_ability_skill(skill_id: String) -> Dictionary:
	for skill: Dictionary in AbilityConfig.SKILL_DEFINITIONS:
		if String(skill.get("id", "")) == skill_id:
			return skill
	return {}


func is_ability_skill_unlocked(skill_id: String) -> bool:
	var skill: Dictionary = get_ability_skill(skill_id)
	if skill.is_empty():
		return false
	return character_level >= int(skill.get("unlock_character_level", 0)) and is_ability_purchased(String(skill.get("ability_id", "")))


func is_ability_skill_purchased(skill_id: String) -> bool:
	return purchased_ability_skill_ids.has(skill_id)


func can_buy_ability_skill(skill_id: String) -> bool:
	if is_ability_skill_purchased(skill_id) or not is_ability_skill_unlocked(skill_id):
		return false
	var cost: int = get_ability_skill_cost(skill_id)
	return cost > 0 and gold >= cost


func get_ability_skill_state(skill_id: String) -> String:
	if is_ability_skill_purchased(skill_id):
		return "purchased"
	if is_ability_skill_unlocked(skill_id):
		return "available"
	return "locked"


func get_ability_skill_cost(skill_id: String) -> int:
	var skill: Dictionary = get_ability_skill(skill_id)
	if skill.is_empty():
		return 0
	var skill_level: int = int(skill.get("skill_level", 0))
	if skill_level < 1 or skill_level > BalanceConfig.ABILITY_SKILL_COST_MULTIPLIERS.size():
		return 0
	var base_cost: int = _get_ability_base_cost(String(skill.get("ability_id", "")))
	return base_cost * BalanceConfig.ABILITY_SKILL_COST_MULTIPLIERS[skill_level - 1]


func buy_ability_skill(skill_id: String) -> Dictionary:
	var skill: Dictionary = get_ability_skill(skill_id)
	if skill.is_empty():
		return _make_purchase_result("Invalid ability skill")
	if is_ability_skill_purchased(skill_id):
		return _make_purchase_result("Ability skill already purchased")
	var ability_id: String = String(skill.get("ability_id", ""))
	if not is_ability_purchased(ability_id):
		return _make_purchase_result("Requires buying %s first" % _get_ability_display_name(ability_id))
	if not is_ability_skill_unlocked(skill_id):
		return _make_purchase_result("Requires Hero Level %d" % int(skill.get("unlock_character_level", 0)))
	var cost: int = get_ability_skill_cost(skill_id)
	if cost <= 0 or gold < cost:
		return _make_purchase_result("Not enough gold", true)
	gold -= cost
	purchased_ability_skill_ids.append(skill_id)
	_sync_ability_rank_fields()
	_update_character_state()
	return _make_purchase_result("%s purchased!" % String(skill.get("name", "Ability skill")), false, true)


func get_hero_skill_bonus_multiplier(bonus_type: String) -> float:
	var total_bonus: float = 0.0
	for skill: Dictionary in HeroSkillConfig.SKILL_DEFINITIONS:
		var skill_id: String = String(skill.get("id", ""))
		if not is_hero_skill_purchased(skill_id):
			continue
		if String(skill.get("bonus_type", "")) == bonus_type:
			total_bonus += float(skill.get("bonus_value", 0.0))
	return 1.0 + total_bonus


func get_partner_skill_cost(skill_id: String) -> int:
	var skill: Dictionary = get_partner_skill(skill_id)
	if skill.is_empty():
		return 0

	var partner_index: int = int(skill.get("partner_index", -1))
	var unlock_count: int = int(skill.get("unlock_count", 0))
	var skill_level: int = int(skill.get("skill_level", 1))
	if partner_index < 0 or partner_index >= BalanceConfig.PARTNER_BASE_COSTS.size() or unlock_count <= 0:
		return 0
	if skill_level < 1 or skill_level > BalanceConfig.PARTNER_SKILL_COST_MULTIPLIERS.size():
		return 0

	var base_milestone_cost: int = _get_partner_cost_for_count(partner_index, unlock_count - 1)
	return base_milestone_cost * BalanceConfig.PARTNER_SKILL_COST_MULTIPLIERS[skill_level - 1]


func is_partner_skill_unlocked(skill_id: String) -> bool:
	var skill: Dictionary = get_partner_skill(skill_id)
	if skill.is_empty():
		return false

	var partner_index: int = int(skill.get("partner_index", -1))
	if partner_index < 0 or partner_index >= partner_counts.size():
		return false

	return partner_counts[partner_index] >= int(skill.get("unlock_count", 0))


func is_partner_skill_purchased(skill_id: String) -> bool:
	return purchased_partner_skill_ids.has(skill_id)


func can_buy_partner_skill(skill_id: String) -> bool:
	if is_partner_skill_purchased(skill_id) or not is_partner_skill_unlocked(skill_id):
		return false

	var cost: int = get_partner_skill_cost(skill_id)
	return cost > 0 and gold >= cost


func get_partner_skill_state(skill_id: String) -> String:
	if is_partner_skill_purchased(skill_id):
		return "purchased"

	if is_partner_skill_unlocked(skill_id):
		return "available"

	return "locked"


func buy_partner_skill(skill_id: String) -> Dictionary:
	var skill: Dictionary = get_partner_skill(skill_id)
	if skill.is_empty():
		return _make_purchase_result("Invalid partner skill")

	if is_partner_skill_purchased(skill_id):
		return _make_purchase_result("Partner skill already purchased")

	if not is_partner_skill_unlocked(skill_id):
		var partner_index: int = int(skill.get("partner_index", -1))
		var partner_name: String = "Partner"
		if partner_index >= 0 and partner_index < PartnerConfig.PARTNER_NAMES.size():
			partner_name = PartnerConfig.PARTNER_NAMES[partner_index]
		return _make_purchase_result("Requires %s x%d" % [
			partner_name,
			int(skill.get("unlock_count", 0)),
		])

	var cost: int = get_partner_skill_cost(skill_id)
	if cost <= 0 or gold < cost:
		return _make_purchase_result("Not enough gold", true)

	gold -= cost
	purchased_partner_skill_ids.append(skill_id)
	_update_character_state()
	return _make_purchase_result("%s purchased!" % String(skill.get("name", "Partner skill")), false, true)


func get_partner_skill_bonus_multiplier(bonus_type: String) -> float:
	return 1.0 + _get_partner_skill_total_bonus(bonus_type)


func get_partner_skill_additive_bonus(bonus_type: String) -> float:
	return _get_partner_skill_total_bonus(bonus_type)


func get_own_partner_skill_multiplier(partner_index: int) -> float:
	var total_bonus: float = 0.0
	for skill: Dictionary in PartnerSkillConfig.SKILL_DEFINITIONS:
		if int(skill.get("partner_index", -1)) != partner_index:
			continue
		if String(skill.get("bonus_type", "")) != "own_partner_dps":
			continue
		var skill_id: String = String(skill.get("id", ""))
		if not is_partner_skill_purchased(skill_id):
			continue
		total_bonus += float(skill.get("bonus_value", 0.0))
	return 1.0 + total_bonus


func get_partner_tier_total_dps(partner_index: int) -> int:
	if partner_index < 0 or partner_index >= partner_counts.size() or partner_index >= BalanceConfig.PARTNER_DPS_VALUES.size():
		return 0

	return int(
		partner_counts[partner_index]
		* BalanceConfig.PARTNER_DPS_VALUES[partner_index]
		* get_partner_milestone_multiplier(partner_index)
		* get_own_partner_skill_multiplier(partner_index)
	)


func _get_partner_skill_total_bonus(bonus_type: String) -> float:
	var total_bonus: float = 0.0
	for skill: Dictionary in PartnerSkillConfig.SKILL_DEFINITIONS:
		var skill_id: String = String(skill.get("id", ""))
		if not is_partner_skill_purchased(skill_id):
			continue
		if String(skill.get("bonus_type", "")) == bonus_type:
			total_bonus += float(skill.get("bonus_value", 0.0))

	return total_bonus


func get_ability_rank(ability_id: String) -> int:
	var rank: int = 0
	for skill: Dictionary in AbilityConfig.SKILL_DEFINITIONS:
		if String(skill.get("ability_id", "")) != ability_id:
			continue
		if is_ability_skill_purchased(String(skill.get("id", ""))):
			rank += 1
	return clampi(rank, 0, ability_max_rank)


func _sync_ability_rank_fields() -> void:
	autoclick_rank = get_ability_rank("autoclick")
	gold_bonus_rank = get_ability_rank("gold_bonus")
	focus_burst_rank = get_ability_rank("focus_burst")
	rally_rank = get_ability_rank("rally")


func is_ability_purchased(ability_id: String) -> bool:
	match ability_id:
		"autoclick": return autoclick_purchased
		"gold_bonus": return gold_bonus_purchased
		"focus_burst": return focus_burst_purchased
		"rally": return rally_purchased
	return false


func is_ability_unlocked(ability_id: String) -> bool:
	match ability_id:
		"autoclick": return autoclick_unlocked
		"gold_bonus": return gold_bonus_unlocked
		"focus_burst": return focus_burst_unlocked
		"rally": return rally_unlocked
	return false


func get_ability_unlock_level(ability_id: String) -> int:
	match ability_id:
		"autoclick": return autoclick_unlock_level
		"gold_bonus": return gold_bonus_unlock_level
		"focus_burst": return focus_burst_unlock_level
		"rally": return rally_unlock_level
	return 0


func get_ability_unlock_cost(ability_id: String) -> int:
	return _get_ability_base_cost(ability_id)


func can_buy_ability_unlock(ability_id: String) -> bool:
	if is_ability_purchased(ability_id):
		return false
	if not is_ability_unlocked(ability_id):
		return false
	var cost: int = get_ability_unlock_cost(ability_id)
	return cost > 0 and gold >= cost


func buy_ability_unlock(ability_id: String) -> Dictionary:
	if is_ability_purchased(ability_id):
		return _make_purchase_result("Already purchased")
	if not is_ability_unlocked(ability_id):
		return _make_purchase_result("Requires Hero Level %d" % get_ability_unlock_level(ability_id))
	var cost: int = get_ability_unlock_cost(ability_id)
	if cost <= 0 or gold < cost:
		return _make_purchase_result("Not enough gold", true)
	gold -= cost
	match ability_id:
		"autoclick":
			autoclick_purchased = true
		"gold_bonus":
			gold_bonus_purchased = true
		"focus_burst":
			focus_burst_purchased = true
		"rally":
			rally_purchased = true
		_:
			return _make_purchase_result("Invalid ability")
	return _make_purchase_result("%s purchased!" % _get_ability_display_name(ability_id), false, true)


func _get_ability_display_name(ability_id: String) -> String:
	match ability_id:
		"autoclick": return "Autoclick"
		"gold_bonus": return "Gold Bonus"
		"focus_burst": return "Focus Burst"
		"rally": return "Rally"
	return "Ability"


func can_upgrade_ability(ability_id: String) -> bool:
	if not is_ability_purchased(ability_id):
		return can_buy_ability_unlock(ability_id)
	for skill: Dictionary in get_ability_skills(ability_id):
		var skill_id: String = String(skill.get("id", ""))
		if not is_ability_skill_purchased(skill_id):
			return is_ability_skill_unlocked(skill_id)
	return false


func get_ability_upgrade_cost(ability_id: String) -> int:
	if not is_ability_purchased(ability_id):
		return get_ability_unlock_cost(ability_id)
	for skill: Dictionary in get_ability_skills(ability_id):
		var skill_id: String = String(skill.get("id", ""))
		if not is_ability_skill_purchased(skill_id):
			return get_ability_skill_cost(skill_id)
	return 0


func _get_ability_base_cost(ability_id: String) -> int:
	match ability_id:
		"autoclick": return autoclick_purchase_cost
		"gold_bonus": return gold_bonus_purchase_cost
		"focus_burst": return focus_burst_purchase_cost
		"rally": return rally_purchase_cost
	return 0


func buy_or_upgrade_ability(ability_id: String) -> Dictionary:
	if not is_ability_purchased(ability_id):
		return buy_ability_unlock(ability_id)
	var skills: Array[Dictionary] = get_ability_skills(ability_id)
	for skill: Dictionary in skills:
		var skill_id: String = String(skill.get("id", ""))
		if not is_ability_skill_purchased(skill_id):
			return buy_ability_skill(skill_id)
	return _make_purchase_result("Already at max rank")


func get_ability_description(ability_id: String) -> String:
	var rank: int = get_ability_rank(ability_id)
	var purchased: bool = is_ability_purchased(ability_id)
	match ability_id:
		"autoclick":
			var hits: int = roundi(20.0 * (1.0 + 0.15 * rank))
			var dur: int = 15 + 2 * rank
			if not purchased:
				return "Unlock: 20 hits/sec | 15s"
			if rank >= ability_max_rank:
				return "%d hits/sec | %ds" % [hits, dur]
			return "%d hits/sec | %ds | Next: +15%% rate, +2s" % [hits, dur]
		"gold_bonus":
			var mult: float = 2.0 + 0.25 * rank
			if not purchased:
				return "Unlock: x2.00 gold | 45s"
			if rank >= ability_max_rank:
				return "x%.2f gold" % mult
			return "x%.2f gold | Next: x%.2f" % [mult, mult + 0.25]
		"focus_burst":
			var mult: float = 2.0 + 0.25 * rank
			if not purchased:
				return "Unlock: x2.00 damage | 20s"
			if rank >= ability_max_rank:
				return "x%.2f damage" % mult
			return "x%.2f damage | Next: x%.2f" % [mult, mult + 0.25]
		"rally":
			var mult: float = 2.0 + 0.25 * rank
			if not purchased:
				return "Unlock: x2.00 partner DPS | 30s"
			if rank >= ability_max_rank:
				return "x%.2f partner DPS" % mult
			return "x%.2f partner DPS | Next: x%.2f" % [mult, mult + 0.25]
		_:
			return ""


func get_prestige_talent_description(talent_index: int) -> String:
	if talent_index < 0 or talent_index >= PrestigeConfig.TALENT_BONUS_TYPES.size():
		return ""

	var amount: int = prestige_talent_bonus_percent_per_level
	match PrestigeConfig.TALENT_BONUS_TYPES[talent_index]:
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
	return CostCalc.get_hero_level_cost(
		level,
		character_cost_base,
		character_cost_linear,
		character_cost_curve,
		character_cost_power,
		BalanceConfig.MILESTONE_LEVELS,
		milestone_cost_multiplier
	)


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
	return CostCalc.get_partner_cost(
		partner_index,
		count,
		BalanceConfig.PARTNER_BASE_COSTS,
		BalanceConfig.PARTNER_COST_STEPS,
		partner_cost_curve_multiplier,
		partner_cost_power,
		BalanceConfig.MILESTONE_LEVELS,
		milestone_cost_multiplier
	)


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
	return CostCalc.get_building_cost(
		building_index,
		count,
		BalanceConfig.BUILDING_BASE_COSTS,
		BalanceConfig.BUILDING_COST_STEPS
	)


func _reset_partner_state() -> void:
	partner_counts.clear()
	partner_purchase_costs.clear()
	for i in range(BalanceConfig.PARTNER_BASE_COSTS.size()):
		partner_counts.append(0)
		partner_purchase_costs.append(BalanceConfig.PARTNER_BASE_COSTS[i])


func _reset_building_state() -> void:
	building_counts.clear()
	building_purchase_costs.clear()
	for i in range(BalanceConfig.BUILDING_BASE_COSTS.size()):
		building_counts.append(0)
		building_purchase_costs.append(BalanceConfig.BUILDING_BASE_COSTS[i])


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
	_sync_ability_rank_fields()

	if not is_ability_purchased("autoclick"):
		autoclick_active = false

	if not is_ability_purchased("gold_bonus"):
		gold_bonus_active = false

	if not is_ability_purchased("focus_burst"):
		focus_burst_active = false

	if not is_ability_purchased("rally"):
		rally_active = false


func set_auto_stage_advance_enabled(enabled: bool) -> void:
	auto_stage_advance_enabled = enabled


func mark_level_cleared(level: int) -> void:
	cleared_level_ids[level] = true


func is_level_cleared(level: int) -> bool:
	return cleared_level_ids.has(level)


func clear_cleared_levels() -> void:
	cleared_level_ids.clear()


func save_current_level_progress() -> void:
	var progress: int = enemies_required_per_level if is_level_cleared(current_level) else clampi(enemies_defeated_on_level, 0, enemies_required_per_level)
	level_enemy_progress[current_level] = progress


func get_saved_level_progress(level: int) -> int:
	return int(level_enemy_progress.get(level, 0))


func set_saved_level_progress(level: int, progress: int) -> void:
	level_enemy_progress[level] = clampi(progress, 0, enemies_required_per_level)


func clear_level_progress(level: int) -> void:
	level_enemy_progress.erase(level)


func clear_all_level_progress() -> void:
	level_enemy_progress.clear()


func get_latest_available_level() -> int:
	return max_unlocked_level


func enable_auto_stage_advance_and_jump_if_needed() -> Dictionary:
	auto_stage_advance_enabled = true
	if is_level_cleared(current_level) and current_level < max_unlocked_level:
		save_current_level_progress()
		current_level = max_unlocked_level
		setup_current_level()
		if is_level_cleared(current_level):
			enemies_defeated_on_level = enemies_required_per_level
		else:
			enemies_defeated_on_level = get_saved_level_progress(current_level)
		return {
			"moved_to_latest": true,
			"advanced_to_next_level": true,
			"current_level": current_level,
			"status_text": "Auto-transition ON. Moved to level %d." % current_level,
		}
	return {
		"moved_to_latest": false,
		"advanced_to_next_level": false,
		"current_level": current_level,
		"status_text": "Auto-transition ON.",
	}


func fail_boss_level() -> Dictionary:
	if is_boss_level and boss_retry_tokens > 0:
		boss_retry_tokens -= 1
		setup_current_level()
		enemies_defeated_on_level = 0
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
	auto_stage_advance_enabled = false
	setup_current_level()
	if is_level_cleared(current_level):
		enemies_defeated_on_level = enemies_required_per_level
	else:
		enemies_defeated_on_level = get_saved_level_progress(current_level)

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


func can_travel_to_level(level: int) -> bool:
	return level >= 1 and level <= max_unlocked_level


func travel_to_level(level: int) -> Dictionary:
	if not can_travel_to_level(level):
		return _make_purchase_result("Level %d is locked" % level)
	if level < max_unlocked_level:
		auto_stage_advance_enabled = false
	save_current_level_progress()
	current_level = level
	setup_current_level()
	if is_level_cleared(current_level):
		enemies_defeated_on_level = enemies_required_per_level
	else:
		enemies_defeated_on_level = get_saved_level_progress(current_level)
	return {
		"defeated": false,
		"level_up": false,
		"reward_gold": 0,
		"damage_dealt": 0,
		"target_hp_before": target_hp,
		"target_hp_after": target_hp,
		"upgraded": false,
		"not_enough_gold": false,
		"status_text": "Travelled to Level %d" % current_level,
		"zone_changed": false,
		"zone_name": "",
		"travelled": true,
	}


func reset_target() -> void:
	choose_enemy_for_current_level()
	recalculate_level_values()
	target_hp = target_max_hp


func choose_enemy_for_current_level() -> void:
	var zone: Dictionary = ZoneConfig.ZONE_DATA[current_zone_index]
	current_enemy_zone_index = current_zone_index
	if is_boss_level:
		is_elite_enemy = false
		enemy_name = zone.boss
		current_enemy_slot = "boss_01"
		return

	if rng.randf() < get_current_elite_spawn_chance():
		is_elite_enemy = true
		enemy_name = zone.elite_enemy
		current_enemy_slot = "elite_01"
		return

	is_elite_enemy = false
	var enemies: Array = zone.enemies
	if enemies.is_empty():
		enemy_name = "Enemy"
		current_enemy_slot = "enemy_01"
		return

	var enemy_index: int = rng.randi_range(0, enemies.size() - 1)
	enemy_name = enemies[enemy_index]
	current_enemy_slot = "enemy_%02d" % (enemy_index + 1)


func recalculate_level_values() -> void:
	var zone: Dictionary = ZoneConfig.ZONE_DATA[current_zone_index]
	var base_hp: int = get_base_enemy_hp_for_level(current_level)
	var base_reward: int = get_base_enemy_reward_for_level(current_level)
	target_max_hp = EnemyCalc.get_scaled_hp(base_hp, zone.hp_multiplier, is_boss_level, is_elite_enemy, BalanceConfig.BOSS_HP_MULTIPLIER, elite_hp_multiplier)
	reward_gold = EnemyCalc.get_scaled_reward(base_reward, zone.reward_multiplier, is_boss_level, is_elite_enemy, BalanceConfig.BOSS_REWARD_MULTIPLIER, elite_reward_multiplier)


func get_base_enemy_hp_for_level(level: int) -> int:
	return EnemyCalc.get_base_hp(level, enemy_hp_base, enemy_hp_linear, enemy_hp_curve, enemy_hp_power)


func get_base_enemy_reward_for_level(level: int) -> int:
	return EnemyCalc.get_base_reward(level, enemy_reward_base, enemy_reward_linear, enemy_reward_curve, enemy_reward_power)


func get_current_zone_index() -> int:
	return _get_zone_index_for_level(current_level)


func _get_zone_index_for_level(level: int) -> int:
	for i in range(ZoneConfig.ZONE_DATA.size()):
		if level <= ZoneConfig.ZONE_DATA[i].level_end:
			return i
	return ZoneConfig.ZONE_DATA.size() - 1


func _update_zone() -> void:
	var idx: int = _get_zone_index_for_level(current_level)
	var zone: Dictionary = ZoneConfig.ZONE_DATA[idx]
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
			* get_partner_skill_bonus_multiplier("click_damage")
			* get_hero_skill_bonus_multiplier("click_damage")
			* get_partner_skill_bonus_multiplier("all_damage")
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


func get_current_elite_spawn_chance() -> float:
	return clampf(elite_spawn_chance + get_partner_skill_additive_bonus("elite_spawn"), 0.0, 1.0)


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


func get_save_data() -> Dictionary:
	return SaveAdapter.build_save_data(self)


func apply_save_data(data: Dictionary) -> bool:
	return SaveAdapter.apply_save_data(self, data)


func reset_to_new_game() -> void:
	gold = 0
	gems = 0
	sound_enabled = true
	music_enabled = true
	character_level = 1
	current_level = 1
	max_unlocked_level = 1
	enemies_defeated_on_level = 0
	cleared_level_ids.clear()
	level_enemy_progress.clear()
	auto_stage_advance_enabled = true
	autoclick_purchased = false
	gold_bonus_purchased = false
	focus_burst_purchased = false
	rally_purchased = false
	autoclick_rank = 0
	gold_bonus_rank = 0
	focus_burst_rank = 0
	rally_rank = 0
	autoclick_active = false
	gold_bonus_active = false
	focus_burst_active = false
	rally_active = false
	purchased_partner_skill_ids.clear()
	purchased_hero_skill_ids.clear()
	purchased_ability_skill_ids.clear()
	prestige_points_available = 0
	prestige_points_total_earned = 0
	total_prestiges = 0
	for i in range(prestige_talent_levels.size()):
		prestige_talent_levels[i] = 0
	boss_retry_tokens = 0
	task_reward_boost_multiplier = 1.0
	total_manual_click_damage_dealt = 0
	total_enemies_defeated = 0
	total_elite_enemies_defeated = 0
	total_bosses_defeated = 0
	total_autoclick_activations = 0
	total_combo_empowered_activations = 0
	_reset_partner_state()
	_reset_building_state()
	initialize_tasks()
	recalculate_character_level_cost()
	_update_character_state()
	setup_current_level()
