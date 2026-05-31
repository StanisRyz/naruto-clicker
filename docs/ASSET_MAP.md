# Asset Map

## Debug visual testing controls (debug builds only)

These keys work only when `BuildConfig.IS_DEBUG_BUILD = true`. Nothing is saved after using them.

| Key | Action |
|-----|--------|
| F12 | Toggle visual test mode. Current and future enemies get 100000 HP. Boss timer pauses. Press again to restore normal HP and resume timer. |
| L | Deal 51% of max HP to current enemy. First press: ~49000/100000 HP (triggers wounded state). Second press: defeats or nearly defeats. |
| K | Mark current level as cleared and advance to the next level. Updates StageNavigator. Useful for rapidly walking through zones. |

- Not saved. Does not call SaveManager.
- Does not grant gold or progress tasks.
- Does not affect release builds (`IS_DEBUG_BUILD = false`).
- Intended for validating zones 1–20 enemy textures, elite textures, boss textures, and backgrounds.

## Zone asset reuse

Normal and elite enemy textures, and background textures, are shared across zones to reduce required assets.
Every boss uses its own unique zone folder.

| Zone | Levels | Enemy asset zone | Background asset zone | Boss asset zone |
|------|--------|------------------|-----------------------|-----------------|
| 1  | 1–10    | 1  | 1  | 1  |
| 2  | 11–20   | 1  | 2  | 2  |
| 3  | 21–30   | 3  | 3  | 3  |
| 4  | 31–40   | 3  | 4  | 4  |
| 5  | 41–50   | 5  | 5  | 5  |
| 6  | 51–60   | 1  | 1  | 6  |
| 7  | 61–70   | 7  | 7  | 7  |
| 8  | 71–80   | 7  | 7  | 8  |
| 9  | 81–90   | 9  | 9  | 9  |
| 10 | 91–100  | 10 | 10 | 10 |
| 11 | 101–110 | 10 | 10 | 11 |
| 12 | 111–120 | 1  | 1  | 12 |
| 13 | 121–130 | 1  | 1  | 13 |
| 14 | 131–140 | 7  | 7  | 14 |
| 15 | 141–150 | 15 | 15 | 15 |
| 16 | 151–160 | 16 | 16 | 16 |
| 17 | 161–170 | 16 | 16 | 17 |
| 18 | 171–180 | 16 | 16 | 18 |
| 19 | 181–190 | 19 | 19 | 19 |
| 20 | 191–200 | 9  | 9  | 20 |

**Key reuse notes:**
- Zone 2 uses enemy assets from zone 1 but has its own background (zone 2).
- Zone 4 uses enemy assets from zone 3 but has its own background (zone 4).
- Zones 6, 12, 13 reuse both enemies and background from zone 1.
- Zones 8, 14 reuse both enemies and background from zone 7.
- Zone 11 reuses both enemies and background from zone 10.
- Zones 17, 18 reuse both enemies and background from zone 16.
- Zone 20 reuses both enemies and background from zone 9.

## Required image folders

### Normal and elite enemy folders

Only these zone folders need enemy_01, enemy_02, enemy_03, and elite_01 sub-folders:

- `assets/images/enemies/zone_01/`
- `assets/images/enemies/zone_03/`
- `assets/images/enemies/zone_05/`
- `assets/images/enemies/zone_07/`
- `assets/images/enemies/zone_09/`
- `assets/images/enemies/zone_10/`
- `assets/images/enemies/zone_15/`
- `assets/images/enemies/zone_16/`
- `assets/images/enemies/zone_19/`

Each enemy slot folder needs four states: `healthy.png`, `hit.png`, `wounded.png`, `defeated.png`.

### Boss folders

Every zone requires a unique boss_01 folder:

- `assets/images/enemies/zone_01/boss_01/`
- `assets/images/enemies/zone_02/boss_01/`
- `assets/images/enemies/zone_03/boss_01/`
- `assets/images/enemies/zone_04/boss_01/`
- `assets/images/enemies/zone_05/boss_01/`
- `assets/images/enemies/zone_06/boss_01/`
- `assets/images/enemies/zone_07/boss_01/`
- `assets/images/enemies/zone_08/boss_01/`
- `assets/images/enemies/zone_09/boss_01/`
- `assets/images/enemies/zone_10/boss_01/`
- `assets/images/enemies/zone_11/boss_01/`
- `assets/images/enemies/zone_12/boss_01/`
- `assets/images/enemies/zone_13/boss_01/`
- `assets/images/enemies/zone_14/boss_01/`
- `assets/images/enemies/zone_15/boss_01/`
- `assets/images/enemies/zone_16/boss_01/`
- `assets/images/enemies/zone_17/boss_01/`
- `assets/images/enemies/zone_18/boss_01/`
- `assets/images/enemies/zone_19/boss_01/`
- `assets/images/enemies/zone_20/boss_01/`

### Background folders

Only these zone folders need a `background.png`:

- `assets/images/backgrounds/zone_01/`
- `assets/images/backgrounds/zone_02/`
- `assets/images/backgrounds/zone_03/`
- `assets/images/backgrounds/zone_04/`
- `assets/images/backgrounds/zone_05/`
- `assets/images/backgrounds/zone_07/`
- `assets/images/backgrounds/zone_09/`
- `assets/images/backgrounds/zone_10/`
- `assets/images/backgrounds/zone_15/`
- `assets/images/backgrounds/zone_16/`
- `assets/images/backgrounds/zone_19/`

Missing files fall back to the default game asset catalog placeholder (no crash).
