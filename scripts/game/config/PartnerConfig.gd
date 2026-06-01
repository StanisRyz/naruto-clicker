class_name PartnerConfig
extends RefCounted

const PARTNER_NAMES: Array = [
	"Partner 1",
	"Partner 2",
	"Partner 3",
	"Field Scout",
	"Spear Guard",
	"Iron Defender",
	"Battle Monk",
	"Elite Samurai",
	"Shadow Captain",
	"War Sage",
	"Beast Tamer",
	"Blade Master",
	"Legendary Commander",
]


static func get_partner_count() -> int:
	return PARTNER_NAMES.size()


static func get_name(index: int) -> String:
	if index < 0 or index >= PARTNER_NAMES.size():
		return ""
	return PARTNER_NAMES[index]


static func get_base_dps(index: int) -> int:
	if index < 0 or index >= BalanceConfig.PARTNER_DPS_VALUES.size():
		return 0
	return BalanceConfig.PARTNER_DPS_VALUES[index]


static func get_base_cost(index: int) -> int:
	if index < 0 or index >= BalanceConfig.PARTNER_BASE_COSTS.size():
		return 0
	return BalanceConfig.PARTNER_BASE_COSTS[index]


static func get_name_key(index: int) -> String:
	return "partner.%02d.name" % (index + 1)
