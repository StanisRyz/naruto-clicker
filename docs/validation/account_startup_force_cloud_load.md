# C7.3.1 — Account Startup Force Cloud Load Validation

## Overview

- Account cloud save is authoritative for **every** Android/RuStore account
  login/session — not just the Guest → Login overlay path (C7.1).
- Stored account session at boot, direct AuthGate account login at boot, account
  register at boot, and the AuthGate overlay revalidating a stored session mid-session
  all force-load the account cloud save automatically.
- `CloudRestorePrompt` no longer appears for any account startup/login decision.
- Guest mode is unaffected: local-only, no backend calls at startup.
- Guest → Register still uploads the guest save (only guest-save migration path).
- Guest → Login still force-loads the account cloud save without uploading guest save
  (unchanged from C7.1 — this patch just adds the startup-equivalent flow alongside it).
- Manual "Load from Cloud" in Settings is unchanged and still requires the user to tap
  the button (that tap is the confirmation; no separate prompt was ever used there).
- Web/Yandex startup is completely unchanged (`_begin_account_startup_cloud_load()`
  no-ops off Android).

---

## Manual Checklist

### Fresh install → login existing account with cloud save
- [ ] Fresh install, AuthGate shown, user logs in to an account that has a cloud save.
- [ ] `auth_gate_completed("account_login")` fires; ClickerScreen is instantiated with
      `_startup_auth_source == "account_login"`, `_gameplay_started_as_guest == false`.
- [ ] `ClickerScreen._ready()` calls `_begin_account_startup_cloud_load()`, which sets
      `_force_account_cloud_load_on_startup = true` and calls `Platform.backend_load_save()`.
- [ ] Cloud save loads automatically; gameplay reflects account progress.
- [ ] `CloudRestorePrompt` does **not** appear at any point.
- [ ] Backend auto-upload (suspended before `_load_game_on_start_async()`) resumes
      after the cloud load completes.

### Fresh install → login account with no cloud save
- [ ] Fresh install, login to an account with `has_save == false`.
- [ ] `_apply_clean_account_save_after_missing_cloud()` runs: a fresh `ClickerState` is
      applied and saved locally.
- [ ] No guest/local save is uploaded before or during this decision.
- [ ] `CloudRestorePrompt` does **not** appear.
- [ ] Backend auto-upload resumes.

### Stored account session at boot (returning user, valid token)
- [ ] App relaunch with a previously valid session; `get_me` succeeds → `account_session`.
- [ ] Same force-load path as above runs (`_gameplay_started_as_guest` is false since
      the source is not `"guest"`).
- [ ] Cloud save loads automatically; no prompt.

### Guest → Register (unchanged, C7.1)
- [ ] Start as Guest, make progress, then Register a new account.
- [ ] `on_account_registered_from_guest_overlay()` runs: current guest save uploads to
      the new account's cloud. No force-load, no `CloudRestorePrompt`.
- [ ] Paid shop unlocks after successful register/session.

### Guest → Login (unchanged, C7.1; now shares the missing-cloud helper)
- [ ] Start as Guest, make progress, then Login to an existing account.
- [ ] Guest save is **not** uploaded.
- [ ] Account cloud save force-loads via `on_account_login_from_guest_overlay()`.
- [ ] If the account has no cloud save, `_apply_clean_account_save_after_missing_cloud()`
      starts a clean save (guest progress discarded, matching C7.1 behavior).
- [ ] Paid shop unlocks for the account.

### AuthGate overlay reopened mid-session, stored session revalidates
- [ ] While playing (e.g. Guest tapping Settings → Account/Cloud → Sign in), the
      overlay's `get_me` succeeds before the user submits anything → `"account_session"`.
- [ ] `Main.gd` calls `_clicker_screen.on_account_login_from_guest_overlay()` (not
      `request_backend_cloud_restore_check`) — force-load runs, no prompt.

### Manual Load from Cloud in Settings (unchanged)
- [ ] Logged-in account, open Settings → Account/Cloud → "Load from Cloud".
- [ ] Confirmation is the button tap itself; `_manual_backend_cloud_download_requested`
      routes the response — unaffected by the new startup force-load flags.
- [ ] Success/failure status messages unchanged.

### Cloud load failure at startup
- [ ] Simulate a `load_save` failure (e.g. network error) during startup force-load.
- [ ] `_force_account_cloud_load_on_startup` clears; backend auto-upload resumes.
- [ ] Local gameplay state is left unchanged — nothing is uploaded as the account save.
- [ ] If Settings happens to be open, a non-intrusive status message shows
      (`account_flow.login_cloud_load_failed`); otherwise only a `push_warning` (error
      code only, no tokens/save payloads).

### Web / Yandex
- [ ] Web build: no AuthGate, no backend calls, `_begin_account_startup_cloud_load()`
      returns immediately on `not OS.has_feature("android")`.
- [ ] Yandex cloud-save (`YandexBridge`) unchanged.

---

## Static / Tooling Checks

```bash
godot --headless --editor --quit
godot --headless --script res://scripts/tools/ValidateLocalizationDataFreshness.gd
godot --headless --script res://scripts/tools/ValidateLocalizationExport.gd
git status
git diff --stat
```

No `localization/game_text.csv` changes were needed — the startup flow reuses the
existing `account_flow.login_cloud_load_started/success/missing/failed` keys, so
`GenerateLocalizationData.gd` does not need to be re-run for this patch.

---

## Files Changed in C7.3.1

| File | Change |
|------|--------|
| `scenes/game/ClickerScreen.gd` | Adds `_force_account_cloud_load_on_startup` flag and `_begin_account_startup_cloud_load()`; `_ready()` calls it instead of `request_backend_cloud_restore_check("startup")`; `load_save` success/failure handlers check the new flag first; renamed `_apply_clean_account_save_after_guest_login()` → `_apply_clean_account_save_after_missing_cloud()` |
| `scenes/main/Main.gd` | `"account_session"` overlay case now calls `on_account_login_from_guest_overlay()` instead of `request_backend_cloud_restore_check("auth_overlay")` |
| `AGENTS.md` | New "Account Startup Force Cloud Load Rules (C7.3.1)" section |
| `README.md` | New "C7.3.1 — Account Startup Force Cloud Load" changelog entry |
| `docs/validation/account_save_authority_guest_shop_lock.md` | Superseded-by note added for the old "Direct Account startup" section |

---

## Known Limitations / Deferred

- `CloudRestorePrompt.gd/.tscn`, `request_backend_cloud_restore_check()`,
  `_evaluate_cloud_restore_candidate()`, and the `_startup_cloud_restore_*` fields are
  left in the repo unused rather than deleted — no remaining call path shows the
  prompt for account startup/login. Cleanup can happen in a later patch.
- No conflict-resolution UI for simultaneous edits (still out of scope).
