# ShopRuntime handles local prototype shop behavior only.
# It does not implement real payments.
# It must not call SaveManager.
# It must not reference UI nodes.
# Real Yandex payments should be integrated later through a separate layer.
class_name ShopRuntime
extends RefCounted


static func add_gems(state: ClickerState, amount: int) -> void:
	state.gems = maxi(0, state.gems + amount)


static func get_shop_buy_count(mode: String) -> int:
	match mode:
		"x1": return 1
		"x2": return 2
		"x3": return 3
		"x4": return 4
	return 1


static func get_permanent_upgrade_cost_for_level(level: int) -> int:
	return ceili(float(ShopConfig.PERMANENT_UPGRADE_BASE_COST_GEMS) * pow(ShopConfig.PERMANENT_UPGRADE_COST_GROWTH, float(maxi(0, level))))


static func get_permanent_upgrade_bulk_cost(state: ClickerState, product_id: String, count: int) -> int:
	var owned: int = state.get_shop_permanent_upgrade_count(product_id)
	var total_cost: int = 0
	for i in range(count):
		total_cost += get_permanent_upgrade_cost_for_level(owned + i)
	return total_cost


static func get_shop_product(product_id: String) -> Dictionary:
	for product: Dictionary in ShopConfig.SHOP_PRODUCTS:
		if String(product.get("id", "")) == product_id:
			return product
	return {}


static func buy_shop_products(state: ClickerState, product_id: String, mode: String) -> Dictionary:
	var product: Dictionary = get_shop_product(product_id)
	if product.is_empty():
		return state._make_purchase_result("Invalid shop product")

	var product_type: String = String(product.get("product_type", "consumable"))
	var count: int = get_shop_buy_count(mode)
	var product_name: String = String(product.get("name", "Shop product"))

	if product_type == "permanent_multiplier":
		var total_cost: int = get_permanent_upgrade_bulk_cost(state, product_id, count)
		if total_cost <= 0 or state.gems < total_cost:
			return state._make_purchase_result("Not enough Gems")

		state.gems -= total_cost
		var owned_before: int = state.get_shop_permanent_upgrade_count(product_id)
		state._set_shop_permanent_upgrade_count(product_id, owned_before + count)
		state._update_character_state()

		var owned_after: int = state.get_shop_permanent_upgrade_count(product_id)
		var total_multiplier: int = int(pow(ShopConfig.PERMANENT_UPGRADE_MULTIPLIER_PER_LEVEL, float(owned_after)))
		var result: Dictionary = state._make_purchase_result(
			"%s x%d! Total multiplier: x%d" % [product_name, count, total_multiplier],
			false, true
		)
		result["status_text"] = "%s purchased x%d! Total: x%d" % [product_name, count, total_multiplier]
		return result

	# consumable
	var cost_gems: int = int(product.get("cost_gems", 0))
	var total_cost_consumable: int = cost_gems * count
	if total_cost_consumable <= 0 or state.gems < total_cost_consumable:
		return state._make_purchase_result("Not enough Gems")

	state.gems -= total_cost_consumable
	var reward_type: String = String(product.get("reward_type", ""))
	var result: Dictionary = state._make_purchase_result("%s purchased!" % product_name, false, true)

	match reward_type:
		"gold":
			var base_reward_unit: int = state.get_current_task_reward_unit()
			var gold_per_pack: int
			match product_id:
				"gold_pack_small":
					gold_per_pack = maxi(1, ceili(float(base_reward_unit) / BalanceConfig.TASK_BASELINE_TTK_SECONDS * BalanceConfig.SHOP_SMALL_GOLD_ETV_SECONDS))
				"gold_pack_large":
					gold_per_pack = maxi(1, ceili(float(base_reward_unit) / BalanceConfig.TASK_BASELINE_TTK_SECONDS * BalanceConfig.SHOP_LARGE_GOLD_ETV_SECONDS))
				_:
					var reward_scale: int = int(product.get("reward_scale", 0))
					gold_per_pack = maxi(1, base_reward_unit * reward_scale)
			var shop_gold: int = gold_per_pack * count
			state.gold += shop_gold
			result["reward_gold"] = shop_gold
			result["status_text"] = "%s x%d purchased! +%d gold" % [product_name, count, shop_gold]
		_:
			result["status_text"] = "Unknown shop reward"

	return result


static func buy_shop_product(state: ClickerState, product_id: String) -> Dictionary:
	return buy_shop_products(state, product_id, "x1")
