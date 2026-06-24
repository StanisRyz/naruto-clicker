extends "res://scripts/platform/PlatformServices.gd"

# Android bridge for Yandex Mobile Ads SDK and the official RuStore Pay SDK.
#
# Ads: Yandex Mobile Ads SDK via the AndroidYandexAds Godot plugin.
#   Plugin source: addons/android_yandex_ads/
#   Singleton:     Engine.get_singleton("AndroidYandexAds")
#   Ad unit ids:   scripts/game/config/AdPlacementConfig.gd
#
# Payments: Official RuStore Pay SDK via RuStoreGodotPayClient.
#   SDK addon:     addons/RuStoreGodotPay/  (class RuStoreGodotPayClient)
#   Core addon:    addons/RuStoreGodotCore/ (class RuStoreGodotCoreUtils)
#   Singletons:    Engine.get_singleton("RuStoreGodotPay") / "RuStoreGodotCore"
#   Old adapter:   addons/android_rustore_pay/ — DEPRECATED, not used for payments.
#   See docs/rustore_pay_integration.md for setup and manual test checklist.

const AdPlacementConfigClass = preload("res://scripts/game/config/AdPlacementConfig.gd")

# ── Payment state ─────────────────────────────────────────────────────────────

var _payment_in_progress: bool = false
var _pending_local_product_id: String = ""
var _pending_platform_product_id: String = ""
var _pay_client: RuStoreGodotPayClient = null

# ── Ad state ──────────────────────────────────────────────────────────────────

var _rewarded_ad_in_progress: bool = false
var _fullscreen_ad_in_progress: bool = false
var _pending_rewarded_placement_id: String = ""
var _pending_fullscreen_placement_id: String = ""

# ── Initialization ────────────────────────────────────────────────────────────

func _ready() -> void:
	var ads_plugin := _get_android_ads_plugin()
	if ads_plugin:
		ads_plugin.rewarded_ad_opened.connect(_on_android_rewarded_ad_opened)
		ads_plugin.rewarded_ad_rewarded.connect(_on_android_rewarded_ad_rewarded)
		ads_plugin.rewarded_ad_closed.connect(_on_android_rewarded_ad_closed)
		ads_plugin.rewarded_ad_error.connect(_on_android_rewarded_ad_error)
		ads_plugin.fullscreen_ad_opened.connect(_on_android_fullscreen_ad_opened)
		ads_plugin.fullscreen_ad_closed.connect(_on_android_fullscreen_ad_closed)
		ads_plugin.fullscreen_ad_error.connect(_on_android_fullscreen_ad_error)
		ads_plugin.initialize()

	_pay_client = _create_rustore_pay_client()
	if _pay_client:
		_pay_client.on_purchase_success.connect(_on_rustore_purchase_success)
		_pay_client.on_purchase_failure.connect(_on_rustore_purchase_failure)
		_pay_client.on_purchase_cancelled.connect(_on_rustore_purchase_cancelled)
		_pay_client.on_get_purchases_success.connect(_on_rustore_get_purchases_success)
		_pay_client.on_get_purchases_failure.connect(_on_rustore_get_purchases_failure)

# ── Plugin / client access ─────────────────────────────────────────────────────

func _get_android_ads_plugin() -> Object:
	if Engine.has_singleton("AndroidYandexAds"):
		return Engine.get_singleton("AndroidYandexAds")
	return null


func _is_android_ads_available() -> bool:
	return _get_android_ads_plugin() != null


# Returns a RuStoreGodotPayClient instance if the official SDK singletons are
# available, or null. Called once in _ready(); result cached in _pay_client.
func _create_rustore_pay_client() -> RuStoreGodotPayClient:
	if not OS.has_feature("android"):
		return null
	if not Engine.has_singleton("RuStoreGodotPay"):
		return null
	if not Engine.has_singleton("RuStoreGodotCore"):
		return null
	return RuStoreGodotPayClient.get_instance()


func _is_rustore_pay_available() -> bool:
	return _pay_client != null


# Resolves a logical placement id to a Yandex ad unit id.
func _resolve_ad_unit_id(placement_id: String) -> String:
	return AdPlacementConfigClass.get_platform_ad_unit_id(placement_id, "rustore")

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func game_ready() -> void:
	pass


func gameplay_start(_attempt: int = 0) -> void:
	pass


func gameplay_stop() -> void:
	pass

# ── Ads ───────────────────────────────────────────────────────────────────────

func is_ad_in_progress() -> bool:
	return _rewarded_ad_in_progress or _fullscreen_ad_in_progress


func show_rewarded_ad(placement_id: String = "") -> void:
	if _rewarded_ad_in_progress:
		return

	if not AdPlacementConfigClass.exists(placement_id):
		rewarded_ad_error.emit("Unknown rewarded ad placement: " + placement_id)
		return

	var ad_unit_id: String = _resolve_ad_unit_id(placement_id)
	if ad_unit_id == "":
		rewarded_ad_error.emit("Rewarded ad unit id not configured for placement: " + placement_id)
		return

	var plugin := _get_android_ads_plugin()
	if not plugin:
		rewarded_ad_error.emit("Rewarded ads not available (AndroidYandexAds plugin not loaded)")
		return

	_rewarded_ad_in_progress = true
	_pending_rewarded_placement_id = placement_id
	plugin.show_rewarded_ad(ad_unit_id)


func show_fullscreen_ad(placement_id: String = "") -> void:
	if _fullscreen_ad_in_progress:
		return

	if not AdPlacementConfigClass.exists(placement_id):
		fullscreen_ad_error.emit("Unknown fullscreen ad placement: " + placement_id)
		return

	var ad_unit_id: String = _resolve_ad_unit_id(placement_id)
	if ad_unit_id == "":
		fullscreen_ad_error.emit("Fullscreen ad unit id not configured for placement: " + placement_id)
		return

	var plugin := _get_android_ads_plugin()
	if not plugin:
		fullscreen_ad_error.emit("Fullscreen ads not available (AndroidYandexAds plugin not loaded)")
		return

	_fullscreen_ad_in_progress = true
	_pending_fullscreen_placement_id = placement_id
	plugin.show_interstitial_ad(ad_unit_id)

# ── Android Yandex Ads plugin callbacks ───────────────────────────────────────

func _on_android_rewarded_ad_opened() -> void:
	if not _rewarded_ad_in_progress:
		return
	rewarded_ad_opened.emit()


func _on_android_rewarded_ad_rewarded() -> void:
	if not _rewarded_ad_in_progress:
		return
	rewarded_ad_rewarded.emit()


func _on_android_rewarded_ad_closed(was_rewarded: bool) -> void:
	if not _rewarded_ad_in_progress:
		return
	_rewarded_ad_in_progress = false
	_pending_rewarded_placement_id = ""
	rewarded_ad_closed.emit(was_rewarded)


func _on_android_rewarded_ad_error(message: String) -> void:
	_rewarded_ad_in_progress = false
	_pending_rewarded_placement_id = ""
	rewarded_ad_error.emit(message)


func _on_android_fullscreen_ad_opened() -> void:
	if not _fullscreen_ad_in_progress:
		return
	fullscreen_ad_opened.emit()


func _on_android_fullscreen_ad_closed(was_shown: bool = true) -> void:
	if not _fullscreen_ad_in_progress:
		return
	_fullscreen_ad_in_progress = false
	_pending_fullscreen_placement_id = ""
	fullscreen_ad_closed.emit(was_shown)


func _on_android_fullscreen_ad_error(message: String) -> void:
	_fullscreen_ad_in_progress = false
	_pending_fullscreen_placement_id = ""
	fullscreen_ad_error.emit(message)

# ── Payments ──────────────────────────────────────────────────────────────────

func purchase_product(platform_product_id: String, local_product_id: String = "") -> void:
	var local_id: String = local_product_id if local_product_id != "" else platform_product_id

	if platform_product_id == "":
		payment_purchase_error.emit(local_id, "Empty platform product id")
		return

	if _payment_in_progress:
		payment_purchase_error.emit(local_id, "Payment already in progress")
		return

	payment_purchase_started.emit(local_id)

	_payment_in_progress = true
	_pending_local_product_id = local_id
	_pending_platform_product_id = platform_product_id

	if not _pay_client:
		_payment_in_progress = false
		_pending_local_product_id = ""
		_pending_platform_product_id = ""
		payment_purchase_error.emit(local_id, "RuStore Pay SDK not available")
		return

	var params := RuStorePayProductPurchaseParams.new(
		RuStorePayProductId.new(platform_product_id)
	)

	_pay_client.purchase(
		params,
		ERuStorePayPreferredPurchaseType.Item.ONE_STEP,
		ERuStorePaySdkTheme.Item.DARK,
		false
	)


func _on_rustore_purchase_success(result: RuStorePayProductPurchaseResult) -> void:
	if not _payment_in_progress:
		return
	var local_id: String = _pending_local_product_id
	_payment_in_progress = false
	_pending_local_product_id = ""
	_pending_platform_product_id = ""

	var purchase_id: String = _extract_purchase_id_from_result(result)
	if purchase_id == "":
		payment_purchase_error.emit(local_id, "Purchase result has no valid purchase id")
		return
	payment_purchase_success.emit(local_id, purchase_id)


# Preferred id order: purchaseId → orderId → invoiceId.
# An empty string means none were present — caller must not grant rewards.
func _extract_purchase_id_from_result(result: RuStorePayProductPurchaseResult) -> String:
	if result == null:
		return ""
	if result.purchaseId != null and result.purchaseId.value != "":
		return result.purchaseId.value
	if result.orderId != null and result.orderId.value != "":
		return result.orderId.value
	if result.invoiceId != null and result.invoiceId.value != "":
		return result.invoiceId.value
	return ""


func _on_rustore_purchase_failure(product_id: RuStorePayProductId, error: RuStorePaymentException) -> void:
	var local_id: String = _pending_local_product_id
	_payment_in_progress = false
	_pending_local_product_id = ""
	_pending_platform_product_id = ""
	var message: String = _exception_message(error)
	if message == "":
		message = "Purchase failed"
	payment_purchase_error.emit(local_id, message)


# on_purchase_cancelled emits (productId, purchaseId, invoiceId) — all ignored here.
# We only need _pending_local_product_id which is already stored.
func _on_rustore_purchase_cancelled(_product_id: Variant, _purchase_id: Variant, _invoice_id: Variant) -> void:
	if not _payment_in_progress:
		return
	var local_id: String = _pending_local_product_id
	_payment_in_progress = false
	_pending_local_product_id = ""
	_pending_platform_product_id = ""
	payment_purchase_cancelled.emit(local_id)


func _exception_message(error: RuStorePaymentException) -> String:
	if error == null:
		return ""
	if error.description != "":
		return error.description
	return error.name


# ONE_STEP consumables are auto-confirmed by the SDK. No explicit consume call
# is required or available for this purchase type.
func consume_purchase(_purchase_token: String) -> void:
	pass


func check_unprocessed_purchases() -> void:
	if not _pay_client:
		unprocessed_purchase_check_completed.emit()
		return
	_pay_client.get_purchases(
		ERuStorePayProductType.Item.CONSUMABLE_PRODUCT,
		ERuStorePayPurchaseStatusFilter.Item.CONFIRMED
	)


func _on_rustore_get_purchases_success(purchases: Array) -> void:
	for purchase in purchases:
		if not (purchase is RuStorePayProductPurchase):
			continue
		var product_id_obj: RuStorePayProductId = purchase.productId
		if product_id_obj == null:
			continue
		var platform_product_id: String = product_id_obj.value
		if platform_product_id == "":
			continue
		var local_id: String = _find_local_product_id(platform_product_id)
		if local_id == "":
			continue
		var purchase_id: String = _extract_purchase_id_from_product_purchase(purchase)
		if purchase_id == "":
			continue
		unprocessed_purchase_found.emit(local_id, purchase_id)
	unprocessed_purchase_check_completed.emit()


func _on_rustore_get_purchases_failure(error: RuStorePaymentException) -> void:
	var message: String = _exception_message(error)
	if message == "":
		message = "Failed to retrieve purchases"
	unprocessed_purchase_check_error.emit(message)


# Maps a RuStore platform product id back to the local (GemPurchaseConfig) id.
func _find_local_product_id(platform_product_id: String) -> String:
	for product: Dictionary in GemPurchaseConfig.get_all():
		if String(product.get("rustore_product_id", "")) == platform_product_id:
			return String(product.get("id", ""))
	return ""


# Same preferred id order as _extract_purchase_id_from_result.
func _extract_purchase_id_from_product_purchase(purchase: RuStorePayProductPurchase) -> String:
	if purchase.purchaseId != null and purchase.purchaseId.value != "":
		return purchase.purchaseId.value
	if purchase.orderId != null and purchase.orderId.value != "":
		return purchase.orderId.value
	if purchase.invoiceId != null and purchase.invoiceId.value != "":
		return purchase.invoiceId.value
	return ""

# ── Cloud save ────────────────────────────────────────────────────────────────

func is_cloud_save_available() -> bool:
	return false


func load_cloud_save() -> void:
	cloud_save_loaded.emit({})


func save_cloud_save(_data: Dictionary, _flush: bool = false) -> void:
	pass


func delete_cloud_save() -> void:
	cloud_save_deleted.emit()

# ── Platform info ─────────────────────────────────────────────────────────────

func get_platform_language() -> String:
	return ""


func refresh_platform_ready() -> bool:
	return false


func get_platform_event_debug_state() -> Dictionary:
	return {}


func get_platform_key() -> String:
	return "rustore"
