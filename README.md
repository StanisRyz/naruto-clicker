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
- Character level upgrades temporarily cost 1 gold.
- Autoclick unlocks at character level 15.
- Gold Bonus unlocks at character level 30 and doubles enemy rewards while active.
- Ability buttons live on the left side of the game field.
- The bottom `Upgrades` button opens a bottom-half upgrade sheet.
- The visible upper game field remains clickable while the upgrade sheet is open.
- The game field is the fullscreen bottom clickable layer.
- Ability buttons are a separate left-middle overlay and must be purchased before activation.
- Autoclick lasts 30 seconds and attacks once every 0.05 seconds while active.
- Gold Bonus lasts 30 seconds and doubles gold rewards while active.
- Partners provide passive DPS and are managed from a separate bottom-half sheet.
- Partner DPS tiers are 10, 30, and 50.
- Partner 2 requires Partner 1, and Partner 3 requires Partner 2.
- Partner damage ticks every 0.1 seconds for `total_dps / 10` damage.

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
- `scenes/ui/UpgradePanel.tscn` - Character level upgrade button.
- `scenes/ui/UpgradeSheet.tscn` - Bottom-half upgrades sheet that hosts UpgradePanel.
- `scenes/ui/PartnerPanel.tscn` - Partner hiring controls and DPS display.
- `scenes/ui/PartnerSheet.tscn` - Bottom-half partners sheet that hosts PartnerPanel.
- `scripts/game/ClickerState.gd` - Temporary prototype state and formulas.

## Web Export Notes

The project is intended for Yandex Games Web export. Keep the 720x1280 portrait setup, GL Compatibility renderer, and Web-friendly Control-based UI layout.

YandexBridge is present for future platform integration, but ads, payments, saves, cloud features, authentication, heroes, settlement systems, and elite enemies should not be added until explicitly requested.
