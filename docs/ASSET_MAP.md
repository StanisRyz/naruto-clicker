# Asset Map

## Debug visual testing controls (debug builds only)

These keys work only when `BuildConfig.IS_DEBUG_BUILD = true`. Nothing is saved after using them.

| Key | Action |
|-----|--------|
| F12 | Toggle visual test mode. Current and future enemies get 100000 HP. Boss timer pauses. Press again to restore normal HP and resume timer. |
| L | Deal 51% of max HP to current enemy. First press: ~49000/100000 HP (triggers wounded state). Second press: defeats or nearly defeats. |
| K | Mark current level as cleared and advance to the next level. Updates StageNavigator. Zone changes every 5 levels; press K repeatedly to walk through all 21 zones in ~105 presses. |

- Not saved. Does not call SaveManager.
- Does not grant gold or progress tasks.
- Does not affect release builds (`IS_DEBUG_BUILD = false`).
- Intended for validating zones 1–21 enemy textures, elite textures, boss textures, and backgrounds.
- Useful for checking zone_01 pool enemies across zones 1–10, zone_11 pool enemies across zones 11–20, zone_21 final pool, and unique bosses in every zone.

## Enemy pools

Non-boss normal and elite enemies use shared pools. Bosses remain unique per gameplay zone.

| Gameplay Zones | Enemy Pool Folder  | Normal Count | Elite Count |
|----------------|--------------------|--------------|-------------|
| 1–10           | enemies/zone_01    | 15           | 4           |
| 11–20          | enemies/zone_11    | 15           | 5           |
| 21             | enemies/zone_21    | 3            | 1           |

**Slot names by pool:**

- `enemies/zone_01`: `enemy_01`–`enemy_15`, `elite_01`–`elite_04`
- `enemies/zone_11`: `enemy_01`–`enemy_15`, `elite_01`–`elite_05`
- `enemies/zone_21`: `enemy_01`–`enemy_03`, `elite_01`

Enemy state filenames: `healthy.png`, `hit.png`, `wounded.png`, `defeated.png`

Runtime selection via `EnemyPoolConfig`. ZoneConfig `enemies` and `elite_enemy` fields are legacy content notes and no longer used for enemy spawning.

## Boss asset zones

Every gameplay zone has a unique boss. Bosses load from the actual gameplay zone folder and do not use shared enemy pools.

| Gameplay Zone | Boss Asset Folder        |
|---------------|--------------------------|
| 1             | enemies/zone_01/boss_01/ |
| 2             | enemies/zone_02/boss_01/ |
| 3             | enemies/zone_03/boss_01/ |
| 4             | enemies/zone_04/boss_01/ |
| 5             | enemies/zone_05/boss_01/ |
| 6             | enemies/zone_06/boss_01/ |
| 7             | enemies/zone_07/boss_01/ |
| 8             | enemies/zone_08/boss_01/ |
| 9             | enemies/zone_09/boss_01/ |
| 10            | enemies/zone_10/boss_01/ |
| 11            | enemies/zone_11/boss_01/ |
| 12            | enemies/zone_12/boss_01/ |
| 13            | enemies/zone_13/boss_01/ |
| 14            | enemies/zone_14/boss_01/ |
| 15            | enemies/zone_15/boss_01/ |
| 16            | enemies/zone_16/boss_01/ |
| 17            | enemies/zone_17/boss_01/ |
| 18            | enemies/zone_18/boss_01/ |
| 19            | enemies/zone_19/boss_01/ |
| 20            | enemies/zone_20/boss_01/ |
| 21            | enemies/zone_21/boss_01/ |

## Background asset reuse

Background textures are shared across zones. Every zone uses the `background_asset_zone` field from ZoneConfig.

| Gameplay Zone | Levels  | Background Asset Zone |
|---------------|---------|-----------------------|
| 1             | 1–5     | 1                     |
| 2             | 6–10    | 2                     |
| 3             | 11–15   | 3                     |
| 4             | 16–20   | 4                     |
| 5             | 21–25   | 5                     |
| 6             | 26–30   | 5                     |
| 7             | 31–35   | 1                     |
| 8             | 36–40   | 8                     |
| 9             | 41–45   | 8                     |
| 10            | 46–50   | 10                    |
| 11            | 51–55   | 11                    |
| 12            | 56–60   | 11                    |
| 13            | 61–65   | 1                     |
| 14            | 66–70   | 1                     |
| 15            | 71–75   | 8                     |
| 16            | 76–80   | 16                    |
| 17            | 81–85   | 17                    |
| 18            | 86–90   | 17                    |
| 19            | 91–95   | 17                    |
| 20            | 96–100  | 20                    |
| 21            | 101–105 | 10                    |

## Required image folders

### Non-boss enemy pool folders

Only these zone folders contain normal/elite enemy slots:

- `assets/images/enemies/zone_01/` — `enemy_01`–`enemy_15`, `elite_01`–`elite_04`
- `assets/images/enemies/zone_11/` — `enemy_01`–`enemy_15`, `elite_01`–`elite_05`
- `assets/images/enemies/zone_21/` — `enemy_01`–`enemy_03`, `elite_01`

Each slot folder needs four states: `healthy.png`, `hit.png`, `wounded.png`, `defeated.png`.

Old non-boss source folders (zone_03, zone_05, zone_08, zone_10, zone_16, zone_17, zone_20 enemy/elite slots) are obsolete. Empty obsolete folders have been removed. Any that contained real assets were preserved.

### Boss folders

Every zone requires a unique `boss_01` folder:

- `assets/images/enemies/zone_01/boss_01/` through `assets/images/enemies/zone_21/boss_01/`

Each boss folder needs the same four state files listed above.

### Background folders

Only these zone folders need a `background.png`:

- `assets/images/backgrounds/zone_01/`
- `assets/images/backgrounds/zone_02/`
- `assets/images/backgrounds/zone_03/`
- `assets/images/backgrounds/zone_04/`
- `assets/images/backgrounds/zone_05/`
- `assets/images/backgrounds/zone_08/`
- `assets/images/backgrounds/zone_10/`
- `assets/images/backgrounds/zone_11/`
- `assets/images/backgrounds/zone_16/`
- `assets/images/backgrounds/zone_17/`
- `assets/images/backgrounds/zone_20/`

Missing files fall back to the default game asset catalog placeholder (no crash).

## Expected filenames

| Asset type | Filename(s) |
|------------|-------------|
| Enemy state | `healthy.png`, `hit.png`, `wounded.png`, `defeated.png` |
| Background | `background.png` |
| Partner / ability / building / shop / task / UI icon | `icon.png` |
| Partner skill icons | `skill_01.png` … `skill_05.png` |
| Ability rank icons | `rank_01.png` … `rank_05.png` |
| Prestige talent icons | `talent_01.png` … `talent_06.png` |

See `docs/ASSET_FOLDERS.md` for a complete folder listing with full paths.

## Top HUD layout

The top HUD (`PrimaryStatsPanel`) uses a single horizontal row containing 6 elements:

Gold | Gems | Hero Level | Click Damage | Partner DPS | Settings

Each stat icon is displayed at **64×64 px**. Recommended source image size: 128×128 or 256×256 for sharper scaling. The panel spans the full screen width minus 15 px on each side (690 px on a 720 px screen). All 6 elements are evenly distributed via `SIZE_EXPAND_FILL` so spacing is equal on all sides.

Value labels use compact number formatting to prevent overflow:

| Raw value | Displayed |
|-----------|-----------|
| 999 | 999 |
| 1 000 | 1.0K |
| 1 500 | 1.5K |
| 1 000 000 | 1.0M |
| 1 250 000 | 1.3M |
| 1 000 000 000 | 1.0B |
| 1 000 000 000 000 | 1.0T |
