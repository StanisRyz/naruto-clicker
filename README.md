# Naruto Clicker / Anime Ninja Idle Clicker

## Project status

Release-candidate / pre-publication for Yandex Games. All core systems are
implemented and ready for final local/Yandex Preview verification. Future work
should focus on QoL improvements, polish, and moderation/release blocking fixes
only. Do not propose major new mechanics or balance changes unless explicitly
requested.

## Tech stack

- Engine: Godot 4.5.1
- Language: GDScript
- Export targets: Web / HTML5 (primary), Android (in progress)
- Platform SDK: Yandex Games (Web), RuStore Pay / Yandex Mobile Ads (Android)
- Layout: vertical mobile portrait

## Platform architecture

All platform-specific calls go through the `Platform` autoload
(`res://autoload/Platform.gd`). Gameplay and UI code must never call
`YandexBridge` directly.

| Export | Active implementation |
|---|---|
| Web (`OS.has_feature("web")`) | `WebYandexPlatform` — delegates to `YandexBridge` |
| Android (`OS.has_feature("android")`) | `AndroidRuStorePlatform` — Yandex Mobile Ads + RuStore Pay |
| Editor / other | `LocalDebugPlatform` — simulates flows in debug builds only |

`Platform` selects the correct implementation at startup, creates it as a
child node, and re-exposes all signals so callers only deal with `Platform`.

### Web / Yandex

`WebYandexPlatform` wraps `YandexBridge`. All SDK internals (JavaScript
callbacks, LoadingAPI, GameplayAPI, Yandex Payments, cloud save) remain
unchanged inside `YandexBridge`. `Platform` forwards `YandexBridge` signals
directly to its own signals, so no behavior changes exist on the Web export.

### Android / RuStore

`AndroidRuStorePlatform` bridges the Yandex Mobile Ads SDK for ads and RuStore
Pay SDK for payments.

**Ads** (active — Yandex Mobile Ads SDK via `AndroidYandexAds` plugin):
- Ad flow is delegated to the `AndroidYandexAds` Godot plugin
  (`addons/android_yandex_ads/`). The plugin must be built and the export plugin
  enabled before Android exports.
- `show_rewarded_ad(placement_id)` / `show_fullscreen_ad(placement_id)` validate
  the placement id and ad unit id before calling the plugin; if either is missing
  they emit a clean error — no crash, no stuck flags.
- All rewards are granted only by the GDScript `rewarded_ad_rewarded` signal
  handler in `ClickerScreen`; the Kotlin plugin never modifies game state.
- Ad unit ids are configured in `scripts/game/config/AdPlacementConfig.gd`
  (`android_ad_unit_id` per placement). All 4 placements have real Yandex Mobile
  Ads unit ids; real-device testing is required before release.

**Payments** — official RuStore Pay SDK via `RuStoreGodotPayClient` (`addons/RuStoreGodotPay/`):
- `AndroidRuStorePlatform` uses `RuStoreGodotPayClient.get_instance()` with guards for
  `OS.has_feature("android")`, `Engine.has_singleton("RuStoreGodotPay")`, and `"RuStoreGodotCore"`.
- Purchase type: `ONE_STEP` consumable — SDK auto-confirms; no explicit consume call needed.
- `check_unprocessed_purchases()` calls `get_purchases(CONSUMABLE_PRODUCT, CONFIRMED)`.
- Empty purchase id from `on_purchase_success` is rejected — no reward granted.
- Old custom adapter `addons/android_rustore_pay/` is deprecated and not used.
- `android/build/res/values/rustore_values.xml` must be configured locally (not committed).
- See `docs/rustore_pay_integration.md` for the full setup and test checklist.

**Cloud save / lifecycle**: no-ops; `load_cloud_save` emits `cloud_save_loaded({})`.

No existing Web/Yandex behavior is affected.

### Android ads plugin

Plugin: `addons/android_yandex_ads/` — Godot 4 Android plugin v2.
Singleton: `Engine.get_singleton("AndroidYandexAds")`.
SDK: `com.yandex.android:mobileads:8.1.0` via `https://maven.yandex.ru/`.
Enabled in `project.godot` via `[editor_plugins]`.

**The plugin AAR must be built before each Android export.** See
`docs/android_ads_build.md` for full build instructions, Logcat tags, and
the callback mapping between Kotlin events and GDScript signals.

Ad unit ids live only in `scripts/game/config/AdPlacementConfig.gd`
(`android_ad_unit_id` per placement). Keep them empty until Yandex Mobile Ads
dashboard placements are created — empty ids fail safely with an error signal.

Rewarded rewards are granted only in `ClickerScreen._on_rewarded_ad_rewarded()`;
the Kotlin plugin never modifies game state.

### Android payments

SDK: official RuStore Godot Pay SDK (`addons/RuStoreGodotPay/` + `addons/RuStoreGodotCore/`).
Client: `RuStoreGodotPayClient` GDScript class.
Singletons: `Engine.get_singleton("RuStoreGodotPay")` / `"RuStoreGodotCore"`.
Both plugins enabled in `project.godot` via `[editor_plugins]`.

The old custom adapter `addons/android_rustore_pay/` is **deprecated** and not
enabled. Do not re-enable it.

Product ids per platform live in `scripts/game/config/GemPurchaseConfig.gd`
(`rustore_product_id` per product). Update to match the RuStore developer console.

Local files required before export (not committed — `/android/` is in `.gitignore`):
- `android/build/res/values/rustore_values.xml` — Application ID
- `android/build/AndroidManifest.xml` — RuStore metadata + intent filter activity

All paid rewards are granted only in `ClickerScreen._on_payment_purchase_success()`;
the SDK never modifies game state.

## Display / resolution

Two layout targets are supported:

| Platform | Viewport | Aspect |
|---|---|---|
| Android (default) | 720×1600 | 9:20 |
| Web / Yandex Games | 720×1280 | 9:16 |

- Stretch mode: `canvas_items`
- Stretch aspect: `keep`
- Scale mode: `fractional`
- Orientation: portrait

The Web viewport override is implemented as a Godot 4 feature-tag project
setting override (`window/size/viewport_height.web=1280`) in `project.godot`.
Android and the editor use the default 720×1600 value. No runtime code is
involved.

Do **not** switch to `viewport` stretch mode — it makes assets pixelated on
high-DPI phones. Do not use `expand` or `ignore` aspect unless explicitly
requested.

## Yandex lifecycle / runtime pause

### Startup flow

- `LoadingAPI.ready()` is called only after `ClickerScreen.startup_completed`
  fires, ensuring the UI is interactive before Yandex marks the game loaded.
- The initial `GameplayAPI.start()` is routed through
  `ClickerScreen.notify_yandex_game_ready()`, which calls `game_ready()` then
  `_try_resume_yandex_gameplay()`.
- `Main.gd` must **not** call `YandexBridge.gameplay_start()` directly. It
  calls `clicker_screen.notify_yandex_game_ready()`.

### Runtime pause

A multi-reason pause dictionary (`_runtime_pause_reasons`) in `ClickerScreen`
controls whether gameplay ticks. Active reasons: `payment`, `rewarded_ad`,
`fullscreen_ad`, `platform`, `hidden`.

`GameplayAPI.stop()` must be paired with adding a pause reason.
`GameplayAPI.start()` must go through `_try_resume_yandex_gameplay()`, which
checks all of:
- `_is_initialized`
- `_runtime_pause_reasons` is empty
- `YandexBridge.is_ad_in_progress()` is false

Gameplay that must not tick during any runtime pause:
- boss timer
- ability timers and cooldowns
- fullscreen ad cooldown
- autoclick accumulator
- partner DPS accumulator
- enemy transition waits (`_wait_runtime_seconds`)
- manual attacks

`game_api_pause` / `game_api_resume` platform signals are forwarded to
`_set_runtime_pause_reason("platform", …)`.

Page visibility (`visibilitychange` / `pagehide` / `pageshow`) sets the
`hidden` pause reason.

## Core gameplay systems

- **Tapping** — tap the enemy to deal click damage; critical hits possible via partner skills.
- **Partner DPS** — 28 partner tiers provide passive damage per tick (major power source).
- **BigNumber economy** — gold, costs, rewards, enemy HP, damage, and DPS all use BigNumber
  (mantissa/exponent base-1000, compact display). Do not use raw `int` literals for large values.
- **Upgrades / skills** — hero level upgrades and purchasable passive skill icons for hero, partners, and abilities.
- **Active abilities** — Autoclick, Gold Bonus, Focus Burst, Rally (unlocked through Upgrade tab, improved by passive skills).
- **Settlement / buildings** — six buildings with bulk-buy and milestone multipliers; 0.1% bonus per purchased building level; reset on prestige.
- **Tasks** — 5 active repeatable tasks from a pool of 10; claim for scaled gold rewards.
- **Prestige** — spend prestige points on permanent talents that survive reset.
- **Stage navigation** — horizontal strip navigator; auto-transition toggle; farmable boss levels.
- **Boss levels** — every 10th level; 30-second timer; fail returns to previous level.
- **Offline reward** — accumulates gold while the game is closed; claim via dialog on return.

Enemy scaling constants (do not change without explicit request):
- `ENEMY_HP_GROWTH = 1.26`
- `ENEMY_REWARD_GROWTH = 1.20`

## Monetization systems

### Floating rewarded ad banner (shown on main screen only)

Appears only on the clear main screen. Reward is randomly selected per viewing:

- x2 all damage for 60 seconds
- x4 enemy kill gold for 60 seconds
- +5 gems

- Initial cooldown: 300 seconds after game load.
- Cooldown between viewings: 300 seconds.
- Visible/available lifetime: 60 seconds. If not clicked within 60 s the banner
  disappears and the normal 300 s cooldown begins.

### Shop rewarded ad

- +3 gems after rewarded success.

### Offline reward ad

- Watch ad to claim offline gold ×3 (instead of ×1).

### Ad placement config

Logical ad placements are defined in `scripts/game/config/AdPlacementConfig.gd`.
Each placement has a stable string id and a per-platform ad unit id field.

| Placement id | Type | Used in |
|---|---|---|
| `rewarded_shop_gems` | rewarded | Shop — +3 gems ad button |
| `rewarded_bonus_banner` | rewarded | Floating rewarded banner |
| `rewarded_offline_gold_x3` | rewarded | Offline reward ×3 ad |
| `fullscreen_auto_interstitial` | fullscreen | Auto cooldown interstitial |

`android_ad_unit_id` in each placement is empty until real unit ids are
created in the Yandex Mobile Ads dashboard and filled in. `AndroidRuStorePlatform`
reads these ids at runtime via `AdPlacementConfig.get_platform_ad_unit_id()`. On
Web (`WebYandexPlatform`) the placement id is accepted but ignored — the Yandex
Web SDK does not use per-placement unit ids. On editor/debug (`LocalDebugPlatform`)
the placement id is also accepted but ignored.

### Fullscreen ads

- No reward granted.
- Safe cooldown-based display only.
- Must not appear during active user interaction, purchases, rewarded ads, dialogs, or other unsafe states.
- A UI input overlay blocks accidental clicks while the fullscreen ad is in progress.

### Rewarded ad rules

- Reward is granted only in the `onRewarded` / `rewarded_ad_rewarded` callback.
- `onClose` without prior reward grants nothing. `onError` grants nothing.
- Before showing any ad: add the relevant runtime pause reason, call
  `AudioManager.pause_for_ad()`, call `GameplayAPI.stop()`.
- After close/error: clear the pause reason and call
  `_try_resume_yandex_gameplay()`. Do not call `GameplayAPI.start()` directly
  from ad handlers.
- Rewarded buff timers (`rewarded_ad_all_damage_x2_expires_at`,
  `rewarded_ad_gold_x2_expires_at`) are compensated for runtime pause: if a
  buff was active when pause started, its expiry is extended by the paused
  wall-clock duration when gameplay resumes.

### Donation gem purchases

| Local ID | Yandex product | RuStore product | Gems | Price |
|---|---|---|---|---|
| `gems_25` | `gems_25` | `gems_25` | +25 gems | 24 RUB |
| `gems_150` | `gems_150` | `gems_150` | +150 gems | 99 RUB |
| `gems_500` | `gems_500` | `gems_500` | +500 gems | 249 RUB |
| `gems_1500` | `gems_1500` | `gems_1500` | +1500 gems | 499 RUB |

Both `yandex_product_id` and `rustore_product_id` are defined in
`GemPurchaseConfig.gd`. `GemPurchaseConfig.get_platform_product_id(id, key)`
resolves the store-specific ID at runtime via `Platform.get_platform_key()`.
Update `rustore_product_id` values to match actual RuStore product registrations
before publishing to RuStore.

**Purchase safety rules (all platforms):**

- Paid gems are granted only after a success callback that carries a **non-empty
  purchase id / order id**. An empty id must not grant gems.
- Duplicate success callbacks must not double-grant. Purchase ids are persisted
  in `ClickerState.processed_purchase_ids` and saved/restored across sessions.
  The list is capped at 100 entries. It is **never** cleared by prestige or reset.
- Real RuStore Pay SDK calls must live only in `AndroidRuStorePlatform.gd`.
- Cancel / error grant nothing.
- Payment modal must pause runtime and audio and call `GameplayAPI.stop()` on
  Web. Cancel/error/success must clear pending payment state and call safe resume.

**Yandex Payments (Web):**

- Uses client-side `ysdk.getPayments()`. Do **not** use
  `getPayments({ signed: true })` without a backend.
- Unprocessed purchases recovered via `payments.getPurchases()` on startup.
- Consumable order: grant gems → update UI → save → cloud flush → `consumePurchase()`.

**RuStore Pay (Android):**

- `AndroidRuStorePlatform.gd` uses `RuStoreGodotPayClient` (official SDK).
- Purchase type `ONE_STEP`; no explicit consume needed.
- `check_unprocessed_purchases()` calls `get_purchases(CONSUMABLE_PRODUCT, CONFIRMED)`.
- Empty purchase id from success result is rejected — no gems granted.
- See `docs/rustore_readiness_checklist.md` for the full pre-upload checklist.

## Audio

### Music tracks

```
res://assets/audio/music/track_01.ogg
res://assets/audio/music/track_02.ogg
res://assets/audio/music/track_03.ogg
res://assets/audio/music/track_04.ogg
res://assets/audio/music/track_05.ogg
res://assets/audio/music/track_06.ogg
res://assets/audio/music/track_07.ogg
```

### SFX

```
res://assets/audio/sfx/hits/hit_01.ogg
res://assets/audio/sfx/hits/hit_02.ogg
res://assets/audio/sfx/hits/hit_03.ogg
res://assets/audio/sfx/ui/button_click.ogg
res://assets/audio/sfx/shop/purchase_success.ogg
res://assets/audio/sfx/shop/purchase_error.ogg
res://assets/audio/sfx/rewards/reward_received.ogg
res://assets/audio/sfx/rewards/gold_received.ogg
```

### Music behavior

- 7 tracks; playback order is randomized/shuffled each session.
- Game does not always start from track 1; immediate repeat is avoided.
- Music starts/resumes after the first real user interaction (required by Web/Yandex autoplay policy).
- Music pauses when the page/tab is hidden and resumes when visible again (if enabled and not
  paused for an ad or payment).

### SFX behavior

- Sound setting gates all SFX; music setting gates music.
- Audio uses a multi-reason pause: `ad`, `platform`, `payment`, `hidden`.
  Music and SFX are suppressed while any pause reason is active.
- SFX are suppressed while the page/tab is hidden, during ads, during platform
  pause, and during active payment.
- Button SFX fires on `button_down`, not after the button action completes.

## Localization

- **Source:** `res://localization/game_text.csv`
- **Generated:** `res://scripts/ui/LocalizationData.gd` (auto-regenerated by the
  editor plugin on save; also regenerated by the export hook before each build)
- All player-visible text must use `LocalizationManager.tr_key()` or
  `LocalizationManager.format_key()`.
- No hardcoded English/Russian strings in `.gd` or `.tscn` files.
- After editing `game_text.csv`, commit both `game_text.csv` and
  `LocalizationData.gd` together.
- Validate before export:
  ```
  godot --headless --script res://scripts/tools/ValidateLocalizationDataFreshness.gd
  godot --headless --script res://scripts/tools/ValidateLocalizationExport.gd
  ```

## Save / reset rules

**Reset Progress preserves:**
- gems
- permanent shop upgrades
- settings / language

**Reset Progress resets:**
- normal run progress (gold, hero level, partners, buildings, normal skills)
- tasks and task baselines
- temporary buffs / active ability timers
- pending offline reward

**Prestige preserves:**
- gems
- permanent shop upgrades
- settings / language
- prestige points (available and total earned)
- prestige talent levels and `total_prestiges`

**Prestige resets:**
- current level and max unlocked level
- normal run progress (gold, hero level, partners, buildings, normal skills)
- `auto_stage_advance_enabled` resets to default ON

Save immediately after purchases, ad rewards, task claims, reset, prestige, settings/language changes, and important economy changes.

**Cloud save:** Yandex cloud save (player data) is used alongside local save. Respect the
Yandex player data size limit. Cloud save is flushed after purchases, ad rewards, and any
action that changes persistent state. BigNumber values in the save must remain
forward-compatible; do not rename save field keys without adding a migration.

## Debug / release rules

- All dev-only features must be gated by `BuildConfig.is_debug_features_enabled()`,
  which reflects `OS.is_debug_build()` internally. Do not manually force
  `IS_DEBUG_BUILD` in source code.
- Use a proper release export (`godot --headless --export-release "Web" …`) to
  produce a production build. Do not ship a debug export.
- F12 debug mode and keyboard shortcuts (F5/F9/F10/F12/L/K) must not work in production.
- Fake ad / payment success must not work in production.
- `BalanceAuditReport`, `ProgressionSimulator`, and other dev tools are dev-only and must not be autoloaded or runtime-active in release builds.

## Localhost note

On localhost, the Yandex SDK is unavailable (`window.ysdk` is not present).

- Real ads will not open.
- Real paid purchases will not open.
- The game must fail gracefully: no rewards or gems must be granted, and the
  game must not be left in a paused state with no recovery path.
- Debug mode simulates ad/payment flows for local testing; these simulations
  must be disabled in release builds.

## Android release build notes

- Android export preset is configured for RuStore package identity:
  `com.stanis.shinobiclickeridle`.
- Release APK must be signed with a **persistent release keystore**. The keystore
  must not be committed to the repository. See `docs/android_release_signing.md`.
- `version/code` must increase for every APK uploaded to RuStore. The first upload
  may use `version/code=1`; every later upload must use a strictly larger integer.
- Build the Android Ads plugin AAR before each export:
  ```bash
  cp android/build/libs/release/godot-lib.template_release.aar \
     addons/android_yandex_ads/android/AndroidYandexAdsPlugin/libs/
  cd addons/android_yandex_ads/android/AndroidYandexAdsPlugin
  ./gradlew assembleRelease
  ```
- RuStore Pay uses the official `RuStoreGodotPayClient` SDK (addons/RuStoreGodotPay/).
  Local `android/build/res/values/rustore_values.xml` must be configured before
  a payment-enabled export. See `docs/rustore_pay_integration.md`.
- Never commit keystore files, passwords, key aliases, or local absolute paths.
- Run the read-only validation script before every RuStore upload:
  ```bash
  python tools/validate_android_release.py --apk <ANDROID_RELEASE_OUTPUT_APK>
  ```
  The script checks package name, versionCode, versionName, APK signature, AAR presence,
  export preset identity, and `.gitignore` safety. It does not replace manual device testing.
- See `docs/android_release_validation.md` for the full pre-upload checklist.

## Export / release

Export target is Web (Yandex Games). Production export must use **release** mode,
not debug.

```
godot --headless --export-release "Web" builds/web/index.html
```

Local test (must be served over HTTP — double-clicking `index.html` will not work):

```
cd builds/web
python -m http.server 8080
```

**Checklist before shipping:**
- `index.html` must be in the archive root for Yandex Games upload.
- No Cyrillic characters or spaces in exported file paths.
- Unpacked build size ≤ 100 MB.
- Test on at least 720×1600, 720×1280, and 1080×2400 window sizes.

## QA checklist

| Area | Status |
|---|---|
| Debug / production separation | Complete |
| Localization cleanup | Complete |
| Save / Load / Reset / Prestige | Complete |
| Ads (rewarded banner, shop, offline) | Complete |
| Payments (gem purchases) | Complete |
| UI (panels, sheets, scrolling, touch) | Complete |
| Audio (SFX, music, settings) | Complete |
| Asset / build sanity | Complete |
| Web export | Ready for final local/Yandex preview verification |
| Yandex Games cabinet testing | Ready for final local/Yandex preview verification |

## Backend cloud-save client and platform bridge

A Yandex Cloud auth/save backend is integrated for Android/RuStore cloud-save.
The integration is split across two patches:

### C1 — Client foundation (completed)

- `scripts/platform/backend/BackendAuthStore.gd` — persists session token,
  email, and email_verified to `user://backend_auth.json`.
- `scripts/platform/backend/BackendApiClient.gd` — HTTP client that wraps all
  backend endpoints (auth, password reset, email verification, save load/save/delete).

### C2 — Platform bridge (completed)

The backend URL is committed as a public project setting in `project.godot`:

```
application/cloud_save/backend_url="https://d5dkb9m5is8d2uqmrsf7.kr8f6hld.apigw.yandexcloud.net"
```

This URL is an API Gateway public endpoint — not a secret. No passwords,
session tokens, SMTP keys, or service-account keys are committed.

**What C2 added:**

- `PlatformServices.gd` — backend auth/save signals and default stub methods.
  All stubs fail with `not_supported`; no crash on any platform.
- `Platform.gd` — re-exposes backend signals and forwards all backend methods
  to the active implementation.
- `AndroidRuStorePlatform.gd` — creates `BackendAuthStore` + `BackendApiClient`,
  configures the URL from the project setting, and delegates all backend methods
  to the client.

**What C2 did NOT change:**

- Web/Yandex Games cloud-save — unchanged; still uses `YandexBridge` / `WebYandexPlatform`.
- `SaveManager` — not yet wired to backend; local save and Yandex cloud save behaviour unchanged.
- Account UI — not yet added; future patch.
- Ads, payments, balance, gameplay — unchanged.

### Configuration

The backend base URL is read from the project setting at Android startup:

```
application/cloud_save/backend_url
```

`AndroidRuStorePlatform` calls `BackendApiClient.configure_from_project_settings()`
automatically in `_ready()`. The URL can also be overridden at runtime via
`Platform.configure_backend_client(url)`.

If the client is not configured when a request is attempted, it emits
`backend_operation_failed(op, "not_configured", 0, {})` without touching the network.

If a protected endpoint is called without a stored session token, it emits
`backend_operation_failed(op, "missing_session", 0, {})` without touching the network.

**Never commit passwords, session tokens, SMTP keys, or service-account keys.**

### Architecture notes

- All backend operations go through `Platform` — gameplay and UI must never
  call `BackendApiClient` directly.
- Web/Yandex Games cloud-save remains entirely separate through `YandexBridge`.
- The backend stores a raw JSON save blob. `save_version` and `last_save_unix_time`
  must be present in save data before calling `Platform.backend_save_save()`.
- `SaveManager` wiring is a future patch.
- Account UI settings panel is a future patch.

### C3 — Android Auth Gate with Guest Mode (completed)

Android/RuStore now shows an auth gate before gameplay on every cold start.

**Android/RuStore startup flow (C3.1 ordering fix applied):**

1. `Main._ready()` detects `OS.has_feature("android")` and instantiates `AuthGateScreen`.
   `ClickerScreen` is NOT instantiated yet — its `_ready()` has not run.
2. `AuthGateScreen` checks `Platform.backend_has_session()`:
   - Session exists → calls `Platform.backend_get_me()` to validate.
     - Valid → emits `auth_gate_completed("account")` → `ClickerScreen` is instantiated.
     - Unauthorized → calls `Platform.backend_clear_local_auth()`, shows login form.
   - No session → shows login form directly.
3. User can: log in, register, request/confirm password reset, or continue as guest.
4. Guest mode → `auth_gate_completed("guest")` → `ClickerScreen` is instantiated.
5. Login/register success → `auth_gate_completed("account")` → `ClickerScreen` is instantiated.
6. `AuthGateScreen` is removed from the scene tree; then `ClickerScreen` is added.
7. `ClickerScreen._ready()` loads local save and initializes gameplay.
8. Existing `startup_completed` / `game_ready` flow continues as before.

**Web/Yandex startup:**

`ClickerScreen` is instantiated immediately in `Main._ready()`. No AuthGate. Unchanged.

**Editor/LocalDebug startup:**

`ClickerScreen` is instantiated immediately in `Main._ready()`. No AuthGate. Unchanged.

**Files added:**

- `scenes/auth/AuthGateScreen.tscn` — auth gate scene (script-driven UI).
- `scenes/auth/AuthGateScreen.gd` — auth gate logic; calls backend only through `Platform`.

**Files changed:**

- `scenes/main/Main.tscn` — removed pre-instanced `ClickerScreen` child node.
- `scenes/main/Main.gd` — lazy `ClickerScreen` instantiation via `_instantiate_clicker_screen()`;
  `_start_game_after_auth_gate(mode)` gate; `get_startup_auth_mode()` accessor.

**What C3 did NOT change:**

- Web/Yandex startup behavior — unchanged (ClickerScreen still instantiated immediately).
- `SaveManager` — not yet wired to backend; local save and Yandex cloud save unchanged.
- Backend Cloud Functions — unchanged.
- Gameplay, ads, payments, balance — unchanged.
- Guest-to-account save upload — future patch.
- Account settings panel — future patch (→ C4).
- Save conflict resolution — future patch.

**New platform method:**

`Platform.backend_clear_local_auth()` — clears the locally stored session token without
making a network request. Used when `get_me` returns `unauthorized` on startup so the
invalid token is removed before showing the login form.

### C4 — Account Settings Panel (completed)

Android/RuStore settings window now shows an account management block.

**Account section behavior:**

- **Guest / no backend session:**
  - Status: "Guest mode"
  - Warning: progress is stored only on this device.
  - Button: "Sign in / Register" → opens `AuthGateScreen` as an overlay above gameplay.
    Gameplay continues without reset; `ClickerScreen` is not re-instantiated.

- **Signed-in account session:**
  - Email address is displayed.
  - Email verification state ("Email verified" / "Email not verified").
  - Button: "Verify email" (visible when not yet verified) → sends verification code.
  - 6-digit code input + "Confirm code" button appear after the code is sent.
  - Button: "Logout" → calls `Platform.backend_logout()`; on failure, calls
    `Platform.backend_clear_local_auth()` as a fallback so the user can always
    return to guest/no-session state.

- **Web/editor:** account block is hidden entirely. No backend calls are made
  automatically. Existing Web/Yandex cloud-save is unchanged.

**AuthGate overlay from settings:**

`Main.show_auth_gate_overlay()` instantiates `AuthGateScreen` above the existing
`ClickerScreen`. When the overlay emits `auth_gate_completed`, `Main` removes it and
stores the new auth mode — it does **not** re-instantiate `ClickerScreen`. Gameplay
continues uninterrupted. `SettingsWindow` is refreshed through
`Platform.backend_auth_changed` when the user later reopens settings.

**What C4 did NOT change:**

- `SaveManager` — not yet wired to backend; local save and Yandex cloud save unchanged.
- Guest progress is not automatically uploaded after login.
- Cloud/local save conflict resolution — future patch.
- Gameplay, ads, payments, balance — unchanged.
- Backend Cloud Functions — unchanged.

**Files changed:**

- `scenes/main/Main.gd` — added `show_auth_gate_overlay()` public method; updated
  `_on_auth_gate_completed()` to skip re-starting gameplay when `_startup_started` is true.
- `scenes/ui/SettingsWindow.gd` — added `account_auth_requested` signal; account section
  UI (script-built, Android-only); `Platform.backend_*` calls for verification/logout;
  `_exit_tree()` disconnects Platform signals.
- `scenes/game/ClickerScreen.gd` — connects `account_auth_requested` and delegates to
  `Main.show_auth_gate_overlay()`.
- `localization/game_text.csv` — 19 new `settings.account.*` keys (EN + RU).
- `scripts/ui/LocalizationData.gd` — regenerated (417 keys).

### C4.1 — Android AuthGate Black Screen Hotfix (completed)

**Root cause:**

`AuthGateScreen.gd` assigned `.keyboard_type` directly on `LineEdit` nodes (4
usages across login / register / reset-request / reset-confirm boxes). This
property name is invalid on the Godot 4.5.1 Android `LineEdit` object — the
engine threw a script error at UI-build time, aborting `_build_ui()`. Because
`ClickerScreen` is not instantiated until `auth_gate_completed` fires (C3.1
ordering), the screen remained black.

Secondary `Nil.visible` errors appeared because the partially-built boxes were
never assigned to their variables, and `_set_state()` wrote to them without null
guards.

**Fix:**

- All four `.keyboard_type = ...` assignments replaced with
  `_try_set_virtual_keyboard_type(edit, LineEdit.KEYBOARD_TYPE_EMAIL_ADDRESS)`.
  The helper checks `"virtual_keyboard_type" in edit` before calling `edit.set()`,
  so it is a no-op on any Godot version that does not expose the property.
- `_set_state()` now null-checks every box and `_guest_button` before writing
  `.visible`. A partially built UI no longer cascades into a secondary crash.
- `_ready()` calls `_is_ui_built()` after `_build_ui()`. If the check fails,
  `_show_fallback_error()` adds a full-rect error label so the screen is never
  black, then returns without calling `_connect_platform_signals()` or
  `_check_existing_session()`.

**What this patch did NOT change:**

- `SaveManager` — still not wired to backend.
- Gameplay, ads, payments, balance — unchanged.
- Backend Cloud Functions — unchanged.
- Web/editor startup flow — unchanged (AuthGate is Android-only).

**Files changed:**

- `scenes/auth/AuthGateScreen.gd` — safe virtual-keyboard helper; null-safe
  state machine; UI build guard in `_ready()`.

### C4.2 — Android AuthGate Visible Layout Hotfix (completed)

**Root cause:**

`AuthGateScreen` UI was building successfully (no script errors) but remained
invisible on Android. The `PanelContainer` inside the `ScrollContainer` had
`custom_minimum_size = Vector2(340, 0)`, which let the scroll container size it
to zero height. Additionally, `AuthGateScreen` itself relied on the parent to
set its anchors — if `Main` added it without forcing a full-rect layout preset,
the root Control had zero size and clipped all children.

**Fix:**

- `_ready()` now calls `set_anchors_and_offsets_preset(PRESET_FULL_RECT)` with
  `SIZE_EXPAND_FILL` and `z_index = 1000` before any other setup, guaranteeing
  the root node covers the screen regardless of how `Main` adds it.
- `_build_ui()` removes the `ScrollContainer` entirely. The new layout is:
  `MarginContainer(full-rect, 24 px margins) → CenterContainer(EXPAND_FILL) →
  PanelContainer(min_size=340×520, SHRINK_CENTER) → VBoxContainer`. No container
  in the auth form path can have zero height.
- `Main._show_auth_gate()` and `Main.show_auth_gate_overlay()` both apply
  `set_anchors_and_offsets_preset(PRESET_FULL_RECT)` after `add_child()` as a
  second safety layer.
- Explicit white font colors added to title and checking labels so text is
  readable on the dark panel even if the theme default is dark.
- Session-check timeout (6 s) added: if `backend_get_me()` never responds,
  `backend_clear_local_auth()` is called and the login form is shown so the
  user is never stuck in CHECKING state indefinitely.
- Debug `print` statements added for `root size`, `panel min size`, and each
  state transition to aid Android logcat validation.

**What this patch did NOT change:**

- `SaveManager` — still not wired to backend.
- Gameplay, ads, payments, balance — unchanged.
- Backend Cloud Functions — unchanged.
- Web/editor startup flow — unchanged.

**Files changed:**

- `scenes/auth/AuthGateScreen.gd` — layout rebuild; full-rect anchor in
  `_ready()`; session-check timeout; font colors; debug prints.
- `scenes/main/Main.gd` — force full-rect on auth gate after `add_child()` in
  both `_show_auth_gate()` and `show_auth_gate_overlay()`.

### C5.1 — Manual Backend Cloud Sync from Settings (completed)

Android/RuStore signed-in accounts can now manually upload and download their save
to/from the backend cloud. Guest mode remains local-only.

**Upload (Save to Cloud):**

- User presses "Save to Cloud" in the Account section of Settings.
- `SettingsWindow` emits `cloud_save_upload_requested`.
- `ClickerScreen` saves the current state to disk, then calls
  `SaveManager.get_cloud_save_payload()` to get a deep copy of the local save
  with `save_version` and `last_save_unix_time` stamped to the current time.
- `Platform.backend_save_save(payload)` sends `PUT /v1/save` with the payload.
- On success, `SettingsWindow` shows "Cloud save uploaded" status.
- On failure, `SettingsWindow` shows the backend error code.

**Download (Load from Cloud):**

- User presses "Load from Cloud" in Settings.
- An inline confirmation warning appears: "Loading from cloud will replace local progress."
- After user confirms, `SettingsWindow` emits `cloud_save_download_requested`.
- `ClickerScreen` calls `Platform.backend_load_save()`.
- On `has_save=false`: status shows "No cloud save found"; local save unchanged.
- On `has_save=true`: `SaveManager.apply_cloud_save_payload(save_data)` validates
  (`save_version > 0`, `last_save_unix_time > 0`), applies migration, and writes
  to the local save file. `ClickerScreen` reloads state from disk, resets runtime
  timers, refreshes all UI panels, and shows "Cloud save loaded".
- On invalid payload: shows "Cloud save is invalid"; local save unchanged.
- On network error: shows backend error code.

**Guest mode:** Cloud save buttons are hidden; status shows "Sign in to use cloud save".

**Web/Yandex:** Account section is hidden entirely (Android-only); Yandex cloud-save
via `YandexBridge` is unchanged.

**New helper methods:**

- `SaveManager.get_cloud_save_payload() -> Dictionary` — deep copy of local save
  with `save_version`, `last_save_unix_time`, and optional `cloud_save_meta` block.
  Does not mutate internal state.
- `SaveManager.apply_cloud_save_payload(payload) -> bool` — validates, migrates,
  and writes a cloud payload to the local save file. Returns false on any validation
  failure without touching the existing local save.

**What C5.1 did NOT add:**

- Automatic cloud-save on game events — future patch.
- Startup cloud-load — future patch.
- Local/cloud conflict resolution — future patch.
- Guest-to-account save upload after login — future patch.
- Backend Cloud Function changes — none.
- Gameplay, ads, payments, balance — unchanged.

**Files changed:**

- `autoload/SaveManager.gd` — added `get_cloud_save_payload()` and
  `apply_cloud_save_payload()`.
- `scenes/ui/SettingsWindow.gd` — added `cloud_save_upload_requested` /
  `cloud_save_download_requested` signals; cloud save sub-section in account block
  (upload button, download button, inline confirmation); `set_cloud_save_status()`
  and `refresh_account_section()` public helpers.
- `scenes/game/ClickerScreen.gd` — connected cloud sync signals; implemented
  `_on_settings_cloud_save_upload_requested()`, `_on_settings_cloud_save_download_requested()`,
  `_on_backend_cloud_op_succeeded()`, `_on_backend_cloud_op_failed()`.
- `localization/game_text.csv` — 17 new `settings.cloud.*` keys (EN + RU).
- `scripts/ui/LocalizationData.gd` — regenerated.

---

### C5.2 — Automatic Backend Cloud Upload (completed)

Automatic backend cloud-save upload for Android/RuStore account users.

**Behavior:**

- **Web/Yandex:** unchanged. Existing Yandex cloud-save via `YandexBridge` is unaffected. No backend calls on Web.
- **Android/RuStore Guest:** local save works as before. No backend cloud upload. Manual cloud controls remain disabled in guest mode.
- **Android/RuStore Account:** after each normal local save, `SaveManager` schedules a backend `PUT /v1/save` automatically, throttled to at most once every 45 seconds. Backend/network failures are silent warnings — local save and gameplay are never affected.

**Key design points:**

- Throttle: 45-second minimum interval between auto-uploads (`BACKEND_CLOUD_AUTO_UPLOAD_MIN_INTERVAL_SEC`).
- Payload size guard: 200 KB limit (`BACKEND_CLOUD_AUTO_UPLOAD_MAX_BYTES`). Oversized payloads are skipped with a warning.
- In-flight guard: only one concurrent backend upload request is allowed. Newer data is queued and retried after 60 seconds if an upload is already in flight.
- Manual "Save to Cloud" still works and flushes immediately (bypasses throttle). It sets buttons busy while the request is in flight and shows success/error in SettingsWindow.
- Manual "Load from Cloud" remains confirmation-based and fully manual — no automatic download.
- Startup cloud auto-load is NOT implemented in this patch.
- Local/cloud conflict resolution is NOT implemented in this patch.
- Guest-to-account save upload after login is NOT implemented automatically in this patch (happens naturally on the next normal save after login).

**What C5.2 did NOT add:**

- Startup cloud auto-load — future patch.
- Local/cloud conflict resolution — future patch.
- Backend Cloud Function changes — none.
- Gameplay, ads, payments, balance — unchanged.

**Files changed:**

- `autoload/SaveManager.gd` — added `BACKEND_CLOUD_AUTO_UPLOAD_MIN_INTERVAL_SEC`, `BACKEND_CLOUD_AUTO_UPLOAD_MAX_BYTES`, backend upload fields, `queue_backend_cloud_save()`, `flush_backend_cloud_save_now()`, `upload_current_save_to_backend_cloud_now()`, `mark_backend_cloud_upload_finished()`, `is_backend_cloud_upload_in_flight()`, `_send_backend_cloud_save()`, `_on_backend_cloud_upload_timer_expired()`; hooked `queue_backend_cloud_save(data)` into `save_data()`.
- `scenes/game/ClickerScreen.gd` — added `_manual_backend_cloud_upload_requested` flag; updated `_on_settings_cloud_save_upload_requested()` to use `SaveManager.upload_current_save_to_backend_cloud_now()`; updated `_on_settings_cloud_save_download_requested()` to set buttons busy; added `save_save` handling in `_on_backend_cloud_op_succeeded()` and `_on_backend_cloud_op_failed()`.
- `scenes/ui/SettingsWindow.gd` — removed `save_save` from its own backend op handlers (ClickerScreen now owns that); added `set_cloud_save_buttons_busy()`.
- `scenes/auth/AuthGateScreen.gd` — temporary layout debug logs gated behind `BuildConfig.IS_DEBUG_BUILD`.
- `localization/game_text.csv` — 3 new `settings.cloud.*` keys (EN + RU).
- `scripts/ui/LocalizationData.gd` — regenerated.

---

### C5.3 — Android Account Startup Cloud-Restore Check (completed)

Startup and post-login cloud-restore check for Android/RuStore account users with a user-confirmation prompt.

**Behavior:**

- **Web/Yandex:** unchanged. Existing Yandex SDK cloud-save behavior remains unchanged. No backend cloud-restore check.
- **Android/RuStore Guest:** local-save-only. No backend cloud-restore check.
- **Android/RuStore Account:** after gameplay starts and a backend session exists, the backend save is checked once automatically. The check also runs after a successful login from the AuthGate overlay while gameplay is already running.

**Prompt logic (Android account only):**

- If no cloud save exists: no prompt, no change.
- If cloud save exists and local save is missing: prompt appears — "Cloud Progress Found".
- If cloud save exists and cloud `last_save_unix_time` is newer than local: prompt appears — "Newer cloud progress found".
- If local save is newer or same age as cloud: no prompt.
- If cloud save is invalid: no prompt, `push_warning` only.
- Cloud save is **never applied silently**. User must confirm.

**Key design points:**

- Check runs at most once per startup. After login from AuthGate overlay, one additional check is allowed.
- If user declines ("Keep Local"), no further startup prompt appears for that session.
- Manual "Load from Cloud" in Settings remains available and unchanged.
- Auto-upload (C5.2) continues to work normally; guest saves are never uploaded.
- No changes to backend Cloud Functions, gameplay, ads, payments, or balance.
- No save payloads are logged.

**What C5.3 did NOT add:**

- Silent auto-load of cloud saves — user confirmation is always required.
- Automatic cloud download on startup — only a check and prompt.
- Full conflict-resolution UI — simple timestamp comparison only.
- Guest-to-account save upload after login.
- Backend Cloud Function changes.
- Gameplay, ads, payments, balance — unchanged.

**Files changed:**

- `localization/game_text.csv` — 9 new `cloud_restore.*` keys (EN + RU).
- `scripts/ui/LocalizationData.gd` — regenerated (445 keys).
- `scenes/ui/CloudRestorePrompt.gd` — new Control-based confirmation dialog; emits `load_cloud_confirmed` / `keep_local_confirmed`; does not call SaveManager or Platform.
- `scenes/ui/CloudRestorePrompt.tscn` — new scene; matches PrestigeConfirmDialog visual style.
- `scenes/game/ClickerScreen.tscn` — added `CloudRestorePrompt` instance.
- `scenes/game/ClickerScreen.gd` — added restore-check state fields; `request_backend_cloud_restore_check()`; `_evaluate_cloud_restore_candidate()`; `_on_cloud_restore_load_confirmed()`; `_on_cloud_restore_keep_local_confirmed()`; `_manual_backend_cloud_download_requested` flag; refactored `load_save` response routing to distinguish manual vs startup check.
- `scenes/main/Main.gd` — after AuthGate overlay login with mode `"account"`, calls `_clicker_screen.request_backend_cloud_restore_check("auth_overlay")`.

### C5.3.1 — Startup Upload Suspension Hotfix (completed)

Prevents `_load_game_on_start_async()` from triggering a backend auto-upload before the startup cloud-restore decision is made, which could overwrite the real cloud save on reinstall.

**Root cause:** `_load_game_on_start_async()` calls `_save_game_now()` → `SaveManager.save_data()` → `queue_backend_cloud_save()`. On a fresh install this uploads a default local save, overwriting any real cloud save before `request_backend_cloud_restore_check("startup")` runs.

**Fix:** Backend auto-upload is suspended at the start of `_ready()` on Android/account and resumed at every restore-decision exit point:
- No cloud save on backend → resume immediately.
- Cloud save invalid or local newer → resume immediately.
- Prompt shown → suspended until player confirms or declines.
- Player confirms Load Cloud → apply payload → resume.
- Player confirms Keep Local → resume.
- Backend check failed → resume.
- Manual Settings Load/Save from Cloud → also resumes as a defensive cleanup.
- Scene destroyed without a decision → `_exit_tree()` resumes.

**What this did NOT change:**
- `upload_current_save_to_backend_cloud_now()` (manual Save to Cloud) has no suspension guard — it always fires.
- Web/Yandex cloud-save is completely unaffected (`_should_suspend...` returns false for non-Android).
- Guest mode is unaffected (no session → suspension never set → no-op).
- No new cloud-save features, no schema changes, no gameplay changes.

**Files changed:**

- `autoload/SaveManager.gd` — `_backend_cloud_auto_upload_suspended` field; `set_backend_cloud_auto_upload_suspended()`; `is_backend_cloud_auto_upload_suspended()`; early-return guard in `queue_backend_cloud_save()`.
- `scenes/game/ClickerScreen.gd` — `_should_suspend_backend_auto_upload_for_startup_restore()`; `_resume_backend_auto_upload_after_restore_decision()`; suspend call in `_ready()`; resume calls in all `load_save` exit paths and prompt handlers; `_exit_tree()` cleanup.

### C5.3.2 — Pre-Startup Local Save Snapshot Hotfix (completed)

Ensures the startup cloud-restore prompt compares cloud save against the local save state that existed **before** startup initialization, not against a default save created during startup.

**Root cause:** After reinstall or clear-data, `_load_game_on_start_async()` creates a new default local save with a current `last_save_unix_time`. `_evaluate_cloud_restore_candidate()` then called `SaveManager.load_data()` and compared cloud `last_save_unix_time` against this freshly-created timestamp, which was newer — so the restore prompt never appeared.

**Fix:** Capture pre-startup local save state in `_capture_pre_startup_local_save_snapshot()` before `_load_game_on_start_async()` runs. `_evaluate_cloud_restore_candidate()` now uses `_pre_startup_had_local_save` and `_pre_startup_local_timestamp` instead of re-reading the current local save.

**Behavior after fix:**
- No local save before startup + cloud save exists → prompt always shown.
- Local save existed before startup with older timestamp → prompt shown.
- Local save existed before startup with equal or newer timestamp → no prompt.
- If pre-startup local save has no `last_save_unix_time` (timestamp = 0) and cloud has a valid timestamp → prompt shown (conservative: assume cloud is newer).
- Snapshot is idempotent; defensive re-call in `_evaluate_cloud_restore_candidate()` is a no-op if already taken.

**What this did NOT change:**
- Manual Settings Load from Cloud — unchanged (still uses existing C5.1 confirmation flow).
- C5.3.1 upload suspension — unchanged and still in effect.
- Web/Yandex, guest mode — unchanged.
- No save schema changes, no gameplay changes.

**Files changed:**

- `scenes/game/ClickerScreen.gd` — `_pre_startup_had_local_save`, `_pre_startup_local_timestamp`, `_pre_startup_local_save_snapshot_taken` fields; `_capture_pre_startup_local_save_snapshot()` helper; snapshot call in `_ready()`; `_evaluate_cloud_restore_candidate()` rewritten to use snapshot.

### C5.4 — Guest → Account Migration Prompt (completed)

After a guest player logs in or registers an account from Settings / AuthGate overlay, the game now offers to upload current local progress to the backend cloud.

**Behavior:**

- If gameplay started as Guest and the player logs in mid-session from Settings:
  - The cloud-restore check runs first (C5.3 flow).
  - If no restore prompt is needed, `GuestMigrationPrompt` appears asking: *"Save your current guest progress to this account?"*
  - **Save to Cloud** — saves locally then uploads to backend; gameplay continues without reload.
  - **Not Now** — prompt closes; gameplay unchanged; future auto-uploads will work because an account session now exists.
- If the restore check shows `CloudRestorePrompt`, the migration prompt is suppressed (restore has priority; both never appear simultaneously).
- Prompt does not appear on Web/Yandex, in pure guest mode, or if gameplay started as account.

**What C5.4 did NOT add:**

- Silent overwrite of backend cloud immediately after login — always requires user confirmation.
- Auto-load of backend cloud save — that remains a separate restore flow.
- Full conflict resolution or merge — future work.
- Save schema changes, gameplay changes, balance changes, monetization changes.

**Files changed:**

- `scenes/ui/GuestMigrationPrompt.gd` — new signal-only dialog; no SaveManager/Platform calls.
- `scenes/ui/GuestMigrationPrompt.tscn` — new scene, visual style matches CloudRestorePrompt.
- `scenes/game/ClickerScreen.tscn` — GuestMigrationPrompt node added.
- `scenes/game/ClickerScreen.gd` — guest-session tracking fields; `set_startup_auth_mode()`; `on_account_login_from_overlay()`; prompt eligibility check; upload handlers; fullscreen-ad and rewarded-banner guards updated.
- `scenes/main/Main.gd` — passes startup auth mode to ClickerScreen; routes overlay login to `on_account_login_from_overlay()`.
- `localization/game_text.csv` — 6 new `guest_migration.*` keys (EN + RU).
- `scripts/ui/LocalizationData.gd` — regenerated (451 keys).

---

### C6 — Backend Cloud Save Stabilization / Release Hardening (completed)

Hardening pass on the Android/RuStore backend auth and cloud-save flows introduced
in C3–C5.4. No new gameplay features, no balance changes, no backend Cloud Function
changes.

**Changes:**

- **`scenes/main/Main.gd`** — `set_startup_auth_mode` now called before `add_child`
  in `_instantiate_clicker_screen()`. This guarantees `_gameplay_started_as_guest`
  is set before any `_ready()` code in `ClickerScreen` can read it, even if future
  code is added before the first `await`.

- **`scenes/auth/AuthGateScreen.gd`** — Four hardening changes:
  - `_request_in_progress: bool` flag prevents duplicate backend requests from rapid
    button presses. Guards added to `_on_login_submit()`, `_on_register_submit()`,
    `_on_reset_request_submit()`, `_on_reset_confirm_submit()`. Flag clears on every
    success/failure response.
  - `_connect_platform_signals()` guards with `is_connected()` before each
    `connect()` call — safe if the method is called more than once.

- **`scenes/game/ClickerScreen.gd`** — Two hardening changes:
  - Ungated `print` statements in `_load_game_on_start_async()` ("cloud save is
    newer", "no valid local save, using cloud save") and `notify_yandex_game_ready()`
    are now gated behind `BuildConfig.IS_DEBUG_BUILD`.
  - `_should_show_guest_migration_prompt()` now checks
    `is_instance_valid(cloud_restore_prompt) and cloud_restore_prompt.visible` as a
    defensive collision guard, in addition to the existing
    `_startup_cloud_restore_prompt_pending` flag check. Both prompts can never be
    visible simultaneously.

**What C6 did NOT change:**

- Web/Yandex cloud-save — unchanged; `YandexBridge` and `WebYandexPlatform` unaffected.
- `SaveManager` — no new cloud-save features; suspension/resume lifecycle unchanged.
- Backend Cloud Functions — none changed.
- Gameplay, ads, payments, balance — unchanged.
- Save schema — no new or renamed fields.
- Localization — no new keys.

**Prompt priority (unchanged, now enforced by visible-guard):**
`CloudRestorePrompt` (highest) → `GuestMigrationPrompt` → Settings/manual.

**Validation:** see `docs/validation/backend_cloud_save_stabilization.md`.

---

### C7.1 — Account Save Authority & Guest Paid Shop Lock (completed)

**Purpose:** Clarify save authority on login/register and lock paid gem purchases for
Android/RuStore guests. Removes the old `GuestMigrationPrompt` mid-session flow.

**New product rules:**

- Guest progress is local-only. Guest can watch rewarded ads. Guest **cannot** use
  paid donation/gem purchases on Android/RuStore.
- **Guest → Register:** current guest save is automatically uploaded to the new
  account's cloud save. Gameplay continues without reload.
- **Guest → Login:** existing account cloud save is the authority and loads
  immediately. Guest save is **never** uploaded on login.
- **Guest → Login with no cloud save:** a clean default account save starts; guest
  progress is discarded.
- Direct account startup restore behavior (C5.3 `CloudRestorePrompt`) is preserved.
- `GuestMigrationPrompt` flow is disabled; the scene/script files remain but the
  prompt is never shown.
- Web/Yandex paid shop behavior is unchanged.

**Changes:**

- **`scenes/auth/AuthGateScreen.gd`** — `get_me` success emits `account_session`;
  login success emits `account_login`; post-register login success emits
  `account_register`. Guest button still emits `guest`.

- **`scenes/main/Main.gd`** — `_on_auth_gate_completed` maps the four result strings
  to `_startup_auth_mode` ("guest"/"account") and `_startup_auth_source`. For overlay
  completions, dispatches `on_account_registered_from_guest_overlay()` or
  `on_account_login_from_guest_overlay()` on the active ClickerScreen.

- **`scenes/game/ClickerScreen.gd`** —
  - `on_account_registered_from_guest_overlay()`: saves locally, uploads to backend
    cloud, continues gameplay, unlocks paid shop.
  - `on_account_login_from_guest_overlay()`: suspends auto-upload, force-loads account
    cloud save, applies it (or starts clean save if none), resumes auto-upload.
  - `_is_paid_shop_available()`: returns `false` on Android without a backend session.
  - Paid `donation_entry` shop tap and `_on_gem_product_purchase_requested` guarded by
    `_is_paid_shop_available()`; opens AuthGate overlay if false.
  - `_on_platform_backend_auth_changed` connected: refreshes shop availability on logout.
  - All `_guest_migration_*` variables and methods removed.

- **`localization/game_text.csv`** — 10 new keys: `shop.paid_guest_locked_*` and
  `account_flow.*`.

**What C7.1 did NOT change:**

- Web/Yandex cloud-save or paid shop — unchanged.
- Backend Cloud Functions — none changed.
- Gameplay balance — unchanged.
- Save schema — no new fields.
- `CloudRestorePrompt` direct-account restore flow — unchanged.
- Rewarded ads — available in all modes including Guest.

**Validation:** see `docs/validation/account_save_authority_guest_shop_lock.md`.

---

### C6.1 — Release Audit Fixes (completed)

Small release-safety fixes applied after the C6 stabilization pass. No new gameplay
features, no balance changes, no backend Cloud Function changes.

**Changes:**

- **`export_presets.cfg`** — Android preset `version/name` set to `"1.0.0"` to match
  `BuildConfig.APP_VERSION` and the expected value in `tools/validate_android_release.py`.
  `version/code`, package name, and Web preset are unchanged.

- **`autoload/SaveManager.gd`** — Two upload-reliability improvements:
  - `upload_current_save_to_backend_cloud_now()` now builds the current payload first.
    If an upload is already in flight, it queues the new payload into
    `_pending_backend_cloud_save_data` and sets `_backend_cloud_retry_pending = true`
    instead of silently relying on the old in-flight data. The function still returns
    `true` so the caller can listen for the eventual result.
  - `_send_backend_cloud_save()` stores a deep copy of the dispatched payload in
    `_backend_cloud_upload_current_payload`. `mark_backend_cloud_upload_finished(false)`
    now restores that payload into `_pending_backend_cloud_save_data` if nothing newer
    is queued, then schedules a 60-second retry. This prevents payload loss when the
    backend returns `request_in_progress` or a network error before the upload response
    is processed.

- **`scenes/game/ClickerScreen.gd`** — Two signal-safety improvements:
  - `_ready()` wraps the `Platform.backend_operation_succeeded` and
    `Platform.backend_operation_failed` connections with `is_connected()` guards,
    matching the pattern already used in `AuthGateScreen`.
  - `_exit_tree()` now disconnects both backend signals if connected, preventing
    stale handler calls after the scene is removed.

- **`scenes/auth/AuthGateScreen.gd`** — Navigation/guest race guard: five navigation
  handlers (`_on_forgot_pressed`, `_on_to_register_pressed`, `_on_to_login_pressed`,
  `_on_back_to_login`, `_on_guest_pressed`) now return early if `_request_in_progress`
  is true. This prevents the Guest button from emitting `auth_gate_completed("guest")`
  while a login/register/reset request is active.

- **`android/build/AndroidManifest.xml`** — `<profileable android:enabled>` set to
  `false` to disable profiling in the release template. RuStore Pay metadata and the
  deeplink activity are unchanged.

**What C6.1 did NOT change:**

- Web/Yandex cloud-save — unchanged.
- Backend Cloud Functions — none changed.
- Save schema — no new or renamed fields.
- Gameplay, ads, payments, balance — unchanged.
- Localization — no new keys.
- `BackendApiClient` — no changes needed (already guards with `_busy` flag).
- `Platform.gd` — no changes needed.

**Validation:** see `docs/validation/backend_cloud_save_stabilization.md` (C6.1 section).

---

## QoL update mode

This project is in release-candidate QoL mode. When contributing:

- Keep balance and monetization values unchanged unless explicitly requested.
- Prefer small, individually reviewable patches.
- Do not introduce major mechanics, architecture rewrites, or new systems by default.
- Preserve Yandex lifecycle safety: runtime pause, audio pause, and payment state
  must remain correct after every change.
- Include brief validation notes (static checks or manual test steps) with every
  code change.
