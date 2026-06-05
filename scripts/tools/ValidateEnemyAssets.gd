extends SceneTree

# Run with: godot --headless --script res://scripts/tools/ValidateEnemyAssets.gd

const STATES: Array[String] = ["healthy.png", "hit.png", "wounded.png", "defeated.png"]

const NON_BOSS_POOLS: Dictionary = {
	"zone_01": {"enemy": 15, "elite": 4},
	"zone_11": {"enemy": 15, "elite": 5},
	"zone_17": {"enemy": 9,  "elite": 3},
}

const BOSS_ZONE_COUNT: int = 21

func _init() -> void:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var slots_checked: int = 0
	var pngs_checked: int = 0

	# --- Non-boss pool slots ---
	for zone_folder: String in NON_BOSS_POOLS:
		var pool: Dictionary = NON_BOSS_POOLS[zone_folder]
		for i in range(1, pool["enemy"] + 1):
			var slot: String = "enemy_%02d" % i
			_check_slot("assets/images/enemies/%s/%s" % [zone_folder, slot], errors, warnings)
			slots_checked += 1
			pngs_checked += STATES.size()
		for i in range(1, pool["elite"] + 1):
			var slot: String = "elite_%02d" % i
			_check_slot("assets/images/enemies/%s/%s" % [zone_folder, slot], errors, warnings)
			slots_checked += 1
			pngs_checked += STATES.size()

	# --- Boss slots (one per gameplay zone 1–21) ---
	for zone_num in range(1, BOSS_ZONE_COUNT + 1):
		var zone_folder: String = "zone_%02d" % zone_num
		_check_slot("assets/images/enemies/%s/boss_01" % zone_folder, errors, warnings)
		slots_checked += 1
		pngs_checked += STATES.size()

	# --- Forbidden zone_21 folders ---
	var zone21_path: String = "res://assets/images/enemies/zone_21"
	var dir: DirAccess = DirAccess.open(zone21_path)
	if dir != null:
		dir.list_dir_begin()
		var entry: String = dir.get_next()
		while entry != "":
			if dir.current_is_dir():
				if entry.begins_with("enemy_") or entry.begins_with("elite_"):
					errors.append("FORBIDDEN folder in zone_21: " + entry)
			entry = dir.get_next()
		dir.list_dir_end()

	# --- Print report ---
	print("")
	print("=== Enemy Asset Validation Report ===")
	print("")

	if errors.is_empty() and warnings.is_empty():
		print("All required enemy PNG assets are present and no forbidden folders found.")
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
	print("Slots checked:      %d / 72" % slots_checked)
	print("PNG files checked:  %d / 288" % pngs_checked)
	print("Errors:             %d" % errors.size())
	print("Warnings:           %d" % warnings.size())
	print("")

	if errors.is_empty():
		print("RESULT: PASS")
		quit(0)
	else:
		print("RESULT: FAIL")
		quit(1)


func _check_slot(rel_path: String, errors: Array[String], warnings: Array[String]) -> void:
	for state: String in STATES:
		var png_path: String  = "res://%s/%s" % [rel_path, state]
		var import_path: String = png_path + ".import"
		if not FileAccess.file_exists(png_path):
			errors.append("Missing PNG: %s/%s" % [rel_path, state])
		elif not FileAccess.file_exists(import_path):
			warnings.append("Missing .import: %s/%s.import" % [rel_path, state])
