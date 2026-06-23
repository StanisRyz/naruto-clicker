# RuStore Readiness Checklist

Pre-upload technical checklist for submitting **Shinobi Clicker: Idle** to
RuStore. Work through each item before uploading the first APK.

---

## App identity

| Item | Value | Status |
|---|---|---|
| App name | Shinobi Clicker: Idle | ✅ Set in `project.godot` and `export_presets.cfg` |
| Package name | `com.stanis.shinobiclickeridle` | ✅ Set in `export_presets.cfg` |
| Version code | 1 (increment before each upload) | ⚠️ Increment before upload |
| Version name | 1.0 (set in export_presets.cfg) | ⚠️ Set before upload |

---

## Build requirements

| Item | Value | Status |
|---|---|---|
| Signed APK | keystore configured in export preset | ⚠️ Verify keystore paths in `export_presets.cfg` |
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
| SDK integration | ⚠️ **Pending** — `AndroidRuStorePlatform._get_rustore_pay_plugin()` returns `null` |
| Real purchase call | ⚠️ **Pending** — `purchase_product()` emits error until plugin is wired |
| RuStore product ids | ⚠️ **Pending** — `rustore_product_id` fields in `GemPurchaseConfig.gd` are placeholders; update to match actual RuStore product registrations |
| Unprocessed purchase recovery | ⚠️ **Pending** — `check_unprocessed_purchases()` emits complete immediately; must call plugin `getPurchases()` when integrated |
| Duplicate purchase protection | ✅ `ClickerState.processed_purchase_ids` — persisted, capped at 100, never cleared by prestige/reset |
| Purchase id deduplication | ✅ `state.is_purchase_processed()` / `state.mark_purchase_processed()` |
| RuStore Pay SDK must not be BillingClient | ✅ Architecture uses RuStore Pay (new SDK) pattern; BillingClient is not used |

**To complete RuStore Pay integration:**
1. Obtain the official RuStore Pay Godot plugin `.aar`.
2. Drop the `.aar` into `android/plugins/` (or wire via export plugin).
3. Implement `_get_rustore_pay_plugin()` to return `Engine.get_singleton("RuStorePayPlugin")`.
4. Implement `purchase_product()` using the plugin's purchase call.
5. Connect plugin `success/cancel/error` signals to `_on_rustore_purchase_*` handlers in `AndroidRuStorePlatform`.
6. Update `rustore_product_id` values in `GemPurchaseConfig.gd` to match RuStore dashboard.
7. Implement `check_unprocessed_purchases()` via plugin `getPurchases()`.

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

## Remaining blockers before RuStore upload

1. **Build the AndroidYandexAds plugin AAR** (`./gradlew assembleRelease`).
2. **Register the app in Yandex Mobile Ads dashboard** and fill in `android_ad_unit_id` values in `AdPlacementConfig.gd`.
3. **Test rewarded and interstitial ads on a real Android device**.
4. **Integrate RuStore Pay SDK** (see steps above).
5. **Update `rustore_product_id` values** in `GemPurchaseConfig.gd`.
6. **Test all 4 gem purchase flows** via RuStore Pay.
7. **Set version code / version name** before each upload.
8. **Verify keystore** is configured and the release APK is signed.
9. **Upload signed release APK** to RuStore developer console.
