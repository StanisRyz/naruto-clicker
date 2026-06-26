# RuStore Pay Integration Guide

## Overview

In-app purchases on Android use the **official RuStore Godot Pay SDK**
(`addons/RuStoreGodotPay/`) via the `RuStoreGodotPayClient` GDScript wrapper.

The old custom `AndroidRuStorePay` adapter (`addons/android_rustore_pay/`) is
**deprecated** and no longer used for payments. It must not be re-enabled in
`project.godot`.

---

## SDK addon locations

```
addons/RuStoreGodotCore/
  RuStoreGodotCore.gd         ← RuStoreGodotCoreUtils (singleton wrapper)
  plugin.cfg                  ← enabled in project.godot [editor_plugins]

addons/RuStoreGodotPay/
  RuStoreGodotPay.gd          ← RuStoreGodotPayClient (main payment client)
  plugin.cfg                  ← enabled in project.godot [editor_plugins]
  ERuStorePayPreferredPurchaseType.gd
  ERuStorePaySdkTheme.gd
  ERuStorePayProductType.gd
  ERuStorePayPurchaseStatusFilter.gd
  RuStorePayProductPurchaseParams.gd
  RuStorePayProductPurchaseResult.gd
  RuStorePayProductPurchase.gd
  RuStorePayJsonParser.gd
  ... (other data classes)
```

## Singleton names (Android native side)

```
Engine.get_singleton("RuStoreGodotPay")   — payment operations
Engine.get_singleton("RuStoreGodotCore")  — core utilities
```

Both are checked before `RuStoreGodotPayClient.get_instance()` is called.
`AndroidRuStorePlatform._create_rustore_pay_client()` guards with:

```gdscript
if not OS.has_feature("android"):    return null
if not Engine.has_singleton("RuStoreGodotPay"):  return null
if not Engine.has_singleton("RuStoreGodotCore"): return null
return RuStoreGodotPayClient.get_instance()
```

---

## Android build template files (tracked in Git)

The Android build template is now tracked selectively. Generated/cache directories
and all secrets remain ignored. The following source files are committed:

| File | Purpose |
|---|---|
| `android/build/AndroidManifest.xml` | App manifest — contains RuStore Pay metadata and deeplink activity |
| `android/build/res/values/rustore_values.xml` | RuStore Pay SDK strings (consoleApplicationId, internalConfigKey, deeplinkScheme) |
| `android/build/src/com/godot/game/RuStoreIntentFilterActivity.java` | Deeplink trampoline activity for RuStore Pay |

**`rustore_values.xml`** defines three required string resources:
```xml
<resources>
    <string name="rustore_PayClientSettings_consoleApplicationId" translatable="false">2063726878</string>
    <string name="rustore_PayClientSettings_internalConfigKey" translatable="false">godot</string>
    <string name="rustore_PayClientSettings_deeplinkScheme" translatable="false">shinobiclickeridle</string>
</resources>
```

**`AndroidManifest.xml`** contains the three RuStore Pay `<meta-data>` entries and
the `RuStoreIntentFilterActivity` declaration inside `<application>`.

**`RuStoreIntentFilterActivity`** is a transparent trampoline: it catches the
`shinobiclickeridle://` deeplink from RuStore Pay, forwards the intent to `GodotApp`
with `FLAG_ACTIVITY_SINGLE_TOP`, and finishes immediately. `GodotActivity.onNewIntent`
picks up the intent and the RuStore Pay SDK processes the payment result.

**Still ignored** (secrets / generated outputs):
- `android/build/local.properties`, `android/local.properties` — signing secrets
- `android/build/build/`, `android/.gradle/`, `android/build/.gradle/` — Gradle cache/output
- `*.jks`, `*.keystore`, `*.p12`, `*.apk`, `*.aab` — signing keys and build artifacts

---

## Product id mapping

Product ids are configured in `scripts/game/config/GemPurchaseConfig.gd`.
Each product has a `rustore_product_id` field.

```gdscript
GemPurchaseConfig.get_platform_product_id(local_id, "rustore")
```

Update `rustore_product_id` values to match the exact ids registered in the
RuStore developer console before publishing.

---

## Purchase flow

```
ClickerScreen             Platform           AndroidRuStorePlatform     RuStoreGodotPayClient
     │                        │                        │                         │
     │  purchase_product(id)  │                        │                         │
     │───────────────────────▶│                        │                         │
     │                        │  purchase_product(id)  │                         │
     │                        │───────────────────────▶│                         │
     │                        │                        │  get_purchase_availability()
     │                        │                        │────────────────────────▶│
     │                        │                        │  on_get_purchase_availability_success
     │                        │                        │◀────────────────────────│
     │                        │                        │  [if isAvailable=true]  │
     │                        │                        │  client.purchase(params)│
     │                        │                        │────────────────────────▶│
     │                        │                        │                         │ (RuStore UI)
     │                        │                        │  on_purchase_success    │
     │                        │  payment_purchase_success◀──────────────────────│
     │◀───────────────────────│                        │                         │
     │  grant gems + save     │                        │                         │
     │  Platform.consume()    │  no-op (ONE_STEP)      │                         │
```

Key invariants:
- Rewards are granted only in `ClickerScreen._on_payment_purchase_success()`.
- `state.mark_purchase_processed(purchase_id)` is called before `consume_purchase()`.
- `state.is_purchase_processed(purchase_id)` guards against duplicate grants.
- `_payment_in_progress` flag prevents overlapping purchase attempts.
- Empty `platform_product_id` is rejected before the flag is set.
- `on_purchase_success` result with all-empty ids is rejected — no reward granted.
- `_pay_client.purchase()` is **never** called unless availability is explicitly `true`.

---

## Purchase availability preflight

Before calling `_pay_client.purchase()`, `AndroidRuStorePlatform` calls
`_pay_client.get_purchase_availability()` and waits for one of two signals:

| Signal | Handler | Outcome |
|---|---|---|
| `on_get_purchase_availability_success` | `_on_rustore_get_purchase_availability_success` | calls `_start_rustore_purchase_after_availability()` only if `result.isAvailable == true` |
| `on_get_purchase_availability_failure` | `_on_rustore_get_purchase_availability_failure` | clears state, emits `payment_purchase_error` |

**Why this is required:**

The official RuStore Godot Pay Android plugin crashes with
`java.lang.IllegalArgumentException: Invalid type for argument #0. Should be of type java.lang.String`
when `purchase()` is called and the SDK emits a failure signal on sideloaded or
test builds where RuStore payments are unavailable. This crash occurs inside the
plugin JNI layer (`RuStoreGodotPay.purchase$lambda$15`) before our GDScript
`_on_rustore_purchase_failure` handler can recover.

By gating `purchase()` behind a successful availability check, the SDK failure
path is never reached when payments are not available.

**`RuStorePayGetPurchaseAvailabilityResult` fields used:**
- `isAvailable: bool` — set directly from JSON `obj["isAvailable"]`
- `cause: RuStoreError` — present when `isAvailable == false`; its `description` or
  `name` field is used as the error message

If the result object is `null` (parse error), the system fails closed: no
purchase is attempted and `payment_purchase_error` is emitted.

**`_start_rustore_purchase_after_availability()` helper:**

Called only when `isAvailable == true`. Reads `_pending_platform_product_id`,
builds `RuStorePayProductPurchaseParams`, and calls `_pay_client.purchase()` with
`ONE_STEP`, `DARK` theme, and `enable_purchase_event_listener = true`.

---

## Purchase parameters

```gdscript
var params := RuStorePayProductPurchaseParams.new(
    RuStorePayProductId.new(platform_product_id)
)

_pay_client.purchase(
    params,
    ERuStorePayPreferredPurchaseType.Item.ONE_STEP,
    ERuStorePaySdkTheme.Item.DARK,
    true  # enable_purchase_event_listener — required for on_payment_failed / on_payment_completed
)
```

Purchase type `ONE_STEP` is used for consumable products. The SDK automatically
confirms the purchase; no explicit consume/confirm call is needed afterward.
`RuStorePayProductPurchaseParams._init()` requires `productId` as its first
positional argument — property assignment after `new()` is incorrect.

`enable_purchase_event_listener = true` enables the payment event listener callbacks:
`on_payment_started`, `on_purchase_created`, `on_payment_completed`, `on_payment_failed`,
and `on_purchase_cancelled`. Without this flag those signals are not emitted, which
leaves the `_payment_in_progress` flag stuck when the RuStore UI shows a generic
error such as "Payment does not work. Try again later."

---

## Purchase id extraction

`on_purchase_success` emits a `RuStorePayProductPurchaseResult` object.
The id is extracted with this preferred order:

1. `result.purchaseId.value` — if non-null and non-empty
2. `result.orderId.value` — if non-null and non-empty
3. `result.invoiceId.value` — if non-null and non-empty

If all three are empty, the success is treated as an error and no reward is
granted. This is implemented in
`AndroidRuStorePlatform._extract_purchase_id_from_result()`.

The same preferred order is applied when extracting ids from
`RuStorePayProductPurchase` objects returned by `get_purchases()`.

---

## Consume behavior

`ONE_STEP` consumables are auto-confirmed by the RuStore Pay SDK. There is no
separate consume or confirm API call for this purchase type.
`AndroidRuStorePlatform.consume_purchase()` is a safe no-op; it exists to
satisfy the `PlatformServices` interface and for symmetry with the Yandex
payment path.

`confirm_two_step_purchase()` and `cancel_two_step_purchase()` are only relevant
for TWO_STEP purchase flows. The current implementation does not use TWO_STEP
and does not call either method.

Rewards are granted only in `ClickerScreen._on_payment_purchase_success()`, which
fires after `payment_purchase_success` is emitted with a non-empty purchase id.
No separate confirm step occurs after reward grant.

---

## Unprocessed purchase recovery

On startup, `ClickerScreen._request_unprocessed_purchase_check_when_ready()`
calls `Platform.check_unprocessed_purchases()`. On Android this calls:

```gdscript
_pay_client.get_purchases(
    ERuStorePayProductType.Item.CONSUMABLE_PRODUCT,
    ERuStorePayPurchaseStatusFilter.Item.CONFIRMED
)
```

For each `RuStorePayProductPurchase` in the result:
1. Extract `productId.value` → look up local id via `GemPurchaseConfig`.
2. Extract purchase id (same preferred order as success path).
3. Skip if unknown product id or empty purchase id.
4. Emit `unprocessed_purchase_found(local_id, purchase_id)`.
5. After loop emit `unprocessed_purchase_check_completed()`.

`ClickerScreen._on_unprocessed_purchase_found()` checks
`state.is_purchase_processed(purchase_id)` before granting.
Already-processed purchases are skipped silently.

On failure, `unprocessed_purchase_check_error(message)` is emitted — the
startup flow continues without crashing.

---

## Signals connected in AndroidRuStorePlatform

| SDK signal | Handler | Notes |
|---|---|---|
| `on_get_purchase_availability_success(result)` | `_on_rustore_get_purchase_availability_success` | Availability preflight — calls `_start_rustore_purchase_after_availability()` only if `isAvailable == true` |
| `on_get_purchase_availability_failure(error)` | `_on_rustore_get_purchase_availability_failure` | Availability preflight failed — clears state, emits error |
| `on_purchase_success(result)` | `_on_rustore_purchase_success` | Primary ONE_STEP success path |
| `on_purchase_failure(product_id, error)` | `_on_rustore_purchase_failure` | SDK-level error |
| `on_purchase_cancelled(product_id, purchase_id, invoice_id)` | `_on_rustore_purchase_cancelled` | User cancelled in RuStore UI |
| `on_payment_completed(product_id, purchase_id, invoice_id)` | `_on_rustore_payment_completed` | Success fallback from event listener |
| `on_payment_failed(product_id, purchase_id, invoice_id)` | `_on_rustore_payment_failed` | Terminal error from event listener (e.g. "Payment does not work") |
| `on_payment_started(product_id, purchase_id, invoice_id)` | `_on_rustore_payment_started` | Log-only; does not clear state |
| `on_purchase_created(product_id, purchase_id, invoice_id)` | `_on_rustore_purchase_created` | Log-only; does not clear state |
| `on_get_purchases_success(purchases)` | `_on_rustore_get_purchases_success` | Startup recovery check |
| `on_get_purchases_failure(error)` | `_on_rustore_get_purchases_failure` | Startup recovery check error |

All terminal handlers (`on_purchase_success`, `on_purchase_failure`,
`on_purchase_cancelled`, `on_payment_completed`, `on_payment_failed`) use the
shared `_consume_pending_payment_local_id()` helper as a dedup gate: it returns
`""` if `_payment_in_progress` is already false, so duplicate events are ignored
regardless of which signal fires first.

Old custom signals (`purchase_success`, `purchase_cancelled`, `purchase_error`,
`pending_purchase_found`, `pending_purchases_check_completed`,
`pending_purchases_check_error`) belonged to the deprecated `AndroidRuStorePay`
adapter and are no longer used.

---

## Terminal event behavior

| Event | Reward granted | Game pause cleared | `_payment_in_progress` cleared |
|---|---|---|---|
| `on_purchase_success` with non-empty id | ✅ Yes | ✅ Yes | ✅ Yes |
| `on_purchase_success` with empty id | ❌ No (error emitted) | ✅ Yes | ✅ Yes |
| `on_purchase_failure` | ❌ No | ✅ Yes | ✅ Yes |
| `on_purchase_cancelled` | ❌ No | ✅ Yes | ✅ Yes |
| `on_payment_failed` | ❌ No | ✅ Yes | ✅ Yes |
| `on_payment_completed` with non-empty id | ✅ Yes | ✅ Yes | ✅ Yes |
| `on_payment_completed` with empty id | ❌ No (error emitted) | ✅ Yes | ✅ Yes |
| `on_payment_started` | ❌ No | ❌ No (intentional) | ❌ No (intentional) |
| `on_purchase_created` | ❌ No | ❌ No (intentional) | ❌ No (intentional) |

---

## Manual test checklist

- [ ] Purchase gems_25 — reward granted, re-purchase allowed after successful ONE_STEP purchase flow
- [ ] Purchase gems_150 — reward granted, re-purchase allowed after successful ONE_STEP purchase flow
- [ ] Purchase gems_500 — reward granted, re-purchase allowed after successful ONE_STEP purchase flow
- [ ] Purchase gems_1500 — reward granted, re-purchase allowed after successful ONE_STEP purchase flow
- [ ] Cancel purchase mid-flow — no reward, dialog buy button re-enabled, gameplay unpaused
- [ ] RuStore shows "Payment does not work" — no reward, dialog buy button re-enabled, gameplay unpaused
- [ ] Purchase while payment in progress — second attempt rejected with error signal
- [ ] Crash after payment, before reward grant — recovery grants reward on next launch
- [ ] Duplicate purchase id — second grant blocked by `state.is_purchase_processed()`
- [ ] Network unavailable — clean error emitted, no crash, no stuck flag
- [ ] Web export unaffected — `YandexBridge` payment flow unchanged

---

## Logcat tags

```
adb logcat -s RuStoreGodotPay RuStoreGodotCore
```

---

## Do NOT use BillingClient

RuStore BillingClient is the **deprecated** payments API. Use RuStore Pay SDK
(`RuStoreGodotPayClient`) only. The AGENTS.md payment rules forbid BillingClient.
