# Naruto Clicker

Naruto Clicker is a vertical idle/clicker game prototype for Yandex Games.

## Status

Early setup/prototype. The project currently has a basic playable clicker loop and a YandexBridge autoload as a future integration point.

Save systems, heroes, loot/items, and monetization are intentionally not implemented yet.

## Project Details

- Engine: Godot 4.5.1
- Language: GDScript
- Target platform: Web / Yandex Games
- Orientation: vertical / portrait
- Viewport: 720x1280
- Renderer: GL Compatibility

## Local Development

Open the project in Godot 4.5.1 and run the main scene from the editor. Keep changes small and verify the scene still opens and runs after each patch.

Do not add external plugins or external assets without explicit approval.

## Current Gameplay Prototype

The main scene contains the first local clicker loop:

- Tap/click the main game field to damage the current enemy.
- `GameField` uses a muted green placeholder background and does not pulse or blink on click.
- `GameField` is primarily visual: muted green background, enemy placeholder states, boss timer, and defeat feedback.
- Enemy name and HP text are not displayed inside `GameField`.
- `EnemyImageHolder` is a centered placeholder square: healthy is white, hit is blue for 0.5 seconds, wounded is red, and defeated is black for 0.2 seconds.
- After enemy defeat, a 0.2 second transition lock keeps enemy HP at 0 and blocks manual, autoclick, and partner damage before reward, kill count, level changes, and the next enemy are applied.
- The main screen has no general `StatusLabel`.
- The main screen uses two independent panels: `PrimaryStatsPanel` for gold, character level, click damage, and partner DPS; `ProgressInfoPanel` for level, zone name, enemies progress, enemy name, enemy HP, and a compact HP bar under the HP text.
- `PrimaryStatsPanel` is a compact top-centered overlay, not a child of stretching main content containers.
- Its center should align with the viewport vertical center axis and it must not stretch full width.
- `PrimaryStatsPanel` uses horizontal stat cards from left to right: gold, character level, click damage, partner DPS.
- Primary stat cards show only a temporary white `ColorRect` placeholder and the value, with transparent backgrounds.
- `PrimaryStatsPanel` includes a placeholder white-square `SettingsButton`; it is a stub until a real settings flow is explicitly requested.
- Prestige and settlement details belong in their bottom tabs, not on the main screen.
- Each level requires defeating 10 enemies.
- Enemy HP and gold reward scale with the current level.
- Every 5th level is a boss level with one boss.
- Bosses must be defeated within 30 seconds or the player returns to the previous level.
- Gold can upgrade character level; character level always equals click damage.
- Character level upgrade cost is `5 + (character_level - 1) * 3`.
- Autoclick unlocks at character level 15.
- Gold Bonus unlocks at character level 30 and doubles enemy rewards while active.
- Focus Burst unlocks at character level 60 and doubles final click/autoclick damage while active.
- Rally unlocks at character level 80 and doubles final partner DPS while active.
- Ability buttons live on the left side of the game field.
- Ability buttons are placeholder ImageHolder-style controls: textless white squares until real icons are added.
- Ability state is shown with color/disabled feedback, not text inside the button.
- The bottom bar opens bottom-half `Upgrades`, `Partners`, `Settlement`, and `Prestige` sheets.
- The bottom bar remains visible and clickable while sheets are open, and tabs switch directly between sheets.
- Bottom-half sheets stop above the bottom bar so the visible upper game field remains clickable.
- Bottom sheet headers and close buttons stay fixed while sheet content scrolls vertically.
- The visible upper game field remains clickable while bottom-half sheets are open.
- The game field is the fullscreen bottom clickable layer.
- Ability buttons are a separate left-middle overlay and must be purchased before activation.
- Autoclick costs 50 gold, and Gold Bonus costs 150 gold.
- Autoclick lasts 15 seconds, attacks once every 0.05 seconds while active, then enters a 60 second cooldown.
- Gold Bonus lasts 45 seconds, doubles gold rewards while active, then enters a 300 second cooldown.
- Focus Burst costs 500 gold, lasts 20 seconds, then enters a 120 second cooldown.
- Rally costs 1000 gold, lasts 30 seconds, then enters a 180 second cooldown.
- War Banner increases Focus Burst and Rally duration, and Clock Tower reduces ability cooldowns up to a 50% cap.
- Partners provide passive DPS and are managed from a separate bottom-half sheet.
- Partner DPS tiers are data-driven: Partner 1 (10), Partner 2 (30), Partner 3 (50), Field Scout (100), Spear Guard (175), Iron Defender (300), Battle Monk (500), Elite Samurai (850), Shadow Captain (1400), War Sage (2300), Beast Tamer (3800), Blade Master (6200), and Legendary Commander (10000).
- The Partners tab uses partner card rows only and should not show a Total DPS summary line.
- Partner initial costs are `[10, 50, 150, 400, 900, 1800, 3500, 7000, 14000, 28000, 56000, 110000, 220000]`.
- Partner costs scale by adding `[10, 30, 50, 100, 180, 300, 500, 900, 1600, 2800, 5000, 9000, 16000]` per owned partner.
- Each partner tier requires at least one of the previous tier.
- Partner damage ticks every 0.1 seconds for `total_dps / 10` damage.
- Hero Level upgrades, partner hires, and settlement buildings use the reusable `BuyModeSelector` for horizontal bulk mode buttons: `x1`, `x10`, `x100`, and `Max`.
- In `UpgradeSheet`, `PartnerSheet`, and `SettlementSheet`, the buy mode selector stays fixed under the sheet header while purchase lists scroll independently below it.
- `SettlementSheet` should use the same header / `BuyModeSelector` / scroll spacing as `UpgradeSheet` and `PartnerSheet`.
- In `UpgradeSheet`, the buy mode selector affects only the Hero Level card; ability purchases are one-time purchases and never use bulk-buy.
- Bulk cost displays show the total package cost. `x10` and `x100` are strict all-or-nothing purchases; `Max` buys as many as current gold allows.
- Partner buttons always show the required package cost when prerequisites are met; failed unaffordable purchases can return "Not enough gold" through the status helper, but no main-screen status label is currently shown.
- Purchase tabs use card-style rows with a temporary white `ColorRect` image placeholder, two-line info text, and an action button.
These formulas are prototype balance values.

## Settlement

Settlement is a separate bottom tab between `Partners` and `Prestige`.

- Training Camp gives +1% final partner DPS per level.
- Market gives +1% final gold gain per level.
- Knight Hut gives +1% final click damage per level.
- War Banner gives +1% Focus Burst and Rally duration per level.
- Clock Tower gives -1% active ability cooldown per level, capped at 50%.
- Boss Shrine gives +1% boss reward gold per level.
- Each building requires at least one of the previous building.
- Building initial costs are `[25, 75, 150, 500, 1200, 3000]`.
- Building costs scale by adding `[25, 50, 100, 250, 600, 1500]` per owned building.
- Buildings use the same bulk modes as partners: `x1`, `x10`, `x100`, and `Max`.
- `x10` and `x100` are strict all-or-nothing purchases; `Max` buys as many as current gold allows.
- Settlement building rows use a temporary white `ColorRect` image placeholder, a two-line building summary, and a buy button.
- Building rows show the building name, owned count, and per-purchase effect; total owned effects belong in summary/stats UI, not each row.
- SettlementPanel should not show a combined settlement bonus summary line above building rows.
- Settlement buildings reset on prestige, while prestige points, prestige talents, and `total_prestiges` are kept.
- No save system is implemented; settlement state is lost on page reload.

## Prestige

Prestige is an unlockable reset in its own bottom `Prestige` tab.

- The bottom bar has `Upgrades`, `Partners`, `Settlement`, and `Prestige` buttons on one row.
- `PrestigeSheet` does not use the buy mode selector.
- `UpgradeSheet` contains a bulk-buy Hero Level card plus one-time ability purchases for Autoclick, Gold Bonus, Focus Burst, and Rally.
- Reward: `floor(current_level / 50) + floor(character_level / 100)` prestige points per prestige action.
- Stage level 52 and character level 102 gives 2 points.
- Stage level 101 and character level 301 gives 5 points.
- The Prestige button is disabled when the reward is 0 and enabled when the reward is greater than 0.
- Pressing the button opens a fully opaque confirmation dialog inside `PrestigeSheet` showing stage points, character points, and total reward points.
- The main Prestige panel shows only available Prestige Points, a card-style prestige action, and card-style talent rows; detailed prestige calculations live in the confirmation dialog.
- Confirming resets all normal progress (gold, character level, game level, abilities, partners, settlement, zone) but keeps available prestige points, total earned prestige points, prestige talents, and `total_prestiges`.
- Prestige points do not provide passive damage or gold bonuses by themselves.
- Available prestige points can be spent on prestige talents; total earned prestige points are historical/stat data only.
- Purchased prestige talents are the only source of prestige-related bonuses.
- Focus Training adds +5% click/autoclick damage per level.
- Trade Routes adds +5% gold gain per level.
- Command Aura adds +5% partner DPS per level.
- Quick Hands adds +5% Autoclick attack rate per level, with a minimum final interval of 0.02 seconds.
- Builder Wisdom adds +5% settlement building bonus effectiveness per level.
- Boss Hunter adds +5% damage against bosses per level for manual clicks, autoclick, and partners.
- Each talent's next cost is `1 + current talent level` available prestige points.
- Gold Bonus still doubles rewards on top of talent and settlement gold multipliers.
- No save system is implemented; prestige state and talents are lost on page reload.

## Zone Progression

Levels are grouped into zones. Each zone has three normal enemies, one elite enemy, one boss, and multipliers applied on top of the base HP and reward formulas.

| Zone | Levels | Name | First Normal Enemy | Boss | HP Mult | Reward Mult |
|------|--------|------|--------------------|------|---------|-------------|
| 1 | 1–10 | Training Grounds | Rogue Ninja | Training Master | 1.0× | 1.0× |
| 2 | 11–20 | Forest Path | Forest Bandit | Forest Guardian | 1.4× | 1.3× |
| 3 | 21–30 | Stone Valley | Stone Warrior | Valley Warlord | 1.9× | 1.7× |
| 4 | 31–40 | Shadow Camp | Shadow Fighter | Shadow Commander | 2.5× | 2.2× |

- After level 40 the game continues using Zone 4 data indefinitely.
- Zone enemy pools are:
  - Training Grounds: Rogue Ninja, Novice Bandit, Training Outcast; elite: Elite Rogue Ninja; boss: Training Master.
  - Forest Path: Forest Bandit, Wild Scout, Hidden Archer; elite: Elite Forest Bandit; boss: Forest Guardian.
  - Stone Valley: Stone Warrior, Valley Raider, Rock Sentinel; elite: Elite Stone Warrior; boss: Valley Warlord.
  - Shadow Camp: Shadow Fighter, Camp Assassin, Dark Scout; elite: Elite Shadow Fighter; boss: Shadow Commander.
- Normal enemies are randomly selected when a new non-boss target is created.
- Elite enemies have a 7% spawn chance on non-boss targets, count as one defeated enemy, have 3x normal HP, and give 5x normal base reward.
- Boss levels still use exactly one boss and are not affected by elite enemy logic.
- Base HP formula: `10 + (level - 1) * 8`. Zone HP multiplier is applied after.
- Base reward formula: `5 + (level - 1) * 3`. Zone reward multiplier is applied after.
- Boss levels (every 5th level) still multiply the zone-scaled HP and reward by 5.
- Zone data is stored as a constant array in `scripts/game/ClickerState.gd`.
- No background images or audio assets are used for zones.

The prototype state and formulas live in `scripts/game/ClickerState.gd`. `scenes/game/ClickerScreen.gd` owns the gameplay flow and updates the UI components.

## Project Structure

- `project.godot` - Godot project settings, main scene, display, renderer, and autoload configuration.
- `autoload/YandexBridge.gd` - Yandex Games integration placeholder/autoload.
- `scenes/main/Main.tscn` - App/root scene. It hosts the clicker screen and remains the project main scene.
- `scenes/main/Main.gd` - Root startup script for YandexBridge ready/gameplay calls.
- `scenes/game/ClickerScreen.tscn` - Main gameplay screen and layout.
- `scenes/game/ClickerScreen.gd` - Owns gameplay flow and UI updates.
- `scenes/ui/PrimaryStatsPanel.tscn` - Compact top-centered horizontal stat overlay for gold, character level, click damage, partner DPS, and a placeholder settings button.
- `scenes/ui/ProgressInfoPanel.tscn` - Compact progress UI for level, zone name, enemies progress, enemy name, enemy HP, and the enemy HP bar.
- `scenes/ui/GameField.tscn` - Fullscreen tap/click attack field, muted green background placeholder, enemy placeholder states, boss timer, and defeat feedback.
- `scenes/ui/AbilityBar.tscn` - Left-side textless placeholder-square active ability buttons.
- `scenes/ui/BuyModeSelector.tscn` - Reusable fixed `x1` / `x10` / `x100` / `Max` selector for hero level, partner, and settlement purchase sheets.
- `scenes/ui/UpgradePanel.tscn` - Card-style Hero Level upgrade row and one-time ability purchase rows.
- `scenes/ui/UpgradeSheet.tscn` - Bottom-half upgrades sheet that hosts UpgradePanel.
- `scenes/ui/PartnerPanel.tscn` - Card-style partner hiring controls and DPS display.
- `scenes/ui/PartnerSheet.tscn` - Bottom-half partners sheet that hosts PartnerPanel.
- `scenes/ui/SettlementPanel.tscn` - Settlement building controls and bonus display.
- `scenes/ui/SettlementSheet.tscn` - Bottom-half settlement sheet that hosts SettlementPanel.
- `scenes/ui/PrestigePanel.tscn` - Compact prestige points display, card-style prestige action, and talent rows.
- `scenes/ui/PrestigeSheet.tscn` - Bottom-half prestige sheet with the opaque confirmation dialog.
- `scripts/game/ClickerState.gd` - Temporary prototype state and formulas.

## Web Export Notes

The project is intended for Yandex Games Web export. Keep the 720x1280 portrait setup, GL Compatibility renderer, and Web-friendly Control-based UI layout.

YandexBridge is present for future platform integration, but ads, payments, saves, cloud features, authentication, heroes, loot/items, and additional enemy systems should not be added until explicitly requested.
