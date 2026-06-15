# UI-facing formatting, descriptions, and view-data builders.
# Must not mutate ClickerState. Must not perform purchases, attacks, saves, or progression changes.
# Must not make gameplay decisions. Read-only access to state is fine.
class_name ClickerStatePresentation
extends RefCounted


# --- Building descriptions ---

static func get_building_short_effect_description(state: ClickerState, building_index: int) -> String:
	if building_index < 0 or building_index >= SettlementConfig.BUILDING_NAMES.size():
		return ""

	var amount: float = state.building_bonus_percent_per_level
	if building_index >= SettlementConfig.BUILDING_BONUS_TYPES.size():
		return "+%.1f%% Bonus" % amount

	match SettlementConfig.BUILDING_BONUS_TYPES[building_index]:
		"partner_dps":
			return "+%.1f%% DPS" % amount
		"gold":
			return "+%.1f%% Gold" % amount
		"click_damage":
			return "+%.1f%% Click Damage" % amount
		"ability_duration":
			return "+%.1f%% Focus/Rally Duration" % amount
		"ability_cooldown":
			return "+%.1f%% Cooldown Efficiency" % amount
		"boss_gold":
			return "+%.1f%% Boss Gold" % amount
		_:
			return "+%.1f%% Bonus" % amount


# --- Localization helper (safe for headless/tool mode where autoload may be absent) ---

static func _fmt(key: String, params: Dictionary = {}) -> String:
	var tree: MainLoop = Engine.get_main_loop()
	if tree == null:
		return key
	var lm: Node = (tree as SceneTree).root.get_node_or_null("LocalizationManager")
	if lm == null:
		return key
	return lm.format_key(key, params)


# --- Building card localized text helpers ---

static func get_building_purchase_bonus_gain_text(state: ClickerState, building_index: int, mode: String) -> String:
	var bonus: float = state.get_building_display_bulk_bonus_gain(building_index, mode)
	return _fmt(
		SettlementConfig.get_purchase_gain_key(building_index),
		{"bonus": NumberFormatter.compact_percent(bonus)}
	)


static func get_building_total_bonus_text(state: ClickerState, building_index: int) -> String:
	var bonus: float = state.get_building_display_total_bonus_percent(building_index)
	return _fmt(
		SettlementConfig.get_total_bonus_key(building_index),
		{"bonus": NumberFormatter.compact_percent(bonus)}
	)


# --- Partner descriptions ---

static func get_partner_description(partner_index: int) -> String:
	if partner_index < 0 or partner_index >= BalanceConfig.PARTNER_COUNT:
		return ""
	return "%s DPS" % NumberFormatter.compact(BalanceConfig.get_partner_dps_bignum(partner_index))


# --- Prestige talent descriptions ---

static func get_prestige_talent_description(state: ClickerState, talent_index: int) -> String:
	if talent_index < 0 or talent_index >= PrestigeConfig.TALENT_BONUS_TYPES.size():
		return ""

	var amount: int = state.get_prestige_talent_bonus_percent_per_level(talent_index)
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


# --- Prestige talent card localized text helpers ---

static func get_prestige_talent_purchase_bonus_gain_text(state: ClickerState, talent_index: int, mode: String) -> String:
	var bonus: int = state.get_prestige_talent_display_bulk_bonus_gain(talent_index, mode)
	return _fmt(
		PrestigeConfig.get_purchase_gain_key(talent_index),
		{"bonus": NumberFormatter.compact(bonus)}
	)


static func get_prestige_talent_total_bonus_text(state: ClickerState, talent_index: int) -> String:
	var bonus: int = state.get_prestige_talent_display_total_bonus_percent(talent_index)
	return _fmt(
		PrestigeConfig.get_total_bonus_key(talent_index),
		{"bonus": NumberFormatter.compact(bonus)}
	)


# --- Ability descriptions ---

static func get_ability_description(state: ClickerState, ability_id: String) -> String:
	var rank: int = state.get_ability_rank(ability_id)
	var purchased: bool = state.is_ability_purchased(ability_id)
	match ability_id:
		"autoclick":
			var base_hits: float = BalanceConfig.AUTOCLICK_BASE_HITS_PER_SEC
			var hits: int = roundi(base_hits * (1.0 + BalanceConfig.AUTOCLICK_RANK_RATE_STEP * rank))
			var dur: int = BalanceConfig.AUTOCLICK_BASE_DURATION_SEC + BalanceConfig.AUTOCLICK_RANK_DURATION_BONUS_SEC * rank
			var base_dur: int = BalanceConfig.AUTOCLICK_BASE_DURATION_SEC
			var rate_pct: int = roundi(BalanceConfig.AUTOCLICK_RANK_RATE_STEP * 100.0)
			var dur_bonus: int = BalanceConfig.AUTOCLICK_RANK_DURATION_BONUS_SEC
			if not purchased:
				return "Unlock: %d hits/sec | %ds" % [int(base_hits), base_dur]
			if rank >= state.ability_max_rank:
				return "%d hits/sec | %ds" % [hits, dur]
			return "%d hits/sec | %ds | Next: +%d%% rate, +%ds" % [hits, dur, rate_pct, dur_bonus]
		"gold_bonus":
			var mult: float = BalanceConfig.ABILITY_BASE_MULTIPLIER + BalanceConfig.ABILITY_RANK_MULTIPLIER_STEP * rank
			var next_mult: float = mult + BalanceConfig.ABILITY_RANK_MULTIPLIER_STEP
			if not purchased:
				return "Unlock: x%.2f gold | 45s" % BalanceConfig.ABILITY_BASE_MULTIPLIER
			if rank >= state.ability_max_rank:
				return "x%.2f gold" % mult
			return "x%.2f gold | Next: x%.2f" % [mult, next_mult]
		"focus_burst":
			var mult: float = BalanceConfig.ABILITY_BASE_MULTIPLIER + BalanceConfig.ABILITY_RANK_MULTIPLIER_STEP * rank
			var next_mult: float = mult + BalanceConfig.ABILITY_RANK_MULTIPLIER_STEP
			if not purchased:
				return "Unlock: x%.2f damage | 20s" % BalanceConfig.ABILITY_BASE_MULTIPLIER
			if rank >= state.ability_max_rank:
				return "x%.2f damage" % mult
			return "x%.2f damage | Next: x%.2f" % [mult, next_mult]
		"rally":
			var mult: float = BalanceConfig.ABILITY_BASE_MULTIPLIER + BalanceConfig.ABILITY_RANK_MULTIPLIER_STEP * rank
			var next_mult: float = mult + BalanceConfig.ABILITY_RANK_MULTIPLIER_STEP
			if not purchased:
				return "Unlock: x%.2f partner DPS | 30s" % BalanceConfig.ABILITY_BASE_MULTIPLIER
			if rank >= state.ability_max_rank:
				return "x%.2f partner DPS" % mult
			return "x%.2f partner DPS | Next: x%.2f" % [mult, next_mult]
		_:
			return ""


# --- Ability card row helpers ---

static func get_ability_effect_text(state: ClickerState, ability_id: String) -> String:
	var rank: int = state.get_ability_rank(ability_id)
	match ability_id:
		"autoclick":
			var hits: int = roundi(
				BalanceConfig.AUTOCLICK_BASE_HITS_PER_SEC
				* (1.0 + BalanceConfig.AUTOCLICK_RANK_RATE_STEP * rank)
			)
			return _fmt(
				AbilityConfig.get_effect_key(ability_id),
				{"hits": hits}
			)
		"gold_bonus":
			var multiplier: float = BalanceConfig.ABILITY_BASE_MULTIPLIER + BalanceConfig.ABILITY_RANK_MULTIPLIER_STEP * rank
			return _fmt(
				AbilityConfig.get_effect_key(ability_id),
				{"multiplier": "%.2f" % multiplier}
			)
		"focus_burst":
			var multiplier: float = BalanceConfig.ABILITY_BASE_MULTIPLIER + BalanceConfig.ABILITY_RANK_MULTIPLIER_STEP * rank
			return _fmt(
				AbilityConfig.get_effect_key(ability_id),
				{"multiplier": "%.2f" % multiplier}
			)
		"rally":
			var multiplier: float = BalanceConfig.ABILITY_BASE_MULTIPLIER + BalanceConfig.ABILITY_RANK_MULTIPLIER_STEP * rank
			return _fmt(
				AbilityConfig.get_effect_key(ability_id),
				{"multiplier": "%.2f" % multiplier}
			)
	return ""


static func get_ability_duration_text(state: ClickerState, ability_id: String) -> String:
	var rank: int = state.get_ability_rank(ability_id)
	var seconds: int
	match ability_id:
		"autoclick":
			seconds = BalanceConfig.AUTOCLICK_BASE_DURATION_SEC + BalanceConfig.AUTOCLICK_RANK_DURATION_BONUS_SEC * rank
		"gold_bonus":
			seconds = int(BalanceConfig.GOLD_BONUS_BASE_DURATION_SEC)
		"focus_burst":
			seconds = int(BalanceConfig.FOCUS_BURST_BASE_DURATION_SEC)
		"rally":
			seconds = int(BalanceConfig.RALLY_BASE_DURATION_SEC)
		_:
			return ""
	return _fmt(AbilityConfig.get_duration_key(ability_id), {"seconds": seconds})


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


static func get_shop_product_view_data(state: ClickerState, mode: String = "x1") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var buy_count: int = ShopRuntime.get_shop_buy_count(mode)
	for product: Dictionary in ShopConfig.SHOP_PRODUCTS:
		var product_id: String = String(product.get("id", ""))
		var product_type: String = String(product.get("product_type", "consumable"))
		var cost_gems: int
		var owned_count: int
		var total_multiplier: int
		var effect_key: String
		var effect_params: Dictionary

		var can_buy: bool
		if product_type == "permanent_multiplier":
			cost_gems = ShopRuntime.get_permanent_upgrade_bulk_cost(state, product_id, buy_count)
			owned_count = state.get_shop_permanent_upgrade_count(product_id)
			total_multiplier = int(pow(ShopConfig.PERMANENT_UPGRADE_MULTIPLIER_PER_LEVEL, float(owned_count)))
			var purchase_multiplier: int = int(pow(ShopConfig.PERMANENT_UPGRADE_MULTIPLIER_PER_LEVEL, float(buy_count)))
			var bonus_type: String = String(product.get("bonus_type", ""))
			match bonus_type:
				"partner_dps":
					effect_key = "shop.card.partner_dps_multiplier"
				"click_damage":
					effect_key = "shop.card.click_damage_multiplier"
				"gold":
					effect_key = "shop.card.gold_multiplier"
				_:
					effect_key = ""
			effect_params = {"multiplier": str(purchase_multiplier)}
			can_buy = state.gems >= cost_gems and cost_gems > 0
		elif product_type == "donation_entry":
			cost_gems = 0
			owned_count = -1
			total_multiplier = -1
			effect_key = "shop.card.gem_purchase_entry"
			effect_params = {}
			can_buy = true
		elif product_type == "rewarded_ad":
			cost_gems = 0
			owned_count = -1
			total_multiplier = -1
			effect_key = "shop.card.rewarded_gems"
			effect_params = {"amount": NumberFormatter.compact(BalanceConfig.SHOP_REWARDED_GEMS_AD_REWARD)}
			can_buy = true
		else:
			cost_gems = int(product.get("cost_gems", 0)) * buy_count
			owned_count = -1
			total_multiplier = -1
			var reward_type: String = String(product.get("reward_type", ""))
			if reward_type == "gold":
				var gold_amount: BigNumber = ShopRuntime.get_gold_pack_reward_for_count(state, product_id, buy_count)
				effect_key = "shop.card.gold_reward"
				effect_params = {"amount": NumberFormatter.compact(gold_amount)}
			else:
				effect_key = ""
				effect_params = {}
			can_buy = state.gems >= cost_gems and cost_gems > 0

		result.append({
			"id": product_id,
			"name": String(product.get("name", "")),
			"name_key": String(product.get("name_key", "")),
			"description": String(product.get("description", "")),
			"description_key": String(product.get("description_key", "")),
			"product_type": product_type,
			"cost_gems": cost_gems,
			"buy_count": buy_count,
			"can_buy": can_buy,
			"owned_count": owned_count,
			"total_multiplier": total_multiplier,
			"effect_key": effect_key,
			"effect_params": effect_params,
		})
	return result
