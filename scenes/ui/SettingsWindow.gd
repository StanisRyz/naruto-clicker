class_name SettingsWindow
extends Control

signal sound_toggled(enabled: bool)
signal music_toggled(enabled: bool)
signal save_requested
signal language_manually_changed(language_code: String)
signal account_auth_requested
signal cloud_save_upload_requested
signal cloud_save_download_requested

const ImageSlotClass = preload("res://scripts/ui/ImageSlot.gd")

@onready var overlay: ColorRect = $Overlay
@onready var panel_container: PanelContainer = $PanelContainer
@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HeaderMargin/Header/CloseButton
@onready var sound_button: Button = $PanelContainer/MarginContainer/VBoxContainer/SoundMargin/SoundRow/SoundToggleButton
@onready var music_button: Button = $PanelContainer/MarginContainer/VBoxContainer/MusicMargin/MusicRow/MusicToggleButton
@onready var _sound_label: Label = $PanelContainer/MarginContainer/VBoxContainer/SoundMargin/SoundRow/SoundLabel
@onready var _music_label: Label = $PanelContainer/MarginContainer/VBoxContainer/MusicMargin/MusicRow/MusicLabel
@onready var save_button: Button = $PanelContainer/MarginContainer/VBoxContainer/SaveButton
@onready var status_label: Label = $PanelContainer/MarginContainer/VBoxContainer/StatusLabel
@onready var version_label: Label = $PanelContainer/MarginContainer/VBoxContainer/VersionLabel
@onready var _title_label: Label = $PanelContainer/MarginContainer/VBoxContainer/HeaderMargin/Header/TitleLabel

var sound_enabled: bool = true
var music_enabled: bool = true
var _language_label: Label = null
var _language_button: Button = null
var _language_button_label: Label = null

var _sound_button_label: Label = null
var _music_button_label: Label = null
var _save_button_label: Label = null

var _account_section: Control = null
var _account_title_label: Label = null
var _account_status_label: Label = null
var _account_email_label: Label = null
var _account_verification_label: Label = null
var _account_guest_warning_label: Label = null
var _account_sign_in_button: Button = null
var _account_sign_in_button_label: Label = null
var _account_verify_button: Button = null
var _account_verify_button_label: Label = null
var _account_code_box: Control = null
var _account_code_input: LineEdit = null
var _account_confirm_button: Button = null
var _account_confirm_button_label: Label = null
var _account_logout_button: Button = null
var _account_logout_button_label: Label = null
var _account_action_label: Label = null
var _account_signals_connected: bool = false

var _cloud_section: Control = null
var _cloud_title_label: Label = null
var _cloud_status_label: Label = null
var _cloud_upload_button: Button = null
var _cloud_upload_button_label: Label = null
var _cloud_download_button: Button = null
var _cloud_download_button_label: Label = null
var _cloud_confirm_box: Control = null
var _cloud_confirm_warning_label: Label = null
var _cloud_confirm_button: Button = null
var _cloud_confirm_button_label: Label = null
var _cloud_cancel_button: Button = null
var _cloud_cancel_button_label: Label = null


func _ready() -> void:
	overlay.gui_input.connect(_on_overlay_gui_input)
	panel_container.gui_input.connect(_on_panel_container_gui_input)
	close_button.pressed.connect(_on_close_button_pressed)
	sound_button.pressed.connect(_on_sound_button_pressed)
	music_button.pressed.connect(_on_music_button_pressed)
	save_button.pressed.connect(_on_save_button_pressed)
	var _version_str: String = BuildConfig.APP_VERSION + ("-dev" if BuildConfig.IS_DEBUG_BUILD else "")
	version_label.text = LocalizationManager.format_key("settings.version", {"version": _version_str})
	_create_language_row()
	_add_background_image_holder(panel_container, "SettingsBackgroundImageHolder", "ui.window.settings.background")
	_make_image_icon_button(close_button, "ui.sheet.close_button")
	_sound_button_label = _make_image_button_label(sound_button, "ui.popup.button.default", "")
	_music_button_label = _make_image_button_label(music_button, "ui.popup.button.default", "")
	_save_button_label = _make_image_button_label(save_button, "ui.popup.button.default", LocalizationManager.tr_key("settings.save_now"))
	UiFontConfig.apply_label_font_size(_sound_label, UiFontConfig.SETTINGS_ROW_FONT_SIZE)
	UiFontConfig.apply_label_font_size(_music_label, UiFontConfig.SETTINGS_ROW_FONT_SIZE)
	UiFontConfig.apply_label_font_size(_sound_button_label, UiFontConfig.SETTINGS_ROW_FONT_SIZE)
	UiFontConfig.apply_label_font_size(_music_button_label, UiFontConfig.SETTINGS_ROW_FONT_SIZE)
	UiFontConfig.apply_label_font_size(_save_button_label, UiFontConfig.SETTINGS_ACTION_BUTTON_FONT_SIZE)
	LocalizationManager.language_changed.connect(_refresh_static_labels)
	_refresh_static_labels()
	if _is_backend_account_ui_supported():
		_create_account_section()
		_connect_account_platform_signals()
	hide()


func _exit_tree() -> void:
	_disconnect_account_platform_signals()


func _refresh_static_labels() -> void:
	_title_label.text = LocalizationManager.tr_key("settings.title")
	_sound_label.text = LocalizationManager.tr_key("settings.sound")
	_music_label.text = LocalizationManager.tr_key("settings.music")
	if _language_label:
		_language_label.text = LocalizationManager.tr_key("settings.language") + ":"
	if _save_button_label:
		_save_button_label.text = LocalizationManager.tr_key("settings.save_now")
	_refresh_account_static_labels()


func _create_language_row() -> void:
	var vbox: VBoxContainer = panel_container.get_node("MarginContainer/VBoxContainer")

	var lang_row := HBoxContainer.new()
	lang_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var lang_label := Label.new()
	lang_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lang_label.text = LocalizationManager.tr_key("settings.language") + ":"
	lang_row.add_child(lang_label)
	_language_label = lang_label

	_language_button = Button.new()
	_language_button.custom_minimum_size = Vector2(175, 60)
	_language_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_language_button.pressed.connect(_on_language_button_pressed)
	lang_row.add_child(_language_button)

	var lang_margin := MarginContainer.new()
	lang_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lang_margin.add_theme_constant_override("margin_left", 15)
	lang_margin.add_theme_constant_override("margin_right", 15)
	lang_margin.add_child(lang_row)

	vbox.add_child(lang_margin)
	vbox.move_child(lang_margin, save_button.get_index())

	_language_button_label = _make_image_button_label(_language_button, "ui.popup.button.default", "")
	UiFontConfig.apply_label_font_size(lang_label, UiFontConfig.SETTINGS_ROW_FONT_SIZE)
	UiFontConfig.apply_label_font_size(_language_button_label, UiFontConfig.SETTINGS_ROW_FONT_SIZE)
	_update_language_button()


func _create_debug_localization_row() -> void:
	var vbox: VBoxContainer = panel_container.get_node("MarginContainer/VBoxContainer")

	var source_label := Label.new()
	source_label.name = "DebugLocalizationSourceLabel"
	source_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	source_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	source_label.modulate = Color(0.5, 0.85, 0.5, 1.0)
	source_label.text = "Localization: %s" % LocalizationManager.get_localization_source_status()
	vbox.add_child(source_label)

	var probe_label := Label.new()
	probe_label.name = "DebugLocalizationProbeLabel"
	probe_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	probe_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	probe_label.modulate = Color(0.5, 0.85, 0.5, 1.0)
	probe_label.text = "Probe: building.02.purchase_gain = '%s'" % LocalizationManager.tr_key("building.02.purchase_gain")
	vbox.add_child(probe_label)


func _update_language_button() -> void:
	if _language_button == null:
		return
	var lang_code: String = LocalizationManager.get_language()
	var text: String = LocalizationManager.tr_key("settings.language." + lang_code)
	if _language_button_label != null:
		_language_button_label.text = text
	else:
		_language_button.text = text


func show_window(state: ClickerState) -> void:
	ButtonVisualUtils.set_image_button_asset(close_button, "ui.sheet.close_button")
	refresh_view(state)
	status_label.text = ""
	_refresh_account_section()
	show()


func hide_window() -> void:
	hide()


func refresh_view(state: ClickerState) -> void:
	sound_enabled = state.sound_enabled
	music_enabled = state.music_enabled
	if _sound_button_label != null:
		_sound_button_label.text = LocalizationManager.tr_key("ui.common.on") if sound_enabled else LocalizationManager.tr_key("ui.common.off")
	if _music_button_label != null:
		_music_button_label.text = LocalizationManager.tr_key("ui.common.on") if music_enabled else LocalizationManager.tr_key("ui.common.off")
	_update_language_button()


func show_status(text: String) -> void:
	status_label.text = text


func _on_close_button_pressed() -> void:
	ButtonVisualUtils.play_pressed_then_call(
		close_button,
		Callable(self, "hide_window"),
		"ui.sheet.close_button",
		"ui.sheet.close_button.pressed",
		0.2,
		Color.WHITE
	)


func _on_sound_button_pressed() -> void:
	ButtonVisualUtils.flash_button_image_holder(
		sound_button.find_child("ButtonImageHolder", false, false),
		"ui.popup.button.default"
	)
	sound_enabled = not sound_enabled
	if _sound_button_label != null:
		_sound_button_label.text = LocalizationManager.tr_key("ui.common.on") if sound_enabled else LocalizationManager.tr_key("ui.common.off")
	status_label.text = ""
	sound_toggled.emit(sound_enabled)


func _on_music_button_pressed() -> void:
	ButtonVisualUtils.flash_button_image_holder(
		music_button.find_child("ButtonImageHolder", false, false),
		"ui.popup.button.default"
	)
	music_enabled = not music_enabled
	if _music_button_label != null:
		_music_button_label.text = LocalizationManager.tr_key("ui.common.on") if music_enabled else LocalizationManager.tr_key("ui.common.off")
	status_label.text = ""
	music_toggled.emit(music_enabled)


func _on_save_button_pressed() -> void:
	ButtonVisualUtils.flash_button_image_holder(
		save_button.find_child("ButtonImageHolder", false, false),
		"ui.popup.button.default"
	)
	save_requested.emit()


func _on_language_button_pressed() -> void:
	ButtonVisualUtils.flash_button_image_holder(
		_language_button.find_child("ButtonImageHolder", false, false),
		"ui.popup.button.default"
	)
	var current: String = LocalizationManager.get_language()
	var langs: Array[String] = LocalizationManager.get_available_languages()
	var idx: int = langs.find(current)
	var next_idx: int = (idx + 1) % langs.size()
	LocalizationManager.set_language(langs[next_idx])
	language_manually_changed.emit(langs[next_idx])


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


# ── Account section ───────────────────────────────────────────────────────────

func _is_backend_account_ui_supported() -> bool:
	return OS.has_feature("android")


func _create_account_section() -> void:
	var vbox: VBoxContainer = panel_container.get_node("MarginContainer/VBoxContainer")

	panel_container.offset_top = -437.0
	panel_container.offset_bottom = 437.0

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var account_vbox := VBoxContainer.new()
	account_vbox.add_theme_constant_override("separation", 8)
	vbox.add_child(account_vbox)
	_account_section = account_vbox

	var title_lbl := Label.new()
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 16)
	account_vbox.add_child(title_lbl)
	_account_title_label = title_lbl

	var status_lbl := Label.new()
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	account_vbox.add_child(status_lbl)
	_account_status_label = status_lbl

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
	sign_in_btn.custom_minimum_size = Vector2(0, 60)
	sign_in_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sign_in_btn.pressed.connect(_on_account_sign_in_pressed)
	account_vbox.add_child(sign_in_btn)
	_account_sign_in_button = sign_in_btn
	_account_sign_in_button_label = _make_image_button_label(
		sign_in_btn, "ui.popup.button.default",
		LocalizationManager.tr_key("settings.account.sign_in_register")
	)
	UiFontConfig.apply_label_font_size(_account_sign_in_button_label, UiFontConfig.SETTINGS_ACTION_BUTTON_FONT_SIZE)

	var verify_btn := Button.new()
	verify_btn.custom_minimum_size = Vector2(0, 60)
	verify_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	verify_btn.pressed.connect(_on_account_verify_email_pressed)
	account_vbox.add_child(verify_btn)
	_account_verify_button = verify_btn
	_account_verify_button_label = _make_image_button_label(
		verify_btn, "ui.popup.button.default",
		LocalizationManager.tr_key("settings.account.verify_email")
	)
	UiFontConfig.apply_label_font_size(_account_verify_button_label, UiFontConfig.SETTINGS_ACTION_BUTTON_FONT_SIZE)

	var code_box := VBoxContainer.new()
	code_box.add_theme_constant_override("separation", 6)
	code_box.visible = false
	account_vbox.add_child(code_box)
	_account_code_box = code_box

	var code_input := LineEdit.new()
	code_input.placeholder_text = LocalizationManager.tr_key("settings.account.verification_code_placeholder")
	code_input.max_length = 6
	code_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	code_input.custom_minimum_size = Vector2(0, 48)
	code_box.add_child(code_input)
	_account_code_input = code_input

	var confirm_btn := Button.new()
	confirm_btn.custom_minimum_size = Vector2(0, 60)
	confirm_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm_btn.pressed.connect(_on_account_confirm_code_pressed)
	code_box.add_child(confirm_btn)
	_account_confirm_button = confirm_btn
	_account_confirm_button_label = _make_image_button_label(
		confirm_btn, "ui.popup.button.default",
		LocalizationManager.tr_key("settings.account.confirm_code")
	)
	UiFontConfig.apply_label_font_size(_account_confirm_button_label, UiFontConfig.SETTINGS_ACTION_BUTTON_FONT_SIZE)

	var logout_btn := Button.new()
	logout_btn.custom_minimum_size = Vector2(0, 60)
	logout_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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

	_create_cloud_section(account_vbox)
	_refresh_account_section()


func _refresh_account_static_labels() -> void:
	if _account_section == null:
		return
	if _account_title_label != null:
		_account_title_label.text = LocalizationManager.tr_key("settings.account.title")
	if _account_sign_in_button_label != null:
		_account_sign_in_button_label.text = LocalizationManager.tr_key("settings.account.sign_in_register")
	if _account_verify_button_label != null:
		_account_verify_button_label.text = LocalizationManager.tr_key("settings.account.verify_email")
	if _account_confirm_button_label != null:
		_account_confirm_button_label.text = LocalizationManager.tr_key("settings.account.confirm_code")
	if _account_logout_button_label != null:
		_account_logout_button_label.text = LocalizationManager.tr_key("settings.account.logout")
	if _account_code_input != null:
		_account_code_input.placeholder_text = LocalizationManager.tr_key("settings.account.verification_code_placeholder")
	_refresh_cloud_static_labels()
	_refresh_account_section()


func _refresh_account_section() -> void:
	if _account_section == null:
		return
	_account_code_box.visible = false
	_account_action_label.visible = false
	_account_action_label.text = ""

	var has_session := Platform.backend_has_session()
	var email := Platform.backend_get_email()
	var verified := Platform.backend_is_email_verified()

	_account_title_label.text = LocalizationManager.tr_key("settings.account.title")
	_account_status_label.text = (
		LocalizationManager.tr_key("settings.account.status_signed_in")
		if has_session else
		LocalizationManager.tr_key("settings.account.status_guest")
	)
	_account_email_label.text = LocalizationManager.format_key("settings.account.email", {"email": email})
	_account_email_label.visible = has_session
	_account_verification_label.text = (
		LocalizationManager.tr_key("settings.account.email_verified")
		if verified else
		LocalizationManager.tr_key("settings.account.email_not_verified")
	)
	_account_verification_label.visible = has_session
	_account_guest_warning_label.text = LocalizationManager.tr_key("settings.account.guest_warning")
	_account_guest_warning_label.visible = not has_session
	_account_sign_in_button.visible = not has_session
	_account_verify_button.visible = has_session and not verified
	_account_logout_button.visible = has_session
	_refresh_cloud_section()


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
	_refresh_account_section()


func _on_account_backend_op_succeeded(operation: String, _response: Dictionary) -> void:
	match operation:
		"request_email_verification":
			_account_code_box.visible = true
			_account_verify_button.visible = false
			_show_account_action(LocalizationManager.tr_key("settings.account.verification_sent"))

		"confirm_email_verification":
			_account_code_box.visible = false
			_show_account_action(LocalizationManager.tr_key("settings.account.verification_success"))
			_refresh_account_section()

		"logout":
			_refresh_account_section()
			_show_account_action(LocalizationManager.tr_key("settings.account.logout_success"))


func _on_account_backend_op_failed(operation: String, error_code: String, _status_code: int, _response: Dictionary) -> void:
	match operation:
		"request_email_verification":
			_show_account_action(
				LocalizationManager.format_key("settings.account.backend_error", {"error": error_code}),
				true
			)

		"confirm_email_verification":
			_show_account_action(
				LocalizationManager.format_key("settings.account.backend_error", {"error": error_code}),
				true
			)

		"logout":
			Platform.backend_clear_local_auth()
			_refresh_account_section()
			_show_account_action(LocalizationManager.tr_key("settings.account.logout_local_fallback"))


func _on_account_sign_in_pressed() -> void:
	account_auth_requested.emit()


func _on_account_verify_email_pressed() -> void:
	_show_account_action("")
	Platform.backend_request_email_verification()


func _on_account_confirm_code_pressed() -> void:
	var code := _account_code_input.text.strip_edges()
	if code.length() != 6 or not code.is_valid_int():
		_show_account_action(LocalizationManager.tr_key("settings.account.verification_invalid_code"), true)
		return
	_show_account_action("")
	Platform.backend_confirm_email_verification(code)


func _on_account_logout_pressed() -> void:
	_show_account_action("")
	Platform.backend_logout()


# ── Cloud save section ────────────────────────────────────────────────────────

func _create_cloud_section(parent_vbox: VBoxContainer) -> void:
	var sep := HSeparator.new()
	parent_vbox.add_child(sep)

	var cloud_vbox := VBoxContainer.new()
	cloud_vbox.add_theme_constant_override("separation", 6)
	parent_vbox.add_child(cloud_vbox)
	_cloud_section = cloud_vbox

	var title_lbl := Label.new()
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 15)
	cloud_vbox.add_child(title_lbl)
	_cloud_title_label = title_lbl

	var status_lbl := Label.new()
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_lbl.add_theme_font_size_override("font_size", 12)
	cloud_vbox.add_child(status_lbl)
	_cloud_status_label = status_lbl

	var upload_btn := Button.new()
	upload_btn.custom_minimum_size = Vector2(0, 56)
	upload_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upload_btn.pressed.connect(_on_cloud_upload_pressed)
	cloud_vbox.add_child(upload_btn)
	_cloud_upload_button = upload_btn
	_cloud_upload_button_label = _make_image_button_label(
		upload_btn, "ui.popup.button.default",
		LocalizationManager.tr_key("settings.cloud.save_to_cloud")
	)
	UiFontConfig.apply_label_font_size(_cloud_upload_button_label, UiFontConfig.SETTINGS_ACTION_BUTTON_FONT_SIZE)

	var download_btn := Button.new()
	download_btn.custom_minimum_size = Vector2(0, 56)
	download_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	download_btn.pressed.connect(_on_cloud_download_pressed)
	cloud_vbox.add_child(download_btn)
	_cloud_download_button = download_btn
	_cloud_download_button_label = _make_image_button_label(
		download_btn, "ui.popup.button.default",
		LocalizationManager.tr_key("settings.cloud.load_from_cloud")
	)
	UiFontConfig.apply_label_font_size(_cloud_download_button_label, UiFontConfig.SETTINGS_ACTION_BUTTON_FONT_SIZE)

	var confirm_box := VBoxContainer.new()
	confirm_box.add_theme_constant_override("separation", 4)
	confirm_box.visible = false
	cloud_vbox.add_child(confirm_box)
	_cloud_confirm_box = confirm_box

	var warn_lbl := Label.new()
	warn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warn_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warn_lbl.add_theme_font_size_override("font_size", 12)
	warn_lbl.add_theme_color_override("font_color", Color(0.9, 0.75, 0.35, 1.0))
	confirm_box.add_child(warn_lbl)
	_cloud_confirm_warning_label = warn_lbl

	var confirm_row := HBoxContainer.new()
	confirm_row.add_theme_constant_override("separation", 6)
	confirm_box.add_child(confirm_row)

	var cancel_btn := Button.new()
	cancel_btn.custom_minimum_size = Vector2(0, 52)
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.pressed.connect(_on_cloud_confirm_cancel_pressed)
	confirm_row.add_child(cancel_btn)
	_cloud_cancel_button = cancel_btn
	_cloud_cancel_button_label = _make_image_button_label(
		cancel_btn, "ui.popup.button.default",
		LocalizationManager.tr_key("settings.cloud.cancel_load")
	)
	UiFontConfig.apply_label_font_size(_cloud_cancel_button_label, UiFontConfig.SETTINGS_ACTION_BUTTON_FONT_SIZE)

	var confirm_btn := Button.new()
	confirm_btn.custom_minimum_size = Vector2(0, 52)
	confirm_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm_btn.pressed.connect(_on_cloud_confirm_load_pressed)
	confirm_row.add_child(confirm_btn)
	_cloud_confirm_button = confirm_btn
	_cloud_confirm_button_label = _make_image_button_label(
		confirm_btn, "ui.popup.button.danger",
		LocalizationManager.tr_key("settings.cloud.confirm_load")
	)
	UiFontConfig.apply_label_font_size(_cloud_confirm_button_label, UiFontConfig.SETTINGS_ACTION_BUTTON_FONT_SIZE)


func _refresh_cloud_section() -> void:
	if _cloud_section == null:
		return
	var has_session := Platform.backend_has_session()
	if _cloud_title_label != null:
		_cloud_title_label.text = LocalizationManager.tr_key("settings.cloud.title")
	if _cloud_status_label != null:
		_cloud_status_label.text = (
			LocalizationManager.tr_key("settings.cloud.status_account_ready")
			if has_session else
			LocalizationManager.tr_key("settings.cloud.status_guest_unavailable")
		)
	if _cloud_upload_button != null:
		_cloud_upload_button.visible = has_session
	if _cloud_download_button != null:
		_cloud_download_button.visible = has_session
	if _cloud_confirm_box != null:
		_cloud_confirm_box.visible = false


func _refresh_cloud_static_labels() -> void:
	if _cloud_section == null:
		return
	if _cloud_title_label != null:
		_cloud_title_label.text = LocalizationManager.tr_key("settings.cloud.title")
	if _cloud_upload_button_label != null:
		_cloud_upload_button_label.text = LocalizationManager.tr_key("settings.cloud.save_to_cloud")
	if _cloud_download_button_label != null:
		_cloud_download_button_label.text = LocalizationManager.tr_key("settings.cloud.load_from_cloud")
	if _cloud_confirm_button_label != null:
		_cloud_confirm_button_label.text = LocalizationManager.tr_key("settings.cloud.confirm_load")
	if _cloud_cancel_button_label != null:
		_cloud_cancel_button_label.text = LocalizationManager.tr_key("settings.cloud.cancel_load")
	if _cloud_confirm_warning_label != null:
		_cloud_confirm_warning_label.text = LocalizationManager.tr_key("settings.cloud.confirm_load_warning")
	_refresh_cloud_section()


func _on_cloud_upload_pressed() -> void:
	if _cloud_confirm_box != null:
		_cloud_confirm_box.visible = false
	set_cloud_save_status(LocalizationManager.tr_key("settings.cloud.upload_started"))
	cloud_save_upload_requested.emit()


func _on_cloud_download_pressed() -> void:
	if _cloud_confirm_box == null:
		return
	if _cloud_confirm_warning_label != null:
		_cloud_confirm_warning_label.text = LocalizationManager.tr_key("settings.cloud.confirm_load_warning")
	_cloud_confirm_box.visible = true


func _on_cloud_confirm_load_pressed() -> void:
	if _cloud_confirm_box != null:
		_cloud_confirm_box.visible = false
	set_cloud_save_status(LocalizationManager.tr_key("settings.cloud.download_started"))
	cloud_save_download_requested.emit()


func _on_cloud_confirm_cancel_pressed() -> void:
	if _cloud_confirm_box != null:
		_cloud_confirm_box.visible = false


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
	if _cloud_download_button != null:
		_cloud_download_button.disabled = is_busy


func refresh_account_section() -> void:
	_refresh_account_section()
