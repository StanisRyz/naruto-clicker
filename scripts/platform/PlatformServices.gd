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

# ── Backend auth/save signals ─────────────────────────────────────────────────
@warning_ignore("unused_signal")
signal backend_auth_changed(auth_data: Dictionary)
@warning_ignore("unused_signal")
signal backend_operation_succeeded(operation: String, response: Dictionary)
@warning_ignore("unused_signal")
signal backend_operation_failed(operation: String, error_code: String, status_code: int, response: Dictionary)

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

# ── Backend auth/save ─────────────────────────────────────────────────────────

func configure_backend_client(_base_url: String = "") -> void:
	pass

func backend_has_session() -> bool:
	return false

func backend_get_email() -> String:
	return ""

func backend_is_email_verified() -> bool:
	return false

func backend_register(_email: String, _password: String) -> bool:
	backend_operation_failed.emit("register", "not_supported", 0, {})
	return false

func backend_login(_email: String, _password: String) -> bool:
	backend_operation_failed.emit("login", "not_supported", 0, {})
	return false

func backend_logout() -> bool:
	backend_operation_failed.emit("logout", "not_supported", 0, {})
	return false

func backend_get_me() -> bool:
	backend_operation_failed.emit("get_me", "not_supported", 0, {})
	return false

func backend_request_password_reset(_email: String) -> bool:
	backend_operation_failed.emit("request_password_reset", "not_supported", 0, {})
	return false

func backend_confirm_password_reset(_email: String, _code: String, _new_password: String) -> bool:
	backend_operation_failed.emit("confirm_password_reset", "not_supported", 0, {})
	return false

func backend_request_email_verification() -> bool:
	backend_operation_failed.emit("request_email_verification", "not_supported", 0, {})
	return false

func backend_confirm_email_verification(_code: String) -> bool:
	backend_operation_failed.emit("confirm_email_verification", "not_supported", 0, {})
	return false

func backend_load_save() -> bool:
	backend_operation_failed.emit("load_save", "not_supported", 0, {})
	return false

func backend_save_save(_save_data: Dictionary) -> bool:
	backend_operation_failed.emit("save_save", "not_supported", 0, {})
	return false

func backend_delete_save() -> bool:
	backend_operation_failed.emit("delete_save", "not_supported", 0, {})
	return false
