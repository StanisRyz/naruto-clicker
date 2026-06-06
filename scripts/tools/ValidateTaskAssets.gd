extends SceneTree

# Run with: godot --headless --script res://scripts/tools/ValidateTaskAssets.gd

func _init() -> void:
	var errors: Array[String] = []
	var warnings: Array[String] = []

	var button_folder: String = "res://assets/images/tasks/tasks_button"
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(button_folder)):
		errors.append("MISSING required folder: %s" % button_folder)

	var required_keys: Dictionary = {
		"task.window_button.default": "res://assets/images/tasks/tasks_button/default.png",
		"task.window_button.completed": "res://assets/images/tasks/tasks_button/completed.png",
	}

	for key in required_keys:
		var expected_path: String = required_keys[key]
		var actual_path: String = GameAssetCatalog.get_path(key)
		if actual_path != expected_path:
			errors.append("WRONG path for '%s': got '%s', expected '%s'" % [key, actual_path, expected_path])
		elif not ResourceLoader.exists(actual_path):
			warnings.append("MISSING file (warning only): %s" % actual_path)

	for w in warnings:
		print("  WARNING: %s" % w)
	for e in errors:
		print("  ERROR: %s" % e)

	if errors.is_empty():
		print("ValidateTaskAssets: OK (%d warnings)" % warnings.size())
		quit(0)
	else:
		print("ValidateTaskAssets: FAILED (%d errors, %d warnings)" % [errors.size(), warnings.size()])
		quit(1)
