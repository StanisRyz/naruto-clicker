class_name EnemyPoolConfig
extends RefCounted

const EARLY_POOL_ZONE: int = 1
const MID_POOL_ZONE: int = 11
const LATE_POOL_ZONE: int = 17

const POOL_DATA: Dictionary = {
	1: {
		"normal": [
			{"name": "Training Rogue 01",       "name_key": "enemy.pool_01.enemy_01.name", "slot": "enemy_01"},
			{"name": "Training Rogue 02",       "name_key": "enemy.pool_01.enemy_02.name", "slot": "enemy_02"},
			{"name": "Training Rogue 03",       "name_key": "enemy.pool_01.enemy_03.name", "slot": "enemy_03"},
			{"name": "Training Bandit 04",      "name_key": "enemy.pool_01.enemy_04.name", "slot": "enemy_04"},
			{"name": "Training Bandit 05",      "name_key": "enemy.pool_01.enemy_05.name", "slot": "enemy_05"},
			{"name": "Training Bandit 06",      "name_key": "enemy.pool_01.enemy_06.name", "slot": "enemy_06"},
			{"name": "Forest Scout 07",         "name_key": "enemy.pool_01.enemy_07.name", "slot": "enemy_07"},
			{"name": "Forest Scout 08",         "name_key": "enemy.pool_01.enemy_08.name", "slot": "enemy_08"},
			{"name": "Stone Drifter 09",        "name_key": "enemy.pool_01.enemy_09.name", "slot": "enemy_09"},
			{"name": "Stone Drifter 10",        "name_key": "enemy.pool_01.enemy_10.name", "slot": "enemy_10"},
			{"name": "Shadow Runner 11",        "name_key": "enemy.pool_01.enemy_11.name", "slot": "enemy_11"},
			{"name": "Shadow Runner 12",        "name_key": "enemy.pool_01.enemy_12.name", "slot": "enemy_12"},
			{"name": "Ash Wanderer 13",         "name_key": "enemy.pool_01.enemy_13.name", "slot": "enemy_13"},
			{"name": "Mist Striker 14",         "name_key": "enemy.pool_01.enemy_14.name", "slot": "enemy_14"},
			{"name": "Wandering Shinobi 15",    "name_key": "enemy.pool_01.enemy_15.name", "slot": "enemy_15"},
		],
		"elite": [
			{"name": "Elite Training Rogue 01",       "name_key": "enemy.pool_01.elite_01.name", "slot": "elite_01"},
			{"name": "Elite Forest Scout 02",         "name_key": "enemy.pool_01.elite_02.name", "slot": "elite_02"},
			{"name": "Elite Shadow Runner 03",        "name_key": "enemy.pool_01.elite_03.name", "slot": "elite_03"},
			{"name": "Elite Wandering Shinobi 04",    "name_key": "enemy.pool_01.elite_04.name", "slot": "elite_04"},
		],
	},
	11: {
		"normal": [
			{"name": "Iron Guard 01",           "name_key": "enemy.pool_11.enemy_01.name", "slot": "enemy_01"},
			{"name": "Iron Guard 02",           "name_key": "enemy.pool_11.enemy_02.name", "slot": "enemy_02"},
			{"name": "Fortress Spearman 03",    "name_key": "enemy.pool_11.enemy_03.name", "slot": "enemy_03"},
			{"name": "Fortress Spearman 04",    "name_key": "enemy.pool_11.enemy_04.name", "slot": "enemy_04"},
			{"name": "Broken Watcher 05",       "name_key": "enemy.pool_11.enemy_05.name", "slot": "enemy_05"},
			{"name": "Broken Watcher 06",       "name_key": "enemy.pool_11.enemy_06.name", "slot": "enemy_06"},
			{"name": "Desert Rogue 07",         "name_key": "enemy.pool_11.enemy_07.name", "slot": "enemy_07"},
			{"name": "Desert Rogue 08",         "name_key": "enemy.pool_11.enemy_08.name", "slot": "enemy_08"},
			{"name": "Snow Assassin 09",        "name_key": "enemy.pool_11.enemy_09.name", "slot": "enemy_09"},
			{"name": "Snow Assassin 10",        "name_key": "enemy.pool_11.enemy_10.name", "slot": "enemy_10"},
			{"name": "Frost Scout 11",          "name_key": "enemy.pool_11.enemy_11.name", "slot": "enemy_11"},
			{"name": "Frost Scout 12",          "name_key": "enemy.pool_11.enemy_12.name", "slot": "enemy_12"},
			{"name": "Ice Guard 13",            "name_key": "enemy.pool_11.enemy_13.name", "slot": "enemy_13"},
			{"name": "Temple Shade 14",         "name_key": "enemy.pool_11.enemy_14.name", "slot": "enemy_14"},
			{"name": "Dark Monk 15",            "name_key": "enemy.pool_11.enemy_15.name", "slot": "enemy_15"},
		],
		"elite": [
			{"name": "Elite Iron Guard 01",        "name_key": "enemy.pool_11.elite_01.name", "slot": "elite_01"},
			{"name": "Elite Broken Watcher 02",    "name_key": "enemy.pool_11.elite_02.name", "slot": "elite_02"},
			{"name": "Elite Desert Rogue 03",      "name_key": "enemy.pool_11.elite_03.name", "slot": "elite_03"},
			{"name": "Elite Snow Assassin 04",     "name_key": "enemy.pool_11.elite_04.name", "slot": "elite_04"},
			{"name": "Elite Temple Shade 05",      "name_key": "enemy.pool_11.elite_05.name", "slot": "elite_05"},
		],
	},
	17: {
		"normal": [
			{"name": "Storm Summit Guard 01",       "name_key": "enemy.pool_17.enemy_01.name", "slot": "enemy_01"},
			{"name": "Storm Summit Striker 02",     "name_key": "enemy.pool_17.enemy_02.name", "slot": "enemy_02"},
			{"name": "Storm Summit Watcher 03",     "name_key": "enemy.pool_17.enemy_03.name", "slot": "enemy_03"},
			{"name": "Storm Summit Raider 04",      "name_key": "enemy.pool_17.enemy_04.name", "slot": "enemy_04"},
			{"name": "Storm Summit Duelist 05",     "name_key": "enemy.pool_17.enemy_05.name", "slot": "enemy_05"},
			{"name": "Storm Summit Scout 06",       "name_key": "enemy.pool_17.enemy_06.name", "slot": "enemy_06"},
			{"name": "Storm Summit Hunter 07",      "name_key": "enemy.pool_17.enemy_07.name", "slot": "enemy_07"},
			{"name": "Storm Summit Sentinel 08",    "name_key": "enemy.pool_17.enemy_08.name", "slot": "enemy_08"},
			{"name": "Storm Summit Enforcer 09",    "name_key": "enemy.pool_17.enemy_09.name", "slot": "enemy_09"},
		],
		"elite": [
			{"name": "Elite Storm Summit Guard 01",     "name_key": "enemy.pool_17.elite_01.name", "slot": "elite_01"},
			{"name": "Elite Storm Summit Striker 02",   "name_key": "enemy.pool_17.elite_02.name", "slot": "elite_02"},
			{"name": "Elite Storm Summit Watcher 03",   "name_key": "enemy.pool_17.elite_03.name", "slot": "elite_03"},
		],
	},
}


static func get_pool_zone_number_for_gameplay_zone(gameplay_zone_number: int) -> int:
	if gameplay_zone_number <= 10:
		return EARLY_POOL_ZONE
	if gameplay_zone_number <= 16:
		return MID_POOL_ZONE
	return LATE_POOL_ZONE


static func get_pool_zone_number_for_level(level: int) -> int:
	var gameplay_zone_number := ZoneConfig.get_zone_number_for_level(level)
	return get_pool_zone_number_for_gameplay_zone(gameplay_zone_number)


static func get_pool_zone_index_for_level(level: int) -> int:
	return get_pool_zone_number_for_level(level) - 1


static func get_normal_candidates_for_level(level: int) -> Array:
	var pool_zone := get_pool_zone_number_for_level(level)
	return Array(POOL_DATA.get(pool_zone, {}).get("normal", []))


static func get_elite_candidates_for_level(level: int) -> Array:
	var pool_zone := get_pool_zone_number_for_level(level)
	return Array(POOL_DATA.get(pool_zone, {}).get("elite", []))


static func get_random_normal_candidate(level: int, rng: RandomNumberGenerator) -> Dictionary:
	var candidates := get_normal_candidates_for_level(level)
	if candidates.is_empty():
		return {
			"name": "Enemy",
			"name_key": "",
			"slot": "enemy_01",
		}
	return candidates[rng.randi_range(0, candidates.size() - 1)]


static func get_random_elite_candidate(level: int, rng: RandomNumberGenerator) -> Dictionary:
	var candidates := get_elite_candidates_for_level(level)
	if candidates.is_empty():
		return {
			"name": "Elite Enemy",
			"name_key": "",
			"slot": "elite_01",
		}
	return candidates[rng.randi_range(0, candidates.size() - 1)]
