class_name SettlementConfig
extends RefCounted

const BUILDING_NAMES: Array = ["Training Camp", "Market", "Knight Hut", "War Banner", "Clock Tower", "Boss Shrine"]
const BUILDING_BONUS_TYPES: Array = ["partner_dps", "gold", "click_damage", "ability_duration", "ability_cooldown", "boss_gold"]


static func get_building_count() -> int:
	return BUILDING_NAMES.size()


static func get_name(index: int) -> String:
	if index < 0 or index >= BUILDING_NAMES.size():
		return ""
	return BUILDING_NAMES[index]


static func get_bonus_type(index: int) -> String:
	if index < 0 or index >= BUILDING_BONUS_TYPES.size():
		return ""
	return BUILDING_BONUS_TYPES[index]


static func get_base_cost(index: int) -> int:
	if index < 0 or index >= BalanceConfig.BUILDING_BASE_COSTS.size():
		return 0
	return BalanceConfig.BUILDING_BASE_COSTS[index]


static func get_cost_step(index: int) -> int:
	if index < 0 or index >= BalanceConfig.BUILDING_COST_STEPS.size():
		return 0
	return BalanceConfig.BUILDING_COST_STEPS[index]
