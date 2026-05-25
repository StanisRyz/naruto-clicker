class_name UpgradeSheet
extends Control

signal character_level_upgrade_requested
signal autoclick_purchase_requested
signal gold_bonus_purchase_requested
signal prestige_requested
signal prestige_confirmed

@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/Header/CloseButton
@onready var upgrade_panel: UpgradePanel = $PanelContainer/MarginContainer/VBoxContainer/UpgradePanel
@onready var prestige_confirm_dialog = $PrestigeConfirmDialog


func _ready() -> void:
	close_button.pressed.connect(hide_sheet)
	upgrade_panel.character_level_upgrade_requested.connect(_on_character_level_upgrade_requested)
	upgrade_panel.autoclick_purchase_requested.connect(_on_autoclick_purchase_requested)
	upgrade_panel.gold_bonus_purchase_requested.connect(_on_gold_bonus_purchase_requested)
	upgrade_panel.prestige_requested.connect(_on_panel_prestige_requested)
	prestige_confirm_dialog.confirmed.connect(_on_dialog_prestige_confirmed)
	hide()


func show_sheet() -> void:
	show()


func hide_sheet() -> void:
	prestige_confirm_dialog.hide()
	hide()


func update_view(state: ClickerState) -> void:
	upgrade_panel.update_view(state)


func show_prestige_confirm(state: ClickerState) -> void:
	var new_points: int = state.prestige_points + state.get_prestige_reward()
	var dmg_mult: float = 1.0 + new_points * state.prestige_damage_bonus_per_point
	var gold_mult: float = 1.0 + new_points * state.prestige_gold_bonus_per_point
	prestige_confirm_dialog.show_dialog(
		state.current_level, state.get_prestige_reward(), dmg_mult, gold_mult
	)


func _on_character_level_upgrade_requested() -> void:
	character_level_upgrade_requested.emit()


func _on_autoclick_purchase_requested() -> void:
	autoclick_purchase_requested.emit()


func _on_gold_bonus_purchase_requested() -> void:
	gold_bonus_purchase_requested.emit()


func _on_panel_prestige_requested() -> void:
	prestige_requested.emit()


func _on_dialog_prestige_confirmed() -> void:
	prestige_confirmed.emit()
