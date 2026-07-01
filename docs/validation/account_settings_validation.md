# Account Settings Panel — Manual Validation Checklist

C4 patch: account block in SettingsWindow, AuthGate overlay from settings, logout,
email verification. Backend cloud-save is NOT wired in this patch.

> **C7.2.2 note:** the section title is now "Account / Cloud"
> (`settings.account_cloud.title`, was `settings.account.title`), and the guest
> warning text was replaced by a longer explanation
> (`settings.account.guest_explanation`, was `settings.account.guest_warning`)
> covering cloud save, paid purchases, and rewarded ads. Reset Progress was removed
> from Settings entirely in C7.2.1 — ignore any "reset" references below. See
> `docs/validation/account_cloud_settings_promotion.md` for the current checklist.

## Validation commands

```bash
# Regenerate LocalizationData.gd (editor plugin does this on save; also run manually)
godot --headless --script res://scripts/tools/GenerateLocalizationData.gd

# Validate freshness
godot --headless --script res://scripts/tools/ValidateLocalizationDataFreshness.gd

# Validate export
godot --headless --script res://scripts/tools/ValidateLocalizationExport.gd

# Check working tree
git status
git diff --stat
```

> **Note:** `ValidateLocalizationDataFreshness.gd` and `ValidateLocalizationExport.gd`
> require a Godot headless binary. The localization sync plugin auto-regenerates
> `LocalizationData.gd` when the CSV is saved in the editor; key count was updated
> from 398 → 417 automatically.

## Android — Guest mode

- [ ] Start the app cold on Android (no existing session).
- [ ] AuthGate appears. Press "Continue as Guest".
- [ ] Gameplay loads normally.
- [ ] Open Settings.
- [ ] Account section is visible.
- [ ] Status label shows "Guest mode".
- [ ] Guest warning text is visible ("progress stored only on this device").
- [ ] "Sign in / Register" button is visible.
- [ ] Email label is hidden.
- [ ] Email verification label is hidden.
- [ ] Logout button is hidden.
- [ ] No backend HTTP request is sent.

## Android — Sign in / Register from settings

- [ ] In guest mode, open Settings and press "Sign in / Register".
- [ ] Settings window closes / AuthGate overlay appears above gameplay.
- [ ] Existing gameplay (enemy, gold, timers) continues — it is NOT reset.
- [ ] ClickerScreen is NOT re-instantiated (no save reload, no startup sequence).
- [ ] Log in with a valid account.
- [ ] AuthGate overlay closes.
- [ ] Gameplay continues from where it was.
- [ ] Reopen Settings. Account section now shows "Signed in" status and the email.
- [ ] No SaveManager backend load/save is triggered.

## Android — Guest button in overlay closes without restart

- [ ] Open AuthGate overlay from Settings. Press "Continue as Guest".
- [ ] Overlay closes.
- [ ] Gameplay continues uninterrupted.
- [ ] Settings account section still shows guest state.

## Android — Logout

- [ ] While signed in, open Settings.
- [ ] Press "Logout".
- [ ] Account section transitions to guest state.
- [ ] Status shows "Guest mode". Warning visible. "Sign in / Register" button visible.
- [ ] Local gameplay save is intact (gold, level, etc. unchanged).
- [ ] No gameplay restart occurs.
- [ ] No backend save deletion occurs.

## Android — Logout failure fallback

- [ ] Simulate a logout failure (e.g., force airplane mode after pressing Logout).
- [ ] Settings shows "Local session cleared" message.
- [ ] Account section transitions to guest state (local auth was cleared).
- [ ] Local save remains intact.

## Android — Email verification request

- [ ] While signed in with an unverified email, open Settings.
- [ ] "Verify email" button is visible.
- [ ] Press "Verify email".
- [ ] Status message shows "Verification code sent".
- [ ] Code input field appears.
- [ ] "Confirm code" button appears.
- [ ] Check email inbox for a 6-digit verification code.

## Android — Email verification confirm (valid code)

- [ ] Enter the 6-digit code received by email.
- [ ] Press "Confirm code".
- [ ] Account section refreshes.
- [ ] "Email verified" is shown.
- [ ] Code input field and "Confirm code" button disappear.
- [ ] "Verify email" button is hidden (email is now verified).

## Android — Email verification confirm (invalid code)

- [ ] Enter a code that is not 6 digits, or non-numeric.
- [ ] Press "Confirm code".
- [ ] Validation error shown ("Enter a 6-digit code").
- [ ] No network request is made.
- [ ] Enter a wrong 6-digit numeric code and press "Confirm code".
- [ ] Backend error is shown (e.g., "Backend error: invalid_code").

## Web / editor — no backend operations

- [ ] Open Settings on Web export or in the editor.
- [ ] No account section is visible (hidden entirely).
- [ ] No backend HTTP request is sent on settings open.
- [ ] All existing settings features (sound, music, language, save, reset) work as before.
- [ ] AuthGate does not appear automatically.

## No-cloud-save assertions (all platforms)

- [ ] Confirm that `SaveManager` never calls `Platform.backend_save_save()` or
  `Platform.backend_load_save()` in this patch. Check git diff for `SaveManager.gd`.
- [ ] Confirm that logging in from settings does NOT trigger a backend load or
  merge/overwrite the local save.
- [ ] Confirm that logging out does NOT delete the local save file.

## Security / logging

- [ ] Confirm no password appears in Godot output.
- [ ] Confirm no session token appears in Godot output.
- [ ] Confirm no verification code appears in Godot output.
- [ ] Confirm `user://backend_auth.json` is not committed to git.
