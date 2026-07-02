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

## Current Settings model and account rules

**Settings window (`SettingsWindow.tscn`/`.gd`) contains, in order:** Sound,
Music, Language, Save Now, Account / Cloud (Android/RuStore only), Version.
There is **no Reset Progress control** — it was removed from production UI in
C7.2.1 and Account / Cloud (C7.2.2, C7.2.3) is its replacement for
progress-management going forward.

**Account rules (Android/RuStore; C7.1–C7.2.4):**
- Guest mode is local-only; progress is stored only on the device.
- Guest → Register uploads the current guest save to the new account's cloud
  save; gameplay continues without reload.
- Guest → Login force-loads the existing account's cloud save (or starts a
  clean save if the account has none); the guest save is never uploaded.
- Android/RuStore paid gem purchases require a backend account session; the
  Guest shop's donation entry is visibly locked (C7.2.4) and opens the AuthGate
  overlay instead of the purchase dialog.
- Rewarded ads remain fully available in Guest mode — never gated behind an
  account session.
- Web/Yandex is unaffected by all of the above: no AuthGate, no Account/Cloud
  section, and the paid shop is always available there.

## Save / reset rules

**Reset Progress is debug/internal only (removed from production UI in C7.2.1).**
The underlying `ClickerState.reset_to_new_game()` / preserved-snapshot helpers still
exist and back prestige and clean-account-save flows, but no production UI path may
call `SaveManager.delete_save()` or expose a user-facing reset.

**Reset Progress preserves (when invoked internally):**
- gems
- permanent shop upgrades
- settings / language

**Reset Progress resets (when invoked internally):**
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
| Save / Load / Prestige | Complete |
| Reset Progress removed from production UI (debug/internal only) | Complete |
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

> **Superseded.** This mid-session prompt flow was replaced by the C7.1 Account
> Save Authority rules (Guest → Register auto-uploads; Guest → Login force-loads
> the account cloud save; no prompt). The runtime flow was removed in C7.1.1, and
> `GuestMigrationPrompt.gd`/`.tscn` plus the `guest_migration.*` localization keys
> were deleted in C7.2.5. The section below is kept for historical record only.

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
`CloudRestorePrompt` (highest) → Settings/manual. (`GuestMigrationPrompt` removed in C7.1.1.)

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
- `GuestMigrationPrompt` flow removed (C7.1.1): node removed from `ClickerScreen.tscn`,
  all runtime references removed from `ClickerScreen.gd`. Scene/script files retained
  but unreferenced.
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

### C7.2.1 — Reset Progress Removed from Production UI (completed)

**Purpose:** Reset Progress was unsafe now that backend accounts, cloud save,
auto-upload, and paid purchases exist — a user-facing local reset could be
propagated to cloud by auto-upload and silently wipe an account's progress.

**Changes:**

- Reset Progress button, confirmation dialog, and signal flow removed from
  `scenes/ui/SettingsWindow.tscn` / `SettingsWindow.gd`
  (`reset_requested`, `reset_confirmed`, `ResetConfirmDialog`, and all related handlers).
- `scenes/game/ClickerScreen.gd` no longer connects to a Settings reset signal or
  calls `SaveManager.delete_save()` from any production UI path.
- Reset-progress-only localization keys removed from `localization/game_text.csv`
  (`settings.reset_progress`, `settings.confirm_reset`, `settings.progress_reset`,
  `settings.reset`, `settings.reset_confirm_title`, `settings.reset_confirm_description`)
  and `scripts/ui/LocalizationData.gd` regenerated.
- Save deletion/reset is now debug/internal only.

**What C7.2.1 did NOT change:**

- Internal runtime reset helpers (`_reset_runtime_state_for_new_game()`,
  `state.reset_to_new_game()`, preserved-snapshot helpers) — still used by prestige
  and by clean account save after Guest → Login with no cloud save.
- Prestige reset logic — unchanged.
- `SaveManager.delete_save()` — still exists for internal/tool use; simply has no
  production UI caller.
- Web/Yandex behavior, backend Cloud Functions, gameplay balance — unchanged.
- Account/Cloud Save controls in Settings — unchanged.

Account/Cloud Settings UI will replace the old Reset Progress affordance in later
patches, if a user-facing reset is ever reintroduced it must go through the account
system, not a raw local wipe.

**Validation:** see `docs/validation/reset_progress_removal.md`.

---

### C7.2.2 — Account / Cloud Entry Promoted in Settings (completed)

**Purpose:** After removing Reset Progress (C7.2.1), make Account / Cloud the
clear replacement entry point in Settings so players are guided toward account
login/register and cloud save instead of a local reset.

**Changes:**

- `scenes/ui/SettingsWindow.gd` — the Android-only account section header now
  reads "Account / Cloud" (`settings.account_cloud.title`, larger font) instead of
  plain "Account"; `VersionLabel` is moved to the bottom of the panel so the
  visual order is Sound → Music → Language → Save Now → Account/Cloud → Version.
- Guest mode explanation text expanded (`settings.account.guest_explanation`,
  was `settings.account.guest_warning`) to explicitly state that signing in
  enables cloud save and gem purchases, while rewarded ads remain available in
  Guest mode.
- `localization/game_text.csv` / `scripts/ui/LocalizationData.gd` — two keys
  renamed and one reworded (455 keys total, no net addition).

**What C7.2.2 did NOT change:**

- Reset Progress remains removed (C7.2.1) — not reintroduced.
- `SettingsWindow` signals (`sound_toggled`, `music_toggled`, `save_requested`,
  `language_manually_changed`, `account_auth_requested`,
  `cloud_save_upload_requested`, `cloud_save_download_requested`) — unchanged.
- Cloud save/load logic, busy-state handling, and load confirmation — unchanged.
- Guest → Login / Guest → Register logic (C7.1) — unchanged.
- Backend Cloud Functions, backend API paths, gameplay balance, ads/payments,
  Web/Yandex behavior — unchanged. Account/Cloud UI stays Android-only
  (`_is_backend_account_ui_supported()` still gates on `OS.has_feature("android")`).

**Validation:** see `docs/validation/account_cloud_settings_promotion.md`.

---

### C7.2.3 — Account Section UX Cleanup (completed)

**Purpose:** Polish and harden the Account/Cloud section after C7.2.2: separate
account vs. cloud status messages, add busy-state to account actions, and fix a
stale-message bug where a just-shown success message was immediately cleared by
a follow-up refresh.

**Changes:**

- `scenes/ui/SettingsWindow.gd` — added `_set_account_actions_busy(is_busy)` and
  `_account_action_busy`; Verify Email, Confirm Code, Logout (and defensively
  Sign in/Register) disable while their backend request is in flight and always
  re-enable on success or failure. Split `_refresh_account_section()` into a
  full variant (clears the action message and verification code input — used on
  window open and on external auth changes) and a state-only
  `_refresh_account_section_state()` (recomputes visibility/text only — used by
  operation success/failure handlers so their result message isn't immediately
  wiped). This fixed a real bug: `confirm_email_verification` success used to
  call the full refresh *after* showing "Email verified", erasing it instantly.
- Guest explanation text reworded to explicitly state progress is local-only,
  and that signing in unlocks cloud save and gem purchases while rewarded ads
  remain available regardless.
- Account messages (`_account_action_label`) and Cloud Save messages
  (`_cloud_status_label`) confirmed to use fully separate labels — no code path
  writes to the wrong one.
- `localization/game_text.csv` / `scripts/ui/LocalizationData.gd` — reworded
  `settings.account.guest_explanation`; added 3 busy-state keys
  (`verification_sending`, `verification_confirming`, `logout_in_progress`;
  458 keys total).

**What C7.2.3 did NOT change:**

- Reset Progress remains removed (C7.2.1) — not reintroduced.
- `SettingsWindow` signals — unchanged (same 7 signals as C7.2.2).
- `SaveManager` backend save/load logic, backend Cloud Functions, backend API
  paths — untouched.
- Guest → Login / Guest → Register logic (C7.1), `CloudRestorePrompt` logic —
  untouched.
- Cloud Save/Load visibility rules, load confirmation, and
  `set_cloud_save_buttons_busy()` — unchanged.
- Gameplay balance, ads/payments, Web/Yandex behavior — unchanged.

**Validation:** see `docs/validation/account_section_ux_cleanup.md`.

---

### C7.2.4 — Guest Paid Shop Lock UX (completed)

**Purpose:** The technical Guest paid-shop guards from C7.1 worked, but the
donation entry card still looked fully available, which confused players when
tapping it opened AuthGate instead of the purchase dialog. This patch makes
the lock state visible.

**Changes:**

- `scenes/ui/ShopPanel.gd` — new `set_paid_shop_available(is_available)`; only
  affects `product_type == "donation_entry"` rendering (button text switches
  to "Sign in / Register", description switches to "Account required", with a
  distinct muted tint). `rewarded_ad` and all other product types are
  unaffected.
- `scenes/ui/ShopSheet.gd` — delegates `set_paid_shop_available()` to the
  panel; adds a small status label so tapping the locked donation entry shows
  a short message ("Sign in or register to buy gems. Ads remain available.")
  before the AuthGate overlay opens.
- `scenes/game/ClickerScreen.gd` — `_update_shop_paid_availability()` now also
  pushes the flag into `shop_sheet`; a one-line startup sync ensures a cold
  Android Guest session shows the locked state immediately rather than only
  after the next auth event.
- Donation entry becomes visually available again immediately after Guest →
  Register or Guest → Login succeed, and locked again immediately after Logout
  — using the same `_update_shop_paid_availability()` call sites already wired
  in C7.1.

**What C7.2.4 did NOT change:**

- Payment/RuStore purchase flow, `GemPurchaseConfig` prices/products —
  untouched.
- Rewarded ads — remain fully available and unaffected in Guest mode.
- Backend Cloud Functions, backend API paths, cloud-save logic — untouched.
- Guest → Login / Guest → Register logic (C7.1) — untouched.
- Gameplay balance — unchanged.
- Reset Progress remains removed (C7.2.1) — not reintroduced.
- Web/Yandex behavior — `_is_paid_shop_available()` still returns `true`
  unconditionally off-Android; the shop never shows a locked state there.

**Validation:** see `docs/validation/guest_paid_shop_lock_ux.md`.

---

### C7.2.5 — Obsolete Reset Progress / GuestMigrationPrompt Cleanup (completed)

**Purpose:** Remove dead files and stale documentation left over after Reset
Progress (C7.2.1) and the old GuestMigrationPrompt flow (C7.1/C7.1.1) were
removed from production.

**Changes:**

- Deleted `scenes/ui/GuestMigrationPrompt.gd`/`.tscn`/`.gd.uid` (confirmed
  unreferenced since C7.1.1) and the unused
  `assets/images/ui/windows/settings/reset_confirm_background.png` (+`.import`)
  left over from C7.2.1.
- Removed the 6 `guest_migration.*` localization keys that only the deleted
  script used (459 → 453 keys).
- Added the "Current Settings model and account rules" summary above and
  marked historical docs/README sections describing the old flows as
  superseded/obsolete, without rewriting their point-in-time content.

**What C7.2.5 did NOT change:** any runtime behavior — this was a
docs/localization/dead-file cleanup only.

**Validation:** see `docs/validation/obsolete_reset_and_guest_migration_cleanup.md`.

---

### C7.2.6 — Final Settings/Account/Cloud/Shop Regression & Fixed-Size Window Audit (completed)

**Purpose:** Final hardening pass across the whole C7.2 series: re-verify
Settings/Account/Cloud/Shop behavior end-to-end, and audit fixed-size textured
windows to confirm none of the C7.2 UI changes introduced dynamic,
content-driven resizing.

**Findings:**

- No functional regressions or UI-state bugs were found in the C7.2.1–C7.2.5
  series — **no `.gd`/`.tscn` files were changed** by this patch.
- Reset Progress and GuestMigrationPrompt remain fully absent at runtime; all
  remaining "reset"/"migration" hits are either the unrelated AuthGate
  password-reset flow, an internal debug-tool label, or clearly-marked
  historical documentation.
- `SettingsWindow` signal contract, Account/Cloud state transitions (Guest ↔
  Account, Logout), busy-state handling, AuthGate entry points (Settings and
  Shop), and the Shop paid-lock behavior were all re-verified against the code
  and match the C7.1–C7.2.4 design with no drift.
- **Fixed-size window audit:** `SettingsWindow`, `ShopSheet`/`ShopPanel`,
  `GemPurchaseDialog`, `CloudRestorePrompt`, `AuthGateScreen`,
  `ShopPurchaseConfirmDialog`, `PrestigeConfirmDialog`, skill popups, and
  `TasksWindow` were all reviewed. No new dynamic or content-driven textured-
  window resizing was introduced by C7.2. One **pre-existing** (from C4, not
  C7.2) non-proportional resize was found in `SettingsWindow` (panel height
  overridden to 874px while width stays 540px when the Account/Cloud section
  is created) — it is a static, conditional resize (Android vs. not), not a
  per-content dynamic one, and was left unchanged since correcting it would be
  a Settings layout redesign, out of scope for this audit patch.

**What C7.2.6 did NOT change:** backend/cloud/payment/gameplay logic, Settings
layout, Account/Cloud runtime behavior, Guest → Login/Register logic,
`CloudRestorePrompt` logic, paid shop lock logic, payment/RuStore flow,
rewarded ads, Web/Yandex behavior — all confirmed unchanged by this audit-only
patch.

**Validation:** see `docs/validation/final_settings_account_cloud_regression.md`.

---

### C7.2.7 — SettingsWindow Fixed Aspect Ratio Cleanup (completed)

**Purpose:** Fix the pre-existing non-proportional `SettingsWindow` resize
flagged (but left unfixed, as out of scope) during the C7.2.6 audit.
`SettingsWindow` must keep a static textured-window size and must not resize
dynamically based on Account/Cloud content.

**Changes:**

- Removed the Android-only runtime override
  (`panel_container.offset_top = -437.0` / `offset_bottom = 437.0`) that made
  the panel `540×874` instead of its designed `540×525` — a non-proportional
  resize that stretched the `ui.window.settings.background` texture unevenly.
- Added an internal `BodyScrollContainer`/`BodyVBoxContainer` inside
  `SettingsWindow.tscn`: the header (title + close button) stays fixed and
  always visible; everything else (Sound, Music, Language, Save Now, Version,
  and the Android-only Account/Cloud section) now lives inside the scroll
  area, mirroring the existing `ShopSheet` header/scroll pattern.
- The outer textured panel is now exactly `540×525` on every platform, always
  — no runtime resize, no per-content growth, no aspect-ratio change.
- A proportional resize was evaluated and rejected: matching the ~1.03:1
  aspect ratio while fitting the full Account/Cloud content would need a
  ~899px-wide panel, which would overflow the 720px mobile viewport.

**What C7.2.7 did NOT change:**

- `SettingsWindow` signals — unchanged (same 7 signals; no reset signals).
- Account/Cloud creation/refresh/busy-state logic — only the container the
  controls are added into changed; all control creation and state logic is
  untouched.
- Backend/cloud/payment/shop/gameplay logic, Guest → Login/Register logic,
  `CloudRestorePrompt` logic, paid shop lock logic, Web/Yandex behavior —
  all unchanged.
- Reset Progress and `GuestMigrationPrompt` remain fully removed.

**Validation:** see `docs/validation/settings_window_fixed_aspect_ratio_cleanup.md`.

---

### C7.3.1 — Account Startup Force Cloud Load (completed)

**Purpose:** Make the account cloud save authoritative for *every* Android/RuStore
account login/session, not just the Guest → Login overlay path from C7.1. Fresh
account startup, a stored account session, and a direct AuthGate account login must
all load the account cloud save automatically — no "Load from cloud?" decision.

**Changes:**

- `ClickerScreen._ready()` now calls `_begin_account_startup_cloud_load()` instead
  of `request_backend_cloud_restore_check("startup")`. The latter is left defined
  but unused (no call sites remain) rather than deleted.
- `_begin_account_startup_cloud_load()` (new): no-op on Web/editor, no-op for Guest
  mode, no-op if there is no backend session. Otherwise sets
  `_force_account_cloud_load_on_startup = true` and calls `Platform.backend_load_save()`
  — the same force-load shape as `on_account_login_from_guest_overlay()` (C7.1), kept
  as a separate flag so the two triggers stay distinguishable.
- `_on_backend_cloud_op_succeeded("load_save", ...)` / `_on_backend_cloud_op_failed(...)`
  now check `_force_account_cloud_load_on_startup` first (before the existing
  `_force_account_cloud_load_after_guest_login`, manual-download, and legacy
  startup-check branches). On success with a save: applies it, refreshes gameplay
  UI, marks the session as non-guest, updates paid shop availability. On success with
  no save: applies a clean account save. On failure: keeps local gameplay state,
  shows a status message only if Settings is open, and never uploads local state.
  Both branches always resume backend auto-upload.
- `_apply_clean_account_save_after_guest_login()` renamed to
  `_apply_clean_account_save_after_missing_cloud()` — now shared by both the
  startup force-load and the Guest → Login force-load paths.
- `Main.gd`'s `"account_session"` case (AuthGate overlay reopened mid-session and a
  stored session revalidates) now calls `on_account_login_from_guest_overlay()`
  instead of `request_backend_cloud_restore_check("auth_overlay")`, so it force-loads
  too instead of going through the restore-prompt path.
- No localization changes: reused the existing `account_flow.login_cloud_load_*`
  keys (started/success/missing/failed) for the startup path's status messages.

**What C7.3.1 did NOT change:**

- Guest → Register upload behavior (C7.1) — `on_account_registered_from_guest_overlay()`
  is untouched.
- Guest → Login force-load behavior (C7.1) — same method, same flag shape, still
  never uploads the guest save.
- `SaveManager` schema, backend Cloud Function code, backend API paths.
- Manual Settings "Load from Cloud" confirmation flow
  (`_manual_backend_cloud_download_requested`) — unchanged.
- Paid shop lock behavior, payment/RuStore flow, rewarded ads, Settings UI layout.
- `CloudRestorePrompt` files/scene — left in the repo unused rather than deleted;
  it simply has no remaining call path that shows it for account startup/login.
- Web/Yandex behavior — completely unaffected (`_begin_account_startup_cloud_load()`
  no-ops on `not OS.has_feature("android")`).

**Validation:** see `docs/validation/account_startup_force_cloud_load.md`.

---

### C7.3.2 — Separate Account Window from Settings (completed)

**Purpose:** `SettingsWindow` had grown crowded once C7.1's Account/Cloud section was
added on top of Sound/Music/Language/Save. Split the detailed account/cloud UI into a
dedicated `AccountWindow` so `SettingsWindow` goes back to basic settings only.

**Changes:**

- Added `scenes/ui/AccountWindow.gd` / `AccountWindow.tscn`: a fixed-size textured
  window (`540×525`, same `"ui.window.settings.background"` texture and
  `BodyScrollContainer`/`BodyVBoxContainer` pattern as `SettingsWindow`, C7.2.7) that owns
  all account status/email/verification UI and the manual Save to Cloud / Load from Cloud
  UI — moved essentially verbatim from `SettingsWindow._create_account_section()` /
  `_create_cloud_section()`, including its own direct `Platform` signal connections for
  refreshing account state.
- `SettingsWindow.gd`: removed all `_account_*`/`_cloud_*` fields, section-building code,
  and the `account_auth_requested`/`cloud_save_upload_requested`/`cloud_save_download_requested`
  signals. Added a single Account button under Save (Android-only, same gating as the old
  Account/Cloud section) and a new `account_window_requested` signal.
- `ClickerScreen.tscn`: added an `AccountWindow` node next to `SettingsWindow`, hidden by
  default. `ClickerScreen.gd`: added `@onready var account_window`, connects
  `settings_window.account_window_requested` → `_on_settings_account_window_requested()`
  (hides Settings, shows AccountWindow — one modal at a time) and the three `AccountWindow`
  signals to the (renamed) `_on_account_window_cloud_save_upload_requested()` /
  `_on_account_window_cloud_save_download_requested()` handlers plus the existing
  `_on_settings_account_auth_requested()`.
- All `settings_window.set_cloud_save_status()` / `set_cloud_save_buttons_busy()` call
  sites replaced with new `_set_account_window_cloud_status()` /
  `_set_account_window_cloud_buttons_busy()` helpers (safe no-ops if `account_window` isn't
  valid). Every `if settings_window.visible:` guard that gated a cloud status message now
  checks `account_window.visible` instead.
- `account_window.visible` added to `_is_safe_for_fullscreen_ad()`,
  `_is_main_screen_clear_for_rewarded_banner()`, and the blocked-input guard in
  `_on_attack_requested()` — the same treatment `settings_window.visible` already had.
- Localization: added one new key, `settings.account_button` ("Account" / "Аккаунт").
  Everything else (`settings.account_cloud.title`, `settings.account.*`,
  `settings.cloud.*`) is reused unchanged as `AccountWindow`'s content — no other CSV
  churn.

**What C7.3.2 did NOT change:**

- Account startup force-load logic (C7.3.1), Guest → Register upload (C7.1), Guest →
  Login force-load (C7.1) — the underlying request/response handling is byte-for-byte the
  same; only which window shows the resulting status message changed.
- `SaveManager` schema, backend Cloud Function code, backend API paths, payment/RuStore
  flow, rewarded ads, paid shop lock logic, gameplay balance.
- `CloudRestorePrompt` — left in the repo unused, as in C7.3.1.
- Web/Yandex behavior — the Account button and `AccountWindow` only exist on Android
  (`_is_backend_account_ui_supported()` gate, same as the old Account/Cloud section).
- Fixed-size window rule — both `SettingsWindow` and `AccountWindow` keep their
  `540×525` outer panel; only `BodyVBoxContainer` content differs between them.

**Validation:** see `docs/validation/separate_account_window_from_settings.md`.

---

### C7.3.3 — Account Window Regression & AuthGate Visual Polish (completed)

**Purpose:** Regression-check the C7.3.2 Settings → AccountWindow split, and apply two
AuthGate visual microfixes: an opaque login/register/reset panel and the boot splash
image as the AuthGate background (visual continuity between app boot and first login).

**Changes:**

- Regression pass over C7.3.2: confirmed `SettingsWindow` still shows only Sound, Music,
  Language, Save, Account, Version with no inline account/cloud details; the Account
  button opens `AccountWindow` and closes Settings; `AccountWindow`'s three signals are
  connected in `ClickerScreen.gd`; cloud status/busy calls route through
  `_set_account_window_cloud_status()`/`_set_account_window_cloud_buttons_busy()`; and
  `account_window.visible` is included in the ad-safety/rewarded-banner/attack-input
  guards. No regressions found — no code changes were needed here.
- `scenes/auth/AuthGateScreen.gd`: added a full-rect `TextureRect` background using
  `res://assets/images/app/boot_splash.png` (`AUTH_BACKGROUND_TEXTURE`,
  `STRETCH_KEEP_ASPECT_COVERED`, `MOUSE_FILTER_IGNORE`) behind the existing dark overlay.
  Lowered the overlay from `Color(0,0,0,0.88)` to `Color(0,0,0,0.35)` so the splash image
  stays visible while keeping the panel/text readable.
- The login/register/reset `PanelContainer` background was already fully opaque
  (`bg_color.a == 1.0`) — documented with a comment rather than changed.
- Added `_apply_opaque_line_edit_style()`: local `normal`/`focus`/`read_only`
  `StyleBoxFlat` overrides (opaque backgrounds, visible focus border) plus explicit
  `font_color`/`font_placeholder_color` overrides, applied to every AuthGate `LineEdit`
  via `_make_line_edit()`. Buttons were left untouched — `main_theme.tres`'s `Button`
  styles are already opaque with white/outlined text, readable over any background.

**What C7.3.3 did NOT change:**

- `auth_gate_completed` source strings (`"guest"`, `"account_session"`, `"account_login"`,
  `"account_register"`), stored-session check, login/register/reset request flow,
  Continue as Guest — all untouched. AuthGate still only calls the backend through
  `Platform`, never `SaveManager` or `BackendApiClient` directly.
- Account startup force-load (C7.3.1), Guest → Register/Login (C7.1),
  `SaveManager` schema, backend Cloud Function code/API paths, payment/RuStore flow,
  rewarded ads, paid shop lock logic, gameplay balance.
- `CloudRestorePrompt` — left in the repo unused, as in C7.3.1/C7.3.2.
- Web/Yandex behavior — AuthGate only exists on Android; nothing in this patch touches
  Web/editor code paths.
- Panel/window sizing — the AuthGate panel keeps its existing procedural fixed
  `custom_minimum_size = Vector2(340, 520)`; no dynamic resize was introduced.

**Validation:** see `docs/validation/account_window_and_auth_visual_regression.md`.

---

### C7.3.4 — CloudRestorePrompt Cleanup & Account/Settings UI Polish (completed)

**Purpose:** Remove the now-dead `CloudRestorePrompt` flow (unused since C7.3.1 made
account cloud save authoritative) and polish `AccountWindow`/`SettingsWindow` — drop
the user-facing "Load from Cloud" action, simplify the account section to essentials,
give `AccountWindow` buttons texture-scale centered sizing instead of full-width
stretch, and enlarge `SettingsWindow` proportionally so Version is visible without
scrolling.

**Changes:**

- **`scenes/ui/CloudRestorePrompt.gd` / `.tscn` / `.gd.uid`** — deleted. Dead files;
  `request_backend_cloud_restore_check()` was already unreferenced outside its own
  definition per the C7.3.1 note.
- **`scenes/game/ClickerScreen.gd`** — removed the `cloud_restore_prompt` node ref and
  all startup cloud-restore prompt state/methods: `_startup_cloud_restore_check_requested`,
  `_startup_cloud_restore_check_in_progress`, `_startup_cloud_restore_prompt_pending`,
  `_startup_cloud_restore_pending_save_data`, `_startup_cloud_restore_pending_mode`,
  `_startup_cloud_restore_declined_this_session`, `_pre_startup_had_local_save`,
  `_pre_startup_local_timestamp`, `_pre_startup_local_save_snapshot_taken`,
  `_capture_pre_startup_local_save_snapshot()`, `_should_check_backend_cloud_restore()`,
  `request_backend_cloud_restore_check()`, `_evaluate_cloud_restore_candidate()`,
  `_on_cloud_restore_load_confirmed()`, `_on_cloud_restore_keep_local_confirmed()`.
  Also removed the manual-download branch (`_manual_backend_cloud_download_requested`,
  `_on_account_window_cloud_save_download_requested()`) since `AccountWindow` no longer
  exposes Load from Cloud. `_force_account_cloud_load_on_startup` and
  `_force_account_cloud_load_after_guest_login` handling — untouched.
- **`scenes/game/ClickerScreen.tscn`** — removed the `CloudRestorePrompt` node and its
  `ext_resource`; `load_steps` decremented from 25 to 24.
- **`scenes/ui/AccountWindow.gd`** — removed `cloud_save_download_requested` signal and
  all Load-from-Cloud UI (download button, confirm/cancel box, warning label) and
  handlers. Removed the Verify Email button, verification code input, and Confirm Code
  button — `Platform.backend_request_email_verification()`/
  `backend_confirm_email_verification()` are untouched (still callable, just no longer
  wired to this window); the window now only *displays* `Email verified`/`Email not
  verified`. Removed the big "Signed in"/"Guest mode" status label and the guest
  explanation label while signed in (guest explanation still shows for guests). Action
  buttons (`Sign in / Register`, `Save to Cloud`, `Logout`) now use
  `custom_minimum_size = Vector2(218, 75)` (`ACTION_BUTTON_SIZE`) with
  `SIZE_SHRINK_CENTER` instead of `SIZE_EXPAND_FILL`, matching the Settings Account
  button scale. `Logout` kept (needed for account switching) but placed after the cloud
  section as a secondary action.
- **`scenes/ui/SettingsWindow.tscn`** — `PanelContainer` enlarged proportionally from
  `540×525` to `648×630` (scale factor `1.2` on both axes), offsets recentered
  (`-324/-315` to `324/315`). Margins/theme unchanged — same fixed-size textured-window
  pattern as before, just larger. This removes the scroll previously needed to see
  Version.
- **`localization/game_text.csv`** — removed 26 stale keys: all 9 `cloud_restore.*`
  keys, and `settings.cloud.{title,status_guest_unavailable,status_account_ready,
  load_from_cloud,confirm_load,cancel_load,confirm_load_warning,download_started,
  download_success,download_failed,no_cloud_save,invalid_cloud_save}`, and
  `settings.account.{status_guest,status_signed_in,verify_email,
  verification_code_placeholder,confirm_code,verification_sending,verification_sent,
  verification_confirming,verification_success,verification_invalid_code}`.
  Regenerated `scripts/ui/LocalizationData.gd` (454 → 423 keys).

**What C7.3.4 did NOT change:**

- Account cloud save authority, startup force-load, Guest → Register upload,
  Guest → Login force-load (C7.1/C7.3.1) — all untouched.
- Backend Cloud Function code/API paths, `SaveManager` schema/payload format,
  payment/RuStore flow, rewarded ads, paid shop lock logic, gameplay balance.
- `Platform.backend_request_email_verification()` /
  `backend_confirm_email_verification()` — backend methods untouched, only the
  `AccountWindow` UI controls that called them were removed.
- Web/Yandex behavior — unchanged.
- `AccountWindow`'s own fixed `540×525` size — unchanged; only `SettingsWindow` was
  resized in this patch.

**Validation:** see `docs/validation/cloud_restore_cleanup_account_ui_polish.md`.

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
