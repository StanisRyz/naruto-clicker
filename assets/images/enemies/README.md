# Enemy Image Assets

Enemy images are loaded by `EnemyAssetCatalog` and displayed via `ImageSlot` in `GameField`.

## Folder format

```
enemies/
  zone_01/
    enemy_01/
      healthy.png
      hit.png
      wounded.png
      defeated.png
    enemy_02/
      healthy.png  ...
    enemy_03/ ...
    elite_01/ ...
    boss_01/ ...
  zone_02/ ...
  zone_03/ ...
  zone_04/ ...
```

## Non-boss enemy pool mapping

Non-boss normal/elite enemies use three shared pool folders. Bosses are unique per gameplay zone.

| Pool folder | Gameplay zones | Normal slots      | Elite slots       |
|-------------|----------------|-------------------|-------------------|
| zone_01     | 1–10           | enemy_01–enemy_15 | elite_01–elite_04 |
| zone_11     | 11–16          | enemy_01–enemy_15 | elite_01–elite_05 |
| zone_17     | 17–21          | enemy_01–enemy_09 | elite_01–elite_03 |

Zone 21 contains only `boss_01/` — it is not a normal/elite pool.

Empty folders use `.gitkeep` until real PNG assets are added.

## Enemy folder mapping

| Folder   | Type                                  |
|----------|---------------------------------------|
| enemy_## | Normal enemy slot (pool-relative)     |
| elite_## | Elite enemy slot (pool-relative)      |
| boss_01  | Boss — unique per gameplay zone       |

## Required state files per enemy folder

| File         | When shown                        | Fallback color |
|--------------|-----------------------------------|----------------|
| healthy.png  | HP > 50%                          | White          |
| hit.png      | 0.3 s after manual click/autoclick | Blue           |
| wounded.png  | HP ≤ 50%                          | Red            |
| defeated.png | On defeat / transition lock        | Black          |

## Fallback chain

1. Exact enemy image: `enemies/zone_01/enemy_01/healthy.png`
2. If missing → default enemy image: `enemy.default.healthy` (GameAssetCatalog)
3. If missing → placeholder color (white/blue/red/black)

Missing files never crash the game.
