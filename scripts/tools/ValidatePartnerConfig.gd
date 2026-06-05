extends SceneTree

# Run with: godot --headless --script res://scripts/tools/ValidatePartnerConfig.gd

const CSV_PATH: String = "res://localization/game_text.csv"
const EXPECTED_PARTNER_COUNT: int = 28
const EXPECTED_PARTNER_NAMES_13: Array = [
	"Partner 1", "Partner 2", "Partner 3", "Field Scout", "Spear Guard",
	"Iron Defender", "Battle Monk", "Elite Samurai", "Shadow Captain",
	"War Sage", "Beast Tamer", "Blade Master", "Legendary Commander",
]


func _init() -> void:
	var errors: Array[String] = []
	var warnings: Array[String] = []

	# --- Config array sizes ---
	var partner_count: int = PartnerConfig.get_partner_count()
	if partner_count != EXPECTED_PARTNER_COUNT:
		errors.append("PartnerConfig.get_partner_count() returned %d, expected %d" % [partner_count, EXPECTED_PARTNER_COUNT])

	if PartnerConfig.PARTNER_NAMES.size() != EXPECTED_PARTNER_COUNT:
		errors.append("PartnerConfig.PARTNER_NAMES.size() is %d, expected %d" % [PartnerConfig.PARTNER_NAMES.size(), EXPECTED_PARTNER_COUNT])

	if BalanceConfig.PARTNER_DPS_VALUES.size() != EXPECTED_PARTNER_COUNT:
		errors.append("BalanceConfig.PARTNER_DPS_VALUES.size() is %d, expected %d" % [BalanceConfig.PARTNER_DPS_VALUES.size(), EXPECTED_PARTNER_COUNT])

	if BalanceConfig.PARTNER_BASE_COSTS.size() != EXPECTED_PARTNER_COUNT:
		errors.append("BalanceConfig.PARTNER_BASE_COSTS.size() is %d, expected %d" % [BalanceConfig.PARTNER_BASE_COSTS.size(), EXPECTED_PARTNER_COUNT])

	# --- Existing 13 partner names not renamed ---
	for i in range(EXPECTED_PARTNER_NAMES_13.size()):
		if i >= PartnerConfig.PARTNER_NAMES.size():
			break
		var actual: String = String(PartnerConfig.PARTNER_NAMES[i])
		var expected: String = EXPECTED_PARTNER_NAMES_13[i]
		if actual != expected:
			errors.append("Partner %d name changed: expected '%s', got '%s'" % [i + 1, expected, actual])

	# --- ClickerState initialization ---
	var state: ClickerState = ClickerState.new()
	if state == null:
		errors.append("ClickerState.new() returned null — crash during initialization")
	elif state.partner_counts.size() != EXPECTED_PARTNER_COUNT:
		errors.append("ClickerState.partner_counts.size() is %d after init, expected %d" % [state.partner_counts.size(), EXPECTED_PARTNER_COUNT])

	# --- Parse CSV ---
	var csv_keys: Dictionary = {}
	var parse_errors: Array[String] = []
	_parse_csv(CSV_PATH, csv_keys, parse_errors)
	errors.append_array(parse_errors)

	if parse_errors.is_empty():
		# --- Localization keys partner.01.name through partner.28.name ---
		for i in range(1, EXPECTED_PARTNER_COUNT + 1):
			var key: String = "partner.%02d.name" % i
			if not csv_keys.has(key):
				errors.append("Missing localization key: " + key)
			elif String(csv_keys[key].get("en", "")) == "":
				errors.append("Empty en value for localization key: " + key)

	# --- Asset path resolution ---
	for i in range(EXPECTED_PARTNER_COUNT):
		var icon_key: String = GameAssetCatalog.partner_icon_key(i)
		var icon_path: String = GameAssetCatalog.get_path(icon_key)
		var expected_icon: String = "res://assets/images/partners/partner_%02d.png" % (i + 1)
		if icon_path != expected_icon:
			errors.append("Partner %d icon path wrong: expected '%s', got '%s'" % [i + 1, expected_icon, icon_path])
		elif not ResourceLoader.exists(icon_path):
			if i < 13:
				errors.append("Partner %d icon file missing: %s" % [i + 1, icon_path])
			else:
				warnings.append("Partner %d icon file missing (placeholder): %s" % [i + 1, icon_path])

		for level in range(1, 6):
			var skill_key: String = GameAssetCatalog.partner_skill_key(i, level)
			var skill_path: String = GameAssetCatalog.get_path(skill_key)
			var expected_skill: String = "res://assets/images/partners/skills/partner_%02d_skill_%02d.png" % [i + 1, level]
			if skill_path != expected_skill:
				errors.append("Partner %d skill %d path wrong: expected '%s', got '%s'" % [i + 1, level, expected_skill, skill_path])
			elif not ResourceLoader.exists(skill_path):
				if i < 13:
					errors.append("Partner %d skill %d file missing: %s" % [i + 1, level, skill_path])
				else:
					warnings.append("Partner %d skill %d file missing (placeholder): %s" % [i + 1, level, skill_path])

	# --- Report ---
	print("")
	print("=== Partner Config Validation Report ===")
	print("")

	if errors.is_empty() and warnings.is_empty():
		print("All partner config checks passed.")
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
	print("Partner count:    %d" % PartnerConfig.get_partner_count())
	print("Errors:           %d" % errors.size())
	print("Warnings:         %d" % warnings.size())
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
	var ru_col: int = -1

	for i in range(headers.size()):
		match headers[i].strip_edges():
			"key": key_col = i
			"en":  en_col  = i
			"ru":  ru_col  = i

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
		var ru_val: String = cols[ru_col].strip_edges() if ru_col >= 0 and ru_col < cols.size() else ""
		out_keys[key] = {"en": en_val, "ru": ru_val}

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
