@tool
extends EditorPlugin

const CSV_PATH: String = "res://localization/game_text.csv"
const OUTPUT_PATH: String = "res://scripts/ui/LocalizationData.gd"
const CHECK_INTERVAL_SEC: float = 2.0

const Generator = preload("res://scripts/tools/LocalizationDataGenerator.gd")

var _last_modified_time: int = 0
var _check_timer: float = 0.0
var _export_plugin: LocalizationExportPlugin


# Runs immediately before every export (Android, Web, PC, …).
# This is the mandatory freshness guarantee — the file watcher below is convenience only.
class LocalizationExportPlugin extends EditorExportPlugin:
	func _get_name() -> String:
		return "LocalizationSync"

	func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
		var Gen = load("res://scripts/tools/LocalizationDataGenerator.gd")
		print("LocalizationSyncPlugin: regenerating LocalizationData.gd before export...")
		var result: Dictionary = Gen.generate(
			"res://localization/game_text.csv",
			"res://scripts/ui/LocalizationData.gd"
		)
		if result["ok"]:
			print("LocalizationSyncPlugin: generated %d localization keys." % result["key_count"])
		else:
			for e: String in result["errors"]:
				push_error("LocalizationSyncPlugin: " + e)
			push_error("LocalizationSyncPlugin: export may contain stale localization — fix errors above before shipping.")


func _enter_tree() -> void:
	_last_modified_time = FileAccess.get_modified_time(CSV_PATH)
	_check_timer = 0.0
	_export_plugin = LocalizationExportPlugin.new()
	add_export_plugin(_export_plugin)


func _exit_tree() -> void:
	remove_export_plugin(_export_plugin)
	_export_plugin = null


# Convenience watcher — regenerates on CSV save during active development.
# Not a substitute for the export hook above.
func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		return

	_check_timer += delta
	if _check_timer < CHECK_INTERVAL_SEC:
		return
	_check_timer = 0.0

	var current_time: int = FileAccess.get_modified_time(CSV_PATH)
	if current_time == _last_modified_time:
		return

	_last_modified_time = current_time
	_regenerate()


func _regenerate() -> void:
	var result: Dictionary = Generator.generate(CSV_PATH, OUTPUT_PATH)
	if result["ok"]:
		print("LocalizationSyncPlugin: regenerated LocalizationData.gd from game_text.csv (%d keys)" % result["key_count"])
		EditorInterface.get_resource_filesystem().scan()
	else:
		for e: String in result["errors"]:
			push_error("LocalizationSyncPlugin: " + e)
		print("LocalizationSyncPlugin: regeneration failed — LocalizationData.gd unchanged. See errors above.")
