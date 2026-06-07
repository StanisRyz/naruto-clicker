@tool
class_name LocalizationDataGenerator
extends RefCounted

# Shared localization generation logic.
# Used by GenerateLocalizationData.gd (headless) and LocalizationSyncPlugin.gd (editor).


static func generate(csv_path: String, output_path: String) -> Dictionary:
	var errors: Array[String] = []

	if not FileAccess.file_exists(csv_path):
		return {"ok": false, "key_count": 0, "errors": ["CSV missing: " + csv_path]}

	var file := FileAccess.open(csv_path, FileAccess.READ)
	if file == null:
		return {"ok": false, "key_count": 0, "errors": ["Cannot open CSV: " + csv_path]}

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
		file.close()
		return {"ok": false, "key_count": 0, "errors": ["CSV missing required column: key"]}
	if en_col < 0:
		file.close()
		return {"ok": false, "key_count": 0, "errors": ["CSV missing required column: en"]}
	if ru_col < 0:
		file.close()
		return {"ok": false, "key_count": 0, "errors": ["CSV missing required column: ru"]}

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
		return {"ok": false, "key_count": 0, "errors": errors}

	var lines: PackedStringArray = PackedStringArray()
	lines.append("class_name LocalizationData")
	lines.append("extends RefCounted")
	lines.append("")
	lines.append("# AUTO-GENERATED — do not edit by hand.")
	lines.append("# Source: res://localization/game_text.csv")
	lines.append("# Regenerate with: godot --headless --script res://scripts/tools/GenerateLocalizationData.gd")
	lines.append("# Generated key count: %d" % key_count)
	lines.append("# Generated at: %d" % int(Time.get_unix_time_from_system()))
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

	var out := FileAccess.open(output_path, FileAccess.WRITE)
	if out == null:
		return {"ok": false, "key_count": 0, "errors": ["Cannot write output: " + output_path]}

	out.store_string("\n".join(lines))
	out.close()

	return {"ok": true, "key_count": key_count, "errors": []}


static func _escape(s: String) -> String:
	s = s.replace("\\", "\\\\")
	s = s.replace("\"", "\\\"")
	s = s.replace("\n", "\\n")
	s = s.replace("\r", "\\r")
	return s


static func _split_csv_line(line: String) -> Array:
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
