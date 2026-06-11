extends SceneTree

# Run with: godot --headless --script res://scripts/tools/ValidateTaskConfig.gd

const CSV_PATH: String = "res://localization/game_text.csv"


func _init() -> void:
	var errors: Array[String] = []
	var warnings: Array[String] = []

	# --- TaskConfig structural validation ---
	var config_errors: Array[String] = TaskConfig.validate()
	errors.append_array(config_errors)

	# --- Localization key check ---
	var csv_keys: Dictionary = {}
	var parse_errors: Array[String] = []
	_parse_csv(CSV_PATH, csv_keys, parse_errors)
	errors.append_array(parse_errors)

	if parse_errors.is_empty():
		for task: Dictionary in TaskConfig.get_all():
			var task_id: String = String(task.get("id", ""))
			var title_key: String = String(task.get("title_key", ""))
			if title_key == "":
				continue
			if not csv_keys.has(title_key):
				errors.append("Missing localization key '%s' for task '%s'" % [title_key, task_id])
			elif String(csv_keys[title_key].get("en", "")) == "":
				errors.append("Empty en value for localization key '%s' (task '%s')" % [title_key, task_id])

	# --- Asset catalog and file check ---
	var icons_found: int = 0
	var icons_missing: int = 0

	for task: Dictionary in TaskConfig.get_all():
		var task_id: String = String(task.get("id", ""))
		if task_id == "":
			continue
		var asset_key: String = GameAssetCatalog.task_icon_key(task_id)
		var asset_path: String = GameAssetCatalog.get_path(asset_key)
		if asset_path == "":
			errors.append("No asset catalog entry for task '%s' (key: %s)" % [task_id, asset_key])
		elif ResourceLoader.exists(asset_path):
			icons_found += 1
		else:
			icons_missing += 1
			warnings.append("Task icon file missing (art pending): %s" % asset_path)

	# --- Report ---
	print("")
	print("=== Task Config Validation Report ===")
	print("")

	if errors.is_empty() and warnings.is_empty():
		print("All task config checks passed.")
		print("")

	if not errors.is_empty():
		print("ERRORS (%d):" % errors.size())
		for e: String in errors:
			print("  [ERROR] " + e)
		print("")

	if not warnings.is_empty():
		print("WARNINGS (%d):" % warnings.size())
		for w: String in warnings:
			print("  [WARN]  " + w)
		print("")

	print("--- Summary ---")
	print("Task definitions:    %d" % TaskConfig.TASK_DEFINITIONS.size())
	print("Active task count:   %d" % TaskConfig.ACTIVE_TASK_COUNT)
	print("Task icons found:    %d / %d" % [icons_found, TaskConfig.TASK_DEFINITIONS.size()])
	print("Task icons missing:  %d / %d" % [icons_missing, TaskConfig.TASK_DEFINITIONS.size()])
	print("Errors:              %d" % errors.size())
	print("Warnings:            %d" % warnings.size())
	print("")

	if errors.is_empty():
		print("RESULT: PASS")
		quit(0)
	else:
		print("RESULT: FAIL")
		quit(1)


func _parse_csv(path: String, out_keys: Dictionary, errors: Array[String]) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("Cannot open CSV: " + path)
		return

	var header_line: String = file.get_line()
	var headers: Array = header_line.split(",")
	var key_col: int = -1
	var en_col: int = -1

	for i in range(headers.size()):
		match headers[i].strip_edges():
			"key": key_col = i
			"en":  en_col  = i

	if key_col < 0 or en_col < 0:
		errors.append("CSV missing required columns 'key' and/or 'en'")
		file.close()
		return

	while not file.eof_reached():
		var line: String = file.get_line()
		if line.strip_edges() == "":
			continue
		var cols: Array = _split_csv_line(line)
		if cols.size() <= key_col:
			continue
		var key: String = cols[key_col].strip_edges()
		if key == "":
			continue
		var en_val: String = cols[en_col].strip_edges() if en_col < cols.size() else ""
		out_keys[key] = {"en": en_val}

	file.close()


func _split_csv_line(line: String) -> Array:
	var result: Array = []
	var field: String = ""
	var in_quotes: bool = false
	var i: int = 0
	while i < line.length():
		var ch: String = line[i]
		if in_quotes:
			if ch == "\"":
				if i + 1 < line.length() and line[i + 1] == "\"":
					field += "\""
					i += 1
				else:
					in_quotes = false
			else:
				field += ch
		else:
			if ch == "\"":
				in_quotes = true
			elif ch == ",":
				result.append(field)
				field = ""
			else:
				field += ch
		i += 1
	result.append(field)
	return result
