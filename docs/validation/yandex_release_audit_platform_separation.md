# Y1 — Yandex Release Audit and Platform Separation

Audit-only patch. No gameplay, balance, reward, price, or backend/API changes.
Documents current Web/Yandex runtime state and prepares the Y2–Y6 follow-up
sequence.

## 1. Platform selection

`autoload/Platform.gd` `_ready()`:

- `OS.has_feature("web")` → `WebYandexPlatform` (delegates to `YandexBridge`).
- `OS.has_feature("android")` → `AndroidRuStorePlatform`.
- else → `LocalDebugPlatform` (editor/desktop debug only).

Verified: Web never instantiates `AndroidRuStorePlatform`. The two impls are
mutually exclusive branches of the same `if/elif/else`.

**Status: OK, no change needed.**

## 2. SDK init / loader

`export_presets.cfg` → `[preset.0.options]` → `html/head_include` injects
`<script src="/sdk.js"></script>` followed by an inline script that calls
`YaGames.init()` on `window.load` and sets `window.ysdk` / `window.ysdkReady`.

`YandexBridge.gd`:
- `refresh_yandex_sdk_ready()` polls `window.ysdk` + `window.ysdkReady` before
  every SDK call (ads, payments, cloud, language).
- `game_ready()` retries (0.5s, up to 60 attempts) until the SDK is ready,
  then calls `ysdk.features.LoadingAPI.ready()`.
- `gameplay_start()` / `gameplay_stop()` call `ysdk.features.GameplayAPI.start()`
  / `.stop()`, also gated on SDK readiness.
- `Main.gd` calls `Platform.game_ready()` only after `ClickerScreen.startup_completed`
  fires (or immediately via `notify_yandex_game_ready()` if already complete) —
  UI is interactive before `LoadingAPI.ready()` is called, per Yandex Games
  requirements.

**Status: OK, no change needed.**

## 3. Language

`YandexBridge.get_yandex_language()` reads `ysdk.environment.i18n.lang`
(lowercased). `WebYandexPlatform.get_platform_language()` returns it directly.

`ClickerScreen._apply_startup_language()` (called from `_ready()`, line 211):
- Only overrides `state.language` if the player has **not** manually picked a
  language (`state.language_manually_selected == false`).
- Normalizes the platform language via `LocalizationManager.normalize_supported_language()`
  (fallback behavior for unsupported languages lives there).
- Calls `LocalizationManager.set_language(state.language)` unconditionally,
  applying the resolved language every startup.

**Status: automatic SDK language apply is already implemented.** The original
Y2 task ("Yandex SDK Language Auto-Apply") is **not needed** — this audit
found it already wired. No follow-up patch required unless testing on a real
Yandex Games session surfaces a normalization gap.

## 4. Saves

`YandexBridge`:
- `load_cloud_save()` → `ysdk.getPlayer({ scopes: false })` → `player.getData([save_v1])`.
- `save_cloud_save(data, flush)` → `player.setData(payload, flush)`, caches
  the resolved `player` object on `window._godot_yandex_player` to avoid
  repeated `getPlayer()` calls.
- Save key: `CLOUD_SAVE_KEY = "save_v1"` (stable constant).

`SaveManager.gd`:
- `load_cloud_data_async()` / `queue_cloud_save()` / `flush_cloud_save_now()`
  all route through `Platform.load_cloud_save()` / `Platform.save_cloud_save()`
  — platform-agnostic, resolves to `YandexBridge` on Web.
- `_send_cloud_save()` enforces `CLOUD_SAVE_MAX_BYTES = 200 * 1024` (200 KB)
  before calling `Platform.save_cloud_save()`, skipping with a warning if the
  payload is too large. This is under Yandex's documented `player.setData`
  limit.
- `queue_backend_cloud_save()` (Android backend account cloud) is hard-gated
  on `OS.has_feature("android")` as its first line — never reached on Web.
- `ClickerScreen._load_game_on_start_async()` calls both `SaveManager.load_data()`
  (local) and `SaveManager.load_cloud_data_async()` (Yandex on Web) and picks
  the newer one by `last_save_unix_time`. This runs for all platforms,
  including Web — Web save/load never touches the Android backend cloud path
  (`backend_load_save` / `backend_save_save` / `CloudRestorePrompt`), which
  are Android-account-only call sites elsewhere in `ClickerScreen.gd`.

**Status: OK, no change needed.** Y3 ("Yandex Save Authority") is **not
needed** as a code patch — the save authority logic described in the original
task is already in place. Recommend closing Y3 unless real-device Yandex
Games testing finds a startup load/autosave/flush gap.

## 5. Payments

`WebYandexPlatform.purchase_product()` → `YandexBridge.purchase_product()` →
`ysdk.getPayments()` → `payments.purchase({ id: yandexId })`.

- Product id source: `scripts/game/config/GemPurchaseConfig.gd` — each
  product has `id` (local), `yandex_product_id`, `rustore_product_id`. Today
  all three are identical per product (`gems_25`, `gems_150`, `gems_500`,
  `gems_1500`) — this is a **placeholder mapping**, not confirmed against the
  actual Yandex draft catalog.
- `ClickerScreen._on_gem_product_purchase_requested()` resolves the
  platform-specific id via `Platform.get_platform_key()` →
  `GemPurchaseConfig.get_platform_product_id(id, "yandex")` on Web.
- Crediting: `_on_payment_purchase_success()` guards against double-credit via
  `_payment_reward_granted_for_current_request` and
  `state.is_purchase_processed(purchase_token)` before calling
  `state.grant_paid_gem_purchase()`. Gems are credited exactly once per token.
- `Platform.consume_purchase(purchase_token)` is called immediately after
  crediting (both for a fresh purchase and for a recovered unprocessed one).
- `_request_unprocessed_purchase_check_when_ready()` calls
  `Platform.check_unprocessed_purchases()` once platform readiness is
  confirmed — recovered purchases go through
  `_on_unprocessed_purchase_found()`, which applies the same
  dedup-then-credit-then-consume sequence.
- Cancel (`_on_payment_purchase_cancelled`) and error
  (`_on_payment_purchase_error`) handlers never call `grant_paid_gem_purchase`
  — no gems are granted on cancel/error.
- Web never requires `Platform.backend_has_session()` for purchases —
  `_is_paid_shop_available()` returns `true` unconditionally off-Android (see
  `AGENTS.md` line ~934).

**Status: purchase/credit/consume/recovery logic is correct.** Gap: **product
id mapping is unverified against the real Yandex draft** (see §6).

## 6. Catalog / price display

- No call to `payments.getCatalog()` exists anywhere in the codebase
  (`YandexBridge.gd`, `WebYandexPlatform.gd`, `GemPurchaseDialog.gd`).
- `GemPurchaseDialog._create_product_cell()` renders the price from the
  hardcoded local field `price_rub` (e.g. `24`, `99`, `249`, `499`) via
  `shop.gem_purchase.price` format string — this is a **RUB-denominated
  placeholder price**, shown identically on Web and Android.
- This directly matches the prior moderation finding: *"portal currency / yans
  price display incorrect."* Yandex Games in-game currency purchases are
  billed in yans, and Yandex requires/expects the displayed price to reflect
  the actual catalog price returned by `payments.getCatalog()`, not a
  hardcoded RUB figure.

**Status: implemented by Y4.** See
`docs/validation/yandex_payments_catalog_price_display.md` for the full
implementation record. Summary: `YandexBridge.load_payment_catalog()` calls
`ysdk.getPayments().then(p => p.getCatalog())` and caches results by Yandex
product id; `Platform.get_catalog_product(local_product_id)` resolves
local → `yandex_product_id` → cached catalog entry;
`GemPurchaseDialog` shows the real catalog `price` on Web instead of
`price_rub`, shows a loading/unavailable/error state around the catalog
fetch, and blocks starting a purchase for a product missing from the
catalog. Android/RuStore and editor/debug price display are unchanged.
Remaining manual step: verify `yandex_product_id` values in
`GemPurchaseConfig.gd` against the real Yandex draft catalog (not possible
from code) — the debug build logs a warning if a product id resolves to no
catalog entry, which is the fastest way to catch a mismatch during preview
testing.

## 7. Ads

- Rewarded: `YandexBridge.show_rewarded_ad()` → `ysdk.adv.showRewardedVideo`
  with `onOpen`/`onRewarded`/`onClose`/`onError` callbacks wired via
  `JavaScriptBridge.create_callback`.
- Fullscreen: `YandexBridge.show_fullscreen_ad()` → `ysdk.adv.showFullscreenAdv`
  with the equivalent callback set.
- `ClickerScreen._on_rewarded_ad_opened()` / `_on_fullscreen_ad_opened()` both
  call `Platform.gameplay_stop()` (and pause audio/runtime) before/at ad open;
  `_on_*_ad_closed()` resumes.
- Reward is granted only in `_on_rewarded_ad_rewarded()` (the SDK's
  `onRewarded` callback), gated by
  `_rewarded_ad_reward_granted_for_current_request` — never granted on close
  alone. Cancelling/closing without a reward callback grants nothing.
- `is_ad_in_progress()` is checked before re-starting `GameplayAPI` elsewhere
  in the codebase (per `AGENTS.md`), avoiding an unsafe overlapping
  start/stop.

**Status: OK, no change needed. Rewards/pricing not touched, per task scope.**

## 8. Unprocessed purchases

`check_unprocessed_purchases()` (`YandexBridge.gd`) calls
`ysdk.getPayments().then(p => p.getPurchases())`, forwards each purchase to
`_godot_unprocessed_purchase_found`, and Web listens via
`Platform.unprocessed_purchase_found` →
`ClickerScreen._on_unprocessed_purchase_found()`. Triggered from
`_request_unprocessed_purchase_check_when_ready()`, called once platform
readiness is confirmed (with its own retry loop, independent of the SDK-ready
retry inside `YandexBridge`).

**Status: OK, no change needed.**

## 9. Android UI exclusion from Web

Confirmed via direct read of each gate:

| UI element | Gate | File |
|---|---|---|
| `AuthGateScreen` (startup) | `OS.has_feature("android")` | `scenes/main/Main.gd:30` |
| `AuthGateScreen` (overlay) | `OS.has_feature("android")` | `scenes/main/Main.gd:71` |
| Account button in Settings | `OS.has_feature("android")` | `scenes/ui/SettingsWindow.gd:294` |
| `AccountWindow` | only reachable via the Android-gated account button | `scenes/ui/SettingsWindow.gd` |
| Backend auto cloud upload | `OS.has_feature("android")` guard, first line | `autoload/SaveManager.gd:306` |
| Backend cloud-restore prompt / force-load | Android + `backend_has_session()` only | `scenes/game/ClickerScreen.gd` (per `AGENTS.md` §"Backend cloud-save is Android + account only") |
| Paid-shop account lock | Android-only (`_is_paid_shop_available()` returns `true` unconditionally off-Android) | `scenes/game/ClickerScreen.gd` |

Web/Yandex shows: normal game start (no AuthGate), Yandex cloud save,
Yandex payments (no account requirement), rewarded/fullscreen ads, normal
shop (never locked).

**Status: OK, no mismatch found.**

## 10. Moderation metadata / media checklist (console/media work, not code)

Non-code checklist to run against the Yandex Games developer console before
the next submission. None of this is solved by this patch.

- [ ] Game title is identical across: game name field, draft field, promo
      material captions, and any in-game title text/splash.
- [ ] Short description: within Yandex's field length limit, no banned
      formatting (no ALL CAPS spam, no emoji spam, no external links).
- [ ] Full description: within length limit, correctly formatted paragraphs,
      no HTML/markdown leaking through as literal text.
- [ ] RU fields are genuinely Russian (not machine-placeholder text).
- [ ] EN fields are genuinely English.
- [ ] Screenshots match the locale they're attached to (RU screenshots show
      RU UI text, EN screenshots show EN UI text).
- [ ] Promo images (icon, cover, banner) have **no rounded corners and no
      frame/border** baked into the image — Yandex adds its own chrome.
- [ ] Category/genre is set to `Казуальные` (Casual) in the draft, matching
      what the moderation note flagged, unless a deliberate category change
      was made and documented.
- [ ] In-app product ids in the Yandex draft match `yandex_product_id` values
      in `GemPurchaseConfig.gd` exactly (currently `gems_25`, `gems_150`,
      `gems_500`, `gems_1500`).
- [ ] Product prices/currency configured in the draft are what should be
      shown to players (drives the Y4 catalog price display work).
- [ ] All 4 products are enabled/published in the draft, not left in a draft
      or disabled state.
- [ ] Purchases are enabled in Partner/monetization settings for this game
      (this was previously reported as "purchases not found or not working").

## 11. Follow-up patch list (Y2–Y6)

- **Y2 — Yandex SDK Language Auto-Apply**: **not needed.** Already
  implemented (`ClickerScreen._apply_startup_language()`). Close unless
  real-device testing finds a gap.
- **Y3 — Yandex Save Authority**: **not needed.** Already implemented
  (`SaveManager` cloud/local merge by timestamp, 200 KB size guard, Android
  backend fully excluded). Close unless real-device testing finds a gap.
- **Y4 — Yandex Payments Catalog / Purchase / Consume**: **implemented.**
  See `docs/validation/yandex_payments_catalog_price_display.md`.
  `payments.getCatalog()` is wired, the hardcoded `price_rub` display on Web
  is replaced with the real catalog price, and missing catalog products are
  shown as unavailable with purchase blocked. Purchase/consume/credit logic
  was not touched. Remaining: verify `yandex_product_id` values against the
  real Yandex draft (console-side, not code).
- **Y5 — Metadata / Media Compliance**: **docs/checklist implemented by this
  patch.** See `docs/validation/yandex_submission_metadata_media_compliance.md`
  and the new `docs/yandex/` folder (`yandex_draft_metadata.md`,
  `yandex_submission_checklist.md`, `yandex_products_checklist.md`,
  `yandex_media_requirements.md`). The underlying console/media/manual work
  itself — filling the draft, exporting clean media, testing in the Yandex
  console — is still outstanding and cannot be completed from this
  repository; the docs prepare it but do not perform it.
- **Y6 — HTML Export Smoke Pass**: needed. Manual verification pass per the
  checklist in §12 below, using a real `godot --headless --export-release
  "Web" …` build served over HTTP (not `file://`) and, ideally, uploaded to
  the Yandex Games test/preview cabinet where `window.ysdk` is genuinely
  available.

## 12. Validation commands run

```bash
godot --headless --editor --quit
godot --headless --script res://scripts/tools/ValidateLocalizationDataFreshness.gd
godot --headless --script res://scripts/tools/ValidateLocalizationExport.gd
git status
git diff --stat
```

No localization keys were changed by this patch, so
`GenerateLocalizationData.gd` was not run.

### Manual / console validation checklist (for Y5/Y6, not run in this patch)

1. Open Yandex draft — confirm game title consistency.
2. Confirm category is `Казуальные`.
3. Confirm RU fields are Russian, EN fields are English.
4. Confirm screenshots have correct language per locale.
5. Confirm promo materials have no rounded corners or frames.
6. Confirm in-app products exist in the Yandex draft and match
   `yandex_product_id` values.
7. Confirm purchases are enabled in monetization/partner settings.
8. Run an HTML build with the Yandex debug panel / preview cabinet.
9. Confirm SDK loader state (`window.ysdk`, `window.ysdkReady`).
10. Confirm language comes from the SDK (`ysdk.environment.i18n.lang`).
11. Confirm Yandex save loads/saves (`player.getData`/`setData`).
12. Confirm rewarded ads work end-to-end.
13. Confirm purchases succeed or clearly report the catalog/product issue
    (expected until Y4 lands).

## 13. Files inspected (no changes made to any of these)

`autoload/Platform.gd`, `autoload/YandexBridge.gd`,
`scripts/platform/WebYandexPlatform.gd`,
`scripts/platform/AndroidRuStorePlatform.gd`,
`scripts/platform/LocalDebugPlatform.gd`,
`scripts/platform/PlatformServices.gd`, `scenes/main/Main.gd`,
`scenes/auth/AuthGateScreen.gd` (referenced, not opened in full — gating
confirmed via `Main.gd`), `scenes/game/ClickerScreen.gd`,
`scenes/ui/AccountWindow.gd` (referenced), `scenes/ui/SettingsWindow.gd`,
`scenes/ui/GemPurchaseDialog.gd`, `scripts/game/config/GemPurchaseConfig.gd`,
`scripts/game/config/ShopConfig.gd` (referenced, not directly relevant to
payments), `autoload/SaveManager.gd`, `export_presets.cfg`, `README.md`,
`AGENTS.md`, `docs/validation/` (existing docs cross-checked for prior
Android/backend separation rules).

## 14. Summary

No code was changed by this audit patch. Findings:

- Platform selection, SDK init/loader, language auto-apply, save authority,
  purchase credit/consume/recovery, ads, and Android UI exclusion from Web
  are **all already correctly implemented and separated**.
- The one confirmed **code gap** was the hardcoded RUB price display instead
  of a Yandex catalog-driven price (§6) — this matched the prior moderation
  complaint about incorrect portal currency/yans display. **Implemented by
  Y4** — see `docs/validation/yandex_payments_catalog_price_display.md`.
- The remaining prior moderation issues (title consistency, description
  formatting, translated fields, screenshot locale, promo image chrome,
  category, product/purchase enablement) are **console/media work**, not
  code — checklist captured in §10, and now formalized under `docs/yandex/`
  by **Y5**.
- Y2 and Y3 as originally scoped turned out to already be implemented; this
  audit recommends closing them rather than re-doing the work.
- **Y4 is implemented.** **Y5's code/docs side is implemented** (this
  update) — see `docs/validation/yandex_submission_metadata_media_compliance.md`.
  The manual console/media work Y5 prepares for is still outstanding.
  Remaining step in the sequence: **Y6** (HTML export smoke pass).
