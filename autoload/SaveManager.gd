extends Node

signal save_completed
signal save_failed(reason: String)
signal load_completed
signal load_failed(reason: String)
signal save_deleted

const SAVE_VERSION: int = 1
const SAVE_PATH: String = "user://save_v1.json"
const TEMP_SAVE_PATH: String = "user://save_v1.tmp"


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_data(data: Dictionary) -> bool:
	data["save_version"] = SAVE_VERSION
	var json_string: String = JSON.stringify(data)

	var temp_file: FileAccess = FileAccess.open(TEMP_SAVE_PATH, FileAccess.WRITE)
	if temp_file == null:
		var reason: String = "Cannot write temp save file"
		push_error("SaveManager: %s" % reason)
		save_failed.emit(reason)
		return false

	temp_file.store_string(json_string)
	temp_file.close()

	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		var reason: String = "Cannot open user:// directory"
		push_error("SaveManager: %s" % reason)
		save_failed.emit(reason)
		return false

	if FileAccess.file_exists(SAVE_PATH):
		dir.remove(SAVE_PATH)

	var rename_err: int = dir.rename(TEMP_SAVE_PATH, SAVE_PATH)
	if rename_err != OK:
		var reason: String = "Failed to finalize save (rename error %d)" % rename_err
		push_error("SaveManager: %s" % reason)
		save_failed.emit(reason)
		return false

	save_completed.emit()
	return true


func load_data() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		load_failed.emit("No save file")
		return {}

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("SaveManager: Cannot open save file for reading")
		load_failed.emit("Cannot open save file")
		return {}

	var json_string: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var parse_err: int = json.parse(json_string)
	if parse_err != OK:
		push_warning("SaveManager: JSON parse error — %s" % json.get_error_message())
		load_failed.emit("Corrupted save: JSON parse failed")
		return {}

	if not json.data is Dictionary:
		push_warning("SaveManager: Save root is not a Dictionary")
		load_failed.emit("Corrupted save: unexpected root type")
		return {}

	var data: Dictionary = json.data
	data = migrate_save_data(data)

	if not validate_save_data(data):
		push_warning("SaveManager: Save data failed validation")
		load_failed.emit("Save data invalid or unsupported version")
		return {}

	load_completed.emit()
	return data


func delete_save() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return true

	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		return false

	var err: int = dir.remove(SAVE_PATH)
	if err == OK:
		save_deleted.emit()
		return true

	return false


func validate_save_data(data: Dictionary) -> bool:
	if not data.has("save_version"):
		return false

	var version: int = int(data.get("save_version", 0))
	if version < 1 or version > SAVE_VERSION:
		push_warning("SaveManager: Unsupported save_version %d" % version)
		return false

	return true


func migrate_save_data(data: Dictionary) -> Dictionary:
	var version: int = int(data.get("save_version", 0))
	if version == SAVE_VERSION:
		return data
	# Future version migrations go here as elif blocks
	return data
