# Y4 — Yandex Payments Catalog / Price Display

Implements the confirmed Y1 code gap: Web/Yandex showed a hardcoded RUB
`price_rub` instead of the real Yandex catalog price. Purchase, credit,
consume, and unprocessed-purchase recovery logic are unchanged.

## Checklist

- [x] `payments.getCatalog()` implemented — `YandexBridge.load_payment_catalog()`
  calls `ysdk.getPayments().then(p => p.getCatalog())`, sanitizes each entry
  to safe fields (`id`, `title`, `description`, `price`, `priceValue`,
  `priceCurrencyCode`, `priceCurrencyImage`), and forwards them to Godot via
  a JS callback (`_godot_payment_catalog_loaded`).
- [x] Catalog cache added — `YandexBridge._catalog_cache: Dictionary` keyed
  by Yandex product id, populated in `_on_js_payment_catalog_loaded()`.
  `get_cached_payment_catalog()` returns it directly; empty until the first
  successful load.
- [x] Local id → `yandex_product_id` → catalog product mapping documented
  and implemented — `YandexBridge.get_catalog_product(local_product_id)`
  resolves via `GemPurchaseConfig.get_platform_product_id(local_product_id,
  "yandex")`, then looks up `_catalog_cache`. Logs a debug-only warning
  (`BuildConfig.is_debug_features_enabled()`) if the resolved Yandex id has
  no cached catalog entry — this is the exact signal to look for if the
  Yandex draft product ids don't match `GemPurchaseConfig.gd`.
- [x] Web/Yandex price comes from catalog `price` — `GemPurchaseDialog`
  writes `catalog_product.get("price", "")` directly into the buy button
  label on Web.
- [x] Web/Yandex does not show hardcoded `price_rub` when a catalog product
  exists — `GemPurchaseDialog._initial_price_text()` shows a
  `shop.gem_purchase.loading_price` placeholder instead of `price_rub` on
  Web, and `_apply_catalog_prices()` never falls back to `price_rub` once
  the catalog resolves.
- [x] Missing product becomes unavailable — if
  `Platform.get_catalog_product(product_id)` is empty after the catalog
  loads, the cell shows `shop.gem_purchase.unavailable` (existing key,
  reused) and the buy button stays disabled.
- [x] Purchase is not started for a missing catalog product —
  `GemPurchaseDialog._on_buy_pressed()` checks
  `Platform.get_catalog_product(product_id).is_empty()` on Yandex before
  emitting `gem_product_purchase_requested`; shows
  `shop.gem_purchase.product_not_found` and logs a debug warning with both
  the local id and the resolved Yandex id instead. `_set_all_buy_buttons_disabled()`
  also refuses to re-enable a button for a missing catalog product after a
  purchase completes elsewhere, so the disabled state can't be bypassed by
  the existing enable/disable calls in `set_payment_done()` /
  `set_payment_failed()` / `show_dialog()`.
- [x] Purchase/credit/consume/recovery logic unchanged —
  `ClickerScreen.gd` was **not modified** by this patch.
  `_on_payment_purchase_success()`, `_on_payment_purchase_cancelled()`,
  `_on_payment_purchase_error()`, `_on_unprocessed_purchase_found()`,
  `state.grant_paid_gem_purchase()`, `state.is_purchase_processed()`, and
  all `Platform.consume_purchase()` call sites are byte-for-byte the same
  as before Y4. The catalog gate lives entirely in `GemPurchaseDialog`,
  one step upstream of `gem_product_purchase_requested` — if it doesn't
  fire, `ClickerScreen._on_gem_product_purchase_requested()` never runs.
- [x] Android/RuStore behavior unchanged — `AndroidRuStorePlatform.gd` gets
  no-op catalog methods (`load_payment_catalog()` emits an empty
  `payment_catalog_loaded([])`, `get_cached_payment_catalog()` /
  `get_catalog_product()` return `{}`). Since `GemPurchaseDialog` only takes
  the catalog code path when `Platform.get_platform_key() == "yandex"`,
  Android continues to show `price_rub` exactly as before, and
  `AndroidRuStorePlatform.purchase_product()` / `consume_purchase()` /
  `check_unprocessed_purchases()` were not touched.
- [x] Yandex draft product ids must match `GemPurchaseConfig.gd` — not
  verified in this patch (no access to the Yandex console). Flagged as an
  explicit manual step below; `get_catalog_product()`'s debug warning is the
  runtime signal for a mismatch.

## What changed

| File | Change |
|---|---|
| `scripts/platform/PlatformServices.gd` | Added `payment_catalog_loaded(products: Array)` / `payment_catalog_error(message: String)` signals and `load_payment_catalog()` / `get_cached_payment_catalog()` / `get_catalog_product(local_product_id)` base methods (all no-ops/empty by default). |
| `autoload/Platform.gd` | Re-declared the two signals, forwards them from both `YandexBridge` and generic `_impl` signal wiring, added the three delegating methods. |
| `autoload/YandexBridge.gd` | Real `payments.getCatalog()` call, JS callback wiring (`_setup_catalog_js_callbacks()`), `_catalog_cache`, `get_catalog_product()` id-mapping + debug warning. |
| `scripts/platform/WebYandexPlatform.gd` | Delegates all three catalog methods to `YandexBridge`. |
| `scripts/platform/AndroidRuStorePlatform.gd` | Empty/no-op catalog methods; RuStore has no equivalent catalog API yet. |
| `scripts/platform/LocalDebugPlatform.gd` | Debug-only catalog built from `GemPurchaseConfig.get_all()` prices, so local/editor testing has something to show. |
| `scenes/ui/GemPurchaseDialog.gd` | Catalog-aware price display, loading/unavailable/error states, catalog load-on-show, purchase-block for missing catalog products. |
| `localization/game_text.csv`, `scripts/ui/LocalizationData.gd` | Added `shop.gem_purchase.loading_price`, `shop.gem_purchase.catalog_error`, `shop.gem_purchase.product_not_found` (RU + EN). Reused the existing `shop.gem_purchase.unavailable` key for a missing catalog product rather than adding a duplicate. |

## Behavior by platform

- **Web/Yandex**: cells start showing "Loading price..."; on `show_dialog()`
  the catalog loads once (cached afterwards, no repeat network calls for the
  lifetime of the cache); each cell then shows the real
  `payments.getCatalog()` price string, or "Unavailable" + disabled button
  if that product id isn't in the Yandex draft catalog. Buying an
  unavailable product is blocked client-side before `Platform.purchase_product()`
  is ever called.
- **Android/RuStore**: no change. Cells show `price_rub` exactly as before
  Y4; `Platform.get_platform_key()` returns `"rustore"`, so `GemPurchaseDialog`
  never enters the Yandex catalog branch.
- **Editor/LocalDebug**: no change to the price display path (still
  `"debug"` platform key, not `"yandex"`); the new debug catalog methods
  exist for future testing but are not wired into `GemPurchaseDialog`'s
  branch condition, matching "keep debug behavior simple."

## Validation commands run

```bash
godot --headless --editor --quit
godot --headless --script res://scripts/tools/ValidateLocalizationDataFreshness.gd
godot --headless --script res://scripts/tools/ValidateLocalizationExport.gd
godot --headless --script res://scripts/tools/GenerateLocalizationData.gd
git status
git diff --stat
```

All passed. `GenerateLocalizationData.gd` was run because the CSV changed
(423 → 426 keys); `LocalizationData.gd` was regenerated and both validators
confirm it's in sync.

## Manual Yandex validation (not run — requires the Yandex console/preview)

1. Open the Yandex draft, confirm `gems_25`, `gems_150`, `gems_500`,
   `gems_1500` exist and are enabled.
2. Confirm product ids in the draft match `yandex_product_id` values in
   `GemPurchaseConfig.gd` exactly.
3. Build a Web export (`godot --headless --export-release "Web" …`).
4. Run it through the Yandex preview/debug panel, not `file://`.
5. Confirm `window.ysdk`/`window.ysdkReady` become true.
6. Open the gem purchase dialog — confirm prices come from the Yandex
   catalog (not `{price} ₽` placeholders).
7. If a product id is deliberately mismatched, confirm it shows
   "Unavailable" and cannot be bought.
8. Buy a product — confirm gems are credited exactly once.
9. Confirm the purchase is consumed after the reward is granted.
10. Reload the game — confirm no duplicate reward from the already-consumed
    purchase.
11. If possible, simulate an unprocessed purchase recovery — confirm it
    credits once and is consumed.
12. Confirm the Android/RuStore purchase flow is unaffected (separate build).

## Known follow-up

This patch does not touch:
- Yandex draft product enablement or pricing (console-side, Y5).
- `priceCurrencyImage` display (field is captured but not rendered — no UI
  requirement for it yet).
- A RuStore-side catalog/price API (RuStore has no public equivalent to
  `getCatalog()` today; Android keeps the `price_rub` placeholder).
