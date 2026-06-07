class_name AbilityConfig
extends RefCounted

const ABILITY_IDS: Array = ["autoclick", "gold_bonus", "focus_burst", "rally"]

const SKILL_DEFINITIONS: Array = [
	{"id": "autoclick_rank_1", "owner_type": "ability", "ability_id": "autoclick", "skill_level": 1, "unlock_character_level": 15, "name": "Autoclick I", "description": "+15% rate, +2s duration", "bonus_type": "autoclick_rank", "bonus_value": 1.0},
	{"id": "autoclick_rank_2", "owner_type": "ability", "ability_id": "autoclick", "skill_level": 2, "unlock_character_level": 30, "name": "Autoclick II", "description": "+15% rate, +2s duration", "bonus_type": "autoclick_rank", "bonus_value": 1.0},
	{"id": "autoclick_rank_3", "owner_type": "ability", "ability_id": "autoclick", "skill_level": 3, "unlock_character_level": 60, "name": "Autoclick III", "description": "+15% rate, +2s duration", "bonus_type": "autoclick_rank", "bonus_value": 1.0},
	{"id": "autoclick_rank_4", "owner_type": "ability", "ability_id": "autoclick", "skill_level": 4, "unlock_character_level": 100, "name": "Autoclick IV", "description": "+15% rate, +2s duration", "bonus_type": "autoclick_rank", "bonus_value": 1.0},
	{"id": "autoclick_rank_5", "owner_type": "ability", "ability_id": "autoclick", "skill_level": 5, "unlock_character_level": 150, "name": "Autoclick V", "description": "+15% rate, +2s duration", "bonus_type": "autoclick_rank", "bonus_value": 1.0},
	{"id": "gold_bonus_rank_1", "owner_type": "ability", "ability_id": "gold_bonus", "skill_level": 1, "unlock_character_level": 30, "name": "Gold Bonus I", "description": "Improves to x2.25 gold", "bonus_type": "gold_bonus_rank", "bonus_value": 1.0},
	{"id": "gold_bonus_rank_2", "owner_type": "ability", "ability_id": "gold_bonus", "skill_level": 2, "unlock_character_level": 60, "name": "Gold Bonus II", "description": "Improves to x2.50 gold", "bonus_type": "gold_bonus_rank", "bonus_value": 1.0},
	{"id": "gold_bonus_rank_3", "owner_type": "ability", "ability_id": "gold_bonus", "skill_level": 3, "unlock_character_level": 100, "name": "Gold Bonus III", "description": "Improves to x2.75 gold", "bonus_type": "gold_bonus_rank", "bonus_value": 1.0},
	{"id": "gold_bonus_rank_4", "owner_type": "ability", "ability_id": "gold_bonus", "skill_level": 4, "unlock_character_level": 150, "name": "Gold Bonus IV", "description": "Improves to x3.00 gold", "bonus_type": "gold_bonus_rank", "bonus_value": 1.0},
	{"id": "gold_bonus_rank_5", "owner_type": "ability", "ability_id": "gold_bonus", "skill_level": 5, "unlock_character_level": 250, "name": "Gold Bonus V", "description": "Improves to x3.25 gold", "bonus_type": "gold_bonus_rank", "bonus_value": 1.0},
	{"id": "focus_burst_rank_1", "owner_type": "ability", "ability_id": "focus_burst", "skill_level": 1, "unlock_character_level": 60, "name": "Focus Burst I", "description": "Improves to x2.25 damage", "bonus_type": "focus_burst_rank", "bonus_value": 1.0},
	{"id": "focus_burst_rank_2", "owner_type": "ability", "ability_id": "focus_burst", "skill_level": 2, "unlock_character_level": 100, "name": "Focus Burst II", "description": "Improves to x2.50 damage", "bonus_type": "focus_burst_rank", "bonus_value": 1.0},
	{"id": "focus_burst_rank_3", "owner_type": "ability", "ability_id": "focus_burst", "skill_level": 3, "unlock_character_level": 150, "name": "Focus Burst III", "description": "Improves to x2.75 damage", "bonus_type": "focus_burst_rank", "bonus_value": 1.0},
	{"id": "focus_burst_rank_4", "owner_type": "ability", "ability_id": "focus_burst", "skill_level": 4, "unlock_character_level": 250, "name": "Focus Burst IV", "description": "Improves to x3.00 damage", "bonus_type": "focus_burst_rank", "bonus_value": 1.0},
	{"id": "focus_burst_rank_5", "owner_type": "ability", "ability_id": "focus_burst", "skill_level": 5, "unlock_character_level": 500, "name": "Focus Burst V", "description": "Improves to x3.25 damage", "bonus_type": "focus_burst_rank", "bonus_value": 1.0},
	{"id": "rally_rank_1", "owner_type": "ability", "ability_id": "rally", "skill_level": 1, "unlock_character_level": 80, "name": "Rally I", "description": "Improves to x2.25 partner DPS", "bonus_type": "rally_rank", "bonus_value": 1.0},
	{"id": "rally_rank_2", "owner_type": "ability", "ability_id": "rally", "skill_level": 2, "unlock_character_level": 125, "name": "Rally II", "description": "Improves to x2.50 partner DPS", "bonus_type": "rally_rank", "bonus_value": 1.0},
	{"id": "rally_rank_3", "owner_type": "ability", "ability_id": "rally", "skill_level": 3, "unlock_character_level": 200, "name": "Rally III", "description": "Improves to x2.75 partner DPS", "bonus_type": "rally_rank", "bonus_value": 1.0},
	{"id": "rally_rank_4", "owner_type": "ability", "ability_id": "rally", "skill_level": 4, "unlock_character_level": 350, "name": "Rally IV", "description": "Improves to x3.00 partner DPS", "bonus_type": "rally_rank", "bonus_value": 1.0},
	{"id": "rally_rank_5", "owner_type": "ability", "ability_id": "rally", "skill_level": 5, "unlock_character_level": 500, "name": "Rally V", "description": "Improves to x3.25 partner DPS", "bonus_type": "rally_rank", "bonus_value": 1.0},
]


static func get_ability_ids() -> Array:
	return ABILITY_IDS


static func get_ability_skill_definitions() -> Array:
	return SKILL_DEFINITIONS


static func get_ability_skill_by_id(skill_id: String) -> Dictionary:
	for skill: Dictionary in SKILL_DEFINITIONS:
		if String(skill.get("id", "")) == skill_id:
			return skill
	return {}


static func get_unlock_level(ability_id: String) -> int:
	match ability_id:
		"autoclick": return BalanceConfig.AUTOCLICK_UNLOCK_LEVEL
		"gold_bonus": return BalanceConfig.GOLD_BONUS_UNLOCK_LEVEL
		"focus_burst": return BalanceConfig.FOCUS_BURST_UNLOCK_LEVEL
		"rally": return BalanceConfig.RALLY_UNLOCK_LEVEL
	return 0


static func get_purchase_cost(ability_id: String) -> int:
	match ability_id:
		"autoclick": return BalanceConfig.AUTOCLICK_PURCHASE_COST
		"gold_bonus": return BalanceConfig.GOLD_BONUS_PURCHASE_COST
		"focus_burst": return BalanceConfig.FOCUS_BURST_PURCHASE_COST
		"rally": return BalanceConfig.RALLY_PURCHASE_COST
	return 0


static func get_effect_key(ability_id: String) -> String:
	return "ability.%s.effect" % ability_id


static func get_effect_next_key(ability_id: String) -> String:
	return "ability.%s.effect_next" % ability_id


static func get_duration_key(ability_id: String) -> String:
	return "ability.%s.duration" % ability_id
