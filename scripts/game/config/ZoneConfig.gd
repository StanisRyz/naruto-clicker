class_name ZoneConfig
extends RefCounted

const LEVELS_PER_ZONE: int = 5
const BOSS_LEVEL_INTERVAL: int = 5

# enemies and elite_enemy are legacy display/content notes.
# Non-boss enemy runtime selection now uses EnemyPoolConfig; these fields are no longer used for enemy spawning.
const ZONE_DATA: Array = [
	{
		"name": "Training Grounds",
		"level_start": 1,
		"level_end": 5,
		"enemies": ["Rogue Ninja", "Novice Bandit", "Training Outcast"],
		"elite_enemy": "Elite Rogue Ninja",
		"boss": "Training Master",
		"hp_multiplier": 1.0,
		"reward_multiplier": 1.0,
		"enemy_asset_zone": 1,
		"background_asset_zone": 1,
	},
	{
		"name": "Forest Path",
		"level_start": 6,
		"level_end": 10,
		"enemies": ["Forest Bandit", "Wild Scout", "Hidden Archer"],
		"elite_enemy": "Elite Forest Bandit",
		"boss": "Forest Guardian",
		"hp_multiplier": 1.4,
		"reward_multiplier": 1.3,
		"enemy_asset_zone": 1,
		"background_asset_zone": 2,
	},
	{
		"name": "Stone Valley",
		"level_start": 11,
		"level_end": 15,
		"enemies": ["Stone Warrior", "Valley Raider", "Rock Sentinel"],
		"elite_enemy": "Elite Stone Warrior",
		"boss": "Valley Warlord",
		"hp_multiplier": 1.9,
		"reward_multiplier": 1.7,
		"enemy_asset_zone": 3,
		"background_asset_zone": 3,
	},
	{
		"name": "Shadow Camp",
		"level_start": 16,
		"level_end": 20,
		"enemies": ["Shadow Fighter", "Camp Assassin", "Dark Scout"],
		"elite_enemy": "Elite Shadow Fighter",
		"boss": "Shadow Commander",
		"hp_multiplier": 2.5,
		"reward_multiplier": 2.2,
		"enemy_asset_zone": 3,
		"background_asset_zone": 4,
	},
	{
		"name": "Burning Outpost",
		"level_start": 21,
		"level_end": 25,
		"enemies": ["Ash Raider", "Flame Scout", "Cinder Guard"],
		"elite_enemy": "Elite Ash Raider",
		"boss": "Burning Outpost Chief",
		"hp_multiplier": 3.2,
		"reward_multiplier": 2.8,
		"enemy_asset_zone": 5,
		"background_asset_zone": 5,
	},
	{
		"name": "Scorched Outpost",
		"level_start": 26,
		"level_end": 30,
		"enemies": ["Scorched Raider", "Outpost Scout", "Ash Guard"],
		"elite_enemy": "Elite Scorched Raider",
		"boss": "Scorched Outpost Captain",
		"hp_multiplier": 3.6,
		"reward_multiplier": 3.1,
		"enemy_asset_zone": 5,
		"background_asset_zone": 5,
	},
	{
		"name": "Old Training Grounds",
		"level_start": 31,
		"level_end": 35,
		"enemies": ["Rogue Ninja", "Novice Bandit", "Training Outcast"],
		"elite_enemy": "Elite Rogue Ninja",
		"boss": "Old Grounds Champion",
		"hp_multiplier": 4.2,
		"reward_multiplier": 3.6,
		"enemy_asset_zone": 1,
		"background_asset_zone": 1,
	},
	{
		"name": "Mist River",
		"level_start": 36,
		"level_end": 40,
		"enemies": ["Mist Rogue", "River Ambusher", "Fog Archer"],
		"elite_enemy": "Elite Mist Rogue",
		"boss": "Mist River Lord",
		"hp_multiplier": 5.1,
		"reward_multiplier": 4.3,
		"enemy_asset_zone": 8,
		"background_asset_zone": 8,
	},
	{
		"name": "Flooded Shrine",
		"level_start": 41,
		"level_end": 45,
		"enemies": ["Mist Rogue", "River Ambusher", "Fog Archer"],
		"elite_enemy": "Elite Mist Rogue",
		"boss": "Flooded Shrine Keeper",
		"hp_multiplier": 6.3,
		"reward_multiplier": 5.2,
		"enemy_asset_zone": 8,
		"background_asset_zone": 8,
	},
	{
		"name": "Thunder Ridge",
		"level_start": 46,
		"level_end": 50,
		"enemies": ["Thunder Bandit", "Storm Scout", "Ridge Spearman"],
		"elite_enemy": "Elite Thunder Bandit",
		"boss": "Thunder Ridge General",
		"hp_multiplier": 7.7,
		"reward_multiplier": 6.2,
		"enemy_asset_zone": 10,
		"background_asset_zone": 10,
	},
	{
		"name": "Iron Fortress",
		"level_start": 51,
		"level_end": 55,
		"enemies": ["Iron Guard", "Fortress Spearman", "Steel Watcher"],
		"elite_enemy": "Elite Iron Guard",
		"boss": "Iron Fortress Commander",
		"hp_multiplier": 9.3,
		"reward_multiplier": 7.4,
		"enemy_asset_zone": 11,
		"background_asset_zone": 11,
	},
	{
		"name": "Broken Fortress",
		"level_start": 56,
		"level_end": 60,
		"enemies": ["Iron Guard", "Fortress Spearman", "Steel Watcher"],
		"elite_enemy": "Elite Iron Guard",
		"boss": "Broken Fortress Tyrant",
		"hp_multiplier": 11.1,
		"reward_multiplier": 8.7,
		"enemy_asset_zone": 11,
		"background_asset_zone": 11,
	},
	{
		"name": "Training Ruins",
		"level_start": 61,
		"level_end": 65,
		"enemies": ["Rogue Ninja", "Novice Bandit", "Training Outcast"],
		"elite_enemy": "Elite Rogue Ninja",
		"boss": "Ruined Dojo Master",
		"hp_multiplier": 13.1,
		"reward_multiplier": 10.1,
		"enemy_asset_zone": 1,
		"background_asset_zone": 1,
	},
	{
		"name": "Ancient Training Yard",
		"level_start": 66,
		"level_end": 70,
		"enemies": ["Rogue Ninja", "Novice Bandit", "Training Outcast"],
		"elite_enemy": "Elite Rogue Ninja",
		"boss": "Ancient Yard Master",
		"hp_multiplier": 15.3,
		"reward_multiplier": 11.7,
		"enemy_asset_zone": 1,
		"background_asset_zone": 1,
	},
	{
		"name": "Hidden Waterfall",
		"level_start": 71,
		"level_end": 75,
		"enemies": ["Mist Rogue", "River Ambusher", "Fog Archer"],
		"elite_enemy": "Elite Mist Rogue",
		"boss": "Hidden Waterfall Sage",
		"hp_multiplier": 17.7,
		"reward_multiplier": 13.4,
		"enemy_asset_zone": 8,
		"background_asset_zone": 8,
	},
	{
		"name": "Desert Camp",
		"level_start": 76,
		"level_end": 80,
		"enemies": ["Desert Rogue", "Sand Raider", "Dune Guard"],
		"elite_enemy": "Elite Desert Rogue",
		"boss": "Desert Camp Warlord",
		"hp_multiplier": 20.3,
		"reward_multiplier": 15.2,
		"enemy_asset_zone": 16,
		"background_asset_zone": 16,
	},
	{
		"name": "Snow Pass",
		"level_start": 81,
		"level_end": 85,
		"enemies": ["Snow Assassin", "Frost Scout", "Ice Guard"],
		"elite_enemy": "Elite Snow Assassin",
		"boss": "Snow Pass Captain",
		"hp_multiplier": 23.1,
		"reward_multiplier": 17.1,
		"enemy_asset_zone": 17,
		"background_asset_zone": 17,
	},
	{
		"name": "Frozen Village",
		"level_start": 86,
		"level_end": 90,
		"enemies": ["Snow Assassin", "Frost Scout", "Ice Guard"],
		"elite_enemy": "Elite Snow Assassin",
		"boss": "Frozen Village Elder",
		"hp_multiplier": 26.1,
		"reward_multiplier": 19.1,
		"enemy_asset_zone": 17,
		"background_asset_zone": 17,
	},
	{
		"name": "Ice Shrine",
		"level_start": 91,
		"level_end": 95,
		"enemies": ["Snow Assassin", "Frost Scout", "Ice Guard"],
		"elite_enemy": "Elite Snow Assassin",
		"boss": "Ice Shrine Guardian",
		"hp_multiplier": 29.3,
		"reward_multiplier": 21.2,
		"enemy_asset_zone": 17,
		"background_asset_zone": 17,
	},
	{
		"name": "Dark Temple",
		"level_start": 96,
		"level_end": 100,
		"enemies": ["Temple Shade", "Dark Monk", "Cursed Guard"],
		"elite_enemy": "Elite Temple Shade",
		"boss": "Dark Temple Overlord",
		"hp_multiplier": 32.7,
		"reward_multiplier": 23.4,
		"enemy_asset_zone": 20,
		"background_asset_zone": 20,
	},
	{
		"name": "Storm Summit",
		"level_start": 101,
		"level_end": 105,
		"enemies": ["Thunder Bandit", "Storm Scout", "Ridge Spearman"],
		"elite_enemy": "Elite Thunder Bandit",
		"boss": "Storm Summit Master",
		"hp_multiplier": 36.3,
		"reward_multiplier": 25.7,
		"enemy_asset_zone": 10,
		"background_asset_zone": 10,
	},
]


const TOTAL_ZONE_LEVELS: int = LEVELS_PER_ZONE * 21


static func get_zone_count() -> int:
	return ZONE_DATA.size()


static func get_cycle_level_for_level(level: int) -> int:
	var safe_level: int = maxi(level, 1)
	return ((safe_level - 1) % TOTAL_ZONE_LEVELS) + 1


static func get_cycle_index_for_level(level: int) -> int:
	var cycle_level: int = get_cycle_level_for_level(level)
	return int((cycle_level - 1) / LEVELS_PER_ZONE)


static func get_zone_index_for_level(level: int) -> int:
	return get_cycle_index_for_level(level)


static func get_zone_data_for_level(level: int) -> Dictionary:
	return ZONE_DATA[get_zone_index_for_level(level)]


static func get_zone_number_for_level(level: int) -> int:
	return get_zone_index_for_level(level) + 1


static func get_enemy_asset_zone_number_for_level(level: int) -> int:
	var zone: Dictionary = get_zone_data_for_level(level)
	if zone.has("enemy_asset_zone"):
		return clampi(int(zone.enemy_asset_zone), 1, ZONE_DATA.size())
	return get_zone_number_for_level(level)


static func get_background_asset_zone_number_for_level(level: int) -> int:
	var zone: Dictionary = get_zone_data_for_level(level)
	if zone.has("background_asset_zone"):
		return clampi(int(zone.background_asset_zone), 1, ZONE_DATA.size())
	return get_zone_number_for_level(level)


static func get_enemy_asset_zone_index_for_level(level: int) -> int:
	return get_enemy_asset_zone_number_for_level(level) - 1


static func get_background_asset_zone_index_for_level(level: int) -> int:
	return get_background_asset_zone_number_for_level(level) - 1


static func get_name_key(zone_index: int) -> String:
	return "zone.%02d.name" % (zone_index + 1)


static func get_boss_key(zone_index: int) -> String:
	return "zone.%02d.boss" % (zone_index + 1)


static func get_name_key_for_level(level: int) -> String:
	return get_name_key(get_zone_index_for_level(level))
