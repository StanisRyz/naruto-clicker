extends "res://scripts/platform/PlatformServices.gd"

# Editor / local / non-platform build.
# Debug builds simulate ad and payment success so flows can be tested locally.
# Release builds emit error callbacks and grant nothing, matching the safety
# contract required for production (no real SDK available, no real grants).

var _rewarded_ad_in_progress: bool = false
var _fullscreen_ad_in_progress: bool = false


func game_ready() -> void:
	pass


func gameplay_start(_attempt: int = 0) -> void:
	pass


func gameplay_stop() -> void:
	pass


func is_ad_in_progress() -> bool:
	return _rewarded_ad_in_progress or _fullscreen_ad_in_progress


func show_rewarded_ad(_placement_id: String = "") -> void:
	if _rewarded_ad_in_progress:
		return
	_rewarded_ad_in_progress = true
	if BuildConfig.is_debug_features_enabled():
		_simulate_rewarded_ad()
	else:
		_rewarded_ad_in_progress = false
		rewarded_ad_error.emit("Rewarded ad unavailable outside platform")


func _simulate_rewarded_ad() -> void:
	rewarded_ad_opened.emit()
	await Engine.get_main_loop().create_timer(0.5).timeout
	rewarded_ad_rewarded.emit()
	await Engine.get_main_loop().create_timer(0.1).timeout
	_rewarded_ad_in_progress = false
	rewarded_ad_closed.emit(true)


func show_fullscreen_ad(_placement_id: String = "") -> void:
	if _fullscreen_ad_in_progress:
		return
	_fullscreen_ad_in_progress = true
	if BuildConfig.is_debug_features_enabled():
		_simulate_fullscreen_ad()
	else:
		_fullscreen_ad_in_progress = false
		fullscreen_ad_error.emit("Fullscreen ad unavailable outside platform")


func _simulate_fullscreen_ad() -> void:
	fullscreen_ad_opened.emit()
	await Engine.get_main_loop().create_timer(0.5).timeout
	_fullscreen_ad_in_progress = false
	fullscreen_ad_closed.emit(true)


func purchase_product(platform_product_id: String, local_product_id: String = "") -> void:
	var id: String = local_product_id if local_product_id != "" else platform_product_id
	payment_purchase_started.emit(id)
	if BuildConfig.is_debug_features_enabled():
		_simulate_payment(id)
	else:
		payment_purchase_error.emit(id, "Payments unavailable outside platform")


func _simulate_payment(local_product_id: String) -> void:
	await Engine.get_main_loop().create_timer(0.5).timeout
	payment_purchase_success.emit(local_product_id, "debug_token_%d" % Time.get_ticks_usec())


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
