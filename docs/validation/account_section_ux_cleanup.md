# C7.2.3 — Account Section UX Cleanup Validation

## Overview

- Fixes a stale-message bug: `confirm_email_verification` success and both
  `logout` success/fallback handlers used to call the full
  `_refresh_account_section()` *after* showing the result message, which
  immediately cleared `_account_action_label` back to `""`. They now call the
  new state-only `_refresh_account_section_state()` instead, so the message
  persists until the next explicit action or window reopen.
- Adds account-action busy-state: Verify Email, Confirm Code, and Logout buttons
  (plus Sign in/Register defensively) disable while a backend request is in
  flight and always re-enable on success or failure — no stuck buttons after an
  error.
- Guest explanation text reworded to state plainly that Guest progress is
  local-only, and that signing in unlocks cloud save and gem purchases while
  rewarded ads remain available either way.
- Account status messages (`_account_action_label`) and Cloud Save status
  (`_cloud_status_label` via `set_cloud_save_status()`) remain fully separate
  label instances — verified no code path writes to the wrong one.

---

## What Changed

- `scenes/ui/SettingsWindow.gd`
  - New `var _account_action_busy: bool`.
  - New `_set_account_actions_busy(is_busy: bool)` — disables/enables Verify
    Email, Confirm Code, Logout, and Sign in/Register buttons.
  - New `_clear_account_verification_input()` — hides the code box and clears
    the code `LineEdit` text (used on logout, not on every refresh).
  - `_refresh_account_section()` split: it now clears the code input/action
    label, then delegates to the new `_refresh_account_section_state()`, which
    only recomputes visibility/text from `Platform.backend_*` and never touches
    the action message or code input. Operation success/failure handlers use the
    state-only variant so their status message isn't immediately erased.
  - `_on_account_verify_email_pressed()` / `_on_account_confirm_code_pressed()` /
    `_on_account_logout_pressed()`: guard against re-entrancy while
    `_account_action_busy`, set busy before the backend call, show a short
    in-progress message (`verification_sending` / `verification_confirming` /
    `logout_in_progress`).
  - `_on_account_backend_op_succeeded()` / `_on_account_backend_op_failed()`:
    every branch now calls `_set_account_actions_busy(false)` first.
  - `_on_account_backend_auth_changed()`: also calls
    `_set_account_actions_busy(false)` defensively, in case auth state changes
    from outside Settings (e.g. Guest → Login/Register overlay flow) while a
    Settings-initiated request was in flight.
- `localization/game_text.csv` / `scripts/ui/LocalizationData.gd`
  - `settings.account.guest_explanation` reworded (EN: explicit "local-only";
    RU: `Гостевой режим. Войдите или зарегистрируйтесь, чтобы сохранять
    прогресс в облаке и покупать гемы. Реклама остаётся доступной.`).
  - 3 new keys: `settings.account.verification_sending`,
    `settings.account.verification_confirming`,
    `settings.account.logout_in_progress` (458 keys total, was 455).

## What Did NOT Change

- Signals: `sound_toggled`, `music_toggled`, `save_requested`,
  `language_manually_changed`, `account_auth_requested`,
  `cloud_save_upload_requested`, `cloud_save_download_requested` — unchanged.
- `SaveManager` backend save/load logic, backend Cloud Function code, backend API
  paths — untouched.
- Guest → Login / Guest → Register flow (C7.1), `CloudRestorePrompt` logic —
  untouched.
- Cloud Save/Load buttons: still visible only with a session, `Load from Cloud`
  still requires confirm/cancel, `set_cloud_save_buttons_busy()` unchanged.
- Reset Progress — remains removed (C7.2.1); not reintroduced.
- Web/Yandex behavior — `_is_backend_account_ui_supported()` still gates the
  whole Account/Cloud block on `OS.has_feature("android")`.

---

## Checklist

- [x] Account messages (`_show_account_action` → `_account_action_label`) and
      Cloud messages (`set_cloud_save_status` → `_cloud_status_label`) use
      distinct label instances; no code path writes account text into
      `_cloud_status_label` or vice versa.
- [x] `_set_account_actions_busy(true)` called before every backend account
      call (`request_email_verification`, `confirm_email_verification`,
      `logout`); `_set_account_actions_busy(false)` called in every
      corresponding success/failure branch, plus defensively in
      `_on_account_backend_auth_changed`.
- [x] Verify Email / Confirm Code / Logout / Sign in-Register buttons all
      guarded against re-entrancy via `_account_action_busy` early-return.
- [x] `confirm_email_verification` success no longer wipes its own success
      message (was a pre-existing bug: full refresh ran after showing the
      message).
- [x] Logout success/fallback clears the verification code input
      (`_clear_account_verification_input()`) without wiping the just-shown
      message.
- [x] Guest explanation mentions: local-only progress, cloud save requires
      account, gem purchases require account, rewarded ads remain available.
- [x] Reset Progress remains absent (unchanged from C7.2.1/C7.2.2).
- [x] `_is_backend_account_ui_supported()` unchanged — Web/editor still hide
      the Account/Cloud section entirely.

---

## Manual Checklist

### Android Guest
- [ ] Open Settings on Android Guest.
- [ ] "Account / Cloud" header visible; guest explanation readable and wraps
      correctly on a vertical mobile viewport.
- [ ] Save to Cloud / Load from Cloud buttons are **not** visible.
- [ ] "Sign in / Register" opens the AuthGate overlay.

### Android Account — email verification
- [ ] Sign in with an unverified account. "Verify email" button visible.
- [ ] Press "Verify email": button (and Confirm/Logout) disable immediately;
      short "Sending verification email..." message shown.
- [ ] On success: code box appears, buttons re-enable, "Verification code sent"
      message shown and persists (not cleared).
- [ ] Enter the 6-digit code, press "Confirm code": buttons disable, "Confirming
      code..." message shown.
- [ ] On success: "Email verified" message shown and **persists** (this was the
      bug being fixed — confirm the message does not disappear immediately).
- [ ] Verification status label updates to "Email verified"; Verify Email
      button disappears.

### Android Account — logout
- [ ] Press "Logout": buttons disable, "Logging out..." shown.
- [ ] On success: view returns to Guest state, "Logged out" message shown and
      persists, verification code input is cleared.
- [ ] Simulate a logout network failure (e.g. airplane mode): "Local session
      cleared" fallback message shown and persists; buttons re-enabled; no
      stuck disabled buttons.

### Cloud Save / Load unaffected
- [ ] Save to Cloud still works; status shown in `_cloud_status_label` only.
- [ ] Load from Cloud still shows the confirm/cancel box before downloading.
- [ ] Triggering an account action (e.g. Verify Email) does not alter the
      Cloud Save status text, and vice versa.

### Web / Yandex
- [ ] Web build: Account/Cloud section not shown (unchanged).
- [ ] Yandex cloud-save via YandexBridge unchanged.

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

**Results (run during C7.2.3 implementation):**
- `godot --headless --editor --quit` — no errors.
- `GenerateLocalizationData.gd` — generated 458 keys (455 → 458, 3 new busy-state keys).
- `ValidateLocalizationDataFreshness.gd` — PASS (458/458 keys, 0 errors, 0 warnings).
- `ValidateLocalizationExport.gd` — PASS (458 EN keys, 454 RU values, 0 errors).

---

## Files Changed in C7.2.3

| File | Change |
|------|--------|
| `scenes/ui/SettingsWindow.gd` | Busy-state helper, verification-input clear helper, split refresh into full/state-only variants, fixed stale-message bug on verification success and logout |
| `localization/game_text.csv` | Reworded `settings.account.guest_explanation`; added 3 busy-state keys |
| `scripts/ui/LocalizationData.gd` | Regenerated from CSV (458 keys) |
| `docs/validation/account_section_ux_cleanup.md` | New validation doc (this file) |
| `README.md` | Added C7.2.3 section |
| `AGENTS.md` | Added Account/Cloud UX cleanup rules |

---

## Known Limitations

- No ScrollContainer added; the existing panel sizing (`offset_top`/`offset_bottom`
  set in `_create_account_section()`) already accommodates the Account/Cloud
  section and was left unchanged, per the "keep this patch small" requirement.
