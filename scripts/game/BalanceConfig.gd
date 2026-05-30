class_name BalanceConfig
extends RefCounted

# Central source for economy coefficients and formulas.
# All values match ClickerState defaults. Tune here, not in ClickerState.
# ClickerState reads scalars directly; arrays are documented here for the simulator.

# --- Hero ---
const HERO_COST_BASE: int = 5
const HERO_COST_LINEAR: float = 2.2
const HERO_COST_CURVE: float = 0.18
const HERO_COST_POWER: float = 2.35
# formula: base + linear*progress + curve*progress^power  (progress = level-1)
# milestone_cost_multiplier applied at milestone target levels

const MILESTONE_LEVELS: Array = [10, 25, 50, 100, 250, 500]
const MILESTONE_MULTIPLIER_PER_REACHED: int = 2   # DPS multiplier each milestone grants
const MILESTONE_COST_MULTIPLIER: int = 3           # cost spike at milestone purchase steps

const HERO_SKILL_COST_MULTIPLIERS: Array = [5, 8, 12, 18, 30]  # per skill_level index

# --- Partners ---
const PARTNER_DPS_VALUES: Array = [10, 20, 35, 65, 120, 220, 410, 750, 1400, 2600, 4800, 9000, 16500]
const PARTNER_BASE_COSTS: Array = [10, 50, 150, 400, 900, 1800, 3500, 7000, 14000, 28000, 56000, 110000, 220000]
const PARTNER_COST_STEPS: Array = [10, 30, 50, 100, 180, 300, 500, 900, 1600, 2800, 5000, 9000, 16000]
const PARTNER_COST_CURVE_MULT: float = 0.015
const PARTNER_COST_POWER: float = 2.15
# formula: base + step*count + base*curve*count^power
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
# Rank effect: base_multiplier 2.0 + 0.25*rank (applies to focus_burst, rally, gold_bonus)
# Autoclick rate: 1.0 + 0.15*rank

# --- Settlement ---
const BUILDING_BASE_COSTS: Array = [25, 75, 150, 500, 1200, 3000]
const BUILDING_COST_STEPS: Array = [25, 50, 100, 250, 600, 1500]
const BUILDING_BONUS_PERCENT_PER_LEVEL: int = 1
# Positive effects (partner DPS, gold, click damage, boss gold): additive percent
# Cooldown reduction uses diminishing returns: 100/(100+raw_percent)

# --- Enemies ---
const ENEMY_HP_BASE: int = 10
const ENEMY_HP_LINEAR: float = 8.0
const ENEMY_HP_CURVE: float = 1.15
const ENEMY_HP_POWER: float = 2.10
# formula: hp_base + linear*stage + curve*stage^power  (stage = level-1)

const ENEMY_REWARD_BASE: int = 5
const ENEMY_REWARD_LINEAR: float = 3.0
const ENEMY_REWARD_CURVE: float = 0.22
const ENEMY_REWARD_POWER: float = 1.80
# formula: reward_base + linear*stage + curve*stage^power

const ELITE_SPAWN_CHANCE: float = 0.07
const ELITE_HP_MULTIPLIER: int = 3
const ELITE_REWARD_MULTIPLIER: int = 5

const BOSS_HP_MULTIPLIER: int = 5
const BOSS_REWARD_MULTIPLIER: int = 5
const BOSS_TIME_LIMIT: float = 30.0

# --- Tasks ---
# reward = current_task_reward_unit * reward_scale * task_boost_multiplier
# reward_scale values per task: 20, 30, 60, 100, 50, 70, 80, 40, 90, 120

# --- Shop ---
const SHOP_GOLD_SMALL_SCALE: int = 120    # seconds of current reward income
const SHOP_GOLD_LARGE_SCALE: int = 350
const SHOP_COMBO_FILL_GEMS: int = 15
const SHOP_BOSS_RETRY_GEMS: int = 20
const SHOP_TASK_BOOST_GEMS: int = 30
const SHOP_TASK_BOOST_MULTIPLIER: float = 2.0

# --- Prestige ---
const PRESTIGE_REQUIRED_LEVEL: int = 50      # stage points: floor(level / this)
const PRESTIGE_CHARACTER_INTERVAL: float = 100.0  # char points: floor(hero_level / this)
const PRESTIGE_TALENT_BONUS_PERCENT_PER_LEVEL: int = 5
