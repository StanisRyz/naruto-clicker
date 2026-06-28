# Validation: AuthGate Android Black Screen Hotfix (C4.1)

## What was fixed

`AuthGateScreen.gd` assigned `.keyboard_type` directly on `LineEdit` nodes.
The property does not exist on the Godot 4.5.1 Android `LineEdit` object.
The engine threw a script error at UI-build time, leaving the screen black.

Secondary `Nil.visible` errors cascaded because `_set_state()` wrote to
partially-built boxes without null guards.

## Files changed

- `scenes/auth/AuthGateScreen.gd`

## Validation commands

```bash
# Static parse check (editor headless)
godot --headless --editor --quit

# Localization freshness (no CSV changes in this patch — should pass unchanged)
godot --headless --script res://scripts/tools/ValidateLocalizationDataFreshness.gd
godot --headless --script res://scripts/tools/ValidateLocalizationExport.gd

# Git diff
git status
git diff --stat
```

> Godot headless commands require the export templates to be installed.
> If templates are absent, skip the headless checks and rely on manual device testing.

## Manual Android validation checklist

### Fresh install — no crash

- [ ] Install APK on Android device.
- [ ] Launch app.
- [ ] Splash screen finishes.
- [ ] AuthGate panel appears (dark overlay + form).
- [ ] Screen is **not** black.
- [ ] Logcat shows `AuthGateScreen: building UI` then `AuthGateScreen: UI ready`.
- [ ] Logcat shows **no** `Invalid assignment of property or key 'keyboard_type'` error.

### Guest mode

- [ ] Tap "Continue as Guest".
- [ ] Gameplay starts (ClickerScreen appears).
- [ ] No crash.

### Login form

- [ ] Login email and password fields are visible and accept input.
- [ ] Email field shows email-type keyboard if the device supports it (optional; no crash if not).
- [ ] Tapping "Login" with empty fields shows a validation message.

### Register form

- [ ] Tap "Register" link.
- [ ] Register form (email, password, confirm) is visible and usable.
- [ ] Tapping "Register" with mismatched passwords shows mismatch error.

### Password reset request

- [ ] Tap "Forgot password".
- [ ] Reset request form is visible.

### Password reset confirm

- [ ] After a reset code is sent, reset confirm form is visible (email pre-filled, code input, new password fields).

### Web / Editor

- [ ] Editor run: ClickerScreen appears immediately, no AuthGate shown.
- [ ] Web export: ClickerScreen appears immediately, no AuthGate shown.

### SaveManager

- [ ] No backend cloud-save calls are made through SaveManager.
- [ ] Local save and Yandex cloud save (Web) are unchanged.
