extends "res://scripts/platform/PlatformServices.gd"

# Forwards all platform calls to YandexBridge.
# Signal forwarding is done by Platform.gd (which wires YandexBridge signals
# directly to Platform signals, bypassing this node).

func game_ready() -> void:
	YandexBridge.game_ready()


func gameplay_start(attempt: int = 0) -> void:
	YandexBridge.gameplay_start(attempt)


func gameplay_stop() -> void:
	YandexBridge.gameplay_stop()


func is_ad_in_progress() -> bool:
	return YandexBridge.is_ad_in_progress()


func show_rewarded_ad(_placement_id: String = "") -> void:
	YandexBridge.show_rewarded_ad()


func show_fullscreen_ad(_placement_id: String = "") -> void:
	YandexBridge.show_fullscreen_ad()


func purchase_product(platform_product_id: String, local_product_id: String = "") -> void:
	YandexBridge.purchase_product(platform_product_id, local_product_id)


func consume_purchase(purchase_token: String) -> void:
	YandexBridge.consume_purchase(purchase_token)


func check_unprocessed_purchases() -> void:
	YandexBridge.check_unprocessed_purchases()


func is_cloud_save_available() -> bool:
	return YandexBridge.is_cloud_save_available()


func load_cloud_save() -> void:
	YandexBridge.load_cloud_save()


func save_cloud_save(data: Dictionary, flush: bool = false) -> void:
	YandexBridge.save_cloud_save(data, flush)


func delete_cloud_save() -> void:
	YandexBridge.delete_cloud_save()


func get_platform_language() -> String:
	return YandexBridge.get_yandex_language()


func refresh_platform_ready() -> bool:
	return YandexBridge.refresh_yandex_sdk_ready()


func get_platform_event_debug_state() -> Dictionary:
	return YandexBridge.get_platform_event_debug_state()
