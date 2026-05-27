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
- Main screen `StatsPanel` is intentionally compact and shows only gold, character level, click damage, partner DPS, level, zone name, and enemies progress.
- Prestige and settlement details belong in their tabs, not on the main screen.
- Main stat icon placeholders are temporary white `ColorRect` nodes.
- Keep `UpgradePanel` responsible only for upgrade controls.
- Use `BottomBar` to open `UpgradeSheet`, `PartnerSheet`, `SettlementSheet`, and `PrestigeSheet`; do not keep sheet controls permanently in the main gameplay flow.
- BottomBar must remain visible and clickable while any bottom sheet is open.
- Opening a BottomBar tab should switch directly to that sheet without requiring the current sheet to close first.
- Keep `UpgradeSheet` to the bottom half of the screen so visible `GameField` space remains clickable while it is open.
- Bottom sheets must not cover BottomBar; they should end above it.
- Bottom sheet headers and close buttons should remain fixed while content scrolls vertically.
- `BuyModeSelector` is the reusable UI for `x1`, `x10`, `x100`, and `Max` purchase modes.
- `BuyModeSelector` must stay fixed under the sheet header in `UpgradeSheet`, `PartnerSheet`, and `SettlementSheet`; purchase lists should scroll independently below it.
- In `UpgradeSheet`, `BuyModeSelector` affects only the Hero Level card; ability purchases must never use bulk-buy modes.
- Do not add `BuyModeSelector` to `PrestigeSheet`.
- Purchase tabs use card-style rows with a temporary white `ColorRect` image placeholder, two-line info text, and an action button.
- Keep `GameField` as the fullscreen bottom clickable layer in `ClickerScreen`.
- Keep visible UI overlays clickable above `GameField`, and make passive text/containers ignore mouse input.
- Keep `GameField` responsible only for tap/click input and simple visual feedback.
- Keep `AbilityBar` separate from `GameField` on the left-middle screen edge.
- Abilities must be purchased in `UpgradeSheet` before activation.
- Autoclick lasts 15 seconds, performs one attack every 0.05 seconds, then enters a 60 second cooldown.
- Gold Bonus lasts 45 seconds, doubles rewards while active, then enters a 300 second cooldown.
- Focus Burst unlocks at character level 60, costs 500 gold, lasts 20 seconds, doubles final click/autoclick damage, and enters a 120 second cooldown.
- Rally unlocks at character level 80, costs 1000 gold, lasts 30 seconds, doubles final partner DPS, and enters a 180 second cooldown.
- Make sure ability buttons do not trigger attacks.
- Partners provide passive DPS through `ClickerState` state and `ClickerScreen` ticking.
- Partner tiers are data-driven: Partner 1 (10 DPS), Partner 2 (30), Partner 3 (50), Field Scout (100), Spear Guard (175), Iron Defender (300), Battle Monk (500), Elite Samurai (850), Shadow Captain (1400), War Sage (2300), Beast Tamer (3800), Blade Master (6200), and Legendary Commander (10000).
- Partner initial costs are `[10, 50, 150, 400, 900, 1800, 3500, 7000, 14000, 28000, 56000, 110000, 220000]`.
- Partner costs scale by adding `[10, 30, 50, 100, 180, 300, 500, 900, 1600, 2800, 5000, 9000, 16000]` per owned partner.
- Each partner tier requires at least one of the previous tier.
- Partner damage ticks every 0.1 seconds for `total_dps / 10` damage.
- Partner purchases use horizontal bulk mode buttons `x1`, `x10`, `x100`, and `Max`; displayed costs must show total package cost.
- Partner `x10` and `x100` purchases are strict all-or-nothing packages; `Max` buys as many as current gold allows.
- PartnerPanel should always show the required package cost when prerequisites are met; "Not enough gold" belongs in StatusLabel after a failed purchase, not in partner button text.
- Keep `PartnerSheet`, `SettlementSheet`, and `PrestigeSheet` as separate bottom-half overlays from `UpgradeSheet`.
- Settlement tab sits between `Partners` and `Prestige` in the bottom bar.
- Settlement buildings are Training Camp (+1% final partner DPS per level), Market (+1% final gold gain per level), Knight Hut (+1% final click damage per level), War Banner (+1% Focus Burst/Rally duration per level), Clock Tower (-1% ability cooldown per level, capped at 50%), and Boss Shrine (+1% boss reward gold per level).
- Settlement rows use a temporary white `ColorRect` image placeholder, two text lines for name/count and per-purchase effect, and a buy button.
- Settlement building rows should not show total owned effect; total bonuses belong in stats or summary UI.
- Each settlement building requires at least one of the previous building.
- Settlement initial costs are `[25, 75, 150, 500, 1200, 3000]`.
- Settlement costs scale by adding `[25, 50, 100, 250, 600, 1500]` per owned building.
- Settlement purchases use bulk modes `x1`, `x10`, `x100`, and `Max` with the same strict all-or-nothing behavior as partners for `x10` and `x100`.
- Settlement buildings reset on prestige.
- Character level replaces the old damage upgrade; character level must equal click damage.
- Character level upgrade cost is `5 + (character_level - 1) * 3`.
- UpgradePanel contains a bulk-buy Hero Level card and one-time ability purchase cards.
- Character level upgrades use horizontal bulk mode buttons `x1`, `x10`, `x100`, and `Max`; displayed costs must show total package cost.
- Character level `x10` and `x100` purchases are strict all-or-nothing packages; `Max` buys as many as current gold allows.
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
- Prestige lives in a separate `PrestigeSheet` opened by the `PrestigeButton` bottom tab; do not keep prestige controls inside `UpgradeSheet`.
- PrestigePanel should stay compact; detailed prestige calculation belongs in the confirmation dialog, not the main PrestigePanel.
- PrestigePanel uses compact `available / total` points text, a card-style prestige action, and card-style talent rows.
- Prestige reward formula is `floor(current_level / 50) + floor(character_level / 100)` points.
- Prestige confirmation dialog (`PrestigeConfirmDialog`) is an overlay child of `PrestigeSheet` and must be fully opaque so underlying UI text is not visible through it.
- Signal flow: PrestigePanel `prestige_requested` -> PrestigeSheet `prestige_requested` -> ClickerScreen calls `show_prestige_confirm(state)`; dialog `confirmed` -> ClickerScreen calls `perform_prestige()`.
- `perform_prestige()` resets all normal progress except available prestige points, total earned prestige points, prestige talents, and `total_prestiges`.
- Prestige points are split into available points and total earned points; spending talents subtracts only from available points.
- Prestige talents are Focus Training (+5% click/autoclick damage per level), Trade Routes (+5% gold gain per level), Command Aura (+5% partner DPS per level), Quick Hands (+5% Autoclick attack rate per level, minimum interval 0.02 seconds), Builder Wisdom (+5% settlement bonus effectiveness per level), and Boss Hunter (+5% boss damage per level).
- Prestige talent next cost is `1 + current talent level`.
- Prestige reset does not reset prestige talents.
- Apply prestige damage multiplier in `_update_character_state()` so `click_damage` always reflects effective damage.
- Apply prestige damage multiplier in `get_partner_tick_damage()`.
- Apply prestige gold multiplier in `attack_with_damage()` before the Gold Bonus x2 multiplier.
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
- Character level starts at 1 and damage starts at 1.
- Old damage upgrade naming is not visible in UI.
- UpgradeSheet keeps `BuyModeSelector` fixed under the header while upgrade cards scroll.
- UpgradePanel uses a card-style Hero Level row and card-style ability purchase rows with white `ColorRect` image placeholders.
- Hero Level card shows the current character level and selected bulk upgrade cost.
- Autoclick button is visible but locked before character level 15.
- Gold Bonus button is visible but locked before character level 30.
- Focus Burst button is visible but locked before character level 60.
- Rally button is visible but locked before character level 80.
- Autoclick unlocks at character level 15.
- Gold Bonus unlocks at character level 30.
- Focus Burst unlocks at character level 60.
- Rally unlocks at character level 80.
- Ability button clicks do not attack the enemy.
- Autoclick active performs automatic damage every 0.05 seconds.
- Gold Bonus active doubles enemy rewards.
- BottomBar has `Upgrades`, `Partners`, `Settlement`, and `Prestige` buttons on one row.
- Partner 1 starts at 10 gold.
- PartnerPanel uses card-style partner rows with white `ColorRect` image placeholders.
- PartnerSheet keeps `BuyModeSelector` fixed under the header while partner rows scroll.
- Partner 2 starts at 50 gold.
- Partner 3 starts at 150 gold.
- Partner 2 cannot be bought before at least one Partner 1.
- Partner 3 cannot be bought before at least one Partner 2.
- All 13 partner tiers are visible through scrolling and each tier requires the previous tier.
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
- Visible `GameField` area still attacks while `PrestigeSheet` is open.
- Clicking inside `PrestigeSheet` does not attack the enemy.
- BottomBar remains visible and clickable while any sheet is open.
- Pressing a different BottomBar tab switches directly to that sheet.
- `AbilityBar` is a left-middle screen overlay.
- Ability buttons do not pulse with `GameField` feedback.
- Ability buttons do not attack the enemy.
- Autoclick cannot activate before purchase.
- Gold Bonus cannot activate before purchase.
- Autoclick can be purchased for 50 gold at character level 15.
- Gold Bonus can be purchased for 150 gold at character level 30.
- Focus Burst can be purchased for 500 gold at character level 60.
- Rally can be purchased for 1000 gold at character level 80.
- Purchased abilities can be activated from `AbilityBar`.
- Autoclick lasts 15 seconds.
- Autoclick enters a 60 second cooldown after ending.
- Gold Bonus lasts 45 seconds.
- Gold Bonus enters a 300 second cooldown after ending.
- Focus Burst doubles click/autoclick damage while active and enters a 120 second cooldown after ending.
- Rally doubles partner DPS while active and enters a 180 second cooldown after ending.
- Ability buttons show active, cooldown, and ready states.
- Abilities cannot activate while active or on cooldown.
- Autoclick performs separate attacks every 0.05 seconds.
- Upgrade x1 buys 1 character level.
- Upgrade x10 buys exactly 10 character levels or buys nothing if gold is insufficient.
- Upgrade x100 buys exactly 100 character levels or buys nothing if gold is insufficient.
- Upgrade Max buys as many character levels as current gold allows.
- Partner x10 and x100 modes buy the full package or buy nothing if gold is insufficient.
- Partner Max buys as many partners as current gold allows.
- Upgrade, Partner, and Settlement bulk mode UI uses horizontal buttons, not dropdowns.
- Settlement opens `SettlementSheet`.
- Training Camp can be bought when enough gold.
- Market requires at least one Training Camp.
- Knight Hut requires at least one Market.
- War Banner, Clock Tower, and Boss Shrine are visible through scrolling and follow the building chain requirement.
- Settlement x1, x10, x100, and Max modes work like partners.
- Settlement buttons always show required cost when prerequisites are met.
- Training Camp increases partner DPS/tick damage.
- Market increases gold rewards.
- Knight Hut increases manual click and autoclick damage.
- War Banner increases Focus Burst and Rally duration.
- Clock Tower reduces ability cooldowns up to the 50% cap.
- Boss Shrine increases boss reward gold.
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
- StatsPanel shows zone name without the zone level range.
- HP and reward values are higher in later zones than the base formula alone.
- Zone defeat feedback shows "New Zone!" flash when zone changes.
- Prestige button is not visible inside UpgradeSheet.
- `PrestigeButton` opens `PrestigeSheet`.
- PrestigeSheet is hidden by default and can be closed.
- PrestigeSheet has no `BuyModeSelector`.
- PrestigePanel shows compact `available / total` prestige points.
- Prestige action and talent rows use card-style rows with white `ColorRect` image placeholders.
- Prestige button is disabled when total points to gain is 0.
- Prestige button enables and shows the reward point count when total points to gain is greater than 0.
- Prestige reward at current_level 52 and character_level 102 is 2.
- Prestige reward at current_level 101 and character_level 301 is 5.
- Pressing Prestige opens a fully opaque PrestigeConfirmDialog inside PrestigeSheet.
- No closes the prestige dialog and does not reset progress.
- Confirming prestige resets normal progress; cancelling does nothing.
- Prestige resets settlement buildings and costs.
- Quick Hands affects Autoclick attack interval without going below 0.02 seconds.
- Builder Wisdom increases settlement percentage bonus effectiveness.
- Boss Hunter increases manual, autoclick, and partner damage against bosses.
- StatsPanel does not show available / total earned Prestige points or total runs; those belong in PrestigeSheet.
- After prestige, all timers (boss, autoclick, gold bonus, ability cooldowns, accumulators) are reset in ClickerScreen.

## Documentation Update Rules

Update this file when adding important systems, scenes, architecture decisions, workflow rules, or validation requirements. Keep README.md aligned with major project setup or workflow changes.
