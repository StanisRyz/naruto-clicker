class_name GuestMigrationPrompt
extends Control

# Guest → Account migration prompt.
# Shown on Android when a guest player logs in/registers mid-session.
# Does NOT call SaveManager or Platform — ClickerScreen owns all data operations.
# Only emits user choice via signals.

signal save_guest_progress_confirmed
signal not_now_confirmed

@onready var _title_label: Label = $CenterContainer/InnerPanel/MarginContainer/VBoxContainer/TitleLabel
@onready var _message_label: Label = $CenterContainer/InnerPanel/MarginContainer/VBoxContainer/MessageLabel
@onready var _save_button: Button = $CenterContainer/InnerPanel/MarginContainer/VBoxContainer/SaveButton
@onready var _not_now_button: Button = $CenterContainer/InnerPanel/MarginContainer/VBoxContainer/NotNowButton


func _ready() -> void:
	_save_button.pressed.connect(_on_save_pressed)
	_not_now_button.pressed.connect(_on_not_now_pressed)
	hide()


func show_prompt() -> void:
	var L := LocalizationManager
	_title_label.text = L.tr_key("guest_migration.title")
	_message_label.text = L.tr_key("guest_migration.message")
	_save_button.text = L.tr_key("guest_migration.save_to_cloud")
	_not_now_button.text = L.tr_key("guest_migration.not_now")
	show()
	move_to_front()


func hide_prompt() -> void:
	hide()


func _on_save_pressed() -> void:
	save_guest_progress_confirmed.emit()


func _on_not_now_pressed() -> void:
	not_now_confirmed.emit()
