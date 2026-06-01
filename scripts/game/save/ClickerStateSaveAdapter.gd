# Save System v1 adapter. Field names here are part of the save format contract.
# Do not rename saved keys without adding a migration in SaveManager.
# ClickerState remains the gameplay API. SaveManager remains the file IO layer.
class_name ClickerStateSaveAdapter
extends RefCounted

const TaskRT = preload("res://scripts/game/runtime/TaskRuntime.gd")


static func build_save_data(state: ClickerState) -> Dictionary:
	var cleared_str: Dictionary = {}
	for k in state.cleared_level_ids:
		cleared_str[str(k)] = true

	var progress_str: Dictionary = {}
	for k in state.level_enemy_progress:
		progress_str[str(k)] = state.level_enemy_progress[k]

	return {
		"gold": state.gold,
		"gems": state.gems,
		"character_level": state.character_level,
		"current_level": state.current_level,
		"max_unlocked_level": state.max_unlocked_level,
		"enemies_defeated_on_level": state.enemies_defeated_on_level,
		"cleared_level_ids": cleared_str,
		"level_enemy_progress": progress_str,
		"auto_stage_advance_enabled": state.auto_stage_advance_enabled,
		"autoclick_purchased": state.autoclick_purchased,
		"gold_bonus_purchased": state.gold_bonus_purchased,
		"focus_burst_purchased": state.focus_burst_purchased,
		"rally_purchased": state.rally_purchased,
		"purchased_hero_skill_ids": Array(state.purchased_hero_skill_ids),
		"purchased_ability_skill_ids": Array(state.purchased_ability_skill_ids),
		"purchased_partner_skill_ids": Array(state.purchased_partner_skill_ids),
		"partner_counts": Array(state.partner_counts),
		"building_counts": Array(state.building_counts),
		"prestige_points_available": state.prestige_points_available,
		"prestige_points_total_earned": state.prestige_points_total_earned,
		"total_prestiges": state.total_prestiges,
		"prestige_talent_levels": Array(state.prestige_talent_levels),
		"boss_retry_tokens": state.boss_retry_tokens,
		"task_reward_boost_multiplier": state.task_reward_boost_multiplier,
		"active_task_ids": Array(state.active_task_ids),
		"inactive_task_ids": Array(state.inactive_task_ids),
		"active_task_states": state.active_task_states.duplicate(true),
		"total_manual_click_damage_dealt": state.total_manual_click_damage_dealt,
		"total_enemies_defeated": state.total_enemies_defeated,
		"total_elite_enemies_defeated": state.total_elite_enemies_defeated,
		"total_bosses_defeated": state.total_bosses_defeated,
		"total_autoclick_activations": state.total_autoclick_activations,
		"total_combo_empowered_activations": state.total_combo_empowered_activations,
		"sound_enabled": state.sound_enabled,
		"music_enabled": state.music_enabled,
		"language": state.language,
	}


static func apply_save_data(state: ClickerState, data: Dictionary) -> bool:
	if data.is_empty():
		return false

	state.gold = maxi(0, int(data.get("gold", 0)))
	state.gems = maxi(0, int(data.get("gems", 0)))
	state.character_level = maxi(1, int(data.get("character_level", 1)))
	state.current_level = maxi(1, int(data.get("current_level", 1)))
	state.max_unlocked_level = maxi(state.current_level, int(data.get("max_unlocked_level", 1)))
	state.auto_stage_advance_enabled = bool(data.get("auto_stage_advance_enabled", true))
	state.sound_enabled = bool(data.get("sound_enabled", true))
	state.music_enabled = bool(data.get("music_enabled", true))
	var saved_lang: String = str(data.get("language", "en"))
	state.language = saved_lang if saved_lang in ["en", "ru"] else "en"

	state.cleared_level_ids.clear()
	var raw_cleared = data.get("cleared_level_ids", {})
	if raw_cleared is Dictionary:
		for k in raw_cleared:
			var lvl: int = int(str(k))
			if lvl > 0:
				state.cleared_level_ids[lvl] = true

	state.level_enemy_progress.clear()
	var raw_progress = data.get("level_enemy_progress", {})
	if raw_progress is Dictionary:
		for k in raw_progress:
			var lvl: int = int(str(k))
			if lvl > 0:
				state.level_enemy_progress[lvl] = maxi(0, int(raw_progress[k]))

	state.autoclick_purchased = bool(data.get("autoclick_purchased", false))
	state.gold_bonus_purchased = bool(data.get("gold_bonus_purchased", false))
	state.focus_burst_purchased = bool(data.get("focus_burst_purchased", false))
	state.rally_purchased = bool(data.get("rally_purchased", false))

	state.purchased_hero_skill_ids.clear()
	var raw_hero_skills = data.get("purchased_hero_skill_ids", [])
	if raw_hero_skills is Array:
		for id in raw_hero_skills:
			var sid: String = str(id)
			if not state.get_hero_skill(sid).is_empty() and not state.purchased_hero_skill_ids.has(sid):
				state.purchased_hero_skill_ids.append(sid)

	state.purchased_ability_skill_ids.clear()
	var raw_ability_skills = data.get("purchased_ability_skill_ids", [])
	if raw_ability_skills is Array:
		for id in raw_ability_skills:
			var sid: String = str(id)
			if not state.get_ability_skill(sid).is_empty() and not state.purchased_ability_skill_ids.has(sid):
				state.purchased_ability_skill_ids.append(sid)

	state.purchased_partner_skill_ids.clear()
	var raw_partner_skills = data.get("purchased_partner_skill_ids", [])
	if raw_partner_skills is Array:
		for id in raw_partner_skills:
			var sid: String = str(id)
			if not state.get_partner_skill(sid).is_empty() and not state.purchased_partner_skill_ids.has(sid):
				state.purchased_partner_skill_ids.append(sid)

	state._reset_partner_state()
	var raw_partner_counts = data.get("partner_counts", [])
	if raw_partner_counts is Array and raw_partner_counts.size() == state.partner_counts.size():
		for i in range(state.partner_counts.size()):
			state.partner_counts[i] = maxi(0, int(raw_partner_counts[i]))
			state.recalculate_partner_cost(i)

	state._reset_building_state()
	var raw_building_counts = data.get("building_counts", [])
	if raw_building_counts is Array and raw_building_counts.size() == state.building_counts.size():
		for i in range(state.building_counts.size()):
			state.building_counts[i] = maxi(0, int(raw_building_counts[i]))
			state.recalculate_building_cost(i)

	state.prestige_points_available = maxi(0, int(data.get("prestige_points_available", 0)))
	state.prestige_points_total_earned = maxi(state.prestige_points_available, int(data.get("prestige_points_total_earned", 0)))
	state.total_prestiges = maxi(0, int(data.get("total_prestiges", 0)))

	var raw_talent_levels = data.get("prestige_talent_levels", [])
	if raw_talent_levels is Array and raw_talent_levels.size() == state.prestige_talent_levels.size():
		for i in range(state.prestige_talent_levels.size()):
			state.prestige_talent_levels[i] = maxi(0, int(raw_talent_levels[i]))

	state.boss_retry_tokens = maxi(0, int(data.get("boss_retry_tokens", 0)))
	state.task_reward_boost_multiplier = maxf(1.0, float(data.get("task_reward_boost_multiplier", 1.0)))

	state.total_manual_click_damage_dealt = maxi(0, int(data.get("total_manual_click_damage_dealt", 0)))
	state.total_enemies_defeated = maxi(0, int(data.get("total_enemies_defeated", 0)))
	state.total_elite_enemies_defeated = maxi(0, int(data.get("total_elite_enemies_defeated", 0)))
	state.total_bosses_defeated = maxi(0, int(data.get("total_bosses_defeated", 0)))
	state.total_autoclick_activations = maxi(0, int(data.get("total_autoclick_activations", 0)))
	state.total_combo_empowered_activations = maxi(0, int(data.get("total_combo_empowered_activations", 0)))

	if not _try_restore_tasks(state, data):
		state.initialize_tasks()

	state.recalculate_character_level_cost()
	state._update_character_state()
	state.setup_current_level()

	var saved_progress: int = maxi(0, int(data.get("enemies_defeated_on_level", 0)))
	if state.is_level_cleared(state.current_level):
		state.enemies_defeated_on_level = state.enemies_required_per_level
	else:
		state.enemies_defeated_on_level = clampi(saved_progress, 0, state.enemies_required_per_level)
	state.level_enemy_progress[state.current_level] = state.enemies_defeated_on_level

	return true


static func _try_restore_tasks(state: ClickerState, data: Dictionary) -> bool:
	var raw_active = data.get("active_task_ids", [])
	var raw_inactive = data.get("inactive_task_ids", [])
	var raw_states = data.get("active_task_states", {})

	if not (raw_active is Array) or not (raw_inactive is Array) or not (raw_states is Dictionary):
		return false

	var all_valid_ids: Array[String] = []
	for task: Dictionary in TaskConfig.TASK_DEFINITIONS:
		var tid: String = String(task.get("id", ""))
		if tid != "":
			all_valid_ids.append(tid)

	var seen_ids: Dictionary = {}
	var restored_active: Array[String] = []
	var restored_inactive: Array[String] = []

	for id in raw_active:
		var sid: String = str(id)
		if not all_valid_ids.has(sid) or seen_ids.has(sid):
			return false
		seen_ids[sid] = true
		restored_active.append(sid)

	for id in raw_inactive:
		var sid: String = str(id)
		if not all_valid_ids.has(sid) or seen_ids.has(sid):
			return false
		seen_ids[sid] = true
		restored_inactive.append(sid)

	if seen_ids.size() != all_valid_ids.size():
		return false

	state.active_task_ids.clear()
	state.inactive_task_ids.clear()
	state.active_task_states.clear()

	for id in restored_active:
		state.active_task_ids.append(id)
	for id in restored_inactive:
		state.inactive_task_ids.append(id)

	for task_id in state.active_task_ids:
		if raw_states.has(task_id) and raw_states[task_id] is Dictionary:
			var rs: Dictionary = raw_states[task_id]
			state.active_task_states[task_id] = {
				"start_value": int(rs.get("start_value", 0)),
				"target_delta": int(rs.get("target_delta", 0)),
				"target_value": int(rs.get("target_value", 0)),
			}
		else:
			TaskRT._initialize_active_task_state(state, task_id)

	return true
