# AGENTS.md

Development rules for AI coding agents working on this repository.

## Project Context

Naruto Clicker is an early setup/prototype for a vertical idle/clicker game targeting Web / Yandex Games. The project should stay small, stable, and easy to validate.

## Tech Stack

- Use Godot 4.5.1.
- Use GDScript only.
- Do not add C#.
- Keep the project compatible with Web export.
- Keep renderer compatibility with Web export, currently GL Compatibility.

## Current Priorities

- Keep the main scene stable and Control-based.
- Preserve the 720x1280 portrait layout.
- Keep YandexBridge as a future integration point.
- Keep `Main.tscn` as the app/root scene.
- Keep `ClickerScreen` responsible for gameplay flow and UI updates.
- Keep prototype state and formulas in `scripts/game/ClickerState.gd`.
- Keep `StatsPanel`, `GameField`, and `UpgradePanel` as focused UI components.
- Keep `UpgradePanel` responsible only for upgrade controls.
- Use `BottomBar` to open `UpgradeSheet`; do not keep upgrade controls permanently in the main gameplay flow.
- Keep `UpgradeSheet` to the bottom half of the screen so visible `GameField` space remains clickable while it is open.
- Keep `GameField` as the fullscreen bottom clickable layer in `ClickerScreen`.
- Keep visible UI overlays clickable above `GameField`, and make passive text/containers ignore mouse input.
- Keep `GameField` responsible only for tap/click input and simple visual feedback.
- Keep `AbilityBar` separate from `GameField` on the left-middle screen edge.
- Abilities must be purchased in `UpgradeSheet` before activation.
- Autoclick lasts 30 seconds and performs one attack every 0.05 seconds.
- Gold Bonus lasts 30 seconds and doubles rewards while active.
- Make sure ability buttons do not trigger attacks.
- Partners provide passive DPS through `ClickerState` state and `ClickerScreen` ticking.
- Partner DPS tiers are 10, 30, and 50.
- Partner initial costs are 10, 50, and 150 gold.
- Partner costs scale as `10 + count * 10`, `50 + count * 30`, and `150 + count * 50`.
- Partner 2 requires at least one Partner 1; Partner 3 requires at least one Partner 2.
- Partner damage ticks every 0.1 seconds for `total_dps / 10` damage.
- Keep `PartnerSheet` as a separate bottom-half overlay from `UpgradeSheet`.
- Character level replaces the old damage upgrade; character level must equal click damage.
- Character level upgrade cost is `5 + (character_level - 1) * 3`.
- Autoclick purchase costs 50 gold.
- Gold Bonus purchase costs 150 gold.
- Treat economy formulas as prototype balance values.
- Autoclick unlocks at character level 15.
- Gold Bonus unlocks at character level 30 and doubles rewards while active.
- Keep UI animation details out of `ClickerState`.
- Let `ClickerScreen` coordinate state results into UI feedback calls.
- Keep the main attack input on the `GameField` tap/click area, not a separate Attack button.
- Keep level progression simple: 10 enemies defeated per level, then advance the level.
- Keep every 5th level as a boss level with exactly one boss.
- Boss levels must use a 30 second timer and return to the previous level on failure.
- Do not add elite enemies.
- Scale enemy HP and gold reward by level with deterministic formulas.
- Zone data lives in `ZONE_DATA` const in `ClickerState.gd`; do not move it to separate files yet.
- Zones group levels 1–10, 11–20, 21–30, 31–40. Level 41+ stays in Zone 4.
- Zone HP multipliers: 1.0, 1.4, 1.9, 2.5. Zone reward multipliers: 1.0, 1.3, 1.7, 2.2.
- Apply zone multipliers after the base HP/reward formula, before the boss ×5 multiplier.
- Enemy and boss names come from the active zone; do not hard-code "Enemy" or "Boss" strings.
- Zone transition is detected in `attack_with_damage()` and included in the result dict as `zone_changed` and `zone_name`.
- Status text priority on level-up: zone change > boss defeated > normal level up.
- No background images or audio assets should be added for zones.
- Prefer small, safe, isolated patches.
- Preserve existing project settings unless the task requires a specific change.

## Coding Rules

- Use GDScript only.
- Keep scripts simple and focused.
- Avoid large architectural rewrites.
- Do not add external plugins.
- Do not add external assets unless explicitly requested.
- Do not introduce gameplay systems beyond the requested task.
- Do not extract gameplay state into broader services until the prototype loop becomes larger or explicitly requested.
- Keep patches easy to review.

## Scene/UI Rules

- Use Control-based UI for the main scene and other screen layouts.
- Keep the game vertical and Web-export friendly.
- Prefer containers and anchors over Node2D positioning for UI.
- Test layout directly in `ClickerScreen.tscn` preview and by running `Main.tscn`.
- `ClickerScreen/MainContent` must use top/full anchors with a bottom offset above `BottomBar`.
- Do not use bottom-wide anchors for `ClickerScreen/MainContent`.
- Keep upgrade buttons and future UI controls separate from `GameField` so they do not accidentally trigger attacks.
- Preserve the main scene UID unless unavoidable.
- Keep prototype UI simple until specific gameplay/UI work is requested.

## Yandex Games / Web Export Rules

- Keep YandexBridge registered as an Autoload unless a task explicitly changes that integration.
- Preserve existing YandexBridge public methods:
  - `game_ready()`
  - `gameplay_start()`
  - `gameplay_stop()`
- Do not add ads, payments, saves, cloud features, or authentication until explicitly requested.
- Make sure editor and desktop preview runs do not crash when Web-only APIs are unavailable.

## What Not To Add Yet

- Save system
- Monetization
- Ads
- Payments
- Cloud saves
- Player authentication
- Complex gameplay systems
- External assets
- External plugins
- Copyrighted images, audio, fonts, or other third-party assets

## Validation Checklist

After each patch, validate manually in Godot:

- Project opens without scene/script inheritance errors.
- `scenes/main/Main.tscn` opens in the editor.
- Main root node is `Control`.
- `scenes/main/Main.gd` is attached to the Main root node.
- `Main.tscn` contains the `ClickerScreen` instance.
- `ClickerScreen` is visible and owns the clicker UI flow.
- `ClickerState` preserves the current HP, reward, and upgrade formulas.
- Clicker UI is visible.
- `GameField` covers the whole screen as the bottom clickable layer.
- Empty screen space clicks attack.
- UI text and buttons remain visible above `GameField`.
- `UpgradesButton` does not attack.
- There is no separate Attack button.
- Clicking/tapping `GameField` reduces enemy HP.
- Clicking upgrade buttons does not attack the enemy.
- `UpgradesButton` opens `UpgradeSheet`.
- `PartnersButton` opens `PartnerSheet`.
- `UpgradeSheet` is hidden by default and can be closed.
- `PartnerSheet` is hidden by default and can be closed.
- Character level upgrade works from inside `UpgradeSheet`.
- Character level starts at 1 and damage starts at 1.
- Character level upgrade starts at 5 gold.
- Buying character level upgrade subtracts the current cost and increases character level and damage by 1.
- Character level cost increases after purchase.
- Old damage upgrade naming is not visible in UI.
- Autoclick button is visible but locked before character level 15.
- Gold Bonus button is visible but locked before character level 30.
- Autoclick unlocks at character level 15.
- Gold Bonus unlocks at character level 30.
- Ability button clicks do not attack the enemy.
- Autoclick active performs automatic damage every second.
- Gold Bonus active doubles enemy rewards.
- BottomBar has `Upgrades` and `Partners` buttons on one row.
- Partner 1 starts at 10 gold.
- Partner 2 starts at 50 gold.
- Partner 3 starts at 150 gold.
- Partner 2 cannot be bought before at least one Partner 1.
- Partner 3 cannot be bought before at least one Partner 2.
- Partner costs increase after purchase.
- Partner counts update after purchase.
- Total Partner DPS updates correctly.
- Partner DPS damages enemy every 0.1 seconds.
- One Partner 1 deals 1 damage per 0.1 seconds.
- Partner 1 plus Partner 2 deals 4 damage per 0.1 seconds.
- Partner kills give gold.
- Gold Bonus doubles partner kill rewards.
- Partners can damage and defeat bosses.
- Visible `GameField` area still attacks while `UpgradeSheet` is open.
- Clicking inside `UpgradeSheet` does not attack the enemy.
- `AbilityBar` is a left-middle screen overlay.
- Ability buttons do not pulse with `GameField` feedback.
- Ability buttons do not attack the enemy.
- Autoclick cannot activate before purchase.
- Gold Bonus cannot activate before purchase.
- Autoclick can be purchased for 50 gold at character level 15.
- Gold Bonus can be purchased for 150 gold at character level 30.
- Purchased abilities can be activated from `AbilityBar`.
- Autoclick lasts 30 seconds.
- Gold Bonus lasts 30 seconds.
- Autoclick performs separate attacks every 0.05 seconds.
- Target defeat gives gold.
- Defeating 10 enemies advances to the next level.
- Level text updates correctly.
- Enemies defeated counter updates correctly.
- Enemy HP and reward increase after level up.
- Levels 5, 10, 15, etc. are boss levels.
- Boss levels have one boss with higher HP and reward.
- Boss timer starts at 30 seconds and decreases.
- Defeating a boss before timeout advances to the next level.
- Boss timeout returns the player to the previous level.
- Normal levels work again after boss timeout.
- Upgrade cannot be bought without enough gold.
- Scene can be run from Godot.
- No error appears because `Main.gd` extends `Control`.
- YandexBridge calls do not crash in non-Web/editor runs.
- `project.godot` still points to the main scene.
- Project remains configured for 720x1280 portrait layout.
- Renderer remains GL Compatibility.
- No missing scene/script errors.
- No external plugins/assets were added.
- Level 1 starts in Training Grounds with enemy "Rogue Ninja".
- Level 5 boss is named "Training Master".
- Reaching level 11 transitions to Forest Path; status shows "New zone: Forest Path".
- Level 11 enemy is "Forest Bandit"; level 15 boss is "Forest Guardian".
- GameField zone name label updates on zone change.
- StatsPanel zone row shows zone name and level range.
- HP and reward values are higher in later zones than the base formula alone.
- Zone defeat feedback shows "New Zone!" flash when zone changes.

## Documentation Update Rules

Update this file when adding important systems, scenes, architecture decisions, workflow rules, or validation requirements. Keep README.md aligned with major project setup or workflow changes.
