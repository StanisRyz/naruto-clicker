class_name GemPurchaseConfig
extends RefCounted

const GEM_PRODUCTS: Array[Dictionary] = [
	{
		"id": "gems_25",
		"yandex_product_id": "gems_25",
		"rustore_product_id": "gems_25",
		"name_key": "shop.gems_25.name",
		"description_key": "shop.gems_25.description",
		"amount_gems": 25,
		"base_gems": 25,
		"bonus_gems": 0,
		"price_rub": 24,
		"icon_key": "shop.gems_25",
	},
	{
		"id": "gems_150",
		"yandex_product_id": "gems_150",
		"rustore_product_id": "gems_150",
		"name_key": "shop.gems_150.name",
		"description_key": "shop.gems_150.description",
		"amount_gems": 150,
		"base_gems": 100,
		"bonus_gems": 50,
		"price_rub": 99,
		"icon_key": "shop.gems_150",
	},
	{
		"id": "gems_500",
		"yandex_product_id": "gems_500",
		"rustore_product_id": "gems_500",
		"name_key": "shop.gems_500.name",
		"description_key": "shop.gems_500.description",
		"amount_gems": 500,
		"base_gems": 250,
		"bonus_gems": 250,
		"price_rub": 249,
		"icon_key": "shop.gems_500",
	},
	{
		"id": "gems_1500",
		"yandex_product_id": "gems_1500",
		"rustore_product_id": "gems_1500",
		"name_key": "shop.gems_1500.name",
		"description_key": "shop.gems_1500.description",
		"amount_gems": 1500,
		"base_gems": 500,
		"bonus_gems": 1000,
		"price_rub": 499,
		"icon_key": "shop.gems_1500",
	},
]

static func get_all() -> Array[Dictionary]:
	return GEM_PRODUCTS


static func get_by_id(product_id: String) -> Dictionary:
	for product: Dictionary in GEM_PRODUCTS:
		if String(product.get("id", "")) == product_id:
			return product
	return {}


# Returns the store-specific product ID for a given local product and platform.
# platform_key: "yandex" | "rustore" | "debug" | anything else → local id fallback
static func get_platform_product_id(product_id: String, platform_key: String) -> String:
	var product: Dictionary = get_by_id(product_id)
	if product.is_empty():
		return ""
	match platform_key:
		"yandex":
			return String(product.get("yandex_product_id", product_id))
		"rustore":
			return String(product.get("rustore_product_id", product_id))
		_:
			return String(product.get("id", product_id))
