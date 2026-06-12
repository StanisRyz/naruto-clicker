class_name PrestigeConfirmDialog
extends Control

signal confirmed
signal cancelled

const ImageSlotClass = preload("res://scripts/ui/ImageSlot.gd")

@onready var _title_label: Label = $CenterContainer/InnerPanel/MarginContainer/VBoxContainer/TitleLabel
@onready var _stage_label: Label = $CenterContainer/InnerPanel/MarginContainer/VBoxContainer/StageLabel
@onready var _level_label: Label = $CenterContainer/InnerPanel/MarginContainer/VBoxContainer/LevelLabel
@onready var _points_label: Label = $CenterContainer/InnerPanel/MarginContainer/VBoxContainer/PointsToGainLabel
@onready var _reset_warning_label: Label = $CenterContainer/InnerPanel/MarginContainer/VBoxContainer/ResetWarningLabel
@onready var _talents_kept_label: Label = $CenterContainer/InnerPanel/MarginContainer/VBoxContainer/TalentsKeptLabel
@onready var yes_button: Button = $CenterContainer/InnerPanel/MarginContainer/VBoxContainer/ButtonRow/YesButton
@onready var no_button: Button = $CenterContainer/InnerPanel/MarginContainer/VBoxContainer/ButtonRow/NoButton


func _ready() -> void:
	yes_button.pressed.connect(_on_yes_pressed)
	no_button.pressed.connect(_on_no_pressed)
	var inner_panel: PanelContainer = $CenterContainer/InnerPanel
	_add_background_image_holder(inner_panel, "PrestigeDialogInnerBackgroundImageHolder", "ui.dialog.prestige.inner_background")
	_make_image_button_label(yes_button, "ui.popup.button.default", LocalizationManager.tr_key("prestige.confirm.yes"))
	_make_image_button_label(no_button, "ui.popup.button.default", LocalizationManager.tr_key("prestige.confirm.no"))
	hide()


func show_dialog(state: ClickerState) -> void:
	var reward: int = state.get_prestige_reward()
	var L := LocalizationManager
	_title_label.text = L.tr_key("prestige.confirm.title")
	_stage_label.text = L.format_key("prestige.confirm.stage", {"stage": state.current_level})
	_level_label.text = L.format_key("prestige.confirm.level", {"level": state.character_level})
	_points_label.text = L.format_key("prestige.confirm.points_to_gain", {"points": NumberFormatter.compact(reward)})
	_reset_warning_label.text = L.tr_key("prestige.confirm.reset_warning")
	_talents_kept_label.text = L.tr_key("prestige.confirm.talents_kept")
	show()
	move_to_front()


func _on_yes_pressed() -> void:
	hide()
	confirmed.emit()


func _on_no_pressed() -> void:
	hide()
	cancelled.emit()


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
