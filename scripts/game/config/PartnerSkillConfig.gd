class_name PartnerSkillConfig
extends RefCounted

const SKILL_DEFINITIONS: Array = [
	# Partner 1 (index 0)
	{"id": "p0_s1", "partner_index": 0, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p0_s2", "partner_index": 0, "skill_level": 2, "unlock_count": 25, "name": "DPS Mastery II", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p0_s3", "partner_index": 0, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p0_s4", "partner_index": 0, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p0_s5", "partner_index": 0, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 2 (index 1)
	{"id": "p1_s1", "partner_index": 1, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p1_s2", "partner_index": 1, "skill_level": 2, "unlock_count": 25, "name": "DPS Mastery II", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p1_s3", "partner_index": 1, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p1_s4", "partner_index": 1, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p1_s5", "partner_index": 1, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 3 (index 2)
	{"id": "p2_s1", "partner_index": 2, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p2_s2", "partner_index": 2, "skill_level": 2, "unlock_count": 25, "name": "DPS Mastery II", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p2_s3", "partner_index": 2, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p2_s4", "partner_index": 2, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p2_s5", "partner_index": 2, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 4 / Field Scout (index 3)
	{"id": "p3_s1", "partner_index": 3, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p3_s2", "partner_index": 3, "skill_level": 2, "unlock_count": 25, "name": "DPS Mastery II", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p3_s3", "partner_index": 3, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p3_s4", "partner_index": 3, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p3_s5", "partner_index": 3, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 5 / Spear Guard (index 4)
	{"id": "p4_s1", "partner_index": 4, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p4_s2", "partner_index": 4, "skill_level": 2, "unlock_count": 25, "name": "DPS Mastery II", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p4_s3", "partner_index": 4, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p4_s4", "partner_index": 4, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p4_s5", "partner_index": 4, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 6 / Iron Defender (index 5)
	{"id": "p5_s1", "partner_index": 5, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p5_s2", "partner_index": 5, "skill_level": 2, "unlock_count": 25, "name": "DPS Mastery II", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p5_s3", "partner_index": 5, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p5_s4", "partner_index": 5, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p5_s5", "partner_index": 5, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 7 / Battle Monk (index 6)
	{"id": "p6_s1", "partner_index": 6, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p6_s2", "partner_index": 6, "skill_level": 2, "unlock_count": 25, "name": "DPS Mastery II", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p6_s3", "partner_index": 6, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p6_s4", "partner_index": 6, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p6_s5", "partner_index": 6, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 8 / Elite Samurai (index 7)
	{"id": "p7_s1", "partner_index": 7, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p7_s2", "partner_index": 7, "skill_level": 2, "unlock_count": 25, "name": "DPS Mastery II", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p7_s3", "partner_index": 7, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p7_s4", "partner_index": 7, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p7_s5", "partner_index": 7, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 9 / Shadow Captain (index 8)
	{"id": "p8_s1", "partner_index": 8, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p8_s2", "partner_index": 8, "skill_level": 2, "unlock_count": 25, "name": "DPS Mastery II", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p8_s3", "partner_index": 8, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p8_s4", "partner_index": 8, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p8_s5", "partner_index": 8, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 10 / War Sage (index 9)
	{"id": "p9_s1", "partner_index": 9, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p9_s2", "partner_index": 9, "skill_level": 2, "unlock_count": 25, "name": "DPS Mastery II", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p9_s3", "partner_index": 9, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p9_s4", "partner_index": 9, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p9_s5", "partner_index": 9, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 11 / Beast Tamer (index 10)
	{"id": "p10_s1", "partner_index": 10, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p10_s2", "partner_index": 10, "skill_level": 2, "unlock_count": 25, "name": "DPS Mastery II", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p10_s3", "partner_index": 10, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p10_s4", "partner_index": 10, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p10_s5", "partner_index": 10, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 12 / Blade Master (index 11)
	{"id": "p11_s1", "partner_index": 11, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p11_s2", "partner_index": 11, "skill_level": 2, "unlock_count": 25, "name": "DPS Mastery II", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p11_s3", "partner_index": 11, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p11_s4", "partner_index": 11, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p11_s5", "partner_index": 11, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 13 / Legendary Commander (index 12)
	{"id": "p12_s1", "partner_index": 12, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p12_s2", "partner_index": 12, "skill_level": 2, "unlock_count": 25, "name": "DPS Mastery II", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p12_s3", "partner_index": 12, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p12_s4", "partner_index": 12, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p12_s5", "partner_index": 12, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
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
