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
- Platform SDK: Yandex Games (Web), RuStore Pay / Ads (Android — placeholder)
- Layout: vertical mobile portrait

## Platform architecture

All platform-specific calls go through the `Platform` autoload
(`res://autoload/Platform.gd`). Gameplay and UI code must never call
`YandexBridge` directly.

| Export | Active implementation |
|---|---|
| Web (`OS.has_feature("web")`) | `WebYandexPlatform` — delegates to `YandexBridge` |
| Android (`OS.has_feature("android")`) | `AndroidRuStorePlatform` — safe placeholder (no real SDK yet) |
| Editor / other | `LocalDebugPlatform` — simulates flows in debug builds only |

`Platform` selects the correct implementation at startup, creates it as a
child node, and re-exposes all signals so callers only deal with `Platform`.

### Web / Yandex

`WebYandexPlatform` wraps `YandexBridge`. All SDK internals (JavaScript
callbacks, LoadingAPI, GameplayAPI, Yandex Payments, cloud save) remain
unchanged inside `YandexBridge`. `Platform` forwards `YandexBridge` signals
directly to its own signals, so no behavior changes exist on the Web export.

### Android / RuStore

`AndroidRuStorePlatform` is a safe placeholder:
- `game_ready`, `gameplay_start`, `gameplay_stop` are no-ops.
- Ad methods emit clean error callbacks; no crashes.
- Payment methods emit `payment_purchase_error`; no crashes.
- Cloud save is unavailable; `load_cloud_save` emits `cloud_save_loaded({})`.
- `check_unprocessed_purchases` emits `unprocessed_purchase_check_completed`.

RuStore Pay SDK and Android Ads SDK integration will extend this class when
ready. No existing Web/Yandex behavior is affected by this placeholder.

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

### Donation gem purchases (Yandex Payments)

| Product ID | Gems | Price |
|---|---|---|
| `gems_25` | +25 gems | 24 RUB |
| `gems_150` | +150 gems | 99 RUB |
| `gems_500` | +500 gems | 249 RUB |
| `gems_1500` | +1500 gems | 499 RUB |

- Use client-side Yandex Payments mode: `ysdk.getPayments()`. Do **not** use
  `getPayments({ signed: true })` unless a backend signature verification flow
  is added.
- Paid gems are granted only after a success callback that carries a **non-empty
  `purchaseToken`**. An empty or missing token must not grant gems.
- Cancel / error / close grant nothing.
- Duplicate success callbacks must not double-grant (deduplication by token).
- Unprocessed purchases are recovered via `payments.getPurchases()` on startup.
- Required consumable order: grant gems → update UI → save locally → request
  cloud save flush → call `consumePurchase()`.
- The gem purchase dialog must not be dismissible (close button or outside click)
  while `_payment_in_progress` is true.
- Payment modal must pause runtime and audio and call `GameplayAPI.stop()`.
  Cancel/error/success must clear pending payment state and call safe resume.

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

## QoL update mode

This project is in release-candidate QoL mode. When contributing:

- Keep balance and monetization values unchanged unless explicitly requested.
- Prefer small, individually reviewable patches.
- Do not introduce major mechanics, architecture rewrites, or new systems by default.
- Preserve Yandex lifecycle safety: runtime pause, audio pause, and payment state
  must remain correct after every change.
- Include brief validation notes (static checks or manual test steps) with every
  code change.
