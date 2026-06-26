# RuStore Readiness Checklist

Pre-upload technical checklist for submitting **Shinobi Clicker: Idle** to
RuStore. Work through each item before uploading the first APK.

---

## App identity

| Item | Value | Status |
|---|---|---|
| App name | Shinobi Clicker: Idle | ✅ Set in `project.godot` and `export_presets.cfg` |
| Package name | `com.stanis.shinobiclickeridle` | ✅ Set in `export_presets.cfg` |
| Version code | 1 (increment before each upload) | ⚠️ Increment before each upload — first upload may use 1; every later upload must be strictly larger |
| Version name | 1.0.0 (set in export_presets.cfg) | ✅ Set to `1.0.0` in `export_presets.cfg` |

---

## Build requirements

| Item | Value | Status |
|---|---|---|
| Signed APK | keystore configured in export preset | ⚠️ Manual verification required — configure keystore locally before export; see `docs/android_release_signing.md` |
| min SDK | 24 | ✅ Set in `export_presets.cfg` and `config.gradle` |
| target SDK | 35 | ✅ Set in `export_presets.cfg` and `config.gradle` |
| Architecture | arm64-v8a (armeabi-v7a optional) | ✅ Set in `export_presets.cfg` |
| Gradle build | Custom Gradle (`use_gradle_build=true`) | ✅ Active |
| Immersive mode | Enabled | ✅ `screen/immersive_mode=true` |

---

## Permissions

| Permission | Required | Status |
|---|---|---|
| `INTERNET` | Yes — for ads and any network calls | ✅ `permissions/internet=true` |
| `ACCESS_NETWORK_STATE` | Yes — for Yandex Ads availability check | ✅ `permissions/access_network_state=true` |
| `POST_NOTIFICATIONS` | Not needed for this app | ✅ Not requested |
| No location, contacts, camera, microphone | Confirmed absent | ✅ |

---

## Android Ads SDK (Yandex Mobile Ads)

| Item | Status |
|---|---|
| Plugin source committed | ✅ `addons/android_yandex_ads/` |
| Plugin enabled in project.godot | ✅ |
| SDK version | `com.yandex.android:mobileads:8.1.0` |
| Plugin AAR built | ⚠️ **Must rebuild** — plugin uses SDK 8 callback API: `loadAd(request, listener)` (non-suspend), `YandexAds.initialize`, `AdError` for show failures; rebuild with `.\gradlew.bat assembleRelease` — see `docs/android_ads_build.md` |
| Ad unit ids configured | ✅ Real Yandex ad unit ids set in `AdPlacementConfig.gd`: `rewarded_shop_gems` (R-M-19501283-1), `rewarded_bonus_banner` (R-M-19501283-2), `rewarded_offline_gold_x3` (R-M-19501283-3), `fullscreen_auto_interstitial` (R-M-19501283-4) |
| Rewarded ads tested on device | ⚠️ Pending — real-device ad display testing required |
| Interstitial ads tested on device | ⚠️ Pending — real-device ad display testing required |
| Reward granted only in GDScript | ✅ `ClickerScreen._on_rewarded_ad_rewarded()` |
| No reward on close without reward callback | ✅ Enforced by `_rewarded_ad_reward_granted_for_current_request` flag |

---

## RuStore Pay SDK (payments)

| Item | Status |
|---|---|
| Official SDK addon committed | ✅ `addons/RuStoreGodotPay/` + `addons/RuStoreGodotCore/` |
| GDScript client class | `RuStoreGodotPayClient` (`addons/RuStoreGodotPay/RuStoreGodotPay.gd`) |
| Singleton names | `Engine.get_singleton("RuStoreGodotPay")` / `"RuStoreGodotCore"` |
| Plugins enabled in project.godot | ✅ `RuStoreGodotCore`, `RuStoreGodotPay` |
| AndroidRuStorePlatform uses official client | ✅ `RuStoreGodotPayClient.get_instance()` — no `AndroidRuStorePay` singleton |
| SDK availability guards | ✅ checks `OS.has_feature("android")`, `Engine.has_singleton("RuStoreGodotPay")`, `Engine.has_singleton("RuStoreGodotCore")` |
| Purchase type | ONE_STEP (auto-confirmed consumable) — `confirm_two_step_purchase` is not used |
| `consume_purchase()` behavior | No-op by design — ONE_STEP is auto-confirmed by SDK; no explicit consume call is made after reward grant |
| `enable_purchase_event_listener` | ✅ `true` — required for `on_payment_failed` / `on_payment_completed` / `on_purchase_cancelled` event callbacks |
| Purchase availability preflight | ✅ `get_purchase_availability()` called before `purchase()` — if unavailable or check fails, `payment_purchase_error` is emitted and `purchase()` is never called; avoids official SDK crash on sideload/test devices |
| Terminal callback hardening | ✅ All 5 terminal signals handled: `on_purchase_success`, `on_purchase_failure`, `on_purchase_cancelled`, `on_payment_completed`, `on_payment_failed` |
| Stuck payment UI bug | ✅ Fixed — `on_payment_failed` + `on_purchase_cancelled` clear `_payment_in_progress` and re-enable dialog buy button |
| Duplicate terminal event dedup | ✅ `_consume_pending_payment_local_id()` — returns `""` if already cleared; all terminal handlers check this |
| Empty product id guard | ✅ `purchase_product()` rejects empty `platform_product_id` before setting in-progress flag |
| Empty purchase id guard | ✅ `on_purchase_success` and `on_payment_completed` with all-empty ids treated as error — no reward granted |
| Purchase id extraction | ✅ preferred order: `purchaseId` → `orderId` → `invoiceId` |
| Duplicate purchase protection | ✅ `ClickerState.processed_purchase_ids` — persisted, capped at 100, never cleared by prestige/reset |
| Unprocessed purchase recovery | ✅ `get_purchases(CONSUMABLE_PRODUCT, CONFIRMED)` on startup |
| Successful purchase on real device | ⚠️ **Pending** — availability preflight prevents crashes on sideload/test builds where payments are unavailable; real successful purchase testing requires install via RuStore or distribution context that supports payments |
| RuStore product ids | ⚠️ **Pending** — `rustore_product_id` fields in `GemPurchaseConfig.gd` are placeholders; update to match RuStore developer console |
| `android/` tracked selectively | ✅ Template source tracked; generated dirs and secrets ignored via targeted `.gitignore` rules |
| `rustore_values.xml` | ✅ `android/build/res/values/rustore_values.xml` committed — consoleApplicationId, internalConfigKey, deeplinkScheme set |
| RuStore manifest metadata | ✅ `android/build/AndroidManifest.xml` — `console_app_id_value`, `internal_config_key`, `sdk_pay_scheme_value` meta-data present |
| RuStoreIntentFilterActivity | ✅ `android/build/src/com/godot/game/RuStoreIntentFilterActivity.java` committed — deeplink trampoline to GodotApp |
| RuStore Pay SDK must not be BillingClient | ✅ Uses `RuStoreGodotPayClient`; BillingClient is forbidden |
| Validate tool | ✅ `scripts/tools/ValidateMonetizationConfig.gd` — headless, validates all 4 gem products |
| Old custom adapter | `addons/android_rustore_pay/` — DEPRECATED, not enabled, not used for payments |

**Required local setup before export:**
1. Update `rustore_product_id` values in `GemPurchaseConfig.gd` to match RuStore developer console.
2. Test all 4 gem purchase flows on a real Android device.

`rustore_values.xml`, AndroidManifest RuStore metadata, and `RuStoreIntentFilterActivity` are now
committed and require no local setup. See `docs/rustore_pay_integration.md` for the full guide.

---

## Core gameplay systems

| Item | Status |
|---|---|
| Save / load | ✅ Local save works; cloud save returns empty `{}` on Android (no Yandex cloud) |
| Reset Progress | ✅ Preserves gems, settings, permanent shop items |
| Prestige | ✅ Preserves gems, prestige points, permanent shop items |
| Offline reward | ✅ Accumulates and presents dialog on return |
| All 4 gem products configured | ✅ `GemPurchaseConfig.gd` — rustore_product_id fields present (placeholders) |

---

## Web / Yandex isolation

| Item | Status |
|---|---|
| Web export unaffected by Android changes | ✅ — `WebYandexPlatform` and `YandexBridge` unchanged |
| Android plugin code not loaded on Web | ✅ — `Platform._ready()` selects impl by `OS.has_feature("android")` |
| Gameplay reward code unchanged | ✅ — no changes to `ClickerScreen` reward handlers |

---

## Release signing and APK validation

- See **`docs/android_release_signing.md`** — keystore generation, storage rules, signing
  configuration in Godot, APK verification commands.
- See **`docs/android_release_validation.md`** — full pre-upload APK validation checklist.
- See **`docs/local_release_env.example.md`** — local path and credential template (never commit).

---

## Remaining blockers before RuStore upload

1. **Configure release keystore locally** and verify the APK is signed (see `docs/android_release_signing.md`).
2. **Build the AndroidYandexAds plugin AAR** (`./gradlew assembleRelease` from `addons/android_yandex_ads/android/AndroidYandexAdsPlugin/`).
3. ✅ **Android ad unit ids configured** — all 4 placements have real Yandex Mobile Ads ids in `AdPlacementConfig.gd`.
4. **Test rewarded and interstitial ads on a real Android device**.
5. **Update `rustore_product_id` values** in `GemPurchaseConfig.gd` to match RuStore developer console.
6. **Test all 4 gem purchase flows** via `RuStoreGodotPayClient` on a real Android device.
7. **Increment `version/code`** in `export_presets.cfg` before each upload after the first.
8. **Validate the release APK** using `docs/android_release_validation.md` before each upload.
9. **Upload signed release APK** to RuStore developer console.
