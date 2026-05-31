class_name ZoneConfig
extends RefCounted

const ZONE_DATA: Array = [
	{
		"name": "Training Grounds",
		"level_start": 1,
		"level_end": 10,
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
		"level_start": 11,
		"level_end": 20,
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
		"level_start": 21,
		"level_end": 30,
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
		"level_start": 31,
		"level_end": 40,
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
		"level_start": 41,
		"level_end": 50,
		"enemies": ["Ash Raider", "Flame Scout", "Cinder Guard"],
		"elite_enemy": "Elite Ash Raider",
		"boss": "Burning Outpost Chief",
		"hp_multiplier": 3.2,
		"reward_multiplier": 2.8,
		"enemy_asset_zone": 5,
		"background_asset_zone": 5,
	},
	{
		"name": "Old Training Grounds",
		"level_start": 51,
		"level_end": 60,
		"enemies": ["Rogue Ninja", "Novice Bandit", "Training Outcast"],
		"elite_enemy": "Elite Rogue Ninja",
		"boss": "Old Grounds Champion",
		"hp_multiplier": 4.0,
		"reward_multiplier": 3.5,
		"enemy_asset_zone": 1,
		"background_asset_zone": 1,
	},
	{
		"name": "Mist River",
		"level_start": 61,
		"level_end": 70,
		"enemies": ["Mist Rogue", "River Ambusher", "Fog Archer"],
		"elite_enemy": "Elite Mist Rogue",
		"boss": "Mist River Lord",
		"hp_multiplier": 5.0,
		"reward_multiplier": 4.3,
		"enemy_asset_zone": 7,
		"background_asset_zone": 7,
	},
	{
		"name": "Flooded Shrine",
		"level_start": 71,
		"level_end": 80,
		"enemies": ["Mist Rogue", "River Ambusher", "Fog Archer"],
		"elite_enemy": "Elite Mist Rogue",
		"boss": "Flooded Shrine Keeper",
		"hp_multiplier": 6.2,
		"reward_multiplier": 5.2,
		"enemy_asset_zone": 7,
		"background_asset_zone": 7,
	},
	{
		"name": "Thunder Ridge",
		"level_start": 81,
		"level_end": 90,
		"enemies": ["Thunder Bandit", "Storm Scout", "Ridge Spearman"],
		"elite_enemy": "Elite Thunder Bandit",
		"boss": "Thunder Ridge General",
		"hp_multiplier": 7.6,
		"reward_multiplier": 6.2,
		"enemy_asset_zone": 9,
		"background_asset_zone": 9,
	},
	{
		"name": "Iron Fortress",
		"level_start": 91,
		"level_end": 100,
		"enemies": ["Iron Guard", "Fortress Spearman", "Steel Watcher"],
		"elite_enemy": "Elite Iron Guard",
		"boss": "Iron Fortress Commander",
		"hp_multiplier": 9.2,
		"reward_multiplier": 7.4,
		"enemy_asset_zone": 10,
		"background_asset_zone": 10,
	},
	{
		"name": "Broken Fortress",
		"level_start": 101,
		"level_end": 110,
		"enemies": ["Iron Guard", "Fortress Spearman", "Steel Watcher"],
		"elite_enemy": "Elite Iron Guard",
		"boss": "Broken Fortress Tyrant",
		"hp_multiplier": 11.0,
		"reward_multiplier": 8.7,
		"enemy_asset_zone": 10,
		"background_asset_zone": 10,
	},
	{
		"name": "Training Ruins",
		"level_start": 111,
		"level_end": 120,
		"enemies": ["Rogue Ninja", "Novice Bandit", "Training Outcast"],
		"elite_enemy": "Elite Rogue Ninja",
		"boss": "Ruined Dojo Master",
		"hp_multiplier": 13.0,
		"reward_multiplier": 10.1,
		"enemy_asset_zone": 1,
		"background_asset_zone": 1,
	},
	{
		"name": "Ancient Training Yard",
		"level_start": 121,
		"level_end": 130,
		"enemies": ["Rogue Ninja", "Novice Bandit", "Training Outcast"],
		"elite_enemy": "Elite Rogue Ninja",
		"boss": "Ancient Yard Master",
		"hp_multiplier": 15.2,
		"reward_multiplier": 11.7,
		"enemy_asset_zone": 1,
		"background_asset_zone": 1,
	},
	{
		"name": "Hidden Waterfall",
		"level_start": 131,
		"level_end": 140,
		"enemies": ["Mist Rogue", "River Ambusher", "Fog Archer"],
		"elite_enemy": "Elite Mist Rogue",
		"boss": "Hidden Waterfall Sage",
		"hp_multiplier": 17.6,
		"reward_multiplier": 13.4,
		"enemy_asset_zone": 7,
		"background_asset_zone": 7,
	},
	{
		"name": "Desert Camp",
		"level_start": 141,
		"level_end": 150,
		"enemies": ["Desert Rogue", "Sand Raider", "Dune Guard"],
		"elite_enemy": "Elite Desert Rogue",
		"boss": "Desert Camp Warlord",
		"hp_multiplier": 20.2,
		"reward_multiplier": 15.2,
		"enemy_asset_zone": 15,
		"background_asset_zone": 15,
	},
	{
		"name": "Snow Pass",
		"level_start": 151,
		"level_end": 160,
		"enemies": ["Snow Assassin", "Frost Scout", "Ice Guard"],
		"elite_enemy": "Elite Snow Assassin",
		"boss": "Snow Pass Captain",
		"hp_multiplier": 23.0,
		"reward_multiplier": 17.1,
		"enemy_asset_zone": 16,
		"background_asset_zone": 16,
	},
	{
		"name": "Frozen Village",
		"level_start": 161,
		"level_end": 170,
		"enemies": ["Snow Assassin", "Frost Scout", "Ice Guard"],
		"elite_enemy": "Elite Snow Assassin",
		"boss": "Frozen Village Elder",
		"hp_multiplier": 26.0,
		"reward_multiplier": 19.1,
		"enemy_asset_zone": 16,
		"background_asset_zone": 16,
	},
	{
		"name": "Ice Shrine",
		"level_start": 171,
		"level_end": 180,
		"enemies": ["Snow Assassin", "Frost Scout", "Ice Guard"],
		"elite_enemy": "Elite Snow Assassin",
		"boss": "Ice Shrine Guardian",
		"hp_multiplier": 29.2,
		"reward_multiplier": 21.2,
		"enemy_asset_zone": 16,
		"background_asset_zone": 16,
	},
	{
		"name": "Dark Temple",
		"level_start": 181,
		"level_end": 190,
		"enemies": ["Temple Shade", "Dark Monk", "Cursed Guard"],
		"elite_enemy": "Elite Temple Shade",
		"boss": "Dark Temple Overlord",
		"hp_multiplier": 32.6,
		"reward_multiplier": 23.4,
		"enemy_asset_zone": 19,
		"background_asset_zone": 19,
	},
	{
		"name": "Storm Summit",
		"level_start": 191,
		"level_end": 200,
		"enemies": ["Thunder Bandit", "Storm Scout", "Ridge Spearman"],
		"elite_enemy": "Elite Thunder Bandit",
		"boss": "Storm Summit Master",
		"hp_multiplier": 36.2,
		"reward_multiplier": 25.7,
		"enemy_asset_zone": 9,
		"background_asset_zone": 9,
	},
]


static func get_zone_count() -> int:
	return ZONE_DATA.size()


static func get_zone_index_for_level(level: int) -> int:
	for i in range(ZONE_DATA.size()):
		if level <= int(ZONE_DATA[i].get("level_end", 0)):
			return i
	return ZONE_DATA.size() - 1


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
