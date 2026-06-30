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
