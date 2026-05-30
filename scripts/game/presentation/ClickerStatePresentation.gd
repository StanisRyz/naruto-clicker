# UI-facing formatting, descriptions, and view-data builders.
# Must not mutate ClickerState. Must not perform purchases, attacks, saves, or progression changes.
# Must not make gameplay decisions. Read-only access to state is fine.
class_name ClickerStatePresentation
extends RefCounted


# --- Building descriptions ---

static func get_building_short_effect_description(state: ClickerState, building_index: int) -> String:
	if building_index < 0 or building_index >= SettlementConfig.BUILDING_NAMES.size():
		return ""

	var amount: int = state.building_bonus_percent_per_level
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


# --- Partner descriptions ---

static func get_partner_description(partner_index: int) -> String:
	if partner_index < 0 or partner_index >= BalanceConfig.PARTNER_DPS_VALUES.size():
		return ""

	return "%d DPS" % BalanceConfig.PARTNER_DPS_VALUES[partner_index]


# --- Prestige talent descriptions ---

static func get_prestige_talent_description(state: ClickerState, talent_index: int) -> String:
	if talent_index < 0 or talent_index >= PrestigeConfig.TALENT_BONUS_TYPES.size():
		return ""

	var amount: int = state.prestige_talent_bonus_percent_per_level
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


# --- Ability descriptions ---

static func get_ability_description(state: ClickerState, ability_id: String) -> String:
	var rank: int = state.get_ability_rank(ability_id)
	var purchased: bool = state.is_ability_purchased(ability_id)
	match ability_id:
		"autoclick":
			var hits: int = roundi(20.0 * (1.0 + 0.15 * rank))
			var dur: int = 15 + 2 * rank
			if not purchased:
				return "Unlock: 20 hits/sec | 15s"
			if rank >= state.ability_max_rank:
				return "%d hits/sec | %ds" % [hits, dur]
			return "%d hits/sec | %ds | Next: +15%% rate, +2s" % [hits, dur]
		"gold_bonus":
			var mult: float = 2.0 + 0.25 * rank
			if not purchased:
				return "Unlock: x2.00 gold | 45s"
			if rank >= state.ability_max_rank:
				return "x%.2f gold" % mult
			return "x%.2f gold | Next: x%.2f" % [mult, mult + 0.25]
		"focus_burst":
			var mult: float = 2.0 + 0.25 * rank
			if not purchased:
				return "Unlock: x2.00 damage | 20s"
			if rank >= state.ability_max_rank:
				return "x%.2f damage" % mult
			return "x%.2f damage | Next: x%.2f" % [mult, mult + 0.25]
		"rally":
			var mult: float = 2.0 + 0.25 * rank
			if not purchased:
				return "Unlock: x2.00 partner DPS | 30s"
			if rank >= state.ability_max_rank:
				return "x%.2f partner DPS" % mult
			return "x%.2f partner DPS | Next: x%.2f" % [mult, mult + 0.25]
		_:
			return ""


# --- Skill state labels ---

static func get_hero_skill_state(state: ClickerState, skill_id: String) -> String:
	if state.is_hero_skill_purchased(skill_id):
		return "purchased"
	if state.is_hero_skill_unlocked(skill_id):
		return "available"
	return "locked"


static func get_ability_skill_state(state: ClickerState, skill_id: String) -> String:
	if state.is_ability_skill_purchased(skill_id):
		return "purchased"
	if state.is_ability_skill_unlocked(skill_id):
		return "available"
	return "locked"


static func get_partner_skill_state(state: ClickerState, skill_id: String) -> String:
	if state.is_partner_skill_purchased(skill_id):
		return "purchased"
	if state.is_partner_skill_unlocked(skill_id):
		return "available"
	return "locked"


# --- View-data builders ---

static func get_active_task_view_data(state: ClickerState) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for task_id in state.active_task_ids:
		var task: Dictionary = state.get_task_definition(task_id)
		if task.is_empty():
			continue
		result.append({
			"id": task_id,
			"title": String(task.get("title", "")),
			"progress": state.get_task_progress(task_id),
			"target": state.get_task_target(task_id),
			"reward_gold": state.get_task_reward_gold(task_id),
			"completed": state.is_task_completed(task_id),
		})
	return result


static func get_shop_product_view_data(state: ClickerState) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for product: Dictionary in ShopConfig.SHOP_PRODUCTS:
		var cost_gems: int = int(product.get("cost_gems", 0))
		result.append({
			"id": String(product.get("id", "")),
			"name": String(product.get("name", "")),
			"description": String(product.get("description", "")),
			"cost_gems": cost_gems,
			"can_buy": state.gems >= cost_gems,
		})
	return result
