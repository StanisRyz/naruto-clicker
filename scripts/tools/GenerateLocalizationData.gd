extends SceneTree

# Run with: godot --headless --script res://scripts/tools/GenerateLocalizationData.gd

const CSV_PATH: String = "res://localization/game_text.csv"
const OUTPUT_PATH: String = "res://scripts/ui/LocalizationData.gd"


func _init() -> void:
	var errors: Array[String] = []

	if not FileAccess.file_exists(CSV_PATH):
		print("[ERROR] CSV missing: " + CSV_PATH)
		quit(1)
		return

	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	if file == null:
		print("[ERROR] Cannot open CSV: " + CSV_PATH)
		quit(1)
		return

	var header_line: String = file.get_line()
	var headers: Array = header_line.split(",")
	var key_col: int = -1
	var en_col: int = -1
	var ru_col: int = -1

	for i in range(headers.size()):
		match headers[i].strip_edges():
			"key": key_col = i
			"en":  en_col  = i
			"ru":  ru_col  = i

	if key_col < 0:
		print("[ERROR] CSV missing required column: key")
		quit(1)
		return
	if en_col < 0:
		print("[ERROR] CSV missing required column: en")
		quit(1)
		return
	if ru_col < 0:
		print("[ERROR] CSV missing required column: ru")
		quit(1)
		return

	var en_entries: Array[String] = []
	var ru_entries: Array[String] = []
	var seen_keys: Dictionary = {}
	var key_count: int = 0

	while not file.eof_reached():
		var line: String = file.get_line()
		if line.strip_edges() == "":
			continue
		var fields: Array = _split_csv_line(line)
		if fields.size() <= key_col:
			continue
		var key: String = fields[key_col].strip_edges()
		if key == "":
			continue
		if seen_keys.has(key):
			errors.append("Duplicate localization key: " + key)
			continue
		seen_keys[key] = true

		var en_text: String = fields[en_col] if en_col < fields.size() else ""
		var ru_text: String = fields[ru_col] if ru_col < fields.size() else ""

		en_entries.append("\t\t\"%s\": \"%s\"," % [_escape(key), _escape(en_text)])
		ru_entries.append("\t\t\"%s\": \"%s\"," % [_escape(key), _escape(ru_text)])
		key_count += 1

	file.close()

	if not errors.is_empty():
		for e in errors:
			print("[ERROR] " + e)
		quit(1)
		return

	var lines: PackedStringArray = PackedStringArray()
	lines.append("class_name LocalizationData")
	lines.append("extends RefCounted")
	lines.append("")
	lines.append("# AUTO-GENERATED — do not edit by hand.")
	lines.append("# Source: res://localization/game_text.csv")
	lines.append("# Regenerate with: godot --headless --script res://scripts/tools/GenerateLocalizationData.gd")
	lines.append("")
	lines.append("const TRANSLATIONS: Dictionary = {")
	lines.append("\t\"en\": {")
	for entry in en_entries:
		lines.append(entry)
	lines.append("\t},")
	lines.append("\t\"ru\": {")
	for entry in ru_entries:
		lines.append(entry)
	lines.append("\t},")
	lines.append("}")
	lines.append("")
	lines.append("")
	lines.append("static func get_translations() -> Dictionary:")
	lines.append("\treturn TRANSLATIONS.duplicate(true)")
	lines.append("")

	var out := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if out == null:
		print("[ERROR] Cannot write output file: " + OUTPUT_PATH)
		quit(1)
		return

	out.store_string("\n".join(lines))
	out.close()

	print("GenerateLocalizationData: generated %d keys -> %s" % [key_count, OUTPUT_PATH])
	quit(0)


func _escape(s: String) -> String:
	s = s.replace("\\", "\\\\")
	s = s.replace("\"", "\\\"")
	s = s.replace("\n", "\\n")
	s = s.replace("\r", "\\r")
	return s


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
