extends "res://scripts/platform/PlatformServices.gd"

# Android payment bridge for RuStore Pay SDK.
# No real RuStore Pay Godot plugin is bundled yet — all payment attempts emit
# a clean error callback so the game stays stable and never crashes.
#
# When the official RuStore Pay Godot plugin is available:
# 1. Drop the .aar into android/plugins/ (or use the Godot Asset Library version).
# 2. Implement _get_rustore_pay_plugin() to return the plugin node.
# 3. Implement purchase_product() using the plugin's documented purchase call.
# 4. Connect plugin success/cancel/error signals to this node's signals.
#
# Ads are also not integrated yet. Ad methods emit clean error callbacks.
# Cloud save is unavailable on Android for now.

# ── Payment state ─────────────────────────────────────────────────────────────

var _payment_in_progress: bool = false
var _pending_local_product_id: String = ""
var _pending_platform_product_id: String = ""

# ── Plugin access ─────────────────────────────────────────────────────────────

# Returns the RuStore Pay plugin node if available, or null.
# Replace the body with the correct plugin singleton name once the plugin is added.
func _get_rustore_pay_plugin() -> Object:
	# TODO: return Engine.get_singleton("RuStorePayPlugin") when plugin is available
	return null


func _is_rustore_pay_available() -> bool:
	return _get_rustore_pay_plugin() != null

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func game_ready() -> void:
	pass


func gameplay_start(_attempt: int = 0) -> void:
	pass


func gameplay_stop() -> void:
	pass

# ── Ads ───────────────────────────────────────────────────────────────────────

func is_ad_in_progress() -> bool:
	return false


func show_rewarded_ad(_placement_id: String = "") -> void:
	rewarded_ad_error.emit("Rewarded ads not available (RuStore Ads not integrated)")


func show_fullscreen_ad(_placement_id: String = "") -> void:
	fullscreen_ad_error.emit("Fullscreen ads not available (RuStore Ads not integrated)")

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
