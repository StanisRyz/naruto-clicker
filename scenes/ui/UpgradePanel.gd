class_name UpgradePanel
extends Control

signal character_level_upgrade_requested

@onready var upgrade_character_level_button: Button = $UpgradeCharacterLevelButton


func _ready() -> void:
	upgrade_character_level_button.pressed.connect(_on_upgrade_character_level_button_pressed)


func update_view(state: ClickerState) -> void:
	upgrade_character_level_button.text = "Upgrade Character Level - Cost: 1"


func _on_upgrade_character_level_button_pressed() -> void:
	character_level_upgrade_requested.emit()
