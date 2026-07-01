# C7.3.3 — Account Window Regression & AuthGate Visual Polish Validation

## Overview

- Regression pass over the C7.3.2 Settings → AccountWindow split — no code changes were
  needed; the wiring, cloud status/busy routing, and ad/input safety guards already work
  as designed.
- AuthGate now shows the same image as the game boot splash
  (`assets/images/app/boot_splash.png`) behind a moderate dark overlay, instead of a
  near-opaque black background.
- The AuthGate login/register/reset panel stays fully opaque; `LineEdit` fields now use
  explicit opaque `normal`/`focus`/`read_only` styles so they stay readable over the
  splash image.
- No backend, cloud-save, payment, or gameplay logic changed in this patch.

---

## Manual Checklist

### Settings → AccountWindow regression (C7.3.2)
- [ ] Open Settings: shows Sound, Music, Language, Save, Account (Android), Version only.
- [ ] No account/cloud details are inline in Settings.
- [ ] Account button sits directly under Save.
- [ ] Tapping Account closes Settings and opens AccountWindow.
- [ ] Closing AccountWindow (X or overlay tap) returns to gameplay cleanly, no leftover
      input-blocking overlay.

### AccountWindow — Guest state
- [ ] Guest status text and guest explanation are shown.
- [ ] Sign in / Register button is visible.
- [ ] Save to Cloud / Load from Cloud buttons are hidden.

### AccountWindow — Account state
- [ ] Signed-in status, email, and verification status are shown.
- [ ] Verify Email button shows only while unverified.
- [ ] Entering a 6-digit code and tapping Confirm Code verifies the email.
- [ ] Logout returns AccountWindow to Guest state.
- [ ] Save to Cloud uploads and shows a success/failure status.
- [ ] Load from Cloud shows the confirmation box before applying anything, then applies
      on confirm.

### Account startup force-load (C7.3.1, unaffected)
- [ ] Stored account session / direct AuthGate login at boot still force-loads the
      account cloud save automatically.
- [ ] No `CloudRestorePrompt` appears for account startup/login.

### Guest → Register / Guest → Login (C7.1, unaffected)
- [ ] Guest → Register still uploads the guest save to the new account's cloud.
- [ ] Guest → Login still force-loads the account cloud save without uploading the guest
      save.

### AuthGate visual — background
- [ ] Fresh install: boot splash appears, then AuthGate appears with the same image
      visible behind a dark overlay (not solid black).
- [ ] Background image fills the screen with no gaps or stretch distortion on the
      720×1600 Android viewport.
- [ ] Background does not intercept taps — buttons and fields behind/above it still work.

### AuthGate visual — panel and inputs
- [ ] Login/register/reset panel looks fully solid — no part of the background shows
      through the panel area.
- [ ] Email/password/confirm/reset/code fields have a visibly solid, readable background
      in both normal and focused state.
- [ ] Placeholder text and entered text are readable in every field.
- [ ] Focus border is visible when a field is tapped/focused.
- [ ] Login, Register, Forgot Password, Reset Request, Reset Confirm, Continue as Guest
      buttons remain readable (white text, visible outline) regardless of the background.

### AuthGate flows (logic unchanged)
- [ ] Continue as Guest still emits `"guest"` and proceeds to gameplay.
- [ ] Login with valid credentials succeeds and emits `"account_login"`.
- [ ] Register + auto-login succeeds and emits `"account_register"`.
- [ ] Stored session check on relaunch emits `"account_session"` when valid.
- [ ] Forgot Password → Reset Request → Reset Confirm flow completes and returns to
      Login with a success message.
- [ ] All forms fit inside the fixed `340×520` panel on the 720×1600 viewport — no
      overflow, no dynamic resize.

### Reset Progress / GuestMigrationPrompt
- [ ] No `Reset Progress` UI anywhere.
- [ ] No `GuestMigrationPrompt` references anywhere at runtime.

### Web / Yandex
- [ ] No AuthGate on Web/editor startup — this patch only touches
      `scenes/auth/AuthGateScreen.gd`, which is Android-only.
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

No localization keys were added or changed in this patch, so
`GenerateLocalizationData.gd` did not need to be re-run.

---

## Files Changed in C7.3.3

| File | Change |
|------|--------|
| `scenes/auth/AuthGateScreen.gd` | Added boot-splash `TextureRect` background; lowered overlay alpha 0.88→0.35; added opaque `LineEdit` style helper `_apply_opaque_line_edit_style()`; documented the already-opaque panel style |
| `AGENTS.md` | New "AuthGate Visual Rules (C7.3.3)" section |
| `README.md` | New "C7.3.3 — Account Window Regression & AuthGate Visual Polish" changelog entry |
| `docs/validation/account_window_and_auth_visual_regression.md` | New — this file |

No changes were needed in `scenes/ui/AccountWindow.gd/.tscn`, `scenes/ui/SettingsWindow.gd/.tscn`,
or `scenes/game/ClickerScreen.gd/.tscn` — the C7.3.2 regression pass found no issues.

---

## Known Limitations / Deferred

- `AuthGateScreen.tscn` remains a thin script-only root Control; the background/overlay/
  panel are still built procedurally in `_build_ui()`, consistent with the existing
  pattern — not converted to scene nodes in this patch.
- `CloudRestorePrompt` remains unused in the repo (deferred cleanup from C7.3.1).
