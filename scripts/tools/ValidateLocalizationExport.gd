extends SceneTree

# Run with: godot --headless --script res://scripts/tools/ValidateLocalizationExport.gd

const CSV_PATH: String = "res://localization/game_text.csv"
const EXPORT_PRESETS_PATH: String = "res://export_presets.cfg"
const REQUIRED_KEYS: Array = [
	"ui.tab.upgrades",
	"ui.tab.partners",
	"settings.language",
	"zone.01.name",
	"partner.01.name",
]

const BuiltinLocalizationData = preload("res://scripts/ui/LocalizationData.gd")


func _init() -> void:
	var errors: Array[String] = []
	var warnings: Array[String] = []

	# --- Built-in LocalizationData.gd ---
	var builtin: Dictionary = BuiltinLocalizationData.get_translations()
	var builtin_en: Dictionary = builtin.get("en", {})
	var builtin_ru: Dictionary = builtin.get("ru", {})

	if not builtin.has("en") or builtin_en.size() == 0:
		errors.append("LocalizationData built-in 'en' dictionary is empty or missing")
	if not builtin.has("ru"):
		errors.append("LocalizationData built-in 'ru' dictionary missing")

	for req in REQUIRED_KEYS:
		if not builtin_en.has(req):
			errors.append("Built-in data missing required key: " + req)
		elif String(builtin_en[req]) == "":
			errors.append("Built-in data has empty English value for required key: " + req)

	# --- CSV exists and can be opened ---
	var csv_keys: Dictionary = {}
	if not FileAccess.file_exists(CSV_PATH):
		errors.append("CSV missing: " + CSV_PATH)
	else:
		var file := FileAccess.open(CSV_PATH, FileAccess.READ)
		if file == null:
			errors.append("CSV cannot be opened: " + CSV_PATH)
		else:
			var header_line: String = file.get_line()
			var headers: Array = header_line.split(",")
			var has_key_col: bool = false
			var has_en_col: bool = false
			var has_ru_col: bool = false
			for h in headers:
				match h.strip_edges():
					"key": has_key_col = true
					"en":  has_en_col  = true
					"ru":  has_ru_col  = true
			if not has_key_col:
				errors.append("CSV missing required column: key")
			if not has_en_col:
				errors.append("CSV missing required column: en")
			if not has_ru_col:
				warnings.append("CSV missing column: ru (Russian translations unavailable)")

			if has_key_col and has_en_col:
				while not file.eof_reached():
					var line: String = file.get_line()
					if line.strip_edges() == "":
						continue
					var cols: Array = _split_csv_line(line)
					if cols.size() < 1:
						continue
					var k: String = cols[0].strip_edges()
					if k != "":
						csv_keys[k] = true
				for req in REQUIRED_KEYS:
					if not csv_keys.has(req):
						errors.append("CSV missing required key: " + req)

			file.close()

	# --- Cross-check CSV vs built-in ---
	if csv_keys.size() > 0 and builtin_en.size() > 0:
		if csv_keys.size() != builtin_en.size():
			warnings.append(
				"Key count mismatch: CSV has %d keys, built-in has %d keys. Run GenerateLocalizationData.gd." % [
					csv_keys.size(), builtin_en.size()
				]
			)
		for csv_key in csv_keys.keys():
			if not builtin_en.has(csv_key):
				errors.append("CSV key missing from built-in LocalizationData: " + csv_key)
		for builtin_key in builtin_en.keys():
			if not csv_keys.has(builtin_key):
				warnings.append("Built-in key not in CSV (stale?): " + builtin_key)

	# --- export_presets.cfg ---
	if not FileAccess.file_exists(EXPORT_PRESETS_PATH):
		errors.append("export_presets.cfg not found: " + EXPORT_PRESETS_PATH)
	else:
		var pfile := FileAccess.open(EXPORT_PRESETS_PATH, FileAccess.READ)
		if pfile == null:
			errors.append("Cannot open export_presets.cfg")
		else:
			var content: String = pfile.get_as_text()
			pfile.close()
			_check_preset_include(content, "Web", errors)
			_check_preset_include(content, "Android", errors)

	# --- Report ---
	print("")
	print("=== Localization Export Validation Report ===")
	print("")

	if errors.is_empty() and warnings.is_empty():
		print("All localization export checks passed.")
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
	print("Built-in English keys:  %d" % builtin_en.size())
	print("Built-in Russian values: %d" % _count_nonempty(builtin_ru))
	print("CSV keys:               %d" % csv_keys.size())
	print("Errors:                 %d" % errors.size())
	print("Warnings:               %d" % warnings.size())
	print("")

	if errors.is_empty():
		print("RESULT: PASS")
		quit(0)
	else:
		print("RESULT: FAIL")
		quit(1)


func _count_nonempty(d: Dictionary) -> int:
	var n: int = 0
	for v in d.values():
		if str(v) != "":
			n += 1
	return n


func _check_preset_include(content: String, preset_name: String, errors: Array[String]) -> void:
	var lines: PackedStringArray = content.split("\n")
	var in_preset: bool = false
	for line in lines:
		var stripped: String = line.strip_edges()
		if stripped.begins_with("name="):
			var name_val: String = stripped.trim_prefix("name=").strip_edges().trim_prefix('"').trim_suffix('"')
			in_preset = (name_val == preset_name)
		if in_preset and stripped.begins_with("include_filter="):
			if "localization/*.csv" in stripped:
				return
			else:
				errors.append("%s preset include_filter missing 'localization/*.csv': %s" % [preset_name, stripped])
				return
	errors.append("%s preset not found or has no include_filter line in export_presets.cfg" % preset_name)


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
