class_name BackendAuthStore

# Persists backend auth data (session token, email, email_verified) to
# user://backend_auth.json.  Never logs session_token.

const AUTH_FILE_PATH: String = "user://backend_auth.json"

var _cached: Dictionary = {}
var _loaded: bool = false


func load_auth() -> Dictionary:
	if _loaded:
		return _cached.duplicate()
	_cached = {}
	_loaded = true

	if not FileAccess.file_exists(AUTH_FILE_PATH):
		return {}

	var file: FileAccess = FileAccess.open(AUTH_FILE_PATH, FileAccess.READ)
	if file == null:
		push_warning("BackendAuthStore: cannot open auth file for reading")
		return {}

	var text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	if json.parse(text) != OK:
		push_warning("BackendAuthStore: auth file JSON parse error, returning empty defaults")
		return {}

	if not json.data is Dictionary:
		push_warning("BackendAuthStore: auth file root is not a Dictionary, returning empty defaults")
		return {}

	_cached = json.data
	return _cached.duplicate()


func save_auth(session_token: String, email: String = "", email_verified: bool = false) -> bool:
	_loaded = true
	_cached = {
		"session_token": session_token,
		"email": email,
		"email_verified": email_verified,
		"updated_at_unix": int(Time.get_unix_time_from_system()),
	}

	var file: FileAccess = FileAccess.open(AUTH_FILE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("BackendAuthStore: cannot open auth file for writing")
		return false

	file.store_string(JSON.stringify(_cached))
	file.close()
	return true


func clear_auth() -> bool:
	_loaded = true
	_cached = {}

	if not FileAccess.file_exists(AUTH_FILE_PATH):
		return true

	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		push_warning("BackendAuthStore: cannot open user:// to remove auth file")
		return false

	var err: int = dir.remove(AUTH_FILE_PATH)
	if err != OK:
		# Overwrite with empty object as a safe fallback.
		var file: FileAccess = FileAccess.open(AUTH_FILE_PATH, FileAccess.WRITE)
		if file != null:
			file.store_string("{}")
			file.close()
	return true


func has_session() -> bool:
	return get_session_token() != ""


func get_session_token() -> String:
	var auth: Dictionary = load_auth()
	return str(auth.get("session_token", ""))


func get_email() -> String:
	var auth: Dictionary = load_auth()
	return str(auth.get("email", ""))


func is_email_verified() -> bool:
	var auth: Dictionary = load_auth()
	return bool(auth.get("email_verified", false))
