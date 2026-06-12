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
- Useful for checking zone_01 pool enemies across zones 1–10, zone_11 pool enemies across zones 11–16, zone_17 pool enemies across zones 17–21, and unique bosses in every zone.

## Enemy pools

Non-boss normal and elite enemies use shared pools. Bosses remain unique per gameplay zone.
Zone 21 is no longer a normal/elite pool — it contains only a unique boss.

| Gameplay Zones | Enemy Pool Folder  | Normal Count | Elite Count |
|----------------|--------------------|--------------|-------------|
| 1–10           | enemies/zone_01    | 15           | 4           |
| 11–16          | enemies/zone_11    | 15           | 5           |
| 17–21          | enemies/zone_17    | 9            | 3           |

**Slot names by pool:**

- `enemies/zone_01`: `enemy_01`–`enemy_15`, `elite_01`–`elite_04`
- `enemies/zone_11`: `enemy_01`–`enemy_15`, `elite_01`–`elite_05`
- `enemies/zone_17`: `enemy_01`–`enemy_09`, `elite_01`–`elite_03`

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

## Cyclic zones

The game has 21 visual/content zones. After stage 105 (end of zone 21), zone data and assets loop cyclically:

- Stages 106–110 → zone 1
- Stages 111–115 → zone 2
- …
- Stages 206–210 → zone 21
- Stages 211–215 → zone 1

Stage numbers continue increasing normally. Only zone data/assets (backgrounds, enemies, boss names, zone names, stage navigation images) are cyclic. `ZoneConfig.get_zone_index_for_level(level)` returns the cyclic index for any level.

---

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
- `assets/images/enemies/zone_17/` — `enemy_01`–`enemy_09`, `elite_01`–`elite_03`

Each slot folder needs four states: `healthy.png`, `hit.png`, `wounded.png`, `defeated.png`.
Empty future enemy folders use `.gitkeep` until real PNG assets are added.

Zone 21 is no longer a normal/elite pool. `assets/images/enemies/zone_21/` contains only `boss_01/`.

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

### TasksWindow window background, close button, and claim button

| Asset key | Path | Recommended size |
|-----------|------|-----------------|
| `task.window.background` | `assets/images/tasks/window/background.png` | 620×670 px |
| `task.window.close` | `assets/images/tasks/window/close.png` | 72×72 px |
| `task.window.claim_button` | `assets/images/tasks/window/claim_button.png` | 120×80 px |

- `task.window.background`: missing → white 620×670 fallback. Present → texture shown, fallback hidden.
- `task.window.close`: missing → white 72×72 fallback. Present → texture shown, fallback hidden. No text drawn over close button.
- `task.window.claim_button`: missing → white 120×80 fallback. Present → texture shown, fallback hidden. Button text (Claim / In Progress / Claimed) drawn above texture by `ButtonTextLabel`. Disabled state dims image and label.

Validation: `godot --headless --script res://scripts/tools/ValidateTaskAssets.gd`

### Shop product icons

Recommended size: **136×136 px**

| Product ID | Asset key | Path |
|------------|-----------|------|
| `gold_pack_small` | `shop.gold_pack_small` | `assets/images/shop/gold_pack_small.png` |
| `gold_pack_large` | `shop.gold_pack_large` | `assets/images/shop/gold_pack_large.png` |
| `permanent_partner_dps_x2` | `shop.permanent_partner_dps_x2` | `assets/images/shop/permanent_partner_dps_x2.png` |
| `permanent_click_damage_x2` | `shop.permanent_click_damage_x2` | `assets/images/shop/permanent_click_damage_x2.png` |
| `permanent_gold_x2` | `shop.permanent_gold_x2` | `assets/images/shop/permanent_gold_x2.png` |

Fallback: missing → white 136×136 square. Present → texture shown, fallback hidden (`show_fallback_behind_texture = false`).

Asset key lookup: `GameAssetCatalog.shop_product_icon_key(product_id)` → `"shop.<product_id>"`.

---

### TasksWindow open button

Path: `assets/images/tasks/tasks_button/`

| File | Asset key | Shown when |
|------|-----------|-----------|
| `default.png` | `task.window_button.default` | No active task can be claimed |
| `completed.png` | `task.window_button.completed` | At least one active task is completed and ready to claim |

Both files are optional during development. Missing files fall back to a white placeholder — no crash.

### Task card background

Path: `assets/images/tasks/task_card.png`

| Asset key | Path |
|---|---|
| `task.card.background` | `res://assets/images/tasks/task_card.png` |

Recommended size: **580×100 px**. Missing → white fallback. Present → texture shown, fallback hidden. Used by all 5 task cards via `ImageSlot` as the first (bottom-most) child of each task row.

### Task card icons

Path: `assets/images/tasks/task_type/icon.png`

Task card image size: **80×80 px** (square). Displayed beside the 3-row text layout:
1. **Condition** (row 0) — task requirement text, font size `TASK_CONDITION_FONT_SIZE`
2. **Progress** (row 1) — `{current} / {target}`, font size `TASK_PROGRESS_FONT_SIZE`
3. **Reward** (row 2) — `Reward: {reward} Gold`, font size `TASK_REWARD_FONT_SIZE`

Font sizes are controlled via `UiFontConfig`. Claim button is **160×80 px**, vertically centered.

## Stage navigation asset reuse

StageNavigator images live in `assets/images/stage_navigation/zone_##/stage.png`. The folder set mirrors the background asset distribution exactly — only 11 folders exist, one per unique `background_asset_zone` value.

Required folders:

```
assets/images/stage_navigation/zone_01/stage.png
assets/images/stage_navigation/zone_02/stage.png
assets/images/stage_navigation/zone_03/stage.png
assets/images/stage_navigation/zone_04/stage.png
assets/images/stage_navigation/zone_05/stage.png
assets/images/stage_navigation/zone_08/stage.png
assets/images/stage_navigation/zone_10/stage.png
assets/images/stage_navigation/zone_11/stage.png
assets/images/stage_navigation/zone_16/stage.png
assets/images/stage_navigation/zone_17/stage.png
assets/images/stage_navigation/zone_20/stage.png
```

Do **not** create `zone_06`, `zone_07`, `zone_09`, `zone_12`–`zone_15`, `zone_18`, `zone_19`, or `zone_21`.

Missing `stage.png` files are **warnings** (safe fallback color shown). Missing or unexpected zone folders are **errors**.

### Common overlays

`assets/images/stage_navigation/common/` — shared overlay icons, both 80×80, both optional.

| File | When shown |
|------|-----------|
| `locked.png` | Locked stage buttons (also darkened by modulate) |
| `current.png` | Current (active) stage button only |

Overlays are layered above the zone stage image, below the stage number label. Missing files are safe — fallback colors and darkening still apply.

Run the following to validate:

```
godot --headless --script res://scripts/tools/ValidateStageNavigationAssets.gd
```

---

## StageNavigator side button textures

Side buttons no longer render text labels. Visuals come entirely from `ImageSlot` texture or fallback color.

Recommended size: **80×80 px**.

| Asset key | Path | Fallback |
|-----------|------|---------|
| `stage.auto_on` | `assets/images/ui/stage_navigation/auto_transition/enabled.png` | Green (`COLOR_AUTO_ON`) |
| `stage.auto_off` | `assets/images/ui/stage_navigation/auto_transition/disabled.png` | Gray (`COLOR_AUTO_OFF`) |
| `stage.latest` | `assets/images/ui/stage_navigation/latest_stage/default.png` | Gold (`COLOR_LATEST`) |

- Missing files are **warnings** (safe color fallback shown, no crash).
- `stage.auto_on` / `stage.auto_off` keys are set by `StageNavigator.set_auto_transition_enabled()` — key names must not change.
- `stage.latest` key is set once in `_build_ui()` — key name must not change.

Validated by: `godot --headless --script res://scripts/tools/ValidateStageNavigationAssets.gd`

---

## Enemy asset validation

Run the following command from the project root to validate all required enemy PNG files:

```
godot --headless --script res://scripts/tools/ValidateEnemyAssets.gd
```

What the script checks:

- All required PNG files exist under `assets/images/enemies/`
- Missing PNG files are reported as **errors** (exit code 1)
- Missing `.import` sidecar files are reported as **warnings** (exit code stays 0 if no PNG errors)
- `assets/images/enemies/zone_21/` must contain only `boss_01/` — any `enemy_*` or `elite_*` subfolder is an **error**
- Expected total: **72 slots** × 4 states = **288 required PNG files**

## Expected filenames

| Asset type | Filename(s) |
|------------|-------------|
| Enemy state | `healthy.png`, `hit.png`, `wounded.png`, `defeated.png` |
| Background | `background.png` |
| Partner / ability / building / shop / task / UI icon | `icon.png` |
| Shared skill rank icons | `skill_01.png` … `skill_05.png` (see below) |
| Prestige talent icons | `talent_01.png` … `talent_06.png` |

### Shared skill rank icons

All hero skill, partner skill, and ability rank skill buttons use the same 5 shared icon files:

| Asset key | Path | Displayed size |
|-----------|------|---------------|
| `skill.rank.1` | `assets/images/skills/skill_01.png` | 32×32 px |
| `skill.rank.2` | `assets/images/skills/skill_02.png` | 32×32 px |
| `skill.rank.3` | `assets/images/skills/skill_03.png` | 32×32 px |
| `skill.rank.4` | `assets/images/skills/skill_04.png` | 32×32 px |
| `skill.rank.5` | `assets/images/skills/skill_05.png` | 32×32 px |

Recommended source size: **64×64 or 128×128 px**.

Used by:
- Hero skill slots (ranks 1–5) via `GameAssetCatalog.hero_skill_key(rank)`
- Partner skill slots (ranks 1–5) via `GameAssetCatalog.partner_skill_key(partner_index, rank)`
- Ability rank skill slots (ranks 1–5) via `GameAssetCatalog.ability_skill_key(ability_id, rank)`

All three helpers resolve to `skill.rank.N`, which `GameAssetCatalog.get_path()` maps to the shared file. The `partner_index` and `ability_id` arguments are retained in the method signatures for call-site compatibility but do not affect the returned path.

Icon visual state is applied as `modulate` on the `ImageSlot` node:
- **Purchased** → `Color.WHITE` (no tint)
- **Affordable / can buy** → `Color(0.65, 1.0, 0.65)` (light green)
- **Locked / cannot buy** → `Color(0.35, 0.35, 0.35)` (dark gray)

Missing files fall back to the locked dark-gray color — no crash.

Active ability visual: a white radial timer drawn by `AbilityCooldownOverlay` (ACTIVE mode). No image file is used — `active.png` is not referenced.

See `docs/ASSET_FOLDERS.md` for a complete folder listing with full paths.

## Fixed popup/window texture sizes

These sizes are authoritative for texture authoring. Popups and windows use explicit fixed dimensions so backgrounds can be prepared at exact pixel sizes.

| Scene | Texture path | Exact size | ImageHolder node name |
|---|---|---|---|
| UpgradeSkillPopup | `assets/images/ui/popups/skill/background.png` | 350×270 px | `PopupBackgroundImageHolder` (added at runtime) |
| PartnerSkillPopup | `assets/images/ui/popups/skill/background.png` | 350×270 px | `PopupBackgroundImageHolder` (added at runtime) |
| AutoTransitionPopup | `assets/images/ui/popups/auto_transition/background.png` | 340×220 px | `PopupBackgroundImageHolder` (added at runtime) |
| SettingsWindow | `assets/images/ui/windows/settings/background.png` | 360×350 px | `SettingsBackgroundImageHolder` (added at runtime) |
| SettingsWindow ResetConfirmDialog | `assets/images/ui/windows/settings/reset_confirm_background.png` | 340×224 px | `ResetConfirmBackgroundImageHolder` (added at runtime) |
| PrestigeConfirmDialog fullscreen | `assets/images/ui/dialogs/prestige/background.png` | 720×1280 px | `PrestigeDialogBackgroundImageHolder` (added at runtime) |
| PrestigeConfirmDialog inner panel | `assets/images/ui/dialogs/prestige/inner_background.png` | 500×350 px | `PrestigeDialogInnerBackgroundImageHolder` (added at runtime) |
| ShopPurchaseConfirmDialog inner panel | `assets/images/ui/popups/shop_confirm/background.png` | 500×230 px | `ShopPurchaseConfirmBackgroundImageHolder` (added at runtime) |

Asset folder structure (folders exist with `.gitkeep`; no PNG files yet):

```
assets/images/ui/popups/skill/
assets/images/ui/popups/auto_transition/
assets/images/ui/popups/shop_confirm/
assets/images/ui/windows/settings/
assets/images/ui/dialogs/prestige/
```

Scene size summary:
- `PanelContainer.custom_minimum_size` and offsets are both set to the exact pixel dimensions above.
- ImageHolder nodes are full-rect (`PRESET_FULL_RECT`) inside their respective `PanelContainer`, so texture fills the panel exactly.
- PrestigeConfirmDialog: outer `PanelContainer` is full-screen (darkened backdrop, 720×1280 design target); `InnerPanel` is fixed 500×350 and centered via `CenterContainer`.

---

## Popup and window textures

All popup/window backgrounds and action buttons use `ImageSlot` nodes added at runtime in `_ready()`.

- **Texture exists** → texture shown, fallback hidden (`show_fallback_behind_texture = false`).
- **Texture missing** → white rectangle fallback shown, no crash.

Close buttons reuse the existing sheet close button: `ui.sheet.close_button` / `assets/images/ui/sheets/close_button.png` (72×56 px).

### Popup backgrounds

| Asset key | Path | Recommended size | Used by |
|-----------|------|-----------------|---------|
| `ui.popup.skill.background` | `assets/images/ui/popups/skill/background.png` | 350×270 px | UpgradeSkillPopup, PartnerSkillPopup |
| `ui.popup.auto_transition.background` | `assets/images/ui/popups/auto_transition/background.png` | 340×220 px | AutoTransitionPopup |

### Window and dialog backgrounds

| Asset key | Path | Recommended size | Used by |
|-----------|------|-----------------|---------|
| `ui.window.settings.background` | `assets/images/ui/windows/settings/background.png` | 360×350 px | SettingsWindow main panel |
| `ui.window.settings.reset_confirm_background` | `assets/images/ui/windows/settings/reset_confirm_background.png` | 340×224 px | SettingsWindow reset confirm dialog |
| `ui.dialog.prestige.background` | `assets/images/ui/dialogs/prestige/background.png` | 720×1280 px | PrestigeConfirmDialog full-screen panel |
| `ui.dialog.prestige.inner_background` | `assets/images/ui/dialogs/prestige/inner_background.png` | 500×350 px | PrestigeConfirmDialog inner panel |
| `ui.popup.shop_confirm.background` | `assets/images/ui/popups/shop_confirm/background.png` | 500×230 px | ShopPurchaseConfirmDialog inner panel |

### Popup action buttons

| Asset key | Path | Recommended size | Used for |
|-----------|------|-----------------|---------|
| `ui.popup.button.default` | `assets/images/ui/popups/buttons/default.png` | 210×72 px | Buy, Save, Cancel, Yes/No buttons |
| `ui.popup.button.danger` | `assets/images/ui/popups/buttons/danger.png` | 210×72 px | Reset and destructive action buttons |

Button text is drawn by a child `Label` (`ButtonTextLabel`) placed above the `ImageSlot` (`ButtonImageHolder`). Native button text is cleared. Both children have `mouse_filter = IGNORE` so clicks reach the `Button` node.

---

## Standard bottom sheet background

| Asset key | Path | Recommended size |
|-----------|------|-----------------|
| `ui.sheet.standard` | `assets/images/ui/sheets/standard_sheet.png` | 720×645 px |
| `ui.sheet.close_button` | `assets/images/ui/sheets/close_button.png` | 72×56 px |

Used by UpgradeSheet, PartnerSheet, SettlementSheet, PrestigeSheet, and ShopSheet.
Rendered by `SheetBackgroundImageHolder` (`ImageSlot`) — first child of `PanelContainer` (Control),
full-rect, `mouse_filter = IGNORE`. Missing file shows dark fallback `Color(0.08, 0.085, 0.1)`.
Texture hides fallback when present (`show_fallback_behind_texture = false`, `stretch_mode = STRETCH_SCALE`).

Validation: `godot --headless --script res://scripts/tools/ValidateSheetAssets.gd`

---

## Standard sheet card background

| Asset key | Path | Recommended size |
|-----------|------|-----------------|
| `ui.card.sheet` | `assets/images/ui/cards/sheet_card.png` | 656×156 px |

Rendered by `CardBackgroundImageHolder` (`ImageSlot`) inside each standard card row in UpgradePanel, PartnerPanel, SettlementPanel, PrestigePanel, and ShopPanel. Positioned as the first child of the row `Control` (behind all content). `mouse_filter = IGNORE`.

Rules:
- Missing file is a **warning** (safe dark fallback shown, no crash).
- Fallback color: `Color(0.12, 0.125, 0.145, 1.0)`.
- Fallback is hidden once the texture loads (`show_fallback_behind_texture = false`).
- Do not put button text or dynamic values in the texture.

Run `godot --headless --script res://scripts/tools/ValidateCardAssets.gd` to validate.

## Standard card purchase button textures

| Asset key | Path | Recommended size | When shown |
|-----------|------|-----------------|------------|
| `ui.card.button.default` | `assets/images/ui/cards/button/default.png` | 210×72 px | Normal / idle state |
| `ui.card.button.active` | `assets/images/ui/cards/button/active.png` | 210×72 px | 0.3 s flash after successful purchase |

Rendered by `ButtonImageHolder` (`ImageSlot`) inside each card purchase button. The button occupies rows 2–4 of the card (y=29..101 inside the 210×136 slot). The button is always a child of a `ButtonSlot` Control (210×136) added to the card `HBoxContainer`.

Used by:
- Upgrade hero level button (`UpgradeButton`)
- Upgrade ability unlock/buy buttons (`BuyButton`)
- Partner hire buttons (`HireButton`)
- Settlement building buy buttons (`BuyButton`)
- Prestige reset/action button (`PrestigeButton`) — default only, no active feedback
- Prestige talent upgrade buttons (`UpgradeButton`)
- Shop product buy buttons (`BuyButton`) — active feedback on successful purchase

Rules:
- Missing file is a **warning** (safe white fallback shown, no crash).
- Fallback color: `Color.WHITE`.
- Fallback is hidden once the texture loads (`show_fallback_behind_texture = false`).
- Button text is drawn by `ButtonTextLabel` (`Label`) child placed above the `ImageSlot`, centered, with word-wrap.
- Native Button background and focus styles are cleared (`button.flat = true`).
- `ImageSlot` and `Label` both have `mouse_filter = IGNORE` — clicks reach the `Button` node.
- Disabled state: `button_image_holder.modulate = Color(0.65, 0.65, 0.65)`, `button_label.modulate = Color(0.45, 0.45, 0.45)`.
- Active flash uses integer token guard; rapid re-purchases cancel the previous timer's reset.

Run `godot --headless --script res://scripts/tools/ValidateCardAssets.gd` to validate.

---

## Top interface image

Asset key: `ui.top_interface`
Path: `assets/images/ui/top_interface.png`
Recommended size: **720×320 px**

Purpose: Shared decorative backdrop for the top HUD + StageNavigator area. Rendered by `TopInterfaceImageHolder` (`ColorRect` + `ImageSlot`, `anchors_preset = -1`, `offset_bottom = 320`) in `ClickerScreen.tscn`, positioned above `GameField` and below all dynamic UI elements.

Covers: y = 0..320 — resource HUD (y = 91..179), settings button, StageNavigator (y = 210..308).

Does **not** cover: ProgressInfoPanel, enemy sprite area, active abilities, bottom tabs.

Rules:
- Missing file falls back to a white rectangle (`Color(1, 1, 1, 1)`) — no crash.
- Texture exists: texture is shown, white fallback is hidden (`show_fallback_behind_texture = false`).
- `mouse_filter = IGNORE` — does not block any input.
- No text, stage numbers, or dynamic values baked into the texture.

Validation: `godot --headless --script res://scripts/tools/ValidateTopInterfaceAssets.gd`

---

## Bottom tabs decorative backdrop

| Asset key | Path |
|-----------|------|
| `ui.bottom_tabs.backdrop` | `assets/images/ui/bottom_bar/tabs_backdrop.png` |

Recommended size: **820×165 px** (50px bleed each side beyond the 720px viewport).

Rendered by `BottomTabsBackdrop` in `ClickerScreen.tscn` — a `ColorRect` + `ImageSlot` positioned behind `BottomBar`. `mouse_filter = IGNORE`. Missing file falls back to transparent. This is a decorative layer only; do not put important detail within ~50px of the left/right edges.

Layout: BottomBar height = 165px, vertical margins = 20/20, button height = 125px. Buttons are vertically centered inside the backdrop (20 + 125 + 20 = 165).

No old `BottomBar` panel background (`ui.bottom_bar.background`) is used.

---

## Bottom tab buttons

Each tab has two image states: `default` and `active`.

| Asset key | Path |
|-----------|------|
| `ui.bottom_tab.upgrades.default` | `assets/images/ui/bottom_bar/tabs/upgrades/default.png` |
| `ui.bottom_tab.upgrades.active` | `assets/images/ui/bottom_bar/tabs/upgrades/active.png` |
| `ui.bottom_tab.partners.default` | `assets/images/ui/bottom_bar/tabs/partners/default.png` |
| `ui.bottom_tab.partners.active` | `assets/images/ui/bottom_bar/tabs/partners/active.png` |
| `ui.bottom_tab.settlement.default` | `assets/images/ui/bottom_bar/tabs/settlement/default.png` |
| `ui.bottom_tab.settlement.active` | `assets/images/ui/bottom_bar/tabs/settlement/active.png` |
| `ui.bottom_tab.prestige.default` | `assets/images/ui/bottom_bar/tabs/prestige/default.png` |
| `ui.bottom_tab.prestige.active` | `assets/images/ui/bottom_bar/tabs/prestige/active.png` |
| `ui.bottom_tab.shop.default` | `assets/images/ui/bottom_bar/tabs/shop/default.png` |
| `ui.bottom_tab.shop.active` | `assets/images/ui/bottom_bar/tabs/shop/active.png` |

Recommended tab image size: **125×125 px** (square). BottomBar has no background texture. Button nodes remain (`Button` type) so pressed signals continue to work. `ImageHolder` (`ImageSlot`) is visual only — mouse input passes through to the button. Missing tab textures fall back to white. Godot no longer draws native text on these buttons.

---

## Top HUD layout

The top HUD (`PrimaryStatsPanel`) uses a single horizontal row containing 4 elements:

Gold | Click Damage | Partner DPS | Settings

Gems are intentionally hidden from the top HUD but remain in the game economy and Shop.

Each stat icon is displayed at **72×72 px**, centered inside an 80×80 px layout cell (4 px inset on all sides). Recommended source image size: 128×128 or 256×256 for sharper scaling. The panel spans the full screen width. All 4 elements are evenly distributed across available width so spacing is equal on all sides. ImageSlot `show_fallback_behind_texture = false` is set on all HUD icons so that loaded PNG icons appear without a white square background; the fallback color is still shown when an image file is missing.

The Settings button retains an 80×80 px clickable area while its icon texture is 72×72 px.

## Sheet header icons

Sheet header resource icons (gold in Upgrades/Partners/Settlement, prestige points in Prestige, gems in Shop) are displayed at **56×56 px** with `show_fallback_behind_texture = false`. The `ResourceValueLabel` uses compact number formatting.

## Number formatting

## ImageSlot fallback rule

`ImageSlot` (`scripts/ui/ImageSlot.gd`) renders a texture on top of a `ColorRect` fallback.

- **Texture exists → fallback must be hidden.** `show_fallback_behind_texture = false` (default) makes the `ColorRect` transparent so transparent PNGs do not show white squares behind them.
- **Texture missing → fallback color is shown.** White for icon slots, colored for state-communicating slots, transparent for decorative slots.
- Only set `show_fallback_behind_texture = true` when an asset intentionally needs a colored background behind a transparent texture. No current slots require this.

Run `godot --headless --script res://scripts/tools/ValidateImageSlotFallbacks.gd` to catch accidental `true` values.

---

All player-facing economy and power values (costs, damage, DPS, HP, gold, rewards, gems, prestige points) use `NumberFormatter.compact()` from `res://scripts/ui/NumberFormatter.gd`. Raw values are preserved in save data, balance calculations, and the playtest logger. Standard compact thresholds (K from 1 000, M from 1 000 000, etc.) — 304 400 displays as 304.4K. Value labels use compact number formatting to prevent overflow:

| Raw value | Displayed |
|-----------|-----------|
| 999 | 999 |
| 1 000 | 1.0K |
| 1 500 | 1.5K |
| 1 000 000 | 1.0M |
| 1 250 000 | 1.3M |
| 1 000 000 000 | 1.0B |
| 1 000 000 000 000 | 1.0T |
