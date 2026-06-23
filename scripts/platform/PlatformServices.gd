extends Node

# Abstract base interface for platform services.
# Signals are declared here so subclasses can emit them without re-declaring.
# The @warning_ignore annotations suppress UNUSED_SIGNAL because GDScript only
# checks the declaring class, not subclasses that emit the signal.

# ── Rewarded ad signals ───────────────────────────────────────────────────────
@warning_ignore("unused_signal")
signal rewarded_ad_opened
@warning_ignore("unused_signal")
signal rewarded_ad_rewarded
@warning_ignore("unused_signal")
signal rewarded_ad_closed(was_shown: bool)
@warning_ignore("unused_signal")
signal rewarded_ad_error(message: String)

# ── Fullscreen ad signals ─────────────────────────────────────────────────────
@warning_ignore("unused_signal")
signal fullscreen_ad_opened
@warning_ignore("unused_signal")
signal fullscreen_ad_closed(was_shown: bool)
@warning_ignore("unused_signal")
signal fullscreen_ad_error(message: String)

# ── Payment signals ───────────────────────────────────────────────────────────
@warning_ignore("unused_signal")
signal payment_purchase_started(product_id: String)
@warning_ignore("unused_signal")
signal payment_purchase_success(product_id: String, purchase_token: String)
@warning_ignore("unused_signal")
signal payment_purchase_cancelled(product_id: String)
@warning_ignore("unused_signal")
signal payment_purchase_error(product_id: String, message: String)
@warning_ignore("unused_signal")
signal unprocessed_purchase_found(product_id: String, purchase_token: String)
@warning_ignore("unused_signal")
signal unprocessed_purchase_check_completed
@warning_ignore("unused_signal")
signal unprocessed_purchase_check_error(message: String)

# ── Cloud save signals ────────────────────────────────────────────────────────
@warning_ignore("unused_signal")
signal cloud_save_loaded(data: Dictionary)
@warning_ignore("unused_signal")
signal cloud_save_load_error(message: String)
@warning_ignore("unused_signal")
signal cloud_save_completed
@warning_ignore("unused_signal")
signal cloud_save_error(message: String)
@warning_ignore("unused_signal")
signal cloud_save_deleted
@warning_ignore("unused_signal")
signal cloud_save_delete_error(message: String)

# ── Platform lifecycle signals ────────────────────────────────────────────────
@warning_ignore("unused_signal")
signal platform_pause_requested
@warning_ignore("unused_signal")
signal platform_resume_requested

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
	pass

func show_fullscreen_ad(_placement_id: String = "") -> void:
	pass

# ── Payments ──────────────────────────────────────────────────────────────────

func purchase_product(_platform_product_id: String, _local_product_id: String = "") -> void:
	pass

func consume_purchase(_purchase_token: String) -> void:
	pass

func check_unprocessed_purchases() -> void:
	pass

# ── Cloud save ────────────────────────────────────────────────────────────────

func is_cloud_save_available() -> bool:
	return false

func load_cloud_save() -> void:
	pass

func save_cloud_save(_data: Dictionary, _flush: bool = false) -> void:
	pass

func delete_cloud_save() -> void:
	pass

# ── Platform info ─────────────────────────────────────────────────────────────

func get_platform_language() -> String:
	return ""

func refresh_platform_ready() -> bool:
	return false

func get_platform_event_debug_state() -> Dictionary:
	return {}

func get_platform_key() -> String:
	return ""
