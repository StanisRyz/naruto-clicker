# C7.3.2 — Separate Account Window from Settings Validation

## Overview

- `SettingsWindow` is compact again: Sound, Music, Language, Save, Account, Version.
- Detailed account/cloud UI (status, email, verification, Save/Load to Cloud, Logout)
  now lives in a new `AccountWindow`, opened via the Account button.
- Both windows keep the fixed `540×525` textured-panel style from C7.2.6/C7.2.7 — no
  dynamic resize, internal `ScrollContainer` for overflow.
- Backend/cloud/payment/shop/gameplay logic is unchanged — this patch only moves *where*
  the UI is displayed, not the request/response flow (C7.1, C7.3.1).
- Web/Yandex: no Account button, no AccountWindow (Android-only gate, same as before).

---

## Manual Checklist

### SettingsWindow content
- [ ] Open Settings. Only Sound, Music, Language, Save, Account (Android only), Version
      are visible.
- [ ] No account status, email, verification, or cloud save controls appear inline in
      Settings.
- [ ] Save button still works and shows the saved/save-failed status message.
- [ ] Settings panel is still a fixed `540×525` textured window — no resize.

### Account button → AccountWindow
- [ ] Tap Account under Save. Settings closes, AccountWindow opens.
- [ ] AccountWindow is a fixed-size textured window with a title, close button, and
      internal scroll body.
- [ ] Closing AccountWindow (X button or tapping the overlay) returns to gameplay, not
      back to Settings.

### AccountWindow — Guest state
- [ ] As Guest, AccountWindow shows Guest status text and the guest explanation label.
- [ ] Sign in / Register button is visible.
- [ ] Cloud Save section (Save to Cloud / Load from Cloud buttons) is hidden.
- [ ] Email, verification status, and Logout are hidden.

### AccountWindow — Account state
- [ ] Logged in, AccountWindow shows "Signed in" status, email, and verification status.
- [ ] Verify Email button shows only when the email is unverified; hidden once verified.
- [ ] Logout button is visible.
- [ ] Cloud Save section shows with Save to Cloud / Load from Cloud buttons enabled.

### Verify Email / Confirm Code / Logout
- [ ] Tap Verify Email: button/actions enter busy state, status message shows sending,
      then a 6-digit code input appears on success.
- [ ] Enter an invalid code (not 6 digits): inline validation error shown, no request sent.
- [ ] Enter a valid code and Confirm: busy state, then verified status updates.
- [ ] Tap Logout: busy state, then AccountWindow returns to Guest state on success (or
      shows the local-fallback message if the backend call fails but local auth is
      cleared).

### Save to Cloud / Load from Cloud
- [ ] Tap Save to Cloud: status shows "Uploading...", then success/failure.
- [ ] Tap Load from Cloud: confirmation box appears with a warning before any data
      changes (unchanged from before the split — the button tap alone never applies a
      cloud save).
- [ ] Confirm Load: status shows "Loading...", then gameplay state updates on success.
- [ ] Cancel: confirmation box closes, nothing changes.

### Guest → Register / Guest → Login (unaffected by this patch)
- [ ] Guest → Register still uploads the current guest save to the new account's cloud
      (C7.1) — status message shows in AccountWindow if it happens to be open, otherwise
      only a `push_warning` on failure (same rule as before, just the window changed).
- [ ] Guest → Login still force-loads the account cloud save without uploading the guest
      save (C7.1); AccountWindow reflects the result if open.

### Account startup force-load (C7.3.1, unaffected)
- [ ] Fresh login / stored session at startup still force-loads the account cloud save
      automatically; no `CloudRestorePrompt` appears. AccountWindow is not open at boot,
      so no status message is expected unless the player opens it afterward.

### Paid shop lock
- [ ] Guest: paid gem shop entry still opens the AuthGate overlay instead of
      `GemPurchaseDialog`.
- [ ] After login/register, paid shop unlocks (unaffected by which window shows account
      status).

### Ad / input safety
- [ ] Fullscreen interstitial ads do not appear while AccountWindow is open
      (`_is_safe_for_fullscreen_ad()` checks `account_window.visible`).
- [ ] Rewarded ad banner hides while AccountWindow is open
      (`_is_main_screen_clear_for_rewarded_banner()` checks `account_window.visible`).
- [ ] Tapping the game field while AccountWindow is open does not register an attack
      (`_on_attack_requested()` checks `account_window.visible`).

### Fixed-size window rule
- [ ] SettingsWindow and AccountWindow both stay `540×525` regardless of content —
      overflow scrolls inside `BodyScrollContainer`, no `offset_top`/`offset_bottom`
      runtime overrides.

### Web / Yandex
- [ ] Web build: no Account button in Settings, no AccountWindow instantiated content
      (window node exists but its account section is never created —
      `_is_backend_account_ui_supported()` returns false off Android).
- [ ] Yandex cloud-save (`YandexBridge`) unchanged.

### Reset Progress / GuestMigrationPrompt
- [ ] No `Reset Progress` UI anywhere in Settings or AccountWindow.
- [ ] No `GuestMigrationPrompt` references anywhere at runtime.

---

## Static / Tooling Checks

```bash
godot --headless --editor --quit
godot --headless --script res://scripts/tools/ValidateLocalizationDataFreshness.gd
godot --headless --script res://scripts/tools/ValidateLocalizationExport.gd
git status
git diff --stat
```

One new localization key was added (`settings.account_button`), so
`GenerateLocalizationData.gd` was re-run and `LocalizationData.gd` regenerated.

---

## Files Changed in C7.3.2

| File | Change |
|------|--------|
| `scenes/ui/AccountWindow.gd` | New — owns account status/email/verification/cloud-save UI, moved from SettingsWindow |
| `scenes/ui/AccountWindow.tscn` | New — fixed-size textured window, header + `BodyScrollContainer` |
| `scenes/ui/SettingsWindow.gd` | Removed account/cloud section code; added Account button + `account_window_requested` signal |
| `scenes/game/ClickerScreen.tscn` | Added `AccountWindow` node next to `SettingsWindow` |
| `scenes/game/ClickerScreen.gd` | Added `account_window` onready/wiring; renamed cloud handlers; added `_set_account_window_cloud_status()` / `_set_account_window_cloud_buttons_busy()`; updated ad/input-safety guards |
| `localization/game_text.csv` / `scripts/ui/LocalizationData.gd` | Added `settings.account_button` |
| `AGENTS.md` | New "AccountWindow / Settings Split Rules (C7.3.2)" section |
| `README.md` | New "C7.3.2 — Separate Account Window from Settings" changelog entry |

---

## Known Limitations / Deferred

- `AccountWindow` reuses the `SettingsWindow` background texture key
  (`"ui.window.settings.background"`) rather than a dedicated asset — no new art was
  commissioned for this patch.
- `CloudRestorePrompt` remains unused in the repo (deferred cleanup from C7.3.1).
