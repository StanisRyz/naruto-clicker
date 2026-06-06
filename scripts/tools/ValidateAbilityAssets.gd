extends SceneTree

# Run with: godot --headless --script res://scripts/tools/ValidateAbilityAssets.gd

const ABILITY_IDS: Array[String] = ["autoclick", "gold_bonus", "focus_burst", "rally"]
const HERO_SKILL_COUNT: int = 5

func _init() -> void:
	var errors: Array[String] = []
	var warnings: Array[String] = []

	# --- Obsolete paths must not exist ---
	var obsolete_folder: String = "res://assets/images/ability_skills"
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(obsolete_folder)):
		errors.append("OBSOLETE folder still exists: %s" % obsolete_folder)

	for ability_id in ABILITY_IDS:
		var flat_path: String = "res://assets/images/abilities/%s.png" % ability_id
		if ResourceLoader.exists(flat_path):
			errors.append("OBSOLETE flat file still exists: %s" % flat_path)

	# --- Required ability folders and icon paths ---
	for ability_id in ABILITY_IDS:
		var folder: String = "res://assets/images/abilities/%s" % ability_id
		if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(folder)):
			errors.append("MISSING required ability folder: %s" % folder)

		var icon_key: String = GameAssetCatalog.ability_icon_key(ability_id)
		var expected_path: String = "res://assets/images/abilities/%s/icon.png" % ability_id
		var actual_path: String = GameAssetCatalog.get_path(icon_key)
		if actual_path != expected_path:
			errors.append("WRONG path for %s: got '%s', expected '%s'" % [icon_key, actual_path, expected_path])
		if not ResourceLoader.exists(actual_path):
			warnings.append("MISSING icon (warning): %s" % actual_path)

	# --- Upgrade card paths ---
	var upgrade_ids: Array[String] = ["hero", "autoclick", "gold_bonus", "focus_burst", "rally"]
	for upgrade_id in upgrade_ids:
		var key: String = "upgrade.%s" % upgrade_id
		var path: String = GameAssetCatalog.get_path(key)
		var expected: String = "res://assets/images/upgrades/%s.png" % upgrade_id
		if path != expected:
			errors.append("WRONG upgrade path for %s: got '%s', expected '%s'" % [key, path, expected])

	# --- Hero skill paths ---
	for i in range(1, HERO_SKILL_COUNT + 1):
		var key: String = GameAssetCatalog.hero_skill_key(i)
		var path: String = GameAssetCatalog.get_path(key)
		var expected: String = "res://assets/images/hero_skills/skill_%02d.png" % i
		if path != expected:
			errors.append("WRONG hero skill path for level %d: got '%s', expected '%s'" % [i, path, expected])
		if not ResourceLoader.exists(path):
			warnings.append("MISSING hero skill (warning): %s" % path)

	# --- Report ---
	for w in warnings:
		print("  WARNING: %s" % w)
	for e in errors:
		print("  ERROR: %s" % e)

	if errors.is_empty():
		print("ValidateAbilityAssets: OK (%d warnings)" % warnings.size())
		quit(0)
	else:
		print("ValidateAbilityAssets: FAILED (%d errors, %d warnings)" % [errors.size(), warnings.size()])
		quit(1)
