class_name TaskConfig
extends RefCounted

const TASK_DEFINITIONS: Array = [
	{"id": "manual_damage_500", "title": "Deal 500 manual damage", "title_key": "task.manual_damage_500.title", "goal_type": "manual_damage_delta", "target_delta": 500, "reward_scale": 4},
	{"id": "defeat_25_enemies", "title": "Defeat 25 enemies", "title_key": "task.defeat_25_enemies.title", "goal_type": "enemies_defeated_delta", "target_delta": 25, "reward_scale": 6},
	{"id": "defeat_2_elites", "title": "Defeat 2 elite enemies", "title_key": "task.defeat_2_elites.title", "goal_type": "elite_enemies_defeated_delta", "target_delta": 2, "reward_scale": 10},
	{"id": "defeat_1_boss", "title": "Defeat 1 boss", "title_key": "task.defeat_1_boss.title", "goal_type": "bosses_defeated_delta", "target_delta": 1, "reward_scale": 14},
	{"id": "gain_10_hero_levels", "title": "Gain 10 Hero Levels", "title_key": "task.gain_10_hero_levels.title", "goal_type": "hero_level_delta", "target_delta": 10, "reward_scale": 8},
	{"id": "hire_10_partners", "title": "Hire 10 partners", "title_key": "task.hire_10_partners.title", "goal_type": "partners_total_delta", "target_delta": 10, "reward_scale": 10},
	{"id": "build_5_buildings", "title": "Build 5 settlement buildings", "title_key": "task.build_5_buildings.title", "goal_type": "buildings_total_delta", "target_delta": 5, "reward_scale": 12},
	{"id": "activate_autoclick_1", "title": "Activate Autoclick 1 time", "title_key": "task.activate_autoclick_1.title", "goal_type": "autoclick_activations_delta", "target_delta": 1, "reward_scale": 8},
	{"id": "gain_10_game_levels", "title": "Reach 10 more levels", "title_key": "task.gain_10_game_levels.title", "goal_type": "game_level_delta", "target_delta": 10, "reward_scale": 16},
]


static func get_all() -> Array:
	return TASK_DEFINITIONS


static func get_by_id(task_id: String) -> Dictionary:
	for task: Dictionary in TASK_DEFINITIONS:
		if String(task.get("id", "")) == task_id:
			return task
	return {}


static func get_ids() -> Array[String]:
	var ids: Array[String] = []
	for task: Dictionary in TASK_DEFINITIONS:
		var tid: String = String(task.get("id", ""))
		if tid != "":
			ids.append(tid)
	return ids
