class_name UpgradePanel
extends Control

signal character_level_upgrade_requested(mode: String)
signal autoclick_purchase_requested
signal gold_bonus_purchase_requested
signal focus_burst_purchase_requested
signal rally_purchase_requested

const BUY_MODES: Array[String] = ["x1", "x10", "x100", "max"]

var selected_buy_mode: String = "x1"
var current_state: ClickerState = null

@onready var upgrade_character_level_button: Button = $VBoxContainer/UpgradeCharacterLevelButton
@onready var buy_autoclick_button: Button = $VBoxContainer/BuyAutoclickButton
@onready var buy_gold_bonus_button: Button = $VBoxContainer/BuyGoldBonusButton
@onready var buy_focus_burst_button: Button = $VBoxContainer/BuyFocusBurstButton
@onready var buy_rally_button: Button = $VBoxContainer/BuyRallyButton


func _ready() -> void:
	upgrade_character_level_button.pressed.connect(_on_upgrade_character_level_button_pressed)
	buy_autoclick_button.pressed.connect(_on_buy_autoclick_button_pressed)
	buy_gold_bonus_button.pressed.connect(_on_buy_gold_bonus_button_pressed)
	buy_focus_burst_button.pressed.connect(_on_buy_focus_burst_button_pressed)
	buy_rally_button.pressed.connect(_on_buy_rally_button_pressed)


func update_view(state: ClickerState) -> void:
	current_state = state
	var bulk_count: int = state.get_character_level_bulk_display_count(selected_buy_mode)
	var bulk_cost: int = state.get_character_level_bulk_display_cost(selected_buy_mode)
	upgrade_character_level_button.text = "Upgrade Character Level x%d - Cost: %d" % [bulk_count, bulk_cost]

	buy_autoclick_button.disabled = state.autoclick_purchased
	buy_gold_bonus_button.disabled = state.gold_bonus_purchased
	buy_focus_burst_button.disabled = state.focus_burst_purchased
	buy_rally_button.disabled = state.rally_purchased

	if state.autoclick_purchased:
		buy_autoclick_button.text = "Autoclick Purchased"
	elif state.autoclick_unlocked:
		buy_autoclick_button.text = "Buy Autoclick - Cost: %d" % state.autoclick_purchase_cost
	else:
		buy_autoclick_button.text = "Autoclick - Requires Level %d" % state.autoclick_unlock_level

	if state.gold_bonus_purchased:
		buy_gold_bonus_button.text = "Gold Bonus Purchased"
	elif state.gold_bonus_unlocked:
		buy_gold_bonus_button.text = "Buy Gold Bonus - Cost: %d" % state.gold_bonus_purchase_cost
	else:
		buy_gold_bonus_button.text = "Gold Bonus - Requires Level %d" % state.gold_bonus_unlock_level

	if state.focus_burst_purchased:
		buy_focus_burst_button.text = "Focus Burst Purchased"
	elif state.focus_burst_unlocked:
		buy_focus_burst_button.text = "Buy Focus Burst - Cost: %d" % state.focus_burst_purchase_cost
	else:
		buy_focus_burst_button.text = "Focus Burst - Requires Level %d" % state.focus_burst_unlock_level

	if state.rally_purchased:
		buy_rally_button.text = "Rally Purchased"
	elif state.rally_unlocked:
		buy_rally_button.text = "Buy Rally - Cost: %d" % state.rally_purchase_cost
	else:
		buy_rally_button.text = "Rally - Requires Level %d" % state.rally_unlock_level


func _on_upgrade_character_level_button_pressed() -> void:
	character_level_upgrade_requested.emit(selected_buy_mode)


func _on_buy_autoclick_button_pressed() -> void:
	autoclick_purchase_requested.emit()


func _on_buy_gold_bonus_button_pressed() -> void:
	gold_bonus_purchase_requested.emit()


func _on_buy_focus_burst_button_pressed() -> void:
	focus_burst_purchase_requested.emit()


func _on_buy_rally_button_pressed() -> void:
	rally_purchase_requested.emit()


func set_buy_mode(mode: String) -> void:
	if not BUY_MODES.has(mode):
		return
	selected_buy_mode = mode
