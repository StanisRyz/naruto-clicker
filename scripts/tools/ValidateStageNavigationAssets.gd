extends SceneTree

const STAGE_NAV_ROOT: String = "res://assets/images/stage_navigation/"

var _errors: int = 0
var _warnings: int = 0


func _init() -> void:
	_run()
	quit(_errors > 0)


func _run() -> void:
	print("=== ValidateStageNavigationAssets ===")
	_check_cyclic_zones()
	var expected_zone_numbers: Array = _get_expected_zone_numbers()
	_check_folders(expected_zone_numbers)
	_check_stage_files(expected_zone_numbers)
	_check_common_overlays()
	_check_path_logic()
	_check_auto_transition()
	print("--- Results: %d error(s), %d warning(s) ---" % [_errors, _warnings])


func _get_expected_zone_numbers() -> Array:
	var seen: Dictionary = {}
	for zone in ZoneConfig.ZONE_DATA:
		var n: int = int(zone.get("background_asset_zone", 0))
		if n > 0:
			seen[n] = true
	var result: Array = seen.keys()
	result.sort()
	return result


func _check_cyclic_zones() -> void:
	print("\n-- Zone cycling --")
	var cases: Array = [
		[1, 1], [5, 1], [6, 2], [105, 21],
		[106, 1], [110, 1], [111, 2], [210, 21], [211, 1],
	]
	for c in cases:
		var level: int = c[0]
		var expected: int = c[1]
		var got: int = ZoneConfig.get_zone_number_for_level(level)
		if got == expected:
			print("  OK  level %d -> zone %d" % [level, got])
		else:
			_error("level %d expected zone %d but got zone %d" % [level, expected, got])


func _check_folders(expected_zone_numbers: Array) -> void:
	print("\n-- Stage nav folders --")

	var expected_names: Dictionary = {}
	for n in expected_zone_numbers:
		expected_names["zone_%02d" % n] = true

	for n in expected_zone_numbers:
		var folder: String = STAGE_NAV_ROOT + "zone_%02d" % n
		if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(folder)):
			print("  OK      %s" % folder)
		else:
			_error("missing expected folder: %s" % folder)

	var nav_dir := DirAccess.open(ProjectSettings.globalize_path(STAGE_NAV_ROOT))
	if nav_dir == null:
		_error("stage_navigation root not found: %s" % STAGE_NAV_ROOT)
		return
	nav_dir.list_dir_begin()
	var entry: String = nav_dir.get_next()
	while entry != "":
		if nav_dir.current_is_dir() and entry.begins_with("zone_"):
			if not expected_names.has(entry):
				_error("unexpected folder (should not exist): %s%s" % [STAGE_NAV_ROOT, entry])
		entry = nav_dir.get_next()
	nav_dir.list_dir_end()


func _check_stage_files(expected_zone_numbers: Array) -> void:
	print("\n-- Stage nav files (optional) --")
	for n in expected_zone_numbers:
		var path: String = STAGE_NAV_ROOT + "zone_%02d/stage.png" % n
		if ResourceLoader.exists(path):
			print("  FOUND   %s" % path)
		else:
			_warn("missing optional: %s" % path)


func _check_common_overlays() -> void:
	print("\n-- Common overlays (optional) --")
	var common_folder: String = STAGE_NAV_ROOT + "common"
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(common_folder)):
		print("  OK      %s/" % common_folder)
	else:
		_error("missing common folder: %s/" % common_folder)
		return

	var locked_path: String = STAGE_NAV_ROOT + "common/locked.png"
	if ResourceLoader.exists(locked_path):
		print("  FOUND   %s" % locked_path)
	else:
		_warn("missing optional: %s" % locked_path)

	var current_path: String = STAGE_NAV_ROOT + "common/current.png"
	if ResourceLoader.exists(current_path):
		print("  FOUND   %s" % current_path)
	else:
		_warn("missing optional: %s" % current_path)


func _check_path_logic() -> void:
	print("\n-- Stage nav path logic --")
	var cases: Array = [
		[1,   "zone_01"], [6,   "zone_02"], [26,  "zone_05"],
		[31,  "zone_01"], [101, "zone_10"], [105, "zone_10"],
		[106, "zone_01"], [111, "zone_02"], [210, "zone_10"],
		[211, "zone_01"],
	]
	for c in cases:
		var level: int = c[0]
		var expected_folder: String = c[1]
		var path: String = StageNavigationAssetCatalog.get_stage_path_for_level(level)
		var expected_path: String = STAGE_NAV_ROOT + expected_folder + "/stage.png"
		if path == expected_path:
			print("  OK  level %d -> %s" % [level, path])
		else:
			_error("level %d: expected '%s', got '%s'" % [level, expected_path, path])


func _check_auto_transition() -> void:
	print("\n-- Auto-transition button assets --")

	var folder: String = "res://assets/images/ui/stage_navigation/auto_transition"
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(folder)):
		print("  OK      %s/" % folder)
	else:
		_error("missing folder: %s/" % folder)

	var expected: Dictionary = {
		"stage.auto_on":  "res://assets/images/ui/stage_navigation/auto_transition/enabled.png",
		"stage.auto_off": "res://assets/images/ui/stage_navigation/auto_transition/disabled.png",
	}
	for key in expected:
		if not GameAssetCatalog.ASSET_PATHS.has(key):
			_error("GameAssetCatalog missing key: %s" % key)
			continue
		var actual: String = GameAssetCatalog.ASSET_PATHS[key]
		var want: String = expected[key]
		if actual != want:
			_error("key '%s' path mismatch: expected '%s', got '%s'" % [key, want, actual])
		else:
			print("  OK      key '%s' -> %s" % [key, actual])
		if ResourceLoader.exists(actual):
			print("  FOUND   %s" % actual)
		else:
			_warn("missing optional PNG: %s" % actual)


func _error(msg: String) -> void:
	_errors += 1
	print("  ERROR: " + msg)


func _warn(msg: String) -> void:
	_warnings += 1
	print("  WARN:  " + msg)
