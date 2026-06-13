class_name PartnerSkillConfig
extends RefCounted

const SKILL_DEFINITIONS: Array = [
	# Partner 1 (index 0)
	{"id": "p0_s1", "partner_index": 0, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p0_s2", "partner_index": 0, "skill_level": 2, "unlock_count": 25, "name": "Click Synergy", "description": "+0.7% Partner DPS as Click Damage", "bonus_type": "click_damage_from_partner_dps", "bonus_value": 0.007},
	{"id": "p0_s3", "partner_index": 0, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p0_s4", "partner_index": 0, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p0_s5", "partner_index": 0, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 2 (index 1)
	{"id": "p1_s1", "partner_index": 1, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p1_s2", "partner_index": 1, "skill_level": 2, "unlock_count": 25, "name": "Click Synergy", "description": "+0.7% Partner DPS as Click Damage", "bonus_type": "click_damage_from_partner_dps", "bonus_value": 0.007},
	{"id": "p1_s3", "partner_index": 1, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p1_s4", "partner_index": 1, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p1_s5", "partner_index": 1, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 3 (index 2)
	{"id": "p2_s1", "partner_index": 2, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p2_s2", "partner_index": 2, "skill_level": 2, "unlock_count": 25, "name": "Click Synergy", "description": "+0.7% Partner DPS as Click Damage", "bonus_type": "click_damage_from_partner_dps", "bonus_value": 0.007},
	{"id": "p2_s3", "partner_index": 2, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p2_s4", "partner_index": 2, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p2_s5", "partner_index": 2, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 4 / Field Scout (index 3)
	{"id": "p3_s1", "partner_index": 3, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p3_s2", "partner_index": 3, "skill_level": 2, "unlock_count": 25, "name": "Click Synergy", "description": "+0.7% Partner DPS as Click Damage", "bonus_type": "click_damage_from_partner_dps", "bonus_value": 0.007},
	{"id": "p3_s3", "partner_index": 3, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p3_s4", "partner_index": 3, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p3_s5", "partner_index": 3, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 5 / Spear Guard (index 4)
	{"id": "p4_s1", "partner_index": 4, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p4_s2", "partner_index": 4, "skill_level": 2, "unlock_count": 25, "name": "Click Synergy", "description": "+0.7% Partner DPS as Click Damage", "bonus_type": "click_damage_from_partner_dps", "bonus_value": 0.007},
	{"id": "p4_s3", "partner_index": 4, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p4_s4", "partner_index": 4, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p4_s5", "partner_index": 4, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 6 / Iron Defender (index 5)
	{"id": "p5_s1", "partner_index": 5, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p5_s2", "partner_index": 5, "skill_level": 2, "unlock_count": 25, "name": "Click Synergy", "description": "+0.7% Partner DPS as Click Damage", "bonus_type": "click_damage_from_partner_dps", "bonus_value": 0.007},
	{"id": "p5_s3", "partner_index": 5, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p5_s4", "partner_index": 5, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p5_s5", "partner_index": 5, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 7 / Battle Monk (index 6)
	{"id": "p6_s1", "partner_index": 6, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p6_s2", "partner_index": 6, "skill_level": 2, "unlock_count": 25, "name": "Click Synergy", "description": "+0.7% Partner DPS as Click Damage", "bonus_type": "click_damage_from_partner_dps", "bonus_value": 0.007},
	{"id": "p6_s3", "partner_index": 6, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p6_s4", "partner_index": 6, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p6_s5", "partner_index": 6, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 8 / Elite Samurai (index 7)
	{"id": "p7_s1", "partner_index": 7, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p7_s2", "partner_index": 7, "skill_level": 2, "unlock_count": 25, "name": "Click Synergy", "description": "+0.7% Partner DPS as Click Damage", "bonus_type": "click_damage_from_partner_dps", "bonus_value": 0.007},
	{"id": "p7_s3", "partner_index": 7, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p7_s4", "partner_index": 7, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p7_s5", "partner_index": 7, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 9 / Shadow Captain (index 8)
	{"id": "p8_s1", "partner_index": 8, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p8_s2", "partner_index": 8, "skill_level": 2, "unlock_count": 25, "name": "Click Synergy", "description": "+0.7% Partner DPS as Click Damage", "bonus_type": "click_damage_from_partner_dps", "bonus_value": 0.007},
	{"id": "p8_s3", "partner_index": 8, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p8_s4", "partner_index": 8, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p8_s5", "partner_index": 8, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 10 / War Sage (index 9)
	{"id": "p9_s1", "partner_index": 9, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p9_s2", "partner_index": 9, "skill_level": 2, "unlock_count": 25, "name": "Click Synergy", "description": "+0.7% Partner DPS as Click Damage", "bonus_type": "click_damage_from_partner_dps", "bonus_value": 0.007},
	{"id": "p9_s3", "partner_index": 9, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p9_s4", "partner_index": 9, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p9_s5", "partner_index": 9, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 11 / Beast Tamer (index 10)
	{"id": "p10_s1", "partner_index": 10, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p10_s2", "partner_index": 10, "skill_level": 2, "unlock_count": 25, "name": "Click Synergy", "description": "+0.7% Partner DPS as Click Damage", "bonus_type": "click_damage_from_partner_dps", "bonus_value": 0.007},
	{"id": "p10_s3", "partner_index": 10, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p10_s4", "partner_index": 10, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p10_s5", "partner_index": 10, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 12 / Blade Master (index 11)
	{"id": "p11_s1", "partner_index": 11, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p11_s2", "partner_index": 11, "skill_level": 2, "unlock_count": 25, "name": "Click Synergy", "description": "+0.7% Partner DPS as Click Damage", "bonus_type": "click_damage_from_partner_dps", "bonus_value": 0.007},
	{"id": "p11_s3", "partner_index": 11, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p11_s4", "partner_index": 11, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p11_s5", "partner_index": 11, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 13 / Legendary Commander (index 12)
	{"id": "p12_s1", "partner_index": 12, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p12_s2", "partner_index": 12, "skill_level": 2, "unlock_count": 25, "name": "Click Synergy", "description": "+0.7% Partner DPS as Click Damage", "bonus_type": "click_damage_from_partner_dps", "bonus_value": 0.007},
	{"id": "p12_s3", "partner_index": 12, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p12_s4", "partner_index": 12, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p12_s5", "partner_index": 12, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 14 / Silent Ronin (index 13)
	{"id": "p13_s1", "partner_index": 13, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p13_s2", "partner_index": 13, "skill_level": 2, "unlock_count": 25, "name": "Click Synergy", "description": "+0.7% Partner DPS as Click Damage", "bonus_type": "click_damage_from_partner_dps", "bonus_value": 0.007},
	{"id": "p13_s3", "partner_index": 13, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p13_s4", "partner_index": 13, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p13_s5", "partner_index": 13, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 15 / Chakra Archer (index 14)
	{"id": "p14_s1", "partner_index": 14, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p14_s2", "partner_index": 14, "skill_level": 2, "unlock_count": 25, "name": "Click Synergy", "description": "+0.7% Partner DPS as Click Damage", "bonus_type": "click_damage_from_partner_dps", "bonus_value": 0.007},
	{"id": "p14_s3", "partner_index": 14, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p14_s4", "partner_index": 14, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p14_s5", "partner_index": 14, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 16 / Sand Guardian (index 15)
	{"id": "p15_s1", "partner_index": 15, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p15_s2", "partner_index": 15, "skill_level": 2, "unlock_count": 25, "name": "Click Synergy", "description": "+0.7% Partner DPS as Click Damage", "bonus_type": "click_damage_from_partner_dps", "bonus_value": 0.007},
	{"id": "p15_s3", "partner_index": 15, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p15_s4", "partner_index": 15, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p15_s5", "partner_index": 15, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 17 / Mist Duelist (index 16)
	{"id": "p16_s1", "partner_index": 16, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p16_s2", "partner_index": 16, "skill_level": 2, "unlock_count": 25, "name": "Click Synergy", "description": "+0.7% Partner DPS as Click Damage", "bonus_type": "click_damage_from_partner_dps", "bonus_value": 0.007},
	{"id": "p16_s3", "partner_index": 16, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p16_s4", "partner_index": 16, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p16_s5", "partner_index": 16, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 18 / Lightning Striker (index 17)
	{"id": "p17_s1", "partner_index": 17, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p17_s2", "partner_index": 17, "skill_level": 2, "unlock_count": 25, "name": "Click Synergy", "description": "+0.7% Partner DPS as Click Damage", "bonus_type": "click_damage_from_partner_dps", "bonus_value": 0.007},
	{"id": "p17_s3", "partner_index": 17, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p17_s4", "partner_index": 17, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p17_s5", "partner_index": 17, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 19 / Puppet Tactician (index 18)
	{"id": "p18_s1", "partner_index": 18, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p18_s2", "partner_index": 18, "skill_level": 2, "unlock_count": 25, "name": "Click Synergy", "description": "+0.7% Partner DPS as Click Damage", "bonus_type": "click_damage_from_partner_dps", "bonus_value": 0.007},
	{"id": "p18_s3", "partner_index": 18, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p18_s4", "partner_index": 18, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p18_s5", "partner_index": 18, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 20 / Seal Specialist (index 19)
	{"id": "p19_s1", "partner_index": 19, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p19_s2", "partner_index": 19, "skill_level": 2, "unlock_count": 25, "name": "Click Synergy", "description": "+0.7% Partner DPS as Click Damage", "bonus_type": "click_damage_from_partner_dps", "bonus_value": 0.007},
	{"id": "p19_s3", "partner_index": 19, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p19_s4", "partner_index": 19, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p19_s5", "partner_index": 19, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 21 / Medical Ninja (index 20)
	{"id": "p20_s1", "partner_index": 20, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p20_s2", "partner_index": 20, "skill_level": 2, "unlock_count": 25, "name": "Click Synergy", "description": "+0.7% Partner DPS as Click Damage", "bonus_type": "click_damage_from_partner_dps", "bonus_value": 0.007},
	{"id": "p20_s3", "partner_index": 20, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p20_s4", "partner_index": 20, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p20_s5", "partner_index": 20, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 22 / Shadow Tracker (index 21)
	{"id": "p21_s1", "partner_index": 21, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p21_s2", "partner_index": 21, "skill_level": 2, "unlock_count": 25, "name": "Click Synergy", "description": "+0.7% Partner DPS as Click Damage", "bonus_type": "click_damage_from_partner_dps", "bonus_value": 0.007},
	{"id": "p21_s3", "partner_index": 21, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p21_s4", "partner_index": 21, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p21_s5", "partner_index": 21, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 23 / Summon Handler (index 22)
	{"id": "p22_s1", "partner_index": 22, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p22_s2", "partner_index": 22, "skill_level": 2, "unlock_count": 25, "name": "Click Synergy", "description": "+0.7% Partner DPS as Click Damage", "bonus_type": "click_damage_from_partner_dps", "bonus_value": 0.007},
	{"id": "p22_s3", "partner_index": 22, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p22_s4", "partner_index": 22, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p22_s5", "partner_index": 22, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 24 / Barrier Keeper (index 23)
	{"id": "p23_s1", "partner_index": 23, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p23_s2", "partner_index": 23, "skill_level": 2, "unlock_count": 25, "name": "Click Synergy", "description": "+0.7% Partner DPS as Click Damage", "bonus_type": "click_damage_from_partner_dps", "bonus_value": 0.007},
	{"id": "p23_s3", "partner_index": 23, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p23_s4", "partner_index": 23, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p23_s5", "partner_index": 23, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 25 / War Strategist (index 24)
	{"id": "p24_s1", "partner_index": 24, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p24_s2", "partner_index": 24, "skill_level": 2, "unlock_count": 25, "name": "Click Synergy", "description": "+0.7% Partner DPS as Click Damage", "bonus_type": "click_damage_from_partner_dps", "bonus_value": 0.007},
	{"id": "p24_s3", "partner_index": 24, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p24_s4", "partner_index": 24, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p24_s5", "partner_index": 24, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 26 / Sage Disciple (index 25)
	{"id": "p25_s1", "partner_index": 25, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p25_s2", "partner_index": 25, "skill_level": 2, "unlock_count": 25, "name": "Click Synergy", "description": "+0.7% Partner DPS as Click Damage", "bonus_type": "click_damage_from_partner_dps", "bonus_value": 0.007},
	{"id": "p25_s3", "partner_index": 25, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p25_s4", "partner_index": 25, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p25_s5", "partner_index": 25, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 27 / Anbu Captain (index 26)
	{"id": "p26_s1", "partner_index": 26, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p26_s2", "partner_index": 26, "skill_level": 2, "unlock_count": 25, "name": "Click Synergy", "description": "+0.7% Partner DPS as Click Damage", "bonus_type": "click_damage_from_partner_dps", "bonus_value": 0.007},
	{"id": "p26_s3", "partner_index": 26, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p26_s4", "partner_index": 26, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p26_s5", "partner_index": 26, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	# Partner 28 / Legendary Sannin (index 27)
	{"id": "p27_s1", "partner_index": 27, "skill_level": 1, "unlock_count": 10, "name": "DPS Mastery I", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p27_s2", "partner_index": 27, "skill_level": 2, "unlock_count": 25, "name": "Click Synergy", "description": "+0.7% Partner DPS as Click Damage", "bonus_type": "click_damage_from_partner_dps", "bonus_value": 0.007},
	{"id": "p27_s3", "partner_index": 27, "skill_level": 3, "unlock_count": 50, "name": "DPS Mastery III", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p27_s4", "partner_index": 27, "skill_level": 4, "unlock_count": 100, "name": "DPS Mastery IV", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
	{"id": "p27_s5", "partner_index": 27, "skill_level": 5, "unlock_count": 250, "name": "DPS Mastery V", "description": "x2 This Partner DPS", "bonus_type": "own_partner_dps", "bonus_value": 1.0},
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
