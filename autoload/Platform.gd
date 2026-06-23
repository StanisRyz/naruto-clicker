extends Node

# Platform abstraction layer.
# Selects the correct PlatformServices implementation at startup and
# re-exposes its signals so callers never reference YandexBridge directly.
#
# Web export  → WebYandexPlatform   (delegates to YandexBridge)
# Android     → AndroidRuStorePlatform (safe placeholder; no real SDK yet)
# Editor/other → LocalDebugPlatform  (simulates flows in debug builds only)

# ── Rewarded ad signals ───────────────────────────────────────────────────────
signal rewarded_ad_opened
signal rewarded_ad_rewarded
signal rewarded_ad_closed(was_shown: bool)
signal rewarded_ad_error(message: String)

# ── Fullscreen ad signals ─────────────────────────────────────────────────────
signal fullscreen_ad_opened
signal fullscreen_ad_closed(was_shown: bool)
signal fullscreen_ad_error(message: String)

# ── Payment signals ───────────────────────────────────────────────────────────
signal payment_purchase_started(product_id: String)
signal payment_purchase_success(product_id: String, purchase_token: String)
signal payment_purchase_cancelled(product_id: String)
signal payment_purchase_error(product_id: String, message: String)
signal unprocessed_purchase_found(product_id: String, purchase_token: String)
signal unprocessed_purchase_check_completed
signal unprocessed_purchase_check_error(message: String)

# ── Cloud save signals ────────────────────────────────────────────────────────
signal cloud_save_loaded(data: Dictionary)
signal cloud_save_load_error(message: String)
signal cloud_save_completed
signal cloud_save_error(message: String)
signal cloud_save_deleted
signal cloud_save_delete_error(message: String)

# ── Platform lifecycle signals ────────────────────────────────────────────────
signal platform_pause_requested
signal platform_resume_requested

var _impl: Node


func _ready() -> void:
	if OS.has_feature("web"):
		_impl = preload("res://scripts/platform/WebYandexPlatform.gd").new()
		add_child(_impl)
		_connect_yandex_bridge_signals()
	elif OS.has_feature("android"):
		_impl = preload("res://scripts/platform/AndroidRuStorePlatform.gd").new()
		add_child(_impl)
		_connect_impl_signals()
	else:
		_impl = preload("res://scripts/platform/LocalDebugPlatform.gd").new()
		add_child(_impl)
		_connect_impl_signals()


func _connect_yandex_bridge_signals() -> void:
	# For Web/Yandex: forward YandexBridge signals directly to Platform.
	# WebYandexPlatform handles method calls; YandexBridge owns the signals.
	YandexBridge.rewarded_ad_opened.connect(rewarded_ad_opened.emit)
	YandexBridge.rewarded_ad_rewarded.connect(rewarded_ad_rewarded.emit)
	YandexBridge.rewarded_ad_closed.connect(rewarded_ad_closed.emit)
	YandexBridge.rewarded_ad_error.connect(rewarded_ad_error.emit)

	YandexBridge.fullscreen_ad_opened.connect(fullscreen_ad_opened.emit)
	YandexBridge.fullscreen_ad_closed.connect(fullscreen_ad_closed.emit)
	YandexBridge.fullscreen_ad_error.connect(fullscreen_ad_error.emit)

	YandexBridge.payment_purchase_started.connect(payment_purchase_started.emit)
	YandexBridge.payment_purchase_success.connect(payment_purchase_success.emit)
	YandexBridge.payment_purchase_cancelled.connect(payment_purchase_cancelled.emit)
	YandexBridge.payment_purchase_error.connect(payment_purchase_error.emit)
	YandexBridge.unprocessed_purchase_found.connect(unprocessed_purchase_found.emit)
	YandexBridge.unprocessed_purchase_check_completed.connect(unprocessed_purchase_check_completed.emit)
	YandexBridge.unprocessed_purchase_check_error.connect(unprocessed_purchase_check_error.emit)

	YandexBridge.cloud_save_loaded.connect(cloud_save_loaded.emit)
	YandexBridge.cloud_save_load_error.connect(cloud_save_load_error.emit)
	YandexBridge.cloud_save_completed.connect(cloud_save_completed.emit)
	YandexBridge.cloud_save_error.connect(cloud_save_error.emit)
	YandexBridge.cloud_save_deleted.connect(cloud_save_deleted.emit)
	YandexBridge.cloud_save_delete_error.connect(cloud_save_delete_error.emit)

	YandexBridge.platform_pause_requested.connect(platform_pause_requested.emit)
	YandexBridge.platform_resume_requested.connect(platform_resume_requested.emit)


func _connect_impl_signals() -> void:
	# For non-web impls: forward their own signals to Platform.
	_impl.rewarded_ad_opened.connect(rewarded_ad_opened.emit)
	_impl.rewarded_ad_rewarded.connect(rewarded_ad_rewarded.emit)
	_impl.rewarded_ad_closed.connect(rewarded_ad_closed.emit)
	_impl.rewarded_ad_error.connect(rewarded_ad_error.emit)

	_impl.fullscreen_ad_opened.connect(fullscreen_ad_opened.emit)
	_impl.fullscreen_ad_closed.connect(fullscreen_ad_closed.emit)
	_impl.fullscreen_ad_error.connect(fullscreen_ad_error.emit)

	_impl.payment_purchase_started.connect(payment_purchase_started.emit)
	_impl.payment_purchase_success.connect(payment_purchase_success.emit)
	_impl.payment_purchase_cancelled.connect(payment_purchase_cancelled.emit)
	_impl.payment_purchase_error.connect(payment_purchase_error.emit)
	_impl.unprocessed_purchase_found.connect(unprocessed_purchase_found.emit)
	_impl.unprocessed_purchase_check_completed.connect(unprocessed_purchase_check_completed.emit)
	_impl.unprocessed_purchase_check_error.connect(unprocessed_purchase_check_error.emit)

	_impl.cloud_save_loaded.connect(cloud_save_loaded.emit)
	_impl.cloud_save_load_error.connect(cloud_save_load_error.emit)
	_impl.cloud_save_completed.connect(cloud_save_completed.emit)
	_impl.cloud_save_error.connect(cloud_save_error.emit)
	_impl.cloud_save_deleted.connect(cloud_save_deleted.emit)
	_impl.cloud_save_delete_error.connect(cloud_save_delete_error.emit)

	_impl.platform_pause_requested.connect(platform_pause_requested.emit)
	_impl.platform_resume_requested.connect(platform_resume_requested.emit)


# ── Lifecycle ─────────────────────────────────────────────────────────────────

func game_ready() -> void:
	_impl.game_ready()


func gameplay_start(attempt: int = 0) -> void:
	_impl.gameplay_start(attempt)


func gameplay_stop() -> void:
	_impl.gameplay_stop()


# ── Ads ───────────────────────────────────────────────────────────────────────

func is_ad_in_progress() -> bool:
	return _impl.is_ad_in_progress()


func show_rewarded_ad(placement_id: String = "") -> void:
	_impl.show_rewarded_ad(placement_id)


func show_fullscreen_ad(placement_id: String = "") -> void:
	_impl.show_fullscreen_ad(placement_id)


# ── Payments ──────────────────────────────────────────────────────────────────

func purchase_product(platform_product_id: String, local_product_id: String = "") -> void:
	_impl.purchase_product(platform_product_id, local_product_id)


func consume_purchase(purchase_token: String) -> void:
	_impl.consume_purchase(purchase_token)


func check_unprocessed_purchases() -> void:
	_impl.check_unprocessed_purchases()


# ── Cloud save ────────────────────────────────────────────────────────────────

func is_cloud_save_available() -> bool:
	return _impl.is_cloud_save_available()


func load_cloud_save() -> void:
	_impl.load_cloud_save()


func save_cloud_save(data: Dictionary, flush: bool = false) -> void:
	_impl.save_cloud_save(data, flush)


func delete_cloud_save() -> void:
	_impl.delete_cloud_save()


# ── Platform info ─────────────────────────────────────────────────────────────

func get_platform_language() -> String:
	return _impl.get_platform_language()


func refresh_platform_ready() -> bool:
	return _impl.refresh_platform_ready()


func get_platform_event_debug_state() -> Dictionary:
	return _impl.get_platform_event_debug_state()
