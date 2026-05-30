class_name BalanceConfig
extends RefCounted

# Central source for economy coefficients and formulas.
# Tune values here; ClickerState and calculators pick them up automatically.
#
# Core Economy Model C v1 (2026-05-30):
#   - Explosive early game (fast first ~10 levels)
#   - Smoother mid-game slowdown
#   - Harder late-game friction
#   Costs: segmented adaptive exponential (hero, partners)
#   Enemies: exponential HP / reward curves
#   Buildings: exponential cost growth
#   Boss/elite multipliers adjusted upward from prototype values


# --- Milestones ---
const MILESTONE_LEVELS: Array = [10, 25, 50, 100, 250, 500]
const MILESTONE_MULTIPLIER_PER_REACHED: int = 2   # DPS ×2 per reached milestone
const MILESTONE_COST_MULTIPLIER: int = 3           # purchase cost ×3 at milestone target


# --- Hero cost — segmented adaptive exponential ---
# cost(L→L+1) = HERO_BASE_COST * growth^(L-1), segment boundary applied continuously
const HERO_BASE_COST: float = 5.0
const HERO_COST_GROWTH_EARLY: float = 1.05   # levels 1–100
const HERO_COST_GROWTH_MID: float = 1.10     # levels 101–500
const HERO_COST_GROWTH_LATE: float = 1.15    # levels 501+
const HERO_COST_MID_START_LEVEL: int = 101
const HERO_COST_LATE_START_LEVEL: int = 501

const HERO_SKILL_COST_MULTIPLIERS: Array = [5, 8, 12, 18, 30]  # per skill_level index


# --- Partners ---
const PARTNER_DPS_VALUES: Array = [10, 20, 35, 65, 120, 220, 410, 750, 1400, 2600, 4800, 9000, 16500]
const PARTNER_BASE_COSTS: Array = [10, 50, 150, 400, 900, 1800, 3500, 7000, 14000, 28000, 56000, 110000, 220000]

# Segmented adaptive exponential cost by owned count:
# cost(count) = base_cost * growth^count, boundary applied continuously
const PARTNER_COST_GROWTH_EARLY: float = 1.07   # counts 0–99
const PARTNER_COST_GROWTH_MID: float = 1.10     # counts 100–249
const PARTNER_COST_GROWTH_LATE: float = 1.13    # counts 250+
const PARTNER_COST_MID_START_COUNT: int = 100
const PARTNER_COST_LATE_START_COUNT: int = 250

const PARTNER_SKILL_UNLOCK_COUNTS: Array = [10, 25, 50, 100, 250]
const PARTNER_SKILL_COST_MULTIPLIERS: Array = [3, 5, 8, 12, 20]


# --- Abilities ---
const AUTOCLICK_UNLOCK_LEVEL: int = 15
const GOLD_BONUS_UNLOCK_LEVEL: int = 30
const FOCUS_BURST_UNLOCK_LEVEL: int = 60
const RALLY_UNLOCK_LEVEL: int = 80

const AUTOCLICK_PURCHASE_COST: int = 50
const GOLD_BONUS_PURCHASE_COST: int = 150
const FOCUS_BURST_PURCHASE_COST: int = 500
const RALLY_PURCHASE_COST: int = 1000

const ABILITY_MAX_RANK: int = 5
const ABILITY_SKILL_COST_MULTIPLIERS: Array = [1, 4, 9, 16, 25]


# --- Settlement — exponential building cost growth ---
# cost(count) = base_cost * BUILDING_COST_GROWTH^count
const BUILDING_BASE_COSTS: Array = [25, 75, 150, 500, 1200, 3000]
const BUILDING_COST_GROWTH: float = 1.18
const BUILDING_BONUS_PERCENT_PER_LEVEL: int = 1
# Positive effects (partner DPS, gold, click damage, boss gold): additive percent
# Cooldown reduction uses diminishing returns: 100/(100+raw_percent)


# --- Enemies — exponential HP and reward curves ---
# hp(level)     = ENEMY_HP_BASE     * ENEMY_HP_GROWTH^(level-1)
# reward(level) = ENEMY_REWARD_BASE * ENEMY_REWARD_GROWTH^(level-1)
# HP grows faster than rewards to create increasing friction over time.
const ENEMY_HP_BASE: float = 10.0
const ENEMY_HP_GROWTH: float = 1.14

const ENEMY_REWARD_BASE: float = 5.0
const ENEMY_REWARD_GROWTH: float = 1.11

const ELITE_SPAWN_CHANCE: float = 0.07
const ELITE_HP_MULTIPLIER: int = 3
const ELITE_REWARD_MULTIPLIER: int = 5

# Softened from research (×10/×15) for first in-game pass; raise after manual testing.
const BOSS_HP_MULTIPLIER: int = 8
const BOSS_REWARD_MULTIPLIER: int = 10
const BOSS_TIME_LIMIT: float = 30.0


# --- Tasks — ETV baseline (for documentation; formula uses unit * reward_scale) ---
# ETV = expected time value. TTK = time-to-kill (seconds per enemy).
const TASK_BASELINE_TTK_SECONDS: float = 2.0
const TASK_REWARD_SECONDS_BASE: float = 60.0
# task_reward ≈ (enemy_reward / TTK) * REWARD_SECONDS * reward_scale_normalized
# Current implementation: task_reward = current_task_reward_unit * reward_scale
# Both forms are equivalent when reward_scale_normalized = reward_scale / REWARD_SECONDS.


# --- Shop gold packs — ETV seconds ---
# shop_gold = (enemy_reward / TASK_BASELINE_TTK_SECONDS) * etv_seconds
# First-pass values; raise after testing.
const SHOP_SMALL_GOLD_ETV_SECONDS: float = 300.0    # 5 minutes ETV
const SHOP_LARGE_GOLD_ETV_SECONDS: float = 1200.0   # 20 minutes ETV

const SHOP_COMBO_FILL_GEMS: int = 15
const SHOP_BOSS_RETRY_GEMS: int = 20
const SHOP_TASK_BOOST_GEMS: int = 30
const SHOP_TASK_BOOST_MULTIPLIER: float = 2.0


# --- Prestige ---
const PRESTIGE_REQUIRED_LEVEL: int = 50
const PRESTIGE_CHARACTER_INTERVAL: float = 100.0
const PRESTIGE_TALENT_BONUS_PERCENT_PER_LEVEL: int = 5
