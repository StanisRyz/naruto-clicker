# C7.2.2 — Account / Cloud Entry Promotion in Settings Validation

## Overview

- `SettingsWindow` (Android/RuStore only) now shows an "Account / Cloud" section
  header instead of a plain "Account" header — the visible replacement entry point
  for the Reset Progress button removed in C7.2.1.
- Version label moved to the bottom of the panel (after Account/Cloud), matching
  the intended visual order: Sound → Music → Language → Save Now → Account/Cloud →
  Version.
- Guest mode explanation text expanded to explicitly mention cloud save, paid gem
  purchases, and that rewarded ads remain available.
- No signals, cloud-save logic, or Guest→Login/Register flows were touched — this
  is a text/layout promotion only.

---

## What Changed

- `scenes/ui/SettingsWindow.gd`
  - `_create_account_section()`: title label font size 16 → 18 (more prominent header).
  - `_refresh_account_static_labels()` / `_refresh_account_section()`: title now
    uses `settings.account_cloud.title` ("Account / Cloud") instead of
    `settings.account.title` ("Account").
  - `_refresh_account_section()`: guest explanation label now uses
    `settings.account.guest_explanation` instead of `settings.account.guest_warning`.
  - `_ready()`: after creating the account section, `version_label` is moved to the
    end of the settings `VBoxContainer` so it renders below Account/Cloud.
- `localization/game_text.csv`
  - Renamed `settings.account.title` → `settings.account_cloud.title`
    ("Account" → "Account / Cloud").
  - Renamed `settings.account.guest_warning` → `settings.account.guest_explanation`
    with new text: "Sign in or register to save progress in cloud and buy gems.
    Rewarded ads remain available in Guest mode." / "Войдите или
    зарегистрируйтесь, чтобы сохранять прогресс в облаке и покупать гемы. Реклама
    остаётся доступной."
- `scripts/ui/LocalizationData.gd` regenerated from CSV (455 keys, same count —
  this was a rename, not an addition).

## What Did NOT Change

- Signals: `sound_toggled`, `music_toggled`, `save_requested`,
  `language_manually_changed`, `account_auth_requested`,
  `cloud_save_upload_requested`, `cloud_save_download_requested` — all unchanged,
  same names, same emit sites.
- `ClickerScreen.gd` connections to `SettingsWindow` signals — unchanged.
- Cloud save/load busy-state handling (`set_cloud_save_buttons_busy`,
  `set_cloud_save_status`) — unchanged.
- Cloud load confirmation flow (`_cloud_confirm_box`) — unchanged.
- `_is_backend_account_ui_supported()` — still `OS.has_feature("android")`; Web/editor
  still hide the entire Account/Cloud section.
- Reset Progress — remains removed (C7.2.1); not reintroduced.
- Backend Cloud Functions, backend API paths, gameplay balance, ads/payments — untouched.

---

## Checklist

- [x] `SettingsWindow` has no Reset Progress button/section (still true after C7.2.1).
- [x] `SettingsWindow` shows an "Account / Cloud" header on Android (not just "Account").
- [x] Guest mode explanation mentions: Guest mode status, cloud save requires account,
      paid gem purchases require account, rewarded ads remain available.
- [x] Account (signed-in) state still shows: signed-in status, email, email
      verification status, Verify Email button (if unverified), Save to Cloud,
      Load from Cloud, Logout.
- [x] Cloud Save/Load buttons remain nested inside the Account/Cloud section
      (via `_create_cloud_section(account_vbox)` — unchanged call site).
- [x] `sound_toggled`, `music_toggled`, `save_requested`, `language_manually_changed`,
      `account_auth_requested`, `cloud_save_upload_requested`,
      `cloud_save_download_requested` signals all present, unchanged names.
- [x] No `reset_requested`/`reset_confirmed` signal reintroduced.
- [x] Web/editor: `_is_backend_account_ui_supported()` still returns `false`, so the
      whole Account/Cloud block (and thus the new header/explanation) stays hidden.

---

## Manual Checklist

### Android Guest
- [ ] Open Settings on Android Guest.
- [ ] Reset Progress is not visible (unchanged from C7.2.1).
- [ ] "Account / Cloud" header is visible.
- [ ] Guest explanation text is visible and mentions cloud save + paid gems + rewarded ads.
- [ ] "Sign in / Register" button still opens the AuthGate overlay.
- [ ] Rewarded ads still work in Guest mode (unaffected by text change).

### Android Account
- [ ] Open Settings on Android Account (signed in).
- [ ] "Account / Cloud" header is visible.
- [ ] Email and verification status visible.
- [ ] Save to Cloud still works (status updates, busy-state disables buttons).
- [ ] Load from Cloud still shows the confirm/cancel box before downloading.
- [ ] Logout still works and returns to Guest-mode display.

### Web / Yandex
- [ ] Web build: Account/Cloud section is not shown (same as before C7.2.2).
- [ ] Yandex cloud-save (via YandexBridge) behavior unchanged.
- [ ] No AuthGate on Web startup.

---

## Static / Tooling Checks

```bash
godot --headless --editor --quit
godot --headless --script res://scripts/tools/GenerateLocalizationData.gd
godot --headless --script res://scripts/tools/ValidateLocalizationDataFreshness.gd
godot --headless --script res://scripts/tools/ValidateLocalizationExport.gd
git status
git diff --stat
```

**Results (run during C7.2.2 implementation):**
- `godot --headless --editor --quit` — no errors.
- `GenerateLocalizationData.gd` — generated 455 keys (renamed, not added).
- `ValidateLocalizationDataFreshness.gd` — PASS (455/455 keys, 0 errors, 0 warnings).
- `ValidateLocalizationExport.gd` — PASS (455 EN keys, 451 RU values, 0 errors).

---

## Files Changed in C7.2.2

| File | Change |
|------|--------|
| `scenes/ui/SettingsWindow.gd` | Account/Cloud header promotion, guest explanation text key, version label reordered to bottom |
| `localization/game_text.csv` | Renamed `settings.account.title` → `settings.account_cloud.title`; renamed and reworded `settings.account.guest_warning` → `settings.account.guest_explanation` |
| `scripts/ui/LocalizationData.gd` | Regenerated from CSV (455 keys) |
| `docs/validation/account_settings_validation.md` | Added forward-pointer note about renamed keys and C7.2.1 reset removal |
| `docs/validation/account_cloud_settings_promotion.md` | New validation doc (this file) |
| `README.md` | Added C7.2.2 section |
| `AGENTS.md` | Added Account/Cloud promotion rules |

---

## Known Limitations

- This patch is UI text/order only; it does not add a standalone Account screen or
  collapsible sections, per scope.
