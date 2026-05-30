class_name CostCalculator
extends RefCounted

const MilestoneCalc = preload("res://scripts/game/calculators/MilestoneCalculator.gd")

# Shared overflow guard: clamp floats before ceili() to stay within int64 range.
const _MAX_SAFE_COST: float = 9.0e18


# --- Hero level cost — segmented adaptive exponential ---
#
# cost(L→L+1) uses different per-level growth rates per segment:
#   L < mid_start             → base_cost * growth_early^(L-1)
#   mid_start <= L < late_start → continuous from mid_start-1, times growth_mid^offset
#   L >= late_start           → continuous from late_start-1, times growth_late^offset
#
# Continuity guaranteed: each segment starts exactly where the previous ended.
# Milestone target levels pay an additional ×milestone_cost_multiplier.

static func get_hero_level_cost(
	level: int,
	base_cost: float,
	growth_early: float,
	growth_mid: float,
	growth_late: float,
	mid_start: int,
	late_start: int,
	milestones: Array,
	milestone_cost_multiplier: int
) -> int:
	var current_level: int = maxi(1, level)
	var target_level: int = current_level + 1

	var cost: float
	if current_level < mid_start:
		cost = base_cost * pow(growth_early, float(current_level - 1))
	elif current_level < late_start:
		var cost_at_boundary: float = base_cost * pow(growth_early, float(mid_start - 2))
		cost = cost_at_boundary * pow(growth_mid, float(current_level - (mid_start - 1)))
	else:
		var cost_at_early: float = base_cost * pow(growth_early, float(mid_start - 2))
		var cost_at_mid: float = cost_at_early * pow(growth_mid, float(late_start - mid_start))
		cost = cost_at_mid * pow(growth_late, float(current_level - (late_start - 1)))

	var int_cost: int = maxi(1, ceili(minf(cost, _MAX_SAFE_COST)))
	return MilestoneCalc.apply_milestone_cost_multiplier(int_cost, target_level, milestones, milestone_cost_multiplier)


# --- Partner cost — segmented adaptive exponential by owned count ---
#
# cost(count→count+1) = base_cost * growth^count (segment boundary applied continuously)
# Milestone target counts pay ×milestone_cost_multiplier.

static func get_partner_cost(
	partner_index: int,
	count: int,
	base_costs: Array,
	growth_early: float,
	growth_mid: float,
	growth_late: float,
	mid_start_count: int,
	late_start_count: int,
	milestones: Array,
	milestone_cost_multiplier: int
) -> int:
	if partner_index < 0 or partner_index >= base_costs.size():
		return 0

	var current_count: int = maxi(0, count)
	var target_count: int = current_count + 1
	var base: float = float(base_costs[partner_index])

	var cost: float
	if current_count < mid_start_count:
		cost = base * pow(growth_early, float(current_count))
	elif current_count < late_start_count:
		var cost_at_boundary: float = base * pow(growth_early, float(mid_start_count - 1))
		cost = cost_at_boundary * pow(growth_mid, float(current_count - (mid_start_count - 1)))
	else:
		var cost_at_early: float = base * pow(growth_early, float(mid_start_count - 1))
		var cost_at_mid: float = cost_at_early * pow(growth_mid, float(late_start_count - mid_start_count))
		cost = cost_at_mid * pow(growth_late, float(current_count - (late_start_count - 1)))

	var int_cost: int = maxi(1, ceili(minf(cost, _MAX_SAFE_COST)))
	return MilestoneCalc.apply_milestone_cost_multiplier(int_cost, target_count, milestones, milestone_cost_multiplier)


# --- Building cost — exponential growth ---
#
# cost(count) = base_cost * growth^count
# Buildings do not use milestone cost spikes.

static func get_building_cost(
	building_index: int,
	count: int,
	base_costs: Array,
	growth: float
) -> int:
	if building_index < 0 or building_index >= base_costs.size():
		return 0
	var base: float = float(base_costs[building_index])
	var cost: float = base * pow(growth, float(count))
	return maxi(1, ceili(minf(cost, _MAX_SAFE_COST)))
