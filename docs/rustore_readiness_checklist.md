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
| Plugin AAR built | ⚠️ **Must build before export** — see `docs/android_ads_build.md` |
| Ad unit ids configured | ⚠️ **Pending** — `android_ad_unit_id` fields in `AdPlacementConfig.gd` are empty; fill in from Yandex Mobile Ads dashboard after app registration |
| Rewarded ads tested on device | ⚠️ Pending — requires real ad unit ids |
| Interstitial ads tested on device | ⚠️ Pending — requires real ad unit ids |
| Reward granted only in GDScript | ✅ `ClickerScreen._on_rewarded_ad_rewarded()` |
| No reward on close without reward callback | ✅ Enforced by `_rewarded_ad_reward_granted_for_current_request` flag |

---

## RuStore Pay SDK (payments)

| Item | Status |
|---|---|
| Plugin structure committed | ✅ `addons/android_rustore_pay/` — Godot 4 Android plugin v2 |
| Singleton name | `Engine.get_singleton("AndroidRuStorePay")` |
| Plugin enabled in project.godot | ✅ |
| Plugin AAR built | ⚠️ **Must build before export** — `./gradlew assembleRelease` from `addons/android_rustore_pay/android/AndroidRuStorePayPlugin/` |
| RuStore Pay SDK stubs filled in | ⚠️ **Pending** — `AndroidRuStorePayPlugin.kt` has `// TODO` stubs; real SDK not available yet |
| RuStore Pay SDK AAR / Maven dep | ⚠️ **Pending** — add to `build.gradle` and `AndroidRuStorePayExportPlugin.gd` once obtained |
| Real purchase call | ⚠️ **Pending** — `purchase()` stub emits error; replace with real SDK call |
| Consume call | ⚠️ **Pending** — `consume()` stub is a no-op; replace with real SDK call |
| Unprocessed purchase recovery | ⚠️ **Pending** — `get_pending_purchases()` stub emits completed immediately; replace with real SDK call |
| RuStore product ids | ⚠️ **Pending** — `rustore_product_id` fields in `GemPurchaseConfig.gd` are placeholders; update to match RuStore developer console |
| Duplicate purchase protection | ✅ `ClickerState.processed_purchase_ids` — persisted, capped at 100, never cleared by prestige/reset |
| Purchase id deduplication | ✅ `state.is_purchase_processed()` / `state.mark_purchase_processed()` |
| RuStore Pay SDK must not be BillingClient | ✅ Architecture uses RuStore Pay (new SDK) pattern; BillingClient is forbidden |
| Signal wiring in AndroidRuStorePlatform | ✅ `_ready()` connects all 6 plugin signals to handlers |
| Empty product id guard | ✅ `purchase_product()` rejects empty `platform_product_id` before setting in-progress flag |
| Validate tool | ✅ `scripts/tools/ValidateMonetizationConfig.gd` — headless, validates all 4 gem products |

**Missing external step (one file required):**

The official RuStore Pay SDK AAR (or Maven coordinate) is not bundled.
This is the single external dependency blocking real payments.

**To complete RuStore Pay integration:**
1. Obtain the official RuStore Pay SDK from the RuStore developer portal.
2. Add to `addons/android_rustore_pay/android/AndroidRuStorePayPlugin/libs/` (or configure Maven).
3. Fill in the `// TODO` stubs in `AndroidRuStorePayPlugin.kt` — see `docs/rustore_pay_integration.md`.
4. Build the plugin AAR: `./gradlew assembleRelease`.
5. Update `rustore_product_id` values in `GemPurchaseConfig.gd` to match RuStore dashboard.
6. Test all 4 gem purchase flows on a real Android device.

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
2. **Build the AndroidYandexAds plugin AAR** (`./gradlew assembleRelease`).
3. **Register the app in Yandex Mobile Ads dashboard** and fill in `android_ad_unit_id` values in `AdPlacementConfig.gd`.
4. **Test rewarded and interstitial ads on a real Android device**.
5. **Obtain RuStore Pay SDK** and fill in `AndroidRuStorePayPlugin.kt` stubs (see `docs/rustore_pay_integration.md`).
6. **Build the AndroidRuStorePay plugin AAR** (`./gradlew assembleRelease`).
7. **Update `rustore_product_id` values** in `GemPurchaseConfig.gd` to match RuStore developer console.
8. **Test all 4 gem purchase flows** via RuStore Pay on a real Android device.
9. **Increment `version/code`** in `export_presets.cfg` before each upload after the first.
10. **Validate the release APK** using `docs/android_release_validation.md` before each upload.
11. **Upload signed release APK** to RuStore developer console.
