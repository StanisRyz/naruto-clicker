class_name ShopConfig
extends RefCounted

const SHOP_PRODUCTS: Array = [
	{
		"id": "gold_pack_small",
		"name": "Small Gold Pack",
		"description": "Gain stage-scaled gold",
		"cost_gems": 10,
		"reward_type": "gold",
		"reward_scale": 120,
	},
	{
		"id": "gold_pack_large",
		"name": "Large Gold Pack",
		"description": "Gain a large stage-scaled gold reward",
		"cost_gems": 25,
		"reward_type": "gold",
		"reward_scale": 350,
	},
	{
		"id": "instant_combo",
		"name": "Instant Combo",
		"description": "Fill Combo Meter to 100%",
		"cost_gems": 15,
		"reward_type": "combo_fill",
		"reward_amount": 100,
	},
	{
		"id": "boss_retry_token",
		"name": "Boss Retry",
		"description": "Return to the failed boss level",
		"cost_gems": 20,
		"reward_type": "boss_retry_token",
		"reward_amount": 1,
	},
	{
		"id": "task_boost",
		"name": "Task Reward Boost",
		"description": "Next claimed task gives x2 gold",
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
