extends SceneTree

# Balance audit tool — headless probe of economy curves.
# Reads BalanceConfig, calculators, config files, and simulates ClickerState.
# No save files read or written. No gameplay values changed.
#
# Run: godot --headless --script res://scripts/tools/BalanceAuditReport.gd

const _BC = preload("res://scripts/game/BalanceConfig.gd")
const _MC = preload("res://scripts/game/calculators/MilestoneCalculator.gd")
const _CC = preload("res://scripts/game/calculators/CostCalculator.gd")
const _EC = preload("res://scripts/game/calculators/EnemyScalingCalculator.gd")
const _ZC = preload("res://scripts/game/config/ZoneConfig.gd")
const _PC = preload("res://scripts/game/config/PartnerConfig.gd")
const _AC = preload("res://scripts/game/config/AbilityConfig.gd")
const _HSC = preload("res://scripts/game/config/HeroSkillConfig.gd")
const _PSC = preload("res://scripts/game/config/PartnerSkillConfig.gd")
const _SC = preload("res://scripts/game/config/SettlementConfig.gd")
const _PRC = preload("res://scripts/game/config/PrestigeConfig.gd")
const _CS = preload("res://scripts/game/ClickerState.gd")

const CLICKS_PER_SEC: float = 6.0
# Partners 14–28 (index 13+) are marked placeholder in BalanceConfig.
const PLACEHOLDER_PARTNER_START_IDX: int = 13

# --- Simulation constants ---
const SIM_MAX_SECONDS: float = 7200.0
const SIM_MAX_LEVEL: int = 150
const SIM_CLICKS_PER_SEC: float = 6.0
const SIM_PURCHASE_INTERVAL_SEC: float = 1.0
const SIM_REPORT_LEVELS: Array = [1, 5, 10, 15, 20, 25, 30, 40, 50, 75, 100, 150]
const SIM_LOG_ALL_PURCHASES: bool = false
const SIM_HERO_LOG_MILESTONES: Array = [10, 25, 50, 100]
const SIM_PARTNER_LOG_MILESTONES: Array = [1, 10, 25, 50]
const SCENARIO_ENEMIES_PER_LEVEL: int = 10

const BALANCE_SCENARIOS: Array[Dictionary] = [
	{
		"id": "baseline",
		"label": "Baseline",
		"hero_damage_mult": 1.0,
		"hero_cost_mult": 1.0,
		"hero_cost_growth_delta": 0.0,
		"partner_dps_mult": 1.0,
		"partner_cost_mult": 1.0,
		"partner_cost_growth_delta": 0.0,
		"building_cost_mult": 1.0,
		"building_effect_mult": 1.0,
		"enemy_hp_mult": 1.0,
		"enemy_reward_mult": 1.0,
		"boss_hp_mult": 1.0,
		"boss_reward_mult": 1.0,
		"ability_cost_mult": 1.0,
	},
	{
		"id": "boss_hp_minus_20",
		"label": "Boss HP -20%",
		"hero_damage_mult": 1.0,
		"hero_cost_mult": 1.0,
		"hero_cost_growth_delta": 0.0,
		"partner_dps_mult": 1.0,
		"partner_cost_mult": 1.0,
		"partner_cost_growth_delta": 0.0,
		"building_cost_mult": 1.0,
		"building_effect_mult": 1.0,
		"enemy_hp_mult": 1.0,
		"enemy_reward_mult": 1.0,
		"boss_hp_mult": 0.80,
		"boss_reward_mult": 1.0,
		"ability_cost_mult": 1.0,
	},
	{
		"id": "boss_hp_minus_5",
		"label": "Boss HP -5%",
		"hero_damage_mult": 1.0,
		"hero_cost_mult": 1.0,
		"hero_cost_growth_delta": 0.0,
		"partner_dps_mult": 1.0,
		"partner_cost_mult": 1.0,
		"partner_cost_growth_delta": 0.0,
		"building_cost_mult": 1.0,
		"building_effect_mult": 1.0,
		"enemy_hp_mult": 1.0,
		"enemy_reward_mult": 1.0,
		"boss_hp_mult": 0.95,
		"boss_reward_mult": 1.0,
		"ability_cost_mult": 1.0,
	},
	{
		"id": "boss_hp_minus_10",
		"label": "Boss HP -10%",
		"hero_damage_mult": 1.0,
		"hero_cost_mult": 1.0,
		"hero_cost_growth_delta": 0.0,
		"partner_dps_mult": 1.0,
		"partner_cost_mult": 1.0,
		"partner_cost_growth_delta": 0.0,
		"building_cost_mult": 1.0,
		"building_effect_mult": 1.0,
		"enemy_hp_mult": 1.0,
		"enemy_reward_mult": 1.0,
		"boss_hp_mult": 0.90,
		"boss_reward_mult": 1.0,
		"ability_cost_mult": 1.0,
	},
	{
		"id": "partner_dps_plus_25",
		"label": "Partner DPS +25%",
		"hero_damage_mult": 1.0,
		"hero_cost_mult": 1.0,
		"hero_cost_growth_delta": 0.0,
		"partner_dps_mult": 1.25,
		"partner_cost_mult": 1.0,
		"partner_cost_growth_delta": 0.0,
		"building_cost_mult": 1.0,
		"building_effect_mult": 1.0,
		"enemy_hp_mult": 1.0,
		"enemy_reward_mult": 1.0,
		"boss_hp_mult": 1.0,
		"boss_reward_mult": 1.0,
		"ability_cost_mult": 1.0,
	},
	{
		"id": "partner_cost_minus_15",
		"label": "Partner Cost -15%",
		"hero_damage_mult": 1.0,
		"hero_cost_mult": 1.0,
		"hero_cost_growth_delta": 0.0,
		"partner_dps_mult": 1.0,
		"partner_cost_mult": 0.85,
		"partner_cost_growth_delta": 0.0,
		"building_cost_mult": 1.0,
		"building_effect_mult": 1.0,
		"enemy_hp_mult": 1.0,
		"enemy_reward_mult": 1.0,
		"boss_hp_mult": 1.0,
		"boss_reward_mult": 1.0,
		"ability_cost_mult": 1.0,
	},
	{
		"id": "partner_cost_minus_5",
		"label": "Partner Cost -5%",
		"hero_damage_mult": 1.0,
		"hero_cost_mult": 1.0,
		"hero_cost_growth_delta": 0.0,
		"partner_dps_mult": 1.0,
		"partner_cost_mult": 0.95,
		"partner_cost_growth_delta": 0.0,
		"building_cost_mult": 1.0,
		"building_effect_mult": 1.0,
		"enemy_hp_mult": 1.0,
		"enemy_reward_mult": 1.0,
		"boss_hp_mult": 1.0,
		"boss_reward_mult": 1.0,
		"ability_cost_mult": 1.0,
	},
	{
		"id": "partner_cost_minus_10",
		"label": "Partner Cost -10%",
		"hero_damage_mult": 1.0,
		"hero_cost_mult": 1.0,
		"hero_cost_growth_delta": 0.0,
		"partner_dps_mult": 1.0,
		"partner_cost_mult": 0.90,
		"partner_cost_growth_delta": 0.0,
		"building_cost_mult": 1.0,
		"building_effect_mult": 1.0,
		"enemy_hp_mult": 1.0,
		"enemy_reward_mult": 1.0,
		"boss_hp_mult": 1.0,
		"boss_reward_mult": 1.0,
		"ability_cost_mult": 1.0,
	},
	{
		"id": "partner_cost_minus_12",
		"label": "Partner Cost -12%",
		"hero_damage_mult": 1.0,
		"hero_cost_mult": 1.0,
		"hero_cost_growth_delta": 0.0,
		"partner_dps_mult": 1.0,
		"partner_cost_mult": 0.88,
		"partner_cost_growth_delta": 0.0,
		"building_cost_mult": 1.0,
		"building_effect_mult": 1.0,
		"enemy_hp_mult": 1.0,
		"enemy_reward_mult": 1.0,
		"boss_hp_mult": 1.0,
		"boss_reward_mult": 1.0,
		"ability_cost_mult": 1.0,
	},
	{
		"id": "partner_cost_minus_10_boss_hp_minus_5",
		"label": "Partner Cost -10%, Boss HP -5%",
		"hero_damage_mult": 1.0,
		"hero_cost_mult": 1.0,
		"hero_cost_growth_delta": 0.0,
		"partner_dps_mult": 1.0,
		"partner_cost_mult": 0.90,
		"partner_cost_growth_delta": 0.0,
		"building_cost_mult": 1.0,
		"building_effect_mult": 1.0,
		"enemy_hp_mult": 1.0,
		"enemy_reward_mult": 1.0,
		"boss_hp_mult": 0.95,
		"boss_reward_mult": 1.0,
		"ability_cost_mult": 1.0,
	},
	{
		"id": "enemy_hp_minus_10",
		"label": "Enemy HP -10%",
		"hero_damage_mult": 1.0,
		"hero_cost_mult": 1.0,
		"hero_cost_growth_delta": 0.0,
		"partner_dps_mult": 1.0,
		"partner_cost_mult": 1.0,
		"partner_cost_growth_delta": 0.0,
		"building_cost_mult": 1.0,
		"building_effect_mult": 1.0,
		"enemy_hp_mult": 0.90,
		"enemy_reward_mult": 1.0,
		"boss_hp_mult": 1.0,
		"boss_reward_mult": 1.0,
		"ability_cost_mult": 1.0,
	},
	{
		"id": "hero_damage_plus_10",
		"label": "Hero Damage +10%",
		"hero_damage_mult": 1.10,
		"hero_cost_mult": 1.0,
		"hero_cost_growth_delta": 0.0,
		"partner_dps_mult": 1.0,
		"partner_cost_mult": 1.0,
		"partner_cost_growth_delta": 0.0,
		"building_cost_mult": 1.0,
		"building_effect_mult": 1.0,
		"enemy_hp_mult": 1.0,
		"enemy_reward_mult": 1.0,
		"boss_hp_mult": 1.0,
		"boss_reward_mult": 1.0,
		"ability_cost_mult": 1.0,
	},
	{
		"id": "early_combined_v1",
		"label": "Early Combined v1",
		"hero_damage_mult": 1.0,
		"hero_cost_mult": 1.0,
		"hero_cost_growth_delta": 0.0,
		"partner_dps_mult": 1.15,
		"partner_cost_mult": 0.90,
		"partner_cost_growth_delta": 0.0,
		"building_cost_mult": 1.0,
		"building_effect_mult": 1.0,
		"enemy_hp_mult": 1.0,
		"enemy_reward_mult": 1.10,
		"boss_hp_mult": 0.85,
		"boss_reward_mult": 1.0,
		"ability_cost_mult": 1.0,
	},
	{
		"id": "idle_support_v1",
		"label": "Idle Support v1",
		"hero_damage_mult": 0.95,
		"hero_cost_mult": 1.0,
		"hero_cost_growth_delta": 0.0,
		"partner_dps_mult": 1.35,
		"partner_cost_mult": 0.85,
		"partner_cost_growth_delta": 0.0,
		"building_cost_mult": 1.0,
		"building_effect_mult": 1.0,
		"enemy_hp_mult": 1.0,
		"enemy_reward_mult": 1.0,
		"boss_hp_mult": 1.0,
		"boss_reward_mult": 1.0,
		"ability_cost_mult": 1.0,
	},
	{
		"id": "partner_curve_balanced_idle",
		"label": "Partner Curve: Balanced Idle",
		"partner_curve_id": "partner_curve_balanced_idle",
		"hero_damage_mult": 1.0,
		"hero_cost_mult": 1.0,
		"hero_cost_growth_delta": 0.0,
		"partner_dps_mult": 1.0,
		"partner_cost_mult": 1.0,
		"partner_cost_growth_delta": 0.0,
		"building_cost_mult": 1.0,
		"building_effect_mult": 1.0,
		"enemy_hp_mult": 1.0,
		"enemy_reward_mult": 1.0,
		"boss_hp_mult": 1.0,
		"boss_reward_mult": 1.0,
		"ability_cost_mult": 1.0,
	},
	{
		"id": "partner_curve_soft_idle",
		"label": "Partner Curve: Soft Idle",
		"partner_curve_id": "partner_curve_soft_idle",
		"hero_damage_mult": 1.0,
		"hero_cost_mult": 1.0,
		"hero_cost_growth_delta": 0.0,
		"partner_dps_mult": 1.0,
		"partner_cost_mult": 1.0,
		"partner_cost_growth_delta": 0.0,
		"building_cost_mult": 1.0,
		"building_effect_mult": 1.0,
		"enemy_hp_mult": 1.0,
		"enemy_reward_mult": 1.0,
		"boss_hp_mult": 1.0,
		"boss_reward_mult": 1.0,
		"ability_cost_mult": 1.0,
	},
	{
		"id": "partner_curve_power_idle",
		"label": "Partner Curve: Power Idle",
		"partner_curve_id": "partner_curve_power_idle",
		"hero_damage_mult": 1.0,
		"hero_cost_mult": 1.0,
		"hero_cost_growth_delta": 0.0,
		"partner_dps_mult": 1.0,
		"partner_cost_mult": 1.0,
		"partner_cost_growth_delta": 0.0,
		"building_cost_mult": 1.0,
		"building_effect_mult": 1.0,
		"enemy_hp_mult": 1.0,
		"enemy_reward_mult": 1.0,
		"boss_hp_mult": 1.0,
		"boss_reward_mult": 1.0,
		"ability_cost_mult": 1.0,
	},
	{
		"id": "partner_curve_late_power",
		"label": "Partner Curve: Late Power",
		"partner_curve_id": "partner_curve_late_power",
		"hero_damage_mult": 1.0,
		"hero_cost_mult": 1.0,
		"hero_cost_growth_delta": 0.0,
		"partner_dps_mult": 1.0,
		"partner_cost_mult": 1.0,
		"partner_cost_growth_delta": 0.0,
		"building_cost_mult": 1.0,
		"building_effect_mult": 1.0,
		"enemy_hp_mult": 1.0,
		"enemy_reward_mult": 1.0,
		"boss_hp_mult": 1.0,
		"boss_reward_mult": 1.0,
		"ability_cost_mult": 1.0,
	},
]

var _warnings: Array[String] = []
var _csv_rows: Array[Dictionary] = []
var _live_profile_results: Dictionary = {}
var _scenario_partner_base_cost_cache: Dictionary = {}


# ==========================================================================
#  Entry point
# ==========================================================================

func _init() -> void:
	_div("=", 74)
	_ln("  BALANCE AUDIT REPORT  —  naruto-clicker")
	_ln("  Headless probe: no save modified, no gameplay changed.")
	_div("=", 74)

	_section_enemy()
	_section_hero()
	_section_partner()
	_section_combat()
	_section_prestige()
	_section_progression_simulation()
	_section_partner_curve_scenario_preview()
	_section_balance_scenario_comparison()
	_section_warnings()
	_write_csv()

	_div("=", 74)
	_ln("  END OF REPORT")
	_div("=", 74)
	quit()


# ==========================================================================
#  SECTION 1 — Enemy Progression
# ==========================================================================

func _section_enemy() -> void:
	_header("SECTION 1 — Enemy Progression  (levels 1–150)")
	_ln("HP/Rwd ratio = growth factor of NormHP vs NormRwd between sampled levels.")
	_ln(_row([
		_rj("Lvl", 5), _rj("Z#", 3), _lj("ZoneName", 19),
		_rj("NormHP", 10), _rj("NormRwd", 9),
		_lj("Boss?", 6), _rj("BossHP", 10), _rj("BossRwd", 9),
		"HP×/Rwd×",
	]))
	_div("-", 100)

	var prev_hp: int = 0
	var prev_rwd: int = 0

	for lvl: int in _enemy_sample_levels():
		var zd: Dictionary = _ZC.get_zone_data_for_level(lvl)
		var hp_m: float  = float(zd.get("hp_multiplier", 1.0))
		var rwd_m: float = float(zd.get("reward_multiplier", 1.0))
		var zname: String = str(zd.get("name", "?"))
		var zidx: int = _ZC.get_zone_index_for_level(lvl)

		var base_hp:  int = _EC.get_base_hp(lvl,     _BC.ENEMY_HP_BASE,     _BC.ENEMY_HP_GROWTH)
		var base_rwd: int = _EC.get_base_reward(lvl, _BC.ENEMY_REWARD_BASE, _BC.ENEMY_REWARD_GROWTH)

		var norm_hp:  int = _EC.get_scaled_hp(base_hp,   hp_m,  false, false, _BC.BOSS_HP_MULTIPLIER,     _BC.ELITE_HP_MULTIPLIER)
		var norm_rwd: int = _EC.get_scaled_reward(base_rwd, rwd_m, false, false, _BC.BOSS_REWARD_MULTIPLIER, _BC.ELITE_REWARD_MULTIPLIER)
		var is_boss: bool = (lvl % _ZC.BOSS_LEVEL_INTERVAL == 0)
		var boss_hp:  int = _EC.get_scaled_hp(base_hp,   hp_m,  true,  false, _BC.BOSS_HP_MULTIPLIER,     _BC.ELITE_HP_MULTIPLIER)
		var boss_rwd: int = _EC.get_scaled_reward(base_rwd, rwd_m, true,  false, _BC.BOSS_REWARD_MULTIPLIER, _BC.ELITE_REWARD_MULTIPLIER)

		var ratio_str: String = "—"
		if prev_hp > 0 and prev_rwd > 0:
			var hp_g:  float = float(norm_hp)  / float(prev_hp)
			var rwd_g: float = float(norm_rwd) / float(prev_rwd)
			ratio_str = "%.2f/%.2f" % [hp_g, rwd_g]
			if hp_g > rwd_g * 1.25 and lvl <= 50:
				_warn("Enemy lvl %d: HP grows ×%.2f but reward only ×%.2f — friction rising faster than income" % [lvl, hp_g, rwd_g])

		_ln(_row([
			_rj(str(lvl), 5), _rj(str(zidx + 1), 3), _lj(zname.left(18), 19),
			_rj(_fn(norm_hp), 10), _rj(_fn(norm_rwd), 9),
			_lj(("BOSS" if is_boss else "—"), 6),
			_rj((_fn(boss_hp)  if is_boss else "—"), 10),
			_rj((_fn(boss_rwd) if is_boss else "—"), 9),
			ratio_str,
		]))

		_csv_append("enemy", lvl, norm_hp, norm_rwd, 0, 0, 0, 0.0,
			"zone=%d%s" % [zidx + 1, " boss" if is_boss else ""])
		if is_boss:
			_csv_append("enemy_boss", lvl, boss_hp, boss_rwd, 0, 0, 0, 0.0,
				"zone=%d" % (zidx + 1))

		prev_hp  = norm_hp
		prev_rwd = norm_rwd

	var cycle: int = _ZC.TOTAL_ZONE_LEVELS
	_ln("")
	_ln("  Zone cycle = %d levels.  Multipliers reset at level %d, %d, ..." % [cycle, cycle + 1, cycle * 2 + 1])
	if cycle < 150:
		_warn("Zone cycle resets at level %d — HP/reward multipliers drop to zone-1 values beyond this" % (cycle + 1))


# ==========================================================================
#  SECTION 2 — Hero Progression
# ==========================================================================

func _section_hero() -> void:
	_header("SECTION 2 — Hero Progression  (damage & upgrade cost)")
	_ln("FinalDmg = int(HERO_BASE_DAMAGE + level * HERO_DAMAGE_PER_LEVEL) × milestone_mult")
	_ln("NextCost includes ×3 spike at milestone target levels.")
	_ln(_row([
		_rj("HeroLvl", 8), _rj("BasePre", 9), _lj("MS×", 6),
		_rj("FinalDmg", 10), _rj("NextCost", 14), "Note",
	]))
	_div("-", 72)

	var prev_dmg:  int = 0
	var prev_cost: int = 0

	for lvl: int in _hero_sample_levels():
		var base_pre: float = _BC.HERO_BASE_DAMAGE + float(lvl) * _BC.HERO_DAMAGE_PER_LEVEL
		var ms_mult:  int = _MC.get_milestone_multiplier(
			lvl, _BC.MILESTONE_LEVELS, _BC.MILESTONE_MULTIPLIER_PER_REACHED)
		var final_dmg: int = maxi(1, int(base_pre) * ms_mult)
		var next_cost: int = _CC.get_hero_level_cost(
			lvl,
			_BC.HERO_BASE_COST,
			_BC.HERO_COST_GROWTH_EARLY, _BC.HERO_COST_GROWTH_MID, _BC.HERO_COST_GROWTH_LATE,
			_BC.HERO_COST_MID_START_LEVEL, _BC.HERO_COST_LATE_START_LEVEL,
			_BC.MILESTONE_LEVELS, _BC.MILESTONE_COST_MULTIPLIER)

		var note: String = ""
		if _MC.is_milestone_target(lvl, _BC.MILESTONE_LEVELS):
			note += "← MILESTONE(×%d dmg, cost×%d)" % [_BC.MILESTONE_MULTIPLIER_PER_REACHED, _BC.MILESTONE_COST_MULTIPLIER]
		if _MC.is_milestone_target(lvl + 1, _BC.MILESTONE_LEVELS):
			note += "next level = milestone cost spike"

		_ln(_row([
			_rj(str(lvl), 8), _rj(_fn(int(base_pre)), 9), _lj("×%d" % ms_mult, 6),
			_rj(_fn(final_dmg), 10), _rj(_fn(next_cost), 14), note,
		]))

		_csv_append("hero", lvl, 0, 0, next_cost, final_dmg, 0, 0.0,
			"ms_mult=%d" % ms_mult)

		if prev_dmg > 0 and prev_cost > 0 and next_cost > 0 and lvl <= 100:
			var cg: float = float(next_cost) / float(prev_cost)
			var dg: float = float(final_dmg) / float(prev_dmg)
			if dg > 0.0 and cg / dg > 3.5:
				_warn("Hero lvl %d: upgrade cost grows ×%.1f but damage only ×%.1f — economy spike" % [lvl, cg, dg])

		prev_dmg  = final_dmg
		prev_cost = next_cost


# ==========================================================================
#  SECTION 3 — Partner Progression
# ==========================================================================

func _section_partner() -> void:
	_header("SECTION 3 — Partner Progression")

	# ---- 3a: main cost table ----
	_ln("Cost@N = cost to buy the Nth copy (owned count before purchase = N-1).")
	_ln("[PH] = placeholder values per BalanceConfig comment.")
	_ln(_row([
		_rj("#", 4), _lj("Name", 23),
		_rj("BaseDPS", 9), _rj("BaseCost", 10),
		_rj("Cost@1", 11), _rj("Cost@10", 11), _rj("Cost@25", 11),
		_rj("Cost@50", 11), _rj("Cost@100", 11), _rj("Cost@250", 13),
		"Flag",
	]))
	_div("-", 118)

	var pcount: int = _BC.PARTNER_DPS_VALUES.size()
	var own_before: Array = [0, 9, 24, 49, 99, 249]

	for i: int in range(pcount):
		var pname:    String = _partner_name(i)
		var base_dps: int    = _BC.PARTNER_DPS_VALUES[i]
		var base_cost: int   = _BC.PARTNER_BASE_COSTS[i] if i < _BC.PARTNER_BASE_COSTS.size() else 0
		var is_ph: bool      = i >= PLACEHOLDER_PARTNER_START_IDX

		var costs: Array = []
		for owned: int in own_before:
			costs.append(_partner_cost(i, owned))

		_ln(_row([
			_rj(str(i + 1), 4), _lj(pname.left(22), 23),
			_rj(_fn(base_dps), 9), _rj(_fn(base_cost), 10),
			_rj(_fn(costs[0]), 11), _rj(_fn(costs[1]), 11), _rj(_fn(costs[2]), 11),
			_rj(_fn(costs[3]), 11), _rj(_fn(costs[4]), 11), _rj(_fn(costs[5]), 13),
			("[PH]" if is_ph else ""),
		]))

		_csv_append("partner_static", i + 1, 0, 0, costs[0], 0, base_dps, 0.0,
			"partner_name=%s base_cost=%d cost_at_10=%d cost_at_25=%d cost_at_50=%d cost_at_100=%d placeholder=%s" % [
				pname, base_cost, costs[1], costs[2], costs[3], costs[4],
				("true" if is_ph else "false"),
			])

		if is_ph:
			_warn("Partner %d (%s): still using placeholder DPS/cost — needs final balance pass" % [i + 1, pname])

	# ---- 3b: DPS efficiency table ----
	_ln("")
	_ln("  DPS efficiency — DPS per gold at first purchase and at 100 owned:")
	_ln(_row([
		_lj("#  Name", 27),
		_rj("DPS/Gold@1", 13), _rj("MS@1", 7),
		_rj("DPS/Gold@100", 15), _rj("MS@100", 8),
	]))
	_div("-", 72)

	for i: int in range(pcount):
		var pname:    String = _partner_name(i)
		var base_dps: int    = _BC.PARTNER_DPS_VALUES[i]
		var c1:   int = _partner_cost(i, 0)
		var c100: int = _partner_cost(i, 99)
		var ms1:   int = _MC.get_milestone_multiplier(1,   _BC.MILESTONE_LEVELS, _BC.MILESTONE_MULTIPLIER_PER_REACHED)
		var ms100: int = _MC.get_milestone_multiplier(100, _BC.MILESTONE_LEVELS, _BC.MILESTONE_MULTIPLIER_PER_REACHED)
		var dpg1:   float = float(base_dps * ms1)   / float(c1)   if c1   > 0 else 0.0
		var dpg100: float = float(base_dps * ms100) / float(c100) if c100 > 0 else 0.0
		_ln(_row([
			_lj("%2d %-22s" % [i + 1, pname.left(22)], 27),
			_rj("%.5f" % dpg1, 13), _rj("×%d" % ms1, 7),
			_rj("%.5f" % dpg100, 15), _rj("×%d" % ms100, 8),
		]))

	# ---- 3c: consecutive DPS/cost ratio (non-placeholder only) ----
	_ln("")
	_ln("  Consecutive non-placeholder partner DPS & cost ratios:")
	_div("-", 68)
	for i: int in range(1, PLACEHOLDER_PARTNER_START_IDX):
		var prev_dps:  int = _BC.PARTNER_DPS_VALUES[i - 1]
		var curr_dps:  int = _BC.PARTNER_DPS_VALUES[i]
		var prev_cost: int = _BC.PARTNER_BASE_COSTS[i - 1]
		var curr_cost: int = _BC.PARTNER_BASE_COSTS[i]
		var dps_r:  float = float(curr_dps)  / float(prev_dps)  if prev_dps  > 0 else 0.0
		var cost_r: float = float(curr_cost) / float(prev_cost) if prev_cost > 0 else 0.0
		var val_r:  float = dps_r / cost_r if cost_r > 0.0 else 0.0
		_ln("  P%d→P%d  DPS×%.2f  Cost×%.2f  value_ratio=%.2f" % [i, i + 1, dps_r, cost_r, val_r])
		if val_r < 0.5 and cost_r > 1.0:
			_warn("Partner %d→%d: DPS-per-cost drops >50%% — value discontinuity" % [i + 1, i + 2])


# ==========================================================================
#  SECTION 4 — Combat Pressure
# ==========================================================================

func _section_combat() -> void:
	_header("SECTION 4 — Combat Pressure  (hero-only, hero_level = game_level)")
	_ln("Worst-case: no partner DPS, no passive multipliers beyond milestone.")
	_ln("BossResult shows estimated seconds to kill boss at 6 clicks/sec.")
	_ln(_row([
		_rj("Lvl", 5), _rj("NormHP", 9), _rj("Reward", 8),
		_rj("HeroDmg", 9), _rj("Clicks", 7), _rj("ManSec", 8),
		_rj("BossHP", 9), _rj("BossSec", 9), "BossResult",
	]))
	_div("-", 95)

	for lvl: int in _combat_sample_levels():
		var zd: Dictionary = _ZC.get_zone_data_for_level(lvl)
		var hp_m:  float = float(zd.get("hp_multiplier", 1.0))
		var rwd_m: float = float(zd.get("reward_multiplier", 1.0))

		var base_hp:  int = _EC.get_base_hp(lvl,     _BC.ENEMY_HP_BASE,     _BC.ENEMY_HP_GROWTH)
		var base_rwd: int = _EC.get_base_reward(lvl, _BC.ENEMY_REWARD_BASE, _BC.ENEMY_REWARD_GROWTH)
		var norm_hp:  int = _EC.get_scaled_hp(base_hp,     hp_m,  false, false, _BC.BOSS_HP_MULTIPLIER, _BC.ELITE_HP_MULTIPLIER)
		var norm_rwd: int = _EC.get_scaled_reward(base_rwd, rwd_m, false, false, _BC.BOSS_REWARD_MULTIPLIER, _BC.ELITE_REWARD_MULTIPLIER)
		var boss_hp:  int = _EC.get_scaled_hp(base_hp, hp_m, true, false, _BC.BOSS_HP_MULTIPLIER, _BC.ELITE_HP_MULTIPLIER)

		var base_pre: float = _BC.HERO_BASE_DAMAGE + float(lvl) * _BC.HERO_DAMAGE_PER_LEVEL
		var ms_mult:  int   = _MC.get_milestone_multiplier(lvl, _BC.MILESTONE_LEVELS, _BC.MILESTONE_MULTIPLIER_PER_REACHED)
		var hero_dmg: int   = maxi(1, int(base_pre) * ms_mult)

		var clicks:     int   = ceili(float(norm_hp) / float(hero_dmg))
		var manual_sec: float = float(clicks) / CLICKS_PER_SEC
		var boss_clicks: int  = ceili(float(boss_hp) / float(hero_dmg))
		var boss_sec:    float = float(boss_clicks) / CLICKS_PER_SEC
		var feasible: bool    = boss_sec <= _BC.BOSS_TIME_LIMIT
		var is_actual_boss: bool = (lvl % _ZC.BOSS_LEVEL_INTERVAL == 0)

		var result_str: String
		if not is_actual_boss:
			result_str = "(no boss)"
		elif feasible:
			result_str = "OK (%.0fs)" % boss_sec
		else:
			result_str = "FAIL (%.0fs > %ds)" % [boss_sec, int(_BC.BOSS_TIME_LIMIT)]

		_ln(_row([
			_rj(str(lvl), 5), _rj(_fn(norm_hp), 9), _rj(_fn(norm_rwd), 8),
			_rj(_fn(hero_dmg), 9), _rj(str(clicks), 7), _rj("%.1fs" % manual_sec, 8),
			_rj(_fn(boss_hp), 9), _rj("%.0fs" % boss_sec, 9), result_str,
		]))

		_csv_append("combat", lvl, norm_hp, norm_rwd, 0, hero_dmg, 0, manual_sec,
			"boss_sec=%.1f feasible=%s" % [boss_sec, str(feasible)])

	_ln("")
	_ln("  NOTE: All FAIL results are expected at higher levels — partner DPS makes them feasible in practice.")


# ==========================================================================
#  SECTION 5 — Prestige Timing
# ==========================================================================

func _section_prestige() -> void:
	_header("SECTION 5 — Prestige Timing Indicators")
	_ln("  PRESTIGE_REQUIRED_LEVEL     = %d" % _BC.PRESTIGE_REQUIRED_LEVEL)
	_ln("  PRESTIGE_CHARACTER_INTERVAL = %.0f" % _BC.PRESTIGE_CHARACTER_INTERVAL)
	_ln("  DAMAGE_TALENT_BONUS        = %d%% per talent level" % _BC.PRESTIGE_DAMAGE_TALENT_BONUS_PERCENT_PER_LEVEL)
	_ln("  GOLD_TALENT_BONUS          = %d%% per talent level" % _BC.PRESTIGE_GOLD_TALENT_BONUS_PERCENT_PER_LEVEL)
	_ln("  UTILITY_TALENT_BONUS       = %d%% per talent level" % _BC.PRESTIGE_UTILITY_TALENT_BONUS_PERCENT_PER_LEVEL)
	_ln("  TALENT_COST                = ceil(%d * %.2f^current_level)" % [_BC.PRESTIGE_TALENT_BASE_COST, _BC.PRESTIGE_TALENT_COST_GROWTH])
	_ln("")
	_ln("  Stage pts   = int(game_level  / PRESTIGE_REQUIRED_LEVEL)")
	_ln("  Char pts    = int(hero_level  / PRESTIGE_CHARACTER_INTERVAL)")
	_ln("  Total reward = stage_pts + char_pts  (must be > 0 to unlock prestige button)")
	_ln("")

	_ln("  Stage points by game level:")
	_ln(_row([_rj("GameLevel", 12), _rj("StagePts", 12), _lj("CanPrestige", 14)]))
	_div("-", 38)
	for lvl: int in ([50, 99, 100, 199, 200] as Array[int]):
		var pts: int = int(lvl / float(_BC.PRESTIGE_REQUIRED_LEVEL))
		_ln(_row([_rj(str(lvl), 12), _rj(str(pts), 12), _lj(("YES" if pts > 0 else "NO"), 14)]))
		_csv_append("prestige_stage", lvl, 0, pts, 0, 0, 0, 0.0, "stage_pts=%d" % pts)

	_ln("")
	_ln("  Character points by hero level:")
	_ln(_row([_rj("HeroLevel", 12), _rj("CharPts", 12)]))
	_div("-", 24)
	for clvl: int in ([100, 199, 200, 399, 400] as Array[int]):
		var pts: int = int(clvl / _BC.PRESTIGE_CHARACTER_INTERVAL)
		_ln(_row([_rj(str(clvl), 12), _rj(str(pts), 12)]))
		_csv_append("prestige_char", clvl, 0, pts, 0, 0, 0, 0.0, "char_pts=%d" % pts)

	_ln("")
	_ln("  First prestige is later now: usually level %d (1 stage point), unless hero reaches level %.0f first." % [
		_BC.PRESTIGE_REQUIRED_LEVEL, _BC.PRESTIGE_CHARACTER_INTERVAL])
	_ln("  Second stage point at level %d." % (_BC.PRESTIGE_REQUIRED_LEVEL * 2))
	_warn("Prestige timing changed: first prestige now occurs later, probably level %d unless hero reaches %.0f." % [
		_BC.PRESTIGE_REQUIRED_LEVEL, _BC.PRESTIGE_CHARACTER_INTERVAL])

	_ln("")
	_ln("  Prestige talent cost examples:")
	_ln(_row([_rj("Copy", 8), _rj("Cost", 8)]))
	_div("-", 18)
	for copy: int in range(1, 6):
		var cost: int = _prestige_talent_cost_for_level(copy - 1)
		_ln(_row([_rj(str(copy), 8), _rj(str(cost), 8)]))
		_csv_append("prestige_talent_cost", copy, 0, 0, cost, 0, 0, 0.0, "copy=%d cost=%d" % [copy, cost])

	_ln("")
	_ln("  Prestige talent bonuses:")
	_ln(_row([_lj("Talent", 22), _rj("Type", 18), _rj("PerCopy", 9)]))
	_div("-", 54)
	for i: int in range(_PRC.get_talent_count()):
		var effect_type: String = _PRC.get_effect_type(i)
		var bonus: int = _prestige_talent_bonus_percent_per_level(i)
		_ln(_row([_lj(_PRC.get_talent_name(i), 22), _rj(effect_type, 18), _rj("%d%%" % bonus, 9)]))
		_csv_append("prestige_talent_bonus", i + 1, 0, 0, 0, bonus, 0, 0.0, "talent=%s effect_type=%s per_copy=%d" % [_PRC.get_talent_name(i), effect_type, bonus])

	_validate_prestige_formulas()

	if _BC.PRESTIGE_REQUIRED_LEVEL < 30:
		_warn("PRESTIGE_REQUIRED_LEVEL=%d is very low — players may prestige before seeing much content" % _BC.PRESTIGE_REQUIRED_LEVEL)
	elif _BC.PRESTIGE_REQUIRED_LEVEL > 150:
		_warn("PRESTIGE_REQUIRED_LEVEL=%d is high — first prestige loop will be very long" % _BC.PRESTIGE_REQUIRED_LEVEL)


# ==========================================================================
#  SECTION 6 — Progression Simulation
# ==========================================================================
#
#  Assumptions:
#    - Fresh ClickerState, no save loaded, no save written.
#    - Manual clicking at SIM_CLICKS_PER_SEC (6) clicks/sec, continuous.
#    - Partner DPS is continuous (tick-based DPS folded into total DPS).
#    - Elites disabled (elite_spawn_chance=0) for deterministic output.
#    - Autoclick/abilities ignored (not purchased).
#    - Shop/gems ignored.
#    - Prestige talents ignored (no prestige loop).
#    - Auto-stage-advance ON (player advances immediately after clearing each level).
#    - Greedy balanced purchase strategy: best DPS-per-gold between hero and partners;
#      buildings bought opportunistically when cheap relative to gold held.
#    - Bosses must die within BalanceConfig.BOSS_TIME_LIMIT or simulation stops.

func _section_progression_simulation() -> void:
	_run_profiled_progression_simulations()
	return

	_header("SECTION 6 — Progression Simulation  (balanced greedy, no elites/abilities)")
	_ln("  Assumptions: 6 clicks/sec, partner DPS continuous, no elites, no abilities,")
	_ln("  no shop, no prestige talents. Purchases every %.0fs sim-time." % SIM_PURCHASE_INTERVAL_SEC)
	_ln("")
	_ln(_row([
		_rj("Time",   8), _rj("Lvl",  5), _rj("Hero",    6),
		_rj("Gold",   9), _rj("ClickDmg", 10), _rj("PartDPS", 10),
		_rj("TotDPS", 10), _rj("HP",  10), _rj("Reward",  8),
		_rj("TTK",    7), "Note",
	]))
	_div("-", 113)

	# --- State setup ---
	var state: _CS = _CS.new()
	state.elite_spawn_chance = 0.0

	# --- Per-partner / per-building tracking arrays (modified in-place by _sim_do_purchases) ---
	var sim_partner_counts: Array = []
	for _pi in range(_BC.PARTNER_DPS_VALUES.size()):
		sim_partner_counts.append(0)
	var sim_building_counts: Array = []
	for _bi in range(state.building_counts.size()):
		sim_building_counts.append(0)

	# --- Scalar tracking ---
	var sim_time: float = 0.0
	var last_purchase_time: float = -SIM_PURCHASE_INTERVAL_SEC
	var total_hero_buys:          int = 0
	var total_partner_buys:       int = 0
	var total_building_buys:      int = 0
	var total_gold_spent_hero:     int = 0
	var total_gold_spent_partners: int = 0
	var total_gold_spent_buildings:int = 0
	var last_purchase_cost: int = 0
	var last_purchase_type: String = ""
	var last_purchase_id:   int = -1
	var purchase_count:     int = 0
	var stopped_reason:     String = "reached_max_seconds"

	var level_times:  Dictionary = {}
	var reported_set: Dictionary = {}

	var boss_wall_level:       int   = -1
	var boss_wall_dps_needed:  float = 0.0
	var boss_wall_dps_actual:  float = 0.0
	var boss_wall_manual_dps:  float = 0.0
	var boss_wall_partner_dps: float = 0.0
	var boss_wall_hero_level:  int   = 0
	var boss_wall_gold:        int   = 0
	var boss_wall_hp:          int   = 0
	var boss_wall_reward:      int   = 0
	var boss_wall_ttk:         float = 0.0

	var first_prestige_time:    float = -1.0
	var first_prestige_reward:  int   = 0
	var hero_level_at_prestige: int   = 0
	var partner_dps_at_prestige:int   = 0

	var reached_level: int = 1

	# One-shot warning flags
	var warned_ttk_early:    bool = false
	var warned_ttk_mid:      bool = false
	var warned_ttk_late:     bool = false
	var warned_no_partner:   bool = false
	var warned_hero_dom:     bool = false
	var warned_partner_early:bool = false

	# Snapshot of last purchase made (for boss-wall "last purchase before wall" row)
	var last_purchase_info: Dictionary = {}

	# --- Main simulation loop ---
	while sim_time < SIM_MAX_SECONDS and state.current_level <= SIM_MAX_LEVEL:
		var lv: int = state.current_level
		reached_level = lv

		if not level_times.has(lv):
			level_times[lv] = sim_time

		# Purchase tick
		if sim_time - last_purchase_time >= SIM_PURCHASE_INTERVAL_SEC:
			last_purchase_time = sim_time
			var pr: Dictionary = _sim_do_purchases(state, sim_partner_counts, sim_building_counts)
			total_hero_buys     += int(pr.hero_buys)
			total_partner_buys  += int(pr.partner_buys)
			total_building_buys += int(pr.building_buys)
			total_gold_spent_hero      += int(pr.gold_spent_hero)
			total_gold_spent_partners  += int(pr.gold_spent_partners)
			total_gold_spent_buildings += int(pr.gold_spent_buildings)
			if str(pr.last_type) != "":
				last_purchase_type = str(pr.last_type)
				last_purchase_id   = int(pr.last_id)
				last_purchase_cost = int(pr.last_cost)

			# DPS snapshot after all purchases this tick
			var post_mdps: float = float(state.get_current_click_damage()) * SIM_CLICKS_PER_SEC
			var post_pdps: float = float(state.get_final_partner_dps(true))
			var post_tdps: float = post_mdps + post_pdps

			# Process per-purchase log
			var running_ptotal: int = total_partner_buys - int(pr.partner_buys)
			for p_entry in pr.purchases:
				purchase_count += 1
				var ptype: String = str(p_entry.get("type", ""))
				if ptype == "partner":
					running_ptotal += 1

				var should_log: bool = SIM_LOG_ALL_PURCHASES
				if not should_log:
					if ptype == "hero":
						var oh: int = int(p_entry.get("old_val", 0))
						var nh: int = int(p_entry.get("new_val", 0))
						for m: int in SIM_HERO_LOG_MILESTONES:
							if oh < m and nh >= m:
								should_log = true
					elif ptype == "partner":
						if int(p_entry.get("old_val", 1)) == 0:
							should_log = true
						for m: int in SIM_PARTNER_LOG_MILESTONES:
							if running_ptotal - 1 < m and running_ptotal >= m:
								should_log = true
					elif ptype == "building":
						if int(p_entry.get("old_val", 1)) == 0:
							should_log = true
					if purchase_count % 10 == 0:
						should_log = true

				if should_log:
					_csv_append(
						"simulation_purchase", lv,
						0, 0, int(p_entry.get("cost", 0)),
						state.get_current_click_damage(),
						int(post_tdps), 0.0,
						"sim_time=%.0f purchase_type=%s purchase_id=%d old_val=%d new_val=%d gold_after=%d hero_level=%d partner_dps=%d total_dps=%d" % [
							sim_time, ptype,
							int(p_entry.get("id", -1)),
							int(p_entry.get("old_val", 0)),
							int(p_entry.get("new_val", 0)),
							state.gold, state.character_level,
							int(post_pdps), int(post_tdps),
						]
					)
				last_purchase_info = {
					"type":       ptype,
					"id":         int(p_entry.get("id", -1)),
					"cost":       int(p_entry.get("cost", 0)),
					"game_level": lv,
					"sim_time":   sim_time,
					"hero_level": state.character_level,
					"gold":       state.gold,
					"partner_dps":int(post_pdps),
					"total_dps":  int(post_tdps),
				}

		# Prestige check (first occurrence only)
		if first_prestige_time < 0.0 and state.can_prestige():
			first_prestige_time    = sim_time
			first_prestige_reward  = state.get_prestige_reward()
			hero_level_at_prestige = state.character_level
			partner_dps_at_prestige= state.get_final_partner_dps(false)

		# Compute combat stats for this enemy
		var manual_dps:  float = float(state.get_current_click_damage()) * SIM_CLICKS_PER_SEC
		var partner_dps: float = float(state.get_final_partner_dps(true))
		var total_dps:   float = manual_dps + partner_dps
		var enemy_hp:    int   = state.target_max_hp

		if total_dps <= 0.0:
			_warn("Simulation: total DPS is 0 at level %d — infinite loop guard triggered" % lv)
			stopped_reason = "no_damage"
			break

		var kill_time: float = float(enemy_hp) / total_dps

		# Boss wall check
		if state.is_boss_level and kill_time > state.boss_time_limit:
			boss_wall_level      = lv
			boss_wall_dps_needed = float(enemy_hp) / state.boss_time_limit
			boss_wall_dps_actual = total_dps
			boss_wall_manual_dps = manual_dps
			boss_wall_partner_dps= partner_dps
			boss_wall_hero_level = state.character_level
			boss_wall_gold       = state.gold
			boss_wall_hp         = enemy_hp
			boss_wall_reward     = state.reward_gold
			boss_wall_ttk        = kill_time
			stopped_reason       = "boss_wall"
			var missing_dps: float = maxf(boss_wall_dps_needed - total_dps, 0.0)
			var missing_pct: float = missing_dps / boss_wall_dps_needed * 100.0 if boss_wall_dps_needed > 0.0 else 0.0
			_ln("")
			_ln("  *** BOSS WALL at level %d ***" % lv)
			_ln("    Required DPS  : %s  (%.0fs limit)" % [_fn(int(boss_wall_dps_needed)), state.boss_time_limit])
			_ln("    Actual DPS    : %s  (click %s + partner %s)" % [
				_fn(int(total_dps)), _fn(int(manual_dps)), _fn(int(partner_dps))])
			_ln("    Missing DPS   : %s  (%.1f%%)" % [_fn(int(missing_dps)), missing_pct])
			_ln("    Hero level    : %d" % state.character_level)
			_ln("    Gold held     : %s" % _fn(state.gold))
			# Log last purchase before boss wall if available
			if not last_purchase_info.is_empty():
				_csv_append(
					"simulation_purchase", lv,
					0, 0, int(last_purchase_info.get("cost", 0)),
					state.get_current_click_damage(),
					int(total_dps), 0.0,
					"sim_time=%.0f purchase_type=%s purchase_id=%d gold_after=%d hero_level=%d partner_dps=%d total_dps=%d last_before_boss_wall=true" % [
						float(last_purchase_info.get("sim_time", 0.0)),
						str(last_purchase_info.get("type", "")),
						int(last_purchase_info.get("id", -1)),
						int(last_purchase_info.get("gold", 0)),
						int(last_purchase_info.get("hero_level", 0)),
						int(last_purchase_info.get("partner_dps", 0)),
						int(last_purchase_info.get("total_dps", 0)),
					]
				)
			break

		# One-shot warnings — TTK thresholds
		if not state.is_boss_level:
			if lv < 20 and kill_time > 10.0 and not warned_ttk_early:
				_warn("Simulation: normal TTK %.1fs > 10s before level 20 (at level %d)" % [kill_time, lv])
				warned_ttk_early = true
			if lv < 50 and kill_time > 30.0 and not warned_ttk_mid:
				_warn("Simulation: normal TTK %.1fs > 30s before level 50 (at level %d)" % [kill_time, lv])
				warned_ttk_mid = true
			if lv < 100 and kill_time > 60.0 and not warned_ttk_late:
				_warn("Simulation: normal TTK %.1fs > 60s before level 100 (at level %d)" % [kill_time, lv])
				warned_ttk_late = true

		# DPS composition warnings
		if lv >= 15 and partner_dps <= 0.0 and not warned_no_partner:
			_warn("Simulation: partner DPS is 0 after level 15 — greedy strategy never purchased partners")
			warned_no_partner = true
		if total_dps > 0.0:
			var hero_ratio: float = manual_dps / total_dps
			if lv > 25 and hero_ratio > 0.95 and not warned_hero_dom:
				_warn("Simulation: hero-only click DPS >95%% of total DPS past level 25 — partner investment too low")
				warned_hero_dom = true
			if lv < 10 and hero_ratio < 0.10 and partner_dps > 0.0 and not warned_partner_early:
				_warn("Simulation: partner DPS >90%% of total DPS before level 10 — partners may be too cheap early")
				warned_partner_early = true

		# Report row on first visit to each milestone level
		var last_purchase_tag: String = "%s#%d" % [last_purchase_type, last_purchase_id] if last_purchase_type != "" else "none"
		if SIM_REPORT_LEVELS.has(lv) and not reported_set.has(lv):
			reported_set[lv] = true
			var note: String = "BOSS" if state.is_boss_level else ""
			if first_prestige_time >= 0.0 and first_prestige_time == sim_time:
				note = note + (" " if note != "" else "") + "PRESTIGE_UNLOCKED"
			_ln(_row([
				_rj(_fmt_time(sim_time), 8),
				_rj(str(lv), 5),
				_rj(str(state.character_level), 6),
				_rj(_fn(state.gold), 9),
				_rj(_fn(state.get_current_click_damage()), 10),
				_rj(_fn(int(partner_dps)), 10),
				_rj(_fn(int(total_dps)), 10),
				_rj(_fn(enemy_hp), 10),
				_rj(_fn(state.reward_gold), 8),
				_rj("%.1fs" % kill_time, 7),
				note,
			]))
			_csv_append(
				"simulation", lv, enemy_hp, state.reward_gold,
				last_purchase_cost,
				state.get_current_click_damage(),
				int(total_dps), kill_time,
				"sim_time=%.0f hero=%d gold=%d click_damage=%d manual_dps=%d partner_dps=%d total_dps=%d boss_wall=%s prestige_rwd=%d total_hero_purchases=%d total_partner_purchases=%d total_building_purchases=%d last_purchase=%s" % [
					sim_time, state.character_level, state.gold,
					state.get_current_click_damage(),
					int(manual_dps), int(partner_dps), int(total_dps),
					("true" if boss_wall_level > 0 else "false"),
					first_prestige_reward,
					total_hero_buys, total_partner_buys, total_building_buys,
					last_purchase_tag,
				]
			)

		# Advance sim time, kill enemy, let state handle gold + level advancement
		sim_time += kill_time
		state.attack_with_damage(state.target_hp)
		state.resolve_defeated_target()

	# Post-loop: finalize stopped_reason
	if stopped_reason == "reached_max_seconds" and state.current_level > SIM_MAX_LEVEL:
		stopped_reason = "reached_target_level"

	# --- Simulation summary (stdout) ---
	_ln("")
	_ln("  === SIMULATION SUMMARY ===")
	_ln("  Strategy           : balanced greedy (best DPS/gold between hero & partners)")
	_ln("  Reached level      : %d" % reached_level)
	_ln("  Total sim time     : %s (%.0f s)" % [_fmt_time(sim_time), sim_time])
	_ln("  Stopped reason     : %s" % stopped_reason)

	if boss_wall_level > 0:
		_ln("  First boss wall    : level %d  (need %s DPS, had %s DPS)" % [
			boss_wall_level, _fn(int(boss_wall_dps_needed)), _fn(int(boss_wall_dps_actual))])
	else:
		_ln("  First boss wall    : none within simulation range")

	for ml: int in [10, 20, 50, 100]:
		if level_times.has(ml):
			_ln("  Time to level %-5d: %s" % [ml, _fmt_time(float(level_times[ml]))])
		else:
			_ln("  Time to level %-5d: not reached" % ml)

	if first_prestige_time >= 0.0:
		_ln("  First prestige     : %s  (reward=%d, hero=%d, partner_dps=%s)" % [
			_fmt_time(first_prestige_time), first_prestige_reward,
			hero_level_at_prestige, _fn(partner_dps_at_prestige)])
	else:
		_ln("  First prestige     : not reached within simulation")

	_ln("  Total purchases    : hero=%d  partners=%d  buildings=%d" % [
		total_hero_buys, total_partner_buys, total_building_buys])
	_ln("  Gold spent         : hero=%s  partners=%s  buildings=%s" % [
		_fn(total_gold_spent_hero), _fn(total_gold_spent_partners), _fn(total_gold_spent_buildings)])

	# --- CSV: simulation_summary ---
	var final_mdps: float = float(state.get_current_click_damage()) * SIM_CLICKS_PER_SEC
	var final_pdps: float = float(state.get_final_partner_dps(true))
	var final_tdps: float = final_mdps + final_pdps
	_csv_append(
		"simulation_summary", reached_level,
		state.target_max_hp, state.reward_gold, 0,
		state.get_current_click_damage(), int(final_tdps), sim_time,
		"reached_level=%d sim_time=%.0f hero=%d gold=%d click=%d manual_dps=%d partner_dps=%d total_dps=%d prestige_reward=%d total_hero_purchases=%d total_partner_purchases=%d total_building_purchases=%d stopped_reason=%s" % [
			reached_level, sim_time,
			state.character_level, state.gold,
			state.get_current_click_damage(),
			int(final_mdps), int(final_pdps), int(final_tdps),
			first_prestige_reward,
			total_hero_buys, total_partner_buys, total_building_buys,
			stopped_reason,
		]
	)

	# --- CSV: simulation_boss_wall ---
	if boss_wall_level > 0:
		var req_dps: float = boss_wall_dps_needed
		var miss_dps: float = maxf(req_dps - boss_wall_dps_actual, 0.0)
		var miss_pct: float = miss_dps / req_dps * 100.0 if req_dps > 0.0 else 0.0
		_csv_append(
			"simulation_boss_wall", boss_wall_level,
			boss_wall_hp, boss_wall_reward, 0,
			int(boss_wall_manual_dps), int(boss_wall_dps_actual), boss_wall_ttk,
			"boss_level=%d boss_hp=%d boss_time_limit=%.0f boss_ttk=%.1f required_dps=%d current_total_dps=%d missing_dps=%d missing_dps_percent=%.1f hero_level=%d gold=%d partner_dps=%d manual_dps=%d" % [
				boss_wall_level, boss_wall_hp,
				float(_BC.BOSS_TIME_LIMIT), boss_wall_ttk,
				int(req_dps), int(boss_wall_dps_actual),
				int(miss_dps), miss_pct,
				boss_wall_hero_level, boss_wall_gold,
				int(boss_wall_partner_dps), int(boss_wall_manual_dps),
			]
		)

	# --- CSV: simulation_boss_wall_fix ---
	if boss_wall_level > 0:
		var bwf_req_dps: float = boss_wall_dps_needed
		var bwf_miss_dps: float = maxf(bwf_req_dps - boss_wall_dps_actual, 0.0)
		var bwf_miss_pct: float = bwf_miss_dps / bwf_req_dps * 100.0 if bwf_req_dps > 0.0 else 0.0
		var bwf_hp_mult_to_pass: float = float(_BC.BOSS_HP_MULTIPLIER) * (float(_BC.BOSS_TIME_LIMIT) / boss_wall_ttk) if boss_wall_ttk > 0.0 else 0.0
		var bwf_req_partner_mult: float = 0.0
		if boss_wall_partner_dps > 0.0:
			var bwf_req_pdps: float = maxf(bwf_req_dps - boss_wall_manual_dps, 0.0)
			bwf_req_partner_mult = bwf_req_pdps / boss_wall_partner_dps
		_csv_append(
			"simulation_boss_wall_fix", boss_wall_level,
			boss_wall_hp, 0, 0,
			int(boss_wall_manual_dps), int(boss_wall_dps_actual), boss_wall_ttk,
			"required_dps=%d current_total_dps=%d missing_dps=%d missing_dps_percent=%.1f boss_hp_multiplier_current=%d boss_hp_multiplier_to_pass=%.1f boss_timer_current=%.0f boss_timer_to_pass=%.1f early_partner_dps_multiplier_to_pass=%.2f" % [
				int(bwf_req_dps), int(boss_wall_dps_actual),
				int(bwf_miss_dps), bwf_miss_pct,
				_BC.BOSS_HP_MULTIPLIER,
				bwf_hp_mult_to_pass,
				float(_BC.BOSS_TIME_LIMIT),
				boss_wall_ttk,
				bwf_req_partner_mult,
			]
		)

	# --- CSV: simulation_partner_summary ---
	var total_pdps_for_share: int = 0
	for pi: int in range(state.partner_counts.size()):
		total_pdps_for_share += state.get_partner_tier_total_dps(pi)
	var any_partner_summary: bool = false
	for pi: int in range(state.partner_counts.size()):
		if state.partner_counts[pi] > 0:
			any_partner_summary = true
			var pname: String = _partner_name(pi)
			var base_dps: int = _BC.PARTNER_DPS_VALUES[pi] if pi < _BC.PARTNER_DPS_VALUES.size() else 0
			var ms_mult: int = state.get_partner_milestone_multiplier(pi)
			var tier_dps: int = state.get_partner_tier_total_dps(pi)
			var next_cost: int = state.partner_purchase_costs[pi] if pi < state.partner_purchase_costs.size() else _partner_cost(pi, state.partner_counts[pi])
			var share_pct: float = float(tier_dps) / float(total_pdps_for_share) * 100.0 if total_pdps_for_share > 0 else 0.0
			_csv_append(
				"simulation_partner_summary", pi + 1,
				0, 0, next_cost, 0, tier_dps, 0.0,
				"partner_name=%s owned_count=%d base_dps=%d milestone_multiplier=%d tier_total_dps=%d next_cost=%d dps_share_percent=%.1f" % [
					pname, state.partner_counts[pi], base_dps, ms_mult, tier_dps, next_cost, share_pct,
				]
			)

	# --- CSV: simulation_building_summary ---
	var any_building_summary: bool = false
	for bi: int in range(sim_building_counts.size()):
		if sim_building_counts[bi] > 0:
			any_building_summary = true
			var next_bc: int = state.get_building_bulk_display_cost(bi, "x1")
			var bonus_pct: int = state.get_building_total_bonus_percent(bi)
			_csv_append(
				"simulation_building_summary", bi + 1,
				0, 0, next_bc, 0, 0, 0.0,
				"building_name=building_%d owned_count=%d next_cost=%d bonus_percent=%d" % [
					bi + 1, int(sim_building_counts[bi]), next_bc, bonus_pct,
				]
			)
	if not any_building_summary:
		_csv_append(
			"simulation_building_summary", 0,
			0, 0, 0, 0, 0, 0.0,
			"no_buildings_purchased"
		)

	# --- CSV: simulation_timing_summary ---
	for ml: int in ([5, 10, 15, 20, 25, 30] as Array[int]):
		var ml_t: float = float(level_times.get(ml, -1.0))
		var ml_t_str: String = ("%.0f" % ml_t) if ml_t >= 0.0 else "not_reached"
		_csv_append(
			"simulation_timing_summary", ml,
			0, 0, 0, 0, 0, maxf(ml_t, 0.0),
			"time_to_level_%d=%s" % [ml, ml_t_str]
		)
	var prestige_t_str: String = ("%.0f" % first_prestige_time) if first_prestige_time >= 0.0 else "not_reached"
	_csv_append(
		"simulation_timing_summary", 0,
		0, 0, 0, 0, 0, maxf(first_prestige_time, 0.0),
		"first_prestige_available_time=%s first_prestige_reward=%d" % [prestige_t_str, first_prestige_reward]
	)

	# --- Simulation-derived warnings ---
	if boss_wall_level > 0 and boss_wall_level < 20:
		_warn("Simulation: boss wall at level %d (before level 20) — DPS ramp-up is too slow in early game" % boss_wall_level)

	if boss_wall_level > 0 and boss_wall_level <= 30:
		var rq: float = boss_wall_dps_needed
		var ms: float = maxf(rq - boss_wall_dps_actual, 0.0)
		var mp: float = ms / rq * 100.0 if rq > 0.0 else 0.0
		_warn("Early boss wall at level %d. Required DPS %s, current DPS %s, missing %.1f%%." % [
			boss_wall_level, _fn(int(rq)), _fn(int(boss_wall_dps_actual)), mp])

	if level_times.has(50) and float(level_times[50]) > 7200.0:
		_warn("Simulation: level 50 takes %.0f min (> 2 hours) — early-game progression too slow" % (float(level_times[50]) / 60.0))

	if first_prestige_time < 0.0:
		_warn("First prestige not reached. Simulation stopped at level %d after %.0f seconds." % [reached_level, sim_time])
		_warn("Simulation: first prestige not reached within %.0f min — check PRESTIGE_REQUIRED_LEVEL or DPS scaling" % (SIM_MAX_SECONDS / 60.0))
		_warn("Simulation active_6cps: first prestige not reached within SIM_MAX_SECONDS=%.0fs." % SIM_MAX_SECONDS)

	if not any_partner_summary and total_partner_buys > 0:
		_warn("Simulation: total_partner_purchases=%d but simulation_partner_summary is empty — partner tracking mismatch" % total_partner_buys)

	if not any_building_summary and total_building_buys > 0:
		_warn("Simulation: total_building_purchases=%d but simulation_building_summary is empty — building tracking mismatch" % total_building_buys)

	if boss_wall_level > 0:
		var bw_miss: float = maxf(boss_wall_dps_needed - boss_wall_dps_actual, 0.0)
		var bw_miss_pct: float = bw_miss / boss_wall_dps_needed * 100.0 if boss_wall_dps_needed > 0.0 else 0.0
		if bw_miss_pct > 0.0 and bw_miss_pct < 25.0:
			_warn("Simulation: boss wall at level %d is a TUNING issue — only %.1f%% DPS missing (<25%%) — small balance tweak will fix" % [boss_wall_level, bw_miss_pct])
		if boss_wall_level <= 30 and first_prestige_time < 0.0:
			_warn("Simulation: boss wall at level %d occurs before first prestige is reachable — player is stuck with no recovery option" % boss_wall_level)
		elif boss_wall_level <= 30 and boss_wall_level < _BC.PRESTIGE_REQUIRED_LEVEL:
			_warn("Simulation: boss wall at level %d is before PRESTIGE_REQUIRED_LEVEL=%d — player cannot prestige to recover" % [boss_wall_level, _BC.PRESTIGE_REQUIRED_LEVEL])


# --- Greedy purchase helper ---
# sim_partner_counts / sim_building_counts are modified in-place (reference pass).
# Returns per-purchase log entries plus gold-spent totals.

func _sim_do_purchases(state: _CS, sim_partner_counts: Array, sim_building_counts: Array) -> Dictionary:
	var hero_buys:            int = 0
	var partner_buys:         int = 0
	var building_buys:        int = 0
	var last_cost:            int = 0
	var last_type:            String = ""
	var last_id:              int = -1
	var gold_spent_hero:      int = 0
	var gold_spent_partners:  int = 0
	var gold_spent_buildings: int = 0
	var purchases: Array = []

	for _safety in range(50):
		var best_value: float = 0.0
		var best_type:  String = ""
		var best_idx:   int = -1
		var best_cost:  int = 0

		# Hero upgrade: value = click_dps_gain / cost
		if state.can_afford_character_level_bulk("x1"):
			var cost: int = state.get_character_level_bulk_display_cost("x1")
			if cost > 0:
				var cur_cdps: float = float(state.get_current_click_damage()) * SIM_CLICKS_PER_SEC
				var nxt_cdps: float = float(state.get_click_damage_for_character_level(state.character_level + 1)) * SIM_CLICKS_PER_SEC
				var gain: float = maxf(nxt_cdps - cur_cdps, 0.5)
				var v: float = gain / float(cost)
				if v > best_value:
					best_value = v
					best_type  = "hero"
					best_cost  = cost

		# Partner upgrades: value = base_dps_gain / cost
		for i: int in range(state.visible_partner_count):
			if state.can_afford_partner_bulk(i, "x1"):
				var cost: int = state.get_partner_bulk_display_cost(i, "x1")
				if cost > 0:
					var gain: float = maxf(float(state.get_partner_bulk_dps_gain(i, "x1")), 0.5)
					var v: float = gain / float(cost)
					if v > best_value:
						best_value = v
						best_type  = "partner"
						best_idx   = i
						best_cost  = cost

		# Buildings: buy cheapest if it costs < 15% of current gold
		if state.gold > 0:
			var cur_tdps: float = float(state.get_current_click_damage()) * SIM_CLICKS_PER_SEC + float(state.get_final_partner_dps(false))
			for b: int in range(state.building_counts.size()):
				if state.can_afford_building_bulk(b, "x1"):
					var cost: int = state.get_building_bulk_display_cost(b, "x1")
					if cost > 0 and float(cost) <= float(state.gold) * 0.15:
						var dps_equiv: float = maxf(cur_tdps * 0.01, 0.5)
						var v: float = dps_equiv / float(cost)
						if v > best_value:
							best_value = v
							best_type  = "building"
							best_idx   = b
							best_cost  = cost

		if best_type.is_empty():
			break

		match best_type:
			"hero":
				var old_v: int = state.character_level
				state.buy_character_level_upgrades("x1")
				hero_buys        += 1
				last_cost         = best_cost
				last_type         = "hero"
				last_id           = -1
				gold_spent_hero  += best_cost
				purchases.append({"type": "hero", "id": -1, "cost": best_cost,
					"old_val": old_v, "new_val": state.character_level})
			"partner":
				var old_v: int = sim_partner_counts[best_idx] if best_idx < sim_partner_counts.size() else 0
				state.buy_partners(best_idx, "x1")
				if best_idx < sim_partner_counts.size():
					sim_partner_counts[best_idx] += 1
				var new_v: int = sim_partner_counts[best_idx] if best_idx < sim_partner_counts.size() else old_v + 1
				partner_buys        += 1
				last_cost            = best_cost
				last_type            = "partner"
				last_id              = best_idx
				gold_spent_partners += best_cost
				purchases.append({"type": "partner", "id": best_idx, "cost": best_cost,
					"old_val": old_v, "new_val": new_v})
			"building":
				var old_v: int = sim_building_counts[best_idx] if best_idx < sim_building_counts.size() else 0
				state.buy_buildings(best_idx, "x1")
				if best_idx < sim_building_counts.size():
					sim_building_counts[best_idx] += 1
				var new_v: int = sim_building_counts[best_idx] if best_idx < sim_building_counts.size() else old_v + 1
				building_buys        += 1
				last_cost             = best_cost
				last_type             = "building"
				last_id               = best_idx
				gold_spent_buildings += best_cost
				purchases.append({"type": "building", "id": best_idx, "cost": best_cost,
					"old_val": old_v, "new_val": new_v})

	return {
		"hero_buys":            hero_buys,
		"partner_buys":         partner_buys,
		"building_buys":        building_buys,
		"last_cost":            last_cost,
		"last_type":            last_type,
		"last_id":              last_id,
		"gold_spent_hero":      gold_spent_hero,
		"gold_spent_partners":  gold_spent_partners,
		"gold_spent_buildings": gold_spent_buildings,
		"purchases":            purchases,
	}


# ==========================================================================
#  SECTION 7 — Warnings Summary
# ==========================================================================

func _run_profiled_progression_simulations() -> void:
	_header("SECTION 6 — Progression Simulation  (profiled greedy, no elites)")
	_ln("  Default active profile: %.0f clicks/sec. Partner DPS is continuous; no shop, no prestige loop." % SIM_CLICKS_PER_SEC)
	_ln("  Profiles buy hero, partners, explicit buildings, abilities, and unlocked skills when enabled.")

	var profiles: Array[Dictionary] = [
		{"id": "active_6cps", "clicks_per_sec": 6.0, "abilities": true, "buildings": true, "skills": true},
		{"id": "active_no_abilities", "clicks_per_sec": 6.0, "abilities": false, "buildings": true, "skills": true},
		{"id": "semi_active_3cps", "clicks_per_sec": 3.0, "abilities": true, "buildings": true, "skills": true},
		{"id": "idle_0cps", "clicks_per_sec": 0.0, "abilities": true, "buildings": true, "skills": true},
	]

	var results: Array[Dictionary] = []
	for profile: Dictionary in profiles:
		var result: Dictionary = _run_progression_profile(profile)
		results.append(result)
		_live_profile_results[str(result.get("profile_id", ""))] = result

	_ln("")
	_ln("  === PROFILE COMPARISON ===")
	_ln(_row([
		_lj("Profile", 23), _rj("Reached", 8), _rj("Time", 8),
		_rj("Hero", 6), _rj("Click", 9), _rj("DPS", 10),
		_lj("BossWall", 10), "Stopped",
	]))
	_div("-", 92)
	for result: Dictionary in results:
		var pid: String = str(result.get("profile_id", ""))
		var wall_text: String = str(result.get("boss_wall_level", -1))
		if int(result.get("boss_wall_level", -1)) <= 0:
			wall_text = "none"
		_ln(_row([
			_lj(pid, 23),
			_rj(str(int(result.get("reached_level", 0))), 8),
			_rj(_fmt_time(float(result.get("sim_time", 0.0))), 8),
			_rj(str(int(result.get("hero_level", 0))), 6),
			_rj(_fn(int(result.get("click_damage", 0))), 9),
			_rj(_fn(int(result.get("total_dps", 0))), 10),
			_lj(wall_text, 10),
			str(result.get("stopped_reason", "")),
		]))
		_csv_append(
			"simulation_profile_comparison", int(result.get("reached_level", 0)),
			int(result.get("target_hp", 0)), int(result.get("reward_gold", 0)), 0,
			int(result.get("click_damage", 0)), int(result.get("total_dps", 0)),
			float(result.get("sim_time", 0.0)),
			"profile_id=%s cps=%.1f abilities=%s buildings=%s skills=%s boss_wall_level=%d stopped_reason=%s first_prestige_reward=%d" % [
				pid,
				float(result.get("clicks_per_sec", 0.0)),
				str(result.get("abilities_enabled", false)),
				str(result.get("buildings_enabled", false)),
				str(result.get("skills_enabled", false)),
				int(result.get("boss_wall_level", -1)),
				str(result.get("stopped_reason", "")),
				int(result.get("first_prestige_reward", 0)),
			]
		)


func _run_progression_profile(profile: Dictionary, scenario: Dictionary = {}, emit_live_output: bool = true, initial_overrides: Dictionary = {}) -> Dictionary:
	var profile_id: String = str(profile.get("id", "profile"))
	var clicks_per_sec: float = float(profile.get("clicks_per_sec", SIM_CLICKS_PER_SEC))
	var category: String = "simulation_%s" % profile_id
	var is_scenario: bool = not scenario.is_empty()
	var scenario_id: String = str(scenario.get("id", "baseline")) if is_scenario else ""
	var use_scenario_modifiers: bool = is_scenario and not _scenario_is_identity_baseline(scenario)
	var state: _CS = _CS.new()
	state.elite_spawn_chance = 0.0
	_sim_apply_initial_overrides(state, initial_overrides)

	if emit_live_output:
		_ln("")
		_ln("  --- Profile: %s ---" % profile_id)
		_ln("  Assumptions: %.1f clicks/sec, abilities=%s, buildings=%s, skills=%s. Purchases every %.0fs." % [
			clicks_per_sec, str(profile.get("abilities", true)), str(profile.get("buildings", true)),
			str(profile.get("skills", true)), SIM_PURCHASE_INTERVAL_SEC])

	var sim_time: float = 0.0
	var last_purchase_time: float = -SIM_PURCHASE_INTERVAL_SEC
	var reached_level: int = 1
	var stopped_reason: String = "reached_max_seconds"
	var level_times: Dictionary = {}
	var reported_set: Dictionary = {}
	var ability_state: Dictionary = _sim_new_ability_state()
	var ability_diagnostics: Dictionary = _sim_new_ability_diagnostics()
	var skill_spend: Dictionary = _sim_new_skill_spend()
	var ability_event_counts: Dictionary = {}
	var last_ability_events: Array[String] = []
	var last_purchase_cost: int = 0
	var last_purchase_type: String = ""
	var last_purchase_id: String = ""
	var purchase_count: int = 0
	var last_purchase_info: Dictionary = {}

	var total_hero_buys: int = 0
	var total_partner_buys: int = 0
	var total_building_buys: int = 0
	var total_ability_buys: int = 0
	var total_hero_skill_buys: int = 0
	var total_partner_skill_buys: int = 0
	var total_ability_skill_buys: int = 0
	var total_gold_spent_hero: int = 0
	var total_gold_spent_partners: int = 0
	var total_gold_spent_buildings: int = 0
	var total_gold_spent_abilities: int = 0
	var total_gold_spent_skills: int = 0

	var boss_wall_level: int = -1
	var boss_wall_dps_needed: float = 0.0
	var boss_wall_dps_actual: float = 0.0
	var boss_wall_manual_dps: float = 0.0
	var boss_wall_partner_dps: float = 0.0
	var boss_wall_ability_dps: float = 0.0
	var boss_wall_hero_level: int = 0
	var boss_wall_gold: int = 0
	var boss_wall_hp: int = 0
	var boss_wall_reward: int = 0
	var boss_wall_ttk: float = 0.0

	var first_prestige_time: float = -1.0
	var first_prestige_reward: int = 0

	while sim_time < SIM_MAX_SECONDS and state.current_level <= SIM_MAX_LEVEL:
		var lv: int = state.current_level
		reached_level = lv
		if not level_times.has(lv):
			level_times[lv] = sim_time

		if sim_time - last_purchase_time >= SIM_PURCHASE_INTERVAL_SEC:
			last_purchase_time = sim_time
			var pr: Dictionary = _sim_do_profile_purchases(state, profile, clicks_per_sec, scenario if use_scenario_modifiers else {})
			total_hero_buys += int(pr.get("hero_buys", 0))
			total_partner_buys += int(pr.get("partner_buys", 0))
			total_building_buys += int(pr.get("building_buys", 0))
			total_ability_buys += int(pr.get("ability_buys", 0))
			total_hero_skill_buys += int(pr.get("hero_skill_buys", 0))
			total_partner_skill_buys += int(pr.get("partner_skill_buys", 0))
			total_ability_skill_buys += int(pr.get("ability_skill_buys", 0))
			total_gold_spent_hero += int(pr.get("gold_spent_hero", 0))
			total_gold_spent_partners += int(pr.get("gold_spent_partners", 0))
			total_gold_spent_buildings += int(pr.get("gold_spent_buildings", 0))
			total_gold_spent_abilities += int(pr.get("gold_spent_abilities", 0))
			total_gold_spent_skills += int(pr.get("gold_spent_skills", 0))
			if str(pr.get("last_type", "")) != "":
				last_purchase_type = str(pr.get("last_type", ""))
				last_purchase_id = str(pr.get("last_id", ""))
				last_purchase_cost = int(pr.get("last_cost", 0))

			var post_stats: Dictionary = _sim_compute_profile_stats(state, profile, clicks_per_sec, sim_time, ability_state, scenario if use_scenario_modifiers else {})
			for p_entry in pr.get("purchases", []):
				purchase_count += 1
				var ptype: String = str(p_entry.get("type", ""))
				_sim_track_profile_purchase_diagnostics(p_entry, ability_diagnostics, skill_spend)
				var should_log: bool = SIM_LOG_ALL_PURCHASES or purchase_count % 10 == 0
				if ptype in ["building", "ability", "hero_skill", "partner_skill", "ability_skill"]:
					should_log = true
				if ptype == "hero":
					for m: int in SIM_HERO_LOG_MILESTONES:
						if int(p_entry.get("old_val", 0)) < m and int(p_entry.get("new_val", 0)) >= m:
							should_log = true
				if ptype == "partner":
					if int(p_entry.get("old_val", 0)) == 0:
						should_log = true
					for pm: int in SIM_PARTNER_LOG_MILESTONES:
						if int(p_entry.get("old_val", 0)) < pm and int(p_entry.get("new_val", 0)) >= pm:
							should_log = true

				if should_log and emit_live_output:
					_csv_append(
						category, lv, 0, 0, int(p_entry.get("cost", 0)),
						int(post_stats.get("click_damage", state.get_current_click_damage())), int(post_stats.get("total_dps", 0.0)), 0.0,
						"event=purchase profile_id=%s sim_time=%.0f purchase_type=%s purchase_id=%s old_val=%d new_val=%d gold_after=%d hero_level=%d total_dps=%d" % [
							profile_id, sim_time, ptype, str(p_entry.get("id", "")),
							int(p_entry.get("old_val", 0)), int(p_entry.get("new_val", 0)),
							state.gold, state.character_level, int(post_stats.get("total_dps", 0.0)),
						]
					)
				last_purchase_info = {
					"type": ptype,
					"id": str(p_entry.get("id", "")),
					"cost": int(p_entry.get("cost", 0)),
					"sim_time": sim_time,
					"hero_level": state.character_level,
					"gold": state.gold,
					"total_dps": int(post_stats.get("total_dps", 0.0)),
				}

		if first_prestige_time < 0.0 and state.can_prestige():
			first_prestige_time = sim_time
			first_prestige_reward = state.get_prestige_reward()

		last_ability_events = _sim_update_ability_usage(state, profile, sim_time, ability_state, ability_diagnostics, clicks_per_sec)
		for event_name: String in last_ability_events:
			ability_event_counts[event_name] = int(ability_event_counts.get(event_name, 0)) + 1

		var stats: Dictionary = _sim_compute_profile_stats(state, profile, clicks_per_sec, sim_time, ability_state, scenario if use_scenario_modifiers else {})
		var manual_dps: float = float(stats.get("manual_dps", 0.0))
		var partner_dps: float = float(stats.get("partner_dps", 0.0))
		var ability_dps: float = float(stats.get("ability_dps", 0.0))
		var total_dps: float = float(stats.get("total_dps", 0.0))
		var enemy_hp: int = _sim_profile_enemy_hp(state, scenario if use_scenario_modifiers else {})

		if total_dps <= 0.0:
			_warn("Simulation %s: total DPS is 0 at level %d — infinite loop guard triggered" % [profile_id, lv])
			stopped_reason = "no_damage"
			break

		var kill_time: float = float(enemy_hp) / total_dps
		if state.is_boss_level and kill_time > state.boss_time_limit:
			boss_wall_level = lv
			boss_wall_dps_needed = float(enemy_hp) / state.boss_time_limit
			boss_wall_dps_actual = total_dps
			boss_wall_manual_dps = manual_dps
			boss_wall_partner_dps = partner_dps
			boss_wall_ability_dps = ability_dps
			boss_wall_hero_level = state.character_level
			boss_wall_gold = state.gold
			boss_wall_hp = enemy_hp
			boss_wall_reward = state.reward_gold
			boss_wall_ttk = kill_time
			stopped_reason = "boss_wall"
			if not last_purchase_info.is_empty() and emit_live_output:
				_csv_append(category, lv, 0, 0, int(last_purchase_info.get("cost", 0)),
					int(stats.get("click_damage", state.get_current_click_damage())), int(total_dps), 0.0,
					"event=last_purchase_before_boss_wall profile_id=%s sim_time=%.0f purchase_type=%s purchase_id=%s gold_after=%d hero_level=%d total_dps=%d" % [
						profile_id, float(last_purchase_info.get("sim_time", 0.0)),
						str(last_purchase_info.get("type", "")), str(last_purchase_info.get("id", "")),
						int(last_purchase_info.get("gold", 0)), int(last_purchase_info.get("hero_level", 0)),
						int(last_purchase_info.get("total_dps", 0)),
					])
			break

		var last_purchase_tag: String = "%s#%s" % [last_purchase_type, last_purchase_id] if last_purchase_type != "" else "none"
		if emit_live_output and SIM_REPORT_LEVELS.has(lv) and not reported_set.has(lv):
			reported_set[lv] = true
			var note: String = "BOSS" if state.is_boss_level else ""
			if not last_ability_events.is_empty():
				note += (" " if note != "" else "") + "abilities=" + "|".join(PackedStringArray(last_ability_events))
			_ln(_row([
				_rj(_fmt_time(sim_time), 8), _rj(str(lv), 5), _rj(str(state.character_level), 6),
				_rj(_fn(state.gold), 9), _rj(_fn(int(stats.get("click_damage", state.get_current_click_damage()))), 10),
				_rj(_fn(int(partner_dps)), 10), _rj(_fn(int(total_dps)), 10),
				_rj(_fn(enemy_hp), 10), _rj(_fn(state.reward_gold), 8),
				_rj("%.1fs" % kill_time, 7), note,
			]))
			_csv_append(
				category, lv, enemy_hp, state.reward_gold,
				last_purchase_cost, int(stats.get("click_damage", state.get_current_click_damage())), int(total_dps), kill_time,
				"profile_id=%s sim_time=%.0f hero=%d gold=%d click_damage=%d manual_dps=%d partner_dps=%d ability_dps=%d total_dps=%d prestige_rwd=%d total_hero_purchases=%d total_partner_purchases=%d total_building_purchases=%d total_ability_purchases=%d total_skill_purchases=%d last_purchase=%s ability_events=%s" % [
					profile_id, sim_time, state.character_level, state.gold,
					state.get_current_click_damage(), int(manual_dps), int(partner_dps), int(ability_dps), int(total_dps),
					first_prestige_reward, total_hero_buys, total_partner_buys, total_building_buys, total_ability_buys,
					total_hero_skill_buys + total_partner_skill_buys + total_ability_skill_buys,
					last_purchase_tag,
					("|".join(PackedStringArray(last_ability_events)) if not last_ability_events.is_empty() else "none"),
				]
			)

		var reward_gold_before: int = state.gold
		var defeat_time: float = sim_time + kill_time
		_sim_set_reward_ability_flags_for_defeat(state, ability_state, defeat_time)
		sim_time = defeat_time
		state.attack_with_damage(state.target_hp)
		state.resolve_defeated_target()
		var gold_gained: int = state.gold - reward_gold_before
		if use_scenario_modifiers:
			var scenario_gold_gained: int = _sim_profile_reward_gain(gold_gained, state.is_boss_level, scenario)
			state.gold = reward_gold_before + scenario_gold_gained
			gold_gained = scenario_gold_gained
		if gold_gained > state.reward_gold and _sim_is_ability_active(ability_state, "gold_bonus", defeat_time):
			ability_event_counts["gold_bonus_reward"] = int(ability_event_counts.get("gold_bonus_reward", 0)) + 1
			_sim_track_gold_bonus_contribution(state, ability_diagnostics, gold_gained)
		_sim_clear_expired_ability_flags(state, ability_state, sim_time)

	if stopped_reason == "reached_max_seconds" and state.current_level > SIM_MAX_LEVEL:
		stopped_reason = "reached_target_level"

	if emit_live_output:
		_ln("  %s summary: reached=%d time=%s stopped=%s purchases hero=%d partners=%d buildings=%d abilities=%d skills=%d" % [
			profile_id, reached_level, _fmt_time(sim_time), stopped_reason,
			total_hero_buys, total_partner_buys, total_building_buys, total_ability_buys,
			total_hero_skill_buys + total_partner_skill_buys + total_ability_skill_buys,
		])

	var final_stats: Dictionary = _sim_compute_profile_stats(state, profile, clicks_per_sec, sim_time, ability_state, scenario if use_scenario_modifiers else {})
	var final_tdps: float = float(final_stats.get("total_dps", 0.0))
	var partner_identity: Dictionary = _sim_partner_identity_metrics(state.partner_counts, scenario)
	if emit_live_output:
		_csv_append("simulation_summary_%s" % profile_id, reached_level,
			state.target_max_hp, state.reward_gold, 0,
			int(final_stats.get("click_damage", state.get_current_click_damage())), int(final_tdps), sim_time,
			"profile_id=%s reached_level=%d sim_time=%.0f hero=%d gold=%d click=%d manual_dps=%d partner_dps=%d ability_dps=%d total_dps=%d prestige_reward=%d total_hero_purchases=%d total_partner_purchases=%d total_building_purchases=%d total_ability_purchases=%d total_hero_skill_purchases=%d total_partner_skill_purchases=%d total_ability_skill_purchases=%d gold_spent_hero=%d gold_spent_partners=%d gold_spent_buildings=%d gold_spent_abilities=%d gold_spent_skills=%d ability_events=%s stopped_reason=%s" % [
				profile_id, reached_level, sim_time, state.character_level, state.gold,
				int(final_stats.get("click_damage", state.get_current_click_damage())), int(final_stats.get("manual_dps", 0.0)),
				int(final_stats.get("partner_dps", 0.0)), int(final_stats.get("ability_dps", 0.0)), int(final_tdps),
				first_prestige_reward, total_hero_buys, total_partner_buys, total_building_buys, total_ability_buys,
				total_hero_skill_buys, total_partner_skill_buys, total_ability_skill_buys,
				total_gold_spent_hero, total_gold_spent_partners, total_gold_spent_buildings,
				total_gold_spent_abilities, total_gold_spent_skills, _sim_format_counts(ability_event_counts), stopped_reason,
			])

	if boss_wall_level > 0 and emit_live_output:
		_sim_append_profile_boss_wall_rows(profile_id, boss_wall_level, boss_wall_hp, boss_wall_reward,
			boss_wall_manual_dps, boss_wall_partner_dps, boss_wall_ability_dps, boss_wall_dps_actual,
			boss_wall_dps_needed, boss_wall_ttk, boss_wall_hero_level, boss_wall_gold)

	var ability_summary_rows: int = 0
	var skill_summary_rows: int = 0
	if emit_live_output:
		_sim_append_profile_partner_summary(profile_id, state)
		_sim_append_profile_building_summary(profile_id, state)
		ability_summary_rows = _sim_append_profile_ability_summary(profile_id, state, ability_diagnostics)
		skill_summary_rows = _sim_append_profile_skill_summary(profile_id, state, skill_spend)
		_sim_append_profile_timing_rows(profile_id, level_times, first_prestige_time, first_prestige_reward)

	if first_prestige_time < 0.0 and emit_live_output:
		_warn("Simulation %s: first prestige not reached. Stopped at level %d after %.0f seconds." % [profile_id, reached_level, sim_time])
	if total_ability_buys > 0 and ability_summary_rows <= 0 and emit_live_output:
		_warn("Simulation %s: abilities were purchased but no ability summary rows were emitted." % profile_id)
	if total_hero_skill_buys + total_partner_skill_buys + total_ability_skill_buys > 0 and skill_summary_rows <= 0 and emit_live_output:
		_warn("Simulation %s: skills were purchased but no skill summary rows were emitted." % profile_id)
	if profile_id == "active_6cps" and boss_wall_level > 0 and boss_wall_dps_actual > 0.0 and emit_live_output:
		var ability_share: float = boss_wall_ability_dps / boss_wall_dps_actual
		if ability_share > 0.5:
			_warn("Simulation active_6cps: ability DPS is %.1f%% of total DPS at boss wall level %d." % [ability_share * 100.0, boss_wall_level])

	return {
		"profile_id": profile_id,
		"scenario_id": scenario_id,
		"scenario_label": str(scenario.get("label", "")) if is_scenario else "",
		"scenario": scenario,
		"clicks_per_sec": clicks_per_sec,
		"abilities_enabled": bool(profile.get("abilities", true)),
		"buildings_enabled": bool(profile.get("buildings", true)),
		"skills_enabled": bool(profile.get("skills", true)),
		"reached_level": reached_level,
		"sim_time": sim_time,
		"stopped_reason": stopped_reason,
		"boss_wall_level": boss_wall_level,
		"wall_level": boss_wall_level,
		"boss_wall": {
			"boss_level": boss_wall_level,
			"boss_hp": boss_wall_hp,
			"boss_reward": boss_wall_reward,
			"boss_ttk": boss_wall_ttk,
			"required_dps": boss_wall_dps_needed,
			"current_dps": boss_wall_dps_actual,
			"missing_dps": maxf(boss_wall_dps_needed - boss_wall_dps_actual, 0.0),
			"missing_dps_percent": (maxf(boss_wall_dps_needed - boss_wall_dps_actual, 0.0) / boss_wall_dps_needed * 100.0) if boss_wall_dps_needed > 0.0 else 0.0,
		},
		"first_prestige_reward": first_prestige_reward,
		"first_prestige_time": first_prestige_time,
		"hero_level": state.character_level,
		"gold": state.gold,
		"click_damage": int(final_stats.get("click_damage", state.get_current_click_damage())),
		"manual_dps": float(final_stats.get("manual_dps", 0.0)),
		"partner_dps": float(final_stats.get("partner_dps", 0.0)),
		"ability_dps": float(final_stats.get("ability_dps", 0.0)),
		"current_ability_dps": float(final_stats.get("ability_dps", 0.0)),
		"cumulative_ability_damage": _sim_cumulative_ability_damage(ability_diagnostics),
		"used_abilities": _sim_used_abilities_note(ability_diagnostics),
		"currently_active_abilities": _sim_currently_active_abilities_note(ability_state, sim_time),
		"total_dps": int(final_tdps),
		"total_partner_purchases": total_partner_buys,
		"strongest_partner_index": int(partner_identity.get("strongest_partner_index", -1)),
		"strongest_partner_dps": int(partner_identity.get("strongest_partner_dps", 0)),
		"strongest_partner_dps_share": float(partner_identity.get("strongest_partner_dps_share", 0.0)),
		"highest_owned_partner_index": int(partner_identity.get("highest_owned_partner_index", -1)),
		"target_hp": state.target_max_hp,
		"reward_gold": state.reward_gold,
		"level_10_time": float(level_times.get(10, -1.0)),
		"level_30_time": float(level_times.get(30, -1.0)),
		"level_50_time": float(level_times.get(50, -1.0)),
		"partner_counts": state.partner_counts.duplicate(),
		"building_counts": state.building_counts.duplicate(),
		"ability_diagnostics": ability_diagnostics,
		"skill_spend": skill_spend,
		"purchased_hero_skill_ids": state.purchased_hero_skill_ids.duplicate(),
		"purchased_partner_skill_ids": state.purchased_partner_skill_ids.duplicate(),
		"purchased_ability_skill_ids": state.purchased_ability_skill_ids.duplicate(),
		"ability_ranks": {
			"autoclick": state.get_ability_rank("autoclick"),
			"gold_bonus": state.get_ability_rank("gold_bonus"),
			"focus_burst": state.get_ability_rank("focus_burst"),
			"rally": state.get_ability_rank("rally"),
		},
		"purchased_abilities": {
			"autoclick": state.is_ability_purchased("autoclick"),
			"gold_bonus": state.is_ability_purchased("gold_bonus"),
			"focus_burst": state.is_ability_purchased("focus_burst"),
			"rally": state.is_ability_purchased("rally"),
		},
	}


func _sim_do_profile_purchases(state: _CS, profile: Dictionary, clicks_per_sec: float, scenario: Dictionary = {}) -> Dictionary:
	var out: Dictionary = {
		"hero_buys": 0, "partner_buys": 0, "building_buys": 0, "ability_buys": 0,
		"hero_skill_buys": 0, "partner_skill_buys": 0, "ability_skill_buys": 0,
		"gold_spent_hero": 0, "gold_spent_partners": 0, "gold_spent_buildings": 0,
		"gold_spent_abilities": 0, "gold_spent_skills": 0,
		"last_cost": 0, "last_type": "", "last_id": "", "purchases": [],
	}
	for _safety in range(70):
		var candidates: Array[Dictionary] = []
		if not scenario.is_empty():
			_sim_update_visible_partners_for_scenario(state, scenario)
		_sim_add_core_purchase_candidates(candidates, state, clicks_per_sec)
		if bool(profile.get("buildings", true)):
			_sim_add_building_candidates(candidates, state, clicks_per_sec)
		if bool(profile.get("abilities", true)):
			_sim_add_ability_unlock_candidates(candidates, state, clicks_per_sec)
		if bool(profile.get("skills", true)):
			_sim_add_skill_candidates(candidates, state, clicks_per_sec)
		if not scenario.is_empty():
			_sim_apply_scenario_to_purchase_candidates(candidates, state, scenario)

		var best: Dictionary = {}
		var best_value: float = 0.0
		for c: Dictionary in candidates:
			var cost: int = int(c.get("cost", 0))
			var value: float = float(c.get("value", 0.0))
			if cost > 0 and state.gold >= cost and value > best_value:
				best = c
				best_value = value
		if best.is_empty():
			break

		var before_gold: int = state.gold
		var kind: String = str(best.get("type", ""))
		var id_text: String = str(best.get("id", ""))
		var old_val: int = int(best.get("old_val", 0))
		var live_cost: int = int(best.get("live_cost", best.get("cost", 0)))
		var scenario_cost: int = int(best.get("cost", live_cost))
		if not scenario.is_empty() and before_gold < live_cost:
			state.gold = live_cost
		var result: Dictionary = {}
		match kind:
			"hero":
				result = state.buy_character_level_upgrades("x1")
			"partner":
				result = state.buy_partners(int(best.get("index", -1)), "x1")
			"building":
				result = state.buy_buildings(int(best.get("index", -1)), "x1")
			"ability":
				result = state.buy_or_upgrade_ability(id_text)
			"hero_skill":
				result = state.buy_hero_skill(id_text)
			"partner_skill":
				result = state.buy_partner_skill(id_text)
			"ability_skill":
				result = state.buy_ability_skill(id_text)
		if not bool(result.get("upgraded", false)):
			state.gold = before_gold
			break

		var spent: int = before_gold - state.gold
		if not scenario.is_empty():
			spent = scenario_cost
			state.gold = before_gold - scenario_cost
		var new_val: int = _sim_get_purchase_new_value(state, best)
		out["last_cost"] = spent
		out["last_type"] = kind
		out["last_id"] = id_text
		(out["purchases"] as Array).append({"type": kind, "id": id_text, "cost": spent, "old_val": old_val, "new_val": new_val})
		match kind:
			"hero":
				out["hero_buys"] = int(out["hero_buys"]) + 1
				out["gold_spent_hero"] = int(out["gold_spent_hero"]) + spent
			"partner":
				out["partner_buys"] = int(out["partner_buys"]) + 1
				out["gold_spent_partners"] = int(out["gold_spent_partners"]) + spent
			"building":
				out["building_buys"] = int(out["building_buys"]) + 1
				out["gold_spent_buildings"] = int(out["gold_spent_buildings"]) + spent
			"ability":
				out["ability_buys"] = int(out["ability_buys"]) + 1
				out["gold_spent_abilities"] = int(out["gold_spent_abilities"]) + spent
			"hero_skill":
				out["hero_skill_buys"] = int(out["hero_skill_buys"]) + 1
				out["gold_spent_skills"] = int(out["gold_spent_skills"]) + spent
			"partner_skill":
				out["partner_skill_buys"] = int(out["partner_skill_buys"]) + 1
				out["gold_spent_skills"] = int(out["gold_spent_skills"]) + spent
			"ability_skill":
				out["ability_skill_buys"] = int(out["ability_skill_buys"]) + 1
				out["gold_spent_skills"] = int(out["gold_spent_skills"]) + spent
	return out


func _sim_update_visible_partners_for_scenario(state: _CS, scenario: Dictionary) -> void:
	while state.visible_partner_count < state.partner_counts.size():
		var prev_index: int = state.visible_partner_count - 1
		if prev_index < 0:
			break
		var prev_next_cost: int = _scenario_partner_cost(prev_index, int(state.partner_counts[prev_index]), scenario)
		if state.gold < prev_next_cost:
			break
		state.visible_partner_count += 1


func _sim_apply_initial_overrides(state: _CS, overrides: Dictionary) -> void:
	if overrides.is_empty():
		return
	state.prestige_points_available = int(overrides.get("prestige_points_available", state.prestige_points_available))
	state.prestige_points_total_earned = int(overrides.get("prestige_points_total_earned", state.prestige_points_total_earned))
	state.total_prestiges = int(overrides.get("total_prestiges", state.total_prestiges))
	var talent_index: int = int(overrides.get("buy_prestige_talent_index", -1))
	if talent_index >= 0 and talent_index < state.prestige_talent_levels.size():
		state.buy_prestige_talent(talent_index)
	state._update_character_state()
	state.setup_current_level()


func _sim_add_core_purchase_candidates(candidates: Array[Dictionary], state: _CS, clicks_per_sec: float) -> void:
	if state.can_afford_character_level_bulk("x1"):
		var hero_cost: int = state.get_character_level_bulk_display_cost("x1")
		var cur_cdps: float = float(state.get_current_click_damage()) * clicks_per_sec
		var nxt_cdps: float = float(state.get_click_damage_for_character_level(state.character_level + 1)) * clicks_per_sec
		candidates.append({
			"type": "hero",
			"id": "hero_level",
			"cost": hero_cost,
			"value": maxf(nxt_cdps - cur_cdps, 0.5) / float(hero_cost),
			"old_val": state.character_level,
		})

	for i: int in range(state.visible_partner_count):
		if state.can_afford_partner_bulk(i, "x1"):
			var pcost: int = state.get_partner_bulk_display_cost(i, "x1")
			candidates.append({
				"type": "partner",
				"id": "partner_%d" % i,
				"index": i,
				"cost": pcost,
				"value": maxf(float(state.get_partner_bulk_dps_gain(i, "x1")), 0.5) / float(pcost),
				"old_val": state.partner_counts[i],
			})


func _sim_add_building_candidates(candidates: Array[Dictionary], state: _CS, clicks_per_sec: float) -> void:
	var cur_tdps: float = float(state.get_current_click_damage()) * clicks_per_sec + float(state.get_final_partner_dps(false))
	for b: int in range(state.building_counts.size()):
		if not state.can_buy_building(b):
			continue
		var cost: int = state.get_building_bulk_display_cost(b, "x1")
		if cost <= 0 or state.gold < cost:
			continue
		var value_gain: float = 0.5
		match _SC.get_bonus_type(b):
			"partner_dps":
				value_gain = maxf(float(state.get_final_partner_dps(false)) * 0.01, 0.5)
			"click_damage":
				value_gain = maxf(float(state.get_current_click_damage()) * clicks_per_sec * 0.01, 0.5)
			"gold":
				value_gain = maxf(float(state.reward_gold) * 0.01, 0.5)
			"ability_duration", "ability_cooldown":
				value_gain = maxf(cur_tdps * 0.005, 0.5)
			"boss_gold":
				value_gain = maxf(float(state.reward_gold) * 0.005, 0.5)
		candidates.append({
			"type": "building",
			"id": "building_%d" % b,
			"index": b,
			"cost": cost,
			"value": value_gain / float(cost),
			"old_val": state.building_counts[b],
		})


func _sim_add_ability_unlock_candidates(candidates: Array[Dictionary], state: _CS, clicks_per_sec: float) -> void:
	for ability_id in _AC.ABILITY_IDS:
		var aid: String = str(ability_id)
		if not state.can_buy_ability_unlock(aid):
			continue
		var cost: int = state.get_ability_upgrade_cost(aid)
		if cost <= 0:
			continue
		var value_gain: float = 0.5
		match aid:
			"autoclick":
				value_gain = maxf(float(state.get_autoclick_damage()) * _BC.AUTOCLICK_BASE_HITS_PER_SEC * 0.25, 0.5)
			"gold_bonus":
				value_gain = maxf(float(state.reward_gold), 0.5)
			"focus_burst":
				value_gain = maxf(float(state.get_current_click_damage()) * clicks_per_sec, 0.5)
			"rally":
				value_gain = maxf(float(state.get_final_partner_dps(false)), 0.5)
		candidates.append({
			"type": "ability",
			"id": aid,
			"cost": cost,
			"value": value_gain / float(cost),
			"old_val": 0,
		})


func _sim_add_skill_candidates(candidates: Array[Dictionary], state: _CS, clicks_per_sec: float) -> void:
	var base_click_dps: float = float(state.get_current_click_damage()) * clicks_per_sec
	var base_partner_dps: float = float(state.get_final_partner_dps(false))
	for skill: Dictionary in _HSC.SKILL_DEFINITIONS:
		var sid: String = str(skill.get("id", ""))
		if state.can_buy_hero_skill(sid):
			var cost: int = state.get_hero_skill_cost(sid)
			var value_gain: float = _sim_skill_value_gain(skill, base_click_dps, base_partner_dps, float(state.reward_gold))
			candidates.append({"type": "hero_skill", "id": sid, "cost": cost, "value": value_gain / float(cost), "old_val": 0, "skill": skill})

	for skill: Dictionary in _PSC.SKILL_DEFINITIONS:
		var sid: String = str(skill.get("id", ""))
		if state.can_buy_partner_skill(sid):
			var cost: int = state.get_partner_skill_cost(sid)
			var value_gain: float = _sim_skill_value_gain(skill, base_click_dps, base_partner_dps, float(state.reward_gold))
			candidates.append({"type": "partner_skill", "id": sid, "cost": cost, "value": value_gain / float(cost), "old_val": 0, "skill": skill})

	for skill: Dictionary in _AC.SKILL_DEFINITIONS:
		var sid: String = str(skill.get("id", ""))
		if state.can_buy_ability_skill(sid):
			var cost: int = state.get_ability_skill_cost(sid)
			var value_gain: float = _sim_skill_value_gain(skill, base_click_dps, base_partner_dps, float(state.reward_gold))
			candidates.append({"type": "ability_skill", "id": sid, "cost": cost, "value": value_gain / float(cost), "old_val": 0, "skill": skill})


func _sim_apply_scenario_to_purchase_candidates(candidates: Array[Dictionary], state: _CS, scenario: Dictionary) -> void:
	for i: int in range(candidates.size()):
		var candidate: Dictionary = candidates[i]
		var live_cost: int = int(candidate.get("cost", 0))
		var scenario_cost: int = _sim_scenario_candidate_cost(candidate, state, scenario)
		if live_cost > 0 and scenario_cost > 0:
			candidate["live_cost"] = live_cost
			candidate["cost"] = scenario_cost
			if str(candidate.get("type", "")) == "partner":
				var pi: int = int(candidate.get("index", -1))
				var owned: int = int(candidate.get("old_val", 0))
				var before_dps: int = _scenario_partner_dps(pi, owned, scenario)
				var after_dps: int = _scenario_partner_dps(pi, owned + 1, scenario)
				candidate["value"] = maxf(float(after_dps - before_dps), 0.5) / float(scenario_cost)
			else:
				candidate["value"] = float(candidate.get("value", 0.0)) * float(live_cost) / float(scenario_cost)
			candidates[i] = candidate


func _sim_scenario_candidate_cost(candidate: Dictionary, state: _CS, scenario: Dictionary) -> int:
	var kind: String = str(candidate.get("type", ""))
	var live_cost: int = int(candidate.get("cost", 0))
	match kind:
		"hero":
			return _scenario_hero_cost(int(candidate.get("old_val", state.character_level)), scenario)
		"partner":
			return _scenario_partner_cost(int(candidate.get("index", -1)), int(candidate.get("old_val", 0)), scenario)
		"building":
			return _scenario_building_cost(int(candidate.get("index", -1)), int(candidate.get("old_val", 0)), scenario)
		"ability", "ability_skill":
			return _scenario_ability_cost(live_cost, scenario)
		"hero_skill":
			return maxi(1, int(round(float(live_cost) * _scf(scenario, "hero_cost_mult"))))
		"partner_skill":
			var skill: Dictionary = candidate.get("skill", {})
			if not skill.is_empty():
				return _scenario_partner_skill_cost(skill, scenario)
			return maxi(1, int(round(float(live_cost) * _scf(scenario, "partner_cost_mult"))))
	return live_cost


func _sim_skill_value_gain(skill: Dictionary, click_dps: float, partner_dps: float, reward: float) -> float:
	var bonus_type: String = str(skill.get("bonus_type", ""))
	var bonus_value: float = float(skill.get("bonus_value", 0.0))
	match bonus_type:
		"click_damage", "all_damage", "focus_burst_rank", "autoclick_rank":
			return maxf(click_dps * maxf(bonus_value, 0.15), 0.5)
		"partner_dps", "own_partner_dps", "rally_rank":
			return maxf(partner_dps * maxf(bonus_value, 0.15), 0.5)
		"gold", "gold_bonus_rank":
			return maxf(reward * maxf(bonus_value, 0.25), 0.5)
	return 0.5


func _sim_get_purchase_new_value(state: _CS, candidate: Dictionary) -> int:
	match str(candidate.get("type", "")):
		"hero":
			return state.character_level
		"partner":
			var pi: int = int(candidate.get("index", -1))
			return state.partner_counts[pi] if pi >= 0 and pi < state.partner_counts.size() else 0
		"building":
			var bi: int = int(candidate.get("index", -1))
			return state.building_counts[bi] if bi >= 0 and bi < state.building_counts.size() else 0
		"ability", "hero_skill", "partner_skill", "ability_skill":
			return 1
	return 0


func _sim_new_ability_state() -> Dictionary:
	return {
		"active_until": {
			"autoclick": 0.0,
			"gold_bonus": 0.0,
			"focus_burst": 0.0,
			"rally": 0.0,
		},
		"ready_at": {
			"autoclick": 0.0,
			"gold_bonus": 0.0,
			"focus_burst": 0.0,
			"rally": 0.0,
		},
	}


func _sim_new_ability_diagnostics() -> Dictionary:
	var out: Dictionary = {}
	for ability_id in _AC.ABILITY_IDS:
		var aid: String = str(ability_id)
		out[aid] = {
			"spent": 0,
			"activations": 0,
			"total_active_time": 0.0,
			"estimated_damage_contributed": 0.0,
			"estimated_gold_contributed": 0.0,
		}
	return out


func _sim_new_skill_spend() -> Dictionary:
	return {
		"hero": 0,
		"partner": 0,
		"ability": 0,
	}


func _sim_track_profile_purchase_diagnostics(purchase: Dictionary, ability_diagnostics: Dictionary, skill_spend: Dictionary) -> void:
	var ptype: String = str(purchase.get("type", ""))
	var pid: String = str(purchase.get("id", ""))
	var spent: int = int(purchase.get("cost", 0))
	match ptype:
		"ability":
			if ability_diagnostics.has(pid):
				var row: Dictionary = ability_diagnostics[pid]
				row["spent"] = int(row.get("spent", 0)) + spent
				ability_diagnostics[pid] = row
		"hero_skill":
			skill_spend["hero"] = int(skill_spend.get("hero", 0)) + spent
		"partner_skill":
			skill_spend["partner"] = int(skill_spend.get("partner", 0)) + spent
		"ability_skill":
			skill_spend["ability"] = int(skill_spend.get("ability", 0)) + spent
			var skill: Dictionary = _AC.get_ability_skill_by_id(pid)
			var ability_id: String = str(skill.get("ability_id", ""))
			if ability_diagnostics.has(ability_id):
				var ability_row: Dictionary = ability_diagnostics[ability_id]
				ability_row["spent"] = int(ability_row.get("spent", 0)) + spent
				ability_diagnostics[ability_id] = ability_row


func _sim_update_ability_usage(state: _CS, profile: Dictionary, sim_time: float, ability_state: Dictionary, ability_diagnostics: Dictionary, clicks_per_sec: float) -> Array[String]:
	var events: Array[String] = []
	if not bool(profile.get("abilities", true)):
		_sim_set_ability_flags(state, false, false, false, false)
		return events

	var active_until: Dictionary = ability_state.get("active_until", {})
	var ready_at: Dictionary = ability_state.get("ready_at", {})
	if state.is_ability_purchased("autoclick") and sim_time >= float(ready_at.get("autoclick", 0.0)):
		var duration: float = _sim_ability_duration(state, "autoclick")
		active_until["autoclick"] = sim_time + duration
		ready_at["autoclick"] = sim_time + _sim_ability_cooldown(state, "autoclick")
		events.append("use_autoclick")
		_sim_track_ability_activation(state, ability_diagnostics, "autoclick", duration, clicks_per_sec)
	if state.is_ability_purchased("gold_bonus") and sim_time >= float(ready_at.get("gold_bonus", 0.0)):
		var duration: float = _sim_ability_duration(state, "gold_bonus")
		active_until["gold_bonus"] = sim_time + duration
		ready_at["gold_bonus"] = sim_time + _sim_ability_cooldown(state, "gold_bonus")
		events.append("use_gold_bonus")
		_sim_track_ability_activation(state, ability_diagnostics, "gold_bonus", duration, clicks_per_sec)
	if state.is_boss_level and state.is_ability_purchased("focus_burst") and sim_time >= float(ready_at.get("focus_burst", 0.0)):
		var duration: float = _sim_ability_duration(state, "focus_burst")
		active_until["focus_burst"] = sim_time + duration
		ready_at["focus_burst"] = sim_time + _sim_ability_cooldown(state, "focus_burst")
		events.append("use_focus_burst")
		_sim_track_ability_activation(state, ability_diagnostics, "focus_burst", duration, clicks_per_sec)
	if state.is_boss_level and state.is_ability_purchased("rally") and sim_time >= float(ready_at.get("rally", 0.0)):
		var duration: float = _sim_ability_duration(state, "rally")
		active_until["rally"] = sim_time + duration
		ready_at["rally"] = sim_time + _sim_ability_cooldown(state, "rally")
		events.append("use_rally")
		_sim_track_ability_activation(state, ability_diagnostics, "rally", duration, clicks_per_sec)

	ability_state["active_until"] = active_until
	ability_state["ready_at"] = ready_at
	_sim_clear_expired_ability_flags(state, ability_state, sim_time)
	return events


func _sim_compute_combat_stats(state: _CS, profile: Dictionary, clicks_per_sec: float, sim_time: float, ability_state: Dictionary) -> Dictionary:
	var abilities_enabled: bool = bool(profile.get("abilities", true))
	var autoclick_on: bool = abilities_enabled and _sim_is_ability_active(ability_state, "autoclick", sim_time)
	var gold_bonus_on: bool = abilities_enabled and _sim_is_ability_active(ability_state, "gold_bonus", sim_time)
	var focus_on: bool = abilities_enabled and _sim_is_ability_active(ability_state, "focus_burst", sim_time)
	var rally_on: bool = abilities_enabled and _sim_is_ability_active(ability_state, "rally", sim_time)
	_sim_set_ability_flags(state, gold_bonus_on, focus_on, rally_on, autoclick_on)
	var manual_dps: float = float(state.get_current_click_damage()) * clicks_per_sec
	var partner_dps: float = float(state.get_final_partner_dps(true))
	var ability_dps: float = 0.0
	if autoclick_on:
		ability_dps = float(state.get_autoclick_damage()) * _BC.AUTOCLICK_BASE_HITS_PER_SEC * state.get_autoclick_rank_rate_multiplier()
	return {"click_damage": state.get_current_click_damage(), "manual_dps": manual_dps, "partner_dps": partner_dps, "ability_dps": ability_dps, "total_dps": manual_dps + partner_dps + ability_dps}


func _sim_compute_profile_stats(state: _CS, profile: Dictionary, clicks_per_sec: float, sim_time: float, ability_state: Dictionary, scenario: Dictionary = {}) -> Dictionary:
	var stats: Dictionary = _sim_compute_combat_stats(state, profile, clicks_per_sec, sim_time, ability_state)
	if scenario.is_empty() or _scenario_is_identity_baseline(scenario):
		return stats
	var hero_mult: float = _scf(scenario, "hero_damage_mult")
	var click_damage: int = maxi(1, int(round(float(stats.get("click_damage", state.get_current_click_damage())) * hero_mult)))
	var manual_dps: float = float(stats.get("manual_dps", 0.0)) * hero_mult
	var partner_dps: float = float(stats.get("partner_dps", 0.0)) * _scf(scenario, "partner_dps_mult")
	if _scenario_has_partner_curve(scenario):
		partner_dps = _scenario_total_partner_dps(_sim_state_as_scenario_state(state), scenario, state.is_boss_level)
		if bool(profile.get("abilities", true)) and _sim_is_ability_active(ability_state, "rally", sim_time):
			partner_dps *= state.get_rally_multiplier()
	var ability_dps: float = float(stats.get("ability_dps", 0.0)) * hero_mult
	return {
		"click_damage": click_damage,
		"manual_dps": manual_dps,
		"partner_dps": partner_dps,
		"ability_dps": ability_dps,
		"total_dps": manual_dps + partner_dps + ability_dps,
	}


func _scenario_is_identity_baseline(scenario: Dictionary) -> bool:
	return str(scenario.get("id", "")) == "baseline" and not _scenario_has_partner_curve(scenario)


func _sim_state_as_scenario_state(state: _CS) -> Dictionary:
	return {
		"partner_counts": state.partner_counts.duplicate(),
		"building_counts": state.building_counts.duplicate(),
		"purchased_hero_skill_ids": state.purchased_hero_skill_ids.duplicate(),
		"purchased_partner_skill_ids": state.purchased_partner_skill_ids.duplicate(),
	}


func _sim_partner_identity_metrics(partner_counts: Array, scenario: Dictionary) -> Dictionary:
	var total_tier_dps: int = 0
	var strongest_index: int = -1
	var strongest_dps: int = 0
	var highest_owned_index: int = -1
	for pi: int in range(partner_counts.size()):
		var owned: int = int(partner_counts[pi])
		if owned <= 0:
			continue
		highest_owned_index = pi
		var tier_dps: int = _scenario_partner_tier_total_dps(pi, owned, scenario)
		total_tier_dps += tier_dps
		if tier_dps > strongest_dps:
			strongest_dps = tier_dps
			strongest_index = pi
	return {
		"strongest_partner_index": strongest_index,
		"strongest_partner_dps": strongest_dps,
		"strongest_partner_dps_share": float(strongest_dps) / float(total_tier_dps) * 100.0 if total_tier_dps > 0 else 0.0,
		"highest_owned_partner_index": highest_owned_index,
		"total_tier_partner_dps": total_tier_dps,
	}


func _sim_profile_enemy_hp(state: _CS, scenario: Dictionary) -> int:
	if scenario.is_empty():
		return state.target_max_hp
	return _scenario_enemy_hp(state.current_level, state.is_boss_level, scenario)


func _sim_profile_reward_gain(live_gold_gained: int, was_boss: bool, scenario: Dictionary) -> int:
	if scenario.is_empty():
		return live_gold_gained
	var mult: float = _scf(scenario, "enemy_reward_mult")
	if was_boss:
		mult *= _scf(scenario, "boss_reward_mult")
	return maxi(0, int(round(float(live_gold_gained) * mult)))


func _sim_track_ability_activation(state: _CS, ability_diagnostics: Dictionary, ability_id: String, duration: float, clicks_per_sec: float) -> void:
	if not ability_diagnostics.has(ability_id):
		return
	var row: Dictionary = ability_diagnostics[ability_id]
	row["activations"] = int(row.get("activations", 0)) + 1
	row["total_active_time"] = float(row.get("total_active_time", 0.0)) + duration
	row["estimated_damage_contributed"] = float(row.get("estimated_damage_contributed", 0.0)) + _sim_estimate_activation_damage(state, ability_id, duration, clicks_per_sec)
	ability_diagnostics[ability_id] = row


func _sim_estimate_activation_damage(state: _CS, ability_id: String, duration: float, clicks_per_sec: float) -> float:
	match ability_id:
		"autoclick":
			return float(state.get_autoclick_damage()) * _BC.AUTOCLICK_BASE_HITS_PER_SEC * state.get_autoclick_rank_rate_multiplier() * duration
		"focus_burst":
			var focus_mult: float = _BC.ABILITY_BASE_MULTIPLIER + _BC.ABILITY_RANK_MULTIPLIER_STEP * float(state.get_ability_rank("focus_burst"))
			return float(state.get_current_click_damage()) * clicks_per_sec * maxf(focus_mult - 1.0, 0.0) * duration
		"rally":
			var rally_mult: float = _BC.ABILITY_BASE_MULTIPLIER + _BC.ABILITY_RANK_MULTIPLIER_STEP * float(state.get_ability_rank("rally"))
			return float(state.get_final_partner_dps(false)) * maxf(rally_mult - 1.0, 0.0) * duration
	return 0.0


func _sim_track_gold_bonus_contribution(state: _CS, ability_diagnostics: Dictionary, gold_gained: int) -> void:
	if not ability_diagnostics.has("gold_bonus"):
		return
	var gold_mult: float = state.get_gold_bonus_multiplier()
	if gold_mult <= 1.0:
		return
	var base_estimate: float = float(gold_gained) / gold_mult
	var row: Dictionary = ability_diagnostics["gold_bonus"]
	row["estimated_gold_contributed"] = float(row.get("estimated_gold_contributed", 0.0)) + maxf(float(gold_gained) - base_estimate, 0.0)
	ability_diagnostics["gold_bonus"] = row


func _sim_cumulative_ability_damage(ability_diagnostics: Dictionary) -> int:
	var total: float = 0.0
	for ability_id in ability_diagnostics.keys():
		var diagnostics: Dictionary = ability_diagnostics.get(ability_id, {})
		total += float(diagnostics.get("estimated_damage_contributed", 0.0))
	return int(total)


func _sim_used_abilities_note(ability_diagnostics: Dictionary) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for ability_id in _AC.ABILITY_IDS:
		var diagnostics: Dictionary = ability_diagnostics.get(str(ability_id), {})
		if int(diagnostics.get("activations", 0)) > 0:
			parts.append(str(ability_id))
	return "none" if parts.is_empty() else "|".join(parts)


func _sim_currently_active_abilities_note(ability_state: Dictionary, sim_time: float) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for ability_id in _AC.ABILITY_IDS:
		var aid: String = str(ability_id)
		if _sim_is_ability_active(ability_state, aid, sim_time):
			parts.append(aid)
	return "none" if parts.is_empty() else "|".join(parts)


func _sim_set_ability_flags(state: _CS, gold_bonus_on: bool, focus_on: bool, rally_on: bool, autoclick_on: bool) -> void:
	state.gold_bonus_active = gold_bonus_on
	state.focus_burst_active = focus_on
	state.rally_active = rally_on
	state.autoclick_active = autoclick_on
	state._update_character_state()


func _sim_set_reward_ability_flags_for_defeat(state: _CS, ability_state: Dictionary, defeat_time: float) -> void:
	_sim_set_ability_flags(
		state,
		_sim_is_ability_active(ability_state, "gold_bonus", defeat_time),
		_sim_is_ability_active(ability_state, "focus_burst", defeat_time),
		_sim_is_ability_active(ability_state, "rally", defeat_time),
		_sim_is_ability_active(ability_state, "autoclick", defeat_time)
	)


func _sim_clear_expired_ability_flags(state: _CS, ability_state: Dictionary, sim_time: float) -> void:
	_sim_set_ability_flags(
		state,
		_sim_is_ability_active(ability_state, "gold_bonus", sim_time),
		_sim_is_ability_active(ability_state, "focus_burst", sim_time),
		_sim_is_ability_active(ability_state, "rally", sim_time),
		_sim_is_ability_active(ability_state, "autoclick", sim_time)
	)


func _sim_is_ability_active(ability_state: Dictionary, ability_id: String, sim_time: float) -> bool:
	var active_until: Dictionary = ability_state.get("active_until", {})
	return sim_time < float(active_until.get(ability_id, 0.0))


func _sim_ability_duration(state: _CS, ability_id: String) -> float:
	var base: float = 0.0
	match ability_id:
		"autoclick":
			base = float(_BC.AUTOCLICK_BASE_DURATION_SEC + state.get_ability_rank("autoclick") * _BC.AUTOCLICK_RANK_DURATION_BONUS_SEC)
		"gold_bonus":
			base = _BC.GOLD_BONUS_BASE_DURATION_SEC
		"focus_burst":
			base = _BC.FOCUS_BURST_BASE_DURATION_SEC
		"rally":
			base = _BC.RALLY_BASE_DURATION_SEC
	return base * state.get_ability_duration_multiplier()


func _sim_ability_cooldown(state: _CS, ability_id: String) -> float:
	var base: float = 0.0
	match ability_id:
		"autoclick":
			base = _BC.AUTOCLICK_COOLDOWN_SEC
		"gold_bonus":
			base = _BC.GOLD_BONUS_COOLDOWN_SEC
		"focus_burst":
			base = _BC.FOCUS_BURST_COOLDOWN_SEC
		"rally":
			base = _BC.RALLY_COOLDOWN_SEC
	return base * state.get_ability_cooldown_multiplier()


func _sim_append_profile_boss_wall_rows(
		profile_id: String, boss_wall_level: int, boss_wall_hp: int, boss_wall_reward: int,
		boss_wall_manual_dps: float, boss_wall_partner_dps: float, boss_wall_ability_dps: float,
		boss_wall_dps_actual: float, boss_wall_dps_needed: float, boss_wall_ttk: float,
		boss_wall_hero_level: int, boss_wall_gold: int) -> void:
	var miss_dps: float = maxf(boss_wall_dps_needed - boss_wall_dps_actual, 0.0)
	var miss_pct: float = miss_dps / boss_wall_dps_needed * 100.0 if boss_wall_dps_needed > 0.0 else 0.0
	_csv_append(
		"simulation_boss_wall_%s" % profile_id, boss_wall_level,
		boss_wall_hp, boss_wall_reward, 0,
		int(boss_wall_manual_dps), int(boss_wall_dps_actual), boss_wall_ttk,
		"profile_id=%s boss_level=%d boss_hp=%d boss_time_limit=%.0f boss_ttk=%.1f required_dps=%d current_total_dps=%d missing_dps=%d missing_dps_percent=%.1f hero_level=%d gold=%d partner_dps=%d manual_dps=%d ability_dps=%d" % [
			profile_id, boss_wall_level, boss_wall_hp, float(_BC.BOSS_TIME_LIMIT), boss_wall_ttk,
			int(boss_wall_dps_needed), int(boss_wall_dps_actual), int(miss_dps), miss_pct,
			boss_wall_hero_level, boss_wall_gold, int(boss_wall_partner_dps), int(boss_wall_manual_dps), int(boss_wall_ability_dps),
		]
	)

	var hp_mult_to_pass: float = float(_BC.BOSS_HP_MULTIPLIER) * (float(_BC.BOSS_TIME_LIMIT) / boss_wall_ttk) if boss_wall_ttk > 0.0 else 0.0
	var req_partner_mult: float = 0.0
	if boss_wall_partner_dps > 0.0:
		var req_pdps: float = maxf(boss_wall_dps_needed - boss_wall_manual_dps - boss_wall_ability_dps, 0.0)
		req_partner_mult = req_pdps / boss_wall_partner_dps
	_csv_append(
		"simulation_boss_wall_fix_%s" % profile_id, boss_wall_level,
		boss_wall_hp, 0, 0,
		int(boss_wall_manual_dps), int(boss_wall_dps_actual), boss_wall_ttk,
		"profile_id=%s required_dps=%d current_total_dps=%d missing_dps=%d missing_dps_percent=%.1f boss_hp_multiplier_current=%d boss_hp_multiplier_to_pass=%.1f boss_timer_current=%.0f boss_timer_to_pass=%.1f early_partner_dps_multiplier_to_pass=%.2f" % [
			profile_id, int(boss_wall_dps_needed), int(boss_wall_dps_actual),
			int(miss_dps), miss_pct, _BC.BOSS_HP_MULTIPLIER, hp_mult_to_pass,
			float(_BC.BOSS_TIME_LIMIT), boss_wall_ttk, req_partner_mult,
		]
	)


func _sim_append_profile_partner_summary(profile_id: String, state: _CS) -> void:
	var total_pdps_for_share: int = 0
	for pi: int in range(state.partner_counts.size()):
		total_pdps_for_share += state.get_partner_tier_total_dps(pi)
	var any_partner_summary: bool = false
	for pi: int in range(state.partner_counts.size()):
		if state.partner_counts[pi] > 0:
			any_partner_summary = true
			var pname: String = _partner_name(pi)
			var base_dps: int = _BC.PARTNER_DPS_VALUES[pi] if pi < _BC.PARTNER_DPS_VALUES.size() else 0
			var ms_mult: int = state.get_partner_milestone_multiplier(pi)
			var tier_dps: int = state.get_partner_tier_total_dps(pi)
			var next_cost: int = state.partner_purchase_costs[pi] if pi < state.partner_purchase_costs.size() else _partner_cost(pi, state.partner_counts[pi])
			var share_pct: float = float(tier_dps) / float(total_pdps_for_share) * 100.0 if total_pdps_for_share > 0 else 0.0
			_csv_append(
				"simulation_partner_summary_%s" % profile_id, pi + 1,
				0, 0, next_cost, 0, tier_dps, 0.0,
				"profile_id=%s partner_name=%s owned_count=%d base_dps=%d milestone_multiplier=%d tier_total_dps=%d next_cost=%d dps_share_percent=%.1f" % [
					profile_id, pname, state.partner_counts[pi], base_dps, ms_mult, tier_dps, next_cost, share_pct,
				]
			)
	if not any_partner_summary:
		_csv_append("simulation_partner_summary_%s" % profile_id, 0, 0, 0, 0, 0, 0, 0.0, "profile_id=%s no_partners_purchased" % profile_id)


func _sim_append_profile_building_summary(profile_id: String, state: _CS) -> void:
	_csv_append(
		"simulation_building_summary_%s" % profile_id, 0,
		0, 0, 0, 0, 0, 0.0,
		"profile_id=%s total_buildings=%d" % [profile_id, state._get_total_building_count()]
	)
	var any_building_summary: bool = false
	for bi: int in range(state.building_counts.size()):
		if state.building_counts[bi] > 0:
			any_building_summary = true
			var next_bc: int = state.get_building_bulk_display_cost(bi, "x1")
			var bonus_pct: int = state.get_building_total_bonus_percent(bi)
			_csv_append(
				"simulation_building_summary_%s" % profile_id, bi + 1,
				0, 0, next_bc, 0, 0, 0.0,
				"profile_id=%s building_name=%s owned_count=%d next_cost=%d bonus_percent=%d" % [
					profile_id, _building_name(bi), state.building_counts[bi], next_bc, bonus_pct,
				]
			)
	if not any_building_summary:
		_csv_append("simulation_building_summary_%s" % profile_id, 0, 0, 0, 0, 0, 0, 0.0, "profile_id=%s no_buildings_purchased" % profile_id)


func _sim_append_profile_ability_summary(profile_id: String, state: _CS, ability_diagnostics: Dictionary) -> int:
	var rows: int = 0
	for ability_id in _AC.ABILITY_IDS:
		var aid: String = str(ability_id)
		var diagnostics: Dictionary = ability_diagnostics.get(aid, {})
		var purchased: bool = state.is_ability_purchased(aid)
		var rank: int = state.get_ability_rank(aid)
		var spent: int = int(diagnostics.get("spent", 0))
		var activations: int = int(diagnostics.get("activations", 0))
		var active_time: float = float(diagnostics.get("total_active_time", 0.0))
		var damage_contribution: float = float(diagnostics.get("estimated_damage_contributed", 0.0))
		var gold_contribution: float = float(diagnostics.get("estimated_gold_contributed", 0.0))
		var cooldown: float = _sim_ability_cooldown(state, aid)
		var duration: float = _sim_ability_duration(state, aid)
		_csv_append(
			"simulation_ability_summary_%s" % profile_id, rows + 1,
			0, int(gold_contribution), spent, int(damage_contribution), 0, active_time,
			"profile_id=%s ability_id=%s purchased=%s rank=%d unlock_rank_cost_spent=%d activations=%d total_active_time=%.1f estimated_damage_contributed=%d estimated_gold_contributed=%d cooldown=%.1f duration=%.1f" % [
				profile_id, aid, ("true" if purchased else "false"), rank, spent, activations,
				active_time, int(damage_contribution), int(gold_contribution), cooldown, duration,
			]
		)
		rows += 1
	return rows


func _sim_append_profile_skill_summary(profile_id: String, state: _CS, skill_spend: Dictionary) -> int:
	var hero_ids: PackedStringArray = _sim_to_packed_strings(state.purchased_hero_skill_ids)
	var partner_ids: PackedStringArray = _sim_to_packed_strings(state.purchased_partner_skill_ids)
	var ability_ids: PackedStringArray = _sim_to_packed_strings(state.purchased_ability_skill_ids)
	var hero_spent: int = int(skill_spend.get("hero", 0))
	var partner_spent: int = int(skill_spend.get("partner", 0))
	var ability_spent: int = int(skill_spend.get("ability", 0))
	var total_spent: int = hero_spent + partner_spent + ability_spent
	_csv_append(
		"simulation_skill_summary_%s" % profile_id, 0,
		0, 0, total_spent, 0, 0, 0.0,
		"profile_id=%s purchased_hero_skills=%d hero_skill_ids=%s purchased_partner_skills=%d partner_skill_ids=%s purchased_ability_skills=%d ability_skill_ids=%s total_skill_spent=%d total_hero_skill_spent=%d total_partner_skill_spent=%d total_ability_skill_spent=%d" % [
			profile_id,
			hero_ids.size(), _sim_join_ids(hero_ids),
			partner_ids.size(), _sim_join_ids(partner_ids),
			ability_ids.size(), _sim_join_ids(ability_ids),
			total_spent, hero_spent, partner_spent, ability_spent,
		]
	)
	return 1


func _sim_append_profile_timing_rows(profile_id: String, level_times: Dictionary, first_prestige_time: float, first_prestige_reward: int) -> void:
	for ml: int in ([5, 10, 15, 20, 25, 30] as Array[int]):
		var ml_t: float = float(level_times.get(ml, -1.0))
		var ml_t_str: String = ("%.0f" % ml_t) if ml_t >= 0.0 else "not_reached"
		_csv_append("simulation_summary_%s" % profile_id, ml, 0, 0, 0, 0, 0, maxf(ml_t, 0.0), "profile_id=%s time_to_level_%d=%s" % [profile_id, ml, ml_t_str])
	var prestige_t_str: String = ("%.0f" % first_prestige_time) if first_prestige_time >= 0.0 else "not_reached"
	_csv_append("simulation_summary_%s" % profile_id, 0, 0, 0, 0, 0, 0, maxf(first_prestige_time, 0.0), "profile_id=%s first_prestige_available_time=%s first_prestige_reward=%d" % [profile_id, prestige_t_str, first_prestige_reward])


func _sim_to_packed_strings(values: Array) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for value in values:
		out.append(str(value))
	return out


func _sim_join_ids(ids: PackedStringArray) -> String:
	if ids.is_empty():
		return "none"
	return "|".join(ids)


# ==========================================================================
#  SECTION 7 — Balance Scenario Comparison
# ==========================================================================

func _section_partner_curve_scenario_preview() -> void:
	_header("SECTION - Partner Curve Scenario Preview")
	_ln("  Generated partner curves are audit-only and do not modify BalanceConfig.")
	_ln(_row([
		_lj("Scenario", 30), _rj("P#", 4), _rj("DPS", 12), _rj("Cost", 14),
		_rj("DPSx", 8), _rj("Costx", 8), _rj("DPS/Gold", 12), _rj("Effx", 8),
	]))
	_div("-", 104)
	_warn_if_live_placeholder_partners()
	for scenario_id: String in _partner_curve_scenario_ids():
		var scenario: Dictionary = _get_balance_scenario_by_id(scenario_id)
		var prev_dps: int = 0
		var prev_cost: int = 0
		var prev_efficiency: float = 0.0
		for pi: int in range(mini(15, int(_get_scenario_partner_curve(scenario_id).get("max_partners", _BC.PARTNER_DPS_VALUES.size())))):
			var base_dps: int = _scenario_partner_base_dps(pi, scenario)
			var base_cost: int = _scenario_partner_base_cost(pi, scenario)
			var dps_ratio: float = float(base_dps) / float(prev_dps) if prev_dps > 0 else 0.0
			var cost_ratio: float = float(base_cost) / float(prev_cost) if prev_cost > 0 else 0.0
			var efficiency: float = float(base_dps) / float(base_cost) if base_cost > 0 else 0.0
			var efficiency_ratio: float = efficiency / prev_efficiency if prev_efficiency > 0.0 else 0.0
			_ln(_row([
				_lj(scenario_id.left(29), 30),
				_rj(str(pi + 1), 4),
				_rj(_fn(base_dps), 12),
				_rj(_fn(base_cost), 14),
				_rj(_ratio_text(dps_ratio), 8),
				_rj(_ratio_text(cost_ratio), 8),
				_rj("%.5f" % efficiency, 12),
				_rj(_ratio_text(efficiency_ratio), 8),
			]))
			_csv_append(
				"partner_curve_preview", pi + 1,
				0, 0, base_cost, 0, base_dps, 0.0,
				"scenario_id=%s partner_index=%d base_dps=%d base_cost=%d dps_ratio=%.3f cost_ratio=%.3f dps_per_gold=%.8f efficiency_ratio=%.3f" % [
					scenario_id, pi, base_dps, base_cost, dps_ratio, cost_ratio, efficiency, efficiency_ratio,
				]
			)
			_add_partner_curve_preview_warnings(scenario_id, pi, base_dps, base_cost, dps_ratio, cost_ratio, efficiency_ratio)
			prev_dps = base_dps
			prev_cost = base_cost
			prev_efficiency = efficiency


func _partner_curve_scenario_ids() -> Array[String]:
	return [
		"partner_curve_balanced_idle",
		"partner_curve_soft_idle",
		"partner_curve_power_idle",
		"partner_curve_late_power",
	]


func _ratio_text(value: float) -> String:
	return "-" if value <= 0.0 else "%.2fx" % value


func _add_partner_curve_preview_warnings(scenario_id: String, partner_index: int, base_dps: int, base_cost: int, dps_ratio: float, cost_ratio: float, efficiency_ratio: float) -> void:
	if partner_index >= 1 and partner_index <= 7:
		if dps_ratio < 3.0:
			_warn("Partner curve %s partner %d: adjacent DPS ratio below 3.0 (%.2fx)." % [scenario_id, partner_index + 1, dps_ratio])
		if cost_ratio < 4.0:
			_warn("Partner curve %s partner %d: adjacent cost ratio below 4.0 (%.2fx)." % [scenario_id, partner_index + 1, cost_ratio])
	if partner_index >= 1:
		if efficiency_ratio > 3.0:
			_warn("Partner curve %s partner %d: DPS per gold grows by more than x3 (%.2fx)." % [scenario_id, partner_index + 1, efficiency_ratio])
		if efficiency_ratio > 0.0 and efficiency_ratio < 0.5:
			_warn("Partner curve %s partner %d: DPS per gold drops by more than 50%% (%.2fx)." % [scenario_id, partner_index + 1, efficiency_ratio])
	if base_dps > 9_000_000_000_000_000 or base_cost > 9_000_000_000_000_000:
		_warn("Partner curve %s partner %d: generated value is near practical 64-bit limits too early." % [scenario_id, partner_index + 1])


func _warn_if_live_placeholder_partners() -> void:
	if _BC.PARTNER_DPS_VALUES.size() <= PLACEHOLDER_PARTNER_START_IDX:
		return
	_warn("Baseline live partners 14-28 still use placeholder values from BalanceConfig; generated curve scenarios are for comparison only.")


func _section_balance_scenario_comparison() -> void:
	_header("SECTION — Balance Scenario Comparison")
	_ln("  Audit-only sandbox. Scenario modifiers are applied inside this report only.")
	_ln(_row([
		_lj("Scenario", 22), _lj("Profile", 20), _rj("Level", 6), _rj("Time", 8),
		_rj("Wall", 6), _rj("Prestige", 8), _rj("Manual%", 8), _rj("Partner%", 9),
		_rj("Ability%", 9), "Notes",
	]))
	_div("-", 118)

	var profiles: Array[Dictionary] = _simulation_profiles()
	var baseline_results: Array[Dictionary] = []
	var baseline_active_wall_level: int = -1
	for scenario: Dictionary in BALANCE_SCENARIOS:
		for profile: Dictionary in profiles:
			var result: Dictionary = _run_balance_scenario_profile(scenario, profile)
			_print_scenario_profile_row(result)
			_append_scenario_csv_rows(result)
			_add_scenario_warnings(result)
			if str(scenario.get("id", "")) == "baseline":
				baseline_results.append(result)
				if str(profile.get("id", "")) == "active_6cps":
					baseline_active_wall_level = int(result.get("wall_level", -1))
			else:
				_append_scenario_runaway_warning_if_needed(result, baseline_active_wall_level)
			_append_scenario_post_prestige_summary_if_needed(scenario, profile, result)
	for result: Dictionary in baseline_results:
		_append_scenario_baseline_validation(result)


func _simulation_profiles() -> Array[Dictionary]:
	return [
		{"id": "active_6cps", "clicks_per_sec": 6.0, "abilities": true, "buildings": true, "skills": true},
		{"id": "active_no_abilities", "clicks_per_sec": 6.0, "abilities": false, "buildings": true, "skills": true},
		{"id": "semi_active_3cps", "clicks_per_sec": 3.0, "abilities": true, "buildings": true, "skills": true},
		{"id": "idle_0cps", "clicks_per_sec": 0.0, "abilities": true, "buildings": true, "skills": true},
	]


func _run_balance_scenario_profile(scenario: Dictionary, profile: Dictionary) -> Dictionary:
	return _run_progression_profile(profile, scenario, false)


func _scenario_new_state() -> Dictionary:
	var partner_counts: Array[int] = []
	for _i in range(_BC.PARTNER_DPS_VALUES.size()):
		partner_counts.append(0)
	var building_counts: Array[int] = []
	for _b in range(_SC.get_building_count()):
		building_counts.append(0)
	return {
		"current_level": 1,
		"defeated_in_level": 0,
		"gold": 0,
		"hero_level": 1,
		"partner_counts": partner_counts,
		"building_counts": building_counts,
		"visible_partner_count": 2,
		"purchased_abilities": {},
		"ability_ranks": {},
		"purchased_hero_skill_ids": [],
		"purchased_partner_skill_ids": [],
	}


func _scenario_new_ability_state() -> Dictionary:
	return {
		"active_until": {},
		"ready_at": {},
	}


func _scenario_do_purchases(state: Dictionary, scenario: Dictionary, profile: Dictionary, clicks_per_sec: float) -> void:
	for _safety in range(70):
		_scenario_update_visible_partners(state, scenario)
		var candidates: Array[Dictionary] = _scenario_purchase_candidates(state, scenario, profile, clicks_per_sec)
		var best: Dictionary = {}
		var best_value: float = 0.0
		var gold: int = int(state.get("gold", 0))
		for candidate: Dictionary in candidates:
			var cost: int = int(candidate.get("cost", 0))
			var value: float = float(candidate.get("value", 0.0))
			if cost > 0 and gold >= cost and value > best_value:
				best = candidate
				best_value = value
		if best.is_empty():
			break
		_scenario_apply_purchase(state, best)


func _scenario_purchase_candidates(state: Dictionary, scenario: Dictionary, profile: Dictionary, clicks_per_sec: float) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	var hero_level: int = int(state.get("hero_level", 1))
	var hero_cost: int = _scenario_hero_cost(hero_level, scenario)
	var current_click: int = _scenario_click_damage(state, scenario)
	var next_click: int = _scenario_hero_damage(hero_level + 1, scenario) * _scenario_click_building_multiplier(state, scenario)
	candidates.append({
		"type": "hero",
		"cost": hero_cost,
		"value": maxf(float(next_click - current_click) * clicks_per_sec, 0.5) / float(hero_cost),
	})

	var partner_counts: Array = state.get("partner_counts", [])
	var visible_count: int = int(state.get("visible_partner_count", 2))
	for pi: int in range(mini(visible_count, partner_counts.size())):
		var owned: int = int(partner_counts[pi])
		var cost: int = _scenario_partner_cost(pi, owned, scenario)
		var before_dps: int = _scenario_partner_dps(pi, owned, scenario)
		var after_dps: int = _scenario_partner_dps(pi, owned + 1, scenario)
		candidates.append({
			"type": "partner",
			"index": pi,
			"cost": cost,
			"value": maxf(float(after_dps - before_dps) * _scenario_partner_building_multiplier(state, scenario), 0.5) / float(cost),
		})

	if bool(profile.get("buildings", true)):
		var building_counts: Array = state.get("building_counts", [])
		var cur_tdps: float = float(current_click) * clicks_per_sec + _scenario_total_partner_dps(state, scenario, false)
		for bi: int in range(building_counts.size()):
			if not _scenario_can_buy_building(state, bi):
				continue
			var bcost: int = _scenario_building_cost(bi, int(building_counts[bi]), scenario)
			var value_gain: float = 0.5
			match _SC.get_bonus_type(bi):
				"partner_dps":
					value_gain = maxf(_scenario_total_partner_dps(state, scenario, false) * 0.01 * _scf(scenario, "building_effect_mult"), 0.5)
				"click_damage":
					value_gain = maxf(float(current_click) * clicks_per_sec * 0.01 * _scf(scenario, "building_effect_mult"), 0.5)
				"gold":
					value_gain = maxf(float(_scenario_enemy_reward(int(state.get("current_level", 1)), false, scenario)) * 0.01, 0.5)
				"ability_duration", "ability_cooldown":
					value_gain = maxf(cur_tdps * 0.005, 0.5)
				"boss_gold":
					value_gain = maxf(float(_scenario_enemy_reward(int(state.get("current_level", 1)), true, scenario)) * 0.005, 0.5)
			candidates.append({"type": "building", "index": bi, "cost": bcost, "value": value_gain / float(bcost)})

	if bool(profile.get("abilities", true)):
		_scenario_add_ability_candidates(candidates, state, scenario, clicks_per_sec)
	if bool(profile.get("skills", true)):
		_scenario_add_skill_candidates(candidates, state, scenario, clicks_per_sec)
	return candidates


func _scenario_add_ability_candidates(candidates: Array[Dictionary], state: Dictionary, scenario: Dictionary, clicks_per_sec: float) -> void:
	for ability_id in _AC.ABILITY_IDS:
		var aid: String = str(ability_id)
		if not _scenario_can_buy_or_rank_ability(state, aid):
			continue
		var cost: int = _scenario_next_ability_cost(state, aid, scenario)
		if cost <= 0:
			continue
		var value_gain: float = 0.5
		match aid:
			"autoclick":
				value_gain = maxf(float(_scenario_click_damage(state, scenario)) * _scenario_autoclick_hits_per_sec(state), 0.5)
			"gold_bonus":
				value_gain = maxf(float(_scenario_enemy_reward(int(state.get("current_level", 1)), false, scenario)), 0.5)
			"focus_burst":
				value_gain = maxf(float(_scenario_click_damage(state, scenario)) * clicks_per_sec, 0.5)
			"rally":
				value_gain = maxf(_scenario_total_partner_dps(state, scenario, false), 0.5)
		candidates.append({"type": "ability", "id": aid, "cost": cost, "value": value_gain / float(cost)})


func _scenario_add_skill_candidates(candidates: Array[Dictionary], state: Dictionary, scenario: Dictionary, clicks_per_sec: float) -> void:
	var click_dps: float = float(_scenario_click_damage(state, scenario)) * clicks_per_sec
	var partner_dps: float = _scenario_total_partner_dps(state, scenario, false)
	var reward: float = float(_scenario_enemy_reward(int(state.get("current_level", 1)), false, scenario))
	for skill: Dictionary in _HSC.SKILL_DEFINITIONS:
		var sid: String = str(skill.get("id", ""))
		if not _scenario_can_buy_hero_skill(state, sid):
			continue
		var cost: int = _scenario_hero_skill_cost(skill, scenario)
		candidates.append({
			"type": "hero_skill",
			"id": sid,
			"cost": cost,
			"value": _sim_skill_value_gain(skill, click_dps, partner_dps, reward) / float(cost),
		})
	for skill: Dictionary in _PSC.SKILL_DEFINITIONS:
		var sid: String = str(skill.get("id", ""))
		if not _scenario_can_buy_partner_skill(state, sid):
			continue
		var cost: int = _scenario_partner_skill_cost(skill, scenario)
		candidates.append({
			"type": "partner_skill",
			"id": sid,
			"cost": cost,
			"value": _sim_skill_value_gain(skill, click_dps, partner_dps, reward) / float(cost),
		})


func _scenario_apply_purchase(state: Dictionary, purchase: Dictionary) -> void:
	var cost: int = int(purchase.get("cost", 0))
	state["gold"] = maxi(0, int(state.get("gold", 0)) - cost)
	match str(purchase.get("type", "")):
		"hero":
			state["hero_level"] = int(state.get("hero_level", 1)) + 1
		"partner":
			var partner_counts: Array = state.get("partner_counts", [])
			var pi: int = int(purchase.get("index", -1))
			if pi >= 0 and pi < partner_counts.size():
				partner_counts[pi] = int(partner_counts[pi]) + 1
				state["partner_counts"] = partner_counts
		"building":
			var building_counts: Array = state.get("building_counts", [])
			var bi: int = int(purchase.get("index", -1))
			if bi >= 0 and bi < building_counts.size():
				building_counts[bi] = int(building_counts[bi]) + 1
				state["building_counts"] = building_counts
		"ability":
			var aid: String = str(purchase.get("id", ""))
			var purchased: Dictionary = state.get("purchased_abilities", {})
			var ranks: Dictionary = state.get("ability_ranks", {})
			if bool(purchased.get(aid, false)):
				ranks[aid] = mini(int(ranks.get(aid, 0)) + 1, 5)
			else:
				purchased[aid] = true
				ranks[aid] = int(ranks.get(aid, 0))
			state["purchased_abilities"] = purchased
			state["ability_ranks"] = ranks
		"hero_skill":
			var hero_ids: Array = state.get("purchased_hero_skill_ids", [])
			hero_ids.append(str(purchase.get("id", "")))
			state["purchased_hero_skill_ids"] = hero_ids
		"partner_skill":
			var partner_ids: Array = state.get("purchased_partner_skill_ids", [])
			partner_ids.append(str(purchase.get("id", "")))
			state["purchased_partner_skill_ids"] = partner_ids


func _scenario_update_visible_partners(state: Dictionary, scenario: Dictionary) -> void:
	var partner_counts: Array = state.get("partner_counts", [])
	var visible_count: int = int(state.get("visible_partner_count", 2))
	while visible_count < partner_counts.size():
		var prev_index: int = visible_count - 1
		if prev_index < 0:
			break
		var prev_next_cost: int = _scenario_partner_cost(prev_index, int(partner_counts[prev_index]), scenario)
		if int(state.get("gold", 0)) < prev_next_cost:
			break
		visible_count += 1
	state["visible_partner_count"] = visible_count


func _scenario_update_ability_usage(state: Dictionary, scenario: Dictionary, profile: Dictionary, ability_state: Dictionary, sim_time: float) -> void:
	if not bool(profile.get("abilities", true)):
		return
	var active_until: Dictionary = ability_state.get("active_until", {})
	var ready_at: Dictionary = ability_state.get("ready_at", {})
	for ability_id in _AC.ABILITY_IDS:
		var aid: String = str(ability_id)
		if not _scenario_is_ability_purchased(state, aid):
			continue
		if (aid == "focus_burst" or aid == "rally") and not _scenario_is_boss_level(int(state.get("current_level", 1))):
			continue
		if sim_time >= float(ready_at.get(aid, 0.0)):
			active_until[aid] = sim_time + _scenario_ability_duration(state, aid)
			ready_at[aid] = sim_time + _scenario_ability_cooldown(state, aid)
	ability_state["active_until"] = active_until
	ability_state["ready_at"] = ready_at


func _scenario_combat_stats(state: Dictionary, scenario: Dictionary, profile: Dictionary, ability_state: Dictionary, sim_time: float, clicks_per_sec: float) -> Dictionary:
	var click_damage: int = _scenario_click_damage(state, scenario)
	var manual_dps: float = float(click_damage) * clicks_per_sec
	var partner_dps: float = _scenario_total_partner_dps(state, scenario, _scenario_is_boss_level(int(state.get("current_level", 1))))
	var ability_dps: float = 0.0
	if bool(profile.get("abilities", true)):
		if _scenario_is_ability_active(ability_state, "autoclick", sim_time):
			ability_dps += float(click_damage) * _scenario_autoclick_hits_per_sec(state)
		if _scenario_is_ability_active(ability_state, "focus_burst", sim_time):
			manual_dps *= _scenario_ability_multiplier(state, "focus_burst")
		if _scenario_is_ability_active(ability_state, "rally", sim_time):
			partner_dps *= _scenario_ability_multiplier(state, "rally")
	return {
		"click_damage": click_damage,
		"manual_dps": manual_dps,
		"partner_dps": partner_dps,
		"ability_dps": ability_dps,
		"total_dps": manual_dps + partner_dps + ability_dps,
	}


func _scenario_advance_after_defeat(state: Dictionary) -> void:
	var level: int = int(state.get("current_level", 1))
	if _scenario_is_boss_level(level):
		state["current_level"] = level + 1
		state["defeated_in_level"] = 0
		return
	var defeated: int = int(state.get("defeated_in_level", 0)) + 1
	if defeated >= SCENARIO_ENEMIES_PER_LEVEL:
		state["current_level"] = level + 1
		state["defeated_in_level"] = 0
	else:
		state["defeated_in_level"] = defeated


func _scenario_enemy_hp(level: int, is_boss: bool, scenario: Dictionary) -> int:
	var zd: Dictionary = _ZC.get_zone_data_for_level(level)
	var base_hp: int = _EC.get_base_hp(level, _BC.ENEMY_HP_BASE, _BC.ENEMY_HP_GROWTH)
	var hp: int = _EC.get_scaled_hp(base_hp, float(zd.get("hp_multiplier", 1.0)), is_boss, false, _BC.BOSS_HP_MULTIPLIER, _BC.ELITE_HP_MULTIPLIER)
	var mult: float = _scf(scenario, "enemy_hp_mult")
	if is_boss:
		mult *= _scf(scenario, "boss_hp_mult")
	return maxi(1, int(round(float(hp) * mult)))


func _scenario_enemy_reward(level: int, is_boss: bool, scenario: Dictionary) -> int:
	var zd: Dictionary = _ZC.get_zone_data_for_level(level)
	var base_reward: int = _EC.get_base_reward(level, _BC.ENEMY_REWARD_BASE, _BC.ENEMY_REWARD_GROWTH)
	var reward: int = _EC.get_scaled_reward(base_reward, float(zd.get("reward_multiplier", 1.0)), is_boss, false, _BC.BOSS_REWARD_MULTIPLIER, _BC.ELITE_REWARD_MULTIPLIER)
	var mult: float = _scf(scenario, "enemy_reward_mult")
	if is_boss:
		mult *= _scf(scenario, "boss_reward_mult")
	return maxi(1, int(round(float(reward) * mult)))


func _scenario_hero_damage(hero_level: int, scenario: Dictionary) -> int:
	var base_pre: float = _BC.HERO_BASE_DAMAGE + float(hero_level) * _BC.HERO_DAMAGE_PER_LEVEL
	var ms_mult: int = _MC.get_milestone_multiplier(hero_level, _BC.MILESTONE_LEVELS, _BC.MILESTONE_MULTIPLIER_PER_REACHED)
	return maxi(1, int(round(float(maxi(1, int(base_pre) * ms_mult)) * _scf(scenario, "hero_damage_mult"))))


func _scenario_hero_cost(hero_level: int, scenario: Dictionary) -> int:
	var delta: float = _scf(scenario, "hero_cost_growth_delta", 0.0)
	var cost: int = _CC.get_hero_level_cost(
		hero_level,
		_BC.HERO_BASE_COST,
		maxf(1.0, _BC.HERO_COST_GROWTH_EARLY + delta),
		maxf(1.0, _BC.HERO_COST_GROWTH_MID + delta),
		maxf(1.0, _BC.HERO_COST_GROWTH_LATE + delta),
		_BC.HERO_COST_MID_START_LEVEL,
		_BC.HERO_COST_LATE_START_LEVEL,
		_BC.MILESTONE_LEVELS,
		_BC.MILESTONE_COST_MULTIPLIER)
	return maxi(1, int(round(float(cost) * _scf(scenario, "hero_cost_mult"))))


func _get_balance_scenario_by_id(scenario_id: String) -> Dictionary:
	for scenario: Dictionary in BALANCE_SCENARIOS:
		if str(scenario.get("id", "")) == scenario_id:
			return scenario
	return {}


func _get_scenario_partner_curve(scenario_id: String) -> Dictionary:
	match scenario_id:
		"partner_curve_balanced_idle":
			return {
				"base_dps": 4.0,
				"base_cost": 35.0,
				"cost_growth": 8.0,
				"dps_growth": 8.8,
				"efficiency_growth": 1.04,
				"max_partners": _BC.PARTNER_DPS_VALUES.size(),
			}
		"partner_curve_soft_idle":
			return {
				"base_dps": 4.0,
				"base_cost": 35.0,
				"cost_growth": 7.0,
				"dps_growth": 7.5,
				"efficiency_growth": 1.03,
				"max_partners": _BC.PARTNER_DPS_VALUES.size(),
			}
		"partner_curve_power_idle":
			return {
				"base_dps": 4.0,
				"base_cost": 35.0,
				"cost_growth": 10.0,
				"dps_growth": 12.0,
				"efficiency_growth": 1.07,
				"max_partners": _BC.PARTNER_DPS_VALUES.size(),
			}
		"partner_curve_late_power":
			return {
				"base_dps": 4.0,
				"base_cost": 35.0,
				"cost_growth": 9.0,
				"dps_growth": 10.0,
				"late_dps_growth": 10.8,
				"late_start_index": 10,
				"efficiency_growth": 1.05,
				"max_partners": _BC.PARTNER_DPS_VALUES.size(),
			}
	return {}


func _scenario_has_partner_curve(scenario: Dictionary) -> bool:
	return not _get_scenario_partner_curve(str(scenario.get("partner_curve_id", scenario.get("id", "")))).is_empty()


func _scenario_partner_base_dps(partner_index: int, scenario: Dictionary) -> int:
	if partner_index < 0 or partner_index >= _BC.PARTNER_DPS_VALUES.size():
		return 0
	var curve: Dictionary = _get_scenario_partner_curve(str(scenario.get("partner_curve_id", scenario.get("id", ""))))
	if curve.is_empty():
		return int(_BC.PARTNER_DPS_VALUES[partner_index])
	var dps_growth: float = float(curve.get("dps_growth", 1.0))
	var late_start: int = int(curve.get("late_start_index", 999999))
	if partner_index > late_start:
		var late_growth: float = float(curve.get("late_dps_growth", dps_growth))
		var early: float = pow(dps_growth, late_start)
		var late: float = pow(late_growth, partner_index - late_start)
		return _scenario_safe_curve_int(float(curve.get("base_dps", 1.0)) * early * late)
	return _scenario_safe_curve_int(float(curve.get("base_dps", 1.0)) * pow(dps_growth, partner_index))


func _scenario_partner_base_cost(partner_index: int, scenario: Dictionary) -> int:
	if partner_index < 0 or partner_index >= _BC.PARTNER_BASE_COSTS.size():
		return 0
	var curve: Dictionary = _get_scenario_partner_curve(str(scenario.get("partner_curve_id", scenario.get("id", ""))))
	if curve.is_empty():
		return int(_BC.PARTNER_BASE_COSTS[partner_index])
	return _scenario_safe_curve_int(float(curve.get("base_cost", 1.0)) * pow(float(curve.get("cost_growth", 1.0)), partner_index))


func _scenario_partner_base_costs(scenario: Dictionary) -> Array[int]:
	var scenario_id: String = str(scenario.get("partner_curve_id", scenario.get("id", "")))
	if _scenario_partner_base_cost_cache.has(scenario_id):
		return (_scenario_partner_base_cost_cache[scenario_id] as Array[int]).duplicate()
	var base_costs: Array[int] = []
	for pi: int in range(_BC.PARTNER_BASE_COSTS.size()):
		base_costs.append(_scenario_partner_base_cost(pi, scenario))
	_scenario_partner_base_cost_cache[scenario_id] = base_costs
	return base_costs.duplicate()


func _scenario_safe_curve_int(value: float) -> int:
	if not is_finite(value):
		return 9_000_000_000_000_000
	return maxi(1, int(round(minf(value, 9_000_000_000_000_000.0))))


func _scenario_partner_tier_total_dps(partner_index: int, owned_count: int, scenario: Dictionary) -> int:
	if partner_index < 0 or owned_count <= 0:
		return 0
	var ms_mult: int = _MC.get_milestone_multiplier(owned_count, _BC.MILESTONE_LEVELS, _BC.MILESTONE_MULTIPLIER_PER_REACHED)
	var dps: float = float(owned_count * _scenario_partner_base_dps(partner_index, scenario) * ms_mult)
	return maxi(0, int(round(dps * _scf(scenario, "partner_dps_mult"))))


func _scenario_partner_dps(partner_index: int, count: int, scenario: Dictionary) -> int:
	return _scenario_partner_tier_total_dps(partner_index, count, scenario)


func _scenario_partner_cost(partner_index: int, owned_count: int, scenario: Dictionary) -> int:
	var delta: float = _scf(scenario, "partner_cost_growth_delta", 0.0)
	if _scenario_has_partner_curve(scenario):
		var generated_cost: int = _CC.get_partner_cost(
			partner_index,
			owned_count,
			_scenario_partner_base_costs(scenario),
			maxf(1.0, _BC.PARTNER_COST_GROWTH_EARLY + delta),
			maxf(1.0, _BC.PARTNER_COST_GROWTH_MID + delta),
			maxf(1.0, _BC.PARTNER_COST_GROWTH_LATE + delta),
			_BC.PARTNER_COST_MID_START_COUNT,
			_BC.PARTNER_COST_LATE_START_COUNT,
			_BC.MILESTONE_LEVELS,
			_BC.MILESTONE_COST_MULTIPLIER)
		return maxi(1, int(round(float(generated_cost) * _scf(scenario, "partner_cost_mult"))))
	var cost: int = _CC.get_partner_cost(
		partner_index,
		owned_count,
		_BC.PARTNER_BASE_COSTS,
		maxf(1.0, _BC.PARTNER_COST_GROWTH_EARLY + delta),
		maxf(1.0, _BC.PARTNER_COST_GROWTH_MID + delta),
		maxf(1.0, _BC.PARTNER_COST_GROWTH_LATE + delta),
		_BC.PARTNER_COST_MID_START_COUNT,
		_BC.PARTNER_COST_LATE_START_COUNT,
		_BC.MILESTONE_LEVELS,
		_BC.MILESTONE_COST_MULTIPLIER)
	return maxi(1, int(round(float(cost) * _scf(scenario, "partner_cost_mult"))))


func _scenario_building_cost(building_index: int, owned_count: int, scenario: Dictionary) -> int:
	var cost: int = _CC.get_building_cost(building_index, owned_count, _BC.BUILDING_BASE_COSTS, _BC.BUILDING_COST_GROWTH)
	return maxi(1, int(round(float(cost) * _scf(scenario, "building_cost_mult"))))


func _scenario_ability_cost(base_cost: int, scenario: Dictionary) -> int:
	return maxi(1, int(round(float(base_cost) * _scf(scenario, "ability_cost_mult"))))


func _scenario_click_damage(state: Dictionary, scenario: Dictionary) -> int:
	var value: float = float(_scenario_hero_damage(int(state.get("hero_level", 1)), scenario))
	value *= _scenario_click_building_multiplier(state, scenario)
	value *= _scenario_hero_skill_bonus_multiplier(state, "click_damage")
	value *= _scenario_partner_skill_bonus_multiplier(state, "click_damage")
	value *= _scenario_partner_skill_bonus_multiplier(state, "all_damage")
	return maxi(1, int(round(value)))


func _scenario_total_partner_dps(state: Dictionary, scenario: Dictionary, boss_context: bool) -> float:
	var partner_counts: Array = state.get("partner_counts", [])
	var total: float = 0.0
	for pi: int in range(partner_counts.size()):
		total += float(_scenario_partner_dps(pi, int(partner_counts[pi]), scenario)) * _scenario_own_partner_skill_multiplier(state, pi)
	total *= _scenario_partner_building_multiplier(state, scenario)
	total *= _scenario_hero_skill_bonus_multiplier(state, "partner_dps")
	total *= _scenario_partner_skill_bonus_multiplier(state, "partner_dps")
	total *= _scenario_partner_skill_bonus_multiplier(state, "all_damage")
	return total


func _scenario_click_building_multiplier(state: Dictionary, scenario: Dictionary) -> float:
	return 1.0 + _scenario_building_bonus_fraction(state, 2, scenario)


func _scenario_partner_building_multiplier(state: Dictionary, scenario: Dictionary) -> float:
	return 1.0 + _scenario_building_bonus_fraction(state, 0, scenario)


func _scenario_gold_multiplier(state: Dictionary, scenario: Dictionary, ability_state: Dictionary, sim_time: float) -> float:
	var mult: float = 1.0 + _scenario_building_bonus_fraction(state, 1, scenario)
	mult *= _scenario_hero_skill_bonus_multiplier(state, "gold")
	mult *= _scenario_partner_skill_bonus_multiplier(state, "gold")
	if _scenario_is_ability_active(ability_state, "gold_bonus", sim_time):
		mult *= _scenario_ability_multiplier(state, "gold_bonus")
	return mult


func _scenario_boss_gold_multiplier(state: Dictionary, scenario: Dictionary) -> float:
	return 1.0 + _scenario_building_bonus_fraction(state, 5, scenario)


func _scenario_building_bonus_fraction(state: Dictionary, building_index: int, scenario: Dictionary) -> float:
	var building_counts: Array = state.get("building_counts", [])
	if building_index < 0 or building_index >= building_counts.size():
		return 0.0
	var count: int = int(building_counts[building_index])
	var ms_mult: int = _MC.get_milestone_multiplier(count, _BC.MILESTONE_LEVELS, _BC.MILESTONE_MULTIPLIER_PER_REACHED)
	var percent: float = float(count * _BC.BUILDING_BONUS_PERCENT_PER_LEVEL * ms_mult) * _scf(scenario, "building_effect_mult")
	return percent / 100.0


func _scenario_can_buy_building(state: Dictionary, building_index: int) -> bool:
	if building_index <= 0:
		return true
	var building_counts: Array = state.get("building_counts", [])
	if building_index >= building_counts.size():
		return false
	return int(building_counts[building_index - 1]) > 0


func _scenario_can_buy_or_rank_ability(state: Dictionary, ability_id: String) -> bool:
	if not _scenario_is_ability_purchased(state, ability_id):
		return int(state.get("hero_level", 1)) >= _AC.get_unlock_level(ability_id)
	return _scenario_ability_rank(state, ability_id) < 5


func _scenario_can_buy_hero_skill(state: Dictionary, skill_id: String) -> bool:
	var purchased_ids: Array = state.get("purchased_hero_skill_ids", [])
	if purchased_ids.has(skill_id):
		return false
	var skill: Dictionary = _HSC.get_by_id(skill_id)
	if skill.is_empty():
		return false
	if int(state.get("hero_level", 1)) < int(skill.get("unlock_character_level", 0)):
		return false
	return _scenario_hero_skill_cost(skill, {}) > 0


func _scenario_can_buy_partner_skill(state: Dictionary, skill_id: String) -> bool:
	var purchased_ids: Array = state.get("purchased_partner_skill_ids", [])
	if purchased_ids.has(skill_id):
		return false
	var skill: Dictionary = _PSC.get_by_id(skill_id)
	if skill.is_empty():
		return false
	var partner_counts: Array = state.get("partner_counts", [])
	var partner_index: int = int(skill.get("partner_index", -1))
	if partner_index < 0 or partner_index >= partner_counts.size():
		return false
	if int(partner_counts[partner_index]) < int(skill.get("unlock_count", 0)):
		return false
	return _scenario_partner_skill_cost(skill, {}) > 0


func _scenario_hero_skill_cost(skill: Dictionary, scenario: Dictionary) -> int:
	var skill_level: int = int(skill.get("skill_level", 0))
	var unlock_level: int = int(skill.get("unlock_character_level", 0))
	if skill_level < 1 or skill_level > _BC.HERO_SKILL_COST_MULTIPLIERS.size() or unlock_level <= 1:
		return 0
	return _scenario_hero_cost(unlock_level - 1, scenario) * int(_BC.HERO_SKILL_COST_MULTIPLIERS[skill_level - 1])


func _scenario_partner_skill_cost(skill: Dictionary, scenario: Dictionary) -> int:
	var partner_index: int = int(skill.get("partner_index", -1))
	var unlock_count: int = int(skill.get("unlock_count", 0))
	var skill_level: int = int(skill.get("skill_level", 0))
	if partner_index < 0 or unlock_count <= 0 or skill_level < 1 or skill_level > _BC.PARTNER_SKILL_COST_MULTIPLIERS.size():
		return 0
	return _scenario_partner_cost(partner_index, unlock_count - 1, scenario) * int(_BC.PARTNER_SKILL_COST_MULTIPLIERS[skill_level - 1])


func _scenario_next_ability_cost(state: Dictionary, ability_id: String, scenario: Dictionary) -> int:
	if not _scenario_is_ability_purchased(state, ability_id):
		return _scenario_ability_cost(_AC.get_purchase_cost(ability_id), scenario)
	var rank: int = _scenario_ability_rank(state, ability_id)
	if rank < 0 or rank >= _BC.ABILITY_SKILL_COST_MULTIPLIERS.size():
		return 0
	var base_cost: int = _AC.get_purchase_cost(ability_id)
	return _scenario_ability_cost(base_cost * int(_BC.ABILITY_SKILL_COST_MULTIPLIERS[rank]), scenario)


func _scenario_is_ability_purchased(state: Dictionary, ability_id: String) -> bool:
	var purchased: Dictionary = state.get("purchased_abilities", {})
	return bool(purchased.get(ability_id, false))


func _scenario_ability_rank(state: Dictionary, ability_id: String) -> int:
	var ranks: Dictionary = state.get("ability_ranks", {})
	return clampi(int(ranks.get(ability_id, 0)), 0, 5)


func _scenario_ability_multiplier(state: Dictionary, ability_id: String) -> float:
	var rank: int = _scenario_ability_rank(state, ability_id)
	return _BC.ABILITY_BASE_MULTIPLIER + _BC.ABILITY_RANK_MULTIPLIER_STEP * float(rank)


func _scenario_autoclick_hits_per_sec(state: Dictionary) -> float:
	return _BC.AUTOCLICK_BASE_HITS_PER_SEC * (1.0 + _BC.AUTOCLICK_RANK_RATE_STEP * float(_scenario_ability_rank(state, "autoclick")))


func _scenario_ability_duration(state: Dictionary, ability_id: String) -> float:
	match ability_id:
		"autoclick":
			return float(_BC.AUTOCLICK_BASE_DURATION_SEC + _scenario_ability_rank(state, "autoclick") * _BC.AUTOCLICK_RANK_DURATION_BONUS_SEC)
		"gold_bonus":
			return _BC.GOLD_BONUS_BASE_DURATION_SEC
		"focus_burst":
			return _BC.FOCUS_BURST_BASE_DURATION_SEC
		"rally":
			return _BC.RALLY_BASE_DURATION_SEC
	return 0.0


func _scenario_ability_cooldown(state: Dictionary, ability_id: String) -> float:
	match ability_id:
		"autoclick":
			return _BC.AUTOCLICK_COOLDOWN_SEC
		"gold_bonus":
			return _BC.GOLD_BONUS_COOLDOWN_SEC
		"focus_burst":
			return _BC.FOCUS_BURST_COOLDOWN_SEC
		"rally":
			return _BC.RALLY_COOLDOWN_SEC
	return 0.0


func _scenario_hero_skill_bonus_multiplier(state: Dictionary, bonus_type: String) -> float:
	var total_bonus: float = 0.0
	var purchased_ids: Array = state.get("purchased_hero_skill_ids", [])
	for skill: Dictionary in _HSC.SKILL_DEFINITIONS:
		var sid: String = str(skill.get("id", ""))
		if not purchased_ids.has(sid):
			continue
		if str(skill.get("bonus_type", "")) == bonus_type:
			total_bonus += float(skill.get("bonus_value", 0.0))
	return 1.0 + total_bonus


func _scenario_partner_skill_bonus_multiplier(state: Dictionary, bonus_type: String) -> float:
	var total_bonus: float = 0.0
	var purchased_ids: Array = state.get("purchased_partner_skill_ids", [])
	for skill: Dictionary in _PSC.SKILL_DEFINITIONS:
		var sid: String = str(skill.get("id", ""))
		if not purchased_ids.has(sid):
			continue
		if str(skill.get("bonus_type", "")) == bonus_type:
			total_bonus += float(skill.get("bonus_value", 0.0))
	return 1.0 + total_bonus


func _scenario_own_partner_skill_multiplier(state: Dictionary, partner_index: int) -> float:
	var total_bonus: float = 0.0
	var purchased_ids: Array = state.get("purchased_partner_skill_ids", [])
	for skill: Dictionary in _PSC.SKILL_DEFINITIONS:
		if int(skill.get("partner_index", -1)) != partner_index:
			continue
		if str(skill.get("bonus_type", "")) != "own_partner_dps":
			continue
		if purchased_ids.has(str(skill.get("id", ""))):
			total_bonus += float(skill.get("bonus_value", 0.0))
	return 1.0 + total_bonus


func _scenario_is_ability_active(ability_state: Dictionary, ability_id: String, sim_time: float) -> bool:
	var active_until: Dictionary = ability_state.get("active_until", {})
	return sim_time < float(active_until.get(ability_id, 0.0))


func _scenario_is_boss_level(level: int) -> bool:
	return level % _ZC.BOSS_LEVEL_INTERVAL == 0


func _scenario_prestige_reward(level: int, hero_level: int) -> int:
	return int(level / float(_BC.PRESTIGE_REQUIRED_LEVEL)) + int(hero_level / _BC.PRESTIGE_CHARACTER_INTERVAL)


func _prestige_talent_cost_for_level(level: int) -> int:
	var safe_level: int = maxi(level, 0)
	return maxi(
		_BC.PRESTIGE_TALENT_BASE_COST,
		ceili(float(_BC.PRESTIGE_TALENT_BASE_COST) * pow(_BC.PRESTIGE_TALENT_COST_GROWTH, float(safe_level)))
	)


func _prestige_talent_bonus_percent_per_level(talent_index: int) -> int:
	match _PRC.get_effect_type(talent_index):
		"damage", "click_damage", "partner_dps", "boss_damage", "all_damage":
			return _BC.PRESTIGE_DAMAGE_TALENT_BONUS_PERCENT_PER_LEVEL
		"gold", "gold_reward", "gold_income":
			return _BC.PRESTIGE_GOLD_TALENT_BONUS_PERCENT_PER_LEVEL
		_:
			return _BC.PRESTIGE_UTILITY_TALENT_BONUS_PERCENT_PER_LEVEL


func _validate_prestige_formulas() -> void:
	var state = _CS.new()
	var failures: PackedStringArray = PackedStringArray()

	var cost_expectations: Dictionary = {
		0: 2,
		1: 3,
		2: 5,
	}
	for level: int in cost_expectations.keys():
		var actual_cost: int = state.get_prestige_talent_cost_for_level(level)
		var expected_cost: int = int(cost_expectations[level])
		if actual_cost != expected_cost:
			failures.append("cost_for_level(%d) expected %d got %d" % [level, expected_cost, actual_cost])

	state.current_level = 99
	if state.get_prestige_stage_points() != 0:
		failures.append("stage points at 99 expected 0 got %d" % state.get_prestige_stage_points())
	state.current_level = 100
	if state.get_prestige_stage_points() != 1:
		failures.append("stage points at 100 expected 1 got %d" % state.get_prestige_stage_points())

	state.character_level = 199
	if state.get_prestige_character_points() != 0:
		failures.append("hero points at 199 expected 0 got %d" % state.get_prestige_character_points())
	state.character_level = 200
	if state.get_prestige_character_points() != 1:
		failures.append("hero points at 200 expected 1 got %d" % state.get_prestige_character_points())

	if state.get_prestige_talent_bonus_percent_for_level(0, 1) != 25:
		failures.append("damage talent level 1 bonus expected 25 got %d" % state.get_prestige_talent_bonus_percent_for_level(0, 1))
	if state.get_prestige_talent_bonus_percent_for_level(1, 1) != 50:
		failures.append("gold talent level 1 bonus expected 50 got %d" % state.get_prestige_talent_bonus_percent_for_level(1, 1))

	if failures.is_empty():
		_ln("")
		_ln("  Prestige formula validation: OK")
		return

	for failure: String in failures:
		_warn("Prestige formula validation failed: %s" % failure)


func _print_scenario_profile_row(result: Dictionary) -> void:
	var total_dps: float = float(result.get("total_dps", 0.0))
	var manual_pct: float = float(result.get("manual_dps", 0.0)) / total_dps * 100.0 if total_dps > 0.0 else 0.0
	var partner_pct: float = float(result.get("partner_dps", 0.0)) / total_dps * 100.0 if total_dps > 0.0 else 0.0
	var ability_pct: float = float(result.get("ability_dps", 0.0)) / total_dps * 100.0 if total_dps > 0.0 else 0.0
	var wall_text: String = str(int(result.get("wall_level", -1))) if int(result.get("wall_level", -1)) > 0 else "none"
	var prestige_text: String = str(int(result.get("first_prestige_reward", 0)))
	var notes: String = str(result.get("stopped_reason", ""))
	_ln(_row([
		_lj(str(result.get("scenario_id", "")).left(21), 22),
		_lj(str(result.get("profile_id", "")).left(19), 20),
		_rj(str(int(result.get("reached_level", 0))), 6),
		_rj(_fmt_time(float(result.get("sim_time", 0.0))), 8),
		_rj(wall_text, 6),
		_rj(prestige_text, 8),
		_rj("%.0f%%" % manual_pct, 8),
		_rj("%.0f%%" % partner_pct, 9),
		_rj("%.0f%%" % ability_pct, 9),
		notes,
	]))


func _append_scenario_csv_rows(result: Dictionary) -> void:
	var scenario_id: String = str(result.get("scenario_id", ""))
	var profile_id: String = str(result.get("profile_id", ""))
	var reached_level: int = int(result.get("reached_level", 0))
	var sim_time: float = float(result.get("sim_time", 0.0))
	var wall_level: int = int(result.get("wall_level", -1))
	var focus_metrics: String = _scenario_focus_metrics_note(result)
	_csv_append(
		"scenario_summary", reached_level,
		0, 0, 0, int(result.get("click_damage", 0)), int(result.get("total_dps", 0.0)), sim_time,
		"scenario_id=%s profile_id=%s reached_level=%d sim_time=%.0f stopped_reason=%s wall_level=%d hero_level=%d gold=%d click_damage=%d manual_dps=%d partner_dps=%d ability_dps=%d current_ability_dps=%d cumulative_ability_damage=%d used_abilities=%s currently_active_abilities=%s total_dps=%d first_prestige_time=%s first_prestige_reward=%d %s" % [
			scenario_id, profile_id, reached_level, sim_time, str(result.get("stopped_reason", "")),
			wall_level, int(result.get("hero_level", 1)), int(result.get("gold", 0)), int(result.get("click_damage", 0)),
			int(result.get("manual_dps", 0.0)), int(result.get("partner_dps", 0.0)), int(result.get("ability_dps", 0.0)),
			int(result.get("current_ability_dps", 0.0)), int(result.get("cumulative_ability_damage", 0)),
			str(result.get("used_abilities", "none")), str(result.get("currently_active_abilities", "none")),
			int(result.get("total_dps", 0.0)), _scenario_time_note(float(result.get("first_prestige_time", -1.0))),
			int(result.get("first_prestige_reward", 0)), focus_metrics,
		]
	)
	_csv_append(
		"scenario_profile_comparison", reached_level,
		0, 0, 0, int(result.get("click_damage", 0)), int(result.get("total_dps", 0.0)), sim_time,
		"scenario_id=%s profile_id=%s label=%s stopped_reason=%s wall_level=%d total_dps=%d manual_share=%.1f partner_share=%.1f ability_share=%.1f current_ability_dps=%d cumulative_ability_damage=%d used_abilities=%s currently_active_abilities=%s active_abilities=%s %s" % [
			scenario_id, profile_id, str(result.get("scenario_label", "")), str(result.get("stopped_reason", "")),
			wall_level, int(result.get("total_dps", 0.0)),
			_scenario_share(float(result.get("manual_dps", 0.0)), float(result.get("total_dps", 0.0))),
			_scenario_share(float(result.get("partner_dps", 0.0)), float(result.get("total_dps", 0.0))),
			_scenario_share(float(result.get("ability_dps", 0.0)), float(result.get("total_dps", 0.0))),
			int(result.get("current_ability_dps", 0.0)), int(result.get("cumulative_ability_damage", 0)),
			str(result.get("used_abilities", "none")), str(result.get("currently_active_abilities", "none")),
			_scenario_purchased_abilities_note(result), focus_metrics,
		]
	)
	if wall_level > 0:
		var wall: Dictionary = result.get("boss_wall", {})
		_csv_append(
			"scenario_boss_wall", wall_level,
			int(wall.get("boss_hp", 0)), 0, 0, 0, int(wall.get("current_dps", 0.0)), float(wall.get("boss_ttk", 0.0)),
			"scenario_id=%s profile_id=%s boss_level=%d boss_hp=%d boss_ttk=%.1f boss_time_limit=%.0f required_dps=%d current_dps=%d missing_dps=%d missing_dps_percent=%.1f manual_dps=%d partner_dps=%d ability_dps=%d current_ability_dps=%d cumulative_ability_damage=%d used_abilities=%s currently_active_abilities=%s active_abilities=%s" % [
				scenario_id, profile_id, wall_level, int(wall.get("boss_hp", 0)), float(wall.get("boss_ttk", 0.0)),
				float(_BC.BOSS_TIME_LIMIT), int(wall.get("required_dps", 0.0)), int(wall.get("current_dps", 0.0)),
				int(wall.get("missing_dps", 0.0)), float(wall.get("missing_dps_percent", 0.0)),
				int(result.get("manual_dps", 0.0)), int(result.get("partner_dps", 0.0)), int(result.get("ability_dps", 0.0)),
				int(result.get("current_ability_dps", 0.0)), int(result.get("cumulative_ability_damage", 0)),
				str(result.get("used_abilities", "none")), str(result.get("currently_active_abilities", "none")),
				_scenario_purchased_abilities_note(result),
			]
		)
	_append_scenario_partner_summary(result)
	_append_scenario_building_summary(result)
	_append_scenario_ability_summary(result)
	_append_scenario_skill_summary(result)


func _append_scenario_partner_summary(result: Dictionary) -> void:
	var scenario_id: String = str(result.get("scenario_id", ""))
	var profile_id: String = str(result.get("profile_id", ""))
	var scenario: Dictionary = result.get("scenario", _get_balance_scenario_by_id(scenario_id))
	var partner_counts: Array = result.get("partner_counts", [])
	var total_tier_dps: int = 0
	for pi_total: int in range(partner_counts.size()):
		total_tier_dps += _scenario_partner_tier_total_dps(pi_total, int(partner_counts[pi_total]), scenario)
	var emitted: bool = false
	for pi: int in range(partner_counts.size()):
		var owned: int = int(partner_counts[pi])
		if owned <= 0:
			continue
		emitted = true
		var base_dps: int = _scenario_partner_base_dps(pi, scenario)
		var tier_dps: int = _scenario_partner_tier_total_dps(pi, owned, scenario)
		var next_cost: int = _scenario_partner_cost(pi, owned, scenario)
		var share_pct: float = float(tier_dps) / float(total_tier_dps) * 100.0 if total_tier_dps > 0 else 0.0
		_csv_append(
			"scenario_partner_summary", pi + 1,
			0, 0, next_cost, 0, tier_dps, 0.0,
			"scenario_id=%s profile_id=%s partner_index=%d partner_name=%s owned_count=%d base_dps=%d tier_total_dps=%d next_cost=%d dps_share_percent=%.1f" % [
				scenario_id, profile_id, pi, _partner_name(pi), owned, base_dps, tier_dps, next_cost, share_pct,
			]
		)
	if not emitted:
		_csv_append("scenario_partner_summary", 0, 0, 0, 0, 0, 0, 0.0, "scenario_id=%s profile_id=%s no_partners_purchased" % [scenario_id, profile_id])


func _append_scenario_building_summary(result: Dictionary) -> void:
	var scenario_id: String = str(result.get("scenario_id", ""))
	var profile_id: String = str(result.get("profile_id", ""))
	var building_counts: Array = result.get("building_counts", [])
	var emitted: bool = false
	for bi: int in range(building_counts.size()):
		var owned: int = int(building_counts[bi])
		if owned <= 0:
			continue
		emitted = true
		_csv_append(
			"scenario_building_summary", bi + 1,
			0, 0, 0, 0, 0, 0.0,
			"scenario_id=%s profile_id=%s building_index=%d building_name=%s owned_count=%d" % [
				scenario_id, profile_id, bi, _building_name(bi), owned,
			]
		)
	if not emitted:
		_csv_append("scenario_building_summary", 0, 0, 0, 0, 0, 0, 0.0, "scenario_id=%s profile_id=%s no_buildings_purchased" % [scenario_id, profile_id])


func _append_scenario_ability_summary(result: Dictionary) -> void:
	var scenario_id: String = str(result.get("scenario_id", ""))
	var profile_id: String = str(result.get("profile_id", ""))
	var diagnostics_by_id: Dictionary = result.get("ability_diagnostics", {})
	var purchased: Dictionary = result.get("purchased_abilities", {})
	var ranks: Dictionary = result.get("ability_ranks", {})
	var idx: int = 1
	for ability_id in _AC.ABILITY_IDS:
		var aid: String = str(ability_id)
		var diagnostics: Dictionary = diagnostics_by_id.get(aid, {})
		var spent: int = int(diagnostics.get("spent", 0))
		var damage_contribution: float = float(diagnostics.get("estimated_damage_contributed", 0.0))
		var gold_contribution: float = float(diagnostics.get("estimated_gold_contributed", 0.0))
		var active_time: float = float(diagnostics.get("total_active_time", 0.0))
		var avg_dps: float = damage_contribution / active_time if active_time > 0.0 else 0.0
		_csv_append(
			"scenario_ability_summary", idx,
			0, int(gold_contribution), spent, int(damage_contribution), int(avg_dps), active_time,
			"scenario_id=%s profile_id=%s ability_id=%s purchased=%s rank=%d activations=%d total_active_time=%.1f estimated_damage_contributed=%d estimated_gold_contributed=%d current_ability_dps=%d cumulative_ability_damage=%d used_abilities=%s currently_active_abilities=%s" % [
				scenario_id, profile_id, aid, str(bool(purchased.get(aid, false))), int(ranks.get(aid, 0)),
				int(diagnostics.get("activations", 0)), active_time, int(damage_contribution), int(gold_contribution),
				int(result.get("current_ability_dps", 0.0)), int(result.get("cumulative_ability_damage", 0)),
				str(result.get("used_abilities", "none")), str(result.get("currently_active_abilities", "none")),
			]
		)
		idx += 1


func _append_scenario_skill_summary(result: Dictionary) -> void:
	var scenario_id: String = str(result.get("scenario_id", ""))
	var profile_id: String = str(result.get("profile_id", ""))
	var skill_spend: Dictionary = result.get("skill_spend", {})
	var hero_ids: PackedStringArray = _sim_to_packed_strings(result.get("purchased_hero_skill_ids", []))
	var partner_ids: PackedStringArray = _sim_to_packed_strings(result.get("purchased_partner_skill_ids", []))
	var ability_ids: PackedStringArray = _sim_to_packed_strings(result.get("purchased_ability_skill_ids", []))
	var total_spent: int = int(skill_spend.get("hero", 0)) + int(skill_spend.get("partner", 0)) + int(skill_spend.get("ability", 0))
	_csv_append(
		"scenario_skill_summary", 0,
		0, 0, total_spent, 0, 0, 0.0,
		"scenario_id=%s profile_id=%s purchased_hero_skills=%d hero_skill_ids=%s purchased_partner_skills=%d partner_skill_ids=%s purchased_ability_skills=%d ability_skill_ids=%s total_skill_spent=%d" % [
			scenario_id, profile_id, hero_ids.size(), _sim_join_ids(hero_ids),
			partner_ids.size(), _sim_join_ids(partner_ids), ability_ids.size(), _sim_join_ids(ability_ids), total_spent,
		]
	)


func _append_scenario_baseline_validation(result: Dictionary) -> void:
	var profile_id: String = str(result.get("profile_id", ""))
	if not _live_profile_results.has(profile_id):
		return
	var live: Dictionary = _live_profile_results[profile_id]
	var live_level: int = int(live.get("reached_level", 0))
	var scenario_level: int = int(result.get("reached_level", 0))
	var live_total_dps: float = float(live.get("total_dps", 0.0))
	var scenario_total_dps: float = float(result.get("total_dps", 0.0))
	var live_ability_dps: float = float(live.get("ability_dps", 0.0))
	var scenario_ability_dps: float = float(result.get("ability_dps", 0.0))
	var level_delta: int = scenario_level - live_level
	var total_dps_ratio: float = scenario_total_dps / live_total_dps if live_total_dps > 0.0 else (1.0 if scenario_total_dps <= 0.0 else 999.0)
	var ability_dps_ratio: float = scenario_ability_dps / live_ability_dps if live_ability_dps > 0.0 else (1.0 if scenario_ability_dps <= 0.0 else 999.0)
	var status: String = "ok"
	if absi(level_delta) > 5 or absf(total_dps_ratio - 1.0) > 0.15 or (live_ability_dps > 0.0 and scenario_ability_dps <= 0.0):
		status = "warn"
		_warn("Scenario baseline validation %s: level_delta=%d total_dps_ratio=%.2f ability_dps_ratio=%.2f." % [profile_id, level_delta, total_dps_ratio, ability_dps_ratio])
	_csv_append(
		"scenario_baseline_validation", scenario_level,
		0, 0, 0, int(result.get("click_damage", 0)), int(scenario_total_dps), float(result.get("sim_time", 0.0)),
		"profile_id=%s live_reached_level=%d scenario_baseline_reached_level=%d live_total_dps=%d scenario_baseline_total_dps=%d live_ability_dps=%d scenario_baseline_ability_dps=%d level_delta=%d total_dps_ratio=%.3f ability_dps_ratio=%.3f status=%s" % [
			profile_id, live_level, scenario_level, int(live_total_dps), int(scenario_total_dps),
			int(live_ability_dps), int(scenario_ability_dps), level_delta, total_dps_ratio, ability_dps_ratio, status,
		]
	)


func _scenario_purchased_abilities_note(result: Dictionary) -> String:
	var purchased: Dictionary = result.get("purchased_abilities", {})
	var parts: PackedStringArray = PackedStringArray()
	for ability_id in _AC.ABILITY_IDS:
		var aid: String = str(ability_id)
		if bool(purchased.get(aid, false)):
			parts.append(aid)
	return "none" if parts.is_empty() else "|".join(parts)


func _scenario_focus_metrics_note(result: Dictionary) -> String:
	var total_dps: float = float(result.get("total_dps", 0.0))
	return "reached_level=%d wall_level=%d sim_time=%.0f first_prestige_reward=%d manual_dps_share=%.1f partner_dps_share=%.1f ability_dps_share=%.1f strongest_partner_index=%d strongest_partner_dps_share=%.1f highest_owned_partner_index=%d total_partner_purchases=%d" % [
		int(result.get("reached_level", 0)),
		int(result.get("wall_level", -1)),
		float(result.get("sim_time", 0.0)),
		int(result.get("first_prestige_reward", 0)),
		_scenario_share(float(result.get("manual_dps", 0.0)), total_dps),
		_scenario_share(float(result.get("partner_dps", 0.0)), total_dps),
		_scenario_share(float(result.get("ability_dps", 0.0)), total_dps),
		int(result.get("strongest_partner_index", -1)),
		float(result.get("strongest_partner_dps_share", 0.0)),
		int(result.get("highest_owned_partner_index", -1)),
		int(result.get("total_partner_purchases", 0)),
	]


func _append_scenario_runaway_warning_if_needed(result: Dictionary, baseline_active_wall_level: int) -> void:
	if baseline_active_wall_level != 50:
		return
	if str(result.get("profile_id", "")) != "active_6cps":
		return
	if int(result.get("reached_level", 0)) < 100:
		return
	var scenario_id: String = str(result.get("scenario_id", ""))
	var msg: String = "Scenario %s active_6cps reaches level %d while baseline walls at 50." % [
		scenario_id, int(result.get("reached_level", 0)),
	]
	_warn(msg)
	_csv_append(
		"scenario_runaway_warning", int(result.get("reached_level", 0)),
		0, 0, 0, int(result.get("click_damage", 0)), int(result.get("total_dps", 0.0)), float(result.get("sim_time", 0.0)),
		"scenario_id=%s profile_id=active_6cps baseline_wall_level=%d reached_level=%d sim_time=%.0f stopped_reason=%s total_dps=%d warning=%s" % [
			scenario_id, baseline_active_wall_level, int(result.get("reached_level", 0)),
			float(result.get("sim_time", 0.0)), str(result.get("stopped_reason", "")), int(result.get("total_dps", 0.0)), msg,
		]
	)


func _append_scenario_post_prestige_summary_if_needed(scenario: Dictionary, profile: Dictionary, result: Dictionary) -> void:
	if str(profile.get("id", "")) != "active_6cps":
		return
	if int(result.get("first_prestige_reward", 0)) <= 0:
		return
	if int(result.get("wall_level", -1)) <= 0:
		return
	var reward: int = int(result.get("first_prestige_reward", 0))
	var talent_index: int = 0
	var talent_name: String = _PRC.get_talent_name(talent_index)
	var second_run: Dictionary = _run_progression_profile(profile, scenario, false, {
		"prestige_points_available": reward,
		"prestige_points_total_earned": reward,
		"total_prestiges": 1,
		"buy_prestige_talent_index": talent_index,
	})
	_csv_append(
		"scenario_post_prestige_summary", int(second_run.get("reached_level", 0)),
		0, 0, 0, int(second_run.get("click_damage", 0)), int(second_run.get("total_dps", 0.0)), float(second_run.get("sim_time", 0.0)),
		"scenario_id=%s profile_id=active_6cps first_run_level=%d first_run_wall=%d first_prestige_reward=%d bought_talent_index=%d bought_talent_name=%s second_reached_level=%d second_wall_level=%d second_stopped_reason=%s second_total_dps=%d second_ability_dps=%d second_current_ability_dps=%d second_cumulative_ability_damage=%d second_used_abilities=%s second_currently_active_abilities=%s" % [
			str(scenario.get("id", "")), int(result.get("reached_level", 0)), int(result.get("wall_level", -1)),
			reward, talent_index, talent_name, int(second_run.get("reached_level", 0)), int(second_run.get("wall_level", -1)),
			str(second_run.get("stopped_reason", "")), int(second_run.get("total_dps", 0.0)), int(second_run.get("ability_dps", 0.0)),
			int(second_run.get("current_ability_dps", 0.0)), int(second_run.get("cumulative_ability_damage", 0)),
			str(second_run.get("used_abilities", "none")), str(second_run.get("currently_active_abilities", "none")),
		]
	)


func _add_scenario_warnings(result: Dictionary) -> void:
	var scenario_id: String = str(result.get("scenario_id", ""))
	var profile_id: String = str(result.get("profile_id", ""))
	var reached_level: int = int(result.get("reached_level", 0))
	var wall_level: int = int(result.get("wall_level", -1))
	var level_50_time: float = float(result.get("level_50_time", -1.0))
	var total_dps: float = float(result.get("total_dps", 0.0))
	var partner_share: float = _scenario_share(float(result.get("partner_dps", 0.0)), total_dps)
	if profile_id == "active_6cps":
		if wall_level > 0 and wall_level < 50:
			_warn("Scenario %s active_6cps: boss wall before level 50 (level %d)." % [scenario_id, wall_level])
		if level_50_time >= 0.0 and level_50_time < 180.0:
			_warn("Scenario %s active_6cps: reaches level 50 in under 3 minutes (%.0fs)." % [scenario_id, level_50_time])
		if level_50_time < 0.0 or level_50_time > 1200.0:
			_warn("Scenario %s active_6cps: reaches level 50 in over 20 minutes or not at all." % scenario_id)
		if reached_level > 30 and partner_share < 20.0:
			_warn("Scenario %s active_6cps: partner DPS share below 20%% after level 30 (%.1f%%)." % [scenario_id, partner_share])
		if reached_level < 30 and partner_share > 80.0:
			_warn("Scenario %s active_6cps: partner DPS share above 80%% before level 30 (%.1f%%)." % [scenario_id, partner_share])
		if wall_level <= 0 and reached_level >= SIM_MAX_LEVEL:
			_warn("Scenario %s active_6cps: no boss wall within scenario simulation range." % scenario_id)
		if reached_level >= 50 and partner_share < 25.0:
			_warn("Scenario %s active_6cps: reaches level 50 but partner DPS share is below 25%% (%.1f%%)." % [scenario_id, partner_share])
		if reached_level >= 50 and float(result.get("strongest_partner_dps_share", 0.0)) < 15.0:
			_warn("Scenario %s active_6cps: reaches level 50 but strongest partner contributes below 15%% of partner DPS (%.1f%%)." % [scenario_id, float(result.get("strongest_partner_dps_share", 0.0))])
		if reached_level >= 50 and int(result.get("highest_owned_partner_index", -1)) <= 1:
			_warn("Scenario %s active_6cps: reaches level 50 while only partners 1-2 are relevant." % scenario_id)
		if scenario_id == "partner_curve_power_idle" and reached_level >= 150 and level_50_time >= 0.0 and level_50_time < 120.0:
			_warn("Scenario partner_curve_power_idle active_6cps: reaches level 150 with level 50 in under 2 minutes; likely too fast.")
	if profile_id == "idle_0cps" and reached_level < 10:
		_warn("Scenario %s idle_0cps: cannot reach level 10." % scenario_id)
	if profile_id == "idle_0cps" and scenario_id.begins_with("partner_curve_") and reached_level < 10:
		_warn("Partner-focused scenario %s idle_0cps still cannot reach level 10." % scenario_id)
	if float(result.get("first_prestige_time", -1.0)) < 0.0 or float(result.get("first_prestige_time", -1.0)) > 7200.0:
		_warn("Scenario %s %s: first prestige is not reached by 2 hours." % [scenario_id, profile_id])


func _scenario_time_note(seconds: float) -> String:
	return "%.0f" % seconds if seconds >= 0.0 else "not_reached"


func _scenario_share(part: float, total: float) -> float:
	return part / total * 100.0 if total > 0.0 else 0.0


func _scf(scenario: Dictionary, key: String, fallback: float = 1.0) -> float:
	return float(scenario.get(key, fallback))


func _sim_format_counts(counts: Dictionary) -> String:
	if counts.is_empty():
		return "none"
	var parts: PackedStringArray = PackedStringArray()
	for key in counts.keys():
		parts.append("%s:%d" % [str(key), int(counts[key])])
	return "|".join(parts)


func _building_name(idx: int) -> String:
	if idx >= 0 and idx < _SC.BUILDING_NAMES.size():
		return str(_SC.BUILDING_NAMES[idx])
	return "Building %d" % (idx + 1)


func _section_warnings() -> void:
	_header("SECTION 7 — Warnings Summary  (%d total)" % _warnings.size())
	if _warnings.is_empty():
		_ln("  No warnings generated.")
	else:
		for i: int in range(_warnings.size()):
			_ln("  [W%02d]  %s" % [i + 1, _warnings[i]])


# ==========================================================================
#  CSV Output
# ==========================================================================

func _write_csv() -> void:
	_header("CSV Output")
	var path: String = "res://balance_audit_report.csv"
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		path = "user://balance_audit_report.csv"
		file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_ln("  WARNING: Could not open CSV for writing (tried res:// and user://).")
		return

	var cols: PackedStringArray = PackedStringArray([
		"category", "level", "hp", "reward", "cost", "damage", "dps", "ttd_seconds", "notes",
	])
	file.store_line(",".join(cols))
	for row: Dictionary in _csv_rows:
		var parts: PackedStringArray = PackedStringArray()
		for col: String in cols:
			var v: String = str(row.get(col, ""))
			if "," in v or "\"" in v:
				v = "\"" + v.replace("\"", "\"\"") + "\""
			parts.append(v)
		file.store_line(",".join(parts))
	file.close()
	_ln("  Written: %s  (%d rows)" % [path, _csv_rows.size()])


# ==========================================================================
#  Sample level lists
# ==========================================================================

func _enemy_sample_levels() -> Array[int]:
	var out: Array[int] = []
	for i: int in range(1, 21):
		out.append(i)
	for v: int in ([25, 30, 35, 40, 45, 50] as Array[int]):
		out.append(v)
	var l: int = 60
	while l <= 150:
		out.append(l)
		l += 10
	return out


func _hero_sample_levels() -> Array[int]:
	var out: Array[int] = []
	for i: int in range(1, 21):
		out.append(i)
	for v: int in ([25, 50, 75, 100] as Array[int]):
		out.append(v)
	var l: int = 150
	while l <= 500:
		out.append(l)
		l += 50
	return out


func _combat_sample_levels() -> Array[int]:
	var out: Array[int] = []
	for v: int in [1, 5, 10, 15, 20, 25, 30, 40, 50, 75, 100, 150]:
		out.append(v)
	return out


# ==========================================================================
#  Helper: partner name — avoids Object.get_name() collision
# ==========================================================================

func _partner_name(idx: int) -> String:
	if idx >= 0 and idx < PartnerConfig.PARTNER_NAMES.size():
		return PartnerConfig.PARTNER_NAMES[idx]
	return "Partner %d" % (idx + 1)


# ==========================================================================
#  Helper: partner cost via CostCalculator
# ==========================================================================

func _partner_cost(idx: int, owned_before: int) -> int:
	return _CC.get_partner_cost(
		idx, owned_before, _BC.PARTNER_BASE_COSTS,
		_BC.PARTNER_COST_GROWTH_EARLY, _BC.PARTNER_COST_GROWTH_MID, _BC.PARTNER_COST_GROWTH_LATE,
		_BC.PARTNER_COST_MID_START_COUNT, _BC.PARTNER_COST_LATE_START_COUNT,
		_BC.MILESTONE_LEVELS, _BC.MILESTONE_COST_MULTIPLIER)


# ==========================================================================
#  Formatting helpers
# ==========================================================================

func _fn(n: int) -> String:
	if n < 0:
		return str(n)
	if n < 1000:
		return str(n)
	if n < 1_000_000:
		return "%.1fK" % (float(n) / 1_000.0)
	if n < 1_000_000_000:
		return "%.2fM" % (float(n) / 1_000_000.0)
	return "%.2fB" % (float(n) / 1_000_000_000.0)


func _fmt_time(seconds: float) -> String:
	var s: int = int(seconds)
	var m: int = s / 60
	s = s % 60
	if m >= 60:
		var h: int = m / 60
		m = m % 60
		return "%dh%02dm" % [h, m]
	return "%dm%02ds" % [m, s]


func _lj(s: String, w: int) -> String:
	if s.length() >= w:
		return s.left(w)
	return s + " ".repeat(w - s.length())


func _rj(s: String, w: int) -> String:
	if s.length() >= w:
		return s.left(w)
	return " ".repeat(w - s.length()) + s


func _row(parts: Array) -> String:
	var out: String = ""
	for p: Variant in parts:
		out += str(p) + " "
	return out


func _ln(s: String) -> void:
	print(s)


func _div(ch: String, n: int) -> void:
	print(ch.repeat(n))


func _header(title: String) -> void:
	print("")
	_div("-", 74)
	print("  " + title)
	_div("-", 74)


func _warn(msg: String) -> void:
	_warnings.append(msg)


func _csv_append(
		category: String, level: int,
		hp: int, reward: int, cost: int, damage: int, dps: int,
		ttd: float, notes: String) -> void:
	_csv_rows.append({
		"category": category, "level": level,
		"hp": hp, "reward": reward, "cost": cost,
		"damage": damage, "dps": dps,
		"ttd_seconds": "%.2f" % ttd,
		"notes": notes,
	})
