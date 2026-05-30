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

## Zone mapping

| Folder  | Levels  | Zone name       |
|---------|---------|-----------------|
| zone_01 | 1–10    | Training Grounds |
| zone_02 | 11–20   | Forest Path     |
| zone_03 | 21–30   | Stone Valley    |
| zone_04 | 31–40   | Shadow Camp     |

Additional zones continue as zone_05, zone_06, etc.

## Enemy folder mapping

| Folder   | Enemy type                              |
|----------|-----------------------------------------|
| enemy_01 | First normal enemy in ZONE_DATA.enemies |
| enemy_02 | Second normal enemy                     |
| enemy_03 | Third normal enemy                      |
| elite_01 | Elite enemy for that zone               |
| boss_01  | Boss enemy for that zone                |

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
