# Asset Folders

## Why .gitkeep files exist

Git does not track empty directories. Every folder in this project contains a `.gitkeep` file so the folder structure is preserved in version control. **Do not delete `.gitkeep` files unless the folder already contains real assets.**

---

## Enemy images

Path: `assets/images/enemies/zone_##/slot/state.png`

### Normal and elite enemy source folders

Only source zones listed in the reuse map require `enemy_01`, `enemy_02`, `enemy_03`, and `elite_01` sub-folders. Other zones reuse these assets.

| Source zone | Used by gameplay zones |
|-------------|----------------------|
| zone_01     | 1, 2, 7, 13, 14      |
| zone_03     | 3, 4                 |
| zone_05     | 5, 6                 |
| zone_08     | 8, 9, 15             |
| zone_10     | 10, 21               |
| zone_11     | 11, 12               |
| zone_16     | 16                   |
| zone_17     | 17, 18, 19           |
| zone_20     | 20                   |

Each slot folder (`enemy_01`, `enemy_02`, `enemy_03`, `elite_01`) needs four files:
- `healthy.png`
- `hit.png`
- `wounded.png`
- `defeated.png`

### Boss folders

Every gameplay zone requires a unique `boss_01` folder, regardless of normal/elite reuse.

Zones 1–21: `assets/images/enemies/zone_01/boss_01/` through `zone_21/boss_01/`

Each boss folder needs the same four state files listed above.

Note: zone_07, zone_09, zone_15, and zone_19 enemy directories exist with only `boss_01/` inside — this is correct, as those zones are not normal/elite source zones but do require unique bosses.

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

Path: `assets/images/partners/partner_##/icon.png`

13 partner folders: `partner_01` through `partner_13`.

---

## Partner skill icons

Path: `assets/images/partner_skills/partner_##/skill_01.png` … `skill_05.png`

13 partner folders: `partner_01` through `partner_13`. Each has up to 5 skill icon slots.

---

## Hero skill icons

Path: `assets/images/hero_skills/skill_01.png` … `skill_05.png`

---

## Active ability icons

Path: `assets/images/abilities/ability_id/icon.png`

Ability folders: `autoclick`, `gold_bonus`, `focus_burst`, `rally`

---

## Ability rank/skill icons

Path: `assets/images/ability_skills/ability_id/rank_01.png` … `rank_05.png`

Ability folders: `autoclick`, `gold_bonus`, `focus_burst`, `rally`

---

## Settlement building icons

Path: `assets/images/settlement/building_name/icon.png`

Building folders: `training_camp`, `market`, `knight_hut`, `war_banner`, `clock_tower`, `boss_shrine`

---

## Shop icons

Path: `assets/images/shop/product_id/icon.png`

Product folders: `gems`, `gold_pack_small`, `gold_pack_large`, `instant_combo`, `boss_retry_token`, `task_reward_boost`

---

## Prestige icons

Path: `assets/images/prestige/prestige_point/icon.png`
Path: `assets/images/prestige/talents/talent_01.png` … `talent_06.png`

---

## Task icons

Path: `assets/images/tasks/task_type/icon.png`

Task folders: `tasks_button`, `manual_damage`, `defeat_enemies`, `defeat_elites`, `defeat_boss`, `hero_levels`, `hire_partners`, `buildings`, `autoclick`, `combo_empowered`, `game_levels`

---

## UI icons

Path: `assets/images/ui/element_name/icon.png`

UI folders: `gold`, `gems`, `prestige_points`, `settings`, `close`, `auto_transition`, `stage_current`, `stage_open`, `stage_locked`, `skill_locked`, `skill_available`, `skill_purchased`

---

## File naming conventions

| Type | Filename |
|------|----------|
| Enemy state | `healthy.png`, `hit.png`, `wounded.png`, `defeated.png` |
| Background | `background.png` |
| Icon (partner/ability/building/shop/task/UI) | `icon.png` |
| Skill/rank | `skill_01.png` … `skill_05.png` or `rank_01.png` … `rank_05.png` |
| Prestige talent | `talent_01.png` … `talent_06.png` |
