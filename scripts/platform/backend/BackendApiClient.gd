class_name BackendApiClient
extends Node

# HTTP client for the Yandex Cloud auth/save backend.
#
# Owns one HTTPRequest child; supports one active request at a time.
# Never logs passwords, session tokens, reset/verification codes, or save JSON.
#
# Usage:
#   var client := BackendApiClient.new()
#   add_child(client)
#   client.set_auth_store(BackendAuthStore.new())
#   client.configure("https://your-backend-url")
#   client.operation_succeeded.connect(_on_ok)
#   client.operation_failed.connect(_on_fail)
#   client.login("user@example.com", "password")

# Project-settings key where the backend base URL may be stored.
const DEFAULT_PROJECT_SETTING_BACKEND_URL := "application/cloud_save/backend_url"

signal operation_succeeded(operation: String, response: Dictionary)
signal operation_failed(operation: String, error_code: String, status_code: int, response: Dictionary)
signal auth_changed(auth_data: Dictionary)

var _base_url: String = ""
var _http: HTTPRequest = null
var _busy: bool = false
var _pending_op: String = ""
var _auth_store: BackendAuthStore = null


func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)


# ── Configuration ─────────────────────────────────────────────────────────────

func configure(base_url: String) -> void:
	_base_url = base_url.strip_edges().trim_suffix("/")


func configure_from_project_settings() -> void:
	var url: String = ProjectSettings.get_setting(DEFAULT_PROJECT_SETTING_BACKEND_URL, "")
	if url != "":
		configure(url)


func get_base_url() -> String:
	return _base_url


func is_configured() -> bool:
	return _base_url != ""


# ── Auth store integration ────────────────────────────────────────────────────

func set_auth_store(store: BackendAuthStore) -> void:
	_auth_store = store


func load_auth_from_store() -> Dictionary:
	if _auth_store == null:
		return {}
	return _auth_store.load_auth()


func save_auth_to_store(session_token: String, email: String = "", email_verified: bool = false) -> bool:
	if _auth_store == null:
		return false
	return _auth_store.save_auth(session_token, email, email_verified)


func clear_auth() -> bool:
	if _auth_store == null:
		return false
	return _auth_store.clear_auth()


func has_session() -> bool:
	if _auth_store == null:
		return false
	return _auth_store.has_session()


func get_session_token() -> String:
	if _auth_store == null:
		return ""
	return _auth_store.get_session_token()


func get_email() -> String:
	if _auth_store == null:
		return ""
	return _auth_store.get_email()


func is_email_verified() -> bool:
	if _auth_store == null:
		return false
	return _auth_store.is_email_verified()


# ── Auth API ──────────────────────────────────────────────────────────────────

func register(email: String, password: String) -> bool:
	var body: Dictionary = {"email": email, "password": password}
	return _post("/v1/auth/register", body, "register", false)


func login(email: String, password: String) -> bool:
	var body: Dictionary = {"email": email, "password": password}
	return _post("/v1/auth/login", body, "login", false)


func logout() -> bool:
	return _post("/v1/auth/logout", {}, "logout", true)


func get_me() -> bool:
	return _get("/v1/me", "get_me", true)


# ── Password reset ────────────────────────────────────────────────────────────

func request_password_reset(email: String) -> bool:
	var body: Dictionary = {"email": email}
	return _post("/v1/auth/password-reset/request", body, "request_password_reset", false)


func confirm_password_reset(email: String, code: String, new_password: String) -> bool:
	var body: Dictionary = {"email": email, "code": code, "new_password": new_password}
	return _post("/v1/auth/password-reset/confirm", body, "confirm_password_reset", false)


# ── Email verification ────────────────────────────────────────────────────────

func request_email_verification() -> bool:
	return _post("/v1/auth/email/verify/request", {}, "request_email_verification", true)


func confirm_email_verification(code: String) -> bool:
	var body: Dictionary = {"code": code}
	return _post("/v1/auth/email/verify/confirm", body, "confirm_email_verification", true)


# ── Cloud save ────────────────────────────────────────────────────────────────

func load_save() -> bool:
	return _get("/v1/save", "load_save", true)


func save_save(save_data: Dictionary) -> bool:
	if save_data.is_empty():
		_fail_local("save_save", "invalid_save_data", 0, {})
		return false
	var body: Dictionary = {"save_data": save_data}
	return _put("/v1/save", body, "save_save", true)


func delete_save() -> bool:
	return _delete("/v1/save", "delete_save", true)


# ── HTTP helpers ──────────────────────────────────────────────────────────────

func _build_headers(needs_auth: bool) -> PackedStringArray:
	var headers: PackedStringArray = PackedStringArray([
		"Content-Type: application/json",
		"Accept: application/json",
	])
	if needs_auth:
		headers.append("Authorization: Bearer " + get_session_token())
	return headers


func _post(path: String, body: Dictionary, operation: String, needs_auth: bool) -> bool:
	if needs_auth and not has_session():
		_fail_local(operation, "missing_session", 0, {})
		return false
	if _busy:
		_fail_local(operation, "request_in_progress", 0, {})
		return false
	_start_request(operation)
	var err: int = _http.request(
		_base_url + path,
		_build_headers(needs_auth),
		HTTPClient.METHOD_POST,
		JSON.stringify(body)
	)
	if err != OK:
		_finish_request()
		_fail_local(operation, "network_error", 0, {})
		return false
	return true


func _get(path: String, operation: String, needs_auth: bool) -> bool:
	if needs_auth and not has_session():
		_fail_local(operation, "missing_session", 0, {})
		return false
	if _busy:
		_fail_local(operation, "request_in_progress", 0, {})
		return false
	_start_request(operation)
	var err: int = _http.request(
		_base_url + path,
		_build_headers(needs_auth),
		HTTPClient.METHOD_GET
	)
	if err != OK:
		_finish_request()
		_fail_local(operation, "network_error", 0, {})
		return false
	return true


func _put(path: String, body: Dictionary, operation: String, needs_auth: bool) -> bool:
	if needs_auth and not has_session():
		_fail_local(operation, "missing_session", 0, {})
		return false
	if _busy:
		_fail_local(operation, "request_in_progress", 0, {})
		return false
	_start_request(operation)
	var err: int = _http.request(
		_base_url + path,
		_build_headers(needs_auth),
		HTTPClient.METHOD_PUT,
		JSON.stringify(body)
	)
	if err != OK:
		_finish_request()
		_fail_local(operation, "network_error", 0, {})
		return false
	return true


func _delete(path: String, operation: String, needs_auth: bool) -> bool:
	if needs_auth and not has_session():
		_fail_local(operation, "missing_session", 0, {})
		return false
	if _busy:
		_fail_local(operation, "request_in_progress", 0, {})
		return false
	_start_request(operation)
	var err: int = _http.request(
		_base_url + path,
		_build_headers(needs_auth),
		HTTPClient.METHOD_DELETE
	)
	if err != OK:
		_finish_request()
		_fail_local(operation, "network_error", 0, {})
		return false
	return true


func _start_request(operation: String) -> void:
	_busy = true
	_pending_op = operation


func _finish_request() -> void:
	_busy = false
	_pending_op = ""


func _fail_local(operation: String, error_code: String, status_code: int, response: Dictionary) -> void:
	operation_failed.emit(operation, error_code, status_code, response)


# ── HTTPRequest callback ──────────────────────────────────────────────────────

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var op: String = _pending_op
	_finish_request()

	if result != HTTPRequest.RESULT_SUCCESS:
		operation_failed.emit(op, "network_error", response_code, {})
		return

	var text: String = body.get_string_from_utf8()
	var parsed: Dictionary = {}

	if text != "":
		var json: JSON = JSON.new()
		if json.parse(text) != OK or not json.data is Dictionary:
			operation_failed.emit(op, "invalid_json_response", response_code, {})
			return
		parsed = json.data

	if parsed.get("ok", false) != true:
		var error_code: String = str(parsed.get("error", "unknown_error"))
		operation_failed.emit(op, error_code, response_code, parsed)
		return

	_handle_success(op, response_code, parsed)


# ── Per-operation success side-effects ────────────────────────────────────────

func _handle_success(op: String, _response_code: int, response: Dictionary) -> void:
	match op:
		"login":
			var token: String = str(response.get("session_token", ""))
			var user: Dictionary = response.get("user", {}) as Dictionary
			var email: String = str(user.get("email", ""))
			var verified: bool = bool(user.get("email_verified", false))
			if token != "" and _auth_store != null:
				_auth_store.save_auth(token, email, verified)
				auth_changed.emit(_auth_store.load_auth())

		"logout":
			if _auth_store != null:
				_auth_store.clear_auth()
				auth_changed.emit({})

		"get_me":
			if _auth_store != null:
				var user: Dictionary = response.get("user", {}) as Dictionary
				var email: String = str(user.get("email", get_email()))
				var verified: bool = bool(user.get("email_verified", is_email_verified()))
				_auth_store.save_auth(get_session_token(), email, verified)
				auth_changed.emit(_auth_store.load_auth())

		"confirm_password_reset":
			# Backend revokes old sessions on password reset.
			if _auth_store != null:
				_auth_store.clear_auth()
				auth_changed.emit({})

		"confirm_email_verification":
			if _auth_store != null:
				_auth_store.save_auth(get_session_token(), get_email(), true)
				auth_changed.emit(_auth_store.load_auth())

	operation_succeeded.emit(op, response)
