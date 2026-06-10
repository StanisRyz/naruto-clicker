extends SceneTree

const STANDARD_KEY: String = "ui.sheet.standard"
const STANDARD_PATH: String = "res://assets/images/ui/sheets/standard_sheet.png"
const CLOSE_KEY: String = "ui.sheet.close_button"
const CLOSE_PATH: String = "res://assets/images/ui/sheets/close_button.png"
const SHEETS_FOLDER: String = "res://assets/images/ui/sheets"
const EXPECTED_WIDTH: int = 720
const EXPECTED_HEIGHT: int = 645
const CLOSE_EXPECTED_WIDTH: int = 72
const CLOSE_EXPECTED_HEIGHT: int = 56

var _errors: int = 0
var _warnings: int = 0


func _init() -> void:
	_run()
	quit(_errors > 0)


func _run() -> void:
	print("=== ValidateSheetAssets ===")
	_check_catalog_key()
	_check_close_catalog_key()
	_check_folder()
	_check_texture()
	_check_close_texture()
	print("--- Results: %d error(s), %d warning(s) ---" % [_errors, _warnings])


func _check_catalog_key() -> void:
	print("\n-- GameAssetCatalog key: ui.sheet.standard --")
	if not GameAssetCatalog.ASSET_PATHS.has(STANDARD_KEY):
		_error("GameAssetCatalog missing key: %s" % STANDARD_KEY)
		return
	var actual: String = GameAssetCatalog.ASSET_PATHS[STANDARD_KEY]
	if actual != STANDARD_PATH:
		_error("key '%s' path mismatch: expected '%s', got '%s'" % [STANDARD_KEY, STANDARD_PATH, actual])
	else:
		print("  OK      key '%s' -> %s" % [STANDARD_KEY, actual])


func _check_close_catalog_key() -> void:
	print("\n-- GameAssetCatalog key: ui.sheet.close_button --")
	if not GameAssetCatalog.ASSET_PATHS.has(CLOSE_KEY):
		_error("GameAssetCatalog missing key: %s" % CLOSE_KEY)
		return
	var actual: String = GameAssetCatalog.ASSET_PATHS[CLOSE_KEY]
	if actual != CLOSE_PATH:
		_error("key '%s' path mismatch: expected '%s', got '%s'" % [CLOSE_KEY, CLOSE_PATH, actual])
	else:
		print("  OK      key '%s' -> %s" % [CLOSE_KEY, actual])


func _check_folder() -> void:
	print("\n-- Asset folder --")
	var abs_path: String = ProjectSettings.globalize_path(SHEETS_FOLDER)
	if DirAccess.dir_exists_absolute(abs_path):
		print("  OK      %s/" % SHEETS_FOLDER)
	else:
		_error("missing folder: %s/" % SHEETS_FOLDER)


func _check_texture() -> void:
	print("\n-- standard_sheet.png (optional during development, recommended 720x645) --")
	if not ResourceLoader.exists(STANDARD_PATH):
		_warn("missing optional PNG (add before release): %s" % STANDARD_PATH)
		return
	print("  FOUND   %s" % STANDARD_PATH)
	var tex: Texture2D = ResourceLoader.load(STANDARD_PATH) as Texture2D
	if tex == null:
		_warn("file exists but could not be loaded as Texture2D: %s" % STANDARD_PATH)
		return
	if tex.get_width() != EXPECTED_WIDTH or tex.get_height() != EXPECTED_HEIGHT:
		_warn("size is %dx%d, recommended %dx%d: %s" % [
			tex.get_width(), tex.get_height(), EXPECTED_WIDTH, EXPECTED_HEIGHT, STANDARD_PATH])
	else:
		print("  OK      size %dx%d" % [tex.get_width(), tex.get_height()])


func _check_close_texture() -> void:
	print("\n-- close_button.png (optional during development, recommended 72x56) --")
	if not ResourceLoader.exists(CLOSE_PATH):
		_warn("missing optional PNG (add before release): %s" % CLOSE_PATH)
		return
	print("  FOUND   %s" % CLOSE_PATH)
	var tex: Texture2D = ResourceLoader.load(CLOSE_PATH) as Texture2D
	if tex == null:
		_warn("file exists but could not be loaded as Texture2D: %s" % CLOSE_PATH)
		return
	if tex.get_width() != CLOSE_EXPECTED_WIDTH or tex.get_height() != CLOSE_EXPECTED_HEIGHT:
		_warn("size is %dx%d, recommended %dx%d: %s" % [
			tex.get_width(), tex.get_height(), CLOSE_EXPECTED_WIDTH, CLOSE_EXPECTED_HEIGHT, CLOSE_PATH])
	else:
		print("  OK      size %dx%d" % [tex.get_width(), tex.get_height()])


func _error(msg: String) -> void:
	_errors += 1
	print("  ERROR: " + msg)


func _warn(msg: String) -> void:
	_warnings += 1
	print("  WARN:  " + msg)
