extends SceneTree

# Run with: godot --headless --script res://scripts/tools/GenerateLocalizationData.gd

const CSV_PATH: String = "res://localization/game_text.csv"
const OUTPUT_PATH: String = "res://scripts/ui/LocalizationData.gd"

const Generator = preload("res://scripts/tools/LocalizationDataGenerator.gd")


func _init() -> void:
	var result: Dictionary = Generator.generate(CSV_PATH, OUTPUT_PATH)
	if result["ok"]:
		print("GenerateLocalizationData: generated %d keys -> %s" % [result["key_count"], OUTPUT_PATH])
		quit(0)
	else:
		for e: String in result["errors"]:
			print("[ERROR] " + e)
		quit(1)
