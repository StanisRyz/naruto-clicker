class_name MilestoneCalculator
extends RefCounted


static func get_reached_milestone_count(value: int, milestones: Array) -> int:
	var count: int = 0
	for milestone in milestones:
		if value >= milestone:
			count += 1
	return count


static func get_milestone_multiplier(value: int, milestones: Array, multiplier_per_reached: int) -> int:
	var multiplier: int = 1
	for milestone in milestones:
		if value >= milestone:
			multiplier *= multiplier_per_reached
	return multiplier


static func is_milestone_target(value: int, milestones: Array) -> bool:
	return milestones.has(value)


static func apply_milestone_cost_multiplier(cost: int, target: int, milestones: Array, cost_multiplier: int) -> int:
	if is_milestone_target(target, milestones):
		return cost * cost_multiplier
	return cost


static func get_next_milestone(value: int, milestones: Array) -> int:
	for milestone in milestones:
		if value < milestone:
			return milestone
	return 0


static func apply_milestone_cost_multiplier_bn(cost: BigNumber, target: int, milestones: Array, cost_multiplier: int) -> BigNumber:
	if is_milestone_target(target, milestones):
		return cost.multiply_int(cost_multiplier)
	return cost
