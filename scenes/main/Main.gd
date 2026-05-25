extends Control

func _ready() -> void:
	await get_tree().process_frame
	YandexBridge.game_ready()
	YandexBridge.gameplay_start()
