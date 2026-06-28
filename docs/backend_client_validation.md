# Backend Client Validation Checklist

Manual validation for `BackendAuthStore` and `BackendApiClient`.
Covers C1 foundation + C2 hardening patch.

## Environment note

`godot --headless --editor --quit` cannot be run in this CI environment because
Godot 4 is not available as a CLI binary here. Static type-checking and
parse-error detection must be done by opening the project in the Godot editor
and confirming no script errors appear in the Output panel.

## Git summary

```
git status
git diff --stat
```

Expected changed/new files this patch:
- `scripts/platform/backend/BackendApiClient.gd`  (hardened)
- `README.md`                                      (configuration section updated)
- `AGENTS.md`                                      (not_configured + http_error rules added)
- `docs/backend_client_validation.md`              (this file, updated)

## Static checks (open project in Godot editor)

- [ ] No script errors for `BackendAuthStore.gd` in Output panel.
- [ ] No script errors for `BackendApiClient.gd` in Output panel.
- [ ] `class_name BackendAuthStore` resolves without duplicate-class warnings.
- [ ] `class_name BackendApiClient` resolves without duplicate-class warnings.

## Configuration guards (no network required)

- [ ] `BackendApiClient.new()` can be added as a child Node without errors.
- [ ] `is_configured()` returns `false` before `configure()` is called.
- [ ] `register("a@b.com", "pw")` before `configure()` emits
  `operation_failed("register", "not_configured", 0, {})` and returns `false`.
- [ ] `login(...)` before `configure()` emits `not_configured`.
- [ ] `request_password_reset(...)` before `configure()` emits `not_configured`.
- [ ] `load_save()` before `configure()` emits `not_configured` (missing_session
  fires first because no session exists; set a fake session then verify
  `not_configured` fires when URL is empty).
- [ ] After `configure("https://example.com/")`, `get_base_url()` returns
  `"https://example.com"` (trailing slash stripped).
- [ ] After `configure("  https://example.com  ")`, `get_base_url()` returns
  `"https://example.com"` (edge whitespace stripped).
- [ ] `is_configured()` returns `true` after a valid configure call.

## Protected endpoint guards — missing session (no network required)

- [ ] `logout()` without a session emits `operation_failed("logout", "missing_session", 0, {})` and returns `false`.
- [ ] `get_me()` without a session emits `missing_session`.
- [ ] `load_save()` without a session emits `missing_session`.
- [ ] `save_save({"save_version": 1, "last_save_unix_time": 0})` without a session emits `missing_session`.
- [ ] `delete_save()` without a session emits `missing_session`.
- [ ] `request_email_verification()` without a session emits `missing_session`.
- [ ] `confirm_email_verification("code")` without a session emits `missing_session`.

## Guard priority order

- [ ] A protected method called with no session AND no URL emits `missing_session`
  (not `not_configured`) — `missing_session` takes priority.
- [ ] An unprotected method called with no URL emits `not_configured`.
- [ ] A method called while a request is in progress emits `request_in_progress`.

## Domain guards (no network required)

- [ ] `save_save({})` emits `operation_failed("save_save", "invalid_save_data", 0, {})` and returns `false`.

## Concurrency guard (no network required)

- [ ] Starting a second request while one is already in-flight emits
  `operation_failed(op, "request_in_progress", 0, {})`.

## Response parsing (_parse_response_body)

These can be verified without a live backend by using a mock HTTPRequest:

- [ ] Empty body → parse result has `error == "empty_response"`.
- [ ] Whitespace-only body → `empty_response`.
- [ ] `"not json"` body → `invalid_json_response`.
- [ ] `"[1,2,3]"` body (valid JSON but not Dictionary) → `invalid_json_response`.
- [ ] `'{"ok":true}'` body → parse succeeds, `response == {"ok": true}`.

## Non-2xx response handling (requires live backend or mock)

- [ ] A 401 response with `{"ok": false, "error": "unauthorized"}` emits
  `operation_failed(op, "unauthorized", 401, {"ok": false, "error": "unauthorized"})`.
- [ ] A 500 response with no body emits `operation_failed(op, "http_error", 500, {})`.
- [ ] A 400 response with a plain-text body emits `operation_failed(op, "http_error", 400, {})`.
- [ ] A 400 response with `{"ok": false}` but no `error` field emits `http_error`.
- [ ] A 400 response with `{"ok": false, "error": "email_already_registered"}` emits
  `operation_failed(op, "email_already_registered", 400, {...})`.

## 2xx response handling (requires live backend or mock)

- [ ] A 200 response with empty body emits `operation_failed(op, "empty_response", 200, {})`.
- [ ] A 200 response with non-JSON body emits `invalid_json_response`.
- [ ] A 200 response with `{"ok": false, "error": "missing_save_version"}` emits
  `operation_failed(op, "missing_save_version", 200, {...})`.
- [ ] A 200 response with `{"ok": false}` (no `error` field) emits `unknown_error`.
- [ ] A 200 response with `{"ok": true, ...}` calls `_handle_success` then emits
  `operation_succeeded`.

## Login success side effects (requires live backend)

- [ ] `login(email, password)` on success stores session token via `BackendAuthStore`
  without printing the token value.
- [ ] After successful login, `has_session()` returns `true`.
- [ ] `auth_changed` is emitted with the updated auth dictionary (no token in console log).

## Logout success side effects (requires live backend)

- [ ] `logout()` on success clears local auth store.
- [ ] `auth_changed` is emitted with `{}`.
- [ ] `has_session()` returns `false` after logout.

## get_me success side effects (requires live backend)

- [ ] `get_me()` on success updates stored email and email_verified while
  keeping the existing session token.
- [ ] `auth_changed` is emitted.

## Password reset confirm side effects (requires live backend or mock)

- [ ] `confirm_password_reset(email, code, new_password)` on success clears
  local auth store (backend revokes old sessions).
- [ ] `auth_changed` is emitted with `{}`.

## Email verification confirm side effects (requires live backend or mock)

- [ ] `confirm_email_verification(code)` on success sets `email_verified = true`
  in local auth store while preserving session token and email.
- [ ] `auth_changed` is emitted.
- [ ] `is_email_verified()` returns `true` after success.

## Security checks

- [ ] No `print()` or `push_warning()` call in `BackendApiClient.gd` or
  `BackendAuthStore.gd` outputs a session token.
- [ ] Request body dictionaries containing passwords, codes, or save JSON are
  never echoed to the console.
- [ ] `user://backend_auth.json` does not appear in `git status` (should be
  excluded by `user://` being outside `res://`).
