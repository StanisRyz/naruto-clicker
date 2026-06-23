extends "res://scripts/platform/PlatformServices.gd"

# Safe Android placeholder. No real RuStore Pay or Ads SDK calls.
# Ad methods emit clean error callbacks; payment methods emit cancel/error.
# Cloud save is unavailable. Lifecycle methods are no-ops.
# Extend this class with RuStore Pay SDK and Android Ads SDK when ready.

func game_ready() -> void:
	pass


func gameplay_start(_attempt: int = 0) -> void:
	pass


func gameplay_stop() -> void:
	pass


func is_ad_in_progress() -> bool:
	return false


func show_rewarded_ad(_placement_id: String = "") -> void:
	rewarded_ad_error.emit("Rewarded ads not available (RuStore Ads not integrated)")


func show_fullscreen_ad(_placement_id: String = "") -> void:
	fullscreen_ad_error.emit("Fullscreen ads not available (RuStore Ads not integrated)")


func purchase_product(platform_product_id: String, local_product_id: String = "") -> void:
	var id: String = local_product_id if local_product_id != "" else platform_product_id
	payment_purchase_started.emit(id)
	payment_purchase_error.emit(id, "Payments not available (RuStore Pay not integrated)")


func consume_purchase(_purchase_token: String) -> void:
	pass


func check_unprocessed_purchases() -> void:
	unprocessed_purchase_check_completed.emit()


func is_cloud_save_available() -> bool:
	return false


func load_cloud_save() -> void:
	cloud_save_loaded.emit({})


func save_cloud_save(_data: Dictionary, _flush: bool = false) -> void:
	pass


func delete_cloud_save() -> void:
	cloud_save_deleted.emit()


func get_platform_language() -> String:
	return ""


func refresh_platform_ready() -> bool:
	return false


func get_platform_event_debug_state() -> Dictionary:
	return {}
