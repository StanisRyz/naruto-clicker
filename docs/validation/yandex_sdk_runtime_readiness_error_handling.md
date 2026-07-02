# Y4.1 — Yandex SDK Runtime Readiness and Error Handling Fix

Fixes three real Web/Yandex runtime issues found in preview/testing:

1. SDK language did not apply from the Yandex SDK (a one-shot read at
   `ClickerScreen._ready()` could run before `window.ysdk` finished
   initializing, and an empty read got normalized to the default language,
   silently overwriting a real saved language).
2. Pressing the rewarded ad button paused gameplay/music but no ad appeared
   — if the SDK never called `onOpen`/`onClose`/`onError`, nothing ever
   resumed gameplay/audio or told the player anything happened.
3. The gem purchase dialog could show "Loading price..." forever if
   `payments.getCatalog()` never resolved or rejected.

No gameplay balance, ad rewards, gem purchase rewards, Yandex product ids,
purchase/credit/consume/recovery logic, `SaveManager` schema, or
Android/RuStore/AuthGate/AccountWindow behavior was changed.

## Checklist

- [x] SDK ready event emitted — `YandexBridge.yandex_sdk_ready` (new signal)
  fires exactly once, the first time `refresh_yandex_sdk_ready()` observes
  `window.ysdk` + `window.ysdkReady` ready. Guarded by
  `_sdk_ready_signal_emitted` so it never repeats. Forwarded through
  `Platform.yandex_sdk_ready`. `YandexBridge.yandex_sdk_unavailable(message)`
  signal is also declared for future use (not emitted by this patch — no
  runtime path currently detects a permanent "SDK will never be available"
  condition; the retry/timeout paths below cover the practical cases).
- [x] Language retry works — `ClickerScreen._apply_startup_language_when_platform_ready(attempt)`
  polls `Platform.get_platform_language()` every
  `STARTUP_LANGUAGE_RETRY_DELAY_SEC` (0.4s) up to
  `STARTUP_LANGUAGE_MAX_RETRY_ATTEMPTS` (20, ~8s total) instead of reading
  once. A manually-selected language (`state.language_manually_selected`)
  is never touched. Non-Yandex platforms exit immediately on the first empty
  read (unchanged behavior/timing for Android/editor).
- [x] RU SDK lang applies RU / EN SDK lang applies EN — unchanged
  normalization path (`LocalizationManager.normalize_supported_language()`),
  just reached after a non-empty platform-language read instead of
  potentially reached with `""`.
- [x] Rewarded ad unavailable resumes gameplay/audio —
  `YandexBridge.show_rewarded_ad()` emits `rewarded_ad_error` synchronously
  when the SDK isn't ready or `ysdk.adv.showRewardedVideo` doesn't exist;
  `ClickerScreen._on_rewarded_ad_error()` always resumes gameplay/audio and
  shows a localized status.
- [x] Rewarded ad timeout resumes gameplay/audio —
  `YandexBridge._watch_rewarded_ad_timeout(token)` fires after
  `REWARDED_AD_TIMEOUT_SEC` (7s) if `_rewarded_ad_in_progress` is still true
  and the token wasn't invalidated; clears the in-progress flag and emits
  `rewarded_ad_error("timeout: ...")`. The token is bumped in
  `_on_js_rewarded_ad_open()` so a real, slow-to-close ad (user watching it)
  never gets timed out mid-playback.
- [x] Rewarded reward granted only on `onRewarded` — unchanged;
  `ClickerScreen._on_rewarded_ad_rewarded()` is the only call site for
  `state.grant_*` reward methods. Timeouts, errors, and
  `onClose(wasShown=false)` never reach it.
- [x] Catalog loaded updates prices — unchanged
  (`_on_js_payment_catalog_loaded` → `payment_catalog_loaded` →
  `GemPurchaseDialog._apply_catalog_prices()`).
- [x] Catalog error shows unavailable state — `GemPurchaseDialog._on_payment_catalog_error()`
  now always clears `_catalog_requested` (previously only cleared while the
  dialog was `visible`, which could leave the flag stuck `true` forever if
  the player closed the dialog before the response arrived) and, while
  visible, shows a localized error on both the per-cell price labels and
  the dialog's status label, and disables all buy buttons.
- [x] Catalog timeout does not stay loading forever —
  `YandexBridge._watch_catalog_load_timeout(token)` fires after
  `CATALOG_LOAD_TIMEOUT_SEC` (9s) if `_catalog_load_pending` is still true;
  emits `payment_catalog_error("timeout: ...")`, which flows through the
  same error handling as any other catalog error.
- [x] Missing catalog products remain disabled — unchanged
  (`GemPurchaseDialog._set_all_buy_buttons_disabled()` /
  `Platform.get_catalog_product()` gate, from Y4).
- [x] Purchase/consume/recovery unchanged — `ClickerScreen._on_payment_purchase_success/cancelled/error`,
  `state.grant_paid_gem_purchase()`, `state.is_purchase_processed()`,
  `Platform.consume_purchase()` call sites, and
  `_on_unprocessed_purchase_found()` were not modified by this patch.

## What changed

| File | Change |
|---|---|
| `autoload/YandexBridge.gd` | Added `yandex_sdk_ready` / `yandex_sdk_unavailable` signals (ready emitted once from `refresh_yandex_sdk_ready()`); added `get_yandex_runtime_debug_state()`; added rewarded-ad request timeout (`_watch_rewarded_ad_timeout`, 7s) with token-based cancellation on genuine `onOpen`; added catalog-load timeout (`_watch_catalog_load_timeout`, 9s); added explicit `getPayments`/`getCatalog` existence checks and `console.log`/`console.warn` diagnostics in `show_rewarded_ad()` and `load_payment_catalog()`; error messages are now prefixed `timeout:` or `unavailable:` so callers can distinguish the two without a new signal parameter. |
| `autoload/Platform.gd` | Forwards `yandex_sdk_ready` / `yandex_sdk_unavailable` from `YandexBridge`; added `get_yandex_runtime_debug_state()` (returns `{}` on platforms without the method). |
| `scripts/platform/WebYandexPlatform.gd` | Delegates `get_yandex_runtime_debug_state()` to `YandexBridge`. |
| `scenes/game/ClickerScreen.gd` | Replaced the one-shot `_apply_startup_language()` body with a retry loop (`_apply_startup_language_when_platform_ready`); added a code-created runtime status toast (`_create_runtime_status_toast` / `_show_runtime_status_toast`) reused for ad-unavailable/timeout and language-fallback statuses; `_on_rewarded_ad_error` and `_on_rewarded_ad_closed(was_shown)` now show a localized status and log the raw message in debug builds. |
| `scenes/ui/GemPurchaseDialog.gd` | `_on_payment_catalog_error()` always resets `_catalog_requested` (bug fix — previously only reset while `visible`), shows a distinct message for the timeout case, and also sets the dialog status label. |
| `localization/game_text.csv`, `scripts/ui/LocalizationData.gd` | Added `yandex.ad.unavailable`, `yandex.ad.timeout`, `yandex.catalog.timeout`, `yandex.catalog.unavailable`, `yandex.language.sdk_unavailable` (RU + EN). `LocalizationData.gd` regenerated automatically. |

## Design notes

- The rewarded-ad and catalog timeouts are implemented once, inside
  `YandexBridge` (not duplicated in `ClickerScreen`/`GemPurchaseDialog`),
  since `YandexBridge` already owns the in-flight state (`_rewarded_ad_in_progress`,
  `_catalog_load_pending`) and is the only place that knows whether a JS
  callback ever actually fired. Both call sites (`ClickerScreen`,
  `GemPurchaseDialog`) already listened to the existing `rewarded_ad_error` /
  `payment_catalog_error` signals, so the timeout reuses that exact path —
  no new signal wiring was needed at the call sites.
- Error messages are prefixed (`timeout: …` / `unavailable: …`) instead of
  adding a new signal parameter, to avoid changing `rewarded_ad_error(message: String)` /
  `payment_catalog_error(message: String)`'s signature (both are also used
  by `Platform`'s forwarding and by existing call sites that only log the
  message).
- `get_yandex_runtime_debug_state()` only returns safe, non-sensitive fields
  (SDK/ready flags, language string, feature-availability booleans, catalog
  cache size) — never tokens, save payloads, or player data. It's for debug
  logs/manual validation only, not shown in any UI.

## Validation commands run

```bash
godot --headless --editor --quit
godot --headless --script res://scripts/tools/ValidateLocalizationDataFreshness.gd
godot --headless --script res://scripts/tools/ValidateLocalizationExport.gd
git status
git diff --stat
```

All passed. `localization/game_text.csv` changed (431 keys, was 426);
`LocalizationData.gd` was regenerated (auto-run by the project's tooling)
and both validators confirm it's in sync.

## Manual Yandex preview validation (not run — requires the Yandex console/preview)

1. Build a Web export (`godot --headless --export-release "Web" …`).
2. Run it through the Yandex preview/debug panel, not `file://`.
3. Confirm loader state reaches `IT`.
4. In the browser console, confirm `window.ysdk` exists, `window.ysdkReady === true`,
   and `window.ysdk.environment.i18n.lang` has the expected value.
5. Test with a RU SDK language — confirm the UI becomes RU automatically
   without a manual language change.
6. Test with an EN SDK language — confirm the UI becomes EN automatically.
7. Press the rewarded ad button. If the ad is unavailable, confirm gameplay
   and music resume and the "Ad is currently unavailable" / "Ad did not
   open" status appears.
8. If the ad opens, confirm the reward is granted only after `onRewarded`.
9. Open the gem shop. Confirm the catalog either loads real prices or shows
   an error/unavailable state after the timeout — never an endless
   "Loading price...".
10. Confirm a purchase still credits gems exactly once, is consumed, and
    unprocessed-purchase recovery still works (Y4 behavior, unchanged).

## Files inspected

`export_presets.cfg`, `autoload/YandexBridge.gd`, `autoload/Platform.gd`,
`scripts/platform/WebYandexPlatform.gd`, `scenes/game/ClickerScreen.gd`,
`scenes/ui/GemPurchaseDialog.gd`, `scenes/ui/ShopSheet.gd`,
`scenes/ui/OfflineRewardDialog.gd`, `scenes/ui/RewardedAdBanner.gd`,
`localization/game_text.csv`, `scripts/ui/LocalizationData.gd`,
`scripts/ui/LocalizationManager.gd`, `scripts/game/BuildConfig.gd`,
`docs/validation/yandex_release_audit_platform_separation.md`,
`docs/validation/yandex_payments_catalog_price_display.md`, `README.md`,
`AGENTS.md`.
