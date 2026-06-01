class_name BuyModeSelector
extends Control

signal buy_mode_changed(mode: String)

const BUY_MODES: Array[String] = ["x1", "x10", "x100", "max"]

var selected_mode: String = "x1"

@onready var buttons: Array[Button] = [
	$HBoxContainer/X1Button,
	$HBoxContainer/X10Button,
	$HBoxContainer/X100Button,
	$HBoxContainer/MaxButton,
]


func _ready() -> void:
	buttons[0].pressed.connect(func() -> void: set_selected_mode("x1"))
	buttons[1].pressed.connect(func() -> void: set_selected_mode("x10"))
	buttons[2].pressed.connect(func() -> void: set_selected_mode("x100"))
	buttons[3].pressed.connect(func() -> void: set_selected_mode("max"))
	LocalizationManager.language_changed.connect(_update_buttons)
	_update_buttons()


func get_selected_mode() -> String:
	return selected_mode


func set_selected_mode(mode: String) -> void:
	if not BUY_MODES.has(mode):
		return
	if selected_mode == mode:
		_update_buttons()
		return

	selected_mode = mode
	_update_buttons()
	buy_mode_changed.emit(selected_mode)


func _update_buttons() -> void:
	for i in range(buttons.size()):
		var mode: String = BUY_MODES[i]
		var button: Button = buttons[i]
		button.disabled = mode == selected_mode
		button.text = _get_buy_mode_label(mode, button.disabled)


func _get_buy_mode_label(mode: String, selected: bool) -> String:
	var label: String = LocalizationManager.tr_key("ui.buy_mode.max") if mode == "max" else mode
	return "[%s]" % label if selected else label
