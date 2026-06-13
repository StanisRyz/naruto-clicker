class_name ShopConfig
extends RefCounted

const SHOP_BUY_MODES: Array[String] = ["x1", "x2", "x3", "x4"]
const PERMANENT_UPGRADE_BASE_COST_GEMS: int = 500
const PERMANENT_UPGRADE_COST_GROWTH: float = 2.0
const PERMANENT_UPGRADE_MULTIPLIER_PER_LEVEL: float = 2.0

const SHOP_PRODUCTS: Array = [
	{
		"id": "rewarded_gems_ad",
		"name": "Watch Ad: +3 Gems",
		"name_key": "shop.rewarded_gems_ad.name",
		"description": "Watch an ad to receive gems",
		"description_key": "shop.rewarded_gems_ad.description",
		"product_type": "rewarded_ad",
		"reward_type": "gems",
		"reward_gems": 3,
		"cost_gems": 0,
	},
	{
		"id": "gold_pack_small",
		"name": "Small Gold Pack",
		"name_key": "shop.gold_pack_small.name",
		"description": "Gain stage-scaled gold",
		"description_key": "shop.gold_pack_small.description",
		"product_type": "consumable",
		"cost_gems": 10,
		"reward_type": "gold",
		"reward_scale": 120,
	},
	{
		"id": "gold_pack_large",
		"name": "Large Gold Pack",
		"name_key": "shop.gold_pack_large.name",
		"description": "Gain a large stage-scaled gold reward",
		"description_key": "shop.gold_pack_large.description",
		"product_type": "consumable",
		"cost_gems": 25,
		"reward_type": "gold",
		"reward_scale": 350,
	},
	{
		"id": "permanent_partner_dps_x2",
		"name": "Permanent Partner DPS x2",
		"name_key": "shop.permanent_partner_dps_x2.name",
		"description": "Permanently doubles Partner DPS",
		"description_key": "shop.permanent_partner_dps_x2.description",
		"product_type": "permanent_multiplier",
		"bonus_type": "partner_dps",
		"base_cost_gems": 500,
	},
	{
		"id": "permanent_click_damage_x2",
		"name": "Permanent Click Damage x2",
		"name_key": "shop.permanent_click_damage_x2.name",
		"description": "Permanently doubles click damage",
		"description_key": "shop.permanent_click_damage_x2.description",
		"product_type": "permanent_multiplier",
		"bonus_type": "click_damage",
		"base_cost_gems": 500,
	},
	{
		"id": "permanent_gold_x2",
		"name": "Permanent Gold x2",
		"name_key": "shop.permanent_gold_x2.name",
		"description": "Permanently doubles gold from enemies",
		"description_key": "shop.permanent_gold_x2.description",
		"product_type": "permanent_multiplier",
		"bonus_type": "gold",
		"base_cost_gems": 500,
	},
]


static func get_all() -> Array:
	return SHOP_PRODUCTS


static func get_by_id(product_id: String) -> Dictionary:
	for product: Dictionary in SHOP_PRODUCTS:
		if String(product.get("id", "")) == product_id:
			return product
	return {}
