class_name PartnerSkillConfig
extends RefCounted

# Partner DPS tiers are prototype balance values tuned around milestone x2 spikes.
const SKILL_DEFINITIONS: Array = [
	# Partner 1 (index 0) — Click Damage
	{"id": "p0_s1", "partner_index": 0, "skill_level": 1, "unlock_count": 10, "name": "Click Training I", "description": "+20% Click Damage", "bonus_type": "click_damage", "bonus_value": 0.20},
	{"id": "p0_s2", "partner_index": 0, "skill_level": 2, "unlock_count": 25, "name": "Click Training II", "description": "+25% Click Damage", "bonus_type": "click_damage", "bonus_value": 0.25},
	{"id": "p0_s3", "partner_index": 0, "skill_level": 3, "unlock_count": 50, "name": "Click Training III", "description": "+50% Click Damage", "bonus_type": "click_damage", "bonus_value": 0.50},
	{"id": "p0_s4", "partner_index": 0, "skill_level": 4, "unlock_count": 100, "name": "Click Training IV", "description": "+100% Click Damage", "bonus_type": "click_damage", "bonus_value": 1.00},
	{"id": "p0_s5", "partner_index": 0, "skill_level": 5, "unlock_count": 250, "name": "Click Training V", "description": "+100% Click Damage", "bonus_type": "click_damage", "bonus_value": 1.00},
	# Partner 2 (index 1) — Own Partner DPS
	{"id": "p1_s1", "partner_index": 1, "skill_level": 1, "unlock_count": 10, "name": "Personal Mastery I", "description": "+50% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 0.50},
	{"id": "p1_s2", "partner_index": 1, "skill_level": 2, "unlock_count": 25, "name": "Personal Mastery II", "description": "+50% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 0.50},
	{"id": "p1_s3", "partner_index": 1, "skill_level": 3, "unlock_count": 50, "name": "Personal Mastery III", "description": "+50% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 0.50},
	{"id": "p1_s4", "partner_index": 1, "skill_level": 4, "unlock_count": 100, "name": "Personal Mastery IV", "description": "+100% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.00},
	{"id": "p1_s5", "partner_index": 1, "skill_level": 5, "unlock_count": 250, "name": "Personal Mastery V", "description": "+100% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.00},
	# Partner 3 (index 2) — Own Partner DPS
	{"id": "p2_s1", "partner_index": 2, "skill_level": 1, "unlock_count": 10, "name": "Personal Mastery I", "description": "+50% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 0.50},
	{"id": "p2_s2", "partner_index": 2, "skill_level": 2, "unlock_count": 25, "name": "Personal Mastery II", "description": "+50% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 0.50},
	{"id": "p2_s3", "partner_index": 2, "skill_level": 3, "unlock_count": 50, "name": "Personal Mastery III", "description": "+50% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 0.50},
	{"id": "p2_s4", "partner_index": 2, "skill_level": 4, "unlock_count": 100, "name": "Personal Mastery IV", "description": "+100% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.00},
	{"id": "p2_s5", "partner_index": 2, "skill_level": 5, "unlock_count": 250, "name": "Personal Mastery V", "description": "+100% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.00},
	# Field Scout (index 3) — Click Damage
	{"id": "p3_s1", "partner_index": 3, "skill_level": 1, "unlock_count": 10, "name": "Click Training I", "description": "+20% Click Damage", "bonus_type": "click_damage", "bonus_value": 0.20},
	{"id": "p3_s2", "partner_index": 3, "skill_level": 2, "unlock_count": 25, "name": "Click Training II", "description": "+25% Click Damage", "bonus_type": "click_damage", "bonus_value": 0.25},
	{"id": "p3_s3", "partner_index": 3, "skill_level": 3, "unlock_count": 50, "name": "Click Training III", "description": "+50% Click Damage", "bonus_type": "click_damage", "bonus_value": 0.50},
	{"id": "p3_s4", "partner_index": 3, "skill_level": 4, "unlock_count": 100, "name": "Click Training IV", "description": "+100% Click Damage", "bonus_type": "click_damage", "bonus_value": 1.00},
	{"id": "p3_s5", "partner_index": 3, "skill_level": 5, "unlock_count": 250, "name": "Click Training V", "description": "+100% Click Damage", "bonus_type": "click_damage", "bonus_value": 1.00},
	# Spear Guard (index 4) — Total Partner DPS
	{"id": "p4_s1", "partner_index": 4, "skill_level": 1, "unlock_count": 10, "name": "Team Command I", "description": "+25% Total Partner DPS", "bonus_type": "partner_dps", "bonus_value": 0.25},
	{"id": "p4_s2", "partner_index": 4, "skill_level": 2, "unlock_count": 25, "name": "Team Command II", "description": "+40% Total Partner DPS", "bonus_type": "partner_dps", "bonus_value": 0.40},
	{"id": "p4_s3", "partner_index": 4, "skill_level": 3, "unlock_count": 50, "name": "Team Command III", "description": "+60% Total Partner DPS", "bonus_type": "partner_dps", "bonus_value": 0.60},
	{"id": "p4_s4", "partner_index": 4, "skill_level": 4, "unlock_count": 100, "name": "Team Command IV", "description": "+60% Total Partner DPS", "bonus_type": "partner_dps", "bonus_value": 0.60},
	{"id": "p4_s5", "partner_index": 4, "skill_level": 5, "unlock_count": 250, "name": "Team Command V", "description": "+100% Total Partner DPS", "bonus_type": "partner_dps", "bonus_value": 1.00},
	# Iron Defender (index 5) — Gold Gain
	{"id": "p5_s1", "partner_index": 5, "skill_level": 1, "unlock_count": 10, "name": "Gold Sense I", "description": "+25% Gold Gain", "bonus_type": "gold", "bonus_value": 0.25},
	{"id": "p5_s2", "partner_index": 5, "skill_level": 2, "unlock_count": 25, "name": "Gold Sense II", "description": "+50% Gold Gain", "bonus_type": "gold", "bonus_value": 0.50},
	{"id": "p5_s3", "partner_index": 5, "skill_level": 3, "unlock_count": 50, "name": "Gold Sense III", "description": "+50% Gold Gain", "bonus_type": "gold", "bonus_value": 0.50},
	{"id": "p5_s4", "partner_index": 5, "skill_level": 4, "unlock_count": 100, "name": "Gold Sense IV", "description": "+50% Gold Gain", "bonus_type": "gold", "bonus_value": 0.50},
	{"id": "p5_s5", "partner_index": 5, "skill_level": 5, "unlock_count": 250, "name": "Gold Sense V", "description": "+50% Gold Gain", "bonus_type": "gold", "bonus_value": 0.50},
	# Battle Monk (index 6) — Own Partner DPS
	{"id": "p6_s1", "partner_index": 6, "skill_level": 1, "unlock_count": 10, "name": "Personal Mastery I", "description": "+50% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 0.50},
	{"id": "p6_s2", "partner_index": 6, "skill_level": 2, "unlock_count": 25, "name": "Personal Mastery II", "description": "+50% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 0.50},
	{"id": "p6_s3", "partner_index": 6, "skill_level": 3, "unlock_count": 50, "name": "Personal Mastery III", "description": "+50% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 0.50},
	{"id": "p6_s4", "partner_index": 6, "skill_level": 4, "unlock_count": 100, "name": "Personal Mastery IV", "description": "+100% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.00},
	{"id": "p6_s5", "partner_index": 6, "skill_level": 5, "unlock_count": 250, "name": "Personal Mastery V", "description": "+100% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.00},
	# Elite Samurai (index 7) — Own Partner DPS
	{"id": "p7_s1", "partner_index": 7, "skill_level": 1, "unlock_count": 10, "name": "Personal Mastery I", "description": "+50% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 0.50},
	{"id": "p7_s2", "partner_index": 7, "skill_level": 2, "unlock_count": 25, "name": "Personal Mastery II", "description": "+50% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 0.50},
	{"id": "p7_s3", "partner_index": 7, "skill_level": 3, "unlock_count": 50, "name": "Personal Mastery III", "description": "+50% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 0.50},
	{"id": "p7_s4", "partner_index": 7, "skill_level": 4, "unlock_count": 100, "name": "Personal Mastery IV", "description": "+100% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.00},
	{"id": "p7_s5", "partner_index": 7, "skill_level": 5, "unlock_count": 250, "name": "Personal Mastery V", "description": "+100% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.00},
	# Shadow Captain (index 8) — Own Partner DPS
	{"id": "p8_s1", "partner_index": 8, "skill_level": 1, "unlock_count": 10, "name": "Personal Mastery I", "description": "+50% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 0.50},
	{"id": "p8_s2", "partner_index": 8, "skill_level": 2, "unlock_count": 25, "name": "Personal Mastery II", "description": "+50% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 0.50},
	{"id": "p8_s3", "partner_index": 8, "skill_level": 3, "unlock_count": 50, "name": "Personal Mastery III", "description": "+50% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 0.50},
	{"id": "p8_s4", "partner_index": 8, "skill_level": 4, "unlock_count": 100, "name": "Personal Mastery IV", "description": "+100% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.00},
	{"id": "p8_s5", "partner_index": 8, "skill_level": 5, "unlock_count": 250, "name": "Personal Mastery V", "description": "+100% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.00},
	# War Sage (index 9) — Own Partner DPS
	{"id": "p9_s1", "partner_index": 9, "skill_level": 1, "unlock_count": 10, "name": "Personal Mastery I", "description": "+50% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 0.50},
	{"id": "p9_s2", "partner_index": 9, "skill_level": 2, "unlock_count": 25, "name": "Personal Mastery II", "description": "+50% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 0.50},
	{"id": "p9_s3", "partner_index": 9, "skill_level": 3, "unlock_count": 50, "name": "Personal Mastery III", "description": "+50% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 0.50},
	{"id": "p9_s4", "partner_index": 9, "skill_level": 4, "unlock_count": 100, "name": "Personal Mastery IV", "description": "+100% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.00},
	{"id": "p9_s5", "partner_index": 9, "skill_level": 5, "unlock_count": 250, "name": "Personal Mastery V", "description": "+100% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.00},
	# Beast Tamer (index 10) — Own Partner DPS
	{"id": "p10_s1", "partner_index": 10, "skill_level": 1, "unlock_count": 10, "name": "Personal Mastery I", "description": "+50% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 0.50},
	{"id": "p10_s2", "partner_index": 10, "skill_level": 2, "unlock_count": 25, "name": "Personal Mastery II", "description": "+50% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 0.50},
	{"id": "p10_s3", "partner_index": 10, "skill_level": 3, "unlock_count": 50, "name": "Personal Mastery III", "description": "+50% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 0.50},
	{"id": "p10_s4", "partner_index": 10, "skill_level": 4, "unlock_count": 100, "name": "Personal Mastery IV", "description": "+100% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.00},
	{"id": "p10_s5", "partner_index": 10, "skill_level": 5, "unlock_count": 250, "name": "Personal Mastery V", "description": "+100% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.00},
	# Blade Master (index 11) — Own Partner DPS
	{"id": "p11_s1", "partner_index": 11, "skill_level": 1, "unlock_count": 10, "name": "Personal Mastery I", "description": "+50% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 0.50},
	{"id": "p11_s2", "partner_index": 11, "skill_level": 2, "unlock_count": 25, "name": "Personal Mastery II", "description": "+50% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 0.50},
	{"id": "p11_s3", "partner_index": 11, "skill_level": 3, "unlock_count": 50, "name": "Personal Mastery III", "description": "+50% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 0.50},
	{"id": "p11_s4", "partner_index": 11, "skill_level": 4, "unlock_count": 100, "name": "Personal Mastery IV", "description": "+100% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.00},
	{"id": "p11_s5", "partner_index": 11, "skill_level": 5, "unlock_count": 250, "name": "Personal Mastery V", "description": "+100% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.00},
	# Legendary Commander (index 12) — Own Partner DPS
	{"id": "p12_s1", "partner_index": 12, "skill_level": 1, "unlock_count": 10, "name": "Personal Mastery I", "description": "+50% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 0.50},
	{"id": "p12_s2", "partner_index": 12, "skill_level": 2, "unlock_count": 25, "name": "Personal Mastery II", "description": "+50% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 0.50},
	{"id": "p12_s3", "partner_index": 12, "skill_level": 3, "unlock_count": 50, "name": "Personal Mastery III", "description": "+50% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 0.50},
	{"id": "p12_s4", "partner_index": 12, "skill_level": 4, "unlock_count": 100, "name": "Personal Mastery IV", "description": "+100% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.00},
	{"id": "p12_s5", "partner_index": 12, "skill_level": 5, "unlock_count": 250, "name": "Personal Mastery V", "description": "+100% This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.00},
]


static func get_all() -> Array:
	return SKILL_DEFINITIONS


static func get_by_id(skill_id: String) -> Dictionary:
	for skill: Dictionary in SKILL_DEFINITIONS:
		if String(skill.get("id", "")) == skill_id:
			return skill
	return {}


static func get_for_partner(partner_index: int) -> Array:
	var result: Array = []
	for skill: Dictionary in SKILL_DEFINITIONS:
		if int(skill.get("partner_index", -1)) == partner_index:
			result.append(skill)
	return result
