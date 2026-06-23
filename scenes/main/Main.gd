extends Control

func _ready() -> void:
	var clicker_screen: Node = get_node_or_null("ClickerScreen")
	if not is_instance_valid(clicker_screen) or not clicker_screen.has_signal("startup_completed"):
		push_warning("Main: ClickerScreen startup_completed not found — calling game_ready as fallback")
		await get_tree().process_frame
		Platform.game_ready()
		return
	if clicker_screen.has_method("is_startup_completed") and clicker_screen.is_startup_completed():
		if clicker_screen.has_method("notify_yandex_game_ready"):
			clicker_screen.notify_yandex_game_ready()
		else:
			Platform.game_ready()
		return
	await clicker_screen.startup_completed
	if clicker_screen.has_method("notify_yandex_game_ready"):
		clicker_screen.notify_yandex_game_ready()
	else:
		Platform.game_ready()
