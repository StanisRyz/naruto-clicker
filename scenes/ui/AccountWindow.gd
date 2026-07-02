class_name AccountWindow
extends Control

# Detailed Account / Cloud UI (C7.3.2). Split out of SettingsWindow so Settings
# stays compact (Sound/Music/Language/Save/Account/Version). This window owns
# all account status, email verification, and manual cloud save UI and talks
# to Platform/backend directly for its own refresh — ClickerScreen only routes
# the auth/cloud-save *requests* and forwards cloud status/busy updates.

signal account_auth_requested
signal cloud_save_upload_requested

const ImageSlotClass = preload("res://scripts/ui/ImageSlot.gd")

@onready var overlay: ColorRect = $Overlay
@onready var panel_container: PanelContainer = $PanelContainer
# Account panel/background is a fixed-size textured window ("ui.window.settings.background",
# STRETCH_SCALE) — same style/asset as SettingsWindow (C7.2.7). Never resize it dynamically
# based on content. Everything below the header lives in BodyScrollContainer so account/cloud
# content scrolls inside the fixed window instead of growing it.
const BODY_PATH: String = "MarginContainer/VBoxContainer/BodyScrollContainer/BodyVBoxContainer"

@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HeaderMargin/Header/CloseButton
@onready var _title_label: Label = $PanelContainer/MarginContainer/VBoxContainer/HeaderMargin/Header/TitleLabel

const ACTION_BUTTON_SIZE: Vector2 = Vector2(218, 75)

var _account_section: Control = null
var _account_email_label: Label = null
var _account_verification_label: Label = null
var _account_guest_warning_label: Label = null
var _account_sign_in_button: Button = null
var _account_sign_in_button_label: Label = null
var _account_logout_button: Button = null
var _account_logout_button_label: Label = null
var _account_action_label: Label = null
var _account_signals_connected: bool = false
var _account_action_busy: bool = false

var _cloud_section: Control = null
var _cloud_status_label: Label = null
var _cloud_upload_button: Button = null
var _cloud_upload_button_label: Label = null


func _ready() -> void:
	overlay.gui_input.connect(_on_overlay_gui_input)
	panel_container.gui_input.connect(_on_panel_container_gui_input)
	close_button.pressed.connect(_on_close_button_pressed)
	_add_background_image_holder(panel_container, "AccountBackgroundImageHolder", "ui.window.settings.background")
	_make_image_icon_button(close_button, "ui.sheet.close_button")
	LocalizationManager.language_changed.connect(_refresh_static_labels)
	_refresh_static_labels()
	if _is_backend_account_ui_supported():
		_create_account_section()
		_connect_account_platform_signals()
	hide()


func _exit_tree() -> void:
	_disconnect_account_platform_signals()


func _refresh_static_labels() -> void:
	_title_label.text = LocalizationManager.tr_key("settings.account_cloud.title")
	_refresh_account_static_labels()


func show_window() -> void:
	ButtonVisualUtils.set_image_button_asset(close_button, "ui.sheet.close_button")
	_refresh_account_section()
	show()


func hide_window() -> void:
	hide()


func _on_close_button_pressed() -> void:
	ButtonVisualUtils.play_pressed_then_call(
		close_button,
		Callable(self, "hide_window"),
		"ui.sheet.close_button",
		"ui.sheet.close_button.pressed",
		0.2,
		Color.WHITE
	)


func _on_overlay_gui_input(event: InputEvent) -> void:
	if _is_pressed_pointer_event(event):
		hide_window()
		accept_event()


func _on_panel_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		accept_event()


func _is_pressed_pointer_event(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		return mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed
	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		return touch_event.pressed
	return false


func _add_background_image_holder(container: Control, holder_name: String, asset_key: String) -> void:
	var holder = ImageSlotClass.new()
	holder.name = holder_name
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.fallback_color = Color.WHITE
	holder.show_fallback_behind_texture = false
	holder.stretch_mode = TextureRect.STRETCH_SCALE
	container.add_child(holder)
	container.move_child(holder, 0)
	holder.set_asset_key(asset_key, Color.WHITE)


func _make_image_icon_button(button: Button, asset_key: String) -> void:
	ButtonVisualUtils.clear_image_button_styles(button)
	button.text = ""
	var holder = ImageSlotClass.new()
	holder.name = "ButtonImageHolder"
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.fallback_color = Color.WHITE
	holder.show_fallback_behind_texture = false
	holder.stretch_mode = TextureRect.STRETCH_SCALE
	button.add_child(holder)
	holder.set_asset_key(asset_key, Color.WHITE)


func _make_image_button_label(button: Button, asset_key: String, initial_text: String) -> Label:
	_make_image_icon_button(button, asset_key)
	var label := Label.new()
	label.name = "ButtonTextLabel"
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.text = initial_text
	button.add_child(label)
	return label


# ── Account / Cloud section (Android/RuStore-only; moved from SettingsWindow in C7.3.2) ──

func _is_backend_account_ui_supported() -> bool:
	return OS.has_feature("android")


func _create_account_section() -> void:
	# Outer AccountWindow panel keeps its fixed textured size (see BODY_PATH comment
	# above) — account/cloud content is added into the scrollable body, not used to
	# grow the panel.
	var vbox: VBoxContainer = panel_container.get_node(BODY_PATH)

	var account_vbox := VBoxContainer.new()
	account_vbox.add_theme_constant_override("separation", 10)
	vbox.add_child(account_vbox)
	_account_section = account_vbox

	var email_lbl := Label.new()
	email_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	email_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	account_vbox.add_child(email_lbl)
	_account_email_label = email_lbl

	var verif_lbl := Label.new()
	verif_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	account_vbox.add_child(verif_lbl)
	_account_verification_label = verif_lbl

	var guest_warn := Label.new()
	guest_warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guest_warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guest_warn.add_theme_color_override("font_color", Color(0.75, 0.65, 0.35, 1.0))
	account_vbox.add_child(guest_warn)
	_account_guest_warning_label = guest_warn

	var sign_in_btn := Button.new()
	sign_in_btn.custom_minimum_size = ACTION_BUTTON_SIZE
	sign_in_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	sign_in_btn.pressed.connect(_on_account_sign_in_pressed)
	account_vbox.add_child(sign_in_btn)
	_account_sign_in_button = sign_in_btn
	_account_sign_in_button_label = _make_image_button_label(
		sign_in_btn, "ui.popup.button.default",
		LocalizationManager.tr_key("settings.account.sign_in_register")
	)
	UiFontConfig.apply_label_font_size(_account_sign_in_button_label, UiFontConfig.SETTINGS_ACTION_BUTTON_FONT_SIZE)

	_create_cloud_section(account_vbox)

	var logout_btn := Button.new()
	logout_btn.custom_minimum_size = ACTION_BUTTON_SIZE
	logout_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	logout_btn.pressed.connect(_on_account_logout_pressed)
	account_vbox.add_child(logout_btn)
	_account_logout_button = logout_btn
	_account_logout_button_label = _make_image_button_label(
		logout_btn, "ui.popup.button.default",
		LocalizationManager.tr_key("settings.account.logout")
	)
	UiFontConfig.apply_label_font_size(_account_logout_button_label, UiFontConfig.SETTINGS_ACTION_BUTTON_FONT_SIZE)

	var action_lbl := Label.new()
	action_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action_lbl.add_theme_font_size_override("font_size", 13)
	action_lbl.visible = false
	account_vbox.add_child(action_lbl)
	_account_action_label = action_lbl

	_refresh_account_section()


func _refresh_account_static_labels() -> void:
	if _account_section == null:
		return
	if _account_sign_in_button_label != null:
		_account_sign_in_button_label.text = LocalizationManager.tr_key("settings.account.sign_in_register")
	if _account_logout_button_label != null:
		_account_logout_button_label.text = LocalizationManager.tr_key("settings.account.logout")
	_refresh_cloud_static_labels()
	_refresh_account_section()


func _refresh_account_section() -> void:
	if _account_section == null:
		return
	_account_action_label.visible = false
	_account_action_label.text = ""
	_refresh_account_section_state()


# Updates account/cloud visibility and status text from current session data
# without touching the account action message — callers that just showed an
# operation result (success/failure) must use this instead of
# `_refresh_account_section()` so the message is not immediately wiped.
func _refresh_account_section_state() -> void:
	if _account_section == null:
		return
	var has_session := Platform.backend_has_session()
	var email := Platform.backend_get_email()
	var verified := Platform.backend_is_email_verified()

	_account_email_label.text = LocalizationManager.format_key("settings.account.email", {"email": email})
	_account_email_label.visible = has_session
	_account_verification_label.text = (
		LocalizationManager.tr_key("settings.account.email_verified")
		if verified else
		LocalizationManager.tr_key("settings.account.email_not_verified")
	)
	_account_verification_label.visible = has_session
	_account_guest_warning_label.text = LocalizationManager.tr_key("settings.account.guest_explanation")
	_account_guest_warning_label.visible = not has_session
	_account_sign_in_button.visible = not has_session
	_account_logout_button.visible = has_session
	_refresh_cloud_section()


func _set_account_actions_busy(is_busy: bool) -> void:
	_account_action_busy = is_busy
	if _account_logout_button != null:
		_account_logout_button.disabled = is_busy
	if _account_sign_in_button != null:
		_account_sign_in_button.disabled = is_busy


func _show_account_action(text: String, is_error: bool = false) -> void:
	if _account_action_label == null:
		return
	_account_action_label.text = text
	_account_action_label.visible = (text != "")
	if is_error:
		_account_action_label.add_theme_color_override("font_color", Color(0.9, 0.35, 0.35, 1.0))
	else:
		_account_action_label.add_theme_color_override("font_color", Color(0.65, 0.85, 0.45, 1.0))


func _connect_account_platform_signals() -> void:
	if _account_signals_connected:
		return
	Platform.backend_auth_changed.connect(_on_account_backend_auth_changed)
	Platform.backend_operation_succeeded.connect(_on_account_backend_op_succeeded)
	Platform.backend_operation_failed.connect(_on_account_backend_op_failed)
	_account_signals_connected = true


func _disconnect_account_platform_signals() -> void:
	if not _account_signals_connected:
		return
	if is_instance_valid(Platform):
		if Platform.backend_auth_changed.is_connected(_on_account_backend_auth_changed):
			Platform.backend_auth_changed.disconnect(_on_account_backend_auth_changed)
		if Platform.backend_operation_succeeded.is_connected(_on_account_backend_op_succeeded):
			Platform.backend_operation_succeeded.disconnect(_on_account_backend_op_succeeded)
		if Platform.backend_operation_failed.is_connected(_on_account_backend_op_failed):
			Platform.backend_operation_failed.disconnect(_on_account_backend_op_failed)
	_account_signals_connected = false


func _on_account_backend_auth_changed(_auth_data: Dictionary) -> void:
	_set_account_actions_busy(false)
	_refresh_account_section()


func _on_account_backend_op_succeeded(operation: String, _response: Dictionary) -> void:
	match operation:
		"logout":
			_set_account_actions_busy(false)
			_refresh_account_section_state()
			_show_account_action(LocalizationManager.tr_key("settings.account.logout_success"))


func _on_account_backend_op_failed(operation: String, _error_code: String, _status_code: int, _response: Dictionary) -> void:
	match operation:
		"logout":
			_set_account_actions_busy(false)
			Platform.backend_clear_local_auth()
			_refresh_account_section_state()
			_show_account_action(LocalizationManager.tr_key("settings.account.logout_local_fallback"))


func _on_account_sign_in_pressed() -> void:
	if _account_action_busy:
		return
	account_auth_requested.emit()


func _on_account_logout_pressed() -> void:
	if _account_action_busy:
		return
	_set_account_actions_busy(true)
	_show_account_action(LocalizationManager.tr_key("settings.account.logout_in_progress"))
	Platform.backend_logout()


# ── Cloud save section ────────────────────────────────────────────────────────

func _create_cloud_section(parent_vbox: VBoxContainer) -> void:
	var cloud_vbox := VBoxContainer.new()
	cloud_vbox.add_theme_constant_override("separation", 6)
	parent_vbox.add_child(cloud_vbox)
	_cloud_section = cloud_vbox

	var upload_btn := Button.new()
	upload_btn.custom_minimum_size = ACTION_BUTTON_SIZE
	upload_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	upload_btn.pressed.connect(_on_cloud_upload_pressed)
	cloud_vbox.add_child(upload_btn)
	_cloud_upload_button = upload_btn
	_cloud_upload_button_label = _make_image_button_label(
		upload_btn, "ui.popup.button.default",
		LocalizationManager.tr_key("settings.cloud.save_to_cloud")
	)
	UiFontConfig.apply_label_font_size(_cloud_upload_button_label, UiFontConfig.SETTINGS_ACTION_BUTTON_FONT_SIZE)

	var status_lbl := Label.new()
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_lbl.add_theme_font_size_override("font_size", 12)
	cloud_vbox.add_child(status_lbl)
	_cloud_status_label = status_lbl


func _refresh_cloud_section() -> void:
	if _cloud_section == null:
		return
	var has_session := Platform.backend_has_session()
	if _cloud_upload_button != null:
		_cloud_upload_button.visible = has_session


func _refresh_cloud_static_labels() -> void:
	if _cloud_section == null:
		return
	if _cloud_upload_button_label != null:
		_cloud_upload_button_label.text = LocalizationManager.tr_key("settings.cloud.save_to_cloud")
	_refresh_cloud_section()


func _on_cloud_upload_pressed() -> void:
	set_cloud_save_status(LocalizationManager.tr_key("settings.cloud.upload_started"))
	cloud_save_upload_requested.emit()


# ── Public cloud save helpers ─────────────────────────────────────────────────

func set_cloud_save_status(message: String, is_error: bool = false) -> void:
	if _cloud_status_label == null:
		return
	_cloud_status_label.text = message
	if is_error:
		_cloud_status_label.add_theme_color_override("font_color", Color(0.9, 0.35, 0.35, 1.0))
	else:
		_cloud_status_label.remove_theme_color_override("font_color")


func set_cloud_save_buttons_busy(is_busy: bool) -> void:
	if _cloud_upload_button != null:
		_cloud_upload_button.disabled = is_busy


func refresh_account_section() -> void:
	_refresh_account_section()
