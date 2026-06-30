class_name AuthGateScreen
extends Control

# Auth gate shown on Android startup before gameplay.
# Calls backend only through Platform. Never calls BackendApiClient directly.
# Never calls SaveManager.
# Emits:
# - "guest"          — user tapped Continue as Guest
# - "account_session" — stored session get_me succeeded
# - "account_login"   — user entered credentials and login succeeded
# - "account_register" — user registered and post-register login succeeded

signal auth_gate_completed(mode: String)

enum _State {
	CHECKING,
	LOGIN,
	REGISTER,
	RESET_REQUEST,
	RESET_CONFIRM,
}

# ── UI refs ───────────────────────────────────────────────────────────────────

var _status_label: Label
var _checking_box: VBoxContainer
var _login_box: VBoxContainer
var _register_box: VBoxContainer
var _reset_request_box: VBoxContainer
var _reset_confirm_box: VBoxContainer
var _guest_button: Button

var _login_email: LineEdit
var _login_password: LineEdit

var _reg_email: LineEdit
var _reg_password: LineEdit
var _reg_confirm: LineEdit

var _reset_req_email: LineEdit

var _reset_conf_email: LineEdit
var _reset_conf_code: LineEdit
var _reset_conf_new_pass: LineEdit
var _reset_conf_confirm: LineEdit

# ── State ─────────────────────────────────────────────────────────────────────

var _current_state: _State = _State.CHECKING
var _post_register_email: String = ""
var _post_register_password: String = ""
var _reset_email_cache: String = ""
var _awaiting_login_after_register: bool = false

var _session_check_generation: int = 0
var _session_check_completed: bool = false
var _request_in_progress: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	z_index = 1000
	mouse_filter = Control.MOUSE_FILTER_STOP
	if BuildConfig.IS_DEBUG_BUILD:
		print("AuthGateScreen: building UI")
	_build_ui()
	if not _is_ui_built():
		_show_fallback_error("Auth UI failed to initialize")
		return
	if BuildConfig.IS_DEBUG_BUILD:
		print("AuthGateScreen: UI ready, root size=", size)
	_connect_platform_signals()
	_check_existing_session()


func _exit_tree() -> void:
	if is_instance_valid(Platform):
		if Platform.backend_operation_succeeded.is_connected(_on_backend_succeeded):
			Platform.backend_operation_succeeded.disconnect(_on_backend_succeeded)
		if Platform.backend_operation_failed.is_connected(_on_backend_failed):
			Platform.backend_operation_failed.disconnect(_on_backend_failed)

# ── UI construction ───────────────────────────────────────────────────────────

func _build_ui() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.88)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(margin)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_child(center)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.10, 0.105, 0.125, 1.0)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = Color(0.26, 0.28, 0.34, 1.0)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.content_margin_left = 24
	panel_style.content_margin_right = 24
	panel_style.content_margin_top = 28
	panel_style.content_margin_bottom = 28

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(340, 520)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", panel_style)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title_label := Label.new()
	title_label.text = LocalizationManager.tr_key("auth.title")
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
	vbox.add_child(title_label)

	if BuildConfig.IS_DEBUG_BUILD:
		print("AuthGateScreen: panel min size=", panel.custom_minimum_size)

	_status_label = Label.new()
	_status_label.text = ""
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 13)
	_status_label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.35, 1.0))
	_status_label.visible = false
	vbox.add_child(_status_label)

	_checking_box = _build_checking_box()
	vbox.add_child(_checking_box)

	_login_box = _build_login_box()
	_login_box.visible = false
	vbox.add_child(_login_box)

	_register_box = _build_register_box()
	_register_box.visible = false
	vbox.add_child(_register_box)

	_reset_request_box = _build_reset_request_box()
	_reset_request_box.visible = false
	vbox.add_child(_reset_request_box)

	_reset_confirm_box = _build_reset_confirm_box()
	_reset_confirm_box.visible = false
	vbox.add_child(_reset_confirm_box)

	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 6)
	vbox.add_child(sep)

	_guest_button = _make_button(
		LocalizationManager.tr_key("auth.guest_button"),
		_on_guest_pressed
	)
	_guest_button.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	_guest_button.visible = false
	vbox.add_child(_guest_button)

	var guest_warning := Label.new()
	guest_warning.text = LocalizationManager.tr_key("auth.guest_warning")
	guest_warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guest_warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guest_warning.add_theme_font_size_override("font_size", 11)
	guest_warning.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55, 1.0))
	guest_warning.visible = false
	vbox.add_child(guest_warning)

	_guest_button.set_meta("warning_label", guest_warning)


func _is_ui_built() -> bool:
	return _checking_box != null and _login_box != null and _register_box != null


func _show_fallback_error(message: String) -> void:
	var label := Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(label)


func _try_set_virtual_keyboard_type(edit: LineEdit, keyboard_type: int) -> void:
	if edit == null:
		return
	if "virtual_keyboard_type" in edit:
		edit.set("virtual_keyboard_type", keyboard_type)


func _build_checking_box() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	var lbl := Label.new()
	lbl.text = LocalizationManager.tr_key("auth.checking_account")
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
	box.add_child(lbl)
	return box


func _build_login_box() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)

	_login_email = _make_line_edit(LocalizationManager.tr_key("auth.email_placeholder"))
	_try_set_virtual_keyboard_type(_login_email, LineEdit.KEYBOARD_TYPE_EMAIL_ADDRESS)
	box.add_child(_login_email)

	_login_password = _make_line_edit(LocalizationManager.tr_key("auth.password_placeholder"))
	_login_password.secret = true
	box.add_child(_login_password)

	var submit := _make_button(LocalizationManager.tr_key("auth.login_button"), _on_login_submit)
	box.add_child(submit)

	var forgot := _make_flat_button(LocalizationManager.tr_key("auth.forgot_password_button"), _on_forgot_pressed)
	box.add_child(forgot)

	var to_reg := _make_flat_button(LocalizationManager.tr_key("auth.register_tab"), _on_to_register_pressed)
	box.add_child(to_reg)

	return box


func _build_register_box() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)

	_reg_email = _make_line_edit(LocalizationManager.tr_key("auth.email_placeholder"))
	_try_set_virtual_keyboard_type(_reg_email, LineEdit.KEYBOARD_TYPE_EMAIL_ADDRESS)
	box.add_child(_reg_email)

	_reg_password = _make_line_edit(LocalizationManager.tr_key("auth.password_placeholder"))
	_reg_password.secret = true
	box.add_child(_reg_password)

	_reg_confirm = _make_line_edit(LocalizationManager.tr_key("auth.confirm_password_placeholder"))
	_reg_confirm.secret = true
	box.add_child(_reg_confirm)

	var submit := _make_button(LocalizationManager.tr_key("auth.register_button"), _on_register_submit)
	box.add_child(submit)

	var to_login := _make_flat_button(LocalizationManager.tr_key("auth.login_tab"), _on_to_login_pressed)
	box.add_child(to_login)

	return box


func _build_reset_request_box() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)

	var title_lbl := Label.new()
	title_lbl.text = LocalizationManager.tr_key("auth.reset_title")
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 16)
	box.add_child(title_lbl)

	_reset_req_email = _make_line_edit(LocalizationManager.tr_key("auth.email_placeholder"))
	_try_set_virtual_keyboard_type(_reset_req_email, LineEdit.KEYBOARD_TYPE_EMAIL_ADDRESS)
	box.add_child(_reset_req_email)

	var submit := _make_button(LocalizationManager.tr_key("auth.reset_request_button"), _on_reset_request_submit)
	box.add_child(submit)

	var back := _make_flat_button(LocalizationManager.tr_key("auth.back_to_login_button"), _on_back_to_login)
	box.add_child(back)

	return box


func _build_reset_confirm_box() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)

	var title_lbl := Label.new()
	title_lbl.text = LocalizationManager.tr_key("auth.reset_title")
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 16)
	box.add_child(title_lbl)

	_reset_conf_email = _make_line_edit(LocalizationManager.tr_key("auth.email_placeholder"))
	_try_set_virtual_keyboard_type(_reset_conf_email, LineEdit.KEYBOARD_TYPE_EMAIL_ADDRESS)
	box.add_child(_reset_conf_email)

	_reset_conf_code = _make_line_edit(LocalizationManager.tr_key("auth.reset_code_placeholder"))
	_reset_conf_code.max_length = 6
	box.add_child(_reset_conf_code)

	_reset_conf_new_pass = _make_line_edit(LocalizationManager.tr_key("auth.new_password_placeholder"))
	_reset_conf_new_pass.secret = true
	box.add_child(_reset_conf_new_pass)

	_reset_conf_confirm = _make_line_edit(LocalizationManager.tr_key("auth.confirm_password_placeholder"))
	_reset_conf_confirm.secret = true
	box.add_child(_reset_conf_confirm)

	var submit := _make_button(LocalizationManager.tr_key("auth.reset_confirm_button"), _on_reset_confirm_submit)
	box.add_child(submit)

	var back := _make_flat_button(LocalizationManager.tr_key("auth.back_to_login_button"), _on_back_to_login)
	box.add_child(back)

	return box


func _make_line_edit(placeholder: String) -> LineEdit:
	var edit := LineEdit.new()
	edit.placeholder_text = placeholder
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.custom_minimum_size = Vector2(0, 44)
	return edit


func _make_button(label_text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 48)
	btn.pressed.connect(callback)
	return btn


func _make_flat_button(label_text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.flat = true
	btn.pressed.connect(callback)
	return btn

# ── State machine ─────────────────────────────────────────────────────────────

func _set_state(state: _State) -> void:
	_current_state = state
	if BuildConfig.IS_DEBUG_BUILD:
		print("AuthGateScreen: state=", state)
	if _checking_box != null:
		_checking_box.visible = (state == _State.CHECKING)
	if _login_box != null:
		_login_box.visible = (state == _State.LOGIN)
	if _register_box != null:
		_register_box.visible = (state == _State.REGISTER)
	if _reset_request_box != null:
		_reset_request_box.visible = (state == _State.RESET_REQUEST)
	if _reset_confirm_box != null:
		_reset_confirm_box.visible = (state == _State.RESET_CONFIRM)

	var show_guest := state in [_State.LOGIN, _State.REGISTER, _State.RESET_REQUEST, _State.RESET_CONFIRM]
	if _guest_button != null:
		_guest_button.visible = show_guest
		var warning_label: Label = _guest_button.get_meta("warning_label") as Label
		if is_instance_valid(warning_label):
			warning_label.visible = show_guest


func _show_status(text: String, is_error: bool = false) -> void:
	_status_label.text = text
	_status_label.visible = (text != "")
	if is_error:
		_status_label.add_theme_color_override("font_color", Color(0.9, 0.35, 0.35, 1.0))
	else:
		_status_label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.35, 1.0))


func _clear_status() -> void:
	_status_label.text = ""
	_status_label.visible = false

# ── Platform signals ──────────────────────────────────────────────────────────

func _connect_platform_signals() -> void:
	if not Platform.backend_operation_succeeded.is_connected(_on_backend_succeeded):
		Platform.backend_operation_succeeded.connect(_on_backend_succeeded)
	if not Platform.backend_operation_failed.is_connected(_on_backend_failed):
		Platform.backend_operation_failed.connect(_on_backend_failed)


func _on_backend_succeeded(operation: String, _response: Dictionary) -> void:
	match operation:
		"get_me":
			_session_check_completed = true
			_clear_status()
			auth_gate_completed.emit("account_session")

		"login":
			_request_in_progress = false
			_clear_status()
			var was_post_register := _awaiting_login_after_register
			if _awaiting_login_after_register:
				_awaiting_login_after_register = false
				_post_register_email = ""
				_post_register_password = ""
			auth_gate_completed.emit("account_register" if was_post_register else "account_login")

		"register":
			_clear_status()
			if _post_register_email != "" and _post_register_password != "":
				_awaiting_login_after_register = true
				Platform.backend_login(_post_register_email, _post_register_password)
			else:
				_request_in_progress = false
				_set_state(_State.LOGIN)
				_show_status(LocalizationManager.tr_key("auth.login_tab"))

		"request_password_reset":
			_request_in_progress = false
			_show_status(LocalizationManager.tr_key("auth.status_reset_code_sent"))
			_reset_conf_email.text = _reset_email_cache
			_set_state(_State.RESET_CONFIRM)

		"confirm_password_reset":
			_request_in_progress = false
			_show_status(LocalizationManager.tr_key("auth.status_password_changed"))
			_set_state(_State.LOGIN)
			_show_status(LocalizationManager.tr_key("auth.status_login_after_reset"))


func _on_backend_failed(operation: String, error_code: String, _status_code: int, _response: Dictionary) -> void:
	match operation:
		"get_me":
			_session_check_completed = true
			if error_code in ["unauthorized", "missing_session"]:
				Platform.backend_clear_local_auth()
			_show_status(LocalizationManager.tr_key("auth.status_checking_failed"), true)
			_set_state(_State.LOGIN)

		"login":
			_request_in_progress = false
			_awaiting_login_after_register = false
			_show_status(error_code, true)

		"register":
			_request_in_progress = false
			_post_register_email = ""
			_post_register_password = ""
			_show_status(error_code, true)

		"request_password_reset":
			_request_in_progress = false
			_show_status(error_code, true)

		"confirm_password_reset":
			_request_in_progress = false
			_show_status(error_code, true)

# ── Startup session check ─────────────────────────────────────────────────────

func _check_existing_session() -> void:
	if Platform.backend_has_session():
		_session_check_generation += 1
		_session_check_completed = false
		var generation := _session_check_generation
		_set_state(_State.CHECKING)
		Platform.backend_get_me()
		_start_session_check_timeout(generation)
	else:
		_set_state(_State.LOGIN)


func _start_session_check_timeout(generation: int) -> void:
	await get_tree().create_timer(6.0).timeout
	if generation != _session_check_generation:
		return
	if _session_check_completed:
		return
	if _current_state != _State.CHECKING:
		return
	Platform.backend_clear_local_auth()
	_show_status(LocalizationManager.tr_key("auth.status_checking_failed"), true)
	_set_state(_State.LOGIN)

# ── Button callbacks ──────────────────────────────────────────────────────────

func _on_login_submit() -> void:
	if _request_in_progress:
		return
	var email := _login_email.text.strip_edges()
	var password := _login_password.text
	if not _validate_email(email):
		return
	if not _validate_password(password):
		return
	_request_in_progress = true
	_clear_status()
	Platform.backend_login(email, password)


func _on_register_submit() -> void:
	if _request_in_progress:
		return
	var email := _reg_email.text.strip_edges()
	var password := _reg_password.text
	var confirm := _reg_confirm.text
	if not _validate_email(email):
		return
	if not _validate_password(password):
		return
	if password != confirm:
		_show_status(LocalizationManager.tr_key("auth.error_password_mismatch"), true)
		return
	_request_in_progress = true
	_clear_status()
	_post_register_email = email
	_post_register_password = password
	Platform.backend_register(email, password)


func _on_forgot_pressed() -> void:
	if _request_in_progress:
		return
	_clear_status()
	_reset_req_email.text = _login_email.text.strip_edges()
	_reset_email_cache = _reset_req_email.text
	_set_state(_State.RESET_REQUEST)


func _on_reset_request_submit() -> void:
	if _request_in_progress:
		return
	var email := _reset_req_email.text.strip_edges()
	if not _validate_email(email):
		return
	_request_in_progress = true
	_clear_status()
	_reset_email_cache = email
	Platform.backend_request_password_reset(email)


func _on_reset_confirm_submit() -> void:
	if _request_in_progress:
		return
	var email := _reset_conf_email.text.strip_edges()
	var code := _reset_conf_code.text.strip_edges()
	var new_pass := _reset_conf_new_pass.text
	var confirm := _reset_conf_confirm.text
	if not _validate_email(email):
		return
	if not _validate_reset_code(code):
		return
	if not _validate_password(new_pass):
		return
	if new_pass != confirm:
		_show_status(LocalizationManager.tr_key("auth.error_password_mismatch"), true)
		return
	_request_in_progress = true
	_clear_status()
	Platform.backend_confirm_password_reset(email, code, new_pass)


func _on_to_register_pressed() -> void:
	if _request_in_progress:
		return
	_clear_status()
	_reg_email.text = _login_email.text.strip_edges()
	_set_state(_State.REGISTER)


func _on_to_login_pressed() -> void:
	if _request_in_progress:
		return
	_clear_status()
	_login_email.text = _reg_email.text.strip_edges()
	_set_state(_State.LOGIN)


func _on_back_to_login() -> void:
	if _request_in_progress:
		return
	_clear_status()
	_set_state(_State.LOGIN)


func _on_guest_pressed() -> void:
	if _request_in_progress:
		return
	_show_status(LocalizationManager.tr_key("auth.status_guest_mode"))
	auth_gate_completed.emit("guest")

# ── Validation ────────────────────────────────────────────────────────────────

func _validate_email(email: String) -> bool:
	if email == "":
		_show_status(LocalizationManager.tr_key("auth.error_email_required"), true)
		return false
	return true


func _validate_password(password: String) -> bool:
	if password.length() < 8:
		_show_status(LocalizationManager.tr_key("auth.error_password_short"), true)
		return false
	return true


func _validate_reset_code(code: String) -> bool:
	if code.length() != 6 or not code.is_valid_int():
		_show_status(LocalizationManager.tr_key("auth.error_code_invalid"), true)
		return false
	return true
