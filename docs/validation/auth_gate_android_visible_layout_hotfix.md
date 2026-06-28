# Validation: AuthGate Android Visible Layout Hotfix (C4.2)

## What was fixed

`AuthGateScreen` UI built without errors but was not visible on Android.

Two root causes:
1. `PanelContainer.custom_minimum_size = Vector2(340, 0)` — the panel had zero
   minimum height inside `ScrollContainer`, collapsing to zero size.
2. `AuthGateScreen` did not set its own anchors in `_ready()`, so it depended on
   the parent (`Main`) to size it — if `Main` added it without a full-rect preset,
   the root Control had zero size.

## Files changed

- `scenes/auth/AuthGateScreen.gd`
- `scenes/main/Main.gd`

## Validation commands

```bash
# Static parse check
godot --headless --editor --quit

# Localization freshness (no CSV changes in this patch — should pass unchanged)
godot --headless --script res://scripts/tools/ValidateLocalizationDataFreshness.gd
godot --headless --script res://scripts/tools/ValidateLocalizationExport.gd

git status
git diff --stat
```

> If Godot export templates are not installed, skip the headless commands and
> rely on manual device testing.

## Expected logcat output (Android)

```
AuthGateScreen: building UI
AuthGateScreen: panel min size=(340, 520)
AuthGateScreen: UI ready
AuthGateScreen: root size=...    # non-zero on next frame; may print 0 if logged before layout
AuthGateScreen: state=1          # LOGIN (no session) or 0 (CHECKING)
```

## Must NOT appear in logcat

```
Invalid assignment of property or key 'keyboard_type'
Nil.visible
```

## Manual Android validation checklist

### Fresh install — AuthGate visible

- [ ] Install APK on Android device.
- [ ] Launch app.
- [ ] Splash screen finishes.
- [ ] AuthGate panel is visible (dark overlay + title + login form).
- [ ] Screen is **not** black.
- [ ] Login email field, password field, and Login button are visible.
- [ ] "Continue as Guest" button is visible.

### Guest mode

- [ ] Tap "Continue as Guest".
- [ ] AuthGate closes, ClickerScreen starts.
- [ ] No crash.

### Android — no session

- [ ] Uninstall and reinstall (or clear app data).
- [ ] AuthGate shows login form directly (no "Checking…" state).

### Android — invalid/stuck session

- [ ] If a previous invalid token is stored, `backend_get_me()` fails or does not
     respond.
- [ ] "Checking account…" state appears briefly.
- [ ] Within 6 seconds, login form appears with "checking failed" status message.
- [ ] Player is never stuck on the checking screen.

### Login form

- [ ] Email and password fields accept input.
- [ ] Submitting empty fields shows validation errors.
- [ ] "Forgot password" link switches to reset-request form.
- [ ] "Register" link switches to register form.

### Register form

- [ ] Email, password, and confirm-password fields are visible.
- [ ] Mismatched passwords shows error.

### Password reset request form

- [ ] Email field is visible and pre-filled if navigated from login.

### Password reset confirm form

- [ ] Email, code (6-digit), new password, confirm fields are visible.

### Web / Editor

- [ ] Editor run: ClickerScreen appears immediately, no AuthGate.
- [ ] Web export: ClickerScreen appears immediately, no AuthGate.

### SaveManager

- [ ] No backend cloud-save calls go through SaveManager.
- [ ] Local save and Yandex cloud save (Web) are unchanged.
