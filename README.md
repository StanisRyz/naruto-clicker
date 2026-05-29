# Naruto Clicker

Naruto Clicker is a vertical idle/clicker game prototype for Yandex Games.

## Status

Early setup/prototype. The project currently has a basic playable clicker loop and a YandexBridge autoload as a future integration point.

Save systems, heroes, loot/items, ads, and real-money payments are intentionally not implemented yet.

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
- `EnemyImageHolder` is a centered placeholder square: healthy is white, hit is blue for 0.3 seconds, wounded is red, and defeated is black for 0.2 seconds.
- Blue hit feedback is only for player-origin damage: manual clicks and Autoclick trigger it, while partner DPS does not.
- The black defeated state still applies to all damage sources.
- After enemy defeat, a 0.2 second transition lock keeps enemy HP at 0 and blocks manual, autoclick, and partner damage before reward, kill count, level changes, and the next enemy are applied.
- The main screen has no general `StatusLabel`.
- The main screen uses two independent panels: `PrimaryStatsPanel` for gold, Gems, character level, click damage, and partner DPS; `ProgressInfoPanel` for level, zone name, enemies progress, enemy name, enemy HP, and a compact HP bar under the HP text.
- `PrimaryStatsPanel` is a compact top-centered overlay, not a child of stretching main content containers.
- Its center should align with the viewport vertical center axis and it must not stretch full width.
- `PrimaryStatsPanel` uses horizontal stat cards from left to right: gold, Gems, character level, click damage, partner DPS.
- Primary stat cards show only a temporary white `ColorRect` placeholder and the value, with transparent backgrounds.
- `PrimaryStatsPanel` includes a placeholder white-square `SettingsButton`; it is a stub until a real settings flow is explicitly requested.
- Prestige and settlement details belong in their bottom tabs, not on the main screen.
- Manual Combo / Chakra Meter is a vertical meter on the right side of the screen that rewards active clicking.
- Manual `GameField` clicks add +1% meter charge, the meter decays by 1% per second, and every 1% charge gives +1% manual click damage.
- At 100% charge, manual click damage becomes x3 for 10 seconds. When the empowered state ends, the meter resets to 0.
- Combo resets on prestige and is runtime-only with no save persistence.
- Autoclick and partner DPS do not build combo and do not receive combo damage bonuses.
- Each level requires defeating 10 enemies.
- Enemy HP and gold reward scale with the current level.
- Every 10th level is a boss level with one boss.
- Bosses must be defeated within 30 seconds or the player returns to the previous level.
- Gold can upgrade character level. Hero damage starts from character level and is boosted by hero level milestones.
- Hero level upgrade costs use a controlled non-linear formula: early purchases stay affordable, while later purchases get harder through a power curve.
- Hero milestone target levels 10, 25, 50, 100, 250, and 500 cost x3 for the purchase that reaches the milestone.
- Hero level and each partner tier have milestone multipliers at 10, 25, 50, 100, 250, and 500 owned levels.
- Each reached milestone doubles the total accumulated contribution of that source, applying to all owned levels rather than only future purchases.
- Hero and each partner tier track milestones independently.
- Autoclick unlocks at character level 15.
- Gold Bonus unlocks at character level 30 and doubles enemy rewards while active.
- Focus Burst unlocks at character level 60 and doubles final click/autoclick damage while active.
- Rally unlocks at character level 80 and doubles final partner DPS while active.
- Ability buttons live on the left side of the game field.
- Ability buttons are placeholder ImageHolder-style controls: textless white squares until real icons are added.
- Ability state is shown with color/disabled feedback, not text inside the button.
- The bottom bar opens bottom-half `Upgrades`, `Partners`, `Settlement`, and `Prestige` sheets.
- The bottom bar remains visible and clickable while sheets are open. Tabs switch directly between sheets, and clicking the active tab again closes its sheet.
- Bottom-half sheets stop above the bottom bar so the visible upper game field remains clickable.
- Bottom sheet headers and close buttons stay fixed while sheet content scrolls vertically.
- The visible upper game field remains clickable while bottom-half sheets are open.
- The game field is the fullscreen bottom clickable layer.
- Ability buttons are a separate left-middle overlay and must be purchased before activation.
- `TasksButton` is a textless white square directly above the right-side `ComboPanel`.
- `TasksWindow` shows 5 active runtime-only tasks from a repeatable pool of 10 tasks; the other 5 tasks stay inactive.
- Active tasks snapshot their baseline when activated, so inactive tasks do not progress in the background.
- Claiming a completed task gives dynamic gold, resets that task into the inactive pool, and swaps in one random inactive task with a fresh baseline.
- Claimed tasks can rotate back later; tasks are never permanently exhausted.
- Level-based tasks are delta tasks such as "Reach 10 more levels", and hero progression uses "Gain 10 Hero Levels".
- Task rewards use `current normal enemy reward * reward_scale`, include current zone reward scaling, and are recalculated when displayed or claimed.
- Task rewards do not include elite/boss reward multipliers, Boss Shrine, Market, Trade Routes, or Gold Bonus.
- Tasks can be closed with the window Close button or by clicking/tapping outside the task panel.
- `TasksWindow` is modal while open: it blocks `GameField` attacks, consumes inside-panel input, and consumes the outside click/tap that closes it.
- Task claim refreshes should be deferred or otherwise input-safe so task rows are not rebuilt while the clicked Claim button is still handling input.
- Tasks do not add new currencies, daily timers, ads, monetization, or save persistence.
- Gems are a prototype premium currency for runtime testing only; they are not connected to real Yandex payments yet and are not saved.
- The Shop is the fifth bottom tab after Prestige. It spends Gems on prototype gameplay rewards: Small Gold Pack, Large Gold Pack, Instant Combo, Boss Retry, and Task Reward Boost.
- The Shop includes a temporary dev-only `Prototype: Get 50 Gems` button for testing product flow without payments.
- Boss Retry tokens automatically retry the same failed boss level once per token. Task Reward Boost doubles the next claimed task reward only once.
- Gems, Boss Retry tokens, and Task Reward Boost state are runtime-only until a save system is explicitly added.
- Autoclick costs 50 gold, and Gold Bonus costs 150 gold.
- Autoclick lasts 15 seconds, attacks once every 0.05 seconds while active, then enters a 60 second cooldown.
- Gold Bonus lasts 45 seconds, doubles gold rewards while active, then enters a 300 second cooldown.
- Focus Burst costs 500 gold, lasts 20 seconds, then enters a 120 second cooldown.
- Rally costs 1000 gold, lasts 30 seconds, then enters a 180 second cooldown.
- War Banner increases Focus Burst and Rally duration, and Clock Tower reduces ability cooldowns up to a 50% cap.
- Partners provide passive DPS and are managed from a separate bottom-half sheet.
- Partner DPS tiers are data-driven: Partner 1 (10), Partner 2 (20), Partner 3 (35), Field Scout (65), Spear Guard (120), Iron Defender (220), Battle Monk (410), Elite Samurai (750), Shadow Captain (1400), War Sage (2600), Beast Tamer (4800), Blade Master (9000), and Legendary Commander (16500).
- The Partners tab uses partner card rows only and should not show a Total DPS summary line.
- The Partners tab progressively reveals cards: visible available partner cards plus one next locked requirement card; deeper locked tiers stay hidden.
- Partner row second lines show per-purchase DPS and the next x2 milestone, such as `+10 DPS | Next x2 at 10`; they do not include `for each PartnerName` or accumulated partner DPS.
- Partner initial costs are `[10, 50, 150, 400, 900, 1800, 3500, 7000, 14000, 28000, 56000, 110000, 220000]`.
- Partner costs use each tier's base and step values plus a controlled non-linear power curve.
- Partner milestone target counts 10, 25, 50, 100, 250, and 500 cost x3 independently per tier.
- Hero and partner bulk-buy costs include milestone price spikes when the package crosses milestone targets.
- Each partner tier requires at least one of the previous tier.
- Partner tier DPS is `owned count * tier DPS * tier milestone multiplier`.
- Partner damage ticks every 0.1 seconds for final partner DPS / 10 damage.
- Base partner DPS includes partner tiers and partner milestones only.
- Final partner DPS adds Command Aura, Training Camp, and Rally; the main stats panel displays final partner DPS without contextual Boss Hunter, while partner damage ticks include Boss Hunter during boss fights.
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
- Builder Wisdom increases settlement building bonus effectiveness.
- Training Camp affects both displayed final Partner DPS and partner tick damage.
- Gold rewards apply Boss Shrine only for bosses, then Trade Routes, Market, and finally Gold Bonus.
- Knight Hut affects displayed click damage and the click damage used by manual clicks and Autoclick; manual combo remains owned by `ClickerScreen`.
- War Banner applies when Focus Burst or Rally is activated and does not affect Autoclick or Gold Bonus duration.
- Clock Tower applies when ability cooldowns start and does not need to reduce already-running cooldowns.
- Each building requires at least one of the previous building.
- Building initial costs are `[25, 75, 150, 500, 1200, 3000]`.
- Building costs scale by adding `[25, 50, 100, 250, 600, 1500]` per owned building.
- Buildings use the same bulk modes as partners: `x1`, `x10`, `x100`, and `Max`.
- `x10` and `x100` are strict all-or-nothing purchases; `Max` buys as many as current gold allows.
- Settlement building rows use a temporary white `ColorRect` image placeholder, a two-line building summary, and a buy button.
- Building rows show the building name, owned count, and per-purchase effect; total owned effects belong in summary/stats UI, not each row.
- SettlementPanel should not show a combined settlement bonus summary line above building rows.
- Settlement building cards progressively reveal: visible available building cards plus one next locked requirement card; deeper locked buildings stay hidden.
- Settlement buildings reset on prestige, while prestige points, prestige talents, and `total_prestiges` are kept.
- No save system is implemented; settlement state is lost on page reload.

## Prestige

Prestige is an unlockable reset in its own bottom `Prestige` tab.

- The bottom bar has `Upgrades`, `Partners`, `Settlement`, `Prestige`, and `Shop` buttons on one row.
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

## Shop

The Shop is a prototype premium-currency tab for gameplay reward testing. It is not a payment integration.

- Bottom bar order is `Upgrades`, `Partners`, `Settlement`, `Prestige`, `Shop`.
- Gems are the only prototype premium currency.
- Real Yandex payments, ads, authentication, and saves are not implemented.
- `Prototype: Get 50 Gems` is a temporary dev-only button.
- Shop products are Small Gold Pack, Large Gold Pack, Instant Combo, Boss Retry, and Task Reward Boost.
- Small and Large Gold Packs use stage-scaled gold based on the same normal enemy reward unit used by task rewards.
- Instant Combo fills the combo meter and starts the empowered combo state.
- Boss Retry adds an automatic retry token for failed boss fights.
- Task Reward Boost makes the next claimed task give x2 gold, then resets.
- Gems and shop reward state are runtime-only until a save system is added.

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
- Enemy formulas use `stage = current_level - 1`.
- Base HP formula: `10 + 8.0 * stage + 1.15 * stage^2.10`. Zone HP multiplier is applied after.
- Base reward formula: `5 + 3.0 * stage + 0.22 * stage^1.80`. Zone reward multiplier is applied after.
- HP grows faster than rewards so later progression leans on milestones, partners, settlement, prestige talents, and abilities.
- Boss levels (every 10th level) still multiply the zone-scaled HP and reward by 5.
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
- `scenes/ui/PrimaryStatsPanel.tscn` - Compact top-centered horizontal stat overlay for gold, Gems, character level, click damage, partner DPS, and a placeholder settings button.
- `scenes/ui/ProgressInfoPanel.tscn` - Compact progress UI for level, zone name, enemies progress, enemy name, enemy HP, and the enemy HP bar.
- `scenes/ui/ComboPanel.tscn` - Right-side vertical runtime-only Manual Combo / Chakra Meter display for meter charge and manual damage multiplier.
- `scenes/ui/TasksWindow.tscn` - Runtime-only modal repeatable tasks overlay with 5 active goals, dynamic level-scaled gold claim rewards, safe deferred row refresh after claim, rotation after claim, and outside-click close behavior that consumes the click.
- `scenes/ui/GameField.tscn` - Fullscreen tap/click attack field, muted green background placeholder, enemy placeholder states, boss timer, and defeat feedback.
- `scenes/ui/AbilityBar.tscn` - Left-side textless placeholder-square active ability buttons.
- `scenes/ui/BuyModeSelector.tscn` - Reusable fixed `x1` / `x10` / `x100` / `Max` selector for hero level, partner, and settlement purchase sheets.
- `scenes/ui/UpgradePanel.tscn` - Card-style Hero Level upgrade row and one-time ability purchase rows.
- `scenes/ui/UpgradeSheet.tscn` - Bottom-half upgrades sheet that hosts UpgradePanel.
- `scenes/ui/PartnerPanel.tscn` - Card-style partner hiring controls with per-purchase DPS effect rows.
- `scenes/ui/PartnerSheet.tscn` - Bottom-half partners sheet that hosts PartnerPanel.
- `scenes/ui/SettlementPanel.tscn` - Settlement building controls and bonus display.
- `scenes/ui/SettlementSheet.tscn` - Bottom-half settlement sheet that hosts SettlementPanel.
- `scenes/ui/PrestigePanel.tscn` - Compact prestige points display, card-style prestige action, and talent rows.
- `scenes/ui/PrestigeSheet.tscn` - Bottom-half prestige sheet with the opaque confirmation dialog.
- `scenes/ui/ShopPanel.tscn` - Prototype Gems shop panel with product cards and a temporary test Gems grant.
- `scenes/ui/ShopSheet.tscn` - Bottom-half shop sheet that hosts ShopPanel.
- `scripts/game/ClickerState.gd` - Temporary prototype state and formulas.

## Web Export Notes

The project is intended for Yandex Games Web export. Keep the 720x1280 portrait setup, GL Compatibility renderer, and Web-friendly Control-based UI layout.

YandexBridge is present for future platform integration, but real ads, payments, saves, cloud features, authentication, heroes, loot/items, and additional enemy systems should not be added until explicitly requested.
