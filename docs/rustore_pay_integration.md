# RuStore Pay Integration Guide

## Overview

In-app purchases on Android use the **AndroidRuStorePay** Godot 4 Android Plugin v2.
The plugin is a compile-safe adapter: it builds and runs without the real RuStore Pay SDK,
but all purchase calls emit `purchase_error` until the SDK stubs are replaced.

---

## Plugin location

```
addons/android_rustore_pay/
  plugin.cfg                               ← Godot editor plugin registration
  AndroidRuStorePayExportPlugin.gd         ← Declares AAR path for Android export
  android/AndroidRuStorePayPlugin/         ← Android library Gradle project
    build.gradle
    settings.gradle
    src/main/
      AndroidManifest.xml                  ← Registers singleton via meta-data
      kotlin/com/shinobi/rustorepay/
        AndroidRuStorePayPlugin.kt         ← GodotPlugin subclass (stub — fill in SDK)
```

## Singleton name

```gdscript
Engine.get_singleton("AndroidRuStorePay")
```

Checked in `AndroidRuStorePlatform._get_rustore_pay_plugin()`. Returns `null` if the
plugin AAR was not included in the build or the Kotlin stubs were not filled in.

---

## Product id mapping

Product ids are configured in `scripts/game/config/GemPurchaseConfig.gd`.
Each product has a `rustore_product_id` field (currently a placeholder matching the local id).

Update `rustore_product_id` values to match the exact product ids registered in the
RuStore developer console before publishing.

```gdscript
GemPurchaseConfig.get_platform_product_id(local_id, "rustore")
```

This resolution happens in `ClickerScreen._on_gem_product_purchase_requested()` via
`Platform.get_platform_key()` — no product id is hardcoded in gameplay code.

---

## Purchase flow

```
ClickerScreen                  Platform              AndroidRuStorePlatform     AndroidRuStorePayPlugin (Kotlin)
     │                             │                          │                            │
     │  purchase_product(id)       │                          │                            │
     │────────────────────────────▶│                          │                            │
     │                             │  purchase_product(id)    │                            │
     │                             │─────────────────────────▶│                            │
     │                             │                          │  plugin.purchase(id)       │
     │                             │                          │───────────────────────────▶│
     │                             │                          │                            │ (SDK call → RuStore UI)
     │                             │                          │  purchase_success(id, tok) │
     │   payment_purchase_success  │◀─────────────────────────│◀───────────────────────────│
     │◀────────────────────────────│                          │                            │
     │  grant gems + mark_processed│                          │                            │
     │  Platform.consume_purchase  │                          │                            │
     │────────────────────────────▶│                          │                            │
     │                             │  consume_purchase(tok)   │                            │
     │                             │─────────────────────────▶│                            │
     │                             │                          │  plugin.consume(tok)       │
     │                             │                          │───────────────────────────▶│
```

Key invariants:
- Rewards are granted only in `ClickerScreen._on_payment_purchase_success()`.
- `state.mark_purchase_processed(purchase_token)` is called before `consume_purchase()`.
- `state.is_purchase_processed(purchase_token)` guards against duplicate grants.
- `_payment_in_progress` flag prevents overlapping purchase attempts.
- Empty `platform_product_id` is rejected before the flag is set.

---

## Consume behavior

RuStore Pay requires consuming (finalizing) consumable purchases to allow re-purchase.
`AndroidRuStorePlatform.consume_purchase(purchase_token)` calls `plugin.consume(token)`.
Consume failures are logged by the Kotlin plugin but not signalled — they are non-fatal
for the user (the purchase has already been granted and persisted).

---

## Unprocessed purchase recovery

On startup, `ClickerScreen._request_unprocessed_purchase_check_when_ready()` calls
`Platform.check_unprocessed_purchases()`. On Android this calls
`plugin.get_pending_purchases()`, which queries RuStore for unconsumed purchases.

For each found purchase, `unprocessed_purchase_found(product_id, purchase_token)` is
emitted. `ClickerScreen._on_unprocessed_purchase_found()` grants the reward and consumes.

This handles the recovery scenario: user paid, app crashed before consume, next launch
detects the dangling purchase and grants it.

---

## Completing the SDK integration

All SDK call sites in `AndroidRuStorePayPlugin.kt` are marked `// TODO: Replace`.
To complete integration:

1. **Obtain the RuStore Pay SDK AAR** from the official RuStore developer portal.
2. **Add the AAR or Maven coordinate** to `build.gradle`:
   - Local AAR: copy into `addons/android_rustore_pay/android/AndroidRuStorePayPlugin/libs/`
     and uncomment the `compileOnly fileTree(...)` line.
   - Maven: uncomment the `compileOnly 'ru.rustore.sdk:...'` line with the verified coordinate.
   - Also add the Maven repo to `build.gradle` → `repositories` and to
     `AndroidRuStorePayExportPlugin.gd` → `_get_android_maven_repos()` /
     `_get_android_dependencies()`.
3. **Fill in the three TODO stubs** in `AndroidRuStorePayPlugin.kt`:
   - `purchase(productId)` — call the SDK launch purchase method; emit `purchase_success`,
     `purchase_cancelled`, or `purchase_error` from the SDK callback.
   - `consume(purchaseToken)` — call the SDK consume/confirm method.
   - `get_pending_purchases()` — call the SDK getPurchases method; emit
     `pending_purchase_found` for each result, then `pending_purchases_check_completed`
     or `pending_purchases_check_error`.
4. **Rebuild the plugin AAR**:
   ```bash
   cp android/build/libs/release/godot-lib.template_release.aar \
      addons/android_rustore_pay/android/AndroidRuStorePayPlugin/libs/
   cd addons/android_rustore_pay/android/AndroidRuStorePayPlugin
   ./gradlew assembleRelease
   ```
5. **Update `rustore_product_id`** values in `GemPurchaseConfig.gd` to match
   the product ids registered in the RuStore developer console.
6. **Test all 4 gem purchase flows** on a real Android device via RuStore.

---

## Manual test checklist

- [ ] Purchase gems_25 — reward granted, consume called, re-purchase allowed
- [ ] Purchase gems_150 — reward granted, consume called, re-purchase allowed
- [ ] Purchase gems_500 — reward granted, consume called, re-purchase allowed
- [ ] Purchase gems_1500 — reward granted, consume called, re-purchase allowed
- [ ] Cancel purchase mid-flow — no reward, no stuck `_payment_in_progress` flag
- [ ] Purchase while payment in progress — second attempt rejected with error signal
- [ ] Crash after payment, before consume — recovery grants reward on next launch
- [ ] Duplicate purchase token — second grant blocked by `state.is_purchase_processed()`
- [ ] Network unavailable — clean error emitted, no crash, no stuck flag
- [ ] Web export unaffected — `YandexBridge` payment flow unchanged

---

## Logcat tags

```
adb logcat -s AndroidRuStorePay
```

| Log line | Meaning |
|---|---|
| `purchase called for productId=...` | Purchase initiated from GDScript |
| `RuStore Pay SDK not integrated` | Stub not yet replaced; expected before SDK wired |
| `consume called for purchaseToken=...` | Consume initiated after reward grant |
| `get_pending_purchases called` | Startup recovery check |

---

## Do NOT use BillingClient

RuStore BillingClient is the **deprecated** payments API. Use RuStore Pay SDK only.
The AGENTS.md payment rules forbid BillingClient for new payment work.
