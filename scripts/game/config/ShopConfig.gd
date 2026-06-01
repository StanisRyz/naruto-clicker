class_name ShopConfig
extends RefCounted

const SHOP_PRODUCTS: Array = [
	{
		"id": "gold_pack_small",
		"name": "Small Gold Pack",
		"name_key": "shop.gold_pack_small.name",
		"description": "Gain stage-scaled gold",
		"description_key": "shop.gold_pack_small.description",
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
		"cost_gems": 25,
		"reward_type": "gold",
		"reward_scale": 350,
	},
	{
		"id": "instant_combo",
		"name": "Instant Combo",
		"name_key": "shop.instant_combo.name",
		"description": "Fill Combo Meter to 100%",
		"description_key": "shop.instant_combo.description",
		"cost_gems": 15,
		"reward_type": "combo_fill",
		"reward_amount": 100,
	},
	{
		"id": "boss_retry_token",
		"name": "Boss Retry",
		"name_key": "shop.boss_retry_token.name",
		"description": "Return to the failed boss level",
		"description_key": "shop.boss_retry_token.description",
		"cost_gems": 20,
		"reward_type": "boss_retry_token",
		"reward_amount": 1,
	},
	{
		"id": "task_boost",
		"name": "Task Reward Boost",
		"name_key": "shop.task_boost.name",
		"description": "Next claimed task gives x2 gold",
		"description_key": "shop.task_boost.description",
		"cost_gems": 30,
		"reward_type": "task_reward_boost",
		"reward_multiplier": 2.0,
	},
]


static func get_all() -> Array:
	return SHOP_PRODUCTS


static func get_by_id(product_id: String) -> Dictionary:
	for product: Dictionary in SHOP_PRODUCTS:
		if String(product.get("id", "")) == product_id:
			return product
	return {}
