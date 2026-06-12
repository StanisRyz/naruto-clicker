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
const _CS = preload("res://scripts/game/ClickerState.gd")

const CLICKS_PER_SEC: float = 4.0
# Partners 14–28 (index 13+) are marked placeholder in BalanceConfig.
const PLACEHOLDER_PARTNER_START_IDX: int = 13

# --- Simulation constants ---
const SIM_MAX_SECONDS: float = 7200.0
const SIM_MAX_LEVEL: int = 150
const SIM_CLICKS_PER_SEC: float = 4.0
const SIM_PURCHASE_INTERVAL_SEC: float = 1.0
const SIM_REPORT_LEVELS: Array = [1, 5, 10, 15, 20, 25, 30, 40, 50, 75, 100, 150]

var _warnings: Array[String] = []
var _csv_rows: Array[Dictionary] = []


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
		var pname:    String = _PC.get_name(i) if i < _PC.get_partner_count() else ("Partner %d" % (i + 1))
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

		_csv_append("partner", i + 1, 0, 0, costs[0], 0, base_dps, 0.0,
			("placeholder" if is_ph else "final"))

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
		var pname:    String = _PC.get_name(i) if i < _PC.get_partner_count() else ("Partner %d" % (i + 1))
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
	_ln("BossResult shows estimated seconds to kill boss at 4 clicks/sec.")
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
	_ln("  TALENT_BONUS_PERCENT        = %d%% per talent level" % _BC.PRESTIGE_TALENT_BONUS_PERCENT_PER_LEVEL)
	_ln("")
	_ln("  Stage pts   = int(game_level  / PRESTIGE_REQUIRED_LEVEL)")
	_ln("  Char pts    = int(hero_level  / 100)")
	_ln("  Total reward = stage_pts + char_pts  (must be > 0 to unlock prestige button)")
	_ln("")

	_ln("  Stage points by game level:")
	_ln(_row([_rj("GameLevel", 12), _rj("StagePts", 12), _lj("CanPrestige", 14)]))
	_div("-", 38)
	for lvl: int in ([50, 75, 100, 150, 200] as Array[int]):
		var pts: int = int(lvl / float(_BC.PRESTIGE_REQUIRED_LEVEL))
		_ln(_row([_rj(str(lvl), 12), _rj(str(pts), 12), _lj(("YES" if pts > 0 else "NO"), 14)]))
		_csv_append("prestige_stage", lvl, 0, pts, 0, 0, 0, 0.0, "stage_pts=%d" % pts)

	_ln("")
	_ln("  Character points by hero level:")
	_ln(_row([_rj("HeroLevel", 12), _rj("CharPts", 12)]))
	_div("-", 24)
	for clvl: int in ([50, 100, 200, 500] as Array[int]):
		var pts: int = int(clvl / 100.0)
		_ln(_row([_rj(str(clvl), 12), _rj(str(pts), 12)]))
		_csv_append("prestige_char", clvl, 0, pts, 0, 0, 0, 0.0, "char_pts=%d" % pts)

	_ln("")
	_ln("  First prestige at level %d (1 stage point).  Second at %d (2 pts)." % [
		_BC.PRESTIGE_REQUIRED_LEVEL, _BC.PRESTIGE_REQUIRED_LEVEL * 2])

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
#    - Manual clicking at SIM_CLICKS_PER_SEC (4) clicks/sec, continuous.
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
	_header("SECTION 6 — Progression Simulation  (balanced greedy, no elites/abilities)")
	_ln("  Assumptions: 4 clicks/sec, partner DPS continuous, no elites, no abilities,")
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

	# --- Tracking variables ---
	var sim_time: float = 0.0
	var last_purchase_time: float = -SIM_PURCHASE_INTERVAL_SEC
	var total_hero_buys: int = 0
	var total_partner_buys: int = 0
	var total_building_buys: int = 0
	var last_purchase_cost: int = 0

	var level_times: Dictionary = {}
	var reported_set: Dictionary = {}

	var boss_wall_level: int = -1
	var boss_wall_dps_needed: float = 0.0
	var boss_wall_dps_actual: float = 0.0

	var first_prestige_time: float = -1.0
	var first_prestige_reward: int = 0
	var hero_level_at_prestige: int = 0
	var partner_dps_at_prestige: int = 0

	var reached_level: int = 1

	# One-shot warning flags
	var warned_ttk_early: bool = false
	var warned_ttk_mid: bool = false
	var warned_ttk_late: bool = false
	var warned_no_partner: bool = false
	var warned_hero_dom: bool = false
	var warned_partner_early: bool = false

	# --- Main simulation loop ---
	while sim_time < SIM_MAX_SECONDS and state.current_level <= SIM_MAX_LEVEL:
		var lv: int = state.current_level
		reached_level = lv

		if not level_times.has(lv):
			level_times[lv] = sim_time

		# Purchase tick
		if sim_time - last_purchase_time >= SIM_PURCHASE_INTERVAL_SEC:
			last_purchase_time = sim_time
			var pr: Dictionary = _sim_do_purchases(state)
			total_hero_buys    += int(pr.hero_buys)
			total_partner_buys += int(pr.partner_buys)
			total_building_buys += int(pr.building_buys)
			if int(pr.last_cost) > 0:
				last_purchase_cost = int(pr.last_cost)

		# Prestige check (first occurrence only)
		if first_prestige_time < 0.0 and state.can_prestige():
			first_prestige_time   = sim_time
			first_prestige_reward = state.get_prestige_reward()
			hero_level_at_prestige  = state.character_level
			partner_dps_at_prestige = state.get_final_partner_dps(false)

		# Compute combat stats for this enemy
		var manual_dps:  float = float(state.get_current_click_damage()) * SIM_CLICKS_PER_SEC
		var partner_dps: float = float(state.get_final_partner_dps(true))
		var total_dps:   float = manual_dps + partner_dps
		var enemy_hp:    int   = state.target_max_hp

		if total_dps <= 0.0:
			_warn("Simulation: total DPS is 0 at level %d — infinite loop guard triggered" % lv)
			break

		var kill_time: float = float(enemy_hp) / total_dps

		# Boss wall check
		if state.is_boss_level and kill_time > state.boss_time_limit:
			boss_wall_level    = lv
			boss_wall_dps_needed = float(enemy_hp) / state.boss_time_limit
			boss_wall_dps_actual = total_dps
			_ln("")
			_ln("  *** BOSS WALL at level %d ***" % lv)
			_ln("    Required DPS  : %s  (%.0fs limit)" % [_fn(int(boss_wall_dps_needed)), state.boss_time_limit])
			_ln("    Actual DPS    : %s  (click %s + partner %s)" % [
				_fn(int(total_dps)), _fn(int(manual_dps)), _fn(int(partner_dps))])
			_ln("    Hero level    : %d" % state.character_level)
			_ln("    Gold held     : %s" % _fn(state.gold))
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
				"sim_time=%.0f hero=%d gold=%d pdps=%d boss_wall=%s prestige_rwd=%d" % [
					sim_time, state.character_level, state.gold, int(partner_dps),
					("true" if boss_wall_level > 0 else "false"),
					first_prestige_reward,
				]
			)

		# Advance sim time, kill enemy, let state handle gold + level advancement
		sim_time += kill_time
		state.attack_with_damage(state.target_hp)
		state.resolve_defeated_target()

	# --- Simulation summary ---
	_ln("")
	_ln("  === SIMULATION SUMMARY ===")
	_ln("  Strategy           : balanced greedy (best DPS/gold between hero & partners)")
	_ln("  Reached level      : %d" % reached_level)
	_ln("  Total sim time     : %s (%.0f s)" % [_fmt_time(sim_time), sim_time])

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

	# Simulation-derived warnings
	if boss_wall_level > 0 and boss_wall_level < 20:
		_warn("Simulation: boss wall at level %d (before level 20) — DPS ramp-up is too slow in early game" % boss_wall_level)

	if level_times.has(50) and float(level_times[50]) > 7200.0:
		_warn("Simulation: level 50 takes %.0f min (> 2 hours) — early-game progression too slow" % (float(level_times[50]) / 60.0))

	if first_prestige_time < 0.0:
		_warn("Simulation: first prestige not reached within %.0f min — check PRESTIGE_REQUIRED_LEVEL or DPS scaling" % (SIM_MAX_SECONDS / 60.0))


# --- Greedy purchase helper ---
# Returns counts of each purchase type and the last unit cost paid.
# Balanced: evaluates hero and each visible partner by DPS-per-gold;
# buildings are bought opportunistically when cheap (< 15% of gold held).

func _sim_do_purchases(state: _CS) -> Dictionary:
	var hero_buys:     int = 0
	var partner_buys:  int = 0
	var building_buys: int = 0
	var last_cost:     int = 0

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
		# (opportunistic — only when DPS buys are too expensive)
		if state.gold > 0:
			var cur_tdps: float = float(state.get_current_click_damage()) * SIM_CLICKS_PER_SEC + float(state.get_final_partner_dps(false))
			for b: int in range(state.building_counts.size()):
				if state.can_afford_building_bulk(b, "x1"):
					var cost: int = state.get_building_bulk_display_cost(b, "x1")
					if cost > 0 and float(cost) <= float(state.gold) * 0.15:
						# Estimated DPS-equivalent: 1% of total DPS per building
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
				state.buy_character_level_upgrades("x1")
				hero_buys += 1
				last_cost = best_cost
			"partner":
				state.buy_partners(best_idx, "x1")
				partner_buys += 1
				last_cost = best_cost
			"building":
				state.buy_buildings(best_idx, "x1")
				building_buys += 1
				last_cost = best_cost

	return {
		"hero_buys":     hero_buys,
		"partner_buys":  partner_buys,
		"building_buys": building_buys,
		"last_cost":     last_cost,
	}


# ==========================================================================
#  SECTION 7 — Warnings Summary
# ==========================================================================

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
