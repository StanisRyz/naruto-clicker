class_name PrestigeConfig
extends RefCounted

const TALENT_NAMES: Array = ["Focus Training", "Trade Routes", "Command Aura", "Quick Hands", "Builder Wisdom", "Boss Hunter"]
const TALENT_BONUS_TYPES: Array = ["click_damage", "gold", "partner_dps", "autoclick_rate", "settlement_effect", "boss_damage"]


static func get_talent_count() -> int:
	return TALENT_NAMES.size()


static func get_talent_name(index: int) -> String:
	if index < 0 or index >= TALENT_NAMES.size():
		return ""
	return TALENT_NAMES[index]


static func get_talent_bonus_type(index: int) -> String:
	if index < 0 or index >= TALENT_BONUS_TYPES.size():
		return ""
	return TALENT_BONUS_TYPES[index]


static func get_name_key(index: int) -> String:
	return "prestige.talent.%02d.name" % (index + 1)
