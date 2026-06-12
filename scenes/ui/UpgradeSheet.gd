class_name UpgradeSheet
extends Control

signal character_level_upgrade_requested(mode: String)
signal hero_skill_purchase_requested(skill_id: String)
signal ability_skill_purchase_requested(skill_id: String)
signal ability_unlock_requested(ability_id: String)
signal closed

@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/Header/CloseButton
@onready var header_resource_value_label: Label = $PanelContainer/MarginContainer/VBoxContainer/Header/HeaderResourceContainer/ResourceValueLabel
@onready var buy_mode_selector: BuyModeSelector = $PanelContainer/MarginContainer/VBoxContainer/BuyModeSelector
@onready var upgrade_panel: UpgradePanel = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/UpgradePanel
@onready var upgrade_skill_popup: UpgradeSkillPopup = $UpgradeSkillPopup

var current_state: ClickerState = null


func _ready() -> void:
	ButtonVisualUtils.setup_image_button(close_button, "ui.sheet.close_button", Color.WHITE)
	UiFontConfig.apply_label_font_size(header_resource_value_label, UiFontConfig.SHEET_RESOURCE_VALUE_FONT_SIZE)
	close_button.pressed.connect(_on_close_pressed)
	buy_mode_selector.buy_mode_changed.connect(_on_buy_mode_changed)
	upgrade_panel.set_buy_mode(buy_mode_selector.get_selected_mode())
	upgrade_panel.character_level_upgrade_requested.connect(_on_character_level_upgrade_requested)
	upgrade_panel.hero_skill_popup_requested.connect(_on_hero_skill_popup_requested)
	upgrade_panel.ability_skill_popup_requested.connect(_on_ability_skill_popup_requested)
	upgrade_panel.ability_unlock_requested.connect(_on_ability_unlock_requested)
	upgrade_skill_popup.hero_skill_purchase_requested.connect(_on_hero_skill_purchase_requested)
	upgrade_skill_popup.ability_skill_purchase_requested.connect(_on_ability_skill_purchase_requested)
	hide()


func _on_close_pressed() -> void:
	ButtonVisualUtils.flash_button_image_holder(
		close_button.find_child("ButtonImageHolder", false, false),
		"ui.sheet.close_button"
	)
	hide_sheet()


func show_sheet() -> void:
	show()


func hide_sheet() -> void:
	upgrade_skill_popup.hide()
	hide()
	closed.emit()


func update_view(state: ClickerState) -> void:
	current_state = state
	header_resource_value_label.text = NumberFormatter.compact(state.gold)
	upgrade_panel.update_view(state)
	upgrade_skill_popup.refresh_view(state)


func _on_buy_mode_changed(mode: String) -> void:
	upgrade_panel.set_buy_mode(mode)
	if current_state != null:
		update_view(current_state)


func _on_character_level_upgrade_requested(mode: String) -> void:
	character_level_upgrade_requested.emit(mode)


func _on_hero_skill_popup_requested(skill_id: String, anchor_global_position: Vector2) -> void:
	if current_state == null:
		return
	if upgrade_skill_popup.is_showing_skill("hero", skill_id):
		upgrade_skill_popup.hide()
		return
	upgrade_skill_popup.show_skill(current_state, "hero", skill_id, anchor_global_position)


func _on_ability_skill_popup_requested(skill_id: String, anchor_global_position: Vector2) -> void:
	if current_state == null:
		return
	if upgrade_skill_popup.is_showing_skill("ability", skill_id):
		upgrade_skill_popup.hide()
		return
	upgrade_skill_popup.show_skill(current_state, "ability", skill_id, anchor_global_position)


func _on_hero_skill_purchase_requested(skill_id: String) -> void:
	hero_skill_purchase_requested.emit(skill_id)


func _on_ability_skill_purchase_requested(skill_id: String) -> void:
	ability_skill_purchase_requested.emit(skill_id)


func _on_ability_unlock_requested(ability_id: String) -> void:
	ability_unlock_requested.emit(ability_id)


func play_hero_purchase_feedback() -> void:
	upgrade_panel.play_hero_purchase_feedback()


func play_ability_purchase_feedback(ability_id: String) -> void:
	upgrade_panel.play_ability_purchase_feedback(ability_id)
