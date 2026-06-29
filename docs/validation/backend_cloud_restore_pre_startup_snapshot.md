# C5.3.2 — Pre-Startup Local Save Snapshot Validation

## Static / Headless Checks

```bash
godot --headless --editor --quit
godot --headless --script res://scripts/tools/ValidateLocalizationDataFreshness.gd
godot --headless --script res://scripts/tools/ValidateLocalizationExport.gd
git status
git diff --stat
```

**Expected:** All commands exit 0. No new localization changes. Only `scenes/game/ClickerScreen.gd` shows a diff (plus `README.md`, `AGENTS.md`, and this doc).

---

## Manual Android Validation Checklist

### Scenario 1 — Reinstall: restore prompt appears (core fix)

1. Play on Android/account. Let auto-upload run (wait 45 s after save, or press Save to Cloud in Settings).
2. Verify cloud save exists (Settings → Cloud Save should show success status).
3. Uninstall the app (or clear app data via Android Settings → Apps → Clear Data).
4. Reinstall and launch.
5. Log in with the same account.
6. **Expected:** `CloudRestorePrompt` appears. The newly-created default local save does NOT suppress the prompt.
7. Tap **Load Cloud Progress**.
8. **Expected:** Game state matches previous progress. No error in logs.

### Scenario 2 — Reinstall: player chooses Keep Local

1. Same setup as Scenario 1.
2. When prompt appears, tap **Keep Local**.
3. **Expected:** Prompt closes. Game continues from blank state.
4. Play and trigger a normal save (enter a new level).
5. **Expected:** Auto-upload fires within 45 s (suspension was cleared by Keep Local). Logs show backend save.

### Scenario 3 — Fresh install, no prior cloud save

1. Install app for the first time (no prior account or no cloud save).
2. Log in to an account that has no cloud save.
3. **Expected:** No restore prompt. Startup proceeds normally. `_pre_startup_had_local_save = false` but `has_save = false` on backend, so no prompt is needed.

### Scenario 4 — Existing local save, cloud older (no prompt)

1. Play on device with account. Let auto-upload run.
2. Continue playing locally (accumulate more progress; next auto-upload not yet fired).
3. Restart app.
4. **Expected:** No restore prompt. Pre-startup local timestamp is newer than cloud timestamp.
5. **Verify in debug log (IS_DEBUG_BUILD):** `Cloud restore pre-startup local save: had=true ts=<ts>` where `<ts>` matches local save time, which is ≥ cloud save time.

### Scenario 5 — Existing local save, cloud newer (prompt appears)

1. Play on device A with account. Let auto-upload run.
2. Log out or switch to device B (which has an older local save or no local save).
3. Launch on device B.
4. **Expected:** Restore prompt appears because cloud is newer than the pre-startup local save on device B.

### Scenario 6 — Guest mode: no restore check, no snapshot used for backend

1. Launch app. On AuthGate tap "Continue as Guest".
2. **Expected:** No restore check, no prompt. `_should_check_backend_cloud_restore()` returns false. Snapshot is still taken (idempotent) but never consulted for a backend check.

### Scenario 7 — Web/Yandex: startup unchanged

1. Open game in browser.
2. **Expected:** `_should_suspend_backend_auto_upload_for_startup_restore()` returns false. No backend check. Yandex SDK cloud-save unaffected. Snapshot is taken (idempotent) but never consulted.

### Scenario 8 — Manual Settings Load from Cloud: unchanged

1. Log in on Android/account. Startup completes (snapshot taken, restore decision made).
2. Open Settings → Cloud Save → tap **Load from Cloud**.
3. **Expected:** Manual download flow is unchanged. Save applied after confirmation. Pre-startup snapshot is not involved.

### Scenario 9 — Auth overlay login during gameplay

1. Start as guest.
2. Open Settings → Account → Sign In. Log in with an account that has a cloud save.
3. **Expected:** `request_backend_cloud_restore_check("auth_overlay")` fires. `_evaluate_cloud_restore_candidate()` is called; it calls `_capture_pre_startup_local_save_snapshot()` defensively but the snapshot was already taken at startup → no-op re-capture. Prompt appears if cloud is newer than the pre-startup local save.

---

## Debug Log Verification (IS_DEBUG_BUILD only)

After launching on Android/account, look for:

```
Cloud restore pre-startup local save: had=true ts=1750000000
```
or (after reinstall):
```
Cloud restore pre-startup local save: had=false ts=0
```

`had=false` → no local save existed before startup → any valid cloud save will trigger the restore prompt.

---

## Key Files Changed

| File | Change |
|------|--------|
| `scenes/game/ClickerScreen.gd` | 3 new fields; `_capture_pre_startup_local_save_snapshot()`; snapshot call in `_ready()`; `_evaluate_cloud_restore_candidate()` rewritten |

---

## Regression Checklist

- [ ] Restore prompt appears after reinstall with existing cloud save (core fix)
- [ ] Restore prompt does NOT appear when local save is newer than cloud
- [ ] Keep Local clears suspension and auto-upload resumes
- [ ] Load Cloud Progress applies save and clears suspension
- [ ] Guest mode: no prompt, no backend calls
- [ ] Web/Yandex: startup unchanged, Yandex SDK cloud-save still works
- [ ] Manual Settings Load from Cloud unchanged
- [ ] No save payloads in logs
- [ ] C5.3.1 suspension still active before `_load_game_on_start_async()` (check that `queue_backend_cloud_save` logs no upload during startup init)
