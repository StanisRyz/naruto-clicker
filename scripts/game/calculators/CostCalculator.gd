class_name CostCalculator
extends RefCounted

const MilestoneCalc = preload("res://scripts/game/calculators/MilestoneCalculator.gd")


static func get_hero_level_cost(
	level: int,
	base: int,
	linear: float,
	curve: float,
	power: float,
	milestones: Array,
	milestone_cost_multiplier: int
) -> int:
	# target level is current + 1; milestone targets cost x milestone_cost_multiplier
	var current_level: int = maxi(1, level)
	var target_level: int = current_level + 1
	var progress: float = float(current_level - 1)
	var raw_cost: float = (
		float(base)
		+ linear * progress
		+ curve * pow(progress, power)
	)
	var cost: int = maxi(1, ceili(raw_cost))
	return MilestoneCalc.apply_milestone_cost_multiplier(cost, target_level, milestones, milestone_cost_multiplier)


static func get_partner_cost(
	partner_index: int,
	count: int,
	base_costs: Array,
	cost_steps: Array,
	curve_multiplier: float,
	power: float,
	milestones: Array,
	milestone_cost_multiplier: int
) -> int:
	if partner_index < 0 or partner_index >= base_costs.size():
		return 0
	# target count is current + 1; milestone targets cost x milestone_cost_multiplier
	var current_count: int = maxi(0, count)
	var target_count: int = current_count + 1
	var base: int = base_costs[partner_index]
	var step: int = cost_steps[partner_index]
	var raw_cost: float = (
		float(base)
		+ float(step * current_count)
		+ float(base) * curve_multiplier * pow(float(current_count), power)
	)
	var cost: int = maxi(1, ceili(raw_cost))
	return MilestoneCalc.apply_milestone_cost_multiplier(cost, target_count, milestones, milestone_cost_multiplier)


static func get_building_cost(
	building_index: int,
	count: int,
	base_costs: Array,
	cost_steps: Array
) -> int:
	if building_index < 0 or building_index >= base_costs.size():
		return 0
	return base_costs[building_index] + count * cost_steps[building_index]
