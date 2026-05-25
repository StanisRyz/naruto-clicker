class_name UpgradePanel
extends Control

signal damage_upgrade_requested

@onready var upgrade_damage_button: Button = $UpgradeDamageButton


func _ready() -> void:
	upgrade_damage_button.pressed.connect(_on_upgrade_damage_button_pressed)


func update_view(state: ClickerState) -> void:
	upgrade_damage_button.text = "Upgrade Damage - Cost: %d" % state.damage_upgrade_cost


func _on_upgrade_damage_button_pressed() -> void:
	damage_upgrade_requested.emit()
