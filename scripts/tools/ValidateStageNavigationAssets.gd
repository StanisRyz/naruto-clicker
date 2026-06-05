extends SceneTree

const ZONE_COUNT: int = 21
const STAGE_NAV_ROOT: String = "res://assets/images/stage_navigation/"

var _errors: int = 0
var _warnings: int = 0


func _init() -> void:
	_run()
	quit(_errors > 0)


func _run() -> void:
	print("=== ValidateStageNavigationAssets ===")
	_check_cyclic_zones()
	_check_folders()
	_check_stage_files()
	_check_path_logic()
	print("--- Results: %d error(s), %d warning(s) ---" % [_errors, _warnings])


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


func _check_folders() -> void:
	print("\n-- Stage nav folders --")
	for i in range(1, ZONE_COUNT + 1):
		var folder: String = STAGE_NAV_ROOT + "zone_%02d" % i
		if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(folder)):
			print("  OK  %s" % folder)
		else:
			_error("missing folder: %s" % folder)


func _check_stage_files() -> void:
	print("\n-- Stage nav files (optional) --")
	for i in range(1, ZONE_COUNT + 1):
		var path: String = STAGE_NAV_ROOT + "zone_%02d/stage.png" % i
		if ResourceLoader.exists(path):
			print("  FOUND   %s" % path)
		else:
			_warn("missing optional: %s" % path)


func _check_path_logic() -> void:
	print("\n-- Stage nav path logic --")
	var path_1: String = StageNavigationAssetCatalog.get_stage_path_for_level(1)
	var path_106: String = StageNavigationAssetCatalog.get_stage_path_for_level(106)
	var path_6: String = StageNavigationAssetCatalog.get_stage_path_for_level(6)
	var path_111: String = StageNavigationAssetCatalog.get_stage_path_for_level(111)

	_check_paths_match("level 106 == level 1", path_106, path_1)
	_check_paths_match("level 111 == level 6", path_111, path_6)

	print("  level 1   path: %s" % path_1)
	print("  level 105 path: %s" % StageNavigationAssetCatalog.get_stage_path_for_level(105))
	print("  level 106 path: %s" % path_106)
	print("  level 111 path: %s" % path_111)


func _check_paths_match(label: String, a: String, b: String) -> void:
	if a == b:
		print("  OK  %s -> %s" % [label, a])
	else:
		_error("%s: expected '%s' == '%s'" % [label, a, b])


func _error(msg: String) -> void:
	_errors += 1
	print("  ERROR: " + msg)


func _warn(msg: String) -> void:
	_warnings += 1
	print("  WARN:  " + msg)
