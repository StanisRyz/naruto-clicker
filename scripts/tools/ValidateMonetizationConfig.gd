## Headless validation tool for GemPurchaseConfig.
##
## Run with:
##   godot --headless --script res://scripts/tools/ValidateMonetizationConfig.gd
##
## Checks every gem product for:
##   - Required fields present and non-empty
##   - Positive gem amounts and prices
##   - No duplicate ids
##   - Non-empty yandex_product_id and rustore_product_id
##   - Consistent amount_gems = base_gems + bonus_gems
##
## Exit code 0 = all checks passed.  Exit code 1 = one or more failures.
extends SceneTree

const GemPurchaseConfigClass = preload("res://scripts/game/config/GemPurchaseConfig.gd")

const REQUIRED_STRING_FIELDS: Array[String] = [
	"id",
	"yandex_product_id",
	"rustore_product_id",
	"name_key",
	"description_key",
	"icon_key",
]

const REQUIRED_POSITIVE_INT_FIELDS: Array[String] = [
	"amount_gems",
	"base_gems",
	"price_rub",
]


func _init() -> void:
	var products: Array[Dictionary] = GemPurchaseConfigClass.get_all()
	var errors: Array[String] = []
	var seen_ids: Array[String] = []

	if products.is_empty():
		errors.append("GEM_PRODUCTS is empty")

	for product: Dictionary in products:
		var pid: String = String(product.get("id", ""))
		var prefix: String = "product '%s'" % pid

		# Duplicate id check
		if pid in seen_ids:
			errors.append("%s: duplicate id" % prefix)
		else:
			seen_ids.append(pid)

		# Required non-empty string fields
		for field: String in REQUIRED_STRING_FIELDS:
			var value = product.get(field, null)
			if value == null or String(value) == "":
				errors.append("%s: '%s' is missing or empty" % [prefix, field])

		# Required positive integer fields
		for field: String in REQUIRED_POSITIVE_INT_FIELDS:
			var value = product.get(field, null)
			if value == null or int(value) <= 0:
				errors.append("%s: '%s' must be a positive integer (got %s)" % [prefix, field, str(value)])

		# bonus_gems must be >= 0
		var bonus: int = int(product.get("bonus_gems", -1))
		if bonus < 0:
			errors.append("%s: 'bonus_gems' must be >= 0 (got %d)" % [prefix, bonus])

		# amount_gems must equal base_gems + bonus_gems
		var amount: int = int(product.get("amount_gems", 0))
		var base: int = int(product.get("base_gems", 0))
		if amount != base + bonus:
			errors.append(
				"%s: amount_gems (%d) != base_gems (%d) + bonus_gems (%d)" % [prefix, amount, base, bonus]
			)

	if errors.is_empty():
		print("ValidateMonetizationConfig: OK — %d products validated" % products.size())
		quit(0)
	else:
		print("ValidateMonetizationConfig: FAILED — %d error(s):" % errors.size())
		for err: String in errors:
			print("  ERROR: " + err)
		quit(1)
