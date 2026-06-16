# Naruto Clicker / Anime Ninja Idle Clicker

## Project status

Final release-candidate / pre-publication. All core systems are implemented and
QA-complete: balance, assets, ads, payments, UI, audio, save/load, localization.

Current next steps: final Web release export, Yandex Games preview QA, upload
and moderation. After release, work should focus on QoL improvements, polish,
and blocking fixes only. Do not propose new major mechanics unless explicitly
requested.

## Tech stack

- Engine: Godot 4.5.1
- Language: GDScript
- Export target: Web / HTML5
- Platform SDK: Yandex Games
- Layout: vertical mobile portrait

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

### Donation gem purchases (Yandex Payments)

| Product ID | Gems | Price |
|---|---|---|
| `gems_25` | +25 gems | 24 RUB |
| `gems_150` | +150 gems | 99 RUB |
| `gems_500` | +500 gems | 249 RUB |
| `gems_1500` | +1500 gems | 499 RUB |

**Rewards** are granted only after a success callback. Close/error/cancel grants nothing.
Protect against duplicate success callbacks (prevent double-granting the same purchase token).
Unprocessed purchases are recovered via `payments.getPurchases()` on startup.
For consumable purchases the required order is: grant gems → update UI → save locally →
request cloud save flush → call `consumePurchase()`.

`GameplayAPI.stop()` / `start()` must be called around all rewarded and fullscreen ads.

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
  paused for an ad).
- Audio pauses during rewarded/fullscreen ads and resumes after close/error when the page is visible.
- `YandexBridge.is_ad_in_progress()` is used to avoid restarting GameplayAPI during ads.

### SFX behavior

- Sound setting gates all SFX; music setting gates music.
- SFX are suppressed while the page/tab is hidden.
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

Save immediately after purchases, ad rewards, task claims, reset, prestige, settings/language changes, and important economy changes.

**Cloud save:** Yandex cloud save (player data) is used alongside local save. Respect the
Yandex player data size limit. Cloud save is flushed after purchases, ad rewards, and any
action that changes persistent state. BigNumber values in the save must remain
forward-compatible; do not rename save field keys without adding a migration.

## Debug / release rules

- All dev-only features must be gated by `BuildConfig.is_debug_features_enabled()`.
- F12 debug mode and keyboard shortcuts (F5/F9/F10/F12/L/K) must not work in production.
- Fake ad / payment success must not work in production.
- `BalanceAuditReport`, `ProgressionSimulator`, and other dev tools are dev-only and must not be autoloaded or runtime-active in release builds.
- Before shipping: set `BuildConfig.IS_DEBUG_BUILD = false` in
  `res://scripts/game/BuildConfig.gd`.

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
