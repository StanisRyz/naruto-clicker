extends Control

# Startup root. On Android, shows AuthGateScreen before gameplay begins.
# Web/editor: unchanged — proceeds directly to startup wait.

const AuthGateScreenScene = preload("res://scenes/auth/AuthGateScreen.tscn")

var _auth_gate: Node = null


func _ready() -> void:
	if _should_show_android_auth_gate():
		_show_auth_gate()
	else:
		_begin_startup_wait()


func _should_show_android_auth_gate() -> bool:
	return OS.has_feature("android")


func _show_auth_gate() -> void:
	_auth_gate = AuthGateScreenScene.instantiate()
	add_child(_auth_gate)
	_auth_gate.auth_gate_completed.connect(_on_auth_gate_completed)


func _on_auth_gate_completed(_mode: String) -> void:
	if is_instance_valid(_auth_gate):
		_auth_gate.queue_free()
		_auth_gate = null
	_begin_startup_wait()


func _begin_startup_wait() -> void:
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
