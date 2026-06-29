# C5.3.1 — Startup Upload Suspension Validation

## Static / Headless Checks

```bash
godot --headless --editor --quit
git status
git diff --stat
```

**Expected:** Editor opens without parse errors. `SaveManager.gd` and `ClickerScreen.gd` show changes.

---

## Manual Android Validation Checklist

### Scenario 1 — Reinstall: cloud save is not overwritten before prompt

1. Play on Android account. Let auto-upload run (45 s timer fires, or force a save).
2. Note the cloud save timestamp in logs.
3. Uninstall the app (or clear app data).
4. Reinstall and launch.
5. Log in with the same account.
6. **Expected:** `CloudRestorePrompt` appears. The cloud save is NOT overwritten by a blank local save before the prompt shows.
7. Tap **Load Cloud Progress**.
8. **Expected:** Game state matches previous progress. Auto-upload resumes normally afterward.

### Scenario 2 — Reinstall: player chooses Keep Local, auto-upload resumes

1. Same setup as Scenario 1 (cloud save exists, blank local after reinstall).
2. When prompt appears, tap **Keep Local**.
3. **Expected:** Prompt closes. Gameplay continues from blank state.
4. Play for a bit and trigger an auto-save (enter a new level, etc.).
5. **Expected:** Backend auto-upload fires within 45 s. No infinite suspension.

### Scenario 3 — Normal launch (cloud same age or older): upload not blocked

1. Play on Android account without reinstalling (local save is current).
2. Restart the app.
3. **Expected:** No prompt. Backend auto-upload fires normally after the first save event.
4. Confirm in logs that `queue_backend_cloud_save` is NOT returning early after startup.

### Scenario 4 — Guest mode: no suspension, no check

1. Launch app. On AuthGate, tap "Continue as Guest".
2. **Expected:** No restore check, no prompt. `_backend_cloud_auto_upload_suspended` never becomes true (no session at startup).
3. Auto-upload is also a no-op for guests (no session guard in `queue_backend_cloud_save`).

### Scenario 5 — Web/Yandex: unaffected

1. Open game in browser.
2. **Expected:** `_should_suspend_backend_auto_upload_for_startup_restore()` returns false (not Android). No suspension set. Yandex SDK cloud-save unaffected.

### Scenario 6 — Manual Save to Cloud while suspended (edge case)

1. Launch app on Android account.
2. Before the startup check response returns (very narrow window), open Settings and tap **Save to Cloud**.
3. **Expected:** Manual save fires immediately via `upload_current_save_to_backend_cloud_now()`, which has no suspension guard. Settings shows success.

### Scenario 7 — Manual Load from Cloud after restore prompt declined

1. Launch app on Android account with a newer cloud save.
2. Restore prompt appears. Tap **Keep Local** (suspension clears).
3. Open Settings → Cloud Save → tap **Load from Cloud** (manual flow).
4. **Expected:** Manual download works normally. No suspension is active. Save is applied after manual confirmation.

### Scenario 8 — Backend check fails at startup

1. Simulate a backend error on startup (disable network, bad token, etc.).
2. **Expected:** `push_warning` is logged. Suspension is cleared. Auto-upload resumes on the next save event.

---

## Key Files Changed

| File | Change |
|------|--------|
| `autoload/SaveManager.gd` | `_backend_cloud_auto_upload_suspended` field; `set_backend_cloud_auto_upload_suspended()`; `is_backend_cloud_auto_upload_suspended()`; guard in `queue_backend_cloud_save()` |
| `scenes/game/ClickerScreen.gd` | `_should_suspend_backend_auto_upload_for_startup_restore()`; `_resume_backend_auto_upload_after_restore_decision()`; suspend in `_ready()`; resume in all `load_save` exit paths; `_exit_tree()` |

---

## Regression Checklist (from C5.3)

- [ ] Local save / load / reset / prestige unaffected
- [ ] Yandex SDK cloud save on Web unaffected
- [ ] Auto-upload (C5.2) still fires for account users after normal saves (no permanent suspension)
- [ ] Manual Settings Save to Cloud always fires (no suspension guard in `upload_current_save_to_backend_cloud_now`)
- [ ] Manual Settings Load from Cloud still works with existing confirmation step
- [ ] Guest mode: no backend calls, no prompt, no suspension
- [ ] Startup restore prompt still appears when cloud is newer (C5.3 behavior unchanged)
- [ ] No save payloads in logs
