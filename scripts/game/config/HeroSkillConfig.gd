class_name HeroSkillConfig
extends RefCounted

const SKILL_DEFINITIONS: Array = [
	{"id": "hero_click_damage_1", "owner_type": "hero", "ability_id": "", "skill_level": 1, "unlock_character_level": 10, "name": "Hero Strike I", "description": "+100% Click Damage", "bonus_type": "click_damage", "bonus_value": 1.00},
	{"id": "hero_partner_dps_1", "owner_type": "hero", "ability_id": "", "skill_level": 2, "unlock_character_level": 25, "name": "Hero Command I", "description": "+100% Partner DPS", "bonus_type": "partner_dps", "bonus_value": 1.00},
	{"id": "hero_gold_1", "owner_type": "hero", "ability_id": "", "skill_level": 3, "unlock_character_level": 50, "name": "Treasure Sense I", "description": "+25% Gold Gain", "bonus_type": "gold", "bonus_value": 0.25},
	{"id": "hero_gold_2", "owner_type": "hero", "ability_id": "", "skill_level": 4, "unlock_character_level": 100, "name": "Treasure Sense II", "description": "+25% Gold Gain", "bonus_type": "gold", "bonus_value": 0.25},
	{"id": "hero_gold_3", "owner_type": "hero", "ability_id": "", "skill_level": 5, "unlock_character_level": 250, "name": "Treasure Sense III", "description": "+50% Gold Gain", "bonus_type": "gold", "bonus_value": 0.50},
]


static func get_all() -> Array:
	return SKILL_DEFINITIONS


static func get_by_id(skill_id: String) -> Dictionary:
	for skill: Dictionary in SKILL_DEFINITIONS:
		if String(skill.get("id", "")) == skill_id:
			return skill
	return {}
