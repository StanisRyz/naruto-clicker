# ShopRuntime handles local prototype shop behavior only.
# It does not implement real payments.
# It must not call SaveManager.
# It must not reference UI nodes.
# Real Yandex payments should be integrated later through a separate layer.
class_name ShopRuntime
extends RefCounted


static func add_gems(state: ClickerState, amount: int) -> void:
	state.gems = maxi(0, state.gems + amount)


static func grant_test_gems(state: ClickerState, amount: int = 50) -> Dictionary:
	add_gems(state, amount)
	return state._make_purchase_result("Prototype test grant: +%d Gems" % amount, false, true)


static func get_shop_product(product_id: String) -> Dictionary:
	for product: Dictionary in ShopConfig.SHOP_PRODUCTS:
		if String(product.get("id", "")) == product_id:
			return product
	return {}


static func buy_shop_product(state: ClickerState, product_id: String) -> Dictionary:
	var product: Dictionary = get_shop_product(product_id)
	if product.is_empty():
		return state._make_purchase_result("Invalid shop product")

	var cost_gems: int = int(product.get("cost_gems", 0))
	if state.gems < cost_gems:
		return state._make_purchase_result("Not enough Gems")

	state.gems -= cost_gems
	var product_name: String = String(product.get("name", "Shop product"))
	var reward_type: String = String(product.get("reward_type", ""))
	var result: Dictionary = state._make_purchase_result("%s purchased!" % product_name, false, true)

	match reward_type:
		"gold":
			# ETV formula: gold = (enemy_reward / TTK_seconds) * etv_seconds
			# etv_seconds comes from BalanceConfig per product id; fallback uses reward_scale.
			var base_reward_unit: int = state.get_current_task_reward_unit()
			var shop_gold: int
			match product_id:
				"gold_pack_small":
					shop_gold = maxi(1, ceili(float(base_reward_unit) / BalanceConfig.TASK_BASELINE_TTK_SECONDS * BalanceConfig.SHOP_SMALL_GOLD_ETV_SECONDS))
				"gold_pack_large":
					shop_gold = maxi(1, ceili(float(base_reward_unit) / BalanceConfig.TASK_BASELINE_TTK_SECONDS * BalanceConfig.SHOP_LARGE_GOLD_ETV_SECONDS))
				_:
					var reward_scale: int = int(product.get("reward_scale", 0))
					shop_gold = maxi(1, base_reward_unit * reward_scale)
			state.gold += shop_gold
			result["reward_gold"] = shop_gold
			result["status_text"] = "%s purchased! +%d gold" % [product_name, shop_gold]
		"boss_retry_token":
			var boss_retry_reward_amount: int = int(product.get("reward_amount", 1))
			state.boss_retry_tokens += boss_retry_reward_amount
			result["status_text"] = "%s purchased! +%d Boss Retry" % [product_name, boss_retry_reward_amount]
		"task_reward_boost":
			var reward_multiplier: float = float(product.get("reward_multiplier", 1.0))
			state.task_reward_boost_multiplier = maxf(state.task_reward_boost_multiplier, reward_multiplier)
			result["status_text"] = "%s purchased! Next task reward x%.1f" % [product_name, state.task_reward_boost_multiplier]
		_:
			result["status_text"] = "Unknown shop reward"

	return result
