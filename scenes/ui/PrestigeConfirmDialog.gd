class_name PrestigeConfirmDialog
extends Control

signal confirmed
signal cancelled

const ImageSlotClass = preload("res://scripts/ui/ImageSlot.gd")

@onready var info_label: Label = $PanelContainer/MarginContainer/InnerPanel/VBoxContainer/InfoLabel
@onready var yes_button: Button = $PanelContainer/MarginContainer/InnerPanel/VBoxContainer/ButtonRow/YesButton
@onready var no_button: Button = $PanelContainer/MarginContainer/InnerPanel/VBoxContainer/ButtonRow/NoButton


func _ready() -> void:
	yes_button.pressed.connect(_on_yes_pressed)
	no_button.pressed.connect(_on_no_pressed)
	var outer_panel: PanelContainer = $PanelContainer
	var inner_panel: PanelContainer = $PanelContainer/MarginContainer/InnerPanel
	_add_background_image_holder(outer_panel, "PrestigeDialogBackgroundImageHolder", "ui.dialog.prestige.background")
	_add_background_image_holder(inner_panel, "PrestigeDialogInnerBackgroundImageHolder", "ui.dialog.prestige.inner_background")
	_make_image_button_label(yes_button, "ui.popup.button.default", "Yes")
	_make_image_button_label(no_button, "ui.popup.button.default", "No")
	hide()


func show_dialog(state: ClickerState) -> void:
	var stage_points: int = state.get_prestige_stage_points()
	var character_points: int = state.get_prestige_character_points()
	var reward: int = state.get_prestige_reward()
	var available_after: int = state.prestige_points_available + reward
	var total_earned_after: int = state.prestige_points_total_earned + reward
	var L := LocalizationManager
	var lines: PackedStringArray = []
	lines.append("%s: %d" % [L.tr_key("prestige.confirm.stage_level"), state.current_level])
	lines.append("%s: %d" % [L.tr_key("prestige.confirm.character_level"), state.character_level])
	lines.append("%s: +%s" % [L.tr_key("prestige.confirm.stage_points"), NumberFormatter.compact(stage_points)])
	lines.append("%s: +%s" % [L.tr_key("prestige.confirm.character_points"), NumberFormatter.compact(character_points)])
	lines.append("%s: +%s" % [L.tr_key("prestige.confirm.points_to_gain"), NumberFormatter.compact(reward)])
	lines.append("%s: %s" % [L.tr_key("prestige.confirm.available_after"), NumberFormatter.compact(available_after)])
	lines.append("%s: %s" % [L.tr_key("prestige.confirm.total_earned_after"), NumberFormatter.compact(total_earned_after)])
	lines.append("")
	lines.append(L.tr_key("prestige.confirm.warning"))
	lines.append(L.tr_key("prestige.confirm.talents_note"))
	info_label.text = "\n".join(lines)
	show()


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
