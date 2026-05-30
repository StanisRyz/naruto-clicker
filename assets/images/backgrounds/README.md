# Zone Background Images

Background images are loaded by `BackgroundAssetCatalog` and displayed via `ImageSlot` in `GameField`.

## Folder format

```
backgrounds/
  zone_01/
    background.png
  zone_02/
    background.png
  zone_03/
    background.png
  zone_04/
    background.png
```

## Zone mapping

| Folder  | Levels | Zone name        |
|---------|--------|------------------|
| zone_01 | 1–10   | Training Grounds |
| zone_02 | 11–20  | Forest Path      |
| zone_03 | 21–30  | Stone Valley     |
| zone_04 | 31–40  | Shadow Camp      |

After level 40 the game reuses zone_04 data unless zone logic is expanded.

## Recommended image format

- Format: PNG or WebP
- Minimum size: 720×1600
- Recommended size: 1080×2400 (portrait 9:20)
- Keep important elements away from edges (safe area = central 80%)
- No UI, text, buttons, or icons
- Character/enemy placement area is around the lower third

## Fallback chain

1. `backgrounds/zone_XX/background.png` — zone-specific background
2. `GameAssetCatalog "game.field_background"` — global default background
3. Muted green `Color(0.25, 0.42, 0.25, 1)` ColorRect placeholder

Missing files never crash the game.
