extends Node

signal save_completed
signal save_failed(reason: String)
signal load_completed
signal load_failed(reason: String)
signal save_deleted
signal _cloud_load_done(data: Dictionary)

const SAVE_VERSION: int = 1
const SAVE_PATH: String = "user://save_v1.json"
const TEMP_SAVE_PATH: String = "user://save_v1.tmp"

const CLOUD_SAVE_MIN_INTERVAL_SEC: float = 15.0
const CLOUD_SAVE_MAX_BYTES: int = 200 * 1024

var _pending_cloud_save_data: Dictionary = {}
var _cloud_save_timer_running: bool = false
var _last_cloud_save_unix_time: int = 0
var _cloud_load_in_progress: bool = false


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
	queue_cloud_save(data)
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


# ── Cloud save coordination ───────────────────────────────────────────────────

func load_cloud_data_async() -> Dictionary:
	if not YandexBridge.is_cloud_save_available():
		return {}

	if _cloud_load_in_progress:
		push_warning("SaveManager: cloud load already in progress, skipping duplicate call")
		return {}

	_cloud_load_in_progress = true

	var on_loaded: Callable
	var on_error: Callable

	on_loaded = func(data: Dictionary) -> void:
		_cloud_load_in_progress = false
		if YandexBridge.cloud_save_loaded.is_connected(on_loaded):
			YandexBridge.cloud_save_loaded.disconnect(on_loaded)
		if YandexBridge.cloud_save_load_error.is_connected(on_error):
			YandexBridge.cloud_save_load_error.disconnect(on_error)
		var parsed: Dictionary = data
		if not parsed.is_empty():
			parsed = migrate_save_data(parsed)
			if not validate_save_data(parsed):
				push_warning("SaveManager: cloud save failed validation, treating as empty")
				parsed = {}
		_cloud_load_done.emit(parsed)

	on_error = func(msg: String) -> void:
		_cloud_load_in_progress = false
		push_warning("SaveManager: cloud load error — %s" % msg)
		if YandexBridge.cloud_save_loaded.is_connected(on_loaded):
			YandexBridge.cloud_save_loaded.disconnect(on_loaded)
		if YandexBridge.cloud_save_load_error.is_connected(on_error):
			YandexBridge.cloud_save_load_error.disconnect(on_error)
		_cloud_load_done.emit({})

	YandexBridge.cloud_save_loaded.connect(on_loaded)
	YandexBridge.cloud_save_load_error.connect(on_error)

	YandexBridge.load_cloud_save()

	var result: Dictionary = await _cloud_load_done
	return result


func queue_cloud_save(data: Dictionary, flush: bool = false) -> void:
	if not YandexBridge.is_cloud_save_available():
		return

	_pending_cloud_save_data = data

	if flush:
		flush_cloud_save_now()
		return

	if _cloud_save_timer_running:
		return

	var now: int = int(Time.get_unix_time_from_system())
	var elapsed: float = float(now - _last_cloud_save_unix_time)

	if elapsed >= CLOUD_SAVE_MIN_INTERVAL_SEC:
		var send_data: Dictionary = _pending_cloud_save_data
		_pending_cloud_save_data = {}
		_send_cloud_save(send_data, false)
	else:
		_cloud_save_timer_running = true
		var delay: float = CLOUD_SAVE_MIN_INTERVAL_SEC - elapsed
		get_tree().create_timer(delay).timeout.connect(_on_cloud_save_timer_expired, CONNECT_ONE_SHOT)


func flush_cloud_save_now() -> void:
	if _pending_cloud_save_data.is_empty():
		return
	_cloud_save_timer_running = false
	var data: Dictionary = _pending_cloud_save_data
	_pending_cloud_save_data = {}
	_send_cloud_save(data, true)


func delete_cloud_save() -> void:
	YandexBridge.delete_cloud_save()


func _on_cloud_save_timer_expired() -> void:
	_cloud_save_timer_running = false
	if _pending_cloud_save_data.is_empty():
		return
	var data: Dictionary = _pending_cloud_save_data
	_pending_cloud_save_data = {}
	_send_cloud_save(data, false)


func _send_cloud_save(data: Dictionary, flush: bool) -> void:
	var json_string: String = JSON.stringify(data)
	var byte_size: int = json_string.to_utf8_buffer().size()
	if byte_size > CLOUD_SAVE_MAX_BYTES:
		push_warning("SaveManager: cloud save too large (%d bytes, limit %d), skipping" % [byte_size, CLOUD_SAVE_MAX_BYTES])
		return
	_last_cloud_save_unix_time = int(Time.get_unix_time_from_system())
	YandexBridge.save_cloud_save(data, flush)
