# C6 Backend Cloud Save Stabilization — Validation Checklist

Covers hardening changes applied in C6 to the Android/RuStore backend auth and
cloud-save flows introduced in C3–C5.4. No new gameplay features, no balance
changes, no backend Cloud Function changes.

---

## 1. Android Guest startup — no backend calls

**Setup:** fresh install on Android, no stored session token.

| Step | Expected |
|------|----------|
| Launch app | AuthGate shows login form (no backend request until user acts) |
| Press "Continue as Guest" | AuthGate closes, ClickerScreen starts |
| Gameplay runs | No backend auth/save requests initiated (guest mode) |
| Open Settings | Account block shows guest-mode status; cloud buttons hidden |

---

## 2. Android Account startup — auth gate + cloud restore priority

**Setup:** Android device with stored session token.

| Step | Expected |
|------|----------|
| Launch app | AuthGate shows CHECKING state |
| Backend `get_me` succeeds | AuthGate closes with mode `"account"` |
| `set_startup_auth_mode("account")` is called **before** `add_child` | `_gameplay_started_as_guest` is false before any `_ready()` code runs |
| ClickerScreen starts | Backend auto-upload is suspended until restore decision |
| Cloud-restore check runs | CloudRestorePrompt shown if cloud save is newer |
| User confirms "Load Cloud" | Cloud save applied; auto-upload resumed |
| User confirms "Keep Local" | Local save kept; auto-upload resumed |

---

## 3. Duplicate auth request prevention

**Setup:** Android, AuthGate login form visible.

| Step | Expected |
|------|----------|
| Enter valid email + password | — |
| Press "Sign In" rapidly multiple times | Only ONE backend login request sent; subsequent presses ignored until response |
| Backend responds (success or failure) | `_request_in_progress` cleared; button is re-activatable |

Repeat for: Register, Request Password Reset, Confirm Reset Code.

---

## 4. Duplicate signal connection guard

**Setup:** AuthGateScreen reopened as overlay from Settings.

| Step | Expected |
|------|----------|
| First auth gate open | `backend_operation_succeeded` / `backend_operation_failed` connected once |
| Auth gate closed, reopened as overlay | Connections not duplicated — `is_connected()` guard prevents double-connect |
| Backend response arrives | Handler called exactly once |

---

## 5. Guest → Account migration prompt (collision guard)

**Setup:** Android guest session; cloud save with newer timestamp exists.

| Step | Expected |
|------|----------|
| Player logs in mid-session from Settings | Cloud-restore check runs first |
| CloudRestorePrompt is visible | GuestMigrationPrompt does NOT appear (visibility guard in `_should_show_guest_migration_prompt()`) |
| User resolves CloudRestorePrompt | GuestMigrationPrompt appears after (if applicable) |
| Both prompts are never visible simultaneously | Confirmed |

---

## 6. Backend auto-upload suspension lifecycle

**Setup:** Android account, startup.

| Step | Expected |
|------|----------|
| `_ready()` runs on Android + session exists | `_backend_cloud_auto_upload_suspended = true` set |
| `_load_game_on_start_async()` calls `_save_game_now()` | `queue_backend_cloud_save()` returns early — suspended |
| Restore decision made (any path) | `_resume_backend_auto_upload_after_restore_decision()` called |
| After resume, next `save_data()` call | Auto-upload proceeds normally |
| Scene exits before decision (`_exit_tree`) | Suspension resumed in `_exit_tree()` — no leak |

---

## 7. Manual cloud save / load busy-state

**Setup:** Android account, Settings open.

| Step | Expected |
|------|----------|
| Press "Save to Cloud" | Buttons disabled (`set_cloud_save_buttons_busy(true)`) while request in flight |
| Backend responds | Buttons re-enabled; status message shown |
| Press "Load from Cloud" | Inline confirmation appears |
| Confirm load | Buttons disabled while request in flight |
| Backend responds | Buttons re-enabled; save applied or error shown |
| Press both buttons rapidly | Second press ignored while first is in flight |

---

## 8. Password reset full flow

**Setup:** Android, AuthGate showing, valid registered email.

| Step | Expected |
|------|----------|
| Enter email, press "Forgot Password?" | Request-reset form shown |
| Press "Send Reset Code" | `_request_in_progress = true`; button disabled |
| Backend responds with code sent | `_request_in_progress = false`; confirm-reset form shown |
| Press "Confirm Reset" rapidly | Only ONE backend request sent |
| Backend confirms reset | `_request_in_progress = false`; login form shown |

---

## 9. Debug prints — release build

**Setup:** Release export (not debug build); `BuildConfig.IS_DEBUG_BUILD = false`.

| Location | Expected in release |
|----------|---------------------|
| `ClickerScreen._load_game_on_start_async()` — "cloud save is newer" | NOT printed |
| `ClickerScreen._load_game_on_start_async()` — "no valid local save, using cloud save" | NOT printed |
| `ClickerScreen.notify_yandex_game_ready()` — "notify_yandex_game_ready called" | NOT printed |
| `AndroidRuStorePlatform` — all prints | Gated behind `OS.is_debug_build()` |
| `AuthGateScreen` — layout debug prints | Gated behind `BuildConfig.IS_DEBUG_BUILD` |

---

## 10. Android-only backend boundary

**Setup:** Web/Yandex export.

| Check | Expected |
|-------|----------|
| No backend HTTP requests on Web startup | Confirmed — `AndroidRuStorePlatform` is not selected |
| No AuthGate shown on Web | `Main._should_show_android_auth_gate()` returns false |
| Settings account block on Web | Hidden (`_is_backend_account_ui_supported()` returns false) |
| `SaveManager.queue_backend_cloud_save()` on Web | Early-returns at `OS.has_feature("android")` guard |
| Yandex cloud-save (`YandexBridge`) | Unchanged; operates normally |

---

## 11. Save payload validation

**Setup:** Android account, manual or startup cloud load.

| Scenario | Expected |
|----------|----------|
| Cloud payload missing `save_version` | `apply_cloud_save_payload()` returns false; local save unchanged |
| Cloud payload `save_version = 0` | Returns false; local save unchanged |
| Cloud payload missing `last_save_unix_time` | Returns false; local save unchanged |
| Valid payload | Applied; ClickerScreen reloads state |

---

## 12. No sensitive log output (all builds)

Grep the GDScript sources for the following patterns and confirm none exist outside
their gated context:

```
print.*token
print.*password
print.*session
print.*reset_code
print.*verify_code
print.*save.*{        # full save JSON
```

Expected: zero ungated matches involving auth credentials or full save payloads.

---

## 13. Web / Yandex regression

After any C6 change, verify on Web export:

- [ ] Game loads and Yandex SDK initializes
- [ ] Rewarded ads work (floating banner, shop, offline ×3)
- [ ] Fullscreen interstitial works
- [ ] Gem purchases work
- [ ] Yandex cloud-save (via `YandexBridge`) still saves/loads
- [ ] Runtime pause/resume on tab visibility change works
- [ ] Audio pause during ads and platform pause works

---

## 14. Ads / Payments regression

- [ ] Rewarded ad reward granted only in `rewarded_ad_rewarded` callback
- [ ] Fullscreen ad grants no reward
- [ ] Gem purchase dedup: same purchase id not granted twice
- [ ] Cancel / error grant nothing
- [ ] `processed_purchase_ids` persists across prestige and reset

---

## C6.1 Release Audit Fixes — Additional Checks

### C6.1-1. Android release validator — version name

```bash
python tools/validate_android_release.py --apk <APK_PATH>
```

| Check | Expected |
|-------|----------|
| `export_presets.cfg` contains `version/name="1.0.0"` | PASS |
| `AndroidManifest.xml` contains `android:versionName="1.0.0"` | PASS (unchanged) |
| `version/code=1` present | PASS (unchanged) |
| `package/unique_name="com.stanis.shinobiclickeridle"` present | PASS (unchanged) |

APK checks (`aapt versionName`, signature) require a built APK and `aapt`/`apksigner` in PATH.
If APK is not available, document that APK checks were skipped and must be run after export.

### C6.1-2. Manual Save to Cloud during in-flight auto-upload

**Setup:** Android account, trigger an auto-upload (save any game state). Immediately press "Save to Cloud" in Settings.

| Step | Expected |
|------|----------|
| Auto-upload begins (`_backend_cloud_upload_in_flight = true`) | — |
| Press "Save to Cloud" | `upload_current_save_to_backend_cloud_now()` called |
| In-flight detected | Current payload built, stored in `_pending_backend_cloud_save_data`, `_backend_cloud_retry_pending = true`, returns `true` |
| Auto-upload succeeds | `mark_backend_cloud_upload_finished(true)` → retry timer fires (60 s) → newest payload uploaded |
| Auto-upload fails | `mark_backend_cloud_upload_finished(false)` → retry triggered immediately via timer |
| Logcat | No full save JSON printed |

### C6.1-3. Backend `request_in_progress` does not permanently lose pending upload

**Setup:** Android account, two save events in rapid succession.

| Step | Expected |
|------|----------|
| First save triggers `_send_backend_cloud_save(payload_A)` | `_backend_cloud_upload_current_payload = payload_A` |
| Second save queued into `_pending_backend_cloud_save_data = payload_B` | — |
| Backend returns `request_in_progress` error → `mark_backend_cloud_upload_finished(false)` | `_pending_backend_cloud_save_data` is `payload_B` (not empty) → retry scheduled |
| First upload responded with normal failure (network error) | `_pending_backend_cloud_save_data` still holds `payload_A` if no newer payload; retry scheduled |
| Retry fires after 60 s | Newest queued payload uploaded |

### C6.1-4. AuthGate Guest cannot bypass active request

**Setup:** Android, AuthGate login form. Enter credentials and press "Sign In". While request is in-flight:

| Action | Expected |
|--------|----------|
| Press "Continue as Guest" | Ignored — `_request_in_progress = true` |
| Press "Register" tab | Ignored |
| Press "Forgot Password?" | Ignored |
| Request succeeds or fails | `_request_in_progress = false`; guest/navigation buttons respond normally |

Repeat for Register form (press "Login" tab while register request in-flight).

### C6.1-5. ClickerScreen backend signals not duplicated

**Setup:** Android account, normal gameplay.

| Scenario | Expected |
|----------|----------|
| `ClickerScreen._ready()` called once | `backend_operation_succeeded` connected once |
| Overlay AuthGate opened and closed (reconnection path) | `is_connected()` guard prevents duplicate; handler still called exactly once per backend event |
| `ClickerScreen._exit_tree()` | Both backend signals disconnected; no handler called after scene removed |

### C6.1-6. Android manifest — profileable disabled

```bash
grep -A2 "profileable" android/build/AndroidManifest.xml
```

Expected output:
```xml
<profileable
    android:shell="true"
    android:enabled="false"
```

### C6.1-7. Release log — no sensitive data

Run on device / emulator, perform:
- Login, logout, password reset request, password reset confirm
- Cloud save / load

Verify Logcat contains none of:
- `session_token`
- `password`
- `reset_code` / `code`
- raw save JSON (large `{` blocks with game state fields)
