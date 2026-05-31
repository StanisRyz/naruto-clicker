# Asset Map

## Debug visual testing controls (debug builds only)

These keys work only when `BuildConfig.IS_DEBUG_BUILD = true`. Nothing is saved after using them.

| Key | Action |
|-----|--------|
| F12 | Toggle visual test mode. Current and future enemies get 100000 HP. Boss timer pauses. Press again to restore normal HP and resume timer. |
| L | Deal 51% of max HP to current enemy. First press: ~49000/100000 HP (triggers wounded state). Second press: defeats or nearly defeats. |
| K | Mark current level as cleared and advance to the next level. Updates StageNavigator. Useful for rapidly walking through zones 1–21. |

- Not saved. Does not call SaveManager.
- Does not grant gold or progress tasks.
- Does not affect release builds (`IS_DEBUG_BUILD = false`).
- Intended for validating zones 1–21 enemy textures, elite textures, boss textures, and backgrounds.

## Zone asset reuse

Normal and elite enemy textures, and background textures, are shared across zones to reduce required assets.
Every boss uses its own unique zone folder.

| Gameplay Zone | Levels  | Enemy Asset Zone | Background Asset Zone | Boss Asset Zone |
|---------------|---------|------------------|-----------------------|-----------------|
| 1             | 1–10    | 1                | 1                     | 1               |
| 2             | 11–20   | 1                | 2                     | 2               |
| 3             | 21–30   | 3                | 3                     | 3               |
| 4             | 31–40   | 3                | 4                     | 4               |
| 5             | 41–50   | 5                | 5                     | 5               |
| 6             | 51–60   | 5                | 5                     | 6               |
| 7             | 61–70   | 1                | 1                     | 7               |
| 8             | 71–80   | 8                | 8                     | 8               |
| 9             | 81–90   | 8                | 8                     | 9               |
| 10            | 91–100  | 10               | 10                    | 10              |
| 11            | 101–110 | 11               | 11                    | 11              |
| 12            | 111–120 | 11               | 11                    | 12              |
| 13            | 121–130 | 1                | 1                     | 13              |
| 14            | 131–140 | 1                | 1                     | 14              |
| 15            | 141–150 | 8                | 8                     | 15              |
| 16            | 151–160 | 16               | 16                    | 16              |
| 17            | 161–170 | 17               | 17                    | 17              |
| 18            | 171–180 | 17               | 17                    | 18              |
| 19            | 181–190 | 17               | 17                    | 19              |
| 20            | 191–200 | 20               | 20                    | 20              |
| 21            | 201–210 | 10               | 10                    | 21              |

**Key reuse notes:**
- Zones 2, 7, 13, 14 reuse enemy assets from zone 1. Zone 2 has its own background.
- Zones 5, 6 share both enemies and background (zone 5 assets).
- Zones 8, 9, 15 share both enemies and background (zone 8 assets).
- Zones 10, 21 share both enemies and background (zone 10 assets).
- Zones 11, 12 share both enemies and background (zone 11 assets).
- Zones 17, 18, 19 share both enemies and background (zone 17 assets).
- Zone 4 reuses zone 3 enemies but has its own background.

## Required image folders

### Normal and elite enemy source folders

Only these zone folders need `enemy_01`, `enemy_02`, `enemy_03`, and `elite_01` sub-folders:

- `assets/images/enemies/zone_01/`
- `assets/images/enemies/zone_03/`
- `assets/images/enemies/zone_05/`
- `assets/images/enemies/zone_08/`
- `assets/images/enemies/zone_10/`
- `assets/images/enemies/zone_11/`
- `assets/images/enemies/zone_16/`
- `assets/images/enemies/zone_17/`
- `assets/images/enemies/zone_20/`

Each enemy slot folder needs four states: `healthy.png`, `hit.png`, `wounded.png`, `defeated.png`.

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
