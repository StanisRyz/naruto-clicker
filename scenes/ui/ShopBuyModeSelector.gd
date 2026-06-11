class_name ShopBuyModeSelector
extends Control

signal buy_mode_changed(mode: String)

const BUY_MODES: Array[String] = ["x1", "x2", "x3", "x4"]

var selected_mode: String = "x1"

@onready var buttons: Array[Button] = [
	$HBoxContainer/X1Button,
	$HBoxContainer/X2Button,
	$HBoxContainer/X3Button,
	$HBoxContainer/X4Button,
]


func _ready() -> void:
	buttons[0].pressed.connect(func() -> void: set_selected_mode("x1"))
	buttons[1].pressed.connect(func() -> void: set_selected_mode("x2"))
	buttons[2].pressed.connect(func() -> void: set_selected_mode("x3"))
	buttons[3].pressed.connect(func() -> void: set_selected_mode("x4"))
	for button in buttons:
		ButtonVisualUtils.clear_text_button_background(button)
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
		button.text = "[%s]" % mode if mode == selected_mode else mode
