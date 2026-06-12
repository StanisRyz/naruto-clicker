# Project Final Audit — 2026-06-12

## Scope
This audit covers code (static analysis), scenes, configs, and assets. Localization completeness in game_text.csv was intentionally skipped per audit scope. Validator scripts could not be executed because the Godot executable is in a Cyrillic-character path that the sandbox shell cannot invoke; all validator results are marked SKIPPED with a note.

---

## Summary
- **Ready for balance:** PARTIAL
- **Blockers:** 3 findings
- **High priority:** 4 findings
- **Medium priority:** 5 findings
- **Low priority:** 3 findings

---

## Validation Commands
| Command | Result | Notes |
|---------|--------|-------|
| ValidateTaskConfig | SKIPPED | Godot CLI unavailable (Cyrillic path). Script exists. |
| ValidateTaskAssets | SKIPPED | Godot CLI unavailable. Script exists. |
| ValidatePartnerConfig | SKIPPED | Godot CLI unavailable. Script exists. |
| ValidateEnemyAssets | SKIPPED | Godot CLI unavailable. Script exists. |
| ValidateSheetAssets | SKIPPED | Godot CLI unavailable. Script exists. |
| ValidateStageNavigationAssets | SKIPPED | Godot CLI unavailable. Script exists. |
| ValidateAbilityAssets | SKIPPED | Godot CLI unavailable. Script exists. |
| ValidateTopInterfaceAssets | SKIPPED | Godot CLI unavailable. Script exists. |
| ValidateBottomBarAssets | SKIPPED | Godot CLI unavailable. Script exists. |
| ValidateCardAssets | SKIPPED | Godot CLI unavailable. Script exists. |
| ValidateImageSlotFallbacks | SKIPPED | Godot CLI unavailable. Script exists. |
| ValidateNumberFormatter | SKIPPED | Godot CLI unavailable. Script exists. |
| ValidateSettlementBalance | SKIPPED | Godot CLI unavailable. Script exists. |

**Action required:** Move or copy `Godot_v4.5.1-stable_win64.exe` to a path without non-ASCII characters (e.g., `C:\Godot\Godot_v4.5.1-stable_win64.exe`) and re-run all validators before balance work. Validators cover all major config, asset, and balance checks; their output is essential for confirming readiness.

---

## Findings

### F-001
- **Severity:** BLOCKER
- **Area:** Build configuration / release readiness
- **File(s):** `scripts/game/BuildConfig.gd:8`
- **Description:** `IS_DEBUG_BUILD` is hardcoded to `true`. This flag gates the `BalancePlaytestLogger` instantiation, exposes a dev panel in SettingsWindow (`-dev` suffix on version), and enables debug purchase override (all items cost 1 gold when `debug_visual_test_mode_enabled` is also true). It is intentional for development but **must be set to `false` before any public export**.
- **Why it matters:** Shipping with `IS_DEBUG_BUILD = true` leaks dev tools and version suffix to players. The balance logger also adds allocations every frame in debug sessions.
- **Recommended fix:** Set `IS_DEBUG_BUILD = false` before export. Add a pre-export checklist item. Optionally replace with `OS.is_debug_build()` and a CI-level constant.
- **Safe to do before balance?** No — leave as `true` during balance testing; flip to `false` only at export time.

### F-002
- **Severity:** BLOCKER
- **Area:** Shop — consumable products missing from ShopConfig
- **File(s):** `scripts/game/config/ShopConfig.gd`, `scripts/game/runtime/ShopRuntime.gd`
- **Description:** `boss_retry_token` and `task_boost` (task_reward_boost) are fully wired in ClickerState (fields `boss_retry_tokens`, `task_reward_boost_multiplier`), saved/loaded by `ClickerStateSaveAdapter`, consumed by `TaskRuntime.claim_task_reward`, handled by `ClickerState.fail_boss_level`, have localization keys in LocalizationData, and have icon keys registered in `GameAssetCatalog` — but **they are absent from `ShopConfig.SHOP_PRODUCTS`**. This means players can never buy them. Their icon paths (`shop/boss_retry.png`, `shop/task_boost.png`) also have no corresponding files in `assets/images/shop/`.
- **Why it matters:** Two designed consumable products are completely unreachable in-game. The boss retry mechanic and task boost multiplier are dead features for players.
- **Recommended fix:** Add `boss_retry_token` and `task_boost` entries to `ShopConfig.SHOP_PRODUCTS` with appropriate `cost_gems`, `reward_type`, and `reward_scale` values. Add `ShopRuntime.buy_shop_products` handling for `reward_type: "boss_retry"` and `reward_type: "task_boost"`. Provide the two missing shop icon images.
- **Safe to do before balance?** Yes — these are additive changes that don't disrupt existing economy.

### F-003
- **Severity:** BLOCKER
- **Area:** Asset — partner skill icons and hero skill icons entirely absent
- **File(s):** `assets/images/partners/Skills/` (empty — only `.gitkeep`), `assets/images/hero_skills/` (empty — only `.gitkeep`)
- **Description:** `GameAssetCatalog` generates paths like `assets/images/partners/Skills/skill1.png` through `skill5.png` for partner skills, and `assets/images/hero_skills/skill_01.png` through `skill_05.png` for hero skills. None of these files exist. All partner skill cards and hero skill cards will display with no icon (fallback color only).
- **Why it matters:** Every skill card in the Upgrades and Partners sheets shows a blank icon. This is visually broken for the entire skill upgrade UI across all 28 partners and 5 hero skill slots.
- **Recommended fix:** Create and place `skill1.png` through `skill5.png` in `assets/images/partners/Skills/`, and `skill_01.png` through `skill_05.png` in `assets/images/hero_skills/`. Confirm image dimensions match the card slot size.
- **Safe to do before balance?** Yes — pure asset addition, no logic changes.

### F-004
- **Severity:** HIGH
- **Area:** Balance config — partner DPS values for partners 14–28 are placeholder
- **File(s):** `scripts/game/BalanceConfig.gd:52`, `scripts/game/BalanceConfig.gd:60`
- **Description:** `PARTNER_DPS_VALUES` and `PARTNER_BASE_COSTS` contain explicit comments: *"Temporary placeholder values for partners 14–28. Final balance pass will be done later."* Partners 14–28 (indices 13–27) use geometrically extrapolated values, not carefully tuned ones.
- **Why it matters:** Any balance work on mid-to-late game economy is based on untuned partner values. DPS curves, prestige timing, and settlement payoff ratios will need re-tuning after these are finalized.
- **Recommended fix:** Complete the balance pass on partners 14–28 before declaring the project balance-ready. Use `ProgressionSimulator.gd` to validate time-to-reach milestones.
- **Safe to do before balance?** No — this is the primary balance work itself; must be done as part of the balance pass.

### F-005
- **Severity:** HIGH
- **Area:** Asset — stage navigation thumbnails missing for most zones
- **File(s):** `assets/images/stage_navigation/`
- **Description:** `StageNavigationAssetCatalog` expects `stage.png` in zone folders for zones 1–21. Only zones 01, 02, 03, 04, 05, 08, 10, 11, 16, 17, 20 have images (11 of 21). Missing: zones 06, 07, 09, 12, 13, 14, 15, 18, 19, 21. The catalog returns `null` for missing textures — the stage navigator will show no thumbnail for those zones.
- **Why it matters:** The stage navigator UI displays blank thumbnails for ~10 zones. This is a visible gap to players who explore those stages.
- **Recommended fix:** Add `stage.png` for all missing zone folders. Zones that share a background zone (e.g. zones 6, 7 share background with zone 5) can reuse the same source art.
- **Safe to do before balance?** Yes — pure asset addition.

### F-006
- **Severity:** HIGH
- **Area:** Asset — normal enemy and elite sprites absent for zone_08 (pool zone for levels 36–50) and zone_17 pools
- **File(s):** `assets/images/enemies/zone_08/`, `assets/images/enemies/zone_17/`
- **Description:** The `EnemyPoolConfig` uses pool zones 1, 11, and 17 for normal/elite enemy sprites. Zone_01 and zone_11 have full enemy and elite sprite sets (enemy_01–enemy_15, elite_01–elite_04/05). Zone_17 has enemy_01–enemy_09 and elite_01–03 but **zone_08** only has `boss_01` sprites — no `enemy_01`–`enemy_15` or `elite_01`–`elite_04`. The `EARLY_POOL_ZONE = 1` uses zone_01 for levels 1–50 (by pool logic), but `ZoneConfig` entries for levels 36–50 specify `enemy_asset_zone: 8` for zones "Mist River" and "Flooded Shrine", which would attempt to load from zone_08.
- **Why it matters:** Normal and elite enemies at levels 36–50 will render with no texture (null fallback). The default enemy fallback in `GameAssetCatalog` is `enemy.default.*` which uses `assets/images/enemies/default_*.png` — those files are also absent (only `.gitkeep` in the enemies root folder).
- **Recommended fix:** Add normal/elite enemy sprites to `zone_08`, or verify that the pool zone routing always serves zone_01 sprites for those levels and fix `ZoneConfig.enemy_asset_zone` accordingly. Also add default fallback enemy images.
- **Safe to do before balance?** Yes — art/config fix.

### F-007
- **Severity:** HIGH
- **Area:** Asset — background images absent for 10 of 21 zones
- **File(s):** `assets/images/backgrounds/`
- **Description:** Background images exist for zones 01, 02 (recently added), 03, 04, 05, 08, 10, 11, 16, 17, 20. Missing: zones 06, 07, 09, 12, 13, 14, 15, 18, 19, 21. `BackgroundAssetCatalog.load_zone_background` falls back to `GameAssetCatalog.load_texture("game.field_background")` which expects `assets/images/game/field_background.png` — that file is absent (only `.gitkeep` in `assets/images/game/`).
- **Why it matters:** Double fallback failure: missing zone backgrounds AND missing the generic background fallback. Levels in those zones will show a blank (default Color) background.
- **Recommended fix:** Add backgrounds for missing zones (can share art per zone group). Also add a `field_background.png` placeholder to `assets/images/game/` as ultimate fallback.
- **Safe to do before balance?** Yes — pure asset addition.

### F-008
- **Severity:** MEDIUM
- **Area:** Code — `_handle_status_text` is a no-op stub
- **File(s):** `scenes/game/ClickerScreen.gd:892`
- **Description:** `_handle_status_text(_text: String) -> void: pass` is called in over a dozen places after purchases, attacks, and task events. No UI element currently displays the status text to the player.
- **Why it matters:** Player feedback for purchases ("Not enough gold", "Level up!", "Boss failed!", etc.) is silently discarded. The game is playable but lacks all transient feedback text that the design intends.
- **Recommended fix:** Implement a status label or floating text display and route status_text through it. At minimum, connect a visible Label to `_handle_status_text`.
- **Safe to do before balance?** Yes — the status text is informational and does not affect economy metrics, but it does affect playtest experience.

### F-009
- **Severity:** MEDIUM
- **Area:** Asset — default enemy images absent
- **File(s):** `assets/images/enemies/default_healthy.png`, `default_hit.png`, `default_wounded.png`, `default_defeated.png` (registered in GameAssetCatalog but not present)
- **Description:** `GameAssetCatalog` registers four default enemy fallback keys (`enemy.default.*`) pointing to `assets/images/enemies/default_*.png`, but only `.gitkeep` exists in the enemies root folder. These serve as the last-resort fallback when a zone-specific texture is missing.
- **Why it matters:** When a zone-specific enemy sprite is missing, the fallback chain reaches null. The enemy image slot will show its fallback color. Layered on top of F-006 and F-007 issues.
- **Recommended fix:** Place four generic enemy placeholder images at `assets/images/enemies/default_healthy.png`, etc.
- **Safe to do before balance?** Yes.

### F-010
- **Severity:** MEDIUM
- **Area:** Code — ZoneConfig `enemies`/`elite_enemy` legacy fields still present
- **File(s):** `scripts/game/config/ZoneConfig.gd:7`
- **Description:** The comment at line 7 states: *"enemies and elite_enemy are legacy display/content notes. Non-boss enemy runtime selection now uses EnemyPoolConfig; these fields are no longer used for enemy spawning."* All 21 zone entries still carry `enemies` and `elite_enemy` arrays.
- **Why it matters:** Stale data increases config maintenance burden. If someone modifies ZoneConfig expecting these arrays to affect spawning, it will have no effect. This is a low-risk but misleading situation.
- **Recommended fix:** Remove `enemies` and `elite_enemy` keys from all `ZONE_DATA` entries. Update the comment block accordingly.
- **Safe to do before balance?** Yes — the fields are read-never; removal is safe.

### F-011
- **Severity:** MEDIUM
- **Area:** Code — PartnerConfig partner names 1 and 2 are placeholder strings
- **File(s):** `scripts/game/config/PartnerConfig.gd:5-6`
- **Description:** The first two entries in `PARTNER_NAMES` are literally `"Partner 1"` and `"Partner 2"`. Partners 3+ have real Naruto-themed names.
- **Why it matters:** These names appear in purchase result messages (`"%s hired x%d!"`) and potentially in partner card headers. Players will see generic placeholder text for the first two partners.
- **Recommended fix:** Assign proper Naruto-themed names to partners at index 0 and 1.
- **Safe to do before balance?** Yes — name-only change, no gameplay effect.

### F-012
- **Severity:** MEDIUM
- **Area:** Code — shop `ShopRuntime` handles `boss_retry_token` and `task_boost` reward types with no logic
- **File(s):** `scripts/game/runtime/ShopRuntime.gd:95-102`
- **Description:** The `match reward_type` in `buy_shop_products` handles `"gold"` explicitly but falls through to `result["status_text"] = "Unknown shop reward"` for any other `reward_type`. When/if `boss_retry_token` and `task_boost` are added to ShopConfig (fixing F-002), they also need `reward_type` handling here (incrementing `state.boss_retry_tokens` and setting `state.task_reward_boost_multiplier`).
- **Why it matters:** Related to F-002. Even after adding shop entries, the runtime buy logic would produce "Unknown shop reward" and not actually grant the items.
- **Recommended fix:** Add `"boss_retry"` and `"task_boost"` cases to the match block in `ShopRuntime.buy_shop_products`. This is part of the same fix as F-002.
- **Safe to do before balance?** Yes.

### F-013
- **Severity:** LOW
- **Area:** Code — `BalancePlaytestLogger` runs unconditionally in debug builds even without user request
- **File(s):** `scenes/game/ClickerScreen.gd:127-131`
- **Description:** The logger is instantiated and `start_session` called in `_ready()` whenever `BuildConfig.IS_DEBUG_BUILD` is true. There is no opt-in mechanism. This is low risk but creates overhead on every game startup during development.
- **Why it matters:** Minor: extra object allocation and persistent data collection during all debug sessions, not just intentional playtest runs.
- **Recommended fix:** Add a `BuildConfig.ENABLE_BALANCE_LOGGER: bool = false` constant (separate from `IS_DEBUG_BUILD`) to allow controlled opt-in during playtest sessions.
- **Safe to do before balance?** Yes — quality of life improvement only.

### F-014
- **Severity:** LOW
- **Area:** Asset — `ui.stage_unlocked` and `ui.stage_locked` and `ui.stage_current` icons registered but potentially unused
- **File(s):** `scripts/ui/GameAssetCatalog.gd:37-39`
- **Description:** `GameAssetCatalog` defines keys `stage.unlocked`, `stage.locked`, and `stage.current` pointing to `assets/images/ui/stage_unlocked.png`, `stage_locked.png`, `stage_current.png`. These files are not present (only `.gitkeep` in the ui folder at root level). The `StageNavigationAssetCatalog` uses a separate path scheme under `stage_navigation/`. Whether the old keys are still referenced in any .tscn or .gd file needs manual confirmation.
- **Why it matters:** If these keys are still used by any UI node, they will silently return null textures. If they are truly orphaned, they are dead catalog entries.
- **Recommended fix:** Grep all .tscn and .gd files for `stage.unlocked`, `stage.locked`, `stage.current` usage. Remove dead entries from GameAssetCatalog or add missing image files if still used.
- **Safe to do before balance?** Yes.

### F-015
- **Severity:** LOW
- **Area:** Docs/comments — BalanceConfig partner placeholder comment
- **File(s):** `scripts/game/BalanceConfig.gd:52`, `scripts/game/BalanceConfig.gd:60`
- **Description:** Comments say "Final balance pass will be done later." These are accurate but will become stale after the balance pass is done. This is tracked above as F-004 (HIGH) for the actual balance work; this LOW item is just the comment cleanup.
- **Why it matters:** After the balance pass, the comments should be removed to avoid future confusion.
- **Recommended fix:** Remove the placeholder comments once F-004 is resolved.
- **Safe to do before balance?** No — remove only after the balance pass is complete.

---

## Asset Audit

### Missing Required Assets
- `assets/images/enemies/default_healthy.png`, `default_hit.png`, `default_wounded.png`, `default_defeated.png` — last-resort enemy fallback, registered in GameAssetCatalog, absent
- `assets/images/game/field_background.png` — fallback background, registered in GameAssetCatalog, absent
- `assets/images/partners/Skills/skill1.png` through `skill5.png` — partner skill icons, entire folder empty
- `assets/images/hero_skills/skill_01.png` through `skill_05.png` — hero skill icons, entire folder empty
- `assets/images/shop/boss_retry.png` — registered in GameAssetCatalog, absent (product also absent from ShopConfig)
- `assets/images/shop/task_boost.png` — registered in GameAssetCatalog, absent (product also absent from ShopConfig)
- `assets/images/enemies/zone_08/enemy_01/` through `enemy_15/` and `elite_01/` through `elite_04/` — normal and elite enemy sprites for the mist/water zone pool (used by levels 36–50 zone enemy_asset_zone references)

### Missing Optional Assets (degrade gracefully but break visual completeness)
- Stage navigation thumbnails for zones 06, 07, 09, 12, 13, 14, 15, 18, 19, 21 (`assets/images/stage_navigation/zone_XX/stage.png`)
- Background images for zones 06, 07, 09, 12, 13, 14, 15, 18, 19, 21 (`assets/images/backgrounds/zone_XX/background.png`)
- `assets/images/ui/stage_unlocked.png`, `stage_locked.png`, `stage_current.png` — registered in GameAssetCatalog; may be in-use or orphaned (needs manual check)
- `assets/images/settlement/` subfolders (training_camp, market, etc.) all empty — if settlement building detail images are used anywhere, they are missing

### Orphan / Possibly Unused Assets
- `assets/images/shop/gold_pack_small/` (subfolder, `.gitkeep` only) — separate from the flat `gold_pack_small.png` that does exist
- `assets/images/shop/instant_combo/`, `task_reward_boost/`, `gems/` subfolders — `.gitkeep` only, contents never created; `instant_combo` product does not appear in ShopConfig
- `assets/images/partner_skills/` (root-level, `.gitkeep` only) — may be a leftover from an old asset path scheme before `partners/Skills/` was adopted

### Size/Path Mismatches
- No explicit size mismatches found via static analysis. Image dimensions could not be verified without running the game; the validator scripts should catch these.

---

## Mechanic Audit

### Complete Systems
- **Hero damage + leveling** — fully implemented in ClickerState with segmented exponential cost scaling, milestone multipliers, hero skill bonuses
- **Partner DPS** — fully implemented for all 28 partners with own-skill bonuses, milestone multipliers, command aura, settlement, shop, rally, boss multipliers
- **Abilities (autoclick, gold_bonus, focus_burst, rally)** — full lifecycle: unlock, purchase, activate, cooldown, duration, rank upgrade, settlement duration/cooldown modifiers
- **Settlement buildings** — 6 buildings, each with distinct effect, purchase/bulk buy, diminishing returns for cooldown reduction, milestone bonuses
- **Prestige system** — prestige calculation, talent purchase (6 talents), reset, points accumulation tracked across prestiges
- **Task system** — 9 task definitions, 5 active at once, rotation on claim, reward scaling with current level, task_reward_boost multiplier consumed on claim
- **Stage navigation** — zone transitions, boss level detection, auto-advance, boss fail/retry, level travel
- **Save/load** — full ClickerState serialization via SaveAdapter, autosave every 10s, atomic write via temp file
- **Shop (gold packs and permanent upgrades)** — 5 products implemented end-to-end
- **Enemy spawning** — EnemyPoolConfig 3-tier pool system, random normal/elite selection, boss per zone
- **Localization** — LocalizationManager autoload, language saved in state, all key UI panels wired to tr_key

### Incomplete Systems
- **Shop consumables (boss_retry_token, task_boost)** — state fields exist, runtime logic exists, but products are not in ShopConfig and not purchasable (F-002)
- **Partner skill icons and hero skill icons** — functional in code but all visually broken due to missing assets (F-003)
- **Balance tuning for partners 14–28** — placeholder values; this is the primary pending balance work (F-004)

### Obsolete/Unused Systems
- `ZoneConfig.ZONE_DATA` `enemies` and `elite_enemy` arrays — documented as legacy, no longer used for spawning (F-010)
- `GameAssetCatalog` keys `stage.unlocked`, `stage.locked`, `stage.current` — possibly orphaned after StageNavigationAssetCatalog was introduced (F-014)
- `assets/images/partner_skills/` root folder — likely leftover from old asset path; replaced by `partners/Skills/`

### Suspicious (needs manual confirmation)
- `ShopRuntime.buy_shop_products` `reward_type` fallthrough to "Unknown shop reward" — safe now (only gold packs and permanent upgrades are in ShopConfig), but will silently fail when boss_retry_token and task_boost are added if F-012 is not fixed simultaneously
- `ProgressionSimulator.gd` exists (playtest/balance tool) but it is unclear if it's wired to any scene or run standalone — confirm it still runs correctly against current BalanceConfig
- `BalancePlaytestLogger` CSV export path — verify the export target (`user://`) is accessible on all target platforms (Yandex Web Games)

---

## Scene/Node Audit

### ClickerScreen.tscn / ClickerScreen.gd
All `@onready` node paths checked against the scene file. All referenced nodes are present in the scene:
- `$TopInterfaceImageHolder`, `$CombatEffectsLayer`, `$PrimaryStatsPanel` — present
- `$MainContent/VBoxContainer/StageNavigator`, `$MainContent/VBoxContainer/ProgressInfoPanel` — present
- `$TasksButton`, `$TasksButton/ImageHolder`, `$TasksWindow`, `$SettingsWindow` — present
- `$GameField`, `$AbilityBar` — present
- `$BottomBar/MarginContainer/HBoxContainer/UpgradesButton` through `ShopButton` — present in scene
- All sheets and `$PrestigeSheet/PrestigeConfirmDialog` — present
- All signal connections reference methods that exist in ClickerScreen.gd

**One issue:** `_handle_status_text` (line 892) is a declared method that receives status strings from 15+ call sites but does nothing (`pass`). This is a stub, not a missing node. See F-008.

### Other Scenes
No scene-level node path issues identified from static review. All sub-scenes (UpgradeSheet, PartnerSheet, etc.) are instanced from valid .tscn files that exist on disk.

---

## Balance Readiness

**PARTIAL** — The project is structurally sound enough to begin balance work on the early game (levels 1–65, partners 1–13, all abilities, all buildings, prestige system). All economy formulas are implemented and functional.

**Must be fixed before balance work is meaningful:**
1. F-004 (HIGH) — Partners 14–28 have placeholder DPS/cost values. Any balance simulation covering levels 66+ or late-game prestige loops is based on temporary numbers and will need to be redone. Run `ProgressionSimulator.gd` profiles after finalizing these values.

**Should be fixed before playtesting:**
1. F-002 + F-012 (BLOCKER + MEDIUM) — Boss retry tokens and task reward boosts are unreachable. Two shop products designed to affect progression pacing are non-functional. This affects mid-game pacing metrics.
2. F-008 (MEDIUM) — Status text feedback is silently discarded. Playtests will lack all transient game feedback, making it harder to observe economy feel.

**Do not affect balance metrics (can wait):**
- F-003, F-005, F-006, F-007, F-009 — Missing art assets. Economy numbers are unaffected; these are visual gaps only.
- F-010, F-011 — Config cleanup and name placeholders.
- F-001, F-013 — Debug/release flags. Leave IS_DEBUG_BUILD = true during balance testing.

**Balance systems present and ready to tune:**
- Hero click damage curve (HERO_BASE_DAMAGE, HERO_DAMAGE_PER_LEVEL, HERO_COST_GROWTH_*)
- Enemy HP and reward curves (ENEMY_HP_BASE, ENEMY_HP_GROWTH, ENEMY_REWARD_BASE, ENEMY_REWARD_GROWTH)
- Partner DPS values (partners 1–13 are considered final; 14–28 are placeholder)
- Building base costs and growth (BUILDING_BASE_COST = 500, BUILDING_COST_GROWTH = 1.22)
- Prestige gate (PRESTIGE_REQUIRED_LEVEL = configurable), talent costs and bonuses
- Ability unlock levels, costs, cooldowns, durations, rank multipliers
- Boss timer (BOSS_TIME_LIMIT)
- Shop gold ETV (SHOP_SMALL_GOLD_ETV_SECONDS, SHOP_LARGE_GOLD_ETV_SECONDS)
- Milestone thresholds and multipliers

**Tooling:** `ProgressionSimulator.gd` exists with F2P_CASUAL, AD_WATCHER, LIGHT_SPENDER profiles and can simulate minutes or until a target level. `BalancePlaytestLogger.gd` collects per-level gold flow, TTK samples, and purchase events. Both tools are present and usable.

---

## Manual Checks After Fixes

- [ ] Move Godot executable to ASCII path and run all 13 validators; confirm all PASS
- [ ] Add boss_retry_token and task_boost to ShopConfig + ShopRuntime; verify purchase in-game grants the item
- [ ] Add partner skill images and hero skill images; confirm card icons render in Upgrades sheet
- [ ] Confirm `ProgressionSimulator.gd` still runs and produces realistic level-up times with current BalanceConfig
- [ ] Run `BalancePlaytestLogger` playtest session and export CSV; verify gold flow and boss TTK are within target ranges
- [ ] Add default enemy fallback images and test zone_08 enemy rendering
- [ ] Set IS_DEBUG_BUILD = false and verify no debug UI or logger leaks in an export build
- [ ] Confirm YandexBridge `game_ready()` is called after initial asset load (not blocking balance, but required for Yandex release)
- [ ] Verify `_handle_status_text` is implemented before user research or soft-launch

