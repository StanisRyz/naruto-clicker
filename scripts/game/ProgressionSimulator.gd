class_name ProgressionSimulator
extends RefCounted

const F2P_CASUAL: String = "f2p_casual"
const AD_WATCHER: String = "ad_watcher"
const LIGHT_SPENDER: String = "light_spender"

# Approximate clicks per second for each profile.
const _PROFILE_CPS: Dictionary = {
	F2P_CASUAL: 0.5,
	AD_WATCHER: 1.0,
	LIGHT_SPENDER: 2.0,
}

# How aggressively to buy upgrades (1 = conservative, 3 = aggressive).
const _PROFILE_SPEND_RATE: Dictionary = {
	F2P_CASUAL: 1,
	AD_WATCHER: 2,
	LIGHT_SPENDER: 3,
}

# Maximum simulation iterations to prevent infinite loops.
const _MAX_ITERATIONS: int = 500000


func simulate_minutes(minutes: float, profile: String) -> Dictionary:
	return _run(minutes, -1, false, profile)


func simulate_until_level(target_level: int, profile: String) -> Dictionary:
	return _run(-1.0, target_level, false, profile)


func simulate_until_first_prestige(profile: String) -> Dictionary:
	return _run(-1.0, -1, true, profile)


func build_progression_table(minutes: Array, profile: String) -> Array:
	var rows: Array = []
	for m in minutes:
		var snapshot: Dictionary = simulate_minutes(float(m), profile)
		snapshot["minutes"] = float(m)
		snapshot["profile"] = profile
		rows.append(snapshot)
	return rows


func export_csv(path: String, rows: Array) -> bool:
	if rows.is_empty():
		return false

	var columns: Array = [
		"profile", "minutes", "level", "hero_level", "total_power",
		"click_damage", "partner_dps", "enemy_hp", "enemy_reward",
		"gold_per_minute", "time_to_clear_level", "prestige_points",
	]

	var lines: PackedStringArray = PackedStringArray()
	lines.append(",".join(columns))
	for row in rows:
		var cells: Array = []
		for col in columns:
			cells.append(str(row.get(col, "")))
		lines.append(",".join(cells))

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	for line in lines:
		file.store_line(line)
	file.close()
	return true


func _run(max_minutes: float, target_level: int, stop_at_prestige: bool, profile: String) -> Dictionary:
	var sim := ClickerState.new()
	var cps: float = _PROFILE_CPS.get(profile, 0.5)
	var spend_rate: int = _PROFILE_SPEND_RATE.get(profile, 1)
	var elapsed: float = 0.0
	var max_seconds: float = max_minutes * 60.0 if max_minutes > 0.0 else 1e9
	var gold_window_start: float = 0.0
	var gold_window_amount: int = 0
	var gold_per_minute: float = 0.0
	var iteration: int = 0

	while elapsed < max_seconds and iteration < _MAX_ITERATIONS:
		iteration += 1

		if target_level > 0 and sim.current_level >= target_level:
			break
		if stop_at_prestige and sim.can_prestige():
			break

		var total_dps: float = _estimate_dps(sim, cps)
		if total_dps <= 0.0:
			elapsed += 1.0
			continue

		var time_to_kill: float = sim.target_hp / total_dps
		elapsed += time_to_kill

		# Kill enemy and collect gold.
		sim.target_hp = 0
		var result: Dictionary = sim.resolve_defeated_target()
		var earned: int = int(result.get("reward_gold", 0))
		gold_window_amount += earned

		# Update gold/min estimate every 60 simulated seconds.
		var window_duration: float = elapsed - gold_window_start
		if window_duration >= 60.0:
			gold_per_minute = gold_window_amount / (window_duration / 60.0)
			gold_window_amount = 0
			gold_window_start = elapsed

		_spend_greedily(sim, spend_rate)

	return _snapshot(sim, elapsed / 60.0, profile, gold_per_minute)


func _estimate_dps(sim: ClickerState, cps: float) -> float:
	var manual_dps: float = float(sim.click_damage) * cps
	var partner_dps: float = float(sim.get_final_partner_dps())
	return manual_dps + partner_dps


func _spend_greedily(sim: ClickerState, spend_rate: int) -> void:
	# Buy character levels first; then partners cheapest-first.
	# spend_rate controls how many rounds of purchases to attempt.
	for _round in range(spend_rate):
		var bought_any: bool = false

		# Buy character levels while affordable.
		while sim.gold >= sim.character_level_upgrade_cost:
			sim.buy_character_level_upgrade()
			bought_any = true

		# Buy partners in order while first one of each tier is affordable.
		for i in range(sim.partner_counts.size()):
			if sim.can_buy_partner(i) and sim.gold >= sim.partner_purchase_costs[i]:
				sim.buy_partner(i)
				bought_any = true
				break  # restart the partner loop after a purchase

		if not bought_any:
			break


func _snapshot(sim: ClickerState, elapsed_minutes: float, profile: String, gold_per_minute: float) -> Dictionary:
	var total_dps: float = _estimate_dps(sim, _PROFILE_CPS.get(profile, 0.5))
	var time_to_clear: float = 0.0
	if total_dps > 0.0:
		var enemies_needed: int = sim.enemies_required_per_level - sim.enemies_defeated_on_level
		time_to_clear = (float(enemies_needed) * float(sim.target_max_hp)) / total_dps

	return {
		"minutes": elapsed_minutes,
		"profile": profile,
		"level": sim.current_level,
		"hero_level": sim.character_level,
		"click_damage": sim.click_damage,
		"partner_dps": sim.get_final_partner_dps(),
		"total_power": sim.click_damage + sim.get_final_partner_dps(),
		"enemy_hp": sim.target_max_hp,
		"enemy_reward": sim.reward_gold,
		"gold_per_minute": int(gold_per_minute),
		"time_to_clear_level": snappedf(time_to_clear, 0.1),
		"prestige_points": sim.get_prestige_reward(),
	}
