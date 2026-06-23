extends "res://scripts/platform/PlatformServices.gd"

# Android bridge for RuStore Pay SDK and RuStore Ads SDK.
# No real SDK plugins are bundled yet — all ad and payment attempts emit
# clean error callbacks so the game stays stable and never crashes.
#
# When the official RuStore Pay Godot plugin is available:
# 1. Drop the .aar into android/plugins/ (or use the Godot Asset Library version).
# 2. Implement _get_rustore_pay_plugin() to return the plugin node.
# 3. Implement purchase_product() using the plugin's documented purchase call.
# 4. Connect plugin success/cancel/error signals to this node's signals.
#
# When the official RuStore Ads Godot plugin is available:
# 1. Drop the .aar into android/plugins/.
# 2. Implement _get_android_ads_plugin() to return the plugin node.
# 3. Fill in android_ad_unit_id values in AdPlacementConfig.gd.
# 4. Connect plugin rewarded/fullscreen callbacks to _on_android_* methods below.

const AdPlacementConfigClass = preload("res://scripts/game/config/AdPlacementConfig.gd")

# ── Payment state ─────────────────────────────────────────────────────────────

var _payment_in_progress: bool = false
var _pending_local_product_id: String = ""
var _pending_platform_product_id: String = ""

# ── Ad state ──────────────────────────────────────────────────────────────────

var _rewarded_ad_in_progress: bool = false
var _fullscreen_ad_in_progress: bool = false
var _pending_rewarded_placement_id: String = ""
var _pending_fullscreen_placement_id: String = ""

# ── Plugin access ─────────────────────────────────────────────────────────────

# Returns the RuStore Pay plugin node if available, or null.
func _get_rustore_pay_plugin() -> Object:
	# TODO: return Engine.get_singleton("RuStorePayPlugin") when plugin is available
	return null


func _is_rustore_pay_available() -> bool:
	return _get_rustore_pay_plugin() != null


# Returns the Android Ads plugin node if available, or null.
func _get_android_ads_plugin() -> Object:
	# TODO: return Engine.get_singleton("RuStoreAdsPlugin") when plugin is available
	return null


func _is_android_ads_available() -> bool:
	return _get_android_ads_plugin() != null


# Resolves a logical placement id to a platform-specific ad unit id.
# Returns "" if the placement does not exist or has no unit id configured.
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

	if not _is_android_ads_available():
		rewarded_ad_error.emit("Rewarded ads not available (RuStore Ads not integrated)")
		return

	_rewarded_ad_in_progress = true
	_pending_rewarded_placement_id = placement_id

	# TODO: call the plugin here, e.g.:
	# var plugin = _get_android_ads_plugin()
	# plugin.show_rewarded_ad(ad_unit_id)
	# Then connect plugin callbacks in _ready() or here to _on_android_rewarded_ad_* methods


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

	if not _is_android_ads_available():
		fullscreen_ad_error.emit("Fullscreen ads not available (RuStore Ads not integrated)")
		return

	_fullscreen_ad_in_progress = true
	_pending_fullscreen_placement_id = placement_id

	# TODO: call the plugin here, e.g.:
	# var plugin = _get_android_ads_plugin()
	# plugin.show_interstitial_ad(ad_unit_id)
	# Then connect plugin callbacks in _ready() or here to _on_android_fullscreen_ad_* methods

# ── Android ad plugin callbacks (wire to plugin signals when plugin is added) ──

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


func _on_android_fullscreen_ad_closed() -> void:
	if not _fullscreen_ad_in_progress:
		return
	_fullscreen_ad_in_progress = false
	_pending_fullscreen_placement_id = ""
	fullscreen_ad_closed.emit()


func _on_android_fullscreen_ad_error(message: String) -> void:
	_fullscreen_ad_in_progress = false
	_pending_fullscreen_placement_id = ""
	fullscreen_ad_error.emit(message)

# ── Payments ──────────────────────────────────────────────────────────────────

func purchase_product(platform_product_id: String, local_product_id: String = "") -> void:
	var local_id: String = local_product_id if local_product_id != "" else platform_product_id

	if _payment_in_progress:
		payment_purchase_error.emit(local_id, "Payment already in progress")
		return

	payment_purchase_started.emit(local_id)

	if not _is_rustore_pay_available():
		# TODO: replace this block with real RuStore Pay plugin call
		payment_purchase_error.emit(local_id, "RuStore Pay plugin not available")
		return

	_payment_in_progress = true
	_pending_local_product_id = local_id
	_pending_platform_product_id = platform_product_id

	# TODO: call the plugin here, e.g.:
	# var plugin = _get_rustore_pay_plugin()
	# plugin.purchase(platform_product_id)
	# Then connect plugin signals in _ready() or here to _on_rustore_purchase_success / _error / _cancel


func _on_rustore_purchase_success(order_id: String) -> void:
	if not _payment_in_progress:
		return
	var local_id: String = _pending_local_product_id
	_payment_in_progress = false
	_pending_local_product_id = ""
	_pending_platform_product_id = ""
	payment_purchase_success.emit(local_id, order_id)


func _on_rustore_purchase_cancelled() -> void:
	if not _payment_in_progress:
		return
	var local_id: String = _pending_local_product_id
	_payment_in_progress = false
	_pending_local_product_id = ""
	_pending_platform_product_id = ""
	payment_purchase_cancelled.emit(local_id)


func _on_rustore_purchase_error(message: String) -> void:
	var local_id: String = _pending_local_product_id
	_payment_in_progress = false
	_pending_local_product_id = ""
	_pending_platform_product_id = ""
	payment_purchase_error.emit(local_id, message)


func consume_purchase(_purchase_token: String) -> void:
	# RuStore Pay uses order_id for deduplication; consumePurchase may not apply.
	# TODO: call plugin consume if the product type requires it.
	pass


func check_unprocessed_purchases() -> void:
	# TODO: call plugin getPurchases() when plugin is available.
	unprocessed_purchase_check_completed.emit()

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
