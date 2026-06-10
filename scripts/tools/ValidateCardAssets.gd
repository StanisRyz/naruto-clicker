extends SceneTree

const EXPECTED_KEY: String = "ui.card.sheet"
const EXPECTED_PATH: String = "res://assets/images/ui/cards/sheet_card.png"
const BUTTON_KEY: String = "ui.card.button"
const BUTTON_PATH: String = "res://assets/images/ui/cards/button.png"
const CARDS_FOLDER: String = "res://assets/images/ui/cards"

var _errors: int = 0
var _warnings: int = 0


func _init() -> void:
	_run()
	quit(_errors > 0)


func _run() -> void:
	print("=== ValidateCardAssets ===")
	_check_catalog_key()
	_check_button_catalog_key()
	_check_folder()
	_check_texture()
	_check_button_texture()
	print("--- Results: %d error(s), %d warning(s) ---" % [_errors, _warnings])


func _check_catalog_key() -> void:
	print("\n-- GameAssetCatalog key: ui.card.sheet --")
	if not GameAssetCatalog.ASSET_PATHS.has(EXPECTED_KEY):
		_error("GameAssetCatalog missing key: %s" % EXPECTED_KEY)
		return

	var actual: String = GameAssetCatalog.ASSET_PATHS[EXPECTED_KEY]
	if actual != EXPECTED_PATH:
		_error("key '%s' path mismatch: expected '%s', got '%s'" % [EXPECTED_KEY, EXPECTED_PATH, actual])
	else:
		print("  OK      key '%s' -> %s" % [EXPECTED_KEY, actual])


func _check_button_catalog_key() -> void:
	print("\n-- GameAssetCatalog key: ui.card.button --")
	if not GameAssetCatalog.ASSET_PATHS.has(BUTTON_KEY):
		_error("GameAssetCatalog missing key: %s" % BUTTON_KEY)
		return

	var actual: String = GameAssetCatalog.ASSET_PATHS[BUTTON_KEY]
	if actual != BUTTON_PATH:
		_error("key '%s' path mismatch: expected '%s', got '%s'" % [BUTTON_KEY, BUTTON_PATH, actual])
	else:
		print("  OK      key '%s' -> %s" % [BUTTON_KEY, actual])


func _check_folder() -> void:
	print("\n-- Asset folder --")
	var abs_path: String = ProjectSettings.globalize_path(CARDS_FOLDER)
	if DirAccess.dir_exists_absolute(abs_path):
		print("  OK      %s/" % CARDS_FOLDER)
	else:
		_error("missing folder: %s/" % CARDS_FOLDER)


func _check_texture() -> void:
	print("\n-- sheet_card.png (optional during development) --")
	if ResourceLoader.exists(EXPECTED_PATH):
		print("  FOUND   %s" % EXPECTED_PATH)
	else:
		_warn("missing optional PNG (add before release): %s" % EXPECTED_PATH)


func _check_button_texture() -> void:
	print("\n-- button.png (optional during development, recommended 210x72) --")
	if ResourceLoader.exists(BUTTON_PATH):
		print("  FOUND   %s" % BUTTON_PATH)
	else:
		_warn("missing optional PNG (add before release): %s" % BUTTON_PATH)


func _error(msg: String) -> void:
	_errors += 1
	print("  ERROR: " + msg)


func _warn(msg: String) -> void:
	_warnings += 1
	print("  WARN:  " + msg)
