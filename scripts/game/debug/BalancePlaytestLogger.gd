# Debug-only local balance telemetry. Collects gameplay events and exports to CSV.
# Never called in release builds. Does not modify game state. Does not call SaveManager.
# Does not reference UI nodes. No network calls.
class_name BalancePlaytestLogger
extends RefCounted

var session_start_time_msec: int = 0
var rows: Array[Dictionary] = []
var level_start_time_msec: int = 0
var current_level_start_gold: int = 0
var current_level_start_kill_count: int = 0
var enemy_spawn_time_msec: int = 0
var enemy_start_hp: int = 0

var _enemy_was_boss: bool = false
var _enemy_was_elite: bool = false
var _total_gold_from_kills: int = 0
var _total_gold_spent: int = 0
var _total_task_rewards: int = 0
var _total_shop_rewards: int = 0
var _boss_ttk_samples: Array[float] = []
var _enemy_ttk_samples: Array[float] = []


func start_session(state: ClickerState) -> void:
	session_start_time_msec = Time.get_ticks_msec()
	rows.clear()
	_total_gold_from_kills = 0
	_total_gold_spent = 0
	_total_task_rewards = 0
	_total_shop_rewards = 0
	_boss_ttk_samples.clear()
	_enemy_ttk_samples.clear()
	level_start_time_msec = session_start_time_msec
	current_level_start_gold = state.gold
	current_level_start_kill_count = state.total_enemies_defeated
	enemy_spawn_time_msec = session_start_time_msec
	enemy_start_hp = state.target_max_hp
	_enemy_was_boss = state.is_boss_level
	_enemy_was_elite = state.is_elite_enemy
	rows.append(_base_row(state, "session_start"))


func mark_level_started(state: ClickerState) -> void:
	level_start_time_msec = Time.get_ticks_msec()
	current_level_start_gold = state.gold
	current_level_start_kill_count = state.total_enemies_defeated


func mark_enemy_spawned(state: ClickerState) -> void:
	enemy_spawn_time_msec = Time.get_ticks_msec()
	enemy_start_hp = state.target_max_hp
	_enemy_was_boss = state.is_boss_level
	_enemy_was_elite = state.is_elite_enemy


func log_enemy_defeated(state: ClickerState, result: Dictionary) -> void:
	var ttk_sec: float = float(Time.get_ticks_msec() - enemy_spawn_time_msec) / 1000.0
	var reward: int = result.get("reward_gold", 0)
	_total_gold_from_kills += reward
	if _enemy_was_boss:
		_boss_ttk_samples.append(ttk_sec)
	else:
		_enemy_ttk_samples.append(ttk_sec)
	var row: Dictionary = _base_row(state, "enemy_defeated")
	row["defeated_on_level"] = result.get("defeated_on_level", state.current_level)
	row["enemy_start_hp"] = enemy_start_hp
	row["enemy_reward_gold"] = reward
	row["enemy_ttk_sec"] = "%.3f" % ttk_sec
	row["was_boss"] = _enemy_was_boss
	row["was_elite"] = _enemy_was_elite
	row["level_cleared"] = result.get("level_up", false)
	row["level_changed"] = result.get("advanced_to_next_level", false)
	row["new_level"] = state.current_level
	row["enemies_defeated_total"] = state.total_enemies_defeated
	rows.append(row)


func log_boss_failed(state: ClickerState) -> void:
	var retry_available: bool = state.boss_retry_tokens > 0
	var row: Dictionary = _base_row(state, "boss_failed")
	row["boss_hp_remaining"] = state.target_hp
	row["boss_max_hp"] = state.target_max_hp
	row["boss_retry_tokens"] = state.boss_retry_tokens
	row["retry_will_be_used"] = retry_available
	row["returned_to_level"] = state.current_level if retry_available else maxi(1, state.current_level - 1)
	rows.append(row)


func log_purchase(state: ClickerState, category: String, item_id: String, cost: int, result: Dictionary) -> void:
	var success: bool = result.get("upgraded", false)
	if success:
		if category == "shop":
			_total_shop_rewards += result.get("reward_gold", 0)
		elif category != "prestige_talent":
			_total_gold_spent += cost
	var row: Dictionary = _base_row(state, "purchase")
	row["purchase_category"] = category
	row["item_id"] = item_id
	row["cost"] = cost
	row["success"] = success
	row["not_enough_gold"] = result.get("not_enough_gold", false)
	rows.append(row)


func log_task_claimed(state: ClickerState, task_id: String, result: Dictionary) -> void:
	var reward: int = result.get("reward_gold", 0)
	_total_task_rewards += reward
	var row: Dictionary = _base_row(state, "task_claimed")
	row["task_id"] = task_id
	row["task_reward_gold"] = reward
	rows.append(row)


func log_ability_used(state: ClickerState, ability_id: String) -> void:
	var row: Dictionary = _base_row(state, "ability_used")
	row["ability_id"] = ability_id
	row["ability_rank"] = state.get_ability_rank(ability_id)
	rows.append(row)


func log_level_changed(state: ClickerState, previous_level: int, new_level: int) -> void:
	var row: Dictionary = _base_row(state, "level_changed")
	row["previous_level"] = previous_level
	row["new_level"] = new_level
	row["level_time_sec"] = "%.2f" % (float(Time.get_ticks_msec() - level_start_time_msec) / 1000.0)
	row["gold_earned_on_level"] = state.gold - current_level_start_gold
	row["kills_on_level"] = state.total_enemies_defeated - current_level_start_kill_count
	rows.append(row)
	mark_level_started(state)


func export_csv(path: String = "user://balance_playtest.csv") -> bool:
	if rows.is_empty():
		push_warning("BalancePlaytestLogger: no rows to export")
		return false
	var columns: Array[String] = _get_column_order()
	var lines: Array[String] = []
	lines.append(_join_row(columns))
	for row: Dictionary in rows:
		var parts: Array[String] = []
		for col: String in columns:
			var raw: String = str(row.get(col, ""))
			if raw.contains(",") or raw.contains("\"") or raw.contains("\n"):
				raw = "\"" + raw.replace("\"", "\"\"") + "\""
			parts.append(raw)
		lines.append(_join_row(parts))
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("BalancePlaytestLogger: cannot write %s (error %d)" % [path, FileAccess.get_open_error()])
		return false
	for line: String in lines:
		file.store_line(line)
	file.close()
	return true


func clear() -> void:
	rows.clear()
	_total_gold_from_kills = 0
	_total_gold_spent = 0
	_total_task_rewards = 0
	_total_shop_rewards = 0
	_boss_ttk_samples.clear()
	_enemy_ttk_samples.clear()
	session_start_time_msec = Time.get_ticks_msec()


func get_summary() -> Dictionary:
	var session_sec: float = float(Time.get_ticks_msec() - session_start_time_msec) / 1000.0
	var highest_level: int = 1
	var enemies_defeated: int = 0
	var bosses_defeated: int = 0
	var boss_fails: int = 0
	var purchases: int = 0
	var tasks_claimed: int = 0
	var abilities_used: int = 0
	for row: Dictionary in rows:
		var et: String = String(row.get("event_type", ""))
		match et:
			"enemy_defeated":
				enemies_defeated += 1
				if bool(row.get("was_boss", false)):
					bosses_defeated += 1
				var lvl: int = int(row.get("new_level", row.get("current_level", 1)))
				if lvl > highest_level:
					highest_level = lvl
			"boss_failed":
				boss_fails += 1
			"purchase":
				if bool(row.get("success", false)):
					purchases += 1
			"task_claimed":
				tasks_claimed += 1
			"ability_used":
				abilities_used += 1
	var avg_enemy_ttk: float = 0.0
	if not _enemy_ttk_samples.is_empty():
		var sum: float = 0.0
		for v: float in _enemy_ttk_samples:
			sum += v
		avg_enemy_ttk = sum / float(_enemy_ttk_samples.size())
	var avg_boss_ttk: float = 0.0
	if not _boss_ttk_samples.is_empty():
		var sum: float = 0.0
		for v: float in _boss_ttk_samples:
			sum += v
		avg_boss_ttk = sum / float(_boss_ttk_samples.size())
	return {
		"session_duration_sec": session_sec,
		"highest_level_reached": highest_level,
		"enemies_defeated": enemies_defeated,
		"bosses_defeated": bosses_defeated,
		"boss_fails": boss_fails,
		"total_gold_earned_from_kills": _total_gold_from_kills,
		"total_gold_spent": _total_gold_spent,
		"total_task_rewards": _total_task_rewards,
		"total_shop_rewards": _total_shop_rewards,
		"average_enemy_ttk_sec": avg_enemy_ttk,
		"average_boss_ttk_sec": avg_boss_ttk,
		"purchases_count": purchases,
		"tasks_claimed_count": tasks_claimed,
		"abilities_used_count": abilities_used,
	}


func _base_row(state: ClickerState, event_type: String) -> Dictionary:
	return {
		"timestamp_sec": "%.2f" % (float(Time.get_ticks_msec() - session_start_time_msec) / 1000.0),
		"event_type": event_type,
		"current_level": state.current_level,
		"max_unlocked_level": state.max_unlocked_level,
		"current_zone_index": state.current_zone_index,
		"enemy_type": state.get_current_enemy_type(),
		"enemy_name": state.enemy_name,
		"gold": state.gold,
		"gems": state.gems,
		"character_level": state.character_level,
		"click_damage": state.get_current_click_damage(),
		"partner_dps": state.get_final_partner_dps(),
		"auto_transition_enabled": state.auto_stage_advance_enabled,
	}


func _join_row(parts: Array[String]) -> String:
	var result: String = ""
	for i: int in range(parts.size()):
		if i > 0:
			result += ","
		result += parts[i]
	return result


func _get_column_order() -> Array[String]:
	return [
		"timestamp_sec", "event_type",
		"current_level", "max_unlocked_level", "current_zone_index",
		"enemy_type", "enemy_name",
		"gold", "gems", "character_level", "click_damage", "partner_dps",
		"auto_transition_enabled",
		"defeated_on_level",
		"enemy_start_hp", "enemy_reward_gold", "enemy_ttk_sec",
		"was_boss", "was_elite",
		"level_cleared", "level_changed", "new_level", "enemies_defeated_total",
		"boss_hp_remaining", "boss_max_hp", "boss_retry_tokens",
		"retry_will_be_used", "returned_to_level",
		"purchase_category", "item_id", "cost", "success", "not_enough_gold",
		"task_id", "task_reward_gold",
		"ability_id", "ability_rank",
		"previous_level", "level_time_sec", "gold_earned_on_level", "kills_on_level",
	]
