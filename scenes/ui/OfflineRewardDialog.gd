class_name OfflineRewardDialog
extends Control

signal claim_requested()
signal claim_ad_requested()

const ImageSlotClass = preload("res://scripts/ui/ImageSlot.gd")

var _claim_label: Label = null
var _claim_ad_label: Label = null
var _claim_holder = null
var _claim_ad_holder = null
var _action_pending: bool = false

@onready var _title_label: Label = $CenterContainer/InnerPanel/MarginContainer/OuterVBox/LabelsVBox/TitleLabel
@onready var _time_label: Label = $CenterContainer/InnerPanel/MarginContainer/OuterVBox/LabelsVBox/TimeLabel
@onready var _reward_label: Label = $CenterContainer/InnerPanel/MarginContainer/OuterVBox/LabelsVBox/RewardLabel
@onready var _claim_button: Button = $CenterContainer/InnerPanel/MarginContainer/OuterVBox/ButtonRow/ClaimButton
@onready var _claim_ad_button: Button = $CenterContainer/InnerPanel/MarginContainer/OuterVBox/ButtonRow/ClaimAdButton


func _ready() -> void:
	_claim_button.pressed.connect(_on_claim_pressed)
	_claim_ad_button.pressed.connect(_on_claim_ad_pressed)
	var inner_panel: PanelContainer = $CenterContainer/InnerPanel
	_add_background_image_holder(inner_panel, "OfflineRewardBackgroundImageHolder", "ui.dialog.offline_reward.background")
	_claim_label = _make_image_button_label(_claim_button, "ui.popup.button.default", LocalizationManager.tr_key("offline_reward.claim"))
	_claim_ad_label = _make_image_button_label(_claim_ad_button, "ui.popup.button.default", LocalizationManager.tr_key("offline_reward.claim_x3"))
	_claim_holder = _claim_button.find_child("ButtonImageHolder", false, false)
	_claim_ad_holder = _claim_ad_button.find_child("ButtonImageHolder", false, false)
	UiFontConfig.apply_label_font_size(_title_label, UiFontConfig.OFFLINE_REWARD_TITLE_FONT_SIZE)
	UiFontConfig.apply_label_font_size(_time_label, UiFontConfig.OFFLINE_REWARD_TIME_FONT_SIZE)
	UiFontConfig.apply_label_font_size(_reward_label, UiFontConfig.OFFLINE_REWARD_REWARD_FONT_SIZE)
	if _claim_label:
		UiFontConfig.apply_label_font_size(_claim_label, UiFontConfig.OFFLINE_REWARD_BUTTON_FONT_SIZE)
	if _claim_ad_label:
		UiFontConfig.apply_label_font_size(_claim_ad_label, UiFontConfig.OFFLINE_REWARD_BUTTON_FONT_SIZE)
	LocalizationManager.language_changed.connect(_refresh_labels)
	hide()


func show_reward(elapsed_seconds: int, reward_gold: int) -> void:
	_action_pending = false
	_reset_button_visuals()
	_set_buttons_disabled(false)
	_title_label.text = LocalizationManager.tr_key("offline_reward.title")
	_time_label.text = LocalizationManager.format_key("offline_reward.time", {"time": format_duration(elapsed_seconds)})
	_reward_label.text = LocalizationManager.format_key("offline_reward.reward", {"gold": _format_number(reward_gold)})
	if _claim_label:
		_claim_label.text = LocalizationManager.tr_key("offline_reward.claim")
	if _claim_ad_label:
		_claim_ad_label.text = LocalizationManager.tr_key("offline_reward.claim_x3")
	show()
	move_to_front()


func hide_dialog() -> void:
	_reset_button_visuals()
	_action_pending = false
	hide()


func set_buttons_loading(loading: bool) -> void:
	_set_buttons_disabled(loading)
	if loading and _claim_ad_label:
		_claim_ad_label.text = LocalizationManager.tr_key("offline_reward.loading_ad")


func _refresh_labels() -> void:
	if not visible:
		return
	if _claim_label:
		_claim_label.text = LocalizationManager.tr_key("offline_reward.claim")
	if _claim_ad_label:
		_claim_ad_label.text = LocalizationManager.tr_key("offline_reward.claim_x3")


func _on_claim_pressed() -> void:
	if _action_pending:
		return
	_action_pending = true
	ButtonVisualUtils.set_button_pressed_visual(_claim_holder, true, "ui.popup.button.default")
	await _claim_button.get_tree().create_timer(0.15).timeout
	_reset_button_visuals()
	_action_pending = false
	claim_requested.emit()


func _on_claim_ad_pressed() -> void:
	if _action_pending:
		return
	_action_pending = true
	ButtonVisualUtils.set_button_pressed_visual(_claim_ad_holder, true, "ui.popup.button.default")
	await _claim_ad_button.get_tree().create_timer(0.15).timeout
	ButtonVisualUtils.set_button_pressed_visual(_claim_ad_holder, false, "ui.popup.button.default")
	_action_pending = false
	claim_ad_requested.emit()


func _reset_button_visuals() -> void:
	ButtonVisualUtils.set_button_pressed_visual(_claim_holder, false, "ui.popup.button.default")
	ButtonVisualUtils.set_button_pressed_visual(_claim_ad_holder, false, "ui.popup.button.default")


func _set_buttons_disabled(disabled: bool) -> void:
	_claim_button.disabled = disabled
	_claim_ad_button.disabled = disabled


func format_duration(seconds: int) -> String:
	var s: int = maxi(0, seconds)
	if s < 60:
		return LocalizationManager.format_key("common.duration.seconds", {"seconds": str(s)})
	var minutes: int = int(s / 60.0)
	var hours: int = int(minutes / 60.0)
	var remaining_minutes: int = minutes % 60
	if hours <= 0:
		return LocalizationManager.format_key("common.duration.minutes", {"minutes": str(minutes)})
	if remaining_minutes <= 0:
		return LocalizationManager.format_key("common.duration.hours", {"hours": str(hours)})
	return LocalizationManager.format_key("common.duration.hours_minutes", {"hours": str(hours), "minutes": str(remaining_minutes)})


func _format_number(value: int) -> String:
	if value >= 1_000_000_000:
		return "%.1fB" % (float(value) / 1_000_000_000.0)
	if value >= 1_000_000:
		return "%.1fM" % (float(value) / 1_000_000.0)
	if value >= 1_000:
		return "%.1fK" % (float(value) / 1_000.0)
	return str(value)


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
