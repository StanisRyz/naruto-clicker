# Task runtime operations: initialization, progress, rewards, claim/rotation.
# Reads and mutates ClickerState task fields through a passed state reference.
# Must not call SaveManager, UI, or scene nodes.
class_name TaskRuntime
extends RefCounted


# --- Initialization ---

static func initialize_tasks(state: ClickerState) -> void:
	state.active_task_ids.clear()
	state.inactive_task_ids.clear()
	state.active_task_states.clear()

	var task_ids: Array[String] = []
	for task: Dictionary in TaskConfig.TASK_DEFINITIONS:
		var task_id: String = String(task.get("id", ""))
		if task_id != "":
			task_ids.append(task_id)

	_shuffle_task_ids(state, task_ids)
	for i in range(task_ids.size()):
		var id: String = task_ids[i]
		if i < 5:
			state.active_task_ids.append(id)
			_initialize_active_task_state(state, id)
		else:
			state.inactive_task_ids.append(id)


static func _shuffle_task_ids(state: ClickerState, task_ids: Array[String]) -> void:
	if task_ids.size() < 2:
		return
	for i in range(task_ids.size() - 1, 0, -1):
		var swap_index: int = state.rng.randi_range(0, i)
		var original_id: String = task_ids[i]
		task_ids[i] = task_ids[swap_index]
		task_ids[swap_index] = original_id


static func _initialize_active_task_state(state: ClickerState, task_id: String) -> void:
	var task: Dictionary = get_task_definition(task_id)
	if task.is_empty():
		return
	var start_value: int = _get_task_current_value(state, task_id)
	var target_delta: int = int(task.get("target_delta", 0))
	state.active_task_states[task_id] = {
		"start_value": start_value,
		"target_delta": target_delta,
		"target_value": start_value + target_delta,
	}


# --- Task definitions ---

static func get_task_definition(task_id: String) -> Dictionary:
	for task: Dictionary in TaskConfig.TASK_DEFINITIONS:
		if String(task.get("id", "")) == task_id:
			return task
	return {}


# --- Progress helpers ---

static func _get_task_current_value(state: ClickerState, task_id: String) -> int:
	var task: Dictionary = get_task_definition(task_id)
	var goal_type: String = String(task.get("goal_type", ""))
	match goal_type:
		"manual_damage_delta":
			return state.total_manual_click_damage_dealt
		"enemies_defeated_delta":
			return state.total_enemies_defeated
		"elite_enemies_defeated_delta":
			return state.total_elite_enemies_defeated
		"bosses_defeated_delta":
			return state.total_bosses_defeated
		"hero_level_delta":
			return state.character_level
		"partners_total_delta":
			var partner_total: int = 0
			for c in state.partner_counts:
				partner_total += c
			return partner_total
		"buildings_total_delta":
			var building_total: int = 0
			for c in state.building_counts:
				building_total += c
			return building_total
		"autoclick_activations_delta":
			return state.total_autoclick_activations
		"combo_empowered_delta":
			return state.total_combo_empowered_activations
		"game_level_delta":
			return state.current_level
	return 0


static func get_task_progress(state: ClickerState, task_id: String) -> int:
	if not state.active_task_ids.has(task_id) or not state.active_task_states.has(task_id):
		return 0
	var task_state: Dictionary = state.active_task_states[task_id]
	var start_value: int = int(task_state.get("start_value", 0))
	var target_delta: int = int(task_state.get("target_delta", 0))
	var progress: int = _get_task_current_value(state, task_id) - start_value
	return clampi(progress, 0, target_delta)


static func get_task_target(state: ClickerState, task_id: String) -> int:
	if not state.active_task_ids.has(task_id) or not state.active_task_states.has(task_id):
		return 0
	var task_state: Dictionary = state.active_task_states[task_id]
	return int(task_state.get("target_delta", 0))


static func is_task_completed(state: ClickerState, task_id: String) -> bool:
	if not state.active_task_ids.has(task_id):
		return false
	return get_task_progress(state, task_id) >= get_task_target(state, task_id)


# --- Reward helpers ---

static func get_current_task_reward_unit(state: ClickerState) -> int:
	var base_reward: int = state.get_base_enemy_reward_for_level(state.current_level)
	var zone_scaled: int = ceili(base_reward * state.zone_reward_multiplier)
	return maxi(1, zone_scaled)


static func get_task_reward_gold(state: ClickerState, task_id: String) -> int:
	var task: Dictionary = get_task_definition(task_id)
	if task.is_empty():
		return 0
	var reward_scale: int = int(task.get("reward_scale", 0))
	if reward_scale <= 0:
		return 0
	return maxi(1, int(get_current_task_reward_unit(state) * reward_scale * state.get_partner_skill_bonus_multiplier("task_reward")))


# --- Claim / rotation ---

static func claim_task_reward(state: ClickerState, task_id: String) -> Dictionary:
	if not state.active_task_ids.has(task_id):
		return state._make_purchase_result("Task is not active")

	if not is_task_completed(state, task_id):
		return state._make_purchase_result("Task is not complete")

	var reward: int = get_task_reward_gold(state, task_id)
	if state.task_reward_boost_multiplier > 1.0:
		reward = int(reward * state.task_reward_boost_multiplier)
		state.task_reward_boost_multiplier = 1.0

	state.gold += reward
	state.active_task_ids.erase(task_id)
	state.active_task_states.erase(task_id)

	if state.inactive_task_ids.is_empty():
		state.inactive_task_ids.append(task_id)
		return state._make_purchase_result("Task complete! +%d gold" % reward, false, true)

	var replacement_index: int = state.rng.randi_range(0, state.inactive_task_ids.size() - 1)
	var replacement_id: String = state.inactive_task_ids[replacement_index]
	state.inactive_task_ids.remove_at(replacement_index)
	state.active_task_ids.append(replacement_id)
	_initialize_active_task_state(state, replacement_id)
	state.inactive_task_ids.append(task_id)

	return state._make_purchase_result("Task complete! +%d gold" % reward, false, true)


# --- Validation ---

static func validate_task_runtime_state(state: ClickerState) -> void:
	var all_valid_ids: Array[String] = []
	for task: Dictionary in TaskConfig.TASK_DEFINITIONS:
		var tid: String = String(task.get("id", ""))
		if tid != "":
			all_valid_ids.append(tid)

	# Strip unknown ids
	var i: int = state.active_task_ids.size() - 1
	while i >= 0:
		if not all_valid_ids.has(state.active_task_ids[i]):
			state.active_task_ids.remove_at(i)
		i -= 1

	i = state.inactive_task_ids.size() - 1
	while i >= 0:
		if not all_valid_ids.has(state.inactive_task_ids[i]):
			state.inactive_task_ids.remove_at(i)
		i -= 1

	# Remove duplicates — keep first occurrence
	var seen: Dictionary = {}
	var combined: Array[String] = []
	for tid in state.active_task_ids:
		if not seen.has(tid):
			seen[tid] = true
			combined.append(tid)
	state.active_task_ids.clear()
	for tid in combined:
		state.active_task_ids.append(tid)

	combined.clear()
	seen.clear()
	for tid in state.inactive_task_ids:
		if not seen.has(tid) and not state.active_task_ids.has(tid):
			seen[tid] = true
			combined.append(tid)
	state.inactive_task_ids.clear()
	for tid in combined:
		state.inactive_task_ids.append(tid)

	# Ensure active_task_states covers all active ids
	for tid in state.active_task_ids:
		if not state.active_task_states.has(tid):
			_initialize_active_task_state(state, tid)

	# Remove stale state entries for non-active tasks
	for tid in state.active_task_states.keys():
		if not state.active_task_ids.has(tid):
			state.active_task_states.erase(tid)

	# If active pool is too small and we have valid ids available, reinitialize
	var total_assigned: int = state.active_task_ids.size() + state.inactive_task_ids.size()
	if state.active_task_ids.size() < 5 and total_assigned < all_valid_ids.size():
		initialize_tasks(state)
