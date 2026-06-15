class_name EnemyScalingCalculator
extends RefCounted


# --- Base enemy HP — exponential — returns BigNumber ---
# hp(level) = base * growth^(level-1)
static func get_base_hp(level: int, base: float, growth: float) -> BigNumber:
	var stage: int = maxi(0, level - 1)
	var result: BigNumber = BigNumber.pow_float(growth, stage).multiply_float(base)
	if result.is_zero():
		return BigNumber.one()
	return result


# --- Base enemy reward — exponential — returns BigNumber ---
# reward(level) = base * growth^(level-1)
static func get_base_reward(level: int, base: float, growth: float) -> BigNumber:
	var stage: int = maxi(0, level - 1)
	var result: BigNumber = BigNumber.pow_float(growth, stage).multiply_float(base)
	if result.is_zero():
		return BigNumber.one()
	return result


static func get_scaled_hp(
	base_hp: BigNumber,
	zone_multiplier: float,
	is_boss: bool,
	is_elite: bool,
	boss_multiplier: int,
	elite_multiplier: int
) -> BigNumber:
	var scaled: BigNumber = base_hp.multiply_float(zone_multiplier)
	if is_boss:
		return scaled.multiply_int(boss_multiplier)
	if is_elite:
		return scaled.multiply_int(elite_multiplier)
	return scaled


static func get_scaled_reward(
	base_reward: BigNumber,
	zone_multiplier: float,
	is_boss: bool,
	is_elite: bool,
	boss_multiplier: int,
	elite_multiplier: int
) -> BigNumber:
	var scaled: BigNumber = base_reward.multiply_float(zone_multiplier)
	if is_boss:
		return scaled.multiply_int(boss_multiplier)
	if is_elite:
		return scaled.multiply_int(elite_multiplier)
	return scaled
