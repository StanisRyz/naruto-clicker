extends SceneTree

const ASSET_KEY: String = "ui.top_interface"
const ASSET_PATH: String = "res://assets/images/ui/top_interface.png"
const EXPECTED_WIDTH: int = 720
const EXPECTED_HEIGHT: int = 320

var _errors: int = 0
var _warnings: int = 0


func _init() -> void:
	_run()
	quit(_errors > 0)


func _run() -> void:
	print("=== ValidateTopInterfaceAssets ===")
	_check_catalog_key()
	_check_texture()
	print("--- Results: %d error(s), %d warning(s) ---" % [_errors, _warnings])


func _check_catalog_key() -> void:
	print("\n-- GameAssetCatalog key: ui.top_interface --")
	if not GameAssetCatalog.ASSET_PATHS.has(ASSET_KEY):
		_error("GameAssetCatalog missing key: %s" % ASSET_KEY)
		return
	var actual: String = GameAssetCatalog.ASSET_PATHS[ASSET_KEY]
	if actual != ASSET_PATH:
		_error("key '%s' path mismatch: expected '%s', got '%s'" % [ASSET_KEY, ASSET_PATH, actual])
	else:
		print("  OK      key '%s' -> %s" % [ASSET_KEY, actual])


func _check_texture() -> void:
	print("\n-- top_interface.png (optional, transparent fallback when missing; recommended 720x320) --")
	if not ResourceLoader.exists(ASSET_PATH):
		_warn("missing optional PNG (transparent fallback active): %s" % ASSET_PATH)
		return
	print("  FOUND   %s" % ASSET_PATH)
	var tex: Texture2D = ResourceLoader.load(ASSET_PATH) as Texture2D
	if tex == null:
		_warn("file exists but could not be loaded as Texture2D: %s" % ASSET_PATH)
		return
	if tex.get_width() != EXPECTED_WIDTH or tex.get_height() != EXPECTED_HEIGHT:
		_warn("size is %dx%d, recommended %dx%d: %s" % [
			tex.get_width(), tex.get_height(), EXPECTED_WIDTH, EXPECTED_HEIGHT, ASSET_PATH])
	else:
		print("  OK      size %dx%d" % [tex.get_width(), tex.get_height()])


func _error(msg: String) -> void:
	_errors += 1
	print("  ERROR: " + msg)


func _warn(msg: String) -> void:
	_warnings += 1
	print("  WARN:  " + msg)
