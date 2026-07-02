# AGENTS.md

Development rules for AI coding agents working on this repository.

## Project rules

- This is a Godot 4.5.1 Web/Yandex Games idle clicker, final release-candidate / pre-publication stage.
- Preserve current architecture.
- Do not make broad rewrites.
- Prefer small focused patches.
- Do not change balance unless explicitly requested.
- Do not modify `BalanceAuditReport.gd` unless explicitly requested.
- Do not add new gameplay systems during release-candidate cleanup unless explicitly requested.
- Config files must contain only static data — no runtime player state, no SaveManager calls, no scene references.
- Pure formula logic lives in `scripts/game/calculators/`; save serialization in `scripts/game/save/`; UI formatting in `scripts/game/presentation/`.

## QoL work rules

The project is at final release-candidate stage. Future tasks must:

- Focus on QoL improvements, polish, and moderation/release blocking fixes only.
- Not introduce new major mechanics unless explicitly requested by the user.
- Not change balance constants unless explicitly requested.
- Keep patches small and individually testable.
- Avoid broad refactors or architectural changes unless fixing a specific bug that requires them.

## Localization rules

- All player-visible text must be in `res://localization/game_text.csv`.
- Use `LocalizationManager.tr_key()` or `LocalizationManager.format_key()`.
- Do not hardcode visible English/Russian text in `.gd` or `.tscn` files.
- After changing `game_text.csv`, commit both the CSV and the regenerated `LocalizationData.gd`.
- Validate before export:
  ```
  godot --headless --script res://scripts/tools/ValidateLocalizationDataFreshness.gd
  godot --headless --script res://scripts/tools/ValidateLocalizationExport.gd
  ```

## UI rules

- Two layout targets: Android/default = 720×1600 (9:20); Web/Yandex = 720×1280 (9:16).
- The Web viewport is set via the Godot 4 feature-tag override `window/size/viewport_height.web=1280`
  in `project.godot`. Android and the editor use the default 1600 value. No runtime code involved.
- Use `canvas_items` stretch mode + `keep` aspect + `fractional` scale.
- Do not switch back to `viewport` stretch mode — it makes assets pixelated on high-DPI devices.
- Do not use `expand` or `ignore` aspect unless explicitly requested.
- UI must keep proportions at all supported window sizes.
- Touch scrolling inside card lists must work by dragging over cards, not only scrollbars.
- Control-based UI only; prefer containers and anchors over Node2D positioning.
- Bottom-anchored nodes (BottomBar, BottomTabsBackdrop, bottom sheets) adjust automatically
  to the shorter Web viewport — do not add per-platform offset hacks.
- Background ImageSlot uses `stretch_mode = STRETCH_KEEP_ASPECT_COVERED` — vertical crop is
  acceptable and expected on the 9:16 Web layout.
- **Fixed-size textured windows must not dynamically resize to fit content (C7.2.6).**
  Popups/windows/cards with an `ImageSlot`-based background (`SettingsWindow`,
  `AccountWindow` (C7.3.2), `ShopSheet`, `ShopPanel` cards, `GemPurchaseDialog`,
  `ShopPurchaseConfirmDialog`, `PrestigeConfirmDialog`, skill popups,
  `TasksWindow`, etc.) must keep their existing fixed `custom_minimum_size` /
  anchor offsets whenever possible. Do not let a `PanelContainer`/`VBoxContainer`
  grow the outer window based on how much text or how many controls are inside
  it — new content must fit via shorter text, smaller spacing, a smaller (but
  still safe) local font size, hiding optional controls, or an existing/added
  internal `ScrollContainer`, in that preference order.
- **If a fixed textured window must actually be resized, resize width and
  height proportionally by the same scale factor (C7.2.6).** Preserve the
  aspect ratio and texture proportions — never change only one axis (e.g. only
  `offset_top`/`offset_bottom` without a matching width change). Document the
  old size, new size, and scale factor in the PR/validation doc.
- **`SettingsWindow` example — content overflow must be handled via internal
  scrolling, not by resizing the panel (C7.2.7).** The Account/Cloud section
  used to make `SettingsWindow` non-proportionally taller
  (`offset_top`/`offset_bottom` override) when created on Android — this was a
  known bug, not a pattern to copy. It was fixed by keeping the outer
  `PanelContainer` fixed at `Vector2(540, 525)` on every platform and adding an
  internal `BodyScrollContainer`/`BodyVBoxContainer` (everything below the
  header scrolls) — see
  `docs/validation/settings_window_fixed_aspect_ratio_cleanup.md`. Any future
  `SettingsWindow` content addition must go inside `BodyVBoxContainer`
  (`SettingsWindow.BODY_PATH`), never resize `panel_container` directly.
- **Settings/Shop UI regression or sizing patches must not change backend/cloud/
  payment/gameplay logic (C7.2.6).** Audits, text tweaks, and layout fixes in
  `SettingsWindow`, `ShopSheet`/`ShopPanel`, or related popups must not alter
  `SaveManager`, backend Cloud Functions, backend API paths, Guest → Login/
  Register logic, `CloudRestorePrompt` logic, paid shop lock logic, payment/
  RuStore flow, rewarded ads, or gameplay balance.

## Payment rules (all platforms)

- **Never grant paid rewards without a non-empty purchase id / order id.** An
  empty string must be rejected at the earliest check.
- **Paid purchase ids must be persisted.** Use `state.is_purchase_processed(id)`
  and `state.mark_purchase_processed(id)`. These write to
  `ClickerState.processed_purchase_ids`, which is saved in every game save and
  never cleared by prestige or reset.
- Do not rely on the runtime-only deduplication that existed before this version.
  Always go through `ClickerState` for dedup checks.
- Real RuStore Pay SDK calls must live **only in `AndroidRuStorePlatform.gd`**.
  Gameplay and UI code must call `Platform.purchase_product()`.
- Do not use the deprecated RuStore BillingClient for new payment work. Use
  RuStore Pay SDK (the newer product-based payments API) when integrating.
- Platform product id resolution goes through
  `GemPurchaseConfig.get_platform_product_id(local_id, Platform.get_platform_key())`.
  Do not hardcode `yandex_product_id` in gameplay code.
- `consume_purchase()` behavior differs by platform (Yandex token vs RuStore
  order id). Always call `Platform.consume_purchase()` after granting; each
  platform impl handles its own semantics.

## Platform abstraction rules

- All gameplay and UI code must call `Platform` (the autoload), **never**
  `YandexBridge` directly. `YandexBridge` is an internal implementation detail
  used only by `WebYandexPlatform`.
- Do not remove or weaken existing Web/Yandex behavior while preparing Android
  or RuStore integration. Web and Android implementations are independent.
- The four platform scripts live in `res://scripts/platform/`:
  - `PlatformServices.gd` — base interface (signals + method stubs)
  - `WebYandexPlatform.gd` — delegates to `YandexBridge`
  - `AndroidRuStorePlatform.gd` — safe Android placeholder
  - `LocalDebugPlatform.gd` — editor/debug simulation
- `Platform.gd` (`res://autoload/Platform.gd`) selects the implementation and
  re-exposes all signals. It is loaded after `YandexBridge` and before
  `SaveManager` in `project.godot`.
- New ad, payment, or cloud-save integrations must be added as methods in
  `PlatformServices.gd` first, then implemented per-platform.

## Yandex lifecycle / runtime pause rules

- `LoadingAPI.ready()` is called only after `ClickerScreen.startup_completed` fires.
- `Main.gd` must **not** call `YandexBridge.gameplay_start()` directly. Initial game-ready
  flow goes through `ClickerScreen.notify_yandex_game_ready()`, which calls `game_ready()`
  then `_try_resume_yandex_gameplay()`.
- `GameplayAPI.start()` must only be called through `_try_resume_yandex_gameplay()`, which
  verifies `_is_initialized`, all runtime pause reasons are clear, and no ad is in progress.
- `GameplayAPI.stop()` must be paired with adding a runtime pause reason
  (`_set_runtime_pause_reason(reason, true)`).
- Handle `game_api_pause` / `game_api_resume` platform signals via
  `_on_yandex_platform_pause_requested()` / `_on_yandex_platform_resume_requested()`.
- Runtime pause stops: boss timer, ability timers and cooldowns, fullscreen ad cooldown,
  autoclick accumulator, partner DPS accumulator, enemy transition waits
  (`_wait_runtime_seconds`), and manual attacks.
- Page visibility (`visibilitychange` / `pagehide` / `pageshow`) sets the `hidden` pause
  reason and is handled by `AudioManager`.

## Ads rules

- Rewarded rewards must be granted only in the `onRewarded` / `rewarded_ad_rewarded` callback.
- `onClose` without prior reward grants nothing.
- `onError` grants nothing.
- Protect against duplicate reward grants for the same ad view.
- Floating rewarded banner, shop rewarded gems, and offline ×3 use separate request contexts.
- Audio must pause during rewarded and fullscreen ads and resume after close/error when the page is visible.
- Before showing any rewarded or fullscreen ad: add the relevant runtime pause reason,
  call `AudioManager.pause_for_ad()`, call `GameplayAPI.stop()`.
- On ad close/error: clear the pause reason and call `_try_resume_yandex_gameplay()`.
  Do **not** call `GameplayAPI.start()` directly from ad handlers.
- `GameplayAPI.stop()` must also be called on page/tab visibility changes (pagehide/pageshow).
- `YandexBridge.is_ad_in_progress()` must be checked before restarting GameplayAPI to avoid
  restarting during an active ad.

### Ad placement config rules

- All ad show calls must pass an explicit placement id string:
  `Platform.show_rewarded_ad("rewarded_shop_gems")`,
  `Platform.show_fullscreen_ad("fullscreen_auto_interstitial")`, etc.
- Placement ids are defined in `scripts/game/config/AdPlacementConfig.gd`.
  Do not add new placement ids without also adding an entry to `AD_PLACEMENTS`.
- `android_ad_unit_id` per placement starts empty and must be filled in from
  the Yandex Mobile Ads dashboard before enabling Android ads. Do not hardcode
  Android ad unit ids anywhere except `AdPlacementConfig.gd`.
- `AdPlacementConfig.get_platform_ad_unit_id(placement_id, platform_key)`
  resolves the unit id. Do not call it from gameplay code; it is called
  internally by `AndroidRuStorePlatform.show_rewarded_ad()` /
  `show_fullscreen_ad()`.
- `WebYandexPlatform` and `LocalDebugPlatform` accept but ignore the
  placement id — do not add placement-id validation to those impls.
- `AndroidRuStorePlatform` emits a clean ad error if the placement id is
  unknown, if the ad unit id is empty, or if the plugin is unavailable.
  The ad-in-progress flag must never be left as `true` when an error is
  emitted before the plugin call.

### Android ads plugin rules

- The `AndroidYandexAds` Godot plugin (`addons/android_yandex_ads/`) is the
  ONLY place where Yandex Mobile Ads SDK (Android) calls may live.
  Gameplay code (`ClickerScreen.gd`) and the platform bridge
  (`AndroidRuStorePlatform.gd`) must not call Yandex SDK types directly.
- **Never grant rewarded rewards inside the Kotlin plugin.** The plugin only
  emits `rewarded_ad_rewarded` — the GDScript handler in `ClickerScreen` is
  the only place a reward is applied to game state.
- Do not add new ad formats (banner, native, app-open, feed, sticky) without
  an explicit user request. Only rewarded and interstitial are integrated.
- Do not alter Web/Yandex ad behavior while changing Android ads. The two
  platforms are completely independent code paths.
- Ad SDK calls (`show_rewarded_ad`, `show_interstitial_ad`) must always run
  on the Android UI thread (`activity.runOnUiThread { ... }`).
- `AndroidRuStorePlatform._on_android_fullscreen_ad_closed(was_shown: bool = true)`
  must emit `fullscreen_ad_closed.emit(was_shown)` — the `was_shown: bool`
  parameter is required by `PlatformServices.gd`'s signal signature. The Kotlin
  plugin must also declare `SignalInfo("fullscreen_ad_closed", Boolean::class.javaObjectType)`.
- Plugin singleton name: `"AndroidYandexAds"`.
  Check availability with `Engine.has_singleton("AndroidYandexAds")`.
- The AndroidYandexAds plugin AAR must be built before each Android export.
  See `docs/android_ads_build.md` for the build command and output path.
- Android export changes (plugin, Gradle, SDK settings) must never break the
  Web/Yandex export. Test Web export after every Android-related change.
- Ad terminology: use "Yandex Mobile Ads SDK" for the ad SDK.
  "RuStore Pay" is exclusively for the payment SDK. Never call the ad SDK
  "RuStore Ads" — RuStore has no public Godot ads plugin.

### Android payments plugin rules

- **`AndroidRuStorePlatform.gd` is the ONLY place where RuStore Pay SDK calls may
  live.** Gameplay code (`ClickerScreen.gd`) must call `Platform.purchase_product()`.
- **Use the official `RuStoreGodotPayClient`** (`addons/RuStoreGodotPay/RuStoreGodotPay.gd`).
  Access it via `RuStoreGodotPayClient.get_instance()` after checking both
  `Engine.has_singleton("RuStoreGodotPay")` and `Engine.has_singleton("RuStoreGodotCore")`.
- **Never use the deprecated RuStore BillingClient.** All payment work must use
  `RuStoreGodotPayClient`. BillingClient is forbidden.
- **Never use `Engine.get_singleton("AndroidRuStorePay")`.** The old custom
  `AndroidRuStorePay` adapter (`addons/android_rustore_pay/`) is deprecated and
  must not be re-enabled in `project.godot` or referenced in payment code.
- **Never grant paid rewards inside the SDK.** Only `ClickerScreen._on_payment_purchase_success()`
  applies rewards to game state.
- **Purchase type: ONE_STEP.** Consumable purchases are auto-confirmed by the SDK.
  `consume_purchase()` is a safe no-op; do not add an explicit confirm/consume call.
- **Purchase id extraction order:** `purchaseId` → `orderId` → `invoiceId`.
  Do not emit `payment_purchase_success` if all three are empty — treat as error.
- **SDK signals used** (from `RuStoreGodotPayClient`):
  - `on_purchase_success(result: RuStorePayProductPurchaseResult)` — purchase completed
  - `on_purchase_failure(product_id: RuStorePayProductId, error: RuStorePaymentException)` — SDK error
  - `on_purchase_cancelled(product_id, purchase_id, invoice_id)` — user cancelled
  - `on_get_purchases_success(purchases: Array)` — recovery check result
  - `on_get_purchases_failure(error: RuStorePaymentException)` — recovery check failed
- **Old custom signals** (`purchase_success`, `purchase_cancelled`, `purchase_error`,
  `pending_purchase_found`, `pending_purchases_check_completed`,
  `pending_purchases_check_error`) belonged to the deprecated adapter. Do not use them.
- `check_unprocessed_purchases()` calls
  `get_purchases(CONSUMABLE_PRODUCT, CONFIRMED)`. When the client is absent it
  emits `unprocessed_purchase_check_completed` so the startup check completes cleanly.
- `_pay_client` is set once in `_ready()` via `_create_rustore_pay_client()`.
  Do not call `RuStoreGodotPayClient.get_instance()` outside `_create_rustore_pay_client()`.
- Local `android/build/res/values/rustore_values.xml` (Application ID) must be
  configured by the developer; it is not committed because `/android/` is in `.gitignore`.
- Do not alter Web/Yandex payment behavior while working on Android payments.

### Floating rewarded banner rules

- Banner appears only on the clear main screen (no dialogs, no sheets open).
- Initial cooldown: 300 seconds after game load.
- Cooldown between viewings: 300 seconds.
- Visible/available lifetime: 60 seconds (`REWARDED_AD_BANNER_LIFETIME_SECONDS = 60`).
  If not clicked within 60 s the banner disappears and the normal 300 s cooldown begins.

### Fullscreen ad rules

- No reward is granted for fullscreen ads.
- Safe cooldown-based display only; must not appear during active user interaction, purchases,
  rewarded ads, dialogs, or any other unsafe state.
- A UI input overlay must block accidental taps while the fullscreen ad is in progress.

## Payment rules

- Use client-side Yandex Payments mode: `ysdk.getPayments()`. Do **not** use
  `getPayments({ signed: true })` unless a backend signature verification flow is added.
- Paid gems are granted only after a payment success callback that carries a **non-empty
  `purchaseToken`**. An empty or missing token must not grant gems; treat it as an error.
- Cancel and error grant nothing.
- A duplicate success callback must not double-grant gems. Prevent double-granting the
  same purchase token within a session.
- Unprocessed purchases must be checked via `payments.getPurchases()` on startup to recover
  any purchases that were not consumed in a previous session.
- For consumable purchases the required order is strictly:
  1. Grant gems.
  2. Update UI.
  3. Save locally.
  4. Request cloud save flush.
  5. Call `consumePurchase()`.
- The payment modal must add a runtime pause reason, call `AudioManager.set_audio_pause_reason`,
  and call `GameplayAPI.stop()` before the Yandex payment dialog opens.
- Payment success/cancel/error must clear pending payment state
  (`_pending_payment_product_id`, `_payment_reward_granted_for_current_request`) and
  call safe resume logic.
- The gem purchase dialog must not be dismissible (close button or outside click) while
  `_payment_in_progress` is true.
- In-game displayed prices must match the actual Yandex product prices:
  - `gems_25` → 24 RUB (+25 gems)
  - `gems_150` → 99 RUB (+150 gems)
  - `gems_500` → 249 RUB (+500 gems)
  - `gems_1500` → 499 RUB (+1500 gems)
- `amount_gems` is the source of truth for reward quantities.
- `price_rub` is the source of truth for displayed prices.

## Save / reset rules

- Both local save and Yandex cloud save (player data) are used. Respect the Yandex player data size limit.
- Cloud save must be flushed after purchases, ad rewards, task claims, reset, prestige, settings/language changes, and any important economy change.
- **Reset Progress is debug/internal only (C7.2.1).** Do not reintroduce a production
  UI path (button, menu entry, etc.) that lets the user reset or delete their save.
  Save deletion/reset actions must remain debug/tool/internal only. Internal runtime
  reset helpers (`ClickerState.reset_to_new_game()`, preserved-snapshot helpers,
  `_reset_runtime_state_for_new_game()`) may remain and are still used by gameplay,
  prestige, and clean account save after Guest → Login with no cloud save. Never add
  a production UI path that calls `SaveManager.delete_save()`.
- **Account / Cloud is the production replacement for Reset Progress in Settings
  (C7.2.2).** The Android-only Account/Cloud section in `SettingsWindow` (header,
  guest explanation, sign-in/register, cloud save/load, logout) is the intended
  user-facing entry point going forward. Do not reintroduce Reset Progress in
  production UI. Do not mix Settings UI structure/text changes with backend
  save-flow changes in the same patch — they are reviewed separately. Android
  backend account controls must remain gated by
  `_is_backend_account_ui_supported()` (Android/RuStore-only); Web/Yandex behavior
  and Yandex SDK cloud-save must remain unchanged.
- **Account status messages and Cloud Save messages must remain separate (C7.2.3).**
  Account operation results (verify email, confirm code, logout, backend errors) go
  through `SettingsWindow._show_account_action()` into `_account_action_label`.
  Cloud save/load results go through `SettingsWindow.set_cloud_save_status()` into
  `_cloud_status_label`. Never write account text into the cloud label or vice versa.
- **Account action buttons must not allow duplicate backend requests (C7.2.3).**
  Verify Email, Confirm Code, and Logout must guard against re-entrancy via
  `_account_action_busy` (set by `_set_account_actions_busy()`), disable while a
  request is in flight, and always re-enable on success or failure — never leave a
  button stuck disabled after a backend error.
- **Settings UI cleanup must not change backend save/auth flow (C7.2.3).** Text,
  layout, and status-message changes in `SettingsWindow` must not alter
  `SaveManager` backend logic, Guest → Login/Register flow, or `CloudRestorePrompt`
  behavior — those are separate, reviewed independently.
- **Android Guest paid gem purchases must be visually locked (C7.2.4).** The
  `donation_entry` shop card (`gem_purchase_entry`) must show an obvious
  account-required state (button text, description, and tint) whenever
  `_is_paid_shop_available()` is false, so tapping it and landing on AuthGate
  isn't a surprise. It must return to the normal state immediately after
  Guest → Register/Login and lock again immediately after Logout.
- **Rewarded ads must remain available in Guest mode (C7.2.4).** Never gate
  `product_type == "rewarded_ad"` behind account/session state — only
  `donation_entry` is affected by the paid shop lock UI.
- **Shop UI must not call `Platform.purchase_product()` in Guest (C7.2.4).**
  `ClickerScreen` owns the account/session decision
  (`_is_paid_shop_available()`); `ShopSheet`/`ShopPanel` only render the flag
  they're given via `set_paid_shop_available()` and must never independently
  decide to start a purchase.
- **Do not mix paid shop UX changes with backend/cloud-save changes (C7.2.4).**
  Shop lock visuals and status messages must not alter `SaveManager`,
  backend Cloud Functions, backend API paths, or Guest → Login/Register logic
  — those are reviewed separately.
- **Docs/localization/asset cleanup patches must not touch backend save-flow
  behavior (C7.2.5).** Removing obsolete Reset Progress or GuestMigrationPrompt
  remnants (docs, localization keys, unused assets, dead files) must never be
  bundled with changes to `SaveManager`, backend Cloud Functions, backend API
  paths, Guest → Login/Register logic, `CloudRestorePrompt`, or paid shop lock
  logic — those remain separate, reviewed changes.
- Gems survive Reset Progress.
- Permanent shop upgrades survive Reset Progress.
- Sound/music/language settings survive Reset Progress.
- Gems, permanent shop upgrades, sound/music/language settings, and prestige points/talents survive Prestige.
- Prestige resets: current level, max unlocked level, normal run progress (gold, hero level,
  partners, buildings, skills), tasks, temporary buffs, and `auto_stage_advance_enabled`
  (resets to default ON).
- Pending offline rewards must not duplicate or disappear. The pending offline reward must not be
  lost, duplicated, or cleared on ad close/error.
- Save immediately after purchases, ad rewards, task claims, reset, prestige, settings/language changes, and important economy changes.
- Save field names (keys in the save dictionary) are part of Save System v1 and must not be renamed without a migration.
- BigNumber values in the save must remain forward-compatible; adding a new BigNumber field requires handling the absent-key case on load.

## Debug / release rules

- Debug features are allowed only when `BuildConfig.is_debug_features_enabled()` returns true.
  This reflects `OS.is_debug_build()` internally — do not manually force `IS_DEBUG_BUILD` in source.
- Use a proper release export (`godot --headless --export-release "Web" …`) to produce a
  production build. Do not ship a debug export.
- F12 debug mode and keyboard shortcuts (F5/F9/F10/F12/L/K) must not work in production.
- Fake ad / payment success must not work in production.
- Dev tools (`ProgressionSimulator`, `BalanceAuditReport`) must not be autoloaded or runtime-active in release builds.

## Audio rules

- Sound setting gates all SFX. Music setting gates music playback.
- Audio uses a multi-reason pause: `ad`, `platform`, `payment`, `hidden`. Music and SFX are
  suppressed while any pause reason is active.
- Music tracks are played in randomized/shuffled order; the game must not always start from track 1
  and must avoid immediate repeats where possible.
- Music starts/resumes after the first real user interaction (required by Web/Yandex autoplay policy).
- Music pauses when the page/tab is hidden (pagehide / `visibilitychange`) and resumes when visible
  again (pageshow) if the music setting is enabled and no other pause reason is active.
- SFX are suppressed while the page/tab is hidden, during ads, during platform pause, and during
  active payment.
- Audio pauses during rewarded/fullscreen ads and resumes after close/error when the page is visible.
- Button SFX fires on `button_down`, not after the delayed button action completes.
- Avoid duplicate button / popup sounds triggered in the same frame.
- `gold_received.ogg` must not spam on every partner tick — only play on meaningful gold events.
- Do not use `Engine.has_singleton("YandexBridge")` to check for the YandexBridge autoload —
  it is always registered. Use it directly as `YandexBridge`.

## Asset rules

- Keep all asset file paths ASCII-only — no spaces, no Cyrillic.
- Do not introduce catalog keys that point to missing files.
- New assets must be registered in the correct catalog (`GameAssetCatalog`, `EnemyAssetCatalog`, or `BackgroundAssetCatalog`).
- Follow existing folder conventions under `res://assets/`.
- Missing image files must never crash the game — `ImageSlot` falls back gracefully.

## Testing rules

Before final release, verify:

- save / load / reset / prestige
- rewarded ads (floating banner, shop, offline)
- gem payments (all four products)
- UI on 720×1600, 720×1280, and 1080×2400
- audio (SFX, music, settings toggle)
- localization (both ru and en)
- asset / build sanity
- Web export (serve over HTTP, not file://)
- Yandex Games cabinet preview

---

## Backend cloud-save rules (C6+ / C6.1+)

These rules apply to all Android/RuStore backend auth and cloud-save work.

- **Signal connection guard required.** Every `Platform.backend_operation_succeeded.connect(...)` and `Platform.backend_operation_failed.connect(...)` call must be wrapped in `if not signal.is_connected(callable)`. Never connect a backend signal without this guard.

- **Backend cloud-save is Android + account only.** `queue_backend_cloud_save()`, `flush_backend_cloud_save_now()`, and all `Platform.backend_*` cloud ops must only run when `OS.has_feature("android")` and `Platform.backend_has_session()` are both true. Guests must never trigger backend cloud-save or cloud-load operations.

- **Do not reintroduce `CloudRestorePrompt`.** It was deleted in C7.3.4 (`scenes/ui/CloudRestorePrompt.gd`/`.tscn` and all `_startup_cloud_restore_*`/`_pre_startup_*` state in `ClickerScreen.gd`). Account login/startup must not ask a local-vs-cloud conflict question — the account cloud save is authoritative and force-loads silently (C7.3.1). `GuestMigrationPrompt` is also no longer shown (C7.1).

- **Backend auto-upload suspension must not leak.** If you add a new exit path from the startup restore-decision flow, you must call `_resume_backend_auto_upload_after_restore_decision()` at that exit point. `_exit_tree()` also calls it as a safety net.

- **Duplicate request guard required.** Any UI submit function that calls a backend operation (`Platform.backend_login()`, `Platform.backend_register()`, `Platform.backend_request_password_reset()`, `Platform.backend_confirm_password_reset()`, etc.) must guard with a `_request_in_progress` flag and clear it on both success and failure responses.

- **Never log auth credentials or full save payloads.** Do not print session tokens, passwords, reset codes, email verification codes, or full save JSON in any log statement — gated or ungated. Use structural summaries (`save_version`, `last_save_unix_time`) only.

- **`set_startup_auth_mode` before `add_child`.** When passing the startup auth mode to `ClickerScreen`, always call `set_startup_auth_mode(mode)` before `add_child(_clicker_screen)`. The mode must be set before `_ready()` (and therefore `_load_game_on_start_async()`) has any opportunity to read it.

- **Debug print gates.** Any `print(...)` inside `ClickerScreen.gd`, `AuthGateScreen.gd`, or other UI/gameplay scripts that exposes internal flow state must be gated behind `BuildConfig.IS_DEBUG_BUILD`. Debug prints in `AndroidRuStorePlatform.gd` use `OS.is_debug_build()`.

- **Backend upload payload must not be lost on failure.** `_send_backend_cloud_save(payload)` must store a copy in `_backend_cloud_upload_current_payload`. On upload failure, if `_pending_backend_cloud_save_data` is empty, restore the in-flight payload and schedule a retry. Never drop a payload silently.

- **Manual Save to Cloud must queue the current payload when an upload is in-flight.** `upload_current_save_to_backend_cloud_now()` must build the current payload first, then — if an upload is already in-flight — store it in `_pending_backend_cloud_save_data` and set `_backend_cloud_retry_pending = true` rather than assuming the old in-flight data is current.

- **AuthGate navigation and Guest must be blocked during active backend request.** All navigation handlers (`_on_forgot_pressed`, `_on_to_register_pressed`, `_on_to_login_pressed`, `_on_back_to_login`) and the guest handler (`_on_guest_pressed`) must return early if `_request_in_progress == true`. The Guest button must never emit `auth_gate_completed("guest")` while a login/register/reset request is active.

- **ClickerScreen must disconnect backend signals on exit.** `_exit_tree()` must disconnect `Platform.backend_operation_succeeded` and `Platform.backend_operation_failed` if connected. Use `is_instance_valid(Platform)` guard.

- **Android export version name must match `BuildConfig.APP_VERSION` and `validate_android_release.py`.** Keep `version/name` in the Android preset of `export_presets.cfg` in sync with `BuildConfig.APP_VERSION` (`scripts/game/BuildConfig.gd`) and `EXPECTED_VERSION_NAME` in `tools/validate_android_release.py`. Do not set `version/name=""`.

- **`<profileable android:enabled>` must be `false` in the release manifest template.** Never set it to `true` in `android/build/AndroidManifest.xml` — profiling must be disabled for release builds.

---

## Coding Rules

- Use GDScript only. Do not add C#.
- Keep scripts simple and focused.
- Avoid large architectural rewrites.
- Do not add external plugins or external assets without explicit approval.
- Do not introduce gameplay systems beyond the requested task.
- Keep patches easy to review.

## Scene / UI Rules

- Use Control-based UI for the main scene and other screen layouts.
- Keep the game vertical and Web-export friendly.
- Prefer containers and anchors over Node2D positioning for UI.
- Test layout in `ClickerScreen.tscn` preview and by running `Main.tscn`.
- `ClickerScreen/MainContent` must use top/full anchors with a bottom offset above `BottomBar`.
- Keep upgrade buttons and future UI controls separate from `GameField` so they do not accidentally trigger attacks.
- Preserve the main scene UID unless unavoidable.

## Yandex Games / Web Export Rules

- Keep YandexBridge registered as an Autoload.
- Preserve existing YandexBridge public methods: `game_ready()`, `gameplay_start()`, `gameplay_stop()`,
  and `notify_yandex_game_ready()` on ClickerScreen.
- Make sure editor and desktop preview runs do not crash when Web-only APIs are unavailable.
- Production export must use release mode, not debug.
- `index.html` must be at the archive root for Yandex Games upload.
- No Cyrillic or spaces in exported file paths.
- Unpacked build ≤ 100 MB.
- Test locally via HTTP server, not by opening `index.html` directly.

### Localhost / offline behavior

- On localhost, `window.ysdk` is not present — the Yandex SDK is unavailable.
- Real ads and real paid purchases will not open.
- The game must fail gracefully: no rewards or gems must be granted, and the game must
  not be left in a paused state with no recovery path.
- Debug mode simulates ad and payment flows for local testing. These simulations are
  disabled in release builds via `BuildConfig.is_debug_features_enabled()`.

### Web/Yandex vs Android/RuStore platform separation (Y1 audit rules)

Confirmed by the Y1 audit (`docs/validation/yandex_release_audit_platform_separation.md`).
These rules make the existing separation explicit so future patches don't
accidentally cross the boundary:

- **Never mix Android/RuStore backend account/cloud with Web/Yandex save
  flow.** Web save/load must only go through `Platform.load_cloud_save()` /
  `Platform.save_cloud_save()` (→ `YandexBridge`), never
  `Platform.backend_load_save()` / `backend_save_save()`.
- **Web/Yandex must not show Android `AuthGateScreen`/`AccountWindow`.** Both
  are gated on `OS.has_feature("android")` at their only call sites
  (`scenes/main/Main.gd`, `scenes/ui/SettingsWindow.gd`). Do not add a
  Web-reachable path to either.
- **Web/Yandex purchases must use Yandex SDK payments
  (`ysdk.getPayments()`/`payments.purchase()`), not RuStore Pay.** Real
  RuStore Pay SDK calls remain confined to `AndroidRuStorePlatform.gd` per
  the existing rule above.
- **Web/Yandex prices/currency shown to the player must come from the Yandex
  catalog (`payments.getCatalog()`), never a hardcoded RUB figure.**
  Implemented by Y4: `YandexBridge.load_payment_catalog()` caches
  `payments.getCatalog()` by Yandex product id; `Platform.get_catalog_product(local_id)`
  resolves it. `GemPurchaseDialog` shows the real catalog `price` on Web and
  never falls back to `GemPurchaseConfig.price_rub` there. `price_rub`
  remains the displayed price on Android/RuStore and in editor/debug only.
  See `docs/validation/yandex_payments_catalog_price_display.md`.
- **Local product id must map to `yandex_product_id` before it can be shown
  or purchased on Web.** Use `GemPurchaseConfig.get_platform_product_id(id,
  "yandex")` → `Platform.get_catalog_product(id)`, never assume the local id
  equals the Yandex catalog id even though today's config happens to keep
  them identical.
- **A Yandex catalog product missing for a given local id must disable that
  product's purchase safely — never show a fake price or start a purchase
  for it.** `GemPurchaseDialog` shows `shop.gem_purchase.unavailable` /
  keeps the buy button disabled, and blocks `gem_product_purchase_requested`
  from firing, before `Platform.purchase_product()` is ever called. A debug
  build logs a warning with both the local id and the resolved Yandex id —
  that is the signal to check `GemPurchaseConfig.gd` against the real
  Yandex draft catalog.
- **Do not change purchase/consume/recovery logic when only fixing
  catalog/price display.** `_on_payment_purchase_success()`,
  `_on_payment_purchase_cancelled()`, `_on_payment_purchase_error()`,
  `_on_unprocessed_purchase_found()`, `state.grant_paid_gem_purchase()`,
  `state.is_purchase_processed()`, and `Platform.consume_purchase()` call
  sites in `ClickerScreen.gd` must stay untouched by catalog/price-display
  work — Y4 gates purchases one step upstream, in `GemPurchaseDialog`,
  precisely so these functions never need to change.
- **Android/RuStore payment flow must remain separate and unaffected by
  Web/Yandex catalog work.** `AndroidRuStorePlatform.gd`'s catalog methods
  are permanent no-ops (`load_payment_catalog()` emits an empty list;
  `get_catalog_product()` returns `{}`) — RuStore has no equivalent catalog
  API. Do not wire RuStore pricing through the same catalog path as Yandex.
- **Web/Yandex language must be auto-applied from the Yandex SDK.** Already
  implemented in `ClickerScreen._apply_startup_language()` — reads
  `Platform.get_platform_language()` (→ `ysdk.environment.i18n.lang`) unless
  the player manually selected a language. Do not bypass this on Web.
- **Platform language must not be a one-shot read before the SDK is
  ready (Y4.1).** `_apply_startup_language_when_platform_ready()` retries
  (up to `STARTUP_LANGUAGE_MAX_RETRY_ATTEMPTS`, every
  `STARTUP_LANGUAGE_RETRY_DELAY_SEC`) until `Platform.get_platform_language()`
  returns a non-empty value or the platform isn't Yandex. Do not revert to a
  single synchronous read — the Yandex SDK is not guaranteed ready the
  instant `ClickerScreen._ready()` runs, and reading it too early previously
  meant an empty language got normalized to the default and could overwrite
  a real saved language.
- **Web/Yandex SDK-dependent features (ads, catalog, language) must handle
  SDK-not-ready, error, AND timeout paths (Y4.1).** Never assume a request
  the SDK acknowledges will always call back.
- **Rewarded ads must never leave gameplay/audio paused if SDK callbacks do
  not arrive.** `YandexBridge.show_rewarded_ad()` starts a
  `REWARDED_AD_TIMEOUT_SEC` (7s) watcher; if none of `onOpen`/`onClose`/
  `onError` fire in time it clears `_rewarded_ad_in_progress` and emits
  `rewarded_ad_error`, which `ClickerScreen` uses to resume gameplay/audio
  and show a localized status. Do not add a rewarded-ad call site that skips
  this resume path.
- **Do not grant ad rewards without `onRewarded`.** Reward is granted only in
  `ClickerScreen._on_rewarded_ad_rewarded()`; timeouts, errors, and
  `onClose(wasShown=false)` must never grant a reward.
- **Catalog loading must never show endless "Loading price..." (Y4.1).**
  `YandexBridge.load_payment_catalog()` times out after
  `CATALOG_LOAD_TIMEOUT_SEC` (9s) and emits `payment_catalog_error` if
  neither `payment_catalog_loaded` nor `payment_catalog_error` arrives.
  `GemPurchaseDialog._on_payment_catalog_error()` always clears
  `_catalog_requested` (even if the dialog was closed before the
  response/timeout arrived) so the next `show_dialog()` can retry.
- **Web/Yandex saves must use Yandex Player data
  (`player.getData`/`setData`).** Already implemented in `YandexBridge.gd`
  under the stable key `save_v1`, with a 200 KB size guard in
  `SaveManager._send_cloud_save()`. Do not route Web saves through the
  Android backend.
- **Yandex release patches must document whether a change is code-side,
  console-side (Yandex developer console / draft settings), or media-side
  (screenshots, promo images, descriptions).** Console/media work is never
  solved by editing GDScript — see the Y5 checklist in
  `docs/validation/yandex_release_audit_platform_separation.md`.
- **Yandex draft/media compliance is partly manual and cannot be solved
  entirely in code.** Title consistency, description text, category, and
  media chrome all require action inside the Yandex developer console — see
  `docs/yandex/yandex_submission_checklist.md`. Do not treat a docs/checklist
  patch as a substitute for actually completing the console-side steps.
- **Product ids in `GemPurchaseConfig.gd` must match the Yandex draft ids
  exactly.** See `docs/yandex/yandex_products_checklist.md`. A mismatch
  makes Y4's catalog integration mark the product unavailable and block its
  purchase — check `YandexBridge.get_catalog_product()`'s debug warning
  first if a product won't show a real price.
- **Do not hardcode Yandex prices in UI.** On Web, `GemPurchaseDialog` must
  keep reading the price from `Platform.get_catalog_product()` (Yandex
  catalog), never a hardcoded RUB or other currency string. `price_rub` in
  `GemPurchaseConfig.gd` remains a fallback for Android/RuStore/editor only.
- **Do not add rounded corners or baked frames to Yandex promo/media
  exports.** See `docs/yandex/yandex_media_requirements.md`. This was a
  prior moderation rejection reason.
- **Screenshots with text must match their locale.** A screenshot attached
  to the RU listing must show RU in-game UI text; EN listing → EN UI text.
- **Keep category guidance as `Казуальные` (Casual) unless changed
  intentionally** — this was previously flagged by moderation and must not
  drift without a deliberate decision.
- **Do not mix Yandex console/media checklist patches with
  gameplay/payment logic patches.** Metadata/media/checklist work (Y5-style)
  should not touch `YandexBridge` purchase/consume/recovery logic, save
  logic, ads, or gameplay balance in the same patch — keep them separable so
  a moderation-focused patch can't accidentally introduce a gameplay
  regression.

## Stage Navigator Rules

- `StageNavigator` shows exactly 5 stage buttons (80×80 ImageSlot-backed squares) at a time.
- Button color states: blue = current stage, white = unlocked, gray = locked.
- Clicking an unlocked (white) stage emits `stage_selected(level)` and triggers `travel_to_level` in `ClickerScreen`.
- Clicking the current (blue) stage or a locked (gray) stage does nothing.
- `StageNavigator` clicks, wheel, and drag must not propagate to `GameField` and must not trigger attacks.
- There are no left/right step-scroll arrow buttons. The strip is scrolled only via mouse wheel and drag/swipe.
- To the right of the 5 stage buttons: a **latest button** (`>>`, yellow, 80×80) and an **auto-transition button** (`A`, green/gray, 80×80).
- The latest button emits `latest_requested`; `ClickerScreen` responds by calling `stage_navigator.center_on_latest_level()`.
- The auto-transition button emits `auto_transition_popup_requested(anchor_global_position: Vector2, button_global_rect: Rect2)` with its own global position; `ClickerScreen` immediately toggles `auto_stage_advance_enabled`, updates the navigator color, and opens `AutoTransitionPopup` as an info popup.
- `center_on_latest_level()` sets `visible_center_level = max_unlocked_level`, clamps, and refreshes.
- `set_auto_transition_enabled(enabled)` updates `_auto_btn_rect.color`: green when ON, gray when OFF.
- `max_unlocked_level` in `ClickerState` tracks the highest stage naturally reached.
- `max_unlocked_level` updates with `maxi(max_unlocked_level, current_level + 1)` when stage objective is cleared in `resolve_defeated_target()`, regardless of `auto_stage_advance_enabled`.
- Only `current_level + 1` is ever unlocked per clear; farming the same cleared level cannot unlock levels beyond the immediately next one.
- `max_unlocked_level` is not reduced by traveling backward, boss fail, or anything other than prestige.
- `max_unlocked_level` resets to 1 on prestige alongside `current_level`.
- `can_travel_to_level(level)` returns true when `level >= 1` and `level <= max_unlocked_level`.
- `travel_to_level(level)` sets `current_level`, resets `enemies_defeated_on_level` to 0, calls `setup_current_level()`, and returns a result dict with `"travelled": true`.
- Traveling does not grant gold, does not count defeated enemies, and does not modify character/partner/settlement/prestige state.
- After travel in `ClickerScreen._on_stage_selected`: reset `partner_damage_accumulator` and `autoclick_accumulator`, increment `enemy_transition_token`, then call `_sync_boss_timer()`, `_update_ui()`, and `game_field.update_view(state)`. Do NOT call `center_on_level` after manual travel.
- After prestige in `ClickerScreen._on_prestige_confirmed`: call `stage_navigator.center_on_level(1)` before `_update_ui()`.
- `update_view(current_level, max_unlocked_level)` must NOT auto-snap `visible_center_level` on every call. It sets the center only once via the `_has_initialized_view` guard, then only clamps and refreshes.
- `center_on_level(level)` is called ONLY when the player actually advances to a new level via gameplay: when `resolve_defeated_target()` returns `advanced_to_next_level: true`, ClickerScreen calls `stage_navigator.center_on_level(state.current_level)`.
- `ClickerScreen._update_ui()` calls `stage_navigator.update_view(state.current_level, state.max_unlocked_level)` and `stage_navigator.set_auto_transition_enabled(state.auto_stage_advance_enabled)`.
- Drag threshold for scroll step is 36 px; drag movement threshold to suppress button click is 8 px.
- Dragging must not accidentally emit `stage_selected`; the `_drag_moved` flag suppresses button presses when drag distance exceeds the movement threshold.
- Mouse wheel is handled via `_gui_input` with `accept_event()` to prevent wheel events from reaching `GameField`.
- Drag is tracked via `_input` using `get_global_rect().has_point` to restrict drag initiation to the navigator area.

## Auto-transition Rules

- `ClickerState.auto_stage_advance_enabled: bool = true` — defaults to true. Saved locally during
  a normal run. Prestige resets it back to default ON.
- `set_auto_stage_advance_enabled(enabled)` is the only setter.
- When `auto_stage_advance_enabled` is ON and `resolve_defeated_target()` detects `did_level_up`: `current_level += 1`, `setup_current_level()`, returns `advanced_to_next_level: true`.
- When `auto_stage_advance_enabled` is OFF and `resolve_defeated_target()` detects `did_level_up`: next level is unlocked (`max_unlocked_level` updated), `enemies_defeated_on_level = 0`, `setup_current_level()` resets the same level's target for farming, returns `advanced_to_next_level: false`.
- Reward gold is always granted on defeat regardless of auto-transition setting.
- `resolve_defeated_target()` result always includes `advanced_to_next_level: bool`, `level_unlocked: bool`, `unlocked_level: int`.
- Boss defeated with auto OFF: boss target resets, boss timer restarts via `_sync_boss_timer()` in `_finish_enemy_transition_after_delay`.
- Task counters (`total_enemies_defeated`, `total_bosses_defeated`, etc.) are always incremented regardless of auto-transition.
- `game_level_delta` tasks track `current_level`; farming the same level with auto OFF does not advance these tasks.
- `AutoTransitionPopup` is a full-screen Control overlay (mouse_filter STOP when visible, PASS when hidden). The inner PanelContainer has mouse_filter STOP. Outside clicks close the popup via `_gui_input` checking `_panel.get_global_rect().has_point`.
- The popup is info-only: it shows current ON/OFF status and has only a close button. There is no toggle button inside the popup.
- Pressing the `A` button triggers `ClickerScreen._toggle_auto_transition_and_show_popup()`, which immediately toggles `auto_stage_advance_enabled`, calls `stage_navigator.set_auto_transition_enabled()`, `_update_ui()`, and then opens the popup.
- Popup signals: `auto_button_pressed_through(anchor: Vector2, button_global_rect: Rect2)` — emitted when the user clicks the `A` button area while the popup is already visible, re-triggering the same toggle+show flow.

## Image Asset System Rules

- `scripts/ui/GameAssetCatalog.gd` is the single source of truth for all image slot keys and file paths.
- `scripts/ui/ImageSlot.gd` is the reusable component that replaces ColorRect image placeholders.
- `ImageSlot extends ColorRect` — it is a drop-in replacement with identical layout behavior.
- Every ImageHolder-style placeholder (ColorRect used as an image slot) must be converted to `ImageSlot`.
- Do not hardcode image paths in UI panels or scenes; always register keys in `GameAssetCatalog.ASSET_PATHS`.
- Missing image files must never crash the game; `ImageSlot` falls back to `fallback_color` when the file is absent.
- Keep placeholder fallback colors in place until final art is ready.
- To add a new image slot: add the key/path to `ASSET_PATHS`, create the `ImageSlot` node, set `asset_key`.
- Use the catalog helper methods for dynamic keys: `partner_icon_key`, `partner_skill_key`, `ability_skill_key`, `hero_skill_key`, `building_icon_key`, `prestige_talent_icon_key`, `shop_product_icon_key`, `task_icon_key`.
- In scripts that create `ImageSlot` dynamically, use `const ImageSlotClass = preload("res://scripts/ui/ImageSlot.gd")` to avoid relying on class_name indexing in the LSP. Do NOT add `const GameAssetCatalog = preload(...)` — `GameAssetCatalog` is a global class_name and a local const with the same name causes SHADOWED_GLOBAL_IDENTIFIER warnings.
- Skill icon fallback colors must still reflect state: gray = locked, blue = available, white = purchased. Use `set_fallback_color(color)` instead of `.color = color` on `ImageSlot` nodes.
- Enemy state asset keys (GameAssetCatalog defaults): `enemy.default.healthy`, `enemy.default.hit`, `enemy.default.wounded`, `enemy.default.defeated`. These are fallbacks only — `GameField` now loads per-enemy textures via `EnemyAssetCatalog` first.
- Stage navigator slot keys: `stage.current`, `stage.unlocked`, `stage.locked`, `stage.latest`, `stage.auto_on`, `stage.auto_off`.
- Sheet header slot keys: `header.gold` (Upgrade/Partner/Settlement), `header.prestige_points` (Prestige), `header.gems` (Shop).
- Asset image files go under `res://assets/images/` and its subdirectories.
- Do not add `.gdignore` to asset image directories.

## Enemy Image System Rules

- `scripts/ui/EnemyAssetCatalog.gd` is the dedicated catalog for per-enemy, per-state image paths. It is separate from `GameAssetCatalog` because enemy images scale with zones and enemy counts.
- Every enemy has 4 visual state images: `healthy.png`, `hit.png`, `wounded.png`, `defeated.png`.
- Folder structure: `res://assets/images/enemies/zone_XX/enemy_YY/state.png`.
- Zone folders are 1-based: zone index 0 → `zone_01`, zone index 1 → `zone_02`, etc.
- Normal enemy folders are 1-based by ZONE_DATA enemies array index: enemy_index 0 → `enemy_01`, 1 → `enemy_02`, 2 → `enemy_03`.
- Elite enemy folder: `elite_01`. Boss enemy folder: `boss_01`.
- `ClickerState` stores `current_enemy_zone_index` (int) and `current_enemy_slot` (String) set in `choose_enemy_for_current_level()`. These are runtime-only; do not save them.
- `GameField` reads `state.current_enemy_zone_index` and `state.current_enemy_slot` and calls `EnemyAssetCatalog.load_enemy_texture()`.
- Fallback chain in `GameField._load_enemy_tex_with_fallback()`:
  1. Try exact enemy image via `EnemyAssetCatalog.load_enemy_texture(zone_index, enemy_slot, state)`.
  2. If null, try default via `GameAssetCatalog.load_texture("enemy.default." + state)`.
  3. If null, `set_direct_texture(null, fallback_color)` shows the placeholder color.
- `GameField` caches textures per enemy identity (`_cached_zone_index`, `_cached_enemy_slot`). Textures are reloaded only when the enemy changes, not every frame.
- `ImageSlot.set_direct_texture(texture, fallback_color)` applies a pre-loaded Texture2D directly without going through `GameAssetCatalog`.
- Hit feedback still only triggers for manual clicks and Autoclick — not partner DPS.
- Partner DPS must not show the hit (blue) state.
- Defeated state shows during transition lock regardless of enemy identity.
- Missing enemy image files must never crash the game.
- Do not hardcode enemy image paths in `GameField`; all path logic belongs in `EnemyAssetCatalog`.
- Do not save `current_enemy_slot` or `current_enemy_zone_index` to the save file; they are re-derived on each `choose_enemy_for_current_level()` call.
- When adding a new zone, add its folder under `res://assets/images/enemies/` and extend zone data in `scripts/game/config/ZoneConfig.gd`.

## Background Image System Rules

- `scripts/ui/BackgroundAssetCatalog.gd` is the dedicated catalog for zone background image paths.
- Folder structure: `res://assets/images/backgrounds/zone_XX/background.png`.
- Zone folders are 1-based: zone index 0 → `zone_01`, zone index 1 → `zone_02`, etc.
- `BackgroundAssetCatalog.load_zone_background(zone_index)` returns `Texture2D` or `null`. Never crashes on missing files.
- Fallback chain: zone background → `GameAssetCatalog "game.field_background"` → muted green `Color(0.25, 0.42, 0.25, 1)`.
- `GameField.BackgroundImageHolder` is an `ImageSlot` with `stretch_mode = STRETCH_KEEP_ASPECT_COVERED` and `mouse_filter = IGNORE`.
- `GameField._update_background_visual(state)` is called from `update_view(state)`. It caches the zone index in `_cached_background_zone_index` and only reloads when the zone changes.
- Background uses `set_direct_texture(texture, BACKGROUND_FALLBACK_COLOR, false)` — transparent behind texture when image exists, muted green when image is missing.
- `ClickerState.get_current_zone_index()` is the public helper used by `GameField` for zone-index-to-background mapping.
- Do not hardcode background paths in `GameField`; all path logic belongs in `BackgroundAssetCatalog`.
- Missing background files must never crash the game.
- When adding a new zone, add its folder under `res://assets/images/backgrounds/` and extend zone data in `scripts/game/config/ZoneConfig.gd`.
- Do not add `const BackgroundAssetCatalog = preload(...)` in `GameField` — `BackgroundAssetCatalog` is a global class_name and a local const with the same name causes `SHADOWED_GLOBAL_IDENTIFIER` warnings.
- Recommended image size: 720×1600 minimum, 1080×2400 recommended, portrait 9:20 safe.

## BalanceConfig Rules

`BalanceConfig` lives at `res://scripts/game/BalanceConfig.gd`. It is a plain `class_name` script (not an autoload). Reference it directly as `BalanceConfig.X` — do **not** add a local `const BalanceConfig = preload(...)`, as that shadows the global class name and produces `SHADOWED_GLOBAL_IDENTIFIER` warnings in Godot 4.5.1.

- All economy numbers belong in `BalanceConfig`. Do not scatter magic numbers across `ClickerState`.
- `ClickerState` reads BalanceConfig scalars at field initialisation time via `var x = BalanceConfig.X`.
- Large arrays (`PARTNER_DPS_VALUES`, skill definitions, etc.) are documented in `BalanceConfig` but kept as typed literals in `ClickerState` to avoid typed-array conversion risk.
- Do not add runtime mutable state to `BalanceConfig` — consts only.
- See `docs/BALANCE.md` for the full tuning guide.
- Do not change balance constants unless explicitly requested.

### BigNumber rules

- Large economy values use `BigNumber`: gold, costs, rewards, enemy HP, damage, DPS, and offline
  rewards where applicable.
- `BigNumber` uses mantissa/exponent base-1000 representation with compact display formatting.
- Do not use raw `int` or `float` literals for values that could exceed safe integer range. Use
  `BigNumber.from_int()`, `BigNumber.from_float()`, or the relevant `BalanceConfig` BigNumber helpers.
- Partner count is `PARTNER_COUNT = 28`. Partner cost and DPS formulas use BigNumber helpers for
  high indices to avoid integer overflow.
- Partner base progression: partner 1 cost = 35, DPS = 4; each subsequent partner base cost ×11,
  base DPS ×12.
- Settlement building bonus is 0.1% per purchased building level.
- Enemy HP growth: `ENEMY_HP_GROWTH = 1.26`. Enemy reward growth: `ENEMY_REWARD_GROWTH = 1.20`.
  Do not change these without explicit request.

## ProgressionSimulator Rules

`ProgressionSimulator` lives at `res://scripts/game/ProgressionSimulator.gd`. It is debug-only tooling.

- It creates a local `ClickerState` instance and simulates progression without touching `SaveManager` or the real player save.
- It is only invoked from `ClickerScreen._run_balance_simulation()`, which is guarded by `BuildConfig.IS_DEBUG_BUILD`.
- Press **F8** in debug mode to print progression tables to the Godot console and export `user://balance_simulation.csv`.
- Do not expose the simulator in any player-facing UI.
- See `docs/BALANCE.md` for output format and tuning workflow.

## BuildConfig Rules

`BuildConfig` is a global autoload registered in `project.godot`. It lives at `res://scripts/game/BuildConfig.gd`.

- `APP_VERSION` — the human-readable version string shown in SettingsWindow.
- `IS_DEBUG_BUILD` — controls all dev-only visibility. Do not rely on `OS.is_debug_build()` for this purpose: Web and Android test builds need manual control.

**Debug mode** (`IS_DEBUG_BUILD = true`):
- Shop `TestGemsButton` ("Prototype: Get 50 Gems") is visible.
- SettingsWindow version label reads "Version X.Y.Z-dev".
- `ClickerScreen._input` F5/F9/F10/F12/L/K debug shortcuts are active.
- Fake ad/payment success is active for testing.

**Release mode** (`IS_DEBUG_BUILD = false`):
- `TestGemsButton` is hidden; VBoxContainer layout collapses the gap automatically.
- SettingsWindow version label reads "Version X.Y.Z".
- All keyboard debug shortcuts are disabled.
- Fake ad/payment success is disabled.

**F12 Debug Visual Test Mode** (debug builds only):
- Press **F12** to toggle. Activated state is stored in `ClickerState.debug_visual_test_mode_enabled`.
- **L** — deals 51% of target HP as instant damage.
- **K** — clears the current level and advances to the next.
- While F12 mode is ON (`ClickerState.is_debug_purchase_override_enabled()` returns `true`):
  - All gold-based purchases cost exactly **1 gold**.
  - All 28 partner rows are visible; gold-based reveal requirement is bypassed.
  - All building rows are visible; previous-building ownership requirement is bypassed.
  - Ability unlock level requirements are ignored.
  - Hero skill, ability skill, and partner skill level/count requirements are ignored.
  - Boss timer does not count down.
  - Enemy HP is capped at `DEBUG_VISUAL_TEST_HP` (100 000) for visual testing.
- Debug purchases modify runtime state normally. Use F10 (delete save) carefully when testing.
- Gems costs, prestige costs, and shop products that cost gems are **not** affected by the override.

**Rules:**
- Do not remove `_on_test_gems_requested` or the `test_gems_requested` signal — they are used during development.
- Do not add new debug tools without wrapping them in `if BuildConfig.IS_DEBUG_BUILD`.
- Do not manually force `IS_DEBUG_BUILD` in source. Use a proper release export to produce
  a production build where `OS.is_debug_build()` returns false.

## UI Font Size Rules

UI font sizes are centralized in `res://scripts/ui/UiFontConfig.gd`. This is the only file where common UI font size constants should be tuned.

- To make HUD values larger: change `UiFontConfig.HUD_VALUE_FONT_SIZE`. Do not increase the global theme font size.
- To adjust bottom tab text: change `UiFontConfig.BOTTOM_TAB_FONT_SIZE`.
- To adjust partner card text: change `PARTNER_TITLE_FONT_SIZE`, `PARTNER_INFO_FONT_SIZE`, `PARTNER_MILESTONE_FONT_SIZE`, or `PARTNER_BUTTON_FONT_SIZE`.
- To adjust upgrade card text: change `UPGRADE_TITLE_FONT_SIZE`, `UPGRADE_INFO_FONT_SIZE`, `UPGRADE_MILESTONE_FONT_SIZE`, or `UPGRADE_BUTTON_FONT_SIZE`.
- To adjust StageNavigator labels: change `STAGE_NUMBER_FONT_SIZE` or `STAGE_SIDE_BUTTON_FONT_SIZE`.
- To adjust ProgressInfoPanel labels (zone name, enemies count, enemy name, HP bar text): change `PROGRESS_ZONE_FONT_SIZE`, `PROGRESS_ENEMIES_FONT_SIZE`, `PROGRESS_ENEMY_NAME_FONT_SIZE`, or `PROGRESS_HP_TEXT_FONT_SIZE`.
- BossTimerLabel has its own full theme applied via `UiFontConfig.apply_boss_timer_theme()`. Tune it with `PROGRESS_BOSS_TIMER_FONT_SIZE`, `PROGRESS_BOSS_TIMER_FONT_COLOR`, `PROGRESS_BOSS_TIMER_OUTLINE_COLOR`, `PROGRESS_BOSS_TIMER_OUTLINE_SIZE`, `PROGRESS_BOSS_TIMER_FONT_PATH` (`.ttf`), and `PROGRESS_BOSS_TIMER_FONT_FALLBACK_PATH` (`.otf`).
- The global theme (`themes/main_theme.tres`) keeps Button and Label font size at 22. Do not raise it to fix HUD readability.
- Use `UiFontConfig.apply_label_font_size(label, size)` and `UiFontConfig.apply_button_font_size(button, size)` to apply overrides at runtime.
- Do not add font size magic numbers to individual UI panels; put new font size constants in `UiFontConfig.gd`.

## Localization Workflow Rules

All player-facing strings live in `res://localization/game_text.csv`. The `LocalizationData.gd` file is auto-generated from the CSV and must always be in sync before export.

**After editing `game_text.csv`:**
1. The editor plugin (`addons/localization_sync`) auto-regenerates `LocalizationData.gd` within 2 seconds.
2. Before exporting, the export hook regenerates it again automatically.
3. Always commit both `game_text.csv` and `LocalizationData.gd` together.

**Validation commands:**
```
godot --headless --script res://scripts/tools/ValidateLocalizationDataFreshness.gd
godot --headless --script res://scripts/tools/ValidateLocalizationExport.gd
```

Both must exit 0 before a Web export is shipped.

**Android still shows old text — checklist:**
1. Open `Project → Export`. Confirm Output panel shows:
   `LocalizationSyncPlugin: generated N localization keys.`
   If absent, the plugin is disabled — enable it in **Project Settings → Plugins**.
2. Run `ValidateLocalizationDataFreshness.gd`. Exit 1 = stale. Run `GenerateLocalizationData.gd` to fix, then re-export.
3. Root cause: Android cannot reliably read raw CSV via `FileAccess`. `LocalizationData.gd` (compiled GDScript) is the only guaranteed source — keep it in sync.

See `docs/LOCALIZATION.md` for the full architecture and troubleshooting guide.

## Zone Config Rules

- Zone definitions live in `scripts/game/config/ZoneConfig.gd` — not in `ClickerState.gd`.
- Do not add zone data back to `ClickerState`; use `ZoneConfig.ZONE_DATA` and `ZoneConfig` helpers everywhere.
- When adding a new zone, extend `ZoneConfig.ZONE_DATA`, add enemy/background asset folders, and update `EnemyAssetCatalog` / `BackgroundAssetCatalog` as needed.

## Prestige Rules

- Prestige reward formula: `floor(current_level / PRESTIGE_REQUIRED_LEVEL) + floor(character_level / PRESTIGE_CHARACTER_INTERVAL)` — see `BalanceConfig` for the actual constants.
- Talent cost formula: `ceili(PRESTIGE_TALENT_BASE_COST * PRESTIGE_TALENT_COST_GROWTH ^ level)` — see `BalanceConfig`.
- Talent bonus percentages are defined in `BalanceConfig` (`PRESTIGE_DAMAGE_TALENT_BONUS_PERCENT_PER_LEVEL`, `PRESTIGE_GOLD_TALENT_BONUS_PERCENT_PER_LEVEL`, `PRESTIGE_UTILITY_TALENT_BONUS_PERCENT_PER_LEVEL`).
- Prestige points do not provide passive bonuses on their own — only purchased talent levels do.
- Prestige talents survive Reset Progress and Prestige; normal progression does not.

## Android Release Rules

- **Never commit keystore files** (`.jks`, `.keystore`, `.p12`), passwords, key aliases,
  or local signing paths. These are machine-specific credentials that must stay out of git.
- **Never commit APK or AAB release builds** (`*.apk`, `*.aab`, `/godot_apk/`). These are
  local build artifacts covered by `.gitignore`.
- **Release validation tooling must remain read-only.** `tools/validate_android_release.py`
  must not modify files, build APKs, change export presets, increment versions, or read
  signing passwords. Do not add write operations to this script.
- **Do not embed keystore paths, passwords, or local secrets** in any validation script or
  tool. Use only placeholder labels or command descriptions.
- **Do not bypass failed validation before a RuStore upload.** If
  `tools/validate_android_release.py` exits with code 1, fix the failing checks before uploading.
- **Do not change package name** (`com.stanis.shinobiclickeridle`) after first upload.
- **Do not decrease `version/code`** after any upload.
- **Do not change the package name** (`com.stanis.shinobiclickeridle`) after the first
  RuStore upload. A package name change creates a new app listing and breaks updates for
  all existing installs.
- **Do not reset or decrease `version/code`** after any upload. The next uploaded APK must
  always have a strictly larger `version/code` than the previous upload.
- **Do not modify release signing settings** (`package/signed`, keystore fields in
  `export_presets.cfg`) without an explicit user request. Changing these can break release builds.
- **RuStore Pay remains blocked** until the official RuStore Pay SDK AAR/API is provided by
  the RuStore developer portal. Do not stub in fake SDK class names or invent API signatures.
- **Release docs and checklists must stay updated** whenever `export_presets.cfg` changes
  (version/code, version/name, SDK settings, permissions). Keep
  `docs/rustore_readiness_checklist.md`, `docs/android_release_signing.md`, and
  `docs/android_release_validation.md` in sync with the actual export preset.

## AuthGate UI Rules

- `AuthGateScreen` must always be full-screen. Call
  `set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)` with
  `SIZE_EXPAND_FILL` in `_ready()` **before** `_build_ui()`. Do not rely on the
  parent to set the correct size.
- `Main._show_auth_gate()` and `Main.show_auth_gate_overlay()` must also call
  `set_anchors_and_offsets_preset(PRESET_FULL_RECT)` on the gate after
  `add_child()` as a second safety layer.
- Do **not** use zero-height containers (`custom_minimum_size = Vector2(x, 0)`)
  anywhere in the mandatory startup UI path. Every container between the root
  node and the visible form must have a non-zero height.
- The auth form layout must use `MarginContainer(full-rect) →
  CenterContainer(EXPAND_FILL) → PanelContainer(explicit min height)`. The
  `ScrollContainer` that had `custom_minimum_size = Vector2(340, 0)` is removed.
- AuthGate startup must always end in one of: login form visible, register form
  visible, or `auth_gate_completed` emitted. It must never leave a black screen.
- If `backend_get_me()` is called on startup, a timeout fallback (≥ 6 s) must
  clear the local auth token and show the login form so the player is never
  stuck in CHECKING state if the backend does not respond.
- Do **not** use `.keyboard_type` on `LineEdit`. The property name is invalid on
  the Godot 4.5.1 Android `LineEdit` object and causes a script error that aborts
  UI construction.
- Any virtual keyboard hint must be set through a safe helper that checks property
  existence first:
  ```gdscript
  func _try_set_virtual_keyboard_type(edit: LineEdit, keyboard_type: int) -> void:
      if edit == null:
          return
      if "virtual_keyboard_type" in edit:
          edit.set("virtual_keyboard_type", keyboard_type)
  ```
  Virtual keyboard hints are optional UI optimizations — they must never be
  required for UI construction to succeed.
- `AuthGateScreen._set_state()` must null-check every box variable before
  assigning `.visible`. A partially built UI must not cascade into secondary
  `Nil.visible` errors.
- `AuthGateScreen._ready()` must verify that critical UI nodes were created after
  `_build_ui()` returns. If the check fails, display a fallback error label
  (never a black screen) and do not proceed to `_connect_platform_signals()` or
  `_check_existing_session()`.
- `AuthGateScreen` must never leave the screen black on any startup failure.

## Account Settings UI Rules

- The account section in `SettingsWindow` is shown **only on Android**
  (`OS.has_feature("android")`). It must be hidden (or not created) on Web/editor to
  avoid confusing Yandex Games users and to prevent stray backend calls on Web.
- `SettingsWindow` must call backend operations **only through `Platform`**. It must
  never instantiate or reference `BackendApiClient` directly.
- `SettingsWindow` must never call `SaveManager` for backend cloud-save operations.
- The `account_auth_requested` signal on `SettingsWindow` is the only way settings
  triggers an AuthGate open. `ClickerScreen` listens and delegates to
  `Main.show_auth_gate_overlay()`.
- `Main.show_auth_gate_overlay()` must **not** re-instantiate `ClickerScreen`. It
  removes the overlay when `auth_gate_completed` fires and stores the new auth mode.
  Gameplay continues uninterrupted.
- Do **not** create a second `AuthGateScreen` if one already exists (`_auth_gate` guard).
- Logout must **not** delete the local game save. Call `Platform.backend_logout()` and on
  any failure call `Platform.backend_clear_local_auth()` as a fallback so the user can
  always return to a no-session state.
- Email verification codes must **never** be logged or stored in script variables beyond
  the temporary LineEdit text that is cleared after use.
- Do not auto-upload guest saves when the user signs in from settings.
- The account section in `SettingsWindow` connects to `Platform.backend_auth_changed`,
  `Platform.backend_operation_succeeded`, and `Platform.backend_operation_failed` only
  for operations it initiates: `logout`, `request_email_verification`,
  `confirm_email_verification`, `save_save`. All other operations must be ignored
  (match by operation string, not wildcard). `load_save` result is handled by
  `ClickerScreen`, which calls `settings_window.set_cloud_save_status()`.
- Disconnect Platform signals in `_exit_tree()` to avoid callbacks on freed nodes.

## Manual Cloud Sync Rules (C5.1)

- Manual backend cloud sync is **account-only on Android/RuStore**. Guest mode
  must never call `Platform.backend_save_save()` or `Platform.backend_load_save()`.
- `SettingsWindow` must **not** apply cloud save data. It emits signals
  (`cloud_save_upload_requested`, `cloud_save_download_requested`) and shows status
  labels via `set_cloud_save_status()`. `ClickerScreen` owns all data operations.
- `SaveManager` must **not** call `Platform` or any backend method. The two new
  helpers (`get_cloud_save_payload`, `apply_cloud_save_payload`) are pure file-IO.
- `SaveManager.get_cloud_save_payload()` always reads from the local save file.
  `ClickerScreen` must call `_save_game_now()` before calling it to ensure the
  disk has the latest state.
- `SaveManager.apply_cloud_save_payload()` validates `save_version > 0` and
  `last_save_unix_time > 0` before writing. Return `false` on any failure — do not
  overwrite the existing local save on invalid payloads.
- Loading from cloud must require a **confirmation step** before emitting
  `cloud_save_download_requested`. Never apply cloud saves without user confirmation.
- Do not log full save payloads. `get_cloud_save_payload()` and `apply_cloud_save_payload()`
  must not print JSON or save content.
- Automatic cloud-save, startup cloud-load, and conflict resolution are **future patches**.
  Do not add them to this flow.
- Web/Yandex cloud-save via `YandexBridge` is completely separate and must remain
  unchanged. The backend cloud-sync UI must never appear on Web/editor.

## Cloud Restore Prompt Rules (C5.3 — removed in C7.3.4)

> **C7.3.4 deleted `CloudRestorePrompt` entirely** (`scenes/ui/CloudRestorePrompt.gd`/`.tscn`,
> all `_startup_cloud_restore_*`/`_pre_startup_*` state and methods in `ClickerScreen.gd`,
> and the `cloud_restore.*` localization keys). The rules below are kept for historical
> context only — do not reintroduce any of this. Account cloud save is authoritative and
> force-loads silently at startup/login (C7.3.1); there is no local-vs-cloud conflict
> prompt anymore. `AccountWindow` also no longer has a manual "Load from Cloud" action
> (see the C7.3.4 rules below) — `_manual_backend_cloud_download_requested` no longer
> exists either.
>
> - Never apply backend cloud saves without user confirmation — historically enforced by
>   `CloudRestorePrompt` signals; now enforced by the account-authority model instead
>   (force-load is itself the "confirmation" — there is nothing to confirm).
> - Startup cloud restore check was Android account-only, guarded by
>   `OS.has_feature("android") and Platform.backend_has_session()`.
> - Guest mode must never call backend load or save — still true; enforced by
>   `_gameplay_started_as_guest` guards in the force-load paths.
> - Web/Yandex cloud-save remains SDK-based via `YandexBridge`/`WebYandexPlatform` —
>   still true and unaffected by this removal.
> - `ClickerScreen` still owns applying the cloud save and refreshing gameplay UI in the
>   force-load paths: `SaveManager.apply_cloud_save_payload()` → `SaveManager.load_data()`
>   → `state.apply_save_data()` → `_reset_runtime_state_for_new_game()` →
>   `_sync_boss_timer()` → `_update_ui()`.
> - Do not log full save payloads — still true for all cloud-save code paths.

## Guest → Account Migration Prompt Rules (C5.4 — superseded by C7.1)

> **C7.1 replaced the `GuestMigrationPrompt` mid-session flow.** The rules below are
> kept for historical context. Do not reintroduce `GuestMigrationPrompt` unless the
> product rule changes. See the C7.1 rules below for the current authority model.

- **`GuestMigrationPrompt` is fully removed at runtime (C7.1.1) and its files are
  deleted (C7.2.5).** The node is not present in `ClickerScreen.tscn`.
  `ClickerScreen.gd` has no `@onready` declaration, no visibility checks, and no
  signal connections for this prompt. `GuestMigrationPrompt.gd/.tscn` and their
  `guest_migration.*` localization keys no longer exist in the repo.
- **Do not reintroduce `GuestMigrationPrompt` or `_maybe_show_guest_migration_prompt()`**
  unless explicitly requested by the product owner — it must not be instantiated
  or referenced anywhere at runtime.

## Account Save Authority & Guest Shop Lock Rules (C7.1)

- **Account cloud save is the authority when logging in to an existing account.**
  `on_account_login_from_guest_overlay()` must force-load the account cloud save and
  must **never** upload the current guest save.
- **Guest progress migrates only on new account registration.**
  `on_account_registered_from_guest_overlay()` uploads the current local save to the
  new account's cloud. This is the only path for guest-to-account save migration.
- **Login to an existing account from Guest must not upload guest save.**
  Backend auto-upload must be suspended before calling `Platform.backend_load_save()`.
- **If the account has no cloud save on Guest → Login, start a clean default save.**
  Do not carry over guest gems, progress, or any state into the account.
- **Android/RuStore paid gem purchases require a backend account session.**
  `_is_paid_shop_available()` returns `false` on Android without `Platform.backend_has_session()`.
  Opening `GemPurchaseDialog` and calling `Platform.purchase_product()` must both be
  guarded by this check.
- **Rewarded ads must remain available in Guest mode.** Never gate rewarded ad shop
  products or the rewarded banner behind `_is_paid_shop_available()`.
- **Paid shop state must refresh on auth changes.** `_on_platform_backend_auth_changed`
  is connected in `ClickerScreen._ready()` and calls `_update_shop_paid_availability()`.
  This handles logout locking the paid shop without requiring a scene restart.
- **`AuthGateScreen` must emit distinct result strings:**
  `"guest"`, `"account_session"` (stored-session `get_me` success),
  `"account_login"` (direct login), `"account_register"` (post-register login).
  Never emit the old `"account"` string.
- **`Main.gd` maps guest/account_* sources to `_startup_auth_mode` ("guest"/"account")**
  and routes overlay results to the correct ClickerScreen method without recreating
  the ClickerScreen scene.
- **`_gameplay_started_as_guest` is set by `set_startup_auth_mode()` called from Main.gd**
  before ClickerScreen `_ready()` runs. Set it to `false` after successful register
  upload or after login cloud-load completes (success or clean-save fallback).
- **`_force_account_cloud_load_after_guest_login` must be checked first** in the
  `load_save` success/failure handlers, before `_force_account_cloud_load_on_startup`'s
  sibling branches. Clear it and resume auto-upload at every exit point of that branch.
- **Do not show `CloudRestorePrompt` for the Guest → Login force-load flow.**
  The account save is applied immediately without user confirmation. (`CloudRestorePrompt`
  no longer exists as of C7.3.4 — this rule is kept because the "no conflict prompt,
  ever" principle still applies.)
- **Web/Yandex behavior is completely unaffected.** `_is_paid_shop_available()` returns
  `true` unconditionally on non-Android. No auth gate on Web startup.

## Account Startup Force Cloud Load Rules (C7.3.1)

- **Account cloud save is authoritative for every account session, not just Guest → Login.**
  Stored account session at boot, direct AuthGate login at boot, and account-register at
  boot all force-load the account cloud save the same way `on_account_login_from_guest_overlay()`
  already does. `CloudRestorePrompt` is no longer shown for any of these paths (and no
  longer exists at all as of C7.3.4).
- **`ClickerScreen._ready()` calls `_begin_account_startup_cloud_load()`.** The old
  `request_backend_cloud_restore_check("startup")` alternative was deleted in C7.3.4 along
  with the rest of the restore-prompt flow — do not reintroduce it.
- **`_begin_account_startup_cloud_load()` no-ops for Guest and for Web/editor.** It only
  proceeds when `OS.has_feature("android") and Platform.backend_has_session()` and
  `_gameplay_started_as_guest` is false. Backend auto-upload suspension is already set by
  `_should_suspend_backend_auto_upload_for_startup_restore()` earlier in `_ready()` under
  the same guard — `_begin_account_startup_cloud_load()` must resume it on every no-op path.
- **`_force_account_cloud_load_on_startup` is checked before `_force_account_cloud_load_after_guest_login`**
  in the `load_save` success/failure handlers — these are the only two force-load branches
  remaining as of C7.3.4.
- **Missing cloud save on force-load starts a clean account save**, via
  `_apply_clean_account_save_after_missing_cloud()` (renamed from
  `_apply_clean_account_save_after_guest_login()` — now shared by both the startup and
  Guest → Login force-load paths; it must never carry over guest gems/progress).
- **`Main.gd`'s `"account_session"` overlay branch also force-loads instead of prompting.**
  When AuthGate is reopened mid-session (`show_auth_gate_overlay()`) and revalidates a
  stored session, it calls `_clicker_screen.on_account_login_from_guest_overlay()` — the
  same guest→login force-load method. There is no restore-prompt alternative to call
  instead (deleted in C7.3.4).
- **Guest → Register upload behavior is unchanged.** `on_account_registered_from_guest_overlay()`
  still uploads the guest save; it is never affected by the startup force-load flag.

## AccountWindow / Settings Split Rules (C7.3.2)

- **`SettingsWindow` must remain basic settings only:** Sound, Music, Language, Save,
  Account button, Version. Detailed account/cloud UI (status, email, verification,
  Save/Load to Cloud, Logout) belongs in `AccountWindow`, not inline in `SettingsWindow`.
  Do not put it back inline — open `AccountWindow` instead.
- **`AccountWindow` must use a fixed-size outer `PanelContainer` and internal
  `BodyScrollContainer`/`BodyVBoxContainer` scrolling**, the same pattern as
  `SettingsWindow` (C7.2.7). Never resize the outer panel dynamically based on content,
  and never resize only one axis. It reuses the `"ui.window.settings.background"` texture
  key for visual consistency — no new art was commissioned for this patch.
- **`AccountWindow` owns its own Platform signal connections** (`backend_auth_changed`,
  `backend_operation_succeeded`, `backend_operation_failed`) for refreshing its own account
  section — moved verbatim from `SettingsWindow._connect_account_platform_signals()`.
  `ClickerScreen` does not need to poll or refresh `AccountWindow`'s account state; it only
  forwards cloud-save request signals and routes cloud status/busy updates to it.
- **`SettingsWindow.account_window_requested` → `ClickerScreen._on_settings_account_window_requested()`
  hides `SettingsWindow` and shows `AccountWindow`** (one modal at a time). Closing
  `AccountWindow` returns to gameplay, not back to `SettingsWindow`.
- **Cloud status/busy routing must go through `_set_account_window_cloud_status()` /
  `_set_account_window_cloud_buttons_busy()`,** not `settings_window.set_cloud_save_status()`
  (removed). Both helpers are safe no-ops if `account_window` isn't valid — cloud
  success/failure handlers must never crash regardless of which window is open.
- **Guards that previously checked `settings_window.visible` to decide whether to show a
  cloud status message now check `account_window.visible`** — the account/cloud UI lives
  there now, not in Settings.
- **`account_window.visible` must be included in ad-safety and rewarded-banner-visibility
  checks** (`_is_safe_for_fullscreen_ad()`, `_is_main_screen_clear_for_rewarded_banner()`)
  and in `_on_attack_requested()`'s blocked-input guard, the same way `settings_window.visible`
  already was.
- **Do not mix `AccountWindow` UI changes with cloud-save authority logic (C7.3.1) or
  Guest → Register/Login logic (C7.1).** This patch only moves *where* the UI lives; the
  underlying backend/cloud request flow, force-load flags, and signal payloads are
  byte-for-byte the same as before the split.
- **The Account button in `SettingsWindow` only exists on Android**
  (`_is_backend_account_ui_supported()` gate), matching the pre-existing Account/Cloud
  section gating. Web/Yandex never sees an Account button or `AccountWindow`.

## CloudRestorePrompt Cleanup & AccountWindow/Settings Polish Rules (C7.3.4)

- **Do not reintroduce `CloudRestorePrompt`.** See the C5.3 section above — it is fully
  deleted, not just unused. There is no local-vs-cloud conflict UI anywhere in the app.
- **`AccountWindow` must not have a user-facing "Load from Cloud" action.** The account
  cloud save is authoritative and force-loads automatically at startup/login (C7.3.1);
  a manual download button would let a user overwrite newer local progress with a stale
  cloud copy for no reason. `Save to Cloud` is the only manual cloud action in
  `AccountWindow`. If a future patch needs manual download back, treat it as a new
  product decision, not a revert of this cleanup.
- **`AccountWindow`'s signed-in state shows only `Email: ...` and
  `Email verified`/`Email not verified`**, plus `Save to Cloud` and `Logout`. Do not add
  back the big "Signed in"/"Guest mode" status label, the Verify Email button, the
  verification code input, or the Confirm Code button — those are deliberately gone from
  the UI (C7.3.4). `Platform.backend_request_email_verification()` and
  `backend_confirm_email_verification()` are untouched and may be re-wired to UI later if
  the product wants inline verification back; don't delete the backend methods.
- **`AccountWindow` action buttons (Sign in / Register, Save to Cloud, Logout) must use
  texture-scale centered sizing, not full-width stretch.** Use
  `custom_minimum_size = AccountWindow.ACTION_BUTTON_SIZE` (`Vector2(218, 75)`, matching
  the `SettingsWindow` Account button) and `size_flags_horizontal = Control.SIZE_SHRINK_CENTER`.
  Do not use `Control.SIZE_EXPAND_FILL` on these buttons.
- **`SettingsWindow` may only be resized proportionally on both X and Y, by the same
  scale factor, never dynamically.** Current fixed size is `648×630` (scaled `1.2×` from
  the original `540×525`, C7.3.4). If a future patch needs more room, pick a new scale
  factor and apply it to both axes — do not stretch one axis, do not compute size from
  content. `AccountWindow` keeps its own separate `540×525` fixed size; the two windows
  are not required to match.
- **Version must remain visible in `SettingsWindow` without scrolling in the normal
  layout** (Sound, Music, Language, Save, Account, Version — `BodyScrollContainer` should
  not need to scroll to reach `VersionLabel`). If content grows again and scrolling
  returns, prefer another proportional resize over shrinking rows or fonts.
- **UI polish patches like this one must not touch backend/cloud-save authority logic.**
  Account startup force-load (C7.3.1), Guest → Register upload, and Guest → Login
  force-load (C7.1) are all unchanged by C7.3.4 — only the UI presenting/triggering them
  changed.

## AuthGate Visual Rules (C7.3.3)

- **`AuthGateScreen` background uses the boot splash image** (same file as
  `project.godot`'s `boot_splash/image`, loaded via `AUTH_BACKGROUND_TEXTURE = preload("res://assets/images/app/boot_splash.png")`)
  for visual continuity between app boot and first login. It sits behind the dark overlay
  as a full-rect `TextureRect` with `mouse_filter = MOUSE_FILTER_IGNORE` and
  `STRETCH_KEEP_ASPECT_COVERED` — it must never intercept input or distort the aspect ratio.
- **The dark overlay above the splash must stay moderate (~0.25–0.45 alpha), never pure
  black/opaque.** The splash image must remain visible; only the panel text/inputs need
  full readability, not the whole screen.
- **The AuthGate login/register/reset `PanelContainer` must stay fully opaque
  (`bg_color.a == 1.0`).** It already is — do not lower it when touching this panel.
- **AuthGate `LineEdit` fields must use explicit opaque `normal`/`focus`/`read_only`
  `StyleBoxFlat` overrides** (see `_apply_opaque_line_edit_style()`) plus explicit
  `font_color`/`font_placeholder_color` — AuthGate builds its UI procedurally with no
  shared theme LineEdit style, so don't assume the default theme is opaque here.
- **Visual AuthGate patches must not change `auth_gate_completed` source strings, the
  stored-session check, login/register/reset request flow, or Continue as Guest.**
  AuthGate must keep calling the backend only through `Platform`, never `SaveManager` or
  `BackendApiClient` directly.
- **Do not mix AuthGate visual polish with cloud-save authority changes (C7.3.1) or
  Settings/AccountWindow changes (C7.3.2).** Keep these patches independently reviewable.

## Startup Upload Suspension Rules (C5.3.1)

- **`SaveManager._backend_cloud_auto_upload_suspended` guards `queue_backend_cloud_save()` only.** `upload_current_save_to_backend_cloud_now()` has no suspension guard and must never acquire one — manual Save to Cloud must always work.
- **Suspension is set in `ClickerScreen._ready()` before `_load_game_on_start_async()`**, only when `_should_suspend_backend_auto_upload_for_startup_restore()` returns true (Android + has_session). It is a no-op on Web and in guest mode.
- **Every restore-decision exit point must call `_resume_backend_auto_upload_after_restore_decision()`.** Missing a resume causes auto-upload to be silently disabled for the session. The `_exit_tree()` cleanup is a last-resort guard, not a substitute for explicit resumes.
- **`apply_cloud_save_payload()` calls `save_data()` which calls `queue_backend_cloud_save()`.** During a force-load flow, the call to `apply_cloud_save_payload` happens while suspension is still active; resume comes afterwards. This prevents an immediate re-upload of the newly written local save before the load is complete.
- **Web/Yandex cloud-save must remain completely unaffected.** The suspension flag lives in `SaveManager` but `queue_backend_cloud_save()` returns early for non-Android before it ever reaches the suspension check.

> The "restore prompt visible" and "Manual Settings Load from Cloud" bullets that used to
> live here were removed in C7.3.4 along with `CloudRestorePrompt` and `AccountWindow`'s
> manual download action — there is no longer a prompt to stay suspended for, and no
> manual download path to call resume from.

## Pre-Startup Local Save Snapshot Rules (C5.3.2 — removed in C7.3.4)

> **`_capture_pre_startup_local_save_snapshot()` and the `_pre_startup_*` fields it wrote
> (`_pre_startup_had_local_save`, `_pre_startup_local_timestamp`,
> `_pre_startup_local_save_snapshot_taken`) were deleted in C7.3.4** along with the rest
> of the `CloudRestorePrompt` flow that consumed them. Nothing in the current codebase
> needs a pre-startup local save snapshot — the account cloud save force-loads
> unconditionally and overwrites local state directly. Do not reintroduce this snapshot
> unless a future patch brings back some form of local-vs-cloud comparison.
- **If `_pre_startup_local_timestamp` is 0 (no `last_save_unix_time`) and cloud timestamp is valid, the restore prompt must appear.** The `cloud_time > 0 > 0` comparison handles this naturally — do not add a special case that suppresses the prompt.
- **Manual Settings Load from Cloud must not use the pre-startup snapshot.** It has its own confirmation flow and applies immediately after the user confirms.

## Backend API Client Rules

- Backend client code lives under `scripts/platform/backend/`.
- Gameplay and UI code must **never** call `BackendApiClient` directly.
  All backend operations go through `Platform` (the autoload).
- Android/RuStore backend implementation lives in `AndroidRuStorePlatform.gd`.
  It creates `BackendAuthStore` and `BackendApiClient` in `_ready()` and delegates
  all `Platform.backend_*` calls to the client.
- Web/Yandex Games cloud-save remains completely separate through the Yandex SDK
  (`YandexBridge` / `WebYandexPlatform`). Do not mix these two code paths.
  Backend operations on Web fail with `not_supported` via inherited stubs.
- The backend stores a raw JSON save blob. It does not know game-specific save
  fields. `save_version` and `last_save_unix_time` must be present in `save_data`
  before calling `Platform.backend_save_save()`.
- `BackendAuthStore` persists session data to `user://backend_auth.json`. This
  file must never be committed to the repository (covered by `.gitignore` via
  `user://`).
- **Never log passwords, session tokens, reset codes, verification codes, or full
  save JSON.** `BackendAuthStore` and `BackendApiClient` enforce this; do not add
  any `print` or `push_warning` that includes these values.
- The backend base URL is committed in `project.godot` as
  `application/cloud_save/backend_url`. It is a public API Gateway endpoint — not a
  secret. Never commit passwords, SMTP keys, or service-account keys.
- `BackendApiClient` reads the URL via `configure_from_project_settings()` at
  Android startup. Do not hardcode the backend URL anywhere in game code.
- **If `is_configured()` is false**, all request methods emit
  `operation_failed(op, "not_configured", 0, {})` and return `false` without
  touching the network.
- **If a protected endpoint is called without a session token**, the client emits
  `operation_failed(op, "missing_session", 0, {})` and returns `false` without
  sending any HTTP request.
- Backend auto-upload (`queue_backend_cloud_save`) is Android + account-session only. It must be a no-op on Web and in Guest mode. The guard is `OS.has_feature("android") and Platform.backend_has_session()`.
- Do not call `Platform.backend_load_save()` or `SaveManager.apply_cloud_save_payload()` automatically. Cloud download is always manual and confirmation-based.
- Do not apply cloud saves automatically. No startup cloud auto-load.
- Backend upload failures must not fail local saves or interrupt gameplay. Silent `push_warning` is the correct response for background auto-upload failures.
- Do not log full save payloads (JSON) or tokens/passwords in any backend cloud save code path.
- All `backend_save_save` calls must go through `SaveManager` methods (`queue_backend_cloud_save`, `upload_current_save_to_backend_cloud_now`). Do not call `Platform.backend_save_save()` directly from UI or ClickerScreen.
- `SaveManager.mark_backend_cloud_upload_finished(success)` must be called from ClickerScreen when every `save_save` backend operation completes (success or failure) so in-flight and retry state stays consistent.
- Do not add account UI until an account UI patch is explicitly requested.
- Backend error codes (e.g. `invalid_credentials`, `email_already_registered`,
  `missing_save_version`) are preserved verbatim by `BackendApiClient`. Do not
  translate or remap them in the client layer — UI handles that.
- Non-2xx responses with a parseable `error` field use that backend error code.
  Non-2xx responses without parseable JSON emit `http_error`.
- 2xx responses with empty body emit `empty_response`. 2xx responses with
  non-JSON or non-Dictionary body emit `invalid_json_response`.

## Documentation Update Rules

Update this file when adding important systems, scenes, architecture decisions, workflow rules, or validation requirements. Keep README.md aligned with major project setup or workflow changes.
