extends SceneTree

# Run with: godot --headless --script res://scripts/tools/ValidateBottomBarAssets.gd

func _init() -> void:
	var errors: Array[String] = []
	var warnings: Array[String] = []

	var required_folders: Array[String] = [
		"res://assets/images/ui/bottom_bar",
		"res://assets/images/ui/bottom_bar/tabs/upgrades",
		"res://assets/images/ui/bottom_bar/tabs/partners",
		"res://assets/images/ui/bottom_bar/tabs/settlement",
		"res://assets/images/ui/bottom_bar/tabs/prestige",
		"res://assets/images/ui/bottom_bar/tabs/shop",
	]

	for folder in required_folders:
		if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(folder)):
			errors.append("MISSING required folder: %s" % folder)

	var required_keys: Dictionary = {
		"ui.bottom_bar.background": "res://assets/images/ui/bottom_bar/background.png",
		"ui.bottom_tab.upgrades.default": "res://assets/images/ui/bottom_bar/tabs/upgrades/default.png",
		"ui.bottom_tab.upgrades.active": "res://assets/images/ui/bottom_bar/tabs/upgrades/active.png",
		"ui.bottom_tab.partners.default": "res://assets/images/ui/bottom_bar/tabs/partners/default.png",
		"ui.bottom_tab.partners.active": "res://assets/images/ui/bottom_bar/tabs/partners/active.png",
		"ui.bottom_tab.settlement.default": "res://assets/images/ui/bottom_bar/tabs/settlement/default.png",
		"ui.bottom_tab.settlement.active": "res://assets/images/ui/bottom_bar/tabs/settlement/active.png",
		"ui.bottom_tab.prestige.default": "res://assets/images/ui/bottom_bar/tabs/prestige/default.png",
		"ui.bottom_tab.prestige.active": "res://assets/images/ui/bottom_bar/tabs/prestige/active.png",
		"ui.bottom_tab.shop.default": "res://assets/images/ui/bottom_bar/tabs/shop/default.png",
		"ui.bottom_tab.shop.active": "res://assets/images/ui/bottom_bar/tabs/shop/active.png",
	}

	for key in required_keys:
		var expected_path: String = required_keys[key]
		var actual_path: String = GameAssetCatalog.get_path(key)
		if actual_path != expected_path:
			errors.append("WRONG path for '%s': got '%s', expected '%s'" % [key, actual_path, expected_path])
		elif not ResourceLoader.exists(actual_path):
			warnings.append("MISSING file (warning only): %s" % actual_path)

	for w in warnings:
		print("  WARNING: %s" % w)
	for e in errors:
		print("  ERROR: %s" % e)

	if errors.is_empty():
		print("ValidateBottomBarAssets: OK (%d warnings)" % warnings.size())
		quit(0)
	else:
		print("ValidateBottomBarAssets: FAILED (%d errors, %d warnings)" % [errors.size(), warnings.size()])
		quit(1)
