class_name CostCalculator
extends RefCounted

const MilestoneCalc = preload("res://scripts/game/calculators/MilestoneCalculator.gd")


# --- Hero level cost — segmented adaptive exponential — returns BigNumber ---
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
) -> BigNumber:
	var current_level: int = maxi(1, level)
	var target_level: int = current_level + 1

	var cost_bn: BigNumber
	if current_level < mid_start:
		cost_bn = BigNumber.pow_float(growth_early, current_level - 1).multiply_float(base_cost)
	elif current_level < late_start:
		# boundary value: base_cost * growth_early^(mid_start-2)
		var boundary: BigNumber = BigNumber.pow_float(growth_early, mid_start - 2).multiply_float(base_cost)
		cost_bn = boundary.multiply_float(pow(growth_mid, float(current_level - (mid_start - 1))))
	else:
		var early_boundary: BigNumber = BigNumber.pow_float(growth_early, mid_start - 2).multiply_float(base_cost)
		var mid_boundary: BigNumber = early_boundary.multiply_float(pow(growth_mid, float(late_start - mid_start)))
		cost_bn = mid_boundary.multiply_float(pow(growth_late, float(current_level - (late_start - 1))))

	cost_bn = MilestoneCalc.apply_milestone_cost_multiplier_bn(cost_bn, target_level, milestones, milestone_cost_multiplier)
	return cost_bn


# --- Partner cost — segmented adaptive exponential by owned count — returns BigNumber ---

static func get_partner_cost(
	partner_index: int,
	count: int,
	_base_costs_arr: Array,
	growth_early: float,
	growth_mid: float,
	growth_late: float,
	mid_start_count: int,
	late_start_count: int,
	milestones: Array,
	milestone_cost_multiplier: int
) -> BigNumber:
	if partner_index < 0:
		return BigNumber.zero()

	var current_count: int = maxi(0, count)
	var target_count: int = current_count + 1

	# Resolve base cost as BigNumber (handles all 28 partners via formula).
	var base_bn: BigNumber = BalanceConfig.get_partner_cost_bignum(partner_index)

	var cost_bn: BigNumber
	if current_count < mid_start_count:
		cost_bn = base_bn.multiply_float(pow(growth_early, float(current_count)))
	elif current_count < late_start_count:
		var boundary: BigNumber = base_bn.multiply_float(pow(growth_early, float(mid_start_count - 1)))
		cost_bn = boundary.multiply_float(pow(growth_mid, float(current_count - (mid_start_count - 1))))
	else:
		var early_b: BigNumber = base_bn.multiply_float(pow(growth_early, float(mid_start_count - 1)))
		var mid_b: BigNumber = early_b.multiply_float(pow(growth_mid, float(late_start_count - mid_start_count)))
		cost_bn = mid_b.multiply_float(pow(growth_late, float(current_count - (late_start_count - 1))))

	cost_bn = MilestoneCalc.apply_milestone_cost_multiplier_bn(cost_bn, target_count, milestones, milestone_cost_multiplier)
	return cost_bn


# --- Building cost — exponential growth — returns BigNumber ---

static func get_building_cost(
	building_index: int,
	count: int,
	base_costs: Array,
	growth: float
) -> BigNumber:
	if building_index < 0 or building_index >= base_costs.size():
		return BigNumber.zero()
	var base: float = float(base_costs[building_index])
	return BigNumber.from_float(base).multiply_float(pow(growth, float(count)))
