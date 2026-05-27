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
@onready var autoclick_icon: ColorRect = $AutoclickButton/ImageHolder
@onready var gold_bonus_icon: ColorRect = $GoldBonusButton/ImageHolder
@onready var focus_burst_icon: ColorRect = $FocusBurstButton/ImageHolder
@onready var rally_icon: ColorRect = $RallyButton/ImageHolder


func _ready() -> void:
	autoclick_button.pressed.connect(_on_autoclick_button_pressed)
	gold_bonus_button.pressed.connect(_on_gold_bonus_button_pressed)
	focus_burst_button.pressed.connect(_on_focus_burst_button_pressed)
	rally_button.pressed.connect(_on_rally_button_pressed)


func update_view(
	state: ClickerState,
	_autoclick_time_left: float,
	_gold_bonus_time_left: float,
	autoclick_cooldown_left: float,
	gold_bonus_cooldown_left: float,
	_focus_burst_time_left: float,
	_rally_time_left: float,
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

	autoclick_button.text = ""
	gold_bonus_button.text = ""
	focus_burst_button.text = ""
	rally_button.text = ""

	_update_icon_color(autoclick_icon, state.autoclick_purchased, state.autoclick_active, autoclick_cooldown_left)
	_update_icon_color(gold_bonus_icon, state.gold_bonus_purchased, state.gold_bonus_active, gold_bonus_cooldown_left)
	_update_icon_color(focus_burst_icon, state.focus_burst_purchased, state.focus_burst_active, focus_burst_cooldown_left)
	_update_icon_color(rally_icon, state.rally_purchased, state.rally_active, rally_cooldown_left)


func _on_autoclick_button_pressed() -> void:
	autoclick_requested.emit()


func _on_gold_bonus_button_pressed() -> void:
	gold_bonus_requested.emit()


func _on_focus_burst_button_pressed() -> void:
	focus_burst_requested.emit()


func _on_rally_button_pressed() -> void:
	rally_requested.emit()


func _update_icon_color(icon: ColorRect, purchased: bool, active: bool, cooldown_left: float) -> void:
	if not purchased:
		icon.color = Color(0.25, 0.25, 0.25, 0.65)
	elif active:
		icon.color = Color(1.0, 1.0, 1.0, 1.0)
	elif cooldown_left > 0.0:
		icon.color = Color(0.55, 0.55, 0.55, 1.0)
	else:
		icon.color = Color.WHITE
