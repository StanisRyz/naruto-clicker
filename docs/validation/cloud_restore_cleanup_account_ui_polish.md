# C7.3.4 — CloudRestorePrompt Cleanup & Account/Settings UI Polish Validation

## Overview

- `CloudRestorePrompt` (`scenes/ui/CloudRestorePrompt.gd/.tscn/.gd.uid`) is deleted —
  it was already unused at runtime since C7.3.1 made account cloud save authoritative.
  All associated state/methods in `ClickerScreen.gd` (`_startup_cloud_restore_*`,
  `_pre_startup_*`, `_capture_pre_startup_local_save_snapshot()`,
  `request_backend_cloud_restore_check()`, `_evaluate_cloud_restore_candidate()`,
  `_on_cloud_restore_load_confirmed()`, `_on_cloud_restore_keep_local_confirmed()`) are
  removed.
- `AccountWindow` no longer has a user-facing "Load from Cloud" action — `Save to Cloud`
  is the only manual cloud action. The manual-download branch in `ClickerScreen.gd`
  (`_manual_backend_cloud_download_requested`, `_on_account_window_cloud_save_download_requested()`)
  is removed along with it.
- `AccountWindow`'s signed-in state is simplified to `Email: ...` + email verification
  status + `Save to Cloud` + `Logout`. The big status label, Verify Email button,
  verification code input, and Confirm Code button are removed from the UI (the backend
  methods they called are untouched).
- `AccountWindow` action buttons now use fixed texture-scale sizing
  (`Vector2(218, 75)`, `SIZE_SHRINK_CENTER`) instead of stretching full window width.
- `SettingsWindow` is enlarged proportionally from `540×525` to `648×630` (`1.2×` on
  both axes) so `VersionLabel` is visible without scrolling.
- 26 stale localization keys removed (`cloud_restore.*` and the Load-from-Cloud /
  Verify-Email keys); `LocalizationData.gd` regenerated (454 → 423 keys).
- No backend Cloud Function, `SaveManager` schema, payment/RuStore, ads, shop-lock, or
  gameplay-balance changes.

---

## Manual Checklist

### CloudRestorePrompt removal
- [ ] No `CloudRestorePrompt` node in `ClickerScreen.tscn`.
- [ ] `scenes/ui/CloudRestorePrompt.gd/.tscn/.gd.uid` do not exist in the repo.
- [ ] No `cloud_restore_prompt` references anywhere in `ClickerScreen.gd`.
- [ ] `_startup_cloud_restore_*` and `_pre_startup_*` fields/methods do not exist in
      `ClickerScreen.gd`.

### Account startup force-load (C7.3.1, unaffected)
- [ ] Fresh install, login existing account: account cloud save loads automatically at
      startup, no prompt of any kind appears.
- [ ] Stored session on relaunch: account cloud save loads automatically, no prompt.

### Guest → Register / Guest → Login (C7.1, unaffected)
- [ ] Start Guest, make progress, Register: guest save uploads to the new account's
      cloud (unchanged behavior).
- [ ] Start Guest, make progress, Login to an existing account: guest save is **not**
      uploaded; the existing account's cloud save force-loads instead.

### AccountWindow — Load from Cloud removed
- [ ] No "Load from Cloud" button anywhere in `AccountWindow`.
- [ ] No confirm/cancel dialog for a cloud download appears anywhere.
- [ ] `Save to Cloud` is present, tappable, and shows a status message on
      success/failure.

### AccountWindow — simplified account info
- [ ] Signed-in state shows only `Email: ...` and `Email verified`/`Email not verified`
      (plus `Save to Cloud` and `Logout`) — no separate big "Signed in" status label.
- [ ] No Verify Email button, no verification code input, no Confirm Code button
      anywhere in `AccountWindow`.
- [ ] Guest state shows the guest explanation text and a `Sign in / Register` button
      only.

### AccountWindow — button sizing/layout
- [ ] `Sign in / Register`, `Save to Cloud`, and `Logout` buttons are centered and
      texture-scale sized (not stretched across the window width).
- [ ] Layout is visually clean with no leftover empty space from removed rows.
- [ ] AccountWindow panel itself is still a fixed `540×525` size — not resized in this
      patch.

### SettingsWindow — proportional resize
- [ ] Settings panel is visibly larger than before (approximately `648×630`, up from
      `540×525`), same aspect ratio, no distortion of the background texture.
- [ ] Sound, Music, Language, Save, Account, Version are all visible in the normal
      layout without needing to scroll.
- [ ] Version sits close to the Account button/status area, not far below with a large
      empty gap.
- [ ] No dynamic resize — the panel keeps a fixed `custom_minimum_size` regardless of
      content/session state.

### Reset Progress / GuestMigrationPrompt (still absent)
- [ ] No `Reset Progress` UI anywhere.
- [ ] No `GuestMigrationPrompt` references anywhere at runtime.

### Web / Yandex
- [ ] No AuthGate / AccountWindow / Account button on Web/editor — this patch only
      touches Android-gated UI (`_is_backend_account_ui_supported()`).
- [ ] Web build behavior otherwise unaffected.

---

## Static / Tooling Checks

```bash
godot --headless --editor --quit
godot --headless --script res://scripts/tools/ValidateLocalizationDataFreshness.gd
godot --headless --script res://scripts/tools/ValidateLocalizationExport.gd
git status
git diff --stat
```

Localization changed in this patch (26 keys removed), so
`GenerateLocalizationData.gd` was re-run before the validators above.

### Results (this session)

- `godot --headless --editor --quit` — completed with no script/scene parse errors
  (filesystem scan, global class registration, and editor layout load all succeeded).
- `godot --headless --script res://scripts/tools/GenerateLocalizationData.gd` —
  generated 423 keys (down from 454).
- `godot --headless --script res://scripts/tools/ValidateLocalizationDataFreshness.gd` —
  PASS, 423/423 keys in sync, 0 errors/warnings.
- `godot --headless --script res://scripts/tools/ValidateLocalizationExport.gd` — PASS,
  423 CSV keys / 423 English / 419 Russian, 0 errors/warnings.

---

## Files Changed in C7.3.4

| File | Change |
|------|--------|
| `scenes/ui/CloudRestorePrompt.gd` | Deleted |
| `scenes/ui/CloudRestorePrompt.tscn` | Deleted |
| `scenes/ui/CloudRestorePrompt.gd.uid` | Deleted |
| `scenes/game/ClickerScreen.gd` | Removed `cloud_restore_prompt` node ref, all `_startup_cloud_restore_*`/`_pre_startup_*` state and methods, the manual-download branch (`_manual_backend_cloud_download_requested`, `_on_account_window_cloud_save_download_requested()`), and the corresponding `load_save` success/failure branches |
| `scenes/game/ClickerScreen.tscn` | Removed `CloudRestorePrompt` node + `ext_resource`; `load_steps` 25 → 24 |
| `scenes/ui/AccountWindow.gd` | Removed `cloud_save_download_requested` signal, Load-from-Cloud UI/handlers, Verify Email/code/Confirm Code UI/handlers, big status label; buttons switched to `ACTION_BUTTON_SIZE` (`Vector2(218,75)`) + `SIZE_SHRINK_CENTER` |
| `scenes/ui/SettingsWindow.tscn` | `PanelContainer` `540×525` → `648×630` (1.2× both axes), offsets recentered |
| `localization/game_text.csv` | Removed 26 stale keys (`cloud_restore.*` + Load-from-Cloud + Verify-Email keys) |
| `scripts/ui/LocalizationData.gd` | Regenerated (454 → 423 keys) |
| `AGENTS.md` | Marked C5.3/C5.3.2 rule sections as superseded/removed; updated C7.1/C7.3.1 cross-references; added "CloudRestorePrompt Cleanup & AccountWindow/Settings Polish Rules (C7.3.4)" section |
| `README.md` | New "C7.3.4 — CloudRestorePrompt Cleanup & Account/Settings UI Polish" changelog entry |
| `docs/validation/cloud_restore_cleanup_account_ui_polish.md` | New — this file |

---

## Known Limitations / Deferred

- `AccountWindow`'s own fixed panel size (`540×525`) was not changed in this patch —
  only `SettingsWindow` was resized. If the simplified `AccountWindow` content still
  feels visually sparse at that size, a follow-up patch could shrink it instead.
- `Platform.backend_request_email_verification()` / `backend_confirm_email_verification()`
  remain fully implemented but are currently unreachable from any UI. A future patch
  can re-expose them (e.g. inline in `AccountWindow` or a dedicated screen) without
  backend changes.
