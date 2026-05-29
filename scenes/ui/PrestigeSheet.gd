class_name PrestigeSheet
extends Control

signal prestige_requested
signal prestige_talent_purchase_requested(talent_index: int)
signal closed

@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/Header/CloseButton
@onready var header_resource_value_label: Label = $PanelContainer/MarginContainer/VBoxContainer/Header/HeaderResourceContainer/ResourceValueLabel
@onready var prestige_panel: PrestigePanel = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/PrestigePanel
@onready var prestige_confirm_dialog: PrestigeConfirmDialog = $PrestigeConfirmDialog


func _ready() -> void:
	close_button.pressed.connect(hide_sheet)
	prestige_panel.prestige_requested.connect(_on_panel_prestige_requested)
	prestige_panel.prestige_talent_purchase_requested.connect(_on_panel_prestige_talent_purchase_requested)
	hide()


func show_sheet() -> void:
	show()


func hide_sheet() -> void:
	prestige_confirm_dialog.hide()
	hide()
	closed.emit()


func update_view(state: ClickerState) -> void:
	header_resource_value_label.text = "%d" % state.prestige_points_available
	prestige_panel.update_view(state)


func show_prestige_confirm(state: ClickerState) -> void:
	prestige_confirm_dialog.show_dialog(state)


func _on_panel_prestige_requested() -> void:
	prestige_requested.emit()


func _on_panel_prestige_talent_purchase_requested(talent_index: int) -> void:
	prestige_talent_purchase_requested.emit(talent_index)
