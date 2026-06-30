# C7.1 / C7.1.1 — Account Save Authority, Guest Paid Shop Lock & GuestMigrationPrompt Removal Validation

## Overview

- Android Guest mode: local-only progress, rewarded ads available, paid gem purchases locked.
- Guest → Register: current guest save uploads to new account cloud; gameplay continues.
- Guest → Login: existing account cloud save loads immediately; guest save is never uploaded.
- Guest → Login with no cloud save: clean account save starts; guest progress is discarded.
- Direct account startup: existing `CloudRestorePrompt` restore behavior preserved.
- Web/Yandex: paid shop and cloud-save behavior completely unchanged.
- Logout: paid shop locks again on Android; auto-upload stops naturally (no session).
- **C7.1.1:** `GuestMigrationPrompt` node removed from `ClickerScreen.tscn`. All runtime
  references (`@onready`, visibility checks) removed from `ClickerScreen.gd`.
  Scene/script files `GuestMigrationPrompt.gd/.tscn` retained but unreferenced.

---

## C7.1.1 Cleanup Checklist

- [ ] `ClickerScreen.tscn` has no `[ext_resource … GuestMigrationPrompt.tscn …]` line.
- [ ] `ClickerScreen.tscn` has no `[node name="GuestMigrationPrompt" …]` node.
- [ ] `ClickerScreen.tscn` `load_steps` is 24 (was 25).
- [ ] `ClickerScreen.gd` has no `@onready var guest_migration_prompt` declaration.
- [ ] `ClickerScreen.gd` has no `guest_migration_prompt.visible` references.
- [ ] `ClickerScreen.gd` `_is_safe_for_fullscreen_ad()` does not check `guest_migration_prompt`.
- [ ] `ClickerScreen.gd` `_is_main_screen_clear_for_rewarded_banner()` does not check `guest_migration_prompt`.
- [ ] `AuthGateScreen.gd` header comment lists `account_session`, `account_login`, `account_register`, `guest`.
- [ ] `GuestMigrationPrompt.gd/.tscn` files exist but are not instantiated by any scene.
- [ ] C7.1 core methods remain intact: `on_account_registered_from_guest_overlay`, `on_account_login_from_guest_overlay`, `_is_paid_shop_available`, `_update_shop_paid_availability`.

---

## Manual Checklist

### Android Guest startup
- [ ] App starts, AuthGate shown, user taps "Continue as Guest".
- [ ] Gameplay starts normally. HUD, abilities, combat all work.
- [ ] `auth_gate_completed("guest")` emitted; `ClickerScreen._gameplay_started_as_guest = true`.

### Android Guest — rewarded ads
- [ ] Rewarded ad banner appears and is tappable in guest mode.
- [ ] Ad plays and reward (gold/damage buff) is granted.
- [ ] Ad shop gems (rewarded_ad product type) can be purchased in guest mode.

### Android Guest — paid gem purchases locked
- [ ] Open Shop → tap donation/paid gems entry.
- [ ] AuthGate overlay appears instead of `GemPurchaseDialog`.
- [ ] `Platform.purchase_product()` is **not** called.
- [ ] `GemPurchaseDialog` does not open.

### Guest → Register
- [ ] From Guest session, open Settings → Sign in / Register → Register tab.
- [ ] Register with a new email/password.
- [ ] `auth_gate_completed("account_register")` emitted.
- [ ] `on_account_registered_from_guest_overlay()` called in ClickerScreen.
- [ ] Current guest save uploaded to backend cloud automatically (no prompt).
- [ ] Settings cloud status shows upload progress then success message.
- [ ] Gameplay continues without scene reload; progress unchanged.
- [ ] `_gameplay_started_as_guest` set to `false`.
- [ ] Paid gem purchases now available (AuthGate no longer shown).

### Guest → Register — upload failure
- [ ] If backend upload fails, local gameplay remains unchanged.
- [ ] Account stays logged in.
- [ ] Error status shown in SettingsWindow if open; otherwise `push_warning` only.
- [ ] Auto-upload will retry the next local save.

### Guest → Login with existing cloud save
- [ ] From Guest session, open Settings → Sign in / Register → Login tab.
- [ ] Login with existing account credentials.
- [ ] `auth_gate_completed("account_login")` emitted.
- [ ] `on_account_login_from_guest_overlay()` called in ClickerScreen.
- [ ] Backend auto-upload suspended immediately.
- [ ] `Platform.backend_load_save()` called — no guest progress uploaded.
- [ ] Cloud save applies; gameplay state reflects account progress.
- [ ] `CloudRestorePrompt` is **not** shown.
- [ ] `GuestMigrationPrompt` is **not** shown.
- [ ] Backend auto-upload resumes after cloud apply.
- [ ] `_gameplay_started_as_guest` set to `false`.
- [ ] Paid gem purchases now available.

### Guest → Login with no cloud save (new account)
- [ ] From Guest session, login with account that has no cloud save.
- [ ] `has_save == false` response received.
- [ ] Clean `ClickerState.new()` applied (no guest gems/progress carried over).
- [ ] Save written locally.
- [ ] `_gameplay_started_as_guest` set to `false`.
- [ ] Paid gem purchases now available.
- [ ] Auto-upload resumes.

### Direct Account startup (session check)
- [ ] App starts with stored session; `get_me` succeeds.
- [ ] `auth_gate_completed("account_session")` emitted.
- [ ] `request_backend_cloud_restore_check("auth_overlay")` called for startup overlay.
- [ ] `CloudRestorePrompt` shown if cloud is newer than local (existing C5.3 behavior).
- [ ] Manual Save/Load from Settings still works.

### Direct Account startup — no session / session expired
- [ ] `get_me` fails → login form shown.
- [ ] After login: `auth_gate_completed("account_login")` emitted.
- [ ] Since `_gameplay_started_as_guest == false` (game not yet started), normal startup flow proceeds.

### Logout
- [ ] Open Settings → Logout.
- [ ] `Platform.backend_has_session()` returns `false`.
- [ ] `_on_platform_backend_auth_changed` fires in ClickerScreen.
- [ ] `GemPurchaseDialog` hidden if open.
- [ ] Shop refreshes: paid gem entry now opens AuthGate again.
- [ ] Backend auto-upload stops naturally (`queue_backend_cloud_save` guards against no session).
- [ ] Local gameplay continues.

### Web / Yandex
- [ ] Web build: paid gem shop functions as before (no Android guard applied).
- [ ] Yandex cloud-save (via YandexBridge) unchanged.
- [ ] No AuthGate on Web startup.

---

## Static / Tooling Checks

```bash
# Validate localization freshness and export
godot --headless --script res://scripts/tools/GenerateLocalizationData.gd
godot --headless --script res://scripts/tools/ValidateLocalizationDataFreshness.gd
godot --headless --script res://scripts/tools/ValidateLocalizationExport.gd

# Confirm no compile errors
godot --headless --editor --quit

# Review changed files
git diff --stat
```

---

## Files Changed in C7.1

| File | Change |
|------|--------|
| `scenes/auth/AuthGateScreen.gd` | `get_me` emits `account_session`; `login` emits `account_login` or `account_register` |
| `scenes/main/Main.gd` | Handles `account_session/login/register`; routes overlay to `on_account_registered_from_guest_overlay` or `on_account_login_from_guest_overlay` |
| `scenes/game/ClickerScreen.gd` | Adds register/login overlay handlers, paid shop lock, clean save helper; removes GuestMigrationPrompt flow |
| `localization/game_text.csv` | 10 new keys: `shop.paid_guest_locked_*`, `account_flow.*` |

---

## Known Limitations

- `GuestMigrationPrompt` scene/script files are retained but never instantiated; the node exists in the scene tree but `show_prompt()` is never called.
- No conflict-resolution UI for simultaneous edits (out of scope for C7.1).
- No silent cloud auto-load on non-guest account startup (intentional; C5.3 prompt remains).
