extends SceneTree

# Run with: godot --headless --script res://scripts/tools/ValidateImageSlotFallbacks.gd
#
# Checks for accidental show_fallback_behind_texture = true in scenes and scripts.
# Intentional true usage must be added to ALLOWLIST below.

const ALLOWLIST: Array[String] = []

const SCENE_DIRS: Array[String] = ["res://scenes"]
const SCRIPT_DIRS: Array[String] = ["res://scripts", "res://scenes"]

const IMAGESLOT_SCRIPT_PATH: String = "res://scripts/ui/ImageSlot.gd"

func _init() -> void:
	var errors: Array[String] = []

	_scan_scenes(errors)
	_scan_scripts(errors)

	if errors.is_empty():
		print("[ValidateImageSlotFallbacks] OK — no accidental show_fallback_behind_texture = true found.")
		quit(0)
	else:
		print("[ValidateImageSlotFallbacks] FAILED — %d issue(s):" % errors.size())
		for e in errors:
			print("  ERROR: %s" % e)
		quit(1)


func _scan_scenes(errors: Array[String]) -> void:
	for dir_path in SCENE_DIRS:
		var abs_dir: String = ProjectSettings.globalize_path(dir_path)
		_walk_files(abs_dir, ".tscn", errors, true)


func _scan_scripts(errors: Array[String]) -> void:
	for dir_path in SCRIPT_DIRS:
		var abs_dir: String = ProjectSettings.globalize_path(dir_path)
		_walk_files(abs_dir, ".gd", errors, false)


func _walk_files(abs_dir: String, extension: String, errors: Array[String], is_scene: bool) -> void:
	var dir: DirAccess = DirAccess.open(abs_dir)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		var full_path: String = abs_dir.path_join(entry)
		if dir.current_is_dir():
			if entry != "." and entry != "..":
				_walk_files(full_path, extension, errors, is_scene)
		elif entry.ends_with(extension):
			_check_file(full_path, errors, is_scene)
		entry = dir.get_next()
	dir.list_dir_end()


func _check_file(abs_path: String, errors: Array[String], is_scene: bool) -> void:
	var file: FileAccess = FileAccess.open(abs_path, FileAccess.READ)
	if file == null:
		return

	var res_path: String = ProjectSettings.localize_path(abs_path)

	# Skip the ImageSlot definition itself
	if res_path == IMAGESLOT_SCRIPT_PATH:
		file.close()
		return

	var line_number: int = 0
	while not file.eof_reached():
		var line: String = file.get_line()
		line_number += 1
		if "show_fallback_behind_texture = true" in line:
			var location: String = "%s:%d" % [res_path, line_number]
			if _is_in_allowlist(location):
				print("[ValidateImageSlotFallbacks] ALLOWED: %s" % location)
			else:
				errors.append("show_fallback_behind_texture = true at %s" % location)
	file.close()


func _is_in_allowlist(location: String) -> bool:
	for allowed in ALLOWLIST:
		if location.begins_with(allowed):
			return true
	return false
