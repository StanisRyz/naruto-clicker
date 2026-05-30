class_name EnemyScalingCalculator
extends RefCounted


static func get_base_hp(level: int, base: int, linear: float, curve: float, power: float) -> int:
	var stage: float = float(maxi(0, level - 1))
	var hp: float = float(base) + linear * stage + curve * pow(stage, power)
	return maxi(1, ceili(hp))


static func get_base_reward(level: int, base: int, linear: float, curve: float, power: float) -> int:
	var stage: float = float(maxi(0, level - 1))
	var reward: float = float(base) + linear * stage + curve * pow(stage, power)
	return maxi(1, ceili(reward))


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
