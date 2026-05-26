class_name AbilityBar
extends VBoxContainer

signal autoclick_requested
signal gold_bonus_requested
signal focus_burst_requested
signal rally_requested

@onready var autoclick_button: Button = $AutoclickButton
@onready var gold_bonus_button: Button = $GoldBonusButton
@onready var focus_burst_button: Button = $FocusBurstButton
@onready var rally_button: Button = $RallyButton


func _ready() -> void:
	autoclick_button.pressed.connect(_on_autoclick_button_pressed)
	gold_bonus_button.pressed.connect(_on_gold_bonus_button_pressed)
	focus_burst_button.pressed.connect(_on_focus_burst_button_pressed)
	rally_button.pressed.connect(_on_rally_button_pressed)


func update_view(
	state: ClickerState,
	autoclick_time_left: float,
	gold_bonus_time_left: float,
	autoclick_cooldown_left: float,
	gold_bonus_cooldown_left: float,
	focus_burst_time_left: float,
	rally_time_left: float,
	focus_burst_cooldown_left: float,
	rally_cooldown_left: float
) -> void:
	autoclick_button.disabled = (
		not state.autoclick_purchased
		or state.autoclick_active
		or autoclick_cooldown_left > 0.0
	)
	gold_bonus_button.disabled = (
		not state.gold_bonus_purchased
		or state.gold_bonus_active
		or gold_bonus_cooldown_left > 0.0
	)
	focus_burst_button.disabled = (
		not state.focus_burst_purchased
		or state.focus_burst_active
		or focus_burst_cooldown_left > 0.0
	)
	rally_button.disabled = (
		not state.rally_purchased
		or state.rally_active
		or rally_cooldown_left > 0.0
	)

	if state.autoclick_active:
		autoclick_button.text = "Auto %ds" % ceili(autoclick_time_left)
	elif autoclick_cooldown_left > 0.0:
		autoclick_button.text = "Auto CD %ds" % ceili(autoclick_cooldown_left)
	else:
		autoclick_button.text = "Auto"

	if state.gold_bonus_active:
		gold_bonus_button.text = "Gold %ds" % ceili(gold_bonus_time_left)
	elif gold_bonus_cooldown_left > 0.0:
		gold_bonus_button.text = "Gold CD %ds" % ceili(gold_bonus_cooldown_left)
	else:
		gold_bonus_button.text = "Gold x2"

	if state.focus_burst_active:
		focus_burst_button.text = "Focus %ds" % ceili(focus_burst_time_left)
	elif focus_burst_cooldown_left > 0.0:
		focus_burst_button.text = "Focus CD %ds" % ceili(focus_burst_cooldown_left)
	else:
		focus_burst_button.text = "Focus"

	if state.rally_active:
		rally_button.text = "Rally %ds" % ceili(rally_time_left)
	elif rally_cooldown_left > 0.0:
		rally_button.text = "Rally CD %ds" % ceili(rally_cooldown_left)
	else:
		rally_button.text = "Rally"


func _on_autoclick_button_pressed() -> void:
	autoclick_requested.emit()


func _on_gold_bonus_button_pressed() -> void:
	gold_bonus_requested.emit()


func _on_focus_burst_button_pressed() -> void:
	focus_burst_requested.emit()


func _on_rally_button_pressed() -> void:
	rally_requested.emit()
