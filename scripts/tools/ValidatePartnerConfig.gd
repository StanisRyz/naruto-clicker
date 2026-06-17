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

	# Compact legacy arrays are intentionally shorter than PARTNER_COUNT:
	# higher-index values overflow int64 (4*23^i at i>=14; 35*25^i at i>=13).
	# Runtime uses get_partner_dps_bignum / get_partner_cost_bignum for all 28 partners.
	var dps_compact_size: int = BalanceConfig.PARTNER_DPS_VALUES.size()
	var cost_compact_size: int = BalanceConfig.PARTNER_BASE_COSTS.size()

	if dps_compact_size <= 0 or dps_compact_size > EXPECTED_PARTNER_COUNT:
		errors.append("BalanceConfig.PARTNER_DPS_VALUES.size() is %d, expected 1..%d" % [dps_compact_size, EXPECTED_PARTNER_COUNT])
	else:
		var expected_dps: int = BalanceConfig.PARTNER_DPS_BASE
		for i in range(dps_compact_size):
			if i > 0:
				expected_dps *= BalanceConfig.PARTNER_DPS_MULT
			if BalanceConfig.PARTNER_DPS_VALUES[i] != expected_dps:
				errors.append("PARTNER_DPS_VALUES[%d] is %d, expected %d (formula: %d*%d^%d)" % [
					i, BalanceConfig.PARTNER_DPS_VALUES[i], expected_dps,
					BalanceConfig.PARTNER_DPS_BASE, BalanceConfig.PARTNER_DPS_MULT, i])

	if cost_compact_size <= 0 or cost_compact_size > EXPECTED_PARTNER_COUNT:
		errors.append("BalanceConfig.PARTNER_BASE_COSTS.size() is %d, expected 1..%d" % [cost_compact_size, EXPECTED_PARTNER_COUNT])
	else:
		var expected_cost: int = BalanceConfig.PARTNER_COST_BASE
		for i in range(cost_compact_size):
			if i > 0:
				expected_cost *= BalanceConfig.PARTNER_COST_MULT
			if BalanceConfig.PARTNER_BASE_COSTS[i] != expected_cost:
				errors.append("PARTNER_BASE_COSTS[%d] is %d, expected %d (formula: %d*%d^%d)" % [
					i, BalanceConfig.PARTNER_BASE_COSTS[i], expected_cost,
					BalanceConfig.PARTNER_COST_BASE, BalanceConfig.PARTNER_COST_MULT, i])

	# --- Runtime BigNumber validation (all 28 partners via formula, no int64 overflow risk) ---
	var prev_dps: BigNumber = BigNumber.zero()
	var prev_cost: BigNumber = BigNumber.zero()
	for i in range(EXPECTED_PARTNER_COUNT):
		var dps_bn: BigNumber = BalanceConfig.get_partner_dps_bignum(i)
		var cost_bn: BigNumber = BalanceConfig.get_partner_cost_bignum(i)
		if not dps_bn.is_positive():
			errors.append("get_partner_dps_bignum(%d) is not positive" % i)
		elif i > 0 and dps_bn.compare_to(prev_dps) <= 0:
			errors.append("get_partner_dps_bignum(%d) did not increase from partner %d" % [i, i - 1])
		if not cost_bn.is_positive():
			errors.append("get_partner_cost_bignum(%d) is not positive" % i)
		elif i > 0 and cost_bn.compare_to(prev_cost) <= 0:
			errors.append("get_partner_cost_bignum(%d) did not increase from partner %d" % [i, i - 1])
		prev_dps = dps_bn
		prev_cost = cost_bn

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
	var skills_folder: String = "res://assets/images/partners/Skills"
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(skills_folder)):
		errors.append("Shared Skills folder missing: " + skills_folder)

	var partner_images_found: int = 0
	var partner_images_missing: int = 0

	for i in range(EXPECTED_PARTNER_COUNT):
		var folder: String = "res://assets/images/partners/partner_%02d" % (i + 1)
		if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(folder)):
			errors.append("Partner %d folder missing: %s" % [i + 1, folder])

		var icon_key: String = GameAssetCatalog.partner_icon_key(i)
		var icon_path: String = GameAssetCatalog.get_path(icon_key)
		var expected_icon: String = "res://assets/images/partners/partner_%02d/partner.png" % (i + 1)
		if icon_path != expected_icon:
			errors.append("Partner %d icon path wrong: expected '%s', got '%s'" % [i + 1, expected_icon, icon_path])
		elif ResourceLoader.exists(icon_path):
			partner_images_found += 1
		else:
			partner_images_missing += 1
			warnings.append("Partner %d icon file missing (art pending): %s" % [i + 1, icon_path])

		var old_flat: String = "res://assets/images/partners/partner_%02d.png" % (i + 1)
		if ResourceLoader.exists(old_flat):
			warnings.append("Old flat partner icon still exists; move to partner_%02d/partner.png: %s" % [i + 1, old_flat])

	for level in range(1, 6):
		var skill_key: String = GameAssetCatalog.partner_skill_key(0, level)
		var skill_path: String = GameAssetCatalog.get_path(skill_key)
		var expected_skill: String = "res://assets/images/partners/Skills/skill%d.png" % level
		if skill_path != expected_skill:
			errors.append("Shared skill %d path wrong: expected '%s', got '%s'" % [level, expected_skill, skill_path])
		elif not ResourceLoader.exists(skill_path):
			warnings.append("Shared skill icon missing (art pending): %s" % skill_path)

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
	print("Partner images found:   %d / %d" % [partner_images_found, EXPECTED_PARTNER_COUNT])
	print("Partner images missing: %d / %d" % [partner_images_missing, EXPECTED_PARTNER_COUNT])
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
