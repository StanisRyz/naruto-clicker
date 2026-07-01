# C5.4 Guest → Account Migration Prompt — Validation Checklist

> **OBSOLETE (historical only).** This C5.4 mid-session `GuestMigrationPrompt`
> flow was replaced by the C7.1 Account Save Authority rules (Guest → Register
> auto-uploads; Guest → Login force-loads the account cloud save; no prompt).
> The runtime flow was removed in C7.1.1, and `GuestMigrationPrompt.gd`/`.tscn`
> and the `guest_migration.*` localization keys were deleted in C7.2.5 — see
> `docs/validation/obsolete_reset_and_guest_migration_cleanup.md`. Do not use
> this checklist to validate current behavior.

## Overview

When a player starts a gameplay session as Guest and later logs in or registers an account from Settings / AuthGate overlay, the game offers to upload current local progress to the backend cloud.

## Files Changed

| File | Change |
|------|--------|
| `scenes/ui/GuestMigrationPrompt.gd` | New — signal-only dialog; no SaveManager/Platform calls |
| `scenes/ui/GuestMigrationPrompt.tscn` | New — Control dialog matching CloudRestorePrompt style |
| `scenes/game/ClickerScreen.tscn` | Added GuestMigrationPrompt instance node |
| `scenes/game/ClickerScreen.gd` | Guest-session tracking; prompt eligibility; upload handlers |
| `scenes/main/Main.gd` | Pass startup auth mode; route overlay login to ClickerScreen |
| `localization/game_text.csv` | 6 new `guest_migration.*` keys |
| `scripts/ui/LocalizationData.gd` | Regenerated (451 keys) |

## Validation Commands

```bash
godot --headless --script res://scripts/tools/GenerateLocalizationData.gd
# Expected: generated 451 keys

godot --headless --script res://scripts/tools/ValidateLocalizationDataFreshness.gd
# Expected: RESULT: PASS — LocalizationData.gd is fresh.

godot --headless --script res://scripts/tools/ValidateLocalizationExport.gd
# Expected: PASS

git status
git diff --stat
```

## Checklist

### Scenario 1 — Guest session → login from Settings → Save to Cloud

- [ ] Start as Guest on Android
- [ ] Make local progress (advance levels, buy upgrades)
- [ ] Open Settings → press "Sign in" → AuthGate overlay appears
- [ ] Log in with valid account
- [ ] GuestMigrationPrompt appears: "Save Guest Progress" title, correct message text
- [ ] Press "Save to Cloud"
- [ ] Prompt hides; gameplay continues without reload
- [ ] SettingsWindow shows "Guest progress saved to cloud" status (if visible)
- [ ] Backend save_save operation completes successfully
- [ ] Future auto-uploads continue normally (account session active)

### Scenario 2 — Guest session → login → Not Now

- [ ] Same steps as Scenario 1 up to GuestMigrationPrompt appearing
- [ ] Press "Not Now"
- [ ] Prompt hides; gameplay continues unchanged
- [ ] No backend upload triggered from Not Now handler
- [ ] Future saves auto-upload normally (account session is now active)

### Scenario 3 — Direct account startup → no prompt

- [ ] Start as Account (existing session or login at startup AuthGate)
- [ ] Play normally
- [ ] GuestMigrationPrompt never appears

### Scenario 4 — Guest session, no account login → no prompt

- [ ] Start as Guest
- [ ] Play without logging in
- [ ] GuestMigrationPrompt never appears

### Scenario 5 — Web / Yandex → no prompt

- [ ] Run on Web/Yandex (or editor without android feature)
- [ ] GuestMigrationPrompt never appears regardless of auth state

### Scenario 6 — CloudRestorePrompt collision prevention

- [ ] Start as Guest; backend already has cloud save from a previous account session
- [ ] Log in from Settings overlay
- [ ] Cloud restore check runs; if cloud save is newer than local:
  - CloudRestorePrompt appears first
  - GuestMigrationPrompt does NOT appear simultaneously
- [ ] After user dismisses CloudRestorePrompt, GuestMigrationPrompt also does not appear (prompt pending flag cleared)

### Scenario 7 — Restore check finds no cloud save → migration prompt follows

- [ ] Start as Guest; account has no cloud save yet
- [ ] Log in from Settings overlay
- [ ] Cloud restore check finds no cloud save → no restore prompt
- [ ] GuestMigrationPrompt appears immediately after (if `SaveManager.has_save()` is true)

### Scenario 8 — Upload failure

- [ ] Trigger Save to Cloud from GuestMigrationPrompt
- [ ] Simulate backend failure (network off or invalid session)
- [ ] SettingsWindow shows "Failed to save guest progress" status (if visible) or push_warning in logs
- [ ] Gameplay continues; local save intact; no reload

### Scenario 9 — No local save → no prompt

- [ ] Fresh install, start as Guest
- [ ] Log in from overlay before any progress saved
- [ ] If `SaveManager.has_save()` returns false, GuestMigrationPrompt does not appear

## Key Invariants

- GuestMigrationPrompt emits signals only; never calls SaveManager or Platform
- ClickerScreen owns all save/upload operations
- CloudRestorePrompt has priority over GuestMigrationPrompt; both never appear simultaneously
- C5.3.1 auto-upload suspension for startup restore check remains intact
- Guest-started flag (`_gameplay_started_as_guest`) is set from Main.gd via `set_startup_auth_mode()` before ClickerScreen._ready() loads the save
- After `_on_guest_migration_save_confirmed` succeeds, `_gameplay_started_as_guest` is cleared to prevent re-prompt
