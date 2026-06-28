# Android Auth Gate — Manual Validation Checklist

Patch: C3 — Android Auth Gate with Guest Mode
Date: 2026-06-28

---

## Static checks

```bash
# Confirm LocalizationData.gd matches CSV (27 auth.* keys added)
godot --headless --script res://scripts/tools/ValidateLocalizationDataFreshness.gd

# Confirm required keys exist and export presets include the CSV
godot --headless --script res://scripts/tools/ValidateLocalizationExport.gd

# Confirm editor opens without errors (parse/scene load check)
godot --headless --editor --quit

git status
git diff --stat
```

> Note: Godot 4 headless editor mode may not be available in all CI environments.
> Run validation manually in the Godot editor if headless fails.

---

## Validation environment notes (2026-06-28)

Headless Godot commands cannot be run in the current environment (Windows, no PATH-accessible
`godot` binary). Validation was performed by code review. Regeneration of `LocalizationData.gd`
was performed automatically by the editor localization-sync plugin on CSV save (confirmed: key
count updated to 398, all `auth.*` keys present in both `en` and `ru` blocks).

---

## Manual checklist

### Web / Editor (no auth gate)

- [ ] Start the game in the Godot editor (LocalDebug platform).
      Gameplay screen appears directly — no AuthGateScreen shown.
- [ ] Start the exported Web build in a browser.
      Gameplay screen appears directly — no AuthGateScreen shown.
- [ ] Confirm `Platform.get_platform_key()` returns `"debug"` in editor, `"yandex"` on web.

### Android — no stored session

- [ ] Launch on Android device with no `user://backend_auth.json` (fresh install or after manual
      file removal).
- [ ] `AuthGateScreen` appears over the game background.
- [ ] Login form is shown (email, password, Sign In, Forgot password?, Register, Continue as Guest).
- [ ] Tapping outside the panel does not dismiss it.

### Android — Guest mode

- [ ] Tap "Continue as Guest" on the auth gate.
- [ ] Auth gate disappears and gameplay starts normally.
- [ ] No backend request is made (confirm via Logcat: no HTTP calls after guest tap).
- [ ] Local save loads correctly in guest mode.
- [ ] `SaveManager` backend cloud-save methods are not called.

### Android — Login success

- [ ] Enter valid credentials and tap Sign In.
- [ ] Auth gate disappears and gameplay starts.
- [ ] No second auth gate appears on next session (token is stored).

### Android — Login failure

- [ ] Enter wrong password and tap Sign In.
- [ ] Status label shows the backend error code (e.g. `invalid_credentials`).
- [ ] Login form remains visible; no crash; no stuck state.

### Android — Register then login

- [ ] Switch to Register tab.
- [ ] Enter new email, password (≥8 chars), confirm password.
- [ ] Tap Register.
- [ ] Backend registers account, then `AuthGateScreen` automatically calls login.
- [ ] On login success auth gate disappears and gameplay starts.

### Android — Register validation errors

- [ ] Empty email → "Email is required" shown, no network request.
- [ ] Password < 8 chars → "Password must be at least 8 characters" shown, no request.
- [ ] Passwords do not match → "Passwords do not match" shown, no request.

### Android — Password reset request

- [ ] Tap "Forgot password?" on the login form.
- [ ] Reset Request form appears (email field, Send Reset Code button, Back).
- [ ] Enter email and tap Send Reset Code.
- [ ] Status shows "Reset code sent to your email".
- [ ] Reset Confirm form appears (email pre-filled, code, new password, confirm, Set New Password).

### Android — Password reset confirm

- [ ] Enter the 6-digit code from email, new password (≥8), confirm password.
- [ ] Tap Set New Password.
- [ ] Status shows "Sign in with your new password" and login form appears.
- [ ] User can log in with the new password.

### Android — Reset confirm validation errors

- [ ] Code not 6 digits → "Enter a 6-digit code" shown, no request.
- [ ] New password < 8 chars → validation error, no request.
- [ ] New password ≠ confirm → "Passwords do not match" shown, no request.

### Android — Existing valid session

- [ ] Log in once to store a session token.
- [ ] Relaunch the app.
- [ ] Auth gate shows "Checking account..." state briefly.
- [ ] `Platform.backend_get_me()` succeeds → auth gate disappears, gameplay starts.
- [ ] No login form is shown.

### Android — Existing invalid/expired session

- [ ] Manually corrupt `user://backend_auth.json` with a fake token
      (e.g. set `session_token` to `"bad_token"`).
- [ ] Launch the app.
- [ ] Auth gate shows "Checking account..." briefly.
- [ ] `get_me` returns `unauthorized`.
- [ ] `Platform.backend_clear_local_auth()` is called — local token is removed.
- [ ] Status shows "Session expired. Please sign in."
- [ ] Login form appears — no infinite loop, no crash.
- [ ] Auth gate does not repeatedly call `get_me`.

### Security / logging

- [ ] Logcat contains no password values.
- [ ] Logcat contains no session token values.
- [ ] Logcat contains no 6-digit reset codes.
- [ ] Logcat contains no full backend response JSON with sensitive fields.

### SaveManager isolation

- [ ] Confirm `SaveManager` does not call `Platform.backend_load_save()` in this patch.
- [ ] Confirm `SaveManager` does not call `Platform.backend_save_save()` in this patch.
- [ ] Local save file (`user://save_v1.json`) is read and written normally regardless of auth mode.

---

## Files changed in C3

| File | Change |
|------|--------|
| `scripts/platform/PlatformServices.gd` | Added `backend_clear_local_auth()` stub |
| `autoload/Platform.gd` | Added `backend_clear_local_auth()` delegate |
| `scripts/platform/AndroidRuStorePlatform.gd` | Added `backend_clear_local_auth()` implementation |
| `localization/game_text.csv` | Added 27 `auth.*` localization keys |
| `scripts/ui/LocalizationData.gd` | Auto-regenerated; key count 371 → 398 |
| `scenes/auth/AuthGateScreen.tscn` | New scene |
| `scenes/auth/AuthGateScreen.gd` | New script |
| `scenes/main/Main.gd` | Added Android auth gate routing |
| `README.md` | Documented C3 |
| `docs/AGENTS.md` | Added auth gate rules |
| `docs/validation/android_auth_gate_validation.md` | This file |

---

## Not changed in C3

- Web/Yandex startup (`WebYandexPlatform.gd`, `YandexBridge`) — unchanged.
- `SaveManager` — no backend wiring.
- Backend Cloud Functions — unchanged.
- Gameplay, ads, payments, balance — unchanged.
- `LocalDebugPlatform.gd` — unchanged (no auth gate in editor).
