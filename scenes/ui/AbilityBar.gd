class_name AbilityBar
extends VBoxContainer

signal autoclick_requested
signal gold_bonus_requested

@onready var autoclick_button: Button = $AutoclickButton
@onready var gold_bonus_button: Button = $GoldBonusButton


func _ready() -> void:
	autoclick_button.pressed.connect(_on_autoclick_button_pressed)
	gold_bonus_button.pressed.connect(_on_gold_bonus_button_pressed)


func update_view(state: ClickerState, autoclick_time_left: float, gold_bonus_time_left: float) -> void:
	autoclick_button.disabled = not state.autoclick_purchased
	gold_bonus_button.disabled = not state.gold_bonus_purchased

	if state.autoclick_active:
		autoclick_button.text = "Auto %.0fs" % ceili(autoclick_time_left)
	else:
		autoclick_button.text = "Auto"

	if state.gold_bonus_active:
		gold_bonus_button.text = "Gold %.0fs" % ceili(gold_bonus_time_left)
	else:
		gold_bonus_button.text = "Gold x2"


func _on_autoclick_button_pressed() -> void:
	autoclick_requested.emit()


func _on_gold_bonus_button_pressed() -> void:
	gold_bonus_requested.emit()
