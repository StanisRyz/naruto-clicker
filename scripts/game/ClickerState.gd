class_name ClickerState
extends RefCounted

const SaveAdapter = preload("res://scripts/game/save/ClickerStateSaveAdapter.gd")
const MilestoneCalc = preload("res://scripts/game/calculators/MilestoneCalculator.gd")
const CostCalc = preload("res://scripts/game/calculators/CostCalculator.gd")
const EnemyCalc = preload("res://scripts/game/calculators/EnemyScalingCalculator.gd")
const Presentation = preload("res://scripts/game/presentation/ClickerStatePresentation.gd")
const TaskRT = preload("res://scripts/game/runtime/TaskRuntime.gd")
const ShopRT = preload("res://scripts/game/runtime/ShopRuntime.gd")


var gold: int = 0
var gems: int = 0
var click_damage: int = 1
var character_level: int = 1
var character_level_upgrade_cost: int = 5
var current_level: int = 1
var max_unlocked_level: int = 1
var auto_stage_advance_enabled: bool =	 true
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
var enemy_name_key: String = ""
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
const INITIAL_VISIBLE_PARTNER_COUNT: int = 2
var visible_partner_count: int = INITIAL_VISIBLE_PARTNER_COUNT
var purchased_partner_skill_ids: Array[String] = []
var purchased_hero_skill_ids: Array[String] = []
var purchased_ability_skill_ids: Array[String] = []
var milestone_multiplier_per_reached: int = BalanceConfig.MILESTONE_MULTIPLIER_PER_REACHED
var milestone_cost_multiplier: int = BalanceConfig.MILESTONE_COST_MULTIPLIER
var building_counts: Array[int] = []
var building_bonus_percent_per_level: int = BalanceConfig.BUILDING_BONUS_PERCENT_PER_LEVEL
var building_purchase_costs: Array[int] = []
var boss_retry_tokens: int = 0
var task_reward_boost_multiplier: float = 1.0

var shop_permanent_partner_dps_x2_count: int = 0
var shop_permanent_click_damage_x2_count: int = 0
var shop_permanent_gold_x2_count: int = 0

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
var language: String = "en"

var prestige_points_available: int = 0
var prestige_points_total_earned: int = 0
var total_prestiges: int = 0
var prestige_required_level: int = BalanceConfig.PRESTIGE_REQUIRED_LEVEL
var prestige_talent_levels: Array[int] = [0, 0, 0, 0, 0, 0]
var active_task_ids: Array[String] = []
var inactive_task_ids: Array[String] = []
var active_task_states: Dictionary = {}
var total_manual_click_damage_dealt: int = 0
var total_enemies_defeated: int = 0
var total_elite_enemies_defeated: int = 0
var total_bosses_defeated: int = 0
var total_autoclick_activations: int = 0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var debug_visual_test_mode_enabled: bool = false
const DEBUG_VISUAL_TEST_HP: int = 100000
const DEBUG_PURCHASE_COST: int = 1
const DEBUG_PURCHASE_MAX_BULK: int = 100
const DEBUG_PRESTIGE_REWARD: int = 999

var last_save_unix_time: int = 0
var pending_offline_gold_reward: int = 0
var pending_offline_elapsed_seconds: int = 0

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
	if is_debug_visual_test_mode_enabled():
		return true
	return get_prestige_reward() > 0


func get_prestige_stage_points() -> int:
	return int(current_level / float(prestige_required_level))


func get_prestige_character_points() -> int:
	return int(character_level / BalanceConfig.PRESTIGE_CHARACTER_INTERVAL)


func get_prestige_reward() -> int:
	if is_debug_visual_test_mode_enabled():
		return DEBUG_PRESTIGE_REWARD
	var progression_points: int = get_prestige_stage_points() + get_prestige_character_points()
	if progression_points <= 0:
		return 0
	return BalanceConfig.PRESTIGE_BASE_REWARD_POINTS + progression_points


func initialize_tasks() -> void:
	TaskRT.initialize_tasks(self)


func get_task_definition(task_id: String) -> Dictionary:
	return TaskConfig.get_by_id(task_id)


func get_task_progress(task_id: String) -> int:
	return TaskRT.get_task_progress(self, task_id)


func get_task_target(task_id: String) -> int:
	return TaskRT.get_task_target(self, task_id)


func get_current_task_reward_unit() -> int:
	return TaskRT.get_current_task_reward_unit(self)


func get_task_reward_gold(task_id: String) -> int:
	return TaskRT.get_task_reward_gold(self, task_id)


func is_task_completed(task_id: String) -> bool:
	return TaskRT.is_task_completed(self, task_id)


func has_claimable_tasks() -> bool:
	for task_id in active_task_ids:
		if is_task_completed(task_id):
			return true
	return false


func get_active_task_view_data() -> Array[Dictionary]:
	return Presentation.get_active_task_view_data(self)


func claim_task_reward(task_id: String) -> Dictionary:
	return TaskRT.claim_task_reward(self, task_id)


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
	return get_prestige_talent_total_bonus_percent(0)


func get_trade_routes_bonus_percent() -> int:
	return get_prestige_talent_total_bonus_percent(1)


func get_command_aura_bonus_percent() -> int:
	return get_prestige_talent_total_bonus_percent(2)


func get_quick_hands_bonus_percent() -> int:
	return get_prestige_talent_total_bonus_percent(3)


func get_builder_wisdom_bonus_percent() -> int:
	return get_prestige_talent_total_bonus_percent(4)


func get_boss_hunter_bonus_percent() -> int:
	return get_prestige_talent_total_bonus_percent(5)


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
	return BalanceConfig.ABILITY_BASE_MULTIPLIER + BalanceConfig.ABILITY_RANK_MULTIPLIER_STEP * rank if focus_burst_active and is_ability_purchased("focus_burst") else 1.0


func get_rally_multiplier() -> float:
	var rank: int = get_ability_rank("rally")
	return BalanceConfig.ABILITY_BASE_MULTIPLIER + BalanceConfig.ABILITY_RANK_MULTIPLIER_STEP * rank if rally_active and is_ability_purchased("rally") else 1.0


func get_gold_bonus_multiplier() -> float:
	var rank: int = get_ability_rank("gold_bonus")
	return BalanceConfig.ABILITY_BASE_MULTIPLIER + BalanceConfig.ABILITY_RANK_MULTIPLIER_STEP * rank if gold_bonus_active and is_ability_purchased("gold_bonus") else 1.0


func get_autoclick_rank_rate_multiplier() -> float:
	var rank: int = get_ability_rank("autoclick")
	return 1.0 + BalanceConfig.AUTOCLICK_RANK_RATE_STEP * rank


func get_boss_damage_multiplier() -> float:
	return get_boss_hunter_multiplier() if is_boss_level else 1.0


func get_current_enemy_type() -> String:
	if is_boss_level:
		return "boss"

	return "elite" if is_elite_enemy else "normal"


func get_prestige_talent_cost_for_level(level: int) -> int:
	var safe_level: int = maxi(level, 0)
	return maxi(
		BalanceConfig.PRESTIGE_TALENT_BASE_COST,
		ceili(
			float(BalanceConfig.PRESTIGE_TALENT_BASE_COST)
			* pow(BalanceConfig.PRESTIGE_TALENT_COST_GROWTH, float(safe_level))
		)
	)


func get_prestige_talent_cost(talent_index: int) -> int:
	if talent_index < 0 or talent_index >= prestige_talent_levels.size():
		return 0
	return get_prestige_talent_cost_for_level(prestige_talent_levels[talent_index])


func get_prestige_talent_bulk_cost_for_count(talent_index: int, count: int) -> int:
	if talent_index < 0 or talent_index >= prestige_talent_levels.size():
		return 0
	var simulated_level: int = prestige_talent_levels[talent_index]
	var total_cost: int = 0
	for i in range(count):
		total_cost += get_prestige_talent_cost_for_level(simulated_level)
		simulated_level += 1
	return total_cost


func get_prestige_talent_bulk_count(talent_index: int, mode: String) -> int:
	if talent_index < 0 or talent_index >= prestige_talent_levels.size():
		return 0

	var fixed_count: int = _get_fixed_buy_count(mode)
	if fixed_count > 0:
		var fixed_cost: int = get_prestige_talent_bulk_cost_for_count(talent_index, fixed_count)
		return fixed_count if prestige_points_available >= fixed_cost else 0

	var simulated_points: int = prestige_points_available
	var simulated_level: int = prestige_talent_levels[talent_index]
	var count: int = 0

	while simulated_points >= get_prestige_talent_cost_for_level(simulated_level):
		simulated_points -= get_prestige_talent_cost_for_level(simulated_level)
		simulated_level += 1
		count += 1

	return count


func get_prestige_talent_bulk_cost(talent_index: int, mode: String) -> int:
	var count: int = get_prestige_talent_bulk_count(talent_index, mode)
	if count <= 0:
		return 0
	return get_prestige_talent_bulk_cost_for_count(talent_index, count)


func can_afford_prestige_talent_bulk(talent_index: int, mode: String) -> bool:
	return get_prestige_talent_bulk_count(talent_index, mode) > 0


func get_prestige_talent_bulk_display_count(talent_index: int, mode: String) -> int:
	if talent_index < 0 or talent_index >= prestige_talent_levels.size():
		return 0
	if mode == "max":
		return get_prestige_talent_bulk_count(talent_index, mode)
	return _get_fixed_buy_count(mode)


func get_prestige_talent_bulk_display_cost(talent_index: int, mode: String) -> int:
	var display_count: int = get_prestige_talent_bulk_display_count(talent_index, mode)
	if display_count > 0:
		return get_prestige_talent_bulk_cost_for_count(talent_index, display_count)
	return get_prestige_talent_cost(talent_index)


func get_prestige_talent_bonus_percent_per_level(talent_index: int) -> int:
	match PrestigeConfig.get_effect_type(talent_index):
		"damage", "click_damage", "partner_dps", "boss_damage", "all_damage":
			return BalanceConfig.PRESTIGE_DAMAGE_TALENT_BONUS_PERCENT_PER_LEVEL
		"gold", "gold_reward", "gold_income":
			return BalanceConfig.PRESTIGE_GOLD_TALENT_BONUS_PERCENT_PER_LEVEL
		_:
			return BalanceConfig.PRESTIGE_UTILITY_TALENT_BONUS_PERCENT_PER_LEVEL


func get_prestige_talent_bonus_percent_for_level(talent_index: int, level: int) -> int:
	return maxi(level, 0) * get_prestige_talent_bonus_percent_per_level(talent_index)


func get_prestige_talent_total_bonus_percent(talent_index: int) -> int:
	if talent_index < 0 or talent_index >= prestige_talent_levels.size():
		return 0
	return get_prestige_talent_bonus_percent_for_level(talent_index, prestige_talent_levels[talent_index])


func get_prestige_talent_bulk_bonus_gain(talent_index: int, mode: String) -> int:
	if talent_index < 0 or talent_index >= prestige_talent_levels.size():
		return 0
	var count: int = get_prestige_talent_bulk_display_count(talent_index, mode)
	if count <= 0:
		return 0
	var talent_level: int = prestige_talent_levels[talent_index]
	var current_bonus: int = get_prestige_talent_bonus_percent_for_level(talent_index, talent_level)
	var future_bonus: int = get_prestige_talent_bonus_percent_for_level(talent_index, talent_level + count)
	return maxi(future_bonus - current_bonus, 0)


func get_prestige_talent_display_total_bonus_percent(talent_index: int) -> int:
	return get_prestige_talent_total_bonus_percent(talent_index)


func get_prestige_talent_display_bulk_bonus_gain(talent_index: int, mode: String) -> int:
	return get_prestige_talent_bulk_bonus_gain(talent_index, mode)


func buy_prestige_talents(talent_index: int, mode: String) -> Dictionary:
	if talent_index < 0 or talent_index >= prestige_talent_levels.size():
		return _make_purchase_result("Invalid prestige talent")

	var bought: int = get_prestige_talent_bulk_count(talent_index, mode)
	var total_cost: int = get_prestige_talent_bulk_cost(talent_index, mode)

	if bought <= 0 or total_cost <= 0 or prestige_points_available < total_cost:
		return _make_purchase_result("Not enough Prestige Points")

	prestige_points_available -= total_cost
	prestige_talent_levels[talent_index] += bought
	_update_character_state()
	return _make_purchase_result("Prestige talent upgraded x%d!" % bought, false, true)


func buy_prestige_talent(talent_index: int) -> Dictionary:
	return buy_prestige_talents(talent_index, "x1")


func add_gems(amount: int) -> void:
	ShopRT.add_gems(self, amount)


func get_shop_product(product_id: String) -> Dictionary:
	return ShopRT.get_shop_product(product_id)


func get_shop_permanent_upgrade_count(product_id: String) -> int:
	match product_id:
		"permanent_partner_dps_x2":
			return shop_permanent_partner_dps_x2_count
		"permanent_click_damage_x2":
			return shop_permanent_click_damage_x2_count
		"permanent_gold_x2":
			return shop_permanent_gold_x2_count
	return 0


func _set_shop_permanent_upgrade_count(product_id: String, value: int) -> void:
	var safe_value: int = maxi(0, value)
	match product_id:
		"permanent_partner_dps_x2":
			shop_permanent_partner_dps_x2_count = safe_value
		"permanent_click_damage_x2":
			shop_permanent_click_damage_x2_count = safe_value
		"permanent_gold_x2":
			shop_permanent_gold_x2_count = safe_value


func get_shop_partner_dps_multiplier() -> float:
	return pow(ShopConfig.PERMANENT_UPGRADE_MULTIPLIER_PER_LEVEL, float(shop_permanent_partner_dps_x2_count))


func get_shop_click_damage_multiplier() -> float:
	return pow(ShopConfig.PERMANENT_UPGRADE_MULTIPLIER_PER_LEVEL, float(shop_permanent_click_damage_x2_count))


func get_shop_gold_multiplier() -> float:
	return pow(ShopConfig.PERMANENT_UPGRADE_MULTIPLIER_PER_LEVEL, float(shop_permanent_gold_x2_count))


func get_shop_product_view_data(mode: String = "x1") -> Array[Dictionary]:
	return Presentation.get_shop_product_view_data(self, mode)


func buy_shop_products(product_id: String, mode: String = "x1") -> Dictionary:
	return ShopRT.buy_shop_products(self, product_id, mode)


func buy_shop_product(product_id: String) -> Dictionary:
	return buy_shop_products(product_id, "x1")


func perform_prestige() -> Dictionary:
	var reward: int = get_prestige_reward()
	if reward <= 0:
		return _make_purchase_result(
			"Prestige requires stage level %d or character level %d" % [
				prestige_required_level,
				int(BalanceConfig.PRESTIGE_CHARACTER_INTERVAL),
			]
		)

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


func get_current_target_reward_gold_preview() -> int:
	if target_hp > 0:
		return 0
	var source_reward: int = reward_gold
	if is_boss_level:
		source_reward = int(source_reward * get_boss_reward_multiplier())
	if is_elite_enemy:
		source_reward = int(source_reward * get_partner_skill_bonus_multiplier("elite_reward"))
	var talent_gold: int = int(
		source_reward
		* get_trade_routes_multiplier()
		* get_partner_skill_gold_multiplier()
		* get_hero_skill_bonus_multiplier("gold")
	)
	var settlement_gold: int = int(talent_gold * get_settlement_gold_multiplier())
	var pre_shop_gold: int = int(settlement_gold * get_gold_bonus_multiplier()) if gold_bonus_active else settlement_gold
	return int(pre_shop_gold * get_shop_gold_multiplier())


func resolve_defeated_target() -> Dictionary:
	if target_hp > 0:
		return _make_attack_result(false, false, 0, 0, target_hp, target_hp, "")

	var target_hp_before: int = target_hp
	var damage_dealt: int = 0
	var defeated_boss: bool = is_boss_level
	var defeated_elite: bool = is_elite_enemy
	var earned_gold: int = get_current_target_reward_gold_preview()
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
	if is_debug_purchase_override_enabled():
		if mode == "max":
			return DEBUG_PURCHASE_MAX_BULK if gold >= DEBUG_PURCHASE_COST else 0
		var dbg_fixed: int = _get_fixed_buy_count(mode)
		return dbg_fixed if gold >= DEBUG_PURCHASE_COST else 0

	var fixed_count: int = _get_fixed_buy_count(mode)
	if fixed_count > 0:
		var fixed_cost: int = _get_character_level_bulk_cost_for_count(fixed_count)
		return fixed_count if gold >= fixed_cost else 0

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

	if is_debug_purchase_override_enabled():
		return DEBUG_PURCHASE_COST

	return _get_character_level_bulk_cost_for_count(count)


func can_afford_character_level_bulk(mode: String) -> bool:
	return get_character_level_bulk_count(mode) > 0


func get_character_level_bulk_display_count(mode: String) -> int:
	if mode == "max":
		return get_character_level_bulk_count(mode)

	return _get_fixed_buy_count(mode)


func get_character_level_bulk_display_cost(mode: String) -> int:
	if is_debug_purchase_override_enabled():
		return DEBUG_PURCHASE_COST

	var display_count: int = get_character_level_bulk_display_count(mode)
	if display_count > 0:
		return _get_character_level_bulk_cost_for_count(display_count)

	return character_level_upgrade_cost


func get_partner_dps_click_damage_bonus_percent() -> float:
	var total_bonus: float = 0.0
	for skill: Dictionary in PartnerSkillConfig.SKILL_DEFINITIONS:
		var skill_id: String = String(skill.get("id", ""))
		if not is_partner_skill_purchased(skill_id):
			continue
		if String(skill.get("bonus_type", "")) == "click_damage_from_partner_dps":
			total_bonus += float(skill.get("bonus_value", 0.0))
	return total_bonus


func get_partner_dps_click_damage_bonus() -> int:
	var bonus_percent: float = get_partner_dps_click_damage_bonus_percent()
	if bonus_percent <= 0.0:
		return 0
	var partner_dps_for_click_bonus: int = get_final_partner_dps(false)
	return maxi(0, int(float(partner_dps_for_click_bonus) * bonus_percent))


func get_click_damage_for_character_level(level: int) -> int:
	var base_damage: int = int(BalanceConfig.HERO_BASE_DAMAGE + float(level) * BalanceConfig.HERO_DAMAGE_PER_LEVEL) * get_milestone_multiplier(level)
	var hero_click_damage: int = maxi(
		1,
		int(
			base_damage
			* get_focus_training_multiplier()
			* get_partner_skill_bonus_multiplier("click_damage")
			* get_hero_skill_bonus_multiplier("click_damage")
			* get_partner_skill_bonus_multiplier("all_damage")
			* get_focus_burst_multiplier()
			* get_settlement_click_damage_multiplier()
			* get_shop_click_damage_multiplier()
		)
	)
	var partner_dps_click_bonus: int = get_partner_dps_click_damage_bonus()
	return maxi(1, hero_click_damage + partner_dps_click_bonus)


func get_character_level_bulk_damage_gain(mode: String) -> int:
	var count: int = get_character_level_bulk_display_count(mode)
	if count <= 0:
		return 0
	var future_damage: int = get_click_damage_for_character_level(character_level + count)
	return maxi(future_damage - click_damage, 0)


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
		* get_shop_partner_dps_multiplier()
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

	var bought: int = get_partner_bulk_count(partner_index, mode)
	var total_cost: int = get_partner_bulk_cost(partner_index, mode)

	if bought <= 0 or total_cost <= 0 or gold < total_cost:
		return _make_purchase_result("Not enough gold", true)

	gold -= total_cost
	partner_counts[partner_index] += bought
	recalculate_partner_cost(partner_index)
	_update_character_state()
	refresh_partner_visibility_unlocks()
	return _make_purchase_result("%s hired x%d!" % [PartnerConfig.PARTNER_NAMES[partner_index], bought], false, true)


func get_partner_bulk_count(partner_index: int, mode: String) -> int:
	if partner_index < 0 or partner_index >= partner_counts.size():
		return 0

	if is_debug_purchase_override_enabled():
		if mode == "max":
			return DEBUG_PURCHASE_MAX_BULK if gold >= DEBUG_PURCHASE_COST else 0
		var dbg_fixed: int = _get_fixed_buy_count(mode)
		return dbg_fixed if gold >= DEBUG_PURCHASE_COST else 0

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

	if is_debug_purchase_override_enabled():
		return DEBUG_PURCHASE_COST

	return _get_partner_bulk_cost_for_count(partner_index, count)


func get_partner_bulk_display_count(partner_index: int, mode: String) -> int:
	if partner_index < 0 or partner_index >= partner_counts.size():
		return 0

	if mode == "max":
		return get_partner_bulk_count(partner_index, mode)

	return _get_fixed_buy_count(mode)


func get_partner_bulk_display_cost(partner_index: int, mode: String) -> int:
	if partner_index < 0 or partner_index >= partner_counts.size():
		return 0

	if is_debug_purchase_override_enabled():
		return DEBUG_PURCHASE_COST

	var display_count: int = get_partner_bulk_display_count(partner_index, mode)
	if display_count > 0:
		return _get_partner_bulk_cost_for_count(partner_index, display_count)

	return partner_purchase_costs[partner_index]


func can_buy_building(building_index: int) -> bool:
	return building_index >= 0 and building_index < building_counts.size()


func buy_building(building_index: int) -> Dictionary:
	return buy_buildings(building_index, "x1")


func buy_buildings(building_index: int, mode: String) -> Dictionary:
	if building_index < 0 or building_index >= building_counts.size():
		return _make_purchase_result("Invalid building")

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

	if is_debug_purchase_override_enabled():
		if mode == "max":
			return DEBUG_PURCHASE_MAX_BULK if gold >= DEBUG_PURCHASE_COST else 0
		var dbg_fixed: int = _get_fixed_buy_count(mode)
		return dbg_fixed if gold >= DEBUG_PURCHASE_COST else 0

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

	if is_debug_purchase_override_enabled():
		return DEBUG_PURCHASE_COST

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

	if is_debug_purchase_override_enabled():
		return DEBUG_PURCHASE_COST

	var display_count: int = get_building_bulk_display_count(building_index, mode)
	if display_count > 0:
		return _get_building_bulk_cost_for_count(building_index, display_count)

	return building_purchase_costs[building_index]


func get_building_effect_description(building_index: int) -> String:
	return Presentation.get_building_short_effect_description(self, building_index)


func get_building_short_effect_description(building_index: int) -> String:
	return Presentation.get_building_short_effect_description(self, building_index)


func get_partner_description(partner_index: int) -> String:
	return Presentation.get_partner_description(partner_index)


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
	if is_debug_purchase_override_enabled():
		return true
	return character_level >= int(skill.get("unlock_character_level", 0))


func is_hero_skill_purchased(skill_id: String) -> bool:
	return purchased_hero_skill_ids.has(skill_id)


func can_buy_hero_skill(skill_id: String) -> bool:
	if is_hero_skill_purchased(skill_id) or not is_hero_skill_unlocked(skill_id):
		return false
	var cost: int = get_hero_skill_cost(skill_id)
	return cost > 0 and gold >= cost


func get_hero_skill_state(skill_id: String) -> String:
	return Presentation.get_hero_skill_state(self, skill_id)


func get_hero_skill_cost(skill_id: String) -> int:
	var skill: Dictionary = get_hero_skill(skill_id)
	if skill.is_empty():
		return 0
	if is_debug_purchase_override_enabled():
		return DEBUG_PURCHASE_COST
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
	if is_debug_purchase_override_enabled():
		return true
	return character_level >= int(skill.get("unlock_character_level", 0)) and is_ability_purchased(String(skill.get("ability_id", "")))


func is_ability_skill_purchased(skill_id: String) -> bool:
	return purchased_ability_skill_ids.has(skill_id)


func can_buy_ability_skill(skill_id: String) -> bool:
	if is_ability_skill_purchased(skill_id) or not is_ability_skill_unlocked(skill_id):
		return false
	var cost: int = get_ability_skill_cost(skill_id)
	return cost > 0 and gold >= cost


func get_ability_skill_state(skill_id: String) -> String:
	return Presentation.get_ability_skill_state(self, skill_id)


func get_ability_skill_cost(skill_id: String) -> int:
	var skill: Dictionary = get_ability_skill(skill_id)
	if skill.is_empty():
		return 0
	if is_debug_purchase_override_enabled():
		return DEBUG_PURCHASE_COST
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
	if not is_debug_purchase_override_enabled() and not is_ability_purchased(ability_id):
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

	if is_debug_purchase_override_enabled():
		return DEBUG_PURCHASE_COST

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

	if is_debug_purchase_override_enabled():
		return true

	return partner_counts[partner_index] >= int(skill.get("unlock_count", 0))


func is_partner_skill_purchased(skill_id: String) -> bool:
	return purchased_partner_skill_ids.has(skill_id)


func can_buy_partner_skill(skill_id: String) -> bool:
	if is_partner_skill_purchased(skill_id) or not is_partner_skill_unlocked(skill_id):
		return false

	var cost: int = get_partner_skill_cost(skill_id)
	return cost > 0 and gold >= cost


func get_partner_skill_state(skill_id: String) -> String:
	return Presentation.get_partner_skill_state(self, skill_id)


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


func get_partner_tier_total_dps_for_count(partner_index: int, count: int) -> int:
	if partner_index < 0 or partner_index >= BalanceConfig.PARTNER_DPS_VALUES.size():
		return 0
	return int(
		count
		* BalanceConfig.PARTNER_DPS_VALUES[partner_index]
		* get_milestone_multiplier(count)
		* get_own_partner_skill_multiplier(partner_index)
	)


func get_partner_bulk_dps_gain(partner_index: int, mode: String) -> int:
	var count: int = get_partner_bulk_display_count(partner_index, mode)
	if count <= 0:
		return 0
	var current_dps: int = get_partner_tier_total_dps(partner_index)
	var future_dps: int = get_partner_tier_total_dps_for_count(partner_index, partner_counts[partner_index] + count)
	return maxi(future_dps - current_dps, 0)


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
	if is_debug_purchase_override_enabled():
		return true
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
	if is_debug_purchase_override_enabled():
		return DEBUG_PURCHASE_COST
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
	return Presentation.get_ability_description(self, ability_id)


func get_prestige_talent_description(talent_index: int) -> String:
	return Presentation.get_prestige_talent_description(self, talent_index)


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


func get_building_bonus_percent_for_count(building_index: int, count: int) -> int:
	if building_index < 0 or building_index >= building_counts.size():
		return 0
	if count <= 0:
		return 0
	var base_bonus: int = count * building_bonus_percent_per_level
	var milestone_bonus: int = base_bonus * get_milestone_multiplier(count)
	return int(milestone_bonus * get_settlement_effectiveness_multiplier())


func get_building_raw_bonus_percent(building_index: int) -> int:
	if building_index < 0 or building_index >= building_counts.size():
		return 0
	return get_building_bonus_percent_for_count(building_index, building_counts[building_index])


func get_building_total_bonus_percent(building_index: int) -> int:
	if building_index < 0 or building_index >= building_counts.size():
		return 0
	return get_building_bonus_percent_for_count(building_index, building_counts[building_index])


func get_building_bulk_bonus_gain(building_index: int, mode: String) -> int:
	if building_index < 0 or building_index >= building_counts.size():
		return 0
	var count: int = get_building_bulk_display_count(building_index, mode)
	if count <= 0:
		return 0
	var current_bonus: int = get_building_bonus_percent_for_count(building_index, building_counts[building_index])
	var future_bonus: int = get_building_bonus_percent_for_count(building_index, building_counts[building_index] + count)
	return maxi(future_bonus - current_bonus, 0)


func get_building_display_bonus_percent_for_count(building_index: int, count: int) -> int:
	if building_index < 0 or building_index >= building_counts.size():
		return 0
	if count <= 0:
		return 0
	var base_bonus: int = count * building_bonus_percent_per_level
	var milestone_bonus: int = base_bonus * get_milestone_multiplier(count)
	var effective_raw_bonus: int = int(milestone_bonus * get_settlement_effectiveness_multiplier())
	if SettlementConfig.get_bonus_type(building_index) == "ability_cooldown":
		return int((1.0 - get_diminishing_reduction_multiplier(effective_raw_bonus)) * 100.0)
	return effective_raw_bonus


func get_building_display_total_bonus_percent(building_index: int) -> int:
	if building_index < 0 or building_index >= building_counts.size():
		return 0
	return get_building_display_bonus_percent_for_count(building_index, building_counts[building_index])


func get_building_display_bulk_bonus_gain(building_index: int, mode: String) -> int:
	if building_index < 0 or building_index >= building_counts.size():
		return 0
	var count: int = get_building_bulk_display_count(building_index, mode)
	if count <= 0:
		return 0
	var current_count: int = building_counts[building_index]
	var current_bonus: int = get_building_display_bonus_percent_for_count(building_index, current_count)
	var future_bonus: int = get_building_display_bonus_percent_for_count(building_index, current_count + count)
	return maxi(future_bonus - current_bonus, 0)


func can_afford_building_bulk(building_index: int, mode: String) -> bool:
	return get_building_bulk_count(building_index, mode) > 0


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


func is_partner_index_valid(partner_index: int) -> bool:
	return partner_index >= 0 and partner_index < partner_counts.size()


func can_buy_partner(partner_index: int) -> bool:
	return is_partner_index_valid(partner_index)


func is_partner_visible(partner_index: int) -> bool:
	if is_debug_purchase_override_enabled():
		return is_partner_index_valid(partner_index)
	return is_partner_index_valid(partner_index) and partner_index < visible_partner_count


func get_partner_visibility_unlock_cost(partner_index: int) -> int:
	if not is_partner_index_valid(partner_index):
		return 0
	return partner_purchase_costs[partner_index]


func refresh_partner_visibility_unlocks() -> void:
	if is_debug_purchase_override_enabled():
		visible_partner_count = partner_counts.size()
		return

	visible_partner_count = clampi(
		maxi(visible_partner_count, INITIAL_VISIBLE_PARTNER_COUNT),
		0,
		partner_counts.size()
	)

	while visible_partner_count < partner_counts.size():
		var last_visible_index: int = visible_partner_count - 1
		var unlock_cost: int = get_partner_visibility_unlock_cost(last_visible_index)
		if unlock_cost <= 0:
			break
		if gold < unlock_cost:
			break
		visible_partner_count += 1


func can_afford_partner_bulk(partner_index: int, mode: String) -> bool:
	return get_partner_bulk_count(partner_index, mode) > 0


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
		BalanceConfig.HERO_BASE_COST,
		BalanceConfig.HERO_COST_GROWTH_EARLY,
		BalanceConfig.HERO_COST_GROWTH_MID,
		BalanceConfig.HERO_COST_GROWTH_LATE,
		BalanceConfig.HERO_COST_MID_START_LEVEL,
		BalanceConfig.HERO_COST_LATE_START_LEVEL,
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
		BalanceConfig.PARTNER_COST_GROWTH_EARLY,
		BalanceConfig.PARTNER_COST_GROWTH_MID,
		BalanceConfig.PARTNER_COST_GROWTH_LATE,
		BalanceConfig.PARTNER_COST_MID_START_COUNT,
		BalanceConfig.PARTNER_COST_LATE_START_COUNT,
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
		BalanceConfig.BUILDING_COST_GROWTH
	)


func _reset_partner_state() -> void:
	partner_counts.clear()
	partner_purchase_costs.clear()
	visible_partner_count = INITIAL_VISIBLE_PARTNER_COUNT
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
	return current_level % ZoneConfig.BOSS_LEVEL_INTERVAL == 0


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
	_apply_debug_visual_test_hp_to_current_target()


func choose_enemy_for_current_level() -> void:
	var zone: Dictionary = ZoneConfig.ZONE_DATA[current_zone_index]
	if is_boss_level:
		is_elite_enemy = false
		enemy_name = zone.boss
		enemy_name_key = ZoneConfig.get_boss_key(current_zone_index)
		current_enemy_slot = "boss_01"
		current_enemy_zone_index = current_zone_index
		return

	current_enemy_zone_index = EnemyPoolConfig.get_pool_zone_index_for_level(current_level)

	if rng.randf() < get_current_elite_spawn_chance():
		is_elite_enemy = true
		var elite_candidate: Dictionary = EnemyPoolConfig.get_random_elite_candidate(current_level, rng)
		enemy_name = String(elite_candidate.get("name", "Elite Enemy"))
		enemy_name_key = String(elite_candidate.get("name_key", ""))
		current_enemy_slot = String(elite_candidate.get("slot", "elite_01"))
		return

	is_elite_enemy = false
	var normal_candidate: Dictionary = EnemyPoolConfig.get_random_normal_candidate(current_level, rng)
	enemy_name = String(normal_candidate.get("name", "Enemy"))
	enemy_name_key = String(normal_candidate.get("name_key", ""))
	current_enemy_slot = String(normal_candidate.get("slot", "enemy_01"))


func recalculate_level_values() -> void:
	var base_hp: int = get_base_enemy_hp_for_level(current_level)
	var base_reward: int = get_base_enemy_reward_for_level(current_level)
	var hp_multiplier: float = ZoneConfig.get_effective_hp_multiplier_for_level(
		current_level, BalanceConfig.ZONE_CYCLE_HP_MULTIPLIER
	)
	var reward_multiplier: float = ZoneConfig.get_effective_reward_multiplier_for_level(
		current_level, BalanceConfig.ZONE_CYCLE_REWARD_MULTIPLIER
	)
	target_max_hp = EnemyCalc.get_scaled_hp(base_hp, hp_multiplier, is_boss_level, is_elite_enemy, BalanceConfig.BOSS_HP_MULTIPLIER, elite_hp_multiplier)
	reward_gold = EnemyCalc.get_scaled_reward(base_reward, reward_multiplier, is_boss_level, is_elite_enemy, BalanceConfig.BOSS_REWARD_MULTIPLIER, elite_reward_multiplier)


func get_base_enemy_hp_for_level(level: int) -> int:
	return EnemyCalc.get_base_hp(level, BalanceConfig.ENEMY_HP_BASE, BalanceConfig.ENEMY_HP_GROWTH)


func get_base_enemy_reward_for_level(level: int) -> int:
	return EnemyCalc.get_base_reward(level, BalanceConfig.ENEMY_REWARD_BASE, BalanceConfig.ENEMY_REWARD_GROWTH)


func get_current_zone_index() -> int:
	return _get_zone_index_for_level(current_level)


func get_current_background_zone_index() -> int:
	return ZoneConfig.get_background_asset_zone_index_for_level(current_level)


func set_debug_visual_test_mode_enabled(enabled: bool) -> void:
	debug_visual_test_mode_enabled = enabled
	setup_current_level()
	if debug_visual_test_mode_enabled:
		_apply_debug_visual_test_hp_to_current_target()


func is_debug_visual_test_mode_enabled() -> bool:
	return debug_visual_test_mode_enabled


func is_debug_purchase_override_enabled() -> bool:
	return BuildConfig.IS_DEBUG_BUILD and debug_visual_test_mode_enabled


func get_debug_purchase_cost(normal_cost: int) -> int:
	if is_debug_purchase_override_enabled() and normal_cost > 0:
		return DEBUG_PURCHASE_COST
	return normal_cost


func can_afford_debug_or_normal_gold_cost(normal_cost: int) -> bool:
	var actual_cost: int = get_debug_purchase_cost(normal_cost)
	return actual_cost > 0 and gold >= actual_cost


func debug_damage_current_target_by_percent(percent: float) -> Dictionary:
	if not debug_visual_test_mode_enabled:
		return _make_attack_result(false, false, 0, 0, target_hp, target_hp, "Debug visual mode is OFF")
	if target_hp <= 0:
		return _make_attack_result(false, false, 0, 0, target_hp, target_hp, "Target already defeated")

	var target_hp_before: int = target_hp
	var damage: int = maxi(1, int(ceil(float(target_max_hp) * percent)))
	target_hp = maxi(target_hp - damage, 0)
	var damage_dealt: int = target_hp_before - target_hp

	return _make_attack_result(
		target_hp <= 0,
		false,
		0,
		damage_dealt,
		target_hp_before,
		target_hp,
		"Debug damage: -%d HP" % damage_dealt
	)


func debug_clear_current_level_for_visual_test() -> Dictionary:
	if not debug_visual_test_mode_enabled:
		return {
			"cleared": false,
			"advanced_to_next_level": false,
			"status_text": "Debug visual mode is OFF"
		}

	mark_level_cleared(current_level)

	var next_level: int = current_level + 1
	var old_zone_index: int = current_zone_index

	max_unlocked_level = maxi(max_unlocked_level, next_level)
	current_level = next_level
	enemies_defeated_on_level = 0
	setup_current_level()

	var zone_changed: bool = current_zone_index != old_zone_index

	return {
		"cleared": true,
		"advanced_to_next_level": true,
		"level_unlocked": true,
		"unlocked_level": max_unlocked_level,
		"zone_changed": zone_changed,
		"zone_name": zone_name,
		"status_text": "Debug: advanced to level %d" % current_level
	}


func _apply_debug_visual_test_hp_to_current_target() -> void:
	if not debug_visual_test_mode_enabled:
		return
	target_max_hp = DEBUG_VISUAL_TEST_HP
	target_hp = DEBUG_VISUAL_TEST_HP


func _get_zone_index_for_level(level: int) -> int:
	return ZoneConfig.get_zone_index_for_level(level)


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
	var base_damage: int = int(BalanceConfig.HERO_BASE_DAMAGE + float(character_level) * BalanceConfig.HERO_DAMAGE_PER_LEVEL) * get_character_milestone_multiplier()
	var hero_click_damage: int = maxi(
		1,
		int(
			base_damage
			* get_focus_training_multiplier()
			* get_partner_skill_bonus_multiplier("click_damage")
			* get_hero_skill_bonus_multiplier("click_damage")
			* get_partner_skill_bonus_multiplier("all_damage")
			* get_focus_burst_multiplier()
			* get_settlement_click_damage_multiplier()
			* get_shop_click_damage_multiplier()
		)
	)
	click_damage = maxi(1, hero_click_damage + get_partner_dps_click_damage_bonus())
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


# --- Boss reward baseline helpers (pure preview — do not mutate state) ---

func get_first_boss_level() -> int:
	return ZoneConfig.BOSS_LEVEL_INTERVAL


func get_last_cleared_boss_level_in_current_run() -> int:
	var best_boss_level: int = 0
	for level_key in cleared_level_ids.keys():
		var level: int = int(level_key)
		if level > 0 and level % ZoneConfig.BOSS_LEVEL_INTERVAL == 0:
			best_boss_level = maxi(best_boss_level, level)
	return best_boss_level


func get_enemy_reward_for_level_preview(level: int, as_boss: bool = false, as_elite: bool = false) -> int:
	if level <= 0:
		return 0
	var base_reward: int = get_base_enemy_reward_for_level(level)
	var reward_multiplier: float = ZoneConfig.get_effective_reward_multiplier_for_level(
		level,
		BalanceConfig.ZONE_CYCLE_REWARD_MULTIPLIER
	)
	return EnemyCalc.get_scaled_reward(
		base_reward,
		reward_multiplier,
		as_boss,
		as_elite,
		BalanceConfig.BOSS_REWARD_MULTIPLIER,
		elite_reward_multiplier
	)


func get_boss_gold_reward_preview(boss_level: int) -> int:
	if boss_level <= 0:
		return 0
	return get_enemy_reward_for_level_preview(boss_level, true, false)


func get_first_boss_gold_reward() -> int:
	return get_boss_gold_reward_preview(get_first_boss_level())


func get_last_cleared_boss_gold_reward() -> int:
	var boss_level: int = get_last_cleared_boss_level_in_current_run()
	if boss_level <= 0:
		return 0
	return get_boss_gold_reward_preview(boss_level)


func get_gold_reward_baseline_for_idle_systems() -> int:
	var last_boss_reward: int = get_last_cleared_boss_gold_reward()
	if last_boss_reward > 0:
		return last_boss_reward
	return get_first_boss_gold_reward()


# --- Offline gold helpers ---

func calculate_offline_gold_reward(elapsed_seconds: int) -> Dictionary:
	var safe_elapsed: int = maxi(elapsed_seconds, 0)
	var capped_elapsed: int = safe_elapsed
	if BalanceConfig.OFFLINE_GOLD_MAX_SECONDS > 0:
		capped_elapsed = mini(capped_elapsed, int(BalanceConfig.OFFLINE_GOLD_MAX_SECONDS))

	var baseline: int = get_gold_reward_baseline_for_idle_systems()
	var ticks: int = int(float(capped_elapsed) / BalanceConfig.OFFLINE_GOLD_TICK_SECONDS)
	var reward: int = maxi(0, ticks * baseline)

	return {
		"elapsed_seconds": safe_elapsed,
		"capped_elapsed_seconds": capped_elapsed,
		"ticks": ticks,
		"baseline_gold": baseline,
		"reward_gold": reward,
	}


func apply_offline_gold_reward(elapsed_seconds: int) -> Dictionary:
	var result: Dictionary = calculate_offline_gold_reward(elapsed_seconds)
	var reward: int = int(result.get("reward_gold", 0))
	if reward > 0:
		gold += reward
		pending_offline_gold_reward = reward
		pending_offline_elapsed_seconds = int(result.get("capped_elapsed_seconds", 0))
	return result


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
	_reset_partner_state()
	_reset_building_state()
	initialize_tasks()
	recalculate_character_level_cost()
	_update_character_state()
	setup_current_level()
