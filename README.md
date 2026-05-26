# Naruto Clicker

Naruto Clicker is a vertical idle/clicker game prototype for Yandex Games.

## Status

Early setup/prototype. The project currently has a basic playable clicker loop and a YandexBridge autoload as a future integration point.

Save systems, heroes, settlement features, and monetization are intentionally not implemented yet.

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
- Enemy HP is shown with a label and progress bar.
- Each level requires defeating 10 enemies.
- Enemy HP and gold reward scale with the current level.
- Every 5th level is a boss level with one boss.
- Bosses must be defeated within 30 seconds or the player returns to the previous level.
- Gold can upgrade character level; character level always equals click damage.
- Character level upgrade cost is `5 + (character_level - 1) * 3`.
- Autoclick unlocks at character level 15.
- Gold Bonus unlocks at character level 30 and doubles enemy rewards while active.
- Ability buttons live on the left side of the game field.
- The bottom bar opens bottom-half `Upgrades`, `Partners`, `Settlement`, and `Prestige` sheets.
- The visible upper game field remains clickable while bottom-half sheets are open.
- The game field is the fullscreen bottom clickable layer.
- Ability buttons are a separate left-middle overlay and must be purchased before activation.
- Autoclick costs 50 gold, and Gold Bonus costs 150 gold.
- Autoclick lasts 15 seconds, attacks once every 0.05 seconds while active, then enters a 60 second cooldown.
- Gold Bonus lasts 45 seconds, doubles gold rewards while active, then enters a 300 second cooldown.
- Partners provide passive DPS and are managed from a separate bottom-half sheet.
- Partner DPS tiers are 10, 30, and 50.
- Partner initial costs are 10, 50, and 150 gold.
- Partner costs scale as `10 + count * 10`, `50 + count * 30`, and `150 + count * 50`.
- Partner 2 requires Partner 1, and Partner 3 requires Partner 2.
- Partner damage ticks every 0.1 seconds for `total_dps / 10` damage.
- Character level upgrades and partner hires use horizontal bulk mode buttons: `x1`, `x10`, `x100`, and `Max`.
- Bulk cost displays show the total package cost. `x10` and `x100` are strict all-or-nothing purchases; `Max` buys as many as current gold allows.
- Partner buttons always show the required package cost when prerequisites are met; failed unaffordable purchases report "Not enough gold" in the status text.
These formulas are prototype balance values.

## Settlement

Settlement is a separate bottom tab between `Partners` and `Prestige`.

- Training Camp gives +1% final partner DPS per level.
- Market gives +1% final gold gain per level.
- Knight Hut gives +1% final click damage per level.
- Market requires at least one Training Camp, and Knight Hut requires at least one Market.
- Buildings use the same bulk modes as partners: `x1`, `x10`, `x100`, and `Max`.
- `x10` and `x100` are strict all-or-nothing purchases; `Max` buys as many as current gold allows.
- Settlement buildings reset on prestige, while `prestige_points` and `total_prestiges` are kept.
- No save system is implemented; settlement state is lost on page reload.

## Prestige

Prestige is an unlockable reset in its own bottom `Prestige` tab.

- The bottom bar has `Upgrades`, `Partners`, and `Prestige` buttons on one row.
- `UpgradeSheet` only contains character level, Autoclick, and Gold Bonus purchases.
- Reward: `floor(current_level / 50) + floor(character_level / 100)` prestige points per prestige action.
- Stage level 52 and character level 102 gives 2 points.
- Stage level 101 and character level 301 gives 5 points.
- The Prestige button is disabled when the reward is 0 and enabled when the reward is greater than 0.
- Pressing the button opens a fully opaque confirmation dialog inside `PrestigeSheet` showing stage points, character points, total points, and resulting bonuses.
- Confirming resets all normal progress (gold, character level, game level, abilities, partners, zone) but keeps `prestige_points` and `total_prestiges`.
- Each prestige point permanently adds +10% to click damage and +10% to gold rewards.
- Gold Bonus still doubles rewards on top of the prestige gold multiplier.
- No save system is implemented; prestige state is lost on page reload.

## Zone Progression

Levels are grouped into zones. Each zone has named enemies and multipliers applied on top of the base HP and reward formulas.

| Zone | Levels | Name | Enemy | Boss | HP Mult | Reward Mult |
|------|--------|------|-------|------|---------|-------------|
| 1 | 1–10 | Training Grounds | Rogue Ninja | Training Master | 1.0× | 1.0× |
| 2 | 11–20 | Forest Path | Forest Bandit | Forest Guardian | 1.4× | 1.3× |
| 3 | 21–30 | Stone Valley | Stone Warrior | Valley Warlord | 1.9× | 1.7× |
| 4 | 31–40 | Shadow Camp | Shadow Fighter | Shadow Commander | 2.5× | 2.2× |

- After level 40 the game continues using Zone 4 data indefinitely.
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
- `scenes/game/ClickerScreen.gd` - Owns gameplay flow, status messages, and UI updates.
- `scenes/ui/StatsPanel.tscn` - Displays gold, character level, damage, level, and enemy progress.
- `scenes/ui/GameField.tscn` - Fullscreen tap/click attack field and enemy HP display.
- `scenes/ui/AbilityBar.tscn` - Left-side active ability buttons.
- `scenes/ui/UpgradePanel.tscn` - Character level and ability purchase buttons.
- `scenes/ui/UpgradeSheet.tscn` - Bottom-half upgrades sheet that hosts UpgradePanel.
- `scenes/ui/PartnerPanel.tscn` - Partner hiring controls and DPS display.
- `scenes/ui/PartnerSheet.tscn` - Bottom-half partners sheet that hosts PartnerPanel.
- `scenes/ui/SettlementPanel.tscn` - Settlement building controls and bonus display.
- `scenes/ui/SettlementSheet.tscn` - Bottom-half settlement sheet that hosts SettlementPanel.
- `scenes/ui/PrestigePanel.tscn` - Prestige summary and prestige request button.
- `scenes/ui/PrestigeSheet.tscn` - Bottom-half prestige sheet with the opaque confirmation dialog.
- `scripts/game/ClickerState.gd` - Temporary prototype state and formulas.

## Web Export Notes

The project is intended for Yandex Games Web export. Keep the 720x1280 portrait setup, GL Compatibility renderer, and Web-friendly Control-based UI layout.

YandexBridge is present for future platform integration, but ads, payments, saves, cloud features, authentication, heroes, settlement systems, and elite enemies should not be added until explicitly requested.
