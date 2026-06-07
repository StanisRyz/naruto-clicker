extends SceneTree

# Run with: godot --headless --script res://scripts/tools/ValidateLocalizationUsage.gd

const CSV_PATH: String = "res://localization/game_text.csv"

const SCRIPTS_ROOT: String = "res://scripts"
const SCENES_ROOT: String = "res://scenes"

# Keys that must have non-empty ru values (hard error if missing)
const REQUIRED_RU_PATTERNS: Array = [
	"ability.*.name",
	"ability.*.effect",
	"ability.*.duration",
	"building.*.name",
	"prestige.talent.*.name",
	"building.*.purchase_gain",
	"building.*.total_bonus",
	"prestige.talent.*.purchase_gain",
	"prestige.talent.*.total_bonus",
]

# Effect-like key suffixes that must never be bare passthrough placeholders
const EFFECT_LIKE_SUFFIXES: Array = [".effect", ".description", ".status", ".duration"]

# Keys that are known removed legacy rows — must not appear in any .gd or .tscn file
const REMOVED_LEGACY_KEYS: Array = [
	"ui.progress.hp_pair",
	"upgrade.hero.name_level_short",
	"upgrade.hero.damage_summary",
	"upgrade.hero.milestone_next",
	"upgrade.hero.milestone_max",
	"upgrade.ability.rank_info",
	"upgrade.ability.status_hint",
	"upgrade.ability.card.status",
	"upgrade.ability.card.effect",
	"upgrade.ability.card.duration",
	"upgrade.ability.duration_seconds",
	"partner.name_count",
	"partner.damage_summary",
	"partner.milestone_next",
	"partner.milestone_max",
	"settlement.name_count",
	"settlement.next_milestone",
	"settlement.max_milestones",
	"prestige.gain",
	"prestige.description",
	"prestige.talent_upgrade",
	"prestige.talent_name_level",
]


func _init() -> void:
	var errors: Array[String] = []
	var warnings: Array[String] = []

	# --- Parse CSV ---
	var csv_rows: Array = _parse_csv()
	if csv_rows.is_empty():
		errors.append("Could not read CSV: " + CSV_PATH)
		_report(errors, warnings)
		return

	# --- Check 1: No (legacy) in context or notes ---
	for row in csv_rows:
		var ctx: String = String(row.get("context", ""))
		var notes: String = String(row.get("notes", ""))
		if "(legacy)" in ctx.to_lower() or "(legacy)" in notes.to_lower() or "legacy" in ctx.to_lower() or "legacy" in notes.to_lower():
			errors.append("CSV row still contains 'legacy' marker — key: %s (context: %s)" % [row["key"], ctx])

	# --- Check 2: No bare passthrough placeholders for effect-like keys ---
	for row in csv_rows:
		var key: String = row["key"]
		var is_effect_like: bool = false
		for suffix in EFFECT_LIKE_SUFFIXES:
			if key.ends_with(suffix):
				is_effect_like = true
				break
		if not is_effect_like:
			continue
		var en: String = row.get("en", "")
		var ru: String = row.get("ru", "")
		if _is_bare_passthrough(en) or _is_bare_passthrough(ru):
			errors.append("Effect-like key has bare passthrough placeholder — key: %s (en=%s, ru=%s)" % [key, en, ru])

	# --- Check 3: Removed legacy keys not referenced in scripts/scenes ---
	var script_files: Array = _find_files_recursive(SCRIPTS_ROOT, ".gd")
	var scene_files: Array = _find_files_recursive(SCENES_ROOT, ".tscn")
	var all_source_files: Array = script_files + scene_files

	for legacy_key in REMOVED_LEGACY_KEYS:
		for fpath in all_source_files:
			var content: String = _read_file(fpath)
			if legacy_key in content:
				errors.append("Removed legacy key '%s' is still referenced in: %s" % [legacy_key, fpath])
				break

	# --- Check 4: Required ru values for visible UI keys ---
	for row in csv_rows:
		var key: String = row["key"]
		var ru: String = row.get("ru", "")
		if _matches_any_pattern(key, REQUIRED_RU_PATTERNS) and ru.strip_edges() == "":
			errors.append("Missing required ru translation for key: %s" % key)

	# --- Check 5: Warnings for other empty ru fields ---
	for row in csv_rows:
		var key: String = row["key"]
		var ru: String = row.get("ru", "")
		if ru.strip_edges() == "" and not _matches_any_pattern(key, REQUIRED_RU_PATTERNS):
			warnings.append("Empty ru value for key: %s" % key)

	_report(errors, warnings)


func _is_bare_passthrough(value: String) -> bool:
	var stripped: String = value.strip_edges()
	if stripped.begins_with("{") and stripped.ends_with("}") and not stripped.substr(1, stripped.length() - 2).contains("{"):
		return true
	return false


func _matches_any_pattern(key: String, patterns: Array) -> bool:
	for pattern in patterns:
		if _key_matches_pattern(key, pattern):
			return true
	return false


func _key_matches_pattern(key: String, pattern: String) -> bool:
	var parts_key: PackedStringArray = key.split(".")
	var parts_pat: PackedStringArray = pattern.split(".")
	if parts_key.size() != parts_pat.size():
		return false
	for i in range(parts_pat.size()):
		if parts_pat[i] == "*":
			continue
		if parts_pat[i] != parts_key[i]:
			return false
	return true


func _parse_csv() -> Array:
	var result: Array = []
	if not FileAccess.file_exists(CSV_PATH):
		return result
	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	if file == null:
		return result

	var header_line: String = file.get_line()
	var headers: PackedStringArray = _split_csv_line(header_line)
	var key_col: int = -1
	var en_col: int = -1
	var ru_col: int = -1
	var ctx_col: int = -1
	var notes_col: int = -1
	for i in range(headers.size()):
		match headers[i].strip_edges():
			"key":     key_col     = i
			"en":      en_col      = i
			"ru":      ru_col      = i
			"context": ctx_col     = i
			"notes":   notes_col   = i

	while not file.eof_reached():
		var line: String = file.get_line()
		if line.strip_edges() == "":
			continue
		var cols: PackedStringArray = _split_csv_line(line)
		if cols.size() < 3 or key_col < 0:
			continue
		var key: String = cols[key_col].strip_edges()
		if key == "":
			continue
		result.append({
			"key": key,
			"en": cols[en_col] if en_col >= 0 and en_col < cols.size() else "",
			"ru": cols[ru_col] if ru_col >= 0 and ru_col < cols.size() else "",
			"context": cols[ctx_col] if ctx_col >= 0 and ctx_col < cols.size() else "",
			"notes": cols[notes_col] if notes_col >= 0 and notes_col < cols.size() else "",
		})

	file.close()
	return result


func _find_files_recursive(root: String, extension: String) -> Array:
	var result: Array = []
	var dir := DirAccess.open(root)
	if dir == null:
		return result
	dir.list_dir_begin()
	var fname: String = dir.get_next()
	while fname != "":
		var full: String = root + "/" + fname
		if dir.current_is_dir() and fname != "." and fname != "..":
			result.append_array(_find_files_recursive(full, extension))
		elif fname.ends_with(extension):
			result.append(full)
		fname = dir.get_next()
	dir.list_dir_end()
	return result


func _read_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var content: String = file.get_as_text()
	file.close()
	return content


func _report(errors: Array[String], warnings: Array[String]) -> void:
	print("")
	print("=== Localization Usage Validation Report ===")
	print("")

	if errors.is_empty() and warnings.is_empty():
		print("All localization usage checks passed.")
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
	print("Errors:   %d" % errors.size())
	print("Warnings: %d" % warnings.size())
	print("")

	if errors.is_empty():
		print("RESULT: PASS")
		quit(0)
	else:
		print("RESULT: FAIL")
		quit(1)


func _split_csv_line(line: String) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
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
