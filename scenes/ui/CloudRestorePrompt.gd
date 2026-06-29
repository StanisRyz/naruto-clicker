class_name CloudRestorePrompt
extends Control

# Startup cloud-restore confirmation dialog.
# Shown on Android/account when backend has a newer save than local.
# Does NOT call SaveManager or Platform — ClickerScreen owns all data operations.

signal load_cloud_confirmed
signal keep_local_confirmed

@onready var _title_label: Label = $CenterContainer/InnerPanel/MarginContainer/VBoxContainer/TitleLabel
@onready var _message_label: Label = $CenterContainer/InnerPanel/MarginContainer/VBoxContainer/MessageLabel
@onready var _timestamp_label: Label = $CenterContainer/InnerPanel/MarginContainer/VBoxContainer/TimestampLabel
@onready var _load_button: Button = $CenterContainer/InnerPanel/MarginContainer/VBoxContainer/LoadButton
@onready var _keep_button: Button = $CenterContainer/InnerPanel/MarginContainer/VBoxContainer/KeepButton


func _ready() -> void:
	_load_button.pressed.connect(_on_load_pressed)
	_keep_button.pressed.connect(_on_keep_pressed)
	hide()


func show_prompt(mode: String, local_timestamp: int, cloud_timestamp: int) -> void:
	var L := LocalizationManager
	_title_label.text = L.tr_key("cloud_restore.title")
	match mode:
		"cloud_found_no_local":
			_message_label.text = L.tr_key("cloud_restore.message_no_local")
			_timestamp_label.visible = false
		"cloud_newer_than_local":
			_message_label.text = L.tr_key("cloud_restore.message_newer")
			_timestamp_label.text = L.format_key("cloud_restore.timestamp_info", {
				"local_time": _format_timestamp(local_timestamp),
				"cloud_time": _format_timestamp(cloud_timestamp),
			})
			_timestamp_label.visible = true
		_:
			_message_label.text = L.tr_key("cloud_restore.message_newer")
			_timestamp_label.visible = false
	_load_button.text = L.tr_key("cloud_restore.load_cloud")
	_keep_button.text = L.tr_key("cloud_restore.keep_local")
	show()
	move_to_front()


func hide_prompt() -> void:
	hide()


func _on_load_pressed() -> void:
	load_cloud_confirmed.emit()


func _on_keep_pressed() -> void:
	keep_local_confirmed.emit()


func _format_timestamp(unix_time: int) -> String:
	if unix_time <= 0:
		return "—"
	var dt: Dictionary = Time.get_datetime_dict_from_unix_time(unix_time)
	return "%02d.%02d %02d:%02d" % [int(dt.day), int(dt.month), int(dt.hour), int(dt.minute)]
