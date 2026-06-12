class_name SettingsWindow
extends Control

signal sound_toggled(enabled: bool)
signal music_toggled(enabled: bool)
signal save_requested
signal reset_requested
signal reset_confirmed

const ImageSlotClass = preload("res://scripts/ui/ImageSlot.gd")

@onready var overlay: ColorRect = $Overlay
@onready var panel_container: PanelContainer = $PanelContainer
@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/Header/CloseButton
@onready var sound_button: Button = $PanelContainer/MarginContainer/VBoxContainer/SoundRow/SoundToggleButton
@onready var music_button: Button = $PanelContainer/MarginContainer/VBoxContainer/MusicRow/MusicToggleButton
@onready var save_button: Button = $PanelContainer/MarginContainer/VBoxContainer/SaveButton
@onready var reset_button: Button = $PanelContainer/MarginContainer/VBoxContainer/ResetButton
@onready var status_label: Label = $PanelContainer/MarginContainer/VBoxContainer/StatusLabel
@onready var version_label: Label = $PanelContainer/MarginContainer/VBoxContainer/VersionLabel
@onready var reset_confirm_dialog: Control = $ResetConfirmDialog
@onready var reset_confirm_overlay: ColorRect = $ResetConfirmDialog/Overlay
@onready var reset_dialog_panel: PanelContainer = $ResetConfirmDialog/PanelContainer
@onready var reset_cancel_button: Button = $ResetConfirmDialog/PanelContainer/MarginContainer/VBoxContainer/ButtonRow/CancelButton
@onready var reset_confirm_button: Button = $ResetConfirmDialog/PanelContainer/MarginContainer/VBoxContainer/ButtonRow/ResetButton

var sound_enabled: bool = true
var music_enabled: bool = true
var _language_button: Button = null

var _sound_button_label: Label = null
var _music_button_label: Label = null


func _ready() -> void:
	overlay.gui_input.connect(_on_overlay_gui_input)
	panel_container.gui_input.connect(_on_panel_container_gui_input)
	reset_confirm_overlay.gui_input.connect(_on_reset_confirm_overlay_gui_input)
	reset_dialog_panel.gui_input.connect(_on_panel_container_gui_input)
	close_button.pressed.connect(hide_window)
	sound_button.pressed.connect(_on_sound_button_pressed)
	music_button.pressed.connect(_on_music_button_pressed)
	save_button.pressed.connect(_on_save_button_pressed)
	reset_button.pressed.connect(_on_reset_button_pressed)
	reset_cancel_button.pressed.connect(_hide_reset_confirm)
	reset_confirm_button.pressed.connect(_on_reset_confirm_button_pressed)
	version_label.text = "Version %s%s" % [BuildConfig.APP_VERSION, "-dev" if BuildConfig.IS_DEBUG_BUILD else ""]
	_create_language_row()
	_add_background_image_holder(panel_container, "SettingsBackgroundImageHolder", "ui.window.settings.background")
	_add_background_image_holder(reset_dialog_panel, "ResetConfirmBackgroundImageHolder", "ui.window.settings.reset_confirm_background")
	_make_image_icon_button(close_button, "ui.sheet.close_button")
	_sound_button_label = _make_image_button_label(sound_button, "ui.popup.button.default", "")
	_music_button_label = _make_image_button_label(music_button, "ui.popup.button.default", "")
	_make_image_button_label(save_button, "ui.popup.button.default", "Save Now")
	_make_image_button_label(reset_button, "ui.popup.button.danger", "Reset Progress")
	_make_image_button_label(reset_cancel_button, "ui.popup.button.default", "Cancel")
	_make_image_button_label(reset_confirm_button, "ui.popup.button.danger", "Reset")
	hide()


func _create_language_row() -> void:
	var vbox: VBoxContainer = panel_container.get_node("MarginContainer/VBoxContainer")

	var lang_row := HBoxContainer.new()
	lang_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var lang_label := Label.new()
	lang_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lang_label.text = LocalizationManager.tr_key("settings.language") + ":"
	lang_row.add_child(lang_label)

	_language_button = Button.new()
	_language_button.pressed.connect(_on_language_button_pressed)
	lang_row.add_child(_language_button)

	vbox.add_child(lang_row)
	vbox.move_child(lang_row, save_button.get_index())

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
	_language_button.text = LocalizationManager.tr_key("settings.language." + lang_code)


func show_window(state: ClickerState) -> void:
	refresh_view(state)
	status_label.text = ""
	reset_confirm_dialog.hide()
	show()


func hide_window() -> void:
	reset_confirm_dialog.hide()
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


func _on_sound_button_pressed() -> void:
	sound_enabled = not sound_enabled
	if _sound_button_label != null:
		_sound_button_label.text = LocalizationManager.tr_key("ui.common.on") if sound_enabled else LocalizationManager.tr_key("ui.common.off")
	status_label.text = ""
	sound_toggled.emit(sound_enabled)


func _on_music_button_pressed() -> void:
	music_enabled = not music_enabled
	if _music_button_label != null:
		_music_button_label.text = LocalizationManager.tr_key("ui.common.on") if music_enabled else LocalizationManager.tr_key("ui.common.off")
	status_label.text = ""
	music_toggled.emit(music_enabled)


func _on_save_button_pressed() -> void:
	save_requested.emit()


func _on_reset_button_pressed() -> void:
	reset_confirm_dialog.show()


func _hide_reset_confirm() -> void:
	reset_confirm_dialog.hide()


func _on_reset_confirm_button_pressed() -> void:
	reset_confirm_dialog.hide()
	reset_confirmed.emit()
	reset_requested.emit()


func _on_language_button_pressed() -> void:
	var current: String = LocalizationManager.get_language()
	var langs: Array[String] = LocalizationManager.get_available_languages()
	var idx: int = langs.find(current)
	var next_idx: int = (idx + 1) % langs.size()
	LocalizationManager.set_language(langs[next_idx])


func _on_overlay_gui_input(event: InputEvent) -> void:
	if _is_pressed_pointer_event(event):
		hide_window()
		accept_event()


func _on_reset_confirm_overlay_gui_input(event: InputEvent) -> void:
	if _is_pressed_pointer_event(event):
		_hide_reset_confirm()
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
