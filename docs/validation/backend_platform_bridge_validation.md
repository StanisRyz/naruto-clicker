# Backend Platform Bridge — Manual Validation Checklist

Patch: C2 — Platform bridge for Android/RuStore backend auth/save.

## Pre-validation commands

```bash
# Check for uncommitted secrets (must return nothing sensitive)
git status
git diff --stat

# Headless compile check (if Godot is available)
godot --headless --editor --quit
```

## Configuration checklist

- [ ] `project.godot` contains `cloud_save/backend_url` under `[application]`
- [ ] The URL is readable via `ProjectSettings.get_setting("application/cloud_save/backend_url")`
- [ ] No passwords, session tokens, SMTP keys, or service-account keys are present in any committed file
- [ ] `user://backend_auth.json` is not committed (covered by `.gitignore`)

## Platform.gd checklist

- [ ] `Platform` declares `backend_auth_changed`, `backend_operation_succeeded`, `backend_operation_failed` signals
- [ ] `Platform._connect_backend_signals()` is called from `_ready()` for all three code paths (web / android / editor)
- [ ] `Platform` exposes all forwarding methods: `configure_backend_client`, `backend_has_session`, `backend_get_email`, `backend_is_email_verified`, `backend_register`, `backend_login`, `backend_logout`, `backend_get_me`, `backend_request_password_reset`, `backend_confirm_password_reset`, `backend_request_email_verification`, `backend_confirm_email_verification`, `backend_load_save`, `backend_save_save`, `backend_delete_save`
- [ ] All forwarding methods return safe defaults when `_impl` is null

## PlatformServices.gd checklist

- [ ] `PlatformServices` declares the three backend signals with `@warning_ignore("unused_signal")`
- [ ] All backend stub methods are present and return `false` / `""` / emit `not_supported` failure

## AndroidRuStorePlatform checklist

- [ ] `_backend_auth_store` (BackendAuthStore) is created in `_ready()`
- [ ] `_backend_client` (BackendApiClient) is created and added as a child node in `_ready()`
- [ ] `_backend_client.set_auth_store(_backend_auth_store)` is called
- [ ] `_backend_client.configure_from_project_settings()` is called — URL is loaded from `project.godot`
- [ ] `auth_changed`, `operation_succeeded`, `operation_failed` signals from client are connected to handler methods
- [ ] Handlers re-emit through `backend_auth_changed`, `backend_operation_succeeded`, `backend_operation_failed`
- [ ] All backend methods delegate to `_backend_client`
- [ ] All backend methods return `false` and emit `backend_client_unavailable` when `_backend_client` is null
- [ ] `configure_backend_client(base_url)` calls `configure(base_url)` if non-empty, else `configure_from_project_settings()`

## Web / Yandex platform checklist

- [ ] `WebYandexPlatform` does not implement any backend methods explicitly — inherits `PlatformServices` stubs
- [ ] Calling `Platform.backend_register(...)` on Web emits `backend_operation_failed` with `not_supported` — no crash
- [ ] `YandexBridge` cloud-save path is unchanged
- [ ] Web payments and ads are unchanged

## LocalDebugPlatform checklist

- [ ] `LocalDebugPlatform` does not implement any backend methods explicitly — inherits `PlatformServices` stubs
- [ ] Calling `Platform.backend_login(...)` in editor emits `backend_operation_failed` with `not_supported` — no crash
- [ ] Ad and payment simulation in editor is unchanged

## SaveManager checklist

- [ ] `SaveManager` does not call `Platform.backend_load_save()` or `Platform.backend_save_save()`
- [ ] Local save format is unchanged
- [ ] Yandex cloud-save behaviour is unchanged

## Runtime smoke tests (manual, Android device or editor)

- [ ] `Platform.backend_has_session()` returns `false` on fresh install
- [ ] `Platform.backend_get_email()` returns `""` on fresh install
- [ ] `Platform.backend_get_me()` without prior login returns `false` and emits `backend_operation_failed` with `missing_session`
- [ ] `Platform.backend_login("bad@test.com", "wrong")` returns `false` eventually and emits `backend_operation_failed` (network required)
- [ ] No session token appears in Logcat / Godot output at any point

## Security checklist

- [ ] No password is printed to console in any code path
- [ ] No session token is printed to console in any code path
- [ ] No reset code or verification code is printed to console
- [ ] No full save JSON blob is printed to console
- [ ] `git log --oneline` shows no secrets in commit messages
- [ ] `git diff HEAD~1` shows no secrets in the diff
