class_name GemPurchaseConfig
extends RefCounted

const GEM_PRODUCTS: Array[Dictionary] = [
	{
		"id": "gems_small",
		"yandex_product_id": "gems_small",
		"name_key": "shop.gems_small.name",
		"description_key": "shop.gems_small.description",
		"amount_gems": 50,
	},
	{
		"id": "gems_medium",
		"yandex_product_id": "gems_medium",
		"name_key": "shop.gems_medium.name",
		"description_key": "shop.gems_medium.description",
		"amount_gems": 200,
	},
	{
		"id": "gems_large",
		"yandex_product_id": "gems_large",
		"name_key": "shop.gems_large.name",
		"description_key": "shop.gems_large.description",
		"amount_gems": 500,
	},
]

static func get_all() -> Array[Dictionary]:
	return GEM_PRODUCTS

static func get_by_id(product_id: String) -> Dictionary:
	for product: Dictionary in GEM_PRODUCTS:
		if String(product.get("id", "")) == product_id:
			return product
	return {}
