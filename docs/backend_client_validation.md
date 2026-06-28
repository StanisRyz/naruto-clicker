# Backend Client Validation Checklist

Manual validation for `BackendAuthStore` and `BackendApiClient` (C1 foundation patch).

## Environment note

`godot --headless --editor --quit` could not be run in the CI environment because
Godot 4 is not available as a CLI binary in this context. Static type-checking and
parse-error detection must be done by opening the project in the Godot editor and
confirming no script errors appear in the Output panel.

## Git summary

```
git status
git diff --stat
```

Expected changed files:
- `scripts/platform/backend/BackendAuthStore.gd`  (new)
- `scripts/platform/backend/BackendApiClient.gd`  (new)
- `README.md`                                      (added backend section)
- `AGENTS.md`                                      (added backend rules section)
- `docs/AGENTS.md`                                 (added backend notes section)
- `docs/backend_client_validation.md`              (this file, new)

## Static checks (open project in Godot editor)

- [ ] No script errors for `BackendAuthStore.gd` in Output panel.
- [ ] No script errors for `BackendApiClient.gd` in Output panel.
- [ ] `class_name BackendAuthStore` resolves correctly (no duplicate class name warnings).
- [ ] `class_name BackendApiClient` resolves correctly.

## BackendApiClient instantiation

- [ ] `BackendApiClient.new()` can be added as a Node child without errors.
- [ ] `configure("https://example.com/")` stores `"https://example.com"` (trailing slash stripped).
- [ ] `configure("  https://example.com  ")` strips whitespace edges.
- [ ] `is_configured()` returns `false` before `configure()` is called.
- [ ] `is_configured()` returns `true` after a non-empty URL is configured.

## BackendAuthStore

- [ ] `load_auth()` returns `{}` when `user://backend_auth.json` does not exist.
- [ ] `load_auth()` returns `{}` when the file contains invalid JSON (no crash).
- [ ] `load_auth()` returns `{}` when the file root is not a Dictionary (no crash).
- [ ] `save_auth("tok123", "a@b.com", true)` writes a valid JSON file to `user://backend_auth.json`.
- [ ] After `save_auth`, `has_session()` returns `true`.
- [ ] After `save_auth`, `get_session_token()` returns the saved token.
- [ ] After `save_auth`, `get_email()` returns the saved email.
- [ ] After `save_auth`, `is_email_verified()` returns the saved value.
- [ ] `clear_auth()` removes or overwrites the auth file; subsequent `has_session()` returns `false`.
- [ ] `session_token` is never printed or logged by `BackendAuthStore`.

## Protected endpoint guards (no network required)

- [ ] Calling `logout()` without a session token emits `operation_failed("logout", "missing_session", 0, {})` and returns `false` — no HTTP request is made.
- [ ] Calling `get_me()` without a session token emits `operation_failed("get_me", "missing_session", 0, {})`.
- [ ] Calling `load_save()` without a session token emits `operation_failed("load_save", "missing_session", 0, {})`.
- [ ] Calling `save_save({})` emits `operation_failed("save_save", "invalid_save_data", 0, {})`.
- [ ] Calling `delete_save()` without a session token emits `operation_failed("delete_save", "missing_session", 0, {})`.

## Concurrency guard (no network required)

- [ ] Starting a second request while one is in progress emits `operation_failed(op, "request_in_progress", 0, {})`.

## Login success (requires live backend)

- [ ] `login(email, password)` on success stores session token via `BackendAuthStore` without printing it.
- [ ] `auth_changed` is emitted with the updated auth dictionary after successful login.
- [ ] `has_session()` returns `true` after successful login.

## Logout success (requires live backend)

- [ ] `logout()` on success clears local auth store.
- [ ] `auth_changed` is emitted with `{}` after successful logout.
- [ ] `has_session()` returns `false` after logout.

## Password reset confirm (requires live backend or mock)

- [ ] `confirm_password_reset(email, code, new_password)` on success clears local auth store.
- [ ] `auth_changed` is emitted with `{}` after successful password reset confirm.

## Email verification confirm (requires live backend or mock)

- [ ] `confirm_email_verification(code)` on success sets `email_verified = true` in local auth store.
- [ ] `auth_changed` is emitted with the updated auth dictionary.

## Save operations (requires live backend)

- [ ] `save_save({"save_version": 1, "last_save_unix_time": 1700000000})` sends `PUT /v1/save` with `{"save_data": {...}}`.
- [ ] `load_save()` on success emits `operation_succeeded("load_save", response)` with the full response dictionary.
- [ ] `delete_save()` on success emits `operation_succeeded("delete_save", response)`.
- [ ] Save data dictionary is never mutated by `BackendApiClient`.

## Error response handling (requires live backend or mock)

- [ ] A response with `{"ok": false, "error": "invalid_credentials"}` emits `operation_failed(op, "invalid_credentials", 401, response)`.
- [ ] A response with `{"ok": false, "error": "email_already_registered"}` emits `operation_failed(op, "email_already_registered", ...)`.
- [ ] A non-JSON response body emits `operation_failed(op, "invalid_json_response", response_code, {})`.
- [ ] A network failure (offline / wrong URL) emits `operation_failed(op, "network_error", ...)`.

## Security checks

- [ ] No `print()` or `push_warning()` call in either script emits the session token value.
- [ ] Passwords, reset codes, and verification codes are never echoed to the console.
- [ ] `user://backend_auth.json` is not committed to the repository.
