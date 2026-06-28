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

## Backend cloud-save client foundation

A Yandex Cloud auth/save backend client has been added as a foundation for
future Android/RuStore cloud-save support.

### What was added

- `scripts/platform/backend/BackendAuthStore.gd` — persists session token,
  email, and email_verified to `user://backend_auth.json`.
- `scripts/platform/backend/BackendApiClient.gd` — HTTP client that wraps all
  backend endpoints (auth, password reset, email verification, save load/save/delete).

### Configuration

The backend base URL is expected in the project setting:

```
application/cloud_save/backend_url
```

Call `BackendApiClient.configure_from_project_settings()` to read it, or
`BackendApiClient.configure(url)` to supply it directly. The client does not
hardcode any URL; it must be configured before making requests.

**Never commit the backend URL as a secret or store credentials in project files.**
No passwords, session tokens, SMTP keys, or service-account keys should be
committed to the repository.

### Architecture notes

- This patch only adds the client foundation. Android/RuStore platform wiring
  and account UI are future patches.
- Web/Yandex Games cloud-save continues to use the Yandex SDK through
  `WebYandexPlatform` and `YandexBridge` — unchanged.
- Gameplay code must not call `BackendApiClient` directly. Future integration
  will go through `Platform` / `AndroidRuStorePlatform`.
- The backend stores a raw JSON save blob. It does not know game-specific save
  fields. `save_version` and `last_save_unix_time` are required by the backend
  and must be present in the save data before calling `save_save()`.

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
