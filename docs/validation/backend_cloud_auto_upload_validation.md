# C5.2 Backend Cloud Auto-Upload — Validation Checklist

Patch: automatic backend cloud-save upload for Android/RuStore account users.

## Validation commands

```bash
# Parse check (headless editor import)
godot --headless --editor --quit

# Regenerate and validate localization
godot --headless --script res://scripts/tools/GenerateLocalizationData.gd
godot --headless --script res://scripts/tools/ValidateLocalizationDataFreshness.gd
godot --headless --script res://scripts/tools/ValidateLocalizationExport.gd

git status
git diff --stat
```

> **Note:** Godot headless import cannot be run from this shell environment
> (requires a display or a Linux Godot server binary). Run manually on a dev
> machine before the final commit.

---

## Manual Android validation checklist

### 1. Android Guest — no backend upload

- Install the app on a device.
- Skip login (continue as guest).
- Play: buy an upgrade, defeat an enemy, wait for the 10-second autosave.
- **Expected:** No `PUT /v1/save` request is made (verify in logcat or backend logs).
- **Expected:** Settings → Cloud Save section shows guest warning; upload/download buttons hidden.

### 2. Android Account — auto-upload after local save

- Install the app, log in with a valid account.
- Play normally: buy an upgrade, defeat an enemy, wait for the autosave interval (~10 s).
- **Expected:** Within 45 seconds of the first local save, a `PUT /v1/save` request fires automatically.
- **Expected:** No player-facing notification or modal appears during background upload.
- **Expected:** Subsequent saves within 45 s are queued; the upload fires after the throttle window expires.
- **Expected:** Opening Settings shows "Cloud save ready" (or the last status if a prior upload completed).

### 3. Manual Save to Cloud — immediate flush

- Log in, open Settings.
- Press **Save to Cloud**.
- **Expected:** Upload/download buttons disable immediately.
- **Expected:** Status shows "Uploading cloud save…".
- **Expected:** On success, status shows "Cloud save uploaded" and buttons re-enable.
- **Expected:** No duplicate request spam (only one `PUT /v1/save`).
- **Expected:** If a background upload is already in flight when the button is pressed, the in-flight completes and its result is shown — not a second request.

### 4. Manual Load from Cloud — still manual and confirmation-based

- Log in, open Settings.
- Press **Load from Cloud**.
- **Expected:** Confirmation dialog appears.
- **Expected:** Pressing Cancel dismisses the dialog without any download.
- **Expected:** Pressing Confirm loads the cloud save and applies it.
- **Expected:** This is the ONLY way cloud data is applied — no automatic download occurs at startup.

### 5. Backend/network error — local save unaffected

- Log in, disable network (airplane mode or block the backend host).
- Play: trigger a local autosave.
- **Expected:** Local save completes successfully (save file updates).
- **Expected:** Gameplay continues normally.
- **Expected:** `push_warning` appears in logcat for the failed background upload.
- **Expected:** No modal, no error dialog, no interruption.
- Re-enable network.
- **Expected:** The pending save retries automatically after ~60 s.

### 6. Web/Yandex — unchanged

- Run the Web export in a browser.
- Play normally.
- **Expected:** Yandex cloud-save behavior is unchanged.
- **Expected:** Zero backend HTTP requests to the RuStore backend URL.

### 7. Reinstall restore scenario (regression check)

- Log in, play until at least one auto-upload fires.
- Uninstall / clear app data.
- Reinstall and log in with the same account.
- Open Settings → **Load from Cloud** → Confirm.
- **Expected:** Progress is restored from the backend.

### 8. Log cleanliness

- Run in a release build (or search logcat for the following).
- **Must NOT appear in production logs:**
  - Full save JSON payload.
  - Auth token, password, or email verification code.
  - `AuthGateScreen: building UI` / `UI ready` / `root size=` / `panel min size=` / `state=` (these are debug-only now).
- `push_warning` for oversized payloads or upload failures is acceptable.
