# Asset Folders

## Why .gitkeep files exist

Git does not track empty directories. Every folder in this project contains a `.gitkeep` file so the folder structure is preserved in version control. **Do not delete `.gitkeep` files unless the folder already contains real assets.**

---

## Enemy images

Path: `assets/images/enemies/zone_##/slot/state.png`

### Non-boss enemy pools

Non-boss enemies use shared pools. Only three zone folders contain normal/elite enemy slots.

| Pool folder | Used by gameplay zones | Normal slots       | Elite slots        |
|-------------|------------------------|--------------------|---------------------|
| zone_01     | 1–10                   | enemy_01–enemy_15  | elite_01–elite_04  |
| zone_11     | 11–16                  | enemy_01–enemy_15  | elite_01–elite_05  |
| zone_17     | 17–21                  | enemy_01–enemy_09  | elite_01–elite_03  |

Each slot folder needs four files:
- `healthy.png`
- `hit.png`
- `wounded.png`
- `defeated.png`

Empty future enemy folders use `.gitkeep` until real PNG assets are added.

Zone 21 is no longer a normal/elite pool. `zone_21/` contains only `boss_01/`.

Old non-boss source folders (zone_03, zone_05, zone_08, zone_10, zone_16, zone_20 enemy/elite slots) are obsolete. Empty obsolete folders have been removed. Any that contained real assets were preserved.

### Boss folders

Every gameplay zone requires a unique `boss_01` folder, regardless of normal/elite pool assignment.

Zones 1–21: `assets/images/enemies/zone_01/boss_01/` through `zone_21/boss_01/`

Each boss folder needs the same four state files listed above.

Note: zone_02, zone_03, zone_04, zone_06, zone_07, zone_09, zone_12, zone_13, zone_14, zone_15, zone_18, zone_19 directories contain only `boss_01/` — this is correct, as those zones are not enemy pool source zones but do require unique bosses.

---

## Background images

Path: `assets/images/backgrounds/zone_##/background.png`

Only source zones listed in the reuse map need a `background.png`.

| Source zone | Used by gameplay zones |
|-------------|----------------------|
| zone_01     | 1, 7, 13, 14         |
| zone_02     | 2                    |
| zone_03     | 3                    |
| zone_04     | 4                    |
| zone_05     | 5, 6                 |
| zone_08     | 8, 9, 15             |
| zone_10     | 10, 21               |
| zone_11     | 11, 12               |
| zone_16     | 16                   |
| zone_17     | 17, 18, 19           |
| zone_20     | 20                   |

---

## Partner images

Path: `assets/images/partners/partner_##/partner.png`

Each partner has its own folder. 28 folders exist: `partner_01/` through `partner_28/`.

Example:
- `assets/images/partners/partner_01/partner.png`
- `assets/images/partners/partner_28/partner.png`

All 28 partner folders must exist. Empty folders carry `.gitkeep` until real PNG art is added.

Fallback behavior:
- If `partner.png` exists: the UI shows the image; the white background square is hidden.
- If `partner.png` is missing: the UI shows a white placeholder square. No crash.

This is expected while assets are being added gradually.

---

## Partner skill icons

Path: `assets/images/partners/Skills/skill#.png`

Skill icons are **shared by all partners**. There are 5 shared icons:
- `assets/images/partners/Skills/skill1.png`
- `assets/images/partners/Skills/skill2.png`
- `assets/images/partners/Skills/skill3.png`
- `assets/images/partners/Skills/skill4.png`
- `assets/images/partners/Skills/skill5.png`

Note: `Skills` uses a capital S — paths are case-sensitive in Web export.

Missing shared skill icons fall back to the locked fallback color safely.

TODO: old per-partner files in `assets/images/partners/skills/` can be removed after shared skill icons are confirmed in production.

---

## Hero skill icons

Path: `assets/images/hero_skills/skill_01.png` … `skill_05.png`

---

## Active ability icons

Path: `assets/images/abilities/ability_id/icon.png`

Ability folders: `autoclick`, `gold_bonus`, `focus_burst`, `rally`

**Important:** Ability rank is gameplay/text only. It does **not** affect the icon. All rank buttons in the UpgradePanel reuse the same `icon.png` and communicate state through color/tint.

Do **not** create `assets/images/ability_skills/` or rank-numbered files (`rank_01.png` … `rank_05.png`) for abilities.

### Active ability visual

Active abilities are indicated by a **white radial timer** drawn by `AbilityCooldownOverlay` in `ACTIVE` mode.
No image file is used. `active.png` is no longer referenced.

---

## Upgrade tab main cards

Path: `assets/images/upgrades/ability_id.png`

Files: `hero.png`, `autoclick.png`, `gold_bonus.png`, `focus_burst.png`, `rally.png`

These are large card images used in the Upgrades tab. Separate from the active ability button icons above.

---

## Settlement building icons

Path: `assets/images/settlement/building_name/icon.png`

Building folders: `training_camp`, `market`, `knight_hut`, `war_banner`, `clock_tower`, `boss_shrine`

---

## Shop icons

Path: `assets/images/shop/product_id/icon.png`

Product folders: `gems`, `gold_pack_small`, `gold_pack_large`, `boss_retry_token`, `task_reward_boost`

---

## Prestige icons

Path: `assets/images/prestige/prestige_point/icon.png`
Path: `assets/images/prestige/talents/talent_01.png` … `talent_06.png`

---

## Task icons

Path: `assets/images/tasks/task_type/icon.png`

Task folders: `tasks_button`, `manual_damage`, `defeat_enemies`, `defeat_elites`, `defeat_boss`, `hero_levels`, `hire_partners`, `buildings`, `autoclick`, `game_levels`

## TasksWindow open button

Path: `assets/images/tasks/tasks_button/`

| File | Shown when |
|------|-----------|
| `default.png` | No active task can be claimed |
| `completed.png` | At least one active task is completed and ready to claim |

Both files should be designed for an 80×80 button. Missing files fall back safely to a white placeholder — no crash.

---

## Top interface image

Path: `assets/images/ui/top_interface.png`

Recommended size: **720×430**

Purpose: Decorative unified background/frame for the upper HUD area (resource HUD, StageNavigator, ProgressInfoPanel, HP bar). Existing labels, icons, stage buttons, and HP bar are rendered by Godot above it.

Rules:
- Missing file falls back to transparent — no crash.
- Keep transparent background where possible.
- Do not include real text, numbers, or dynamic values.
- Do not include the boss timer area unless the design intentionally leaves room for it.

---

## UI icons

Path: `assets/images/ui/element_name/icon.png`

UI folders: `gold`, `gems`, `prestige_points`, `settings`, `close`, `auto_transition`, `stage_current`, `stage_open`, `stage_locked`, `skill_locked`, `skill_available`, `skill_purchased`

---

## Stage navigation images

Path: `assets/images/stage_navigation/zone_##/stage.png`

Stage navigation uses the **same zone folders as backgrounds** — not one folder per gameplay zone. Only 11 folders exist, matching the unique `background_asset_zone` values in ZoneConfig.

Required folders (mirrors background distribution):

```
assets/images/stage_navigation/zone_01/
assets/images/stage_navigation/zone_02/
assets/images/stage_navigation/zone_03/
assets/images/stage_navigation/zone_04/
assets/images/stage_navigation/zone_05/
assets/images/stage_navigation/zone_08/
assets/images/stage_navigation/zone_10/
assets/images/stage_navigation/zone_11/
assets/images/stage_navigation/zone_16/
assets/images/stage_navigation/zone_17/
assets/images/stage_navigation/zone_20/
```

Do **not** create `zone_06`, `zone_07`, `zone_09`, `zone_12`–`zone_15`, `zone_18`, `zone_19`, or `zone_21` — those gameplay zones reuse a background from another folder.

| Folder   | Used by gameplay zones |
|----------|------------------------|
| zone_01  | 1, 7, 13, 14 (and cyclic repeats) |
| zone_02  | 2                      |
| zone_03  | 3                      |
| zone_04  | 4                      |
| zone_05  | 5, 6                   |
| zone_08  | 8, 9, 15               |
| zone_10  | 10, 21                 |
| zone_11  | 11, 12                 |
| zone_16  | 16                     |
| zone_17  | 17, 18, 19             |
| zone_20  | 20                     |

Empty folders carry `.gitkeep` until real PNG art is added.

Fallback behavior:
- If `stage.png` exists: the button shows the image; the fallback color square is hidden.
- If `stage.png` is missing: the button shows the fallback color (blue = current, white = unlocked, grey = locked). No crash.

### Common overlays

Folder: `assets/images/stage_navigation/common/`

| File | Purpose | Required |
|------|---------|---------|
| `locked.png` | Drawn on top of locked stage buttons | Optional |
| `current.png` | Drawn on top of the current (active) stage button | Optional |

Both images should be **80×80 px**. They are layered above the zone stage image but below the stage number label. Neither blocks clicks or drag input.

- If `locked.png` is missing, locked stages are still darkened (modulate `0.35, 0.35, 0.35`) but no icon appears.
- If `current.png` is missing, the current stage still shows its fallback color (blue) but no icon appears.

---

## Cyclic zones

The game has 21 visual/content zones, each with 5 stages (levels 1–105). After stage 105, zone data and assets loop back to zone 1:

- Stages 106–110 use zone 1 data/assets
- Stages 111–115 use zone 2 data/assets
- …and so on

Stage numbers continue increasing normally (106, 107, …). Only zone data and assets are cyclic. This applies to backgrounds, enemies, boss names/keys, zone names, and stage navigation images.

---

## Manual UI size tuning locations

These are the scene values to edit when button sizes need to change. Update container offsets together with button sizes to avoid clipping.

### Active ability buttons

File: `scenes/ui/AbilityBar.tscn`

| What to change | Property |
|----------------|----------|
| Container width | `AbilityBar offset_right` (= offset_left + button_size) |
| Container height | `AbilityBar offset_bottom` (= offset_top + 4×size + 3×separation) |
| Button size | `AutoclickButton / GoldBonusButton / FocusBurstButton / RallyButton custom_minimum_size` |
| Button spacing | `AbilityBar theme_override_constants/separation` |

Current values (100×100 buttons, separation 12):
- `offset_left = 16`, `offset_right = 116`
- `offset_top = -141`, `offset_bottom = 295`
- `custom_minimum_size = Vector2(100, 100)`

### TasksWindow open button

File: `scenes/game/ClickerScreen.tscn`

| What to change | Property |
|----------------|----------|
| Button size | `TasksButton custom_minimum_size` |
| Horizontal position | `TasksButton offset_left` and `offset_right` (keep right margin = −24) |
| Vertical position | `TasksButton offset_top` and `offset_bottom` (keep top = −141 to align with AbilityBar) |

Current values (100×100):
- `custom_minimum_size = Vector2(100, 100)`
- `offset_left = -124`, `offset_right = -24`, `offset_top = -141`, `offset_bottom = -41`

---

## Custom fonts

Path: `assets/fonts/`

| File | Purpose | Required |
|------|---------|---------|
| `boss_timer.ttf` | Custom font for BossTimerLabel | Optional |
| `boss_timer.otf` | Fallback if `.ttf` is missing | Optional |

Both files are optional. If neither exists the boss timer falls back to the default project font. Color and outline are still applied regardless.

Boss timer visual tuning — all constants in `scripts/ui/UiFontConfig.gd`:

| Constant | Controls |
|----------|---------|
| `PROGRESS_BOSS_TIMER_FONT_SIZE` | Font size |
| `PROGRESS_BOSS_TIMER_FONT_PATH` | Path to `.ttf` font |
| `PROGRESS_BOSS_TIMER_FONT_FALLBACK_PATH` | Path to `.otf` fallback |
| `PROGRESS_BOSS_TIMER_FONT_COLOR` | Text color |
| `PROGRESS_BOSS_TIMER_OUTLINE_COLOR` | Outline color |
| `PROGRESS_BOSS_TIMER_OUTLINE_SIZE` | Outline thickness in pixels |

Only BossTimerLabel is affected. Other ProgressInfoPanel labels use the standard size-only overrides.

---

## Bottom tabs decorative backdrop

Path: `assets/images/ui/bottom_bar/tabs_backdrop.png`

Recommended size: **820×165 px**

The backdrop is a decorative layer placed behind the five tab buttons. It is 820px wide for a 720px viewport, providing 50px of horizontal bleed on each side so the texture does not look cropped at the screen edges. Do not put important details near the extreme left/right edges (within ~50px of each edge).

Layout (BottomBar matches backdrop height, buttons are vertically centered):
- BottomTabsBackdrop height: 165px
- BottomBar height: 165px
- BottomBar vertical margins: 20px top / 20px bottom
- Button height: 125px (20 + 125 + 20 = 165)

Rules:
- Rendered by `BottomTabsBackdrop` (`ColorRect` + `ImageSlot`) in `ClickerScreen.tscn`.
- `mouse_filter = IGNORE` — does not block clicks.
- Missing file falls back to transparent — no crash.
- This is NOT the old `BottomBar` panel background. No `background.png` is used for the BottomBar.

---

## Bottom tab button images

Path: `assets/images/ui/bottom_bar/tabs/<tab_name>/default.png` and `active.png`

Tab names: `upgrades`, `partners`, `settlement`, `prestige`, `shop`

| File | Shown when |
|------|-----------|
| `default.png` | Tab is not the currently open sheet |
| `active.png` | Tab is the currently open sheet |

Recommended size: **125×125 px** per tab button (square).

Rules:
- BottomBar has no background texture — only tab button textures are used.
- Button images may include baked-in text/art; Godot no longer draws native button text on the bottom bar.
- Missing files fall back to white — no crash.
- Switching tabs updates images immediately via `_update_bottom_bar_view()`.
- Closing a sheet returns all tabs to `default.png`.

Required folders:
```
assets/images/ui/bottom_bar/tabs/upgrades/
assets/images/ui/bottom_bar/tabs/partners/
assets/images/ui/bottom_bar/tabs/settlement/
assets/images/ui/bottom_bar/tabs/prestige/
assets/images/ui/bottom_bar/tabs/shop/
```

Run the following to validate:

```
godot --headless --script res://scripts/tools/ValidateBottomBarAssets.gd
```

---

## File naming conventions

| Type | Filename |
|------|----------|
| Enemy state | `healthy.png`, `hit.png`, `wounded.png`, `defeated.png` |
| Background | `background.png` |
| Icon (partner/ability/building/shop/task/UI) | `icon.png` |
| Hero skill | `skill_01.png` … `skill_05.png` |
| Active ability icon | `icon.png` (same file for all ranks) |
| Prestige talent | `talent_01.png` … `talent_06.png` |
