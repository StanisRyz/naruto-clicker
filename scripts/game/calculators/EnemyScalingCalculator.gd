class_name EnemyScalingCalculator
extends RefCounted


# --- Base enemy HP — exponential ---
# hp(level) = base * growth^(level-1)
static func get_base_hp(level: int, base: float, growth: float) -> int:
	var stage: int = maxi(0, level - 1)
	return maxi(1, ceili(base * pow(growth, float(stage))))


# --- Base enemy reward — exponential ---
# reward(level) = base * growth^(level-1)
static func get_base_reward(level: int, base: float, growth: float) -> int:
	var stage: int = maxi(0, level - 1)
	return maxi(1, ceili(base * pow(growth, float(stage))))


static func get_scaled_hp(
	base_hp: int,
	zone_multiplier: float,
	is_boss: bool,
	is_elite: bool,
	boss_multiplier: int,
	elite_multiplier: int
) -> int:
	var scaled: int = ceili(base_hp * zone_multiplier)
	if is_boss:
		return scaled * boss_multiplier
	if is_elite:
		return scaled * elite_multiplier
	return scaled


static func get_scaled_reward(
	base_reward: int,
	zone_multiplier: float,
	is_boss: bool,
	is_elite: bool,
	boss_multiplier: int,
	elite_multiplier: int
) -> int:
	var scaled: int = ceili(base_reward * zone_multiplier)
	if is_boss:
		return scaled * boss_multiplier
	if is_elite:
		return scaled * elite_multiplier
	return scaled
