class_name BalanceConfig
extends RefCounted

# Central source for economy coefficients and formulas.
# Tune values here; ClickerState, calculators, and presentation pick them up automatically.
#
# Core Economy Model C v1 (2026-05-30):
#   Explosive early game, smoother mid-game, harder late-game friction.
#   Exponential cost and enemy curves replace old polynomial prototype values.
#
# Power Progression Model C v1 (2026-05-30):
#   Hero damage formula centralised.
#   Ability costs and skill cost multipliers tuned to new economy.
#   Ability multiplier constants extracted from magic numbers.


# --- Milestones ---
# Apply to both hero damage and partner DPS: each reached milestone ×MULTIPLIER_PER_REACHED.
# Milestone purchase cost spike: ×COST_MULTIPLIER at the milestone target level/count.
const MILESTONE_LEVELS: Array = [10, 25, 50, 100, 250, 500]
const MILESTONE_MULTIPLIER_PER_REACHED: int = 2   # hero and partner milestone DPS/damage ×2
const MILESTONE_COST_MULTIPLIER: int = 3           # purchase cost ×3 at milestone target

# Alias constants for clarity (same value as MILESTONE_MULTIPLIER_PER_REACHED):
const HERO_MILESTONE_DAMAGE_MULTIPLIER: int = 2
const PARTNER_MILESTONE_DPS_MULTIPLIER: int = 2


# --- Hero damage formula ---
# base_click_damage = HERO_BASE_DAMAGE + character_level * HERO_DAMAGE_PER_LEVEL
# then × milestone multiplier × all passive multipliers
const HERO_BASE_DAMAGE: float = 1.0
const HERO_DAMAGE_PER_LEVEL: float = 1.0


# --- Hero cost — segmented adaptive exponential ---
# cost(L→L+1) = HERO_BASE_COST * growth^(L-1), segment boundary applied continuously
const HERO_BASE_COST: float = 5.0
const HERO_COST_GROWTH_EARLY: float = 1.08   # levels 1–100
const HERO_COST_GROWTH_MID: float = 1.13     # levels 101–500
const HERO_COST_GROWTH_LATE: float = 1.18    # levels 501+
const HERO_COST_MID_START_LEVEL: int = 101
const HERO_COST_LATE_START_LEVEL: int = 501

# Hero skill cost = hero_level_cost(unlock_level - 1) * multiplier_at_skill_index
const HERO_SKILL_COST_MULTIPLIERS: Array = [4, 7, 11, 17, 26]


# --- Partners ---
const PARTNER_DPS_VALUES: Array = [
	4, 12, 30, 70, 150, 320, 680, 1450, 3100, 6600, 14000, 30000, 64000,
	# Partners 14–28 use the accepted late_partner_curve_soft balance from BalanceAuditReport v14.
	# Generated from partner 13 with approximately:
	# DPS growth x2.15 and cost growth x2.10 between new partner tiers.
	137600, 295840, 636056, 1367520, 2940169, 6321363, 13590931, 29220501,
	62824076, 135071764, 290404294, 624369231, 1342393847, 2886146771, 6205215558,
]
# Partner 1 is a weak idle assistant; mid partners carry mid game; later partners are long-term goals.

const PARTNER_BASE_COSTS: Array = [
	35, 110, 300, 750, 1700, 3800, 8500, 19000, 43000, 96000, 215000, 480000, 1050000,
	# Partners 14–28 use the accepted late_partner_curve_soft balance from BalanceAuditReport v14.
	# Generated from partner 13 with approximately:
	# DPS growth x2.15 and cost growth x2.10 between new partner tiers.
	2205000, 4630500, 9724050, 20420505, 42883061, 90054427, 189114297, 397140023,
	833994049, 1751387503, 3677913756, 7723618887, 16219599663, 34061159291, 71528434512,
]

# Segmented adaptive exponential cost by owned count:
# cost(count) = base_cost * growth^count, boundary applied continuously
const PARTNER_COST_GROWTH_EARLY: float = 1.12   # counts 0–99
const PARTNER_COST_GROWTH_MID: float = 1.145    # counts 100–249
const PARTNER_COST_GROWTH_LATE: float = 1.17    # counts 250+
const PARTNER_COST_MID_START_COUNT: int = 100
const PARTNER_COST_LATE_START_COUNT: int = 250

const PARTNER_SKILL_UNLOCK_COUNTS: Array = [10, 25, 50, 100, 250]
# Partner skill cost = partner_cost_at_unlock_count * multiplier_at_skill_index
const PARTNER_SKILL_COST_MULTIPLIERS: Array = [4, 6, 9, 14, 22]


# --- Abilities ---
const AUTOCLICK_UNLOCK_LEVEL: int = 15
const GOLD_BONUS_UNLOCK_LEVEL: int = 30
const FOCUS_BURST_UNLOCK_LEVEL: int = 60
const RALLY_UNLOCK_LEVEL: int = 80

# Tuned to new exponential economy (Power Progression Model C v1):
const AUTOCLICK_PURCHASE_COST: int = 300
const GOLD_BONUS_PURCHASE_COST: int = 1200
const FOCUS_BURST_PURCHASE_COST: int = 5000
const RALLY_PURCHASE_COST: int = 15000

const ABILITY_MAX_RANK: int = 5

# focus_burst / rally / gold_bonus: multiplier = BASE + STEP * rank
# rank 0 = ×2.0, rank 5 = ×3.25
const ABILITY_BASE_MULTIPLIER: float = 2.0
const ABILITY_RANK_MULTIPLIER_STEP: float = 0.25

# Autoclick: rate multiplier = 1.0 + RATE_STEP * rank (base 15 hits/sec at rank 0)
const AUTOCLICK_BASE_HITS_PER_SEC: float = 15.0
const AUTOCLICK_BASE_DURATION_SEC: int = 15
const AUTOCLICK_RANK_DURATION_BONUS_SEC: int = 2
const AUTOCLICK_RANK_RATE_STEP: float = 0.15
const AUTOCLICK_COOLDOWN_SEC: float = 90.0

# Gold Bonus
const GOLD_BONUS_BASE_DURATION_SEC: float = 30.0
const GOLD_BONUS_COOLDOWN_SEC: float = 180.0

# Focus Burst
const FOCUS_BURST_BASE_DURATION_SEC: float = 12.0
const FOCUS_BURST_COOLDOWN_SEC: float = 120.0

# Rally
const RALLY_BASE_DURATION_SEC: float = 20.0
const RALLY_COOLDOWN_SEC: float = 150.0

# Ability skill cost = ability_purchase_cost * multiplier_at_skill_index
const ABILITY_SKILL_COST_MULTIPLIERS: Array = [1, 3, 7, 13, 22]


# --- Settlement — exponential building cost growth ---
# cost(count) = base_cost * BUILDING_COST_GROWTH^count
# All buildings share the same base cost and growth; only owned count differentiates price.
const BUILDING_BASE_COST: int = 500
const BUILDING_BASE_COSTS: Array = [
	BUILDING_BASE_COST,
	BUILDING_BASE_COST,
	BUILDING_BASE_COST,
	BUILDING_BASE_COST,
	BUILDING_BASE_COST,
	BUILDING_BASE_COST,
]
const BUILDING_COST_GROWTH: float = 1.22
const BUILDING_BONUS_PERCENT_PER_LEVEL: int = 1
# Positive effects (partner DPS, gold, click damage, boss gold): additive percent
# Cooldown reduction uses diminishing returns: 100/(100+raw_percent)


# --- Enemies — exponential HP and reward curves ---
# hp(level)     = ENEMY_HP_BASE     * ENEMY_HP_GROWTH^(level-1)
# reward(level) = ENEMY_REWARD_BASE * ENEMY_REWARD_GROWTH^(level-1)
# HP grows faster than rewards to create increasing friction over time.
const ENEMY_HP_BASE: float = 18.0
const ENEMY_HP_GROWTH: float = 1.165

const ENEMY_REWARD_BASE: float = 4.0
const ENEMY_REWARD_GROWTH: float = 1.115

const ELITE_SPAWN_CHANCE: float = 0.07
const ELITE_HP_MULTIPLIER: int = 3
const ELITE_REWARD_MULTIPLIER: int = 5

# Softened from research (×10/×15) for first in-game pass; raise after manual testing.
const BOSS_HP_MULTIPLIER: int = 20
const BOSS_REWARD_MULTIPLIER: int = 15
const BOSS_TIME_LIMIT: float = 30.0

# Zone cycle scaling — applied per full cycle of 105 levels.
# Intentionally larger than the final zone multipliers (hp=36.3, reward=25.7)
# so each new visual cycle starts slightly stronger than the end of the previous one.
const ZONE_CYCLE_HP_MULTIPLIER: float = 40.0
const ZONE_CYCLE_REWARD_MULTIPLIER: float = 28.0


# --- Tasks — ETV baseline (for documentation; formula uses unit * reward_scale) ---
const TASK_BASELINE_TTK_SECONDS: float = 2.0
const TASK_REWARD_SECONDS_BASE: float = 60.0


# --- Shop gold packs — ETV seconds ---
# shop_gold = (enemy_reward / TASK_BASELINE_TTK_SECONDS) * etv_seconds
const SHOP_SMALL_GOLD_ETV_SECONDS: float = 300.0    # 5 minutes ETV
const SHOP_LARGE_GOLD_ETV_SECONDS: float = 1200.0   # 20 minutes ETV

const SHOP_BOSS_RETRY_GEMS: int = 20
const SHOP_TASK_BOOST_GEMS: int = 30
const SHOP_TASK_BOOST_MULTIPLIER: float = 2.0


# --- Prestige ---
const PRESTIGE_REQUIRED_LEVEL: int = 100
const PRESTIGE_CHARACTER_INTERVAL: float = 200.0
const PRESTIGE_DAMAGE_TALENT_BONUS_PERCENT_PER_LEVEL: int = 50
const PRESTIGE_GOLD_TALENT_BONUS_PERCENT_PER_LEVEL: int = 100
const PRESTIGE_UTILITY_TALENT_BONUS_PERCENT_PER_LEVEL: int = 10
const PRESTIGE_TALENT_BASE_COST: int = 2
const PRESTIGE_TALENT_COST_GROWTH: float = 1.5
const PRESTIGE_BASE_REWARD_POINTS: int = 1
