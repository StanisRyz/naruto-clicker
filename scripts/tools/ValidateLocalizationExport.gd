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
	# 4-row partner card keys
	"partner.name_count",
	"partner.damage_summary",
	"partner.milestone_next",
	"partner.milestone_max",
	"partner.hire_button",
	# 4-row hero card keys
	"upgrade.hero.name_level_short",
	"upgrade.hero.damage_summary",
	"upgrade.hero.milestone_next",
	"upgrade.hero.milestone_max",
	"upgrade.hero.button",
	# Ability card keys
	"upgrade.ability.rank_info",
	"upgrade.ability.status_hint",
	"upgrade.ability.purchased",
	"upgrade.ability.requires_level",
	"upgrade.ability.buy",
]

const OBSOLETE_KEYS: Array = [
	"partner.name_header",
	"partner.dps_next_milestone",
	"partner.dps_max",
	"partner.requires_previous",
	"upgrade.hero.name_level",
	"upgrade.hero.damage_info",
	"upgrade.hero.damage_max",
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
	var csv_rows: Array = []   # Array of {key, en, ru}
	var csv_keys: Dictionary = {}

	if not FileAccess.file_exists(CSV_PATH):
		errors.append("CSV missing: " + CSV_PATH)
	else:
		var file := FileAccess.open(CSV_PATH, FileAccess.READ)
		if file == null:
			errors.append("CSV cannot be opened: " + CSV_PATH)
		else:
			# --- Header check ---
			var header_line: String = file.get_line()
			var headers: Array = _split_csv_line(header_line)
			var key_col: int = -1
			var en_col: int = -1
			var ru_col: int = -1
			var context_col: int = -1
			var notes_col: int = -1
			for i in range(headers.size()):
				match headers[i].strip_edges():
					"key":     key_col     = i
					"en":      en_col      = i
					"ru":      ru_col      = i
					"context": context_col = i
					"notes":   notes_col   = i

			if key_col < 0:
				errors.append("CSV missing required column: key")
			if en_col < 0:
				errors.append("CSV missing required column: en")
			if ru_col < 0:
				warnings.append("CSV missing column: ru (Russian translations unavailable)")
			if headers.size() != 5:
				errors.append("CSV header must have exactly 5 columns (key,en,ru,context,notes), found %d" % headers.size())

			var row_num: int = 1
			while not file.eof_reached():
				var line: String = file.get_line()
				row_num += 1
				if line.strip_edges() == "":
					continue
				var cols: Array = _split_csv_line(line)
				if cols.size() != 5:
					errors.append("Row %d has %d columns (expected 5): %s" % [row_num, cols.size(), line.left(80)])
					continue
				if key_col < 0 or en_col < 0:
					continue
				var k: String = cols[key_col].strip_edges()
				if k == "":
					errors.append("Row %d has empty key" % row_num)
					continue
				if csv_keys.has(k):
					errors.append("Duplicate key on row %d: %s" % [row_num, k])
					continue
				var en_val: String = cols[en_col]
				var ru_val: String = cols[ru_col] if ru_col >= 0 else ""
				csv_keys[k] = true
				csv_rows.append({"key": k, "en": en_val, "ru": ru_val})

			file.close()

			# Required keys in CSV
			for req in REQUIRED_KEYS:
				if not csv_keys.has(req):
					errors.append("CSV missing required key: " + req)

			# Obsolete key warnings
			for obs in OBSOLETE_KEYS:
				if csv_keys.has(obs):
					warnings.append("Obsolete key still present in CSV (should be removed): " + obs)

			# Placeholder consistency
			for row in csv_rows:
				var en_placeholders: Array = _extract_placeholders(row["en"])
				var ru_val: String = row["ru"]
				if ru_val == "":
					continue
				var ru_placeholders: Array = _extract_placeholders(ru_val)
				for ph in en_placeholders:
					if not ph in ru_placeholders:
						errors.append("Placeholder {%s} in 'en' missing from 'ru' for key: %s" % [ph, row["key"]])
				for ph in ru_placeholders:
					if not ph in en_placeholders:
						errors.append("Placeholder {%s} in 'ru' not in 'en' for key: %s" % [ph, row["key"]])

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


func _extract_placeholders(text: String) -> Array:
	var result: Array = []
	var i: int = 0
	while i < text.length():
		if text[i] == "{":
			var j: int = text.find("}", i + 1)
			if j > i:
				var ph: String = text.substr(i + 1, j - i - 1)
				if ph != "" and not ph in result:
					result.append(ph)
				i = j + 1
			else:
				i += 1
		else:
			i += 1
	return result


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
