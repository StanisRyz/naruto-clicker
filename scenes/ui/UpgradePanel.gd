class_name UpgradePanel
extends Control

signal character_level_upgrade_requested
signal autoclick_purchase_requested
signal gold_bonus_purchase_requested

@onready var upgrade_character_level_button: Button = $VBoxContainer/UpgradeCharacterLevelButton
@onready var buy_autoclick_button: Button = $VBoxContainer/BuyAutoclickButton
@onready var buy_gold_bonus_button: Button = $VBoxContainer/BuyGoldBonusButton


func _ready() -> void:
	upgrade_character_level_button.pressed.connect(_on_upgrade_character_level_button_pressed)
	buy_autoclick_button.pressed.connect(_on_buy_autoclick_button_pressed)
	buy_gold_bonus_button.pressed.connect(_on_buy_gold_bonus_button_pressed)


func update_view(state: ClickerState) -> void:
	upgrade_character_level_button.text = "Upgrade Character Level - Cost: %d" % state.character_level_upgrade_cost
	buy_autoclick_button.disabled = state.autoclick_purchased
	buy_gold_bonus_button.disabled = state.gold_bonus_purchased

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


func _on_upgrade_character_level_button_pressed() -> void:
	character_level_upgrade_requested.emit()


func _on_buy_autoclick_button_pressed() -> void:
	autoclick_purchase_requested.emit()


func _on_buy_gold_bonus_button_pressed() -> void:
	gold_bonus_purchase_requested.emit()
