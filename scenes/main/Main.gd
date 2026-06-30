extends Control

# Startup root.
#
# Android: AuthGateScreen is shown first. ClickerScreen is instantiated only
# after auth_gate_completed fires, so ClickerScreen._ready() (which loads save
# and initializes gameplay) never runs before the auth/guest decision.
#
# Web / Editor: ClickerScreen is instantiated immediately in _ready().
# No AuthGate. Startup behavior is unchanged.

const AuthGateScreenScene = preload("res://scenes/auth/AuthGateScreen.tscn")
const ClickerScreenScene = preload("res://scenes/game/ClickerScreen.tscn")

var _auth_gate: Node = null
var _clicker_screen: Node = null
var _startup_started: bool = false
var _startup_auth_mode: String = ""
var _startup_auth_source: String = ""


func _ready() -> void:
	if _should_show_android_auth_gate():
		_show_auth_gate()
	else:
		_start_game_after_auth_gate("web_or_local")


func _should_show_android_auth_gate() -> bool:
	return OS.has_feature("android")


func _show_auth_gate() -> void:
	_auth_gate = AuthGateScreenScene.instantiate()
	add_child(_auth_gate)
	if _auth_gate is Control:
		(_auth_gate as Control).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		(_auth_gate as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		(_auth_gate as Control).size_flags_vertical = Control.SIZE_EXPAND_FILL
	_auth_gate.auth_gate_completed.connect(_on_auth_gate_completed)


func _on_auth_gate_completed(source: String) -> void:
	if is_instance_valid(_auth_gate):
		_auth_gate.queue_free()
		_auth_gate = null
	var auth_mode: String = "guest" if source == "guest" else "account"
	_startup_auth_source = source
	if _startup_started:
		_startup_auth_mode = auth_mode
		if is_instance_valid(_clicker_screen):
			match source:
				"account_register":
					if _clicker_screen.has_method("on_account_registered_from_guest_overlay"):
						_clicker_screen.on_account_registered_from_guest_overlay()
				"account_login":
					if _clicker_screen.has_method("on_account_login_from_guest_overlay"):
						_clicker_screen.on_account_login_from_guest_overlay()
				"account_session":
					if _clicker_screen.has_method("request_backend_cloud_restore_check"):
						_clicker_screen.request_backend_cloud_restore_check("auth_overlay")
	else:
		_start_game_after_auth_gate(auth_mode)


func show_auth_gate_overlay() -> bool:
	if not OS.has_feature("android"):
		return false
	if is_instance_valid(_auth_gate):
		return false
	_auth_gate = AuthGateScreenScene.instantiate()
	add_child(_auth_gate)
	if _auth_gate is Control:
		(_auth_gate as Control).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		(_auth_gate as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		(_auth_gate as Control).size_flags_vertical = Control.SIZE_EXPAND_FILL
	_auth_gate.auth_gate_completed.connect(_on_auth_gate_completed)
	return true


func _start_game_after_auth_gate(mode: String) -> void:
	if _startup_started:
		return
	_startup_started = true
	_startup_auth_mode = mode
	_instantiate_clicker_screen()
	_begin_startup_wait()


func _instantiate_clicker_screen() -> void:
	if is_instance_valid(_clicker_screen):
		return
	_clicker_screen = ClickerScreenScene.instantiate()
	_clicker_screen.name = "ClickerScreen"
	if _clicker_screen.has_method("set_startup_auth_mode"):
		_clicker_screen.set_startup_auth_mode(_startup_auth_mode)
	if _clicker_screen.has_method("set_startup_auth_source"):
		_clicker_screen.set_startup_auth_source(_startup_auth_source)
	add_child(_clicker_screen)


func get_startup_auth_mode() -> String:
	return _startup_auth_mode


func _begin_startup_wait() -> void:
	var cs: Node = _clicker_screen if is_instance_valid(_clicker_screen) else get_node_or_null("ClickerScreen")
	if not is_instance_valid(cs) or not cs.has_signal("startup_completed"):
		push_warning("Main: ClickerScreen startup_completed not found — calling game_ready as fallback")
		await get_tree().process_frame
		Platform.game_ready()
		return
	if cs.has_method("is_startup_completed") and cs.is_startup_completed():
		if cs.has_method("notify_yandex_game_ready"):
			cs.notify_yandex_game_ready()
		else:
			Platform.game_ready()
		return
	await cs.startup_completed
	if cs.has_method("notify_yandex_game_ready"):
		cs.notify_yandex_game_ready()
	else:
		Platform.game_ready()
