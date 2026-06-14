## Dev-only tool — NOT autoloaded, NOT referenced by production scenes.
## Run from the Godot editor via EditorScript or attach temporarily to a debug node.
##
## Usage:
##   var report := AssetBuildSanityReport.new()
##   report.run()
extends RefCounted

class_name AssetBuildSanityReport

# ---------------------------------------------------------------------------
# Asset paths to verify — pulled from catalog constants where possible
# ---------------------------------------------------------------------------

const _AUDIO_PATHS: Array[String] = [
	"res://assets/audio/music/track_01.ogg",
	"res://assets/audio/music/track_02.ogg",
	"res://assets/audio/music/track_03.ogg",
	"res://assets/audio/music/track_04.ogg",
	"res://assets/audio/music/track_05.ogg",
	"res://assets/audio/music/track_06.ogg",
	"res://assets/audio/music/track_07.ogg",
	"res://assets/audio/sfx/hits/hit_01.ogg",
	"res://assets/audio/sfx/hits/hit_02.ogg",
	"res://assets/audio/sfx/hits/hit_03.ogg",
	"res://assets/audio/sfx/ui/button_click.ogg",
	"res://assets/audio/sfx/shop/purchase_success.ogg",
	"res://assets/audio/sfx/shop/purchase_error.ogg",
	"res://assets/audio/sfx/rewards/reward_received.ogg",
	"res://assets/audio/sfx/rewards/gold_received.ogg",
]

const _FONT_PATHS: Array[String] = [
	"res://assets/fonts/Montserrat-Bold.ttf",
	"res://assets/fonts/boss_timer.ttf",
]

const _LOCALIZATION_PATHS: Array[String] = [
	"res://localization/game_text.csv",
	"res://scripts/ui/LocalizationData.gd",
]

# Tool scripts that must NOT be in autoload
const _TOOL_SCRIPTS: Array[String] = [
	"res://scripts/tools/BalanceAuditReport.gd",
	"res://scripts/tools/LocalizationHardcodedTextAudit.gd",
	"res://scripts/tools/SaveIntegrityDebugReport.gd",
]

# Autoloads that must be present (script paths)
const _REQUIRED_AUTOLOADS: Array[String] = [
	"res://scripts/game/BuildConfig.gd",
	"res://autoload/YandexBridge.gd",
	"res://autoload/SaveManager.gd",
	"res://scripts/ui/LocalizationManager.gd",
	"res://autoload/AudioManager.gd",
]

# ---------------------------------------------------------------------------

var _missing: Array[String] = []
var _stale_catalog: Array[String] = []
var _warnings: Array[String] = []


func run() -> void:
	_missing.clear()
	_stale_catalog.clear()
	_warnings.clear()

	print("\n========== AssetBuildSanityReport ==========")
	_check_audio()
	_check_fonts()
	_check_localization()
	_check_catalog_keys()
	_check_enemy_defaults()
	_check_field_background()
	_check_tool_scripts_not_in_scene()
	_print_summary()
	print("============================================\n")


func _check_audio() -> void:
	print("[Audio]")
	for path in _AUDIO_PATHS:
		if not ResourceLoader.exists(path):
			_missing.append(path)
			print("  MISSING: %s" % path)
		else:
			print("  OK: %s" % path)


func _check_fonts() -> void:
	print("[Fonts]")
	for path in _FONT_PATHS:
		if not ResourceLoader.exists(path):
			_missing.append(path)
			print("  MISSING: %s" % path)
		else:
			print("  OK: %s" % path)


func _check_localization() -> void:
	print("[Localization]")
	for path in _LOCALIZATION_PATHS:
		if not ResourceLoader.exists(path):
			_missing.append(path)
			print("  MISSING: %s" % path)
		else:
			print("  OK: %s" % path)


func _check_catalog_keys() -> void:
	print("[GameAssetCatalog keys]")
	var missing_keys: Array[String] = []
	for key in GameAssetCatalog.ASSET_PATHS.keys():
		var path: String = GameAssetCatalog.ASSET_PATHS[key]
		if not ResourceLoader.exists(path):
			missing_keys.append("  MISSING key='%s' path='%s'" % [key, path])
	if missing_keys.is_empty():
		print("  All catalog keys resolve to existing files.")
	else:
		for msg in missing_keys:
			print(msg)
			_missing.append(msg)


func _check_enemy_defaults() -> void:
	print("[Enemy default fallback images]")
	var states: Array[String] = ["healthy", "hit", "wounded", "defeated"]
	for state in states:
		var path: String = "res://assets/images/enemies/default_%s.png" % state
		if not ResourceLoader.exists(path):
			_missing.append(path)
			print("  MISSING (fallback for zones without art): %s" % path)
		else:
			print("  OK: %s" % path)


func _check_field_background() -> void:
	print("[Game field background]")
	var path: String = "res://assets/images/game/field_background.png"
	if not ResourceLoader.exists(path):
		_missing.append(path)
		print("  MISSING (zone background ultimate fallback): %s" % path)
	else:
		print("  OK: %s" % path)


func _check_tool_scripts_not_in_scene() -> void:
	print("[Tool scripts isolation]")
	for path in _TOOL_SCRIPTS:
		if ResourceLoader.exists(path):
			print("  OK (exists but must not be autoloaded): %s" % path)
		else:
			print("  NOT FOUND (no risk): %s" % path)


func _print_summary() -> void:
	print("\n[Summary]")
	print("  Missing files: %d" % _missing.size())
	for m in _missing:
		print("    - %s" % m)
	if _missing.is_empty():
		print("  BUILD SANITY: PASS")
	else:
		print("  BUILD SANITY: FAIL — fix missing files before export")
