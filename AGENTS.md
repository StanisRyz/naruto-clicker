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

- The `AndroidRuStorePay` Godot plugin (`addons/android_rustore_pay/`) is the
  ONLY place where RuStore Pay SDK calls may live. Gameplay code and the platform
  bridge must not call RuStore SDK types directly.
- **Never use the deprecated RuStore BillingClient.** All payment work must use the
  RuStore Pay SDK (newer product-based API). The AGENTS.md payment rules forbid
  BillingClient.
- **Never grant paid rewards inside the Kotlin plugin.** The plugin only emits
  `purchase_success(productId, purchaseToken)` — the GDScript handler in
  `ClickerScreen._on_payment_purchase_success()` is the only place a reward is
  applied to game state.
- **Never invent RuStore Pay SDK API names.** If the real SDK is not available,
  keep the compile-safe stub and document the missing external SDK step.
  Do not guess class names or method signatures.
- Plugin singleton name: `"AndroidRuStorePay"`.
  Check availability with `Engine.has_singleton("AndroidRuStorePay")`.
- Signal contract (plugin → GDScript):
  - `purchase_success(productId: String, purchaseToken: String)` — purchase completed
  - `purchase_cancelled` — user closed the RuStore UI without paying
  - `purchase_error(message: String)` — SDK error
  - `pending_purchase_found(productId: String, purchaseToken: String)` — recovery
  - `pending_purchases_check_completed` — recovery check done, no pending items
  - `pending_purchases_check_error(message: String)` — recovery check failed
- `AndroidRuStorePlatform._on_rustore_purchase_success(platform_product_id, purchase_token)`
  uses `_pending_local_product_id` (not `platform_product_id`) when emitting
  `payment_purchase_success` so `ClickerScreen` sees the local product id.
- `consume_purchase(purchase_token)` must be called after every successful grant.
  In RuStore Pay SDK terms, `purchaseToken` is the `purchaseId` returned by the SDK.
- `check_unprocessed_purchases()` calls `plugin.get_pending_purchases()`. When the
  plugin is absent (stub not wired), it falls back to emitting
  `unprocessed_purchase_check_completed` so the startup check completes cleanly.
- The AndroidRuStorePay plugin AAR must be built before each Android export.
  See `docs/rustore_pay_integration.md` for the build command and integration checklist.
- All RuStore Pay SDK calls must run on the Android UI thread (`activity.runOnUiThread { ... }`).
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

## Documentation Update Rules

Update this file when adding important systems, scenes, architecture decisions, workflow rules, or validation requirements. Keep README.md aligned with major project setup or workflow changes.
