# Yandex Products Checklist

Per-product verification checklist for the 4 gem products defined in
`scripts/game/config/GemPurchaseConfig.gd`. Product ids, rewards, and prices
are **not changed by this doc** — this is a verification checklist only.

## Current code-side product ids

| Local id | `yandex_product_id` | Gems | `price_rub` (reference/local fallback) |
|---|---|---|---|
| `gems_25` | `gems_25` | +25 | 24 |
| `gems_150` | `gems_150` | +150 (100 base + 50 bonus) | 99 |
| `gems_500` | `gems_500` | +500 (250 base + 250 bonus) | 249 |
| `gems_1500` | `gems_1500` | +1500 (500 base + 1000 bonus) | 499 |

`price_rub` is the local fallback used for the loading state and for
Android/RuStore/editor display (see Y4:
`docs/validation/yandex_payments_catalog_price_display.md`). It is **not**
what Web/Yandex players see once the catalog loads — the real price on Web
comes from `payments.getCatalog()`.

## Per-product checklist (repeat for each of the 4 products)

For `gems_25`:
- [ ] Product exists in the Yandex draft.
- [ ] Product id in the draft is exactly `gems_25` (case-sensitive, no
      extra whitespace).
- [ ] Product is enabled/published in the draft (not left disabled).
- [ ] Price is configured in the Yandex console.
- [ ] Product appears in `payments.getCatalog()` when tested in the Yandex
      preview (confirm via the debug warning path below, or by opening the
      gem shop dialog on Web and checking the price is not stuck on
      "Loading price...").
- [ ] Product can be purchased in preview.
- [ ] Gems are credited exactly once per purchase.
- [ ] Purchase is consumed after the reward is granted (confirmed no
      duplicate reward on reload).

For `gems_150`: same 8 checks as `gems_25`, substituting `gems_150`.

For `gems_500`: same 8 checks as `gems_25`, substituting `gems_500`.

For `gems_1500`: same 8 checks as `gems_25`, substituting `gems_1500`.

## Warning — missing catalog product

If a product id in `GemPurchaseConfig.gd` does not match the Yandex draft's
product id exactly, Y4's catalog integration makes that product show as
**unavailable** in `GemPurchaseDialog` and **blocks the purchase** before
`Platform.purchase_product()` is ever called — the player cannot buy it, and
no error is silently swallowed into a broken payment flow.

To find a mismatch quickly: run a debug build
(`BuildConfig.is_debug_features_enabled()` true) and open the gem shop on
Web. `YandexBridge.get_catalog_product()` logs:

```
YandexBridge: catalog product missing for local='<local_id>' yandex_id='<resolved_yandex_id>'
```

for any local id whose resolved `yandex_product_id` isn't in the loaded
catalog. Fix by either correcting `yandex_product_id` in
`GemPurchaseConfig.gd` to match the real draft id, or correcting the
product id in the Yandex draft to match the config — whichever is wrong.

## Not covered here

Creating, enabling, or pricing products in the Yandex console is a manual
action and cannot be done from this repository.
