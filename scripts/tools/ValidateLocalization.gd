extends SceneTree

# Run with: godot --headless --script res://scripts/tools/ValidateLocalization.gd

const CSV_PATH: String = "res://localization/game_text.csv"
const BOSS_ZONE_COUNT: int = 21

func _init() -> void:
	var errors: Array[String] = []
	var warnings: Array[String] = []

	# --- Parse CSV ---
	var csv_keys: Dictionary = {}  # key -> {en, ru}
	var parse_ok: bool = _parse_csv(CSV_PATH, csv_keys, errors)

	if parse_ok:
		# --- Check boss keys ---
		for zone_num in range(1, BOSS_ZONE_COUNT + 1):
			var key: String = "zone.%02d.boss" % zone_num
			_check_key(key, csv_keys, errors, warnings)

		# --- Check normal/elite enemy keys from pool data ---
		_check_pool(1,  15, 4,  csv_keys, errors, warnings)
		_check_pool(11, 15, 5,  csv_keys, errors, warnings)
		_check_pool(17, 9,  3,  csv_keys, errors, warnings)

	# --- Report ---
	print("")
	print("=== Localization Validation Report ===")
	print("")

	if errors.is_empty() and warnings.is_empty():
		print("All required localization keys are present.")
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

	var total_keys: int = csv_keys.size()
	print("--- Summary ---")
	print("CSV keys loaded:  %d" % total_keys)
	print("Errors:           %d" % errors.size())
	print("Warnings:         %d" % warnings.size())
	print("")

	if errors.is_empty():
		print("RESULT: PASS")
		quit(0)
	else:
		print("RESULT: FAIL")
		quit(1)


func _parse_csv(path: String, out_keys: Dictionary, errors: Array[String]) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("Cannot open CSV: " + path)
		return false

	var header_line: String = file.get_line()
	var headers: Array = header_line.split(",")
	var key_col: int = -1
	var en_col: int  = -1
	var ru_col: int  = -1

	for i in range(headers.size()):
		match headers[i].strip_edges():
			"key": key_col = i
			"en":  en_col  = i
			"ru":  ru_col  = i

	if key_col < 0 or en_col < 0:
		errors.append("CSV missing required columns 'key' and/or 'en'")
		file.close()
		return false

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
		var ru_val: String = cols[ru_col].strip_edges() if ru_col >= 0 and ru_col < cols.size() else ""
		out_keys[key] = {"en": en_val, "ru": ru_val}

	file.close()
	return true


func _split_csv_line(line: String) -> Array:
	# Minimal CSV split that handles double-quoted fields.
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


func _check_pool(pool_num: int, enemy_count: int, elite_count: int,
		csv_keys: Dictionary, errors: Array[String], warnings: Array[String]) -> void:
	var pool_tag: String = "pool_%02d" % pool_num
	for i in range(1, enemy_count + 1):
		_check_key("enemy.%s.enemy_%02d.name" % [pool_tag, i], csv_keys, errors, warnings)
	for i in range(1, elite_count + 1):
		_check_key("enemy.%s.elite_%02d.name" % [pool_tag, i], csv_keys, errors, warnings)


func _check_key(key: String, csv_keys: Dictionary,
		errors: Array[String], warnings: Array[String]) -> void:
	if not csv_keys.has(key):
		errors.append("Missing key: " + key)
		return
	var entry: Dictionary = csv_keys[key]
	if String(entry.get("en", "")) == "":
		errors.append("Missing en value for key: " + key)
	if String(entry.get("ru", "")) == "":
		warnings.append("Missing ru translation for key: " + key)
