extends SceneTree

const EXPECTED_KEY: String = "ui.card.sheet"
const EXPECTED_PATH: String = "res://assets/images/ui/cards/sheet_card.png"
const BUTTON_DEFAULT_KEY: String = "ui.card.button.default"
const BUTTON_DEFAULT_PATH: String = "res://assets/images/ui/cards/button/default.png"
const BUTTON_ACTIVE_KEY: String = "ui.card.button.active"
const BUTTON_ACTIVE_PATH: String = "res://assets/images/ui/cards/button/active.png"
const CARDS_FOLDER: String = "res://assets/images/ui/cards"
const BUTTON_FOLDER: String = "res://assets/images/ui/cards/button"

var _errors: int = 0
var _warnings: int = 0


func _init() -> void:
	_run()
	quit(_errors > 0)


func _run() -> void:
	print("=== ValidateCardAssets ===")
	_check_catalog_key()
	_check_button_catalog_keys()
	_check_folder()
	_check_button_folder()
	_check_texture()
	_check_button_textures()
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


func _check_button_catalog_keys() -> void:
	print("\n-- GameAssetCatalog keys: ui.card.button.default / ui.card.button.active --")
	for pair in [[BUTTON_DEFAULT_KEY, BUTTON_DEFAULT_PATH], [BUTTON_ACTIVE_KEY, BUTTON_ACTIVE_PATH]]:
		var key: String = pair[0]
		var expected_path: String = pair[1]
		if not GameAssetCatalog.ASSET_PATHS.has(key):
			_error("GameAssetCatalog missing key: %s" % key)
			continue
		var actual: String = GameAssetCatalog.ASSET_PATHS[key]
		if actual != expected_path:
			_error("key '%s' path mismatch: expected '%s', got '%s'" % [key, expected_path, actual])
		else:
			print("  OK      key '%s' -> %s" % [key, actual])


func _check_folder() -> void:
	print("\n-- Asset folder --")
	var abs_path: String = ProjectSettings.globalize_path(CARDS_FOLDER)
	if DirAccess.dir_exists_absolute(abs_path):
		print("  OK      %s/" % CARDS_FOLDER)
	else:
		_error("missing folder: %s/" % CARDS_FOLDER)


func _check_button_folder() -> void:
	print("\n-- Button asset folder --")
	var abs_path: String = ProjectSettings.globalize_path(BUTTON_FOLDER)
	if DirAccess.dir_exists_absolute(abs_path):
		print("  OK      %s/" % BUTTON_FOLDER)
	else:
		_error("missing folder: %s/" % BUTTON_FOLDER)


func _check_texture() -> void:
	print("\n-- sheet_card.png (optional during development) --")
	if ResourceLoader.exists(EXPECTED_PATH):
		print("  FOUND   %s" % EXPECTED_PATH)
	else:
		_warn("missing optional PNG (add before release): %s" % EXPECTED_PATH)


func _check_button_textures() -> void:
	print("\n-- button/default.png and button/active.png (optional during development, 210x72) --")
	for path in [BUTTON_DEFAULT_PATH, BUTTON_ACTIVE_PATH]:
		if ResourceLoader.exists(path):
			print("  FOUND   %s" % path)
		else:
			_warn("missing optional PNG (add before release): %s" % path)


func _error(msg: String) -> void:
	_errors += 1
	print("  ERROR: " + msg)


func _warn(msg: String) -> void:
	_warnings += 1
	print("  WARN:  " + msg)
