class_name TaskConfig
extends RefCounted

const ACTIVE_TASK_COUNT: int = 5

const GOAL_TYPES: Array[String] = [
	"manual_damage_delta",
	"enemies_defeated_delta",
	"elite_enemies_defeated_delta",
	"bosses_defeated_delta",
	"hero_level_delta",
	"partners_total_delta",
	"buildings_total_delta",
	"autoclick_activations_delta",
	"game_level_delta",
]

# id:           Stable save/runtime id. Do not rename after release.
# title:        English fallback/debug title.
# title_key:    Localization key in localization/game_text.csv.
# goal_type:    One of GOAL_TYPES. Runtime counter used for progress.
# target_delta: How much progress is required from the moment the task becomes active.
# reward_scale: Multiplier applied to current task reward unit.
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


static func is_goal_type_supported(goal_type: String) -> bool:
	return GOAL_TYPES.has(goal_type)


static func validate() -> Array[String]:
	var errors: Array[String] = []
	var seen_ids: Dictionary = {}

	for i in range(TASK_DEFINITIONS.size()):
		var task: Dictionary = TASK_DEFINITIONS[i]
		var id: String = String(task.get("id", ""))
		var title_key: String = String(task.get("title_key", ""))
		var goal_type: String = String(task.get("goal_type", ""))
		var target_delta: int = int(task.get("target_delta", 0))
		var reward_scale: int = int(task.get("reward_scale", 0))

		if id == "":
			errors.append("Task %d has empty id." % i)
		elif seen_ids.has(id):
			errors.append("Duplicate task id: %s" % id)
		else:
			seen_ids[id] = true

		if title_key == "":
			errors.append("Task %s has empty title_key." % id)

		if not is_goal_type_supported(goal_type):
			errors.append("Task %s has unsupported goal_type: %s" % [id, goal_type])

		if target_delta <= 0:
			errors.append("Task %s has invalid target_delta: %d" % [id, target_delta])

		if reward_scale <= 0:
			errors.append("Task %s has invalid reward_scale: %d" % [id, reward_scale])

	if TASK_DEFINITIONS.size() < ACTIVE_TASK_COUNT:
		errors.append("Not enough tasks: %d definitions for %d active tasks." % [
			TASK_DEFINITIONS.size(),
			ACTIVE_TASK_COUNT,
		])

	return errors


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
