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

## Required local Android configuration

Because `/android/` is in `.gitignore`, these files are **never committed**.
Each developer must configure them locally before building a payment-enabled APK:

1. **`android/build/res/values/rustore_values.xml`** — Application ID:
   ```xml
   <resources>
       <string name="rustore_application_id">YOUR_APP_ID</string>
   </resources>
   ```
2. **`android/build/AndroidManifest.xml`** — RuStore metadata entry and
   `RuStoreIntentFilterActivity` declaration per official RuStore Godot Pay docs.

See the [official RuStore Godot Pay documentation](https://www.rustore.ru/help/sdk/godot-pay)
for the exact manifest entries and intent filter activity required.

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

---

## Purchase parameters

```gdscript
var params := RuStorePayProductPurchaseParams.new()
params.productId = RuStorePayProductId.new(platform_product_id)

_pay_client.purchase(
    params,
    ERuStorePayPreferredPurchaseType.Item.ONE_STEP,
    ERuStorePaySdkTheme.Item.DARK,
    false  # enable_purchase_event_listener
)
```

Purchase type `ONE_STEP` is used for consumable products. The SDK automatically
confirms the purchase; no explicit consume/confirm call is needed afterward.

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

| SDK signal | Handler |
|---|---|
| `on_purchase_success(result)` | `_on_rustore_purchase_success` |
| `on_purchase_failure(product_id, error)` | `_on_rustore_purchase_failure` |
| `on_purchase_cancelled(product_id, purchase_id, invoice_id)` | `_on_rustore_purchase_cancelled` |
| `on_get_purchases_success(purchases)` | `_on_rustore_get_purchases_success` |
| `on_get_purchases_failure(error)` | `_on_rustore_get_purchases_failure` |

Old custom signals (`purchase_success`, `purchase_cancelled`, `purchase_error`,
`pending_purchase_found`, `pending_purchases_check_completed`,
`pending_purchases_check_error`) belonged to the deprecated `AndroidRuStorePay`
adapter and are no longer used.

---

## Manual test checklist

- [ ] Purchase gems_25 — reward granted, re-purchase allowed after confirm
- [ ] Purchase gems_150 — reward granted, re-purchase allowed after confirm
- [ ] Purchase gems_500 — reward granted, re-purchase allowed after confirm
- [ ] Purchase gems_1500 — reward granted, re-purchase allowed after confirm
- [ ] Cancel purchase mid-flow — no reward, no stuck `_payment_in_progress` flag
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
