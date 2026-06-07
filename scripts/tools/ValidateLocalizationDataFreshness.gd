extends SceneTree

# Run with: godot --headless --script res://scripts/tools/ValidateLocalizationDataFreshness.gd
# Verifies that LocalizationData.gd is in sync with game_text.csv.
# Exit 0 = fresh, Exit 1 = stale.

const CSV_PATH: String = "res://localization/game_text.csv"

const BuiltinData = preload("res://scripts/ui/LocalizationData.gd")


func _init() -> void:
	var errors: Array[String] = []
	var warnings: Array[String] = []

	# --- Parse CSV ---
	var csv_en: Dictionary = {}
	var csv_ru: Dictionary = {}

	if not FileAccess.file_exists(CSV_PATH):
		errors.append("CSV missing: " + CSV_PATH)
		_report(errors, warnings, 0, 0)
		return

	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	if file == null:
		errors.append("Cannot open CSV: " + CSV_PATH)
		_report(errors, warnings, 0, 0)
		return

	var header_line: String = file.get_line()
	var headers: PackedStringArray = header_line.split(",")
	var key_col: int = -1
	var en_col: int = -1
	var ru_col: int = -1
	for i in range(headers.size()):
		match headers[i].strip_edges():
			"key": key_col = i
			"en":  en_col  = i
			"ru":  ru_col  = i

	if key_col < 0 or en_col < 0 or ru_col < 0:
		errors.append("CSV missing required columns (key/en/ru)")
		file.close()
		_report(errors, warnings, 0, 0)
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
		csv_en[key] = cols[en_col] if en_col < cols.size() else ""
		csv_ru[key] = cols[ru_col] if ru_col < cols.size() else ""
	file.close()

	# --- Load built-in data ---
	var builtin: Dictionary = BuiltinData.get_translations()
	var builtin_en: Dictionary = builtin.get("en", {})
	var builtin_ru: Dictionary = builtin.get("ru", {})

	# --- Compare key counts ---
	if csv_en.size() != builtin_en.size():
		warnings.append("Key count mismatch: CSV=%d LocalizationData=%d" % [csv_en.size(), builtin_en.size()])

	# --- CSV keys missing from built-in ---
	for key in csv_en.keys():
		if not builtin_en.has(key):
			errors.append("CSV key missing from LocalizationData.gd: %s" % key)

	# --- Built-in keys not in CSV ---
	for key in builtin_en.keys():
		if not csv_en.has(key):
			errors.append("LocalizationData.gd key not in CSV (stale): %s" % key)

	# --- Value mismatches ---
	for key in csv_en.keys():
		if not builtin_en.has(key):
			continue
		var csv_val: String = csv_en[key]
		var builtin_val: String = builtin_en[key]
		if csv_val != builtin_val:
			errors.append("EN mismatch for '%s': CSV=%s | LocalizationData=%s" % [key, csv_val, builtin_val])

		var csv_ru_val: String = csv_ru.get(key, "")
		var builtin_ru_val: String = builtin_ru.get(key, "")
		if csv_ru_val != builtin_ru_val:
			errors.append("RU mismatch for '%s': CSV=%s | LocalizationData=%s" % [key, csv_ru_val, builtin_ru_val])

	_report(errors, warnings, csv_en.size(), builtin_en.size())


func _report(errors: Array[String], warnings: Array[String], csv_count: int, builtin_count: int) -> void:
	print("")
	print("=== Localization Data Freshness Validation ===")
	print("")

	if errors.is_empty() and warnings.is_empty():
		print("LocalizationData.gd is in sync with game_text.csv.")
		print("")

	if not errors.is_empty():
		print("ERRORS (%d):" % errors.size())
		for e in errors:
			print("  [ERROR] " + e)
		print("")

	if not warnings.is_empty():
		print("WARNINGS (%d):" % warnings.size())
		for w in warnings:
			print("  [WARN]  " + w)
		print("")

	print("--- Summary ---")
	print("CSV keys:               %d" % csv_count)
	print("LocalizationData keys:  %d" % builtin_count)
	print("Errors:                 %d" % errors.size())
	print("Warnings:               %d" % warnings.size())
	print("")

	if errors.is_empty():
		print("RESULT: PASS — LocalizationData.gd is fresh.")
		quit(0)
	else:
		print("RESULT: FAIL — LocalizationData.gd is stale. Run GenerateLocalizationData.gd.")
		quit(1)


func _split_csv_line(line: String) -> Array:
	var result: Array = []
	var field: String = ""
	var in_quotes: bool = false
	var i: int = 0
	while i < line.length():
		var ch: String = line[i]
		if in_quotes:
			if ch == '"':
				if i + 1 < line.length() and line[i + 1] == '"':
					field += '"'
					i += 1
				else:
					in_quotes = false
			else:
				field += ch
		else:
			if ch == '"':
				in_quotes = true
			elif ch == ",":
				result.append(field)
				field = ""
			else:
				field += ch
		i += 1
	result.append(field)
	return result
