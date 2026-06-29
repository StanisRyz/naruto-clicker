# C5.3 — Backend Cloud Restore Prompt Validation

## Static / Headless Checks

```bash
godot --headless --editor --quit
godot --headless --script res://scripts/tools/GenerateLocalizationData.gd
godot --headless --script res://scripts/tools/ValidateLocalizationDataFreshness.gd
godot --headless --script res://scripts/tools/ValidateLocalizationExport.gd
git status
git diff --stat
```

**Expected:** All commands exit 0. Localization has 445 keys. `cloud_restore.*` keys present in both EN and RU blocks of `LocalizationData.gd`.

**If Godot headless is not available in the current environment:** Run checks manually inside the Godot editor via Project → Tools → Run Script, or run validation as part of the next Android export build.

---

## Manual Android Validation Checklist

### Scenario A — Reinstall restore (cloud newer, no local)

1. Play for several minutes on Android account (cloud auto-upload will run).
2. Uninstall or clear app data.
3. Reinstall and launch.
4. Log in with the same account.
5. **Expected:** `CloudRestorePrompt` appears with "Cloud Progress Found" message.
6. Tap **Load Cloud Progress**.
7. **Expected:** Game state matches the saved progress. No error in logs.

### Scenario B — Decline restore

1. Same setup as Scenario A (cloud save exists, no local).
2. Tap **Keep Local**.
3. **Expected:** Prompt closes. New local progress starts fresh. No upload triggered immediately.
4. Restart app, log in again.
5. **Expected:** No second prompt (declined this session — but new session allows check again only after explicit re-login from overlay).

### Scenario C — Cloud older than local (no prompt)

1. Play on device with account. Let auto-upload run.
2. Keep playing (accumulate more progress locally without triggering upload, or force local to be newer).
3. Restart app.
4. **Expected:** No `CloudRestorePrompt` appears.

### Scenario D — Cloud and local same timestamp (no prompt)

1. Immediately after a successful cloud save, restart the app.
2. **Expected:** No prompt (timestamps equal → local is not older).

### Scenario E — Guest mode (no backend check)

1. Launch app. On AuthGate, tap "Continue as Guest".
2. **Expected:** No `CloudRestorePrompt` ever appears. No backend `load_save` call. Gameplay continues normally.

### Scenario F — Web/Yandex (unchanged)

1. Open game in browser.
2. **Expected:** Startup behavior unchanged. No backend cloud-restore check. Yandex SDK cloud-save still works if configured.

### Scenario G — Manual Settings Load from Cloud (unchanged)

1. Log in on Android account.
2. Open Settings → Cloud Save.
3. Tap **Load from Cloud**.
4. **Expected:** Existing confirmation step appears. After confirming, save is applied and UI refreshes. SettingsWindow shows success/error status.

### Scenario H — Startup check + manual download concurrent

1. On fresh install with cloud save, log in.
2. While startup check may be in-progress, immediately open Settings and tap Load from Cloud.
3. **Expected:** Manual download takes priority. Settings flow completes normally. No duplicate prompt or error.

### Scenario I — Auth overlay login while game is running

1. Start as guest.
2. Open Settings → Account → Sign In.
3. Log in with an account that has a cloud save.
4. **Expected:** After overlay closes, `CloudRestorePrompt` appears if cloud is newer than local (or no local exists).

### Scenario J — Invalid cloud save

1. Corrupt or incompatible save is stored in backend (e.g., missing `save_version`).
2. Launch app and log in.
3. **Expected:** No prompt appears. `push_warning` logged. Gameplay continues normally.

---

## Key Files Changed

| File | Change |
|------|--------|
| `localization/game_text.csv` | 9 new `cloud_restore.*` keys |
| `scripts/ui/LocalizationData.gd` | Regenerated (445 keys) |
| `scenes/ui/CloudRestorePrompt.gd` | New prompt dialog script |
| `scenes/ui/CloudRestorePrompt.tscn` | New prompt dialog scene |
| `scenes/game/ClickerScreen.tscn` | Added `CloudRestorePrompt` node |
| `scenes/game/ClickerScreen.gd` | Restore-check state, helpers, routing |
| `scenes/main/Main.gd` | Trigger restore check on overlay login |
| `README.md` | C5.3 section added |
| `AGENTS.md` | Cloud restore rules added |

---

## Regression Checklist

- [ ] Local save / load / reset / prestige unaffected
- [ ] Yandex SDK cloud save on Web unaffected
- [ ] Auto-upload (C5.2) still fires for account users after normal saves
- [ ] Manual Settings Load from Cloud still works with confirmation
- [ ] Guest mode: no backend calls, no prompt
- [ ] Fullscreen ad does not show while `CloudRestorePrompt` is visible
- [ ] Rewarded banner hidden while `CloudRestorePrompt` is visible
- [ ] No save payloads in logs
