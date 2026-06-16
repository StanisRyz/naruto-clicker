extends Control

func _ready() -> void:
	var clicker_screen: Node = get_node_or_null("ClickerScreen")
	if not is_instance_valid(clicker_screen) or not clicker_screen.has_signal("startup_completed"):
		push_warning("Main: ClickerScreen startup_completed not found — calling game_ready as fallback")
		await get_tree().process_frame
		YandexBridge.game_ready()
		YandexBridge.gameplay_start()
		return
	await clicker_screen.startup_completed
	YandexBridge.game_ready()
	YandexBridge.gameplay_start()
