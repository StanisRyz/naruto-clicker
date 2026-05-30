# Naruto Clicker

Naruto Clicker is a vertical idle/clicker game prototype for Yandex Games.

## Status

Pre-release. The project has a complete clicker loop with all major gameplay systems working: partners, settlement, prestige, shop, tasks, active abilities, stage navigation, auto-transition, Save System v1, SettingsWindow with Reset Progress, and exports configured for Web (Yandex Games) and Android.

Heroes, loot/items, ads, cloud saves, and real-money payments are intentionally not implemented yet.

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
- `PrimaryStatsPanel` includes a white-square `SettingsButton` that opens `SettingsWindow`.
- `SettingsWindow` is a modal overlay with Sound and Music placeholder toggles, Save Now, and Reset Progress.
- Sound and Music toggles are persisted but do not affect audio yet because audio is not implemented.
- Reset Progress requires confirmation, deletes the local save, and starts a fresh new game.
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
- Active abilities are unlocked once through the large card button, then improved by passive rank skill icons.
- Autoclick unlocks at character level 15, base cost 50 gold. Each passive rank adds +15% attack rate and +2 seconds duration.
- Gold Bonus unlocks at character level 30, base cost 150 gold. Base is x2.00, and passive ranks add +0.25 multiplier each.
- Focus Burst unlocks at character level 60, base cost 500 gold. Base is x2.00, and passive ranks add +0.25 multiplier each.
- Rally unlocks at character level 80, base cost 1000 gold. Base is x2.00, and passive ranks add +0.25 multiplier each.
- Upgrade costs: base_cost × rank_to_buy² × 2 (e.g. Autoclick rank 2 costs 50×4×2 = 400 gold).
- Prestige resets purchased abilities, Hero skills, and ability passive ranks to 0 along with normal progression.
- Ability buttons live on the left side of the game field.
- Ability buttons are placeholder ImageHolder-style controls: textless white squares until real icons are added.
- Ability state is shown with color/disabled feedback, not text inside the button.
- The bottom bar opens bottom-half `Upgrades`, `Partners`, `Settlement`, `Prestige`, and `Shop` sheets.
- The bottom bar remains visible and clickable while sheets are open. Tabs switch directly between sheets, and clicking the active tab again closes its sheet.
- Bottom-half sheets stop above the bottom bar so the visible upper game field remains clickable.
- Bottom sheet headers and close buttons stay fixed while sheet content scrolls vertically.
- `UpgradeSheet`, `PartnerSheet`, and `SettlementSheet` headers show a white resource placeholder and current gold beside the title.
- `PrestigeSheet` header shows a white resource placeholder and current available prestige points beside the title.
- `ShopSheet` header shows a white resource placeholder and current Gems beside the title.
- The visible upper game field remains clickable while bottom-half sheets are open.
- The game field is the fullscreen bottom clickable layer.
- Ability buttons are a separate left-middle overlay and must be purchased before activation.
- `TasksButton` is a textless white square directly above the right-side `ComboPanel`.
- `TasksWindow` shows 5 active tasks from a repeatable pool of 10 tasks; the other 5 tasks stay inactive.
- Active tasks snapshot their baseline when activated, so inactive tasks do not progress in the background.
- Claiming a completed task gives dynamic gold, resets that task into the inactive pool, and swaps in one random inactive task with a fresh baseline.
- Claimed tasks can rotate back later; tasks are never permanently exhausted.
- Level-based tasks are delta tasks such as "Reach 10 more levels", and hero progression uses "Gain 10 Hero Levels".
- Task rewards use `current normal enemy reward * reward_scale`, include current zone reward scaling, and are recalculated when displayed or claimed.
- Task rewards do not include elite/boss reward multipliers, Boss Shrine, Market, Trade Routes, or Gold Bonus.
- Tasks can be closed with the window Close button or by clicking/tapping outside the task panel.
- `TasksWindow` is modal while open: it blocks `GameField` attacks, consumes inside-panel input, and consumes the outside click/tap that closes it.
- Task claim refreshes should be deferred or otherwise input-safe so task rows are not rebuilt while the clicked Claim button is still handling input.
- Tasks do not add new currencies, daily timers, ads, or monetization.
- Gems are a prototype premium currency for runtime testing only; they are not connected to real Yandex payments.
- The Shop is the fifth bottom tab after Prestige. It spends Gems on prototype gameplay rewards: Small Gold Pack, Large Gold Pack, Instant Combo, Boss Retry, and Task Reward Boost.
- The Shop includes a temporary dev-only `Prototype: Get 50 Gems` button for testing product flow without payments.
- Boss Retry tokens automatically retry the same failed boss level once per token. Task Reward Boost doubles the next claimed task reward only once.
- Gems, Boss Retry tokens, and Task Reward Boost are local-save prototype state until real payments/save integration are explicitly added.
- Autoclick unlock base: 20 hits/sec for 15 s, 60 s cooldown. Each passive rank adds +15% rate and +2 s duration after Autoclick is purchased.
- Gold Bonus base: x2 gold for 45 s, 300 s cooldown. Passive ranks add +0.25 multiplier each.
- Focus Burst base: x2 damage for 20 s, 120 s cooldown. Passive ranks add +0.25 multiplier each.
- Rally base: x2 partner DPS for 30 s, 180 s cooldown. Passive ranks add +0.25 multiplier each.
- War Banner increases Focus Burst and Rally duration, and Clock Tower improves cooldown efficiency with diminishing returns.
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
- Partner cards use three vertical info rows on the right: name/count, per-purchase DPS plus next x2 milestone, then a row of 5 partner skill icons.
- The main partner ImageHolder stays square and visually fills the taller card; the 5 skill icons are small fixed squares (32×32) in a horizontal row under the DPS/milestone line.
- Partner skills are purchasable gold upgrades shown as small ImageHolder-style icons in partner cards, not automatic unlocks.
- Each partner has 5 purchasable skill icons that unlock at partner counts 10, 25, 50, 100, and 250. The 500 milestone is reserved for a future ultimate skill.
- Skill icon states are gray for locked, blue for available to buy, and white for purchased.
- Clicking any skill icon opens a compact non-modal popup with the skill name, description, required partner count, current count vs requirement, gold cost, and Buy button. The popup fits its content height and must not stretch vertically to the screen bottom. The popup closes when clicking outside the popup panel. Clicking another skill icon while the popup is open switches the popup to that skill without closing first. Clicks inside the popup panel do not close it.
- Skill bonuses apply only after purchase and reset on prestige with normal partner progress.
- Skill categories and distribution:
  - Partner 1 and Field Scout (Partner 4): Click Damage skills — Click Training I–V (+20%/+25%/+50%/+100%/+100%).
  - Spear Guard (Partner 5): Total Partner DPS skills — Team Command I–V (+25%/+40%/+60%/+60%/+100%).
  - Iron Defender (Partner 6): Gold Gain skills — Gold Sense I–V (+25%/+50%/+50%/+50%/+50%).
  - All other partners (Partner 2, 3, 7–13): Own Partner DPS skills — Personal Mastery I–V (+50%/+50%/+50%/+100%/+100%) affecting only that partner tier's DPS.
- Hero Level upgrades, partner hires, and settlement buildings use the reusable `BuyModeSelector` for horizontal bulk mode buttons: `x1`, `x10`, `x100`, and `Max`.
- In `UpgradeSheet`, `PartnerSheet`, and `SettlementSheet`, the buy mode selector stays fixed under the sheet header while purchase lists scroll independently below it.
- `UpgradePanel` uses the same VBoxContainer-based layout pattern as `PartnerPanel`; it should not use a full-rect Control wrapper that can overlap the fixed buy mode selector.
- `SettlementSheet` should use the same header / `BuyModeSelector` / scroll spacing as `UpgradeSheet` and `PartnerSheet`.
- In `UpgradeSheet`, the buy mode selector affects only the Hero Level card; ability buy/upgrade actions never use bulk-buy modes.
- Bulk cost displays show the total package cost. `x10` and `x100` are strict all-or-nothing purchases; `Max` buys as many as current gold allows.
- Partner buttons always show the required package cost when prerequisites are met; failed unaffordable purchases can return "Not enough gold" through the status helper, but no main-screen status label is currently shown.
- Partner card first lines show partner name, owned count, and that tier's total DPS contribution: `Partner Name | Count | DPS X`.
- Partner card second lines stay focused on per-purchase DPS and the next x2 milestone.
- Purchase tabs use card-style rows with a temporary white `ColorRect` image placeholder, right-side info rows, skill icons where applicable, and a full-height action button in its own right column.
These formulas are prototype balance values.

## Settlement

Settlement is a separate bottom tab between `Partners` and `Prestige`.

- Training Camp gives +1% final partner DPS per level.
- Market gives +1% final gold gain per level.
- Knight Hut gives +1% final click damage per level.
- War Banner gives +1% Focus Burst and Rally duration per level.
- Clock Tower gives +1% cooldown efficiency per level.
- Boss Shrine gives +1% boss reward gold per level.
- Builder Wisdom increases settlement building bonus effectiveness.
- Settlement buildings use independent milestone multipliers at 10, 25, 50, 100, 250, and 500 owned buildings.
- Each reached building milestone doubles that building's total accumulated effect, and Builder Wisdom applies after the milestone multiplier.
- Settlement effects use two scaling types: positive additive bonuses and diminishing reduction bonuses.
- Positive bonuses can grow above 100%.
- Reduction bonuses use `final_multiplier = 100 / (100 + raw_bonus)`, so cooldowns, costs, and future reduction effects never reach 0.
- Clock Tower uses cooldown efficiency through this diminishing formula. Future cost-reduction buildings should use the same formula.
- Training Camp affects both displayed final Partner DPS and partner tick damage.
- Gold rewards apply Boss Shrine only for bosses, then Trade Routes, Market, and finally Gold Bonus.
- Knight Hut affects displayed click damage and the click damage used by manual clicks and Autoclick; manual combo remains owned by `ClickerScreen`.
- War Banner applies when Focus Burst or Rally is activated and does not affect Autoclick or Gold Bonus duration.
- Clock Tower applies its cooldown efficiency multiplier when ability cooldowns start and does not need to reduce already-running cooldowns.
- Each building requires at least one of the previous building.
- Building initial costs are `[25, 75, 150, 500, 1200, 3000]`.
- Building costs scale by adding `[25, 50, 100, 250, 600, 1500]` per owned building.
- Buildings use the same bulk modes as partners: `x1`, `x10`, `x100`, and `Max`.
- `x10` and `x100` are strict all-or-nothing purchases; `Max` buys as many as current gold allows.
- Settlement building rows use a temporary white `ColorRect` image placeholder, a two-line building summary, and a buy button.
- Building rows show the building name, owned count, per-purchase effect, and next x2 milestone; total owned effects belong in summary/stats UI, not each row.
- SettlementPanel should not show a combined settlement bonus summary line above building rows.
- Settlement building cards progressively reveal: visible available building cards plus one next locked requirement card; deeper locked buildings stay hidden.
- Settlement buildings reset on prestige, while prestige points, prestige talents, and `total_prestiges` are kept.
- Settlement state is included in local Save System v1.

## Prestige

Prestige is an unlockable reset in its own bottom `Prestige` tab.

- The bottom bar has `Upgrades`, `Partners`, `Settlement`, `Prestige`, and `Shop` buttons on one row.
- `PrestigeSheet` does not use the buy mode selector.
- `UpgradeSheet` contains Partner-style upgrade cards: Hero Level plus Autoclick, Gold Bonus, Focus Burst, and Rally. Each card uses a large square `ImageHolder`, right-side title/effect rows, a row of 5 small skill icons, and a full-height right-column action button.
- Hero Level's first line shows current level and current click damage: `Hero Level | Level X | Damage Y`. Its second line still shows damage plus the next x2 milestone or max milestones.
- Hero Level keeps its separate bulk-buy button and `BuyModeSelector` behavior; hero skill icon purchases do not use bulk-buy.
- Hero Level has 5 purchasable passive skill icons unlocked by character level. Ability cards are unlocked once through the main card button, then have 5 purchasable passive rank skill icons unlocked by character level.
- Upgrade skill icon colors match partner skills: gray = locked, blue = available to buy, white = purchased.
- Ability activation uses the ability purchased flag. Ability rank/effects are derived from purchased passive skill icons, and passive ability skills require buying the ability first.
- Hero skills and ability skills are normal progression and reset on prestige.
- Reward: `floor(current_level / 50) + floor(character_level / 100)` prestige points per prestige action.
- Stage level 52 and character level 102 gives 2 points.
- Stage level 101 and character level 301 gives 5 points.
- The Prestige button is disabled when the reward is 0 and enabled when the reward is greater than 0.
- Pressing the button opens a fully opaque confirmation dialog inside `PrestigeSheet` showing stage points, character points, and total reward points.
- The main Prestige panel shows only a card-style prestige action and card-style talent rows; available prestige points are shown in the `PrestigeSheet` header, and detailed prestige calculations live in the confirmation dialog.
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
- Prestige state and talents are included in local Save System v1.

## Shop

The Shop is a prototype premium-currency tab for gameplay reward testing. It is not a payment integration.

- Bottom bar order is `Upgrades`, `Partners`, `Settlement`, `Prestige`, `Shop`.
- Gems are the only prototype premium currency.
- Real Yandex payments, ads, authentication, and cloud saves are not implemented.
- `Prototype: Get 50 Gems` is a temporary dev-only button.
- Shop products are Small Gold Pack, Large Gold Pack, Instant Combo, Boss Retry, and Task Reward Boost.
- Small and Large Gold Packs use stage-scaled gold based on the same normal enemy reward unit used by task rewards.
- Instant Combo fills the combo meter and starts the empowered combo state.
- Boss Retry adds an automatic retry token for failed boss fights.
- Task Reward Boost makes the next claimed task give x2 gold, then resets.
- Gems and shop reward state are local-save prototype state until real payments/save integration are explicitly added.
- `ShopPanel` shows the temporary Gems grant and product cards only; Boss Retry tokens and Task Reward Boost still exist as runtime mechanics but are not shown as top summary rows.

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
- Zone data is stored in `scripts/game/config/ZoneConfig.gd`.
- Zone background images are loaded by `BackgroundAssetCatalog` and displayed in `GameField.BackgroundImageHolder`.

The prototype runtime state lives in `scripts/game/ClickerState.gd`. Pure formulas live in `scripts/game/calculators/`. Task and shop runtime logic live in `scripts/game/runtime/`. Save serialization lives in `scripts/game/save/`. UI formatting lives in `scripts/game/presentation/`. `scenes/game/ClickerScreen.gd` owns the gameplay flow and updates the UI components.

## Stage Navigator

The "Naruto Clicker" title has been replaced by a horizontal Stage Navigator row at the top of `MainContent`.

- Displays 7 small square buttons (60×60) centered on the current stage.
- Button color states:
  - **Blue** — current selected stage.
  - **White** — unlocked/opened stage (reachable for farming).
  - **Gray** — locked future stage (not yet reached).
- Player can click any white (unlocked) stage to travel there instantly.
- Clicking a gray (locked) or the current (blue) stage does nothing.
- Traveling resets the current enemy, enemies-defeated counter, and boss timer.
- Traveling to a previous boss level starts the boss timer again (farmable).

### Side buttons

To the right of the 7 stage buttons:

- **Latest button** (`>>`, yellow) — jumps the visible strip to `max_unlocked_level`. Does not travel there; only scrolls the view.
- **Auto-transition button** (`A`) — immediately toggles Auto-transition ON/OFF and opens the info popup. Green when ON, gray when OFF.

### Scrolling

The stage strip can be scrolled two ways (step-scroll buttons have been removed):

- **Mouse wheel** — wheel up/left scrolls left; wheel down/right scrolls right.
- **Drag/swipe** — drag or swipe horizontally; dragging right reveals earlier stages, dragging left reveals later stages. Dragging does not accidentally trigger stage travel.

### Scroll position

- Manual scrolling is always preserved. Normal UI updates (`update_view`) do not auto-center the strip.
- The first time the navigator displays, it centers on `current_level`.
- `center_on_level(level)` is called explicitly only when the player actually advances to a new level through gameplay, and after prestige.
- Manual stage travel via the strip does **not** force a re-center.

### Scroll bounds

- Scroll left stops when stage 1 is the leftmost visible button.
- Scroll right stops when the rightmost visible button equals `max_unlocked_level + 3` (shows up to 3 locked future stages).

### max_unlocked_level

- Tracks the highest stage the player has reached naturally.
- Updated whenever `current_level` clears its objective (regardless of Auto-transition setting).
- Only unlocks `current_level + 1` per clear — farming the same cleared stage never unlocks beyond the immediately next level.
- Traveling backward does **not** reduce `max_unlocked_level`.
- Boss fail returns to the previous level but does **not** reduce `max_unlocked_level`.
- Resets to 1 on prestige alongside normal progression reset.

## Auto-transition

Controls whether the game automatically moves to the next level after a stage is cleared.

- **ON (default)** — after defeating all required enemies (10 normals or 1 boss), the player automatically advances to `current_level + 1`.
- **OFF** — the stage objective is still cleared and the next level is unlocked (becomes white in the strip), but `current_level` stays the same. The enemy resets for farming. The player must manually click the next stage in the strip to move forward, or re-enable Auto-transition.

### Boss behavior with Auto-transition OFF

- Defeating the boss grants the reward and unlocks the next stage.
- The boss timer restarts for the same boss level.
- The player can farm the boss repeatedly; `max_unlocked_level` does not increase further from repeated boss clears on the same level.

### Auto-transition popup

Pressing the `A` button immediately toggles Auto-transition ON/OFF and then opens a compact info popup. The popup:
- Shows the current status (ON / OFF).
- Closes with the X button or by clicking outside the popup.
- Clicking inside the popup does not attack the GameField.
- The popup is info-only; the toggle happens the moment the `A` button is pressed.

## Project Structure

- `project.godot` - Godot project settings, main scene, display, renderer, and autoload configuration.
- `autoload/YandexBridge.gd` - Yandex Games integration placeholder/autoload.
- `autoload/SaveManager.gd` - Local save autoload. Atomic JSON write to `user://save_v1.json`, version validation, and migration hook.
- `scenes/main/Main.tscn` - App/root scene. It hosts the clicker screen and remains the project main scene.
- `scenes/main/Main.gd` - Root startup script for YandexBridge ready/gameplay calls.
- `scenes/game/ClickerScreen.tscn` - Main gameplay screen and layout.
- `scenes/game/ClickerScreen.gd` - Owns gameplay flow and UI updates.
- `scenes/ui/PrimaryStatsPanel.tscn` - Compact top-centered horizontal stat overlay for gold, Gems, character level, click damage, partner DPS, and the settings button.
- `scenes/ui/SettingsWindow.tscn` - Modal settings overlay with Sound/Music placeholders, Save Now, and Reset Progress confirmation.
- `scenes/ui/ProgressInfoPanel.tscn` - Compact progress UI for level, zone name, enemies progress, enemy name, enemy HP, and the enemy HP bar.
- `scenes/ui/ComboPanel.tscn` - Right-side vertical runtime-only Manual Combo / Chakra Meter display for meter charge and manual damage multiplier.
- `scenes/ui/TasksWindow.tscn` - Modal repeatable tasks overlay with 5 active goals, dynamic level-scaled gold claim rewards, safe deferred row refresh after claim, rotation after claim, and outside-click close behavior that consumes the click.
- `scenes/ui/GameField.tscn` - Fullscreen tap/click attack field, muted green background placeholder, enemy placeholder states, boss timer, and defeat feedback.
- `scenes/ui/AbilityBar.tscn` - Left-side textless placeholder-square active ability buttons.
- `scenes/ui/BuyModeSelector.tscn` - Reusable fixed `x1` / `x10` / `x100` / `Max` selector for hero level, partner, and settlement purchase sheets.
- `scenes/ui/UpgradePanel.tscn` - Partner-style Hero Level and ability upgrade cards with skill icon rows.
- `scenes/ui/UpgradeSheet.tscn` - Bottom-half upgrades sheet that hosts UpgradePanel and the upgrade skill popup.
- `scenes/ui/UpgradeSkillPopup.tscn` - Compact popup for Hero and ability skill purchases.
- `scenes/ui/PartnerPanel.tscn` - Card-style partner hiring controls with per-purchase DPS effect rows.
- `scenes/ui/PartnerSheet.tscn` - Bottom-half partners sheet that hosts PartnerPanel.
- `scenes/ui/SettlementPanel.tscn` - Settlement building controls and bonus display.
- `scenes/ui/SettlementSheet.tscn` - Bottom-half settlement sheet that hosts SettlementPanel.
- `scenes/ui/PrestigePanel.tscn` - Compact card-style prestige action and talent rows.
- `scenes/ui/PrestigeSheet.tscn` - Bottom-half prestige sheet with header prestige points and the opaque confirmation dialog.
- `scenes/ui/ShopPanel.tscn` - Prototype shop panel with product cards and a temporary test Gems grant.
- `scenes/ui/ShopSheet.tscn` - Bottom-half shop sheet with header Gems that hosts ShopPanel.
- `scripts/game/ClickerState.gd` - Runtime player state and gameplay API. Static definitions live in `config/`. Pure formulas live in `calculators/`. Task and shop logic live in `runtime/`. Save serialization lives in `save/`. UI formatting lives in `presentation/`.
- `scripts/game/save/ClickerStateSaveAdapter.gd` - Save System v1 serializer; builds and applies save dictionaries. File IO is handled by SaveManager.
- `scripts/game/calculators/` - Stateless pure formula functions for milestone math, cost curves, and enemy scaling.
- `scripts/game/runtime/TaskRuntime.gd` - Task initialization, progress, reward, claim, and rotation logic.
- `scripts/game/runtime/ShopRuntime.gd` - Local shop purchase logic and Gems helpers. Prototype only; no real payments.
- `scripts/game/presentation/ClickerStatePresentation.gd` - UI-facing formatting, description strings, and view-data builders. Read-only access to ClickerState.
- `scripts/game/config/ZoneConfig.gd` - Zone definitions (names, level ranges, enemy lists, HP/reward multipliers).
- `scripts/game/config/PartnerConfig.gd` - Partner names; DPS and costs delegate to BalanceConfig.
- `scripts/game/config/PartnerSkillConfig.gd` - All 65 partner skill definitions.
- `scripts/game/config/HeroSkillConfig.gd` - Hero passive skill definitions.
- `scripts/game/config/AbilityConfig.gd` - Ability rank skill definitions and unlock/cost helpers.
- `scripts/game/config/SettlementConfig.gd` - Building names and bonus types.
- `scripts/game/config/PrestigeConfig.gd` - Prestige talent names and bonus types.
- `scripts/game/config/TaskConfig.gd` - Task definitions (id, goal type, target, reward scale).
- `scripts/game/config/ShopConfig.gd` - Shop product definitions.
- `scenes/ui/StageNavigator.tscn` / `StageNavigator.gd` - Horizontal 7-button stage navigator; replaces the "Naruto Clicker" title label.

## Image Asset System

The project uses a centralized image placeholder system. All UI elements that will eventually show images use `ImageSlot` nodes backed by `GameAssetCatalog`.

### How it works

- `scripts/ui/GameAssetCatalog.gd` — single editable file listing every image slot key and its file path.
- `scripts/ui/ImageSlot.gd` — drop-in replacement for ColorRect placeholders. Shows a texture when the file exists; falls back to the placeholder color when the file is missing.

### Adding an image

1. Put the PNG file under `res://assets/images/...` (e.g. `res://assets/images/ui/gold.png`).
2. Make sure the matching key in `GameAssetCatalog.ASSET_PATHS` points to that path.
3. Run the game — the slot will automatically show the image.

No code changes are needed in UI panels or scenes unless a new slot type is being added.

### Asset key groups

| Group | Example keys |
|-------|-------------|
| Core UI | `ui.gold`, `ui.gems`, `ui.hero_level`, `ui.click_damage`, `ui.partner_dps`, `ui.settings` |
| Sheet headers | `header.gold`, `header.prestige_points`, `header.gems` |
| Game field | `game.field_background`, `enemy.default.healthy/hit/wounded/defeated` |
| Stage navigator | `stage.current`, `stage.unlocked`, `stage.locked`, `stage.latest`, `stage.auto_on/off` |
| Abilities | `ability.autoclick`, `ability.gold_bonus`, `ability.focus_burst`, `ability.rally` |
| Upgrade cards | `upgrade.hero`, `upgrade.autoclick`, etc. |
| Partners | `partner.0.icon` … `partner.12.icon`, `partner.0.skill.1` … |
| Buildings | `building.0.icon` … `building.5.icon` |
| Prestige | `prestige.action`, `prestige.focus_training`, etc. |
| Shop | `shop.gold_pack_small`, `shop.boss_retry_token`, etc. |
| Tasks | `task.manual_damage_500`, `task.defeat_25_enemies`, etc. |

### Rules

- Missing image files never crash the game — the placeholder color is shown instead.
- Do not hardcode image paths in UI panels; always use `GameAssetCatalog`.
- New ImageHolder nodes should use `ImageSlot` and a key registered in `GameAssetCatalog.ASSET_PATHS`.
- Keep placeholder fallback colors in place until final art is ready.
- Helper methods: `partner_icon_key(index)`, `partner_skill_key(index, level)`, `ability_skill_key(id, level)`, `hero_skill_key(level)`, `building_icon_key(index)`, `prestige_talent_icon_key(id)`, `shop_product_icon_key(id)`, `task_icon_key(id)`.

## Enemy Image System

Enemy visuals use a separate catalog from the general UI image system.

- `scripts/ui/EnemyAssetCatalog.gd` — dedicated catalog for per-enemy, per-state image paths. Kept separate from `GameAssetCatalog` because enemy images scale with zones and enemy counts.
- `ClickerState` stores `current_enemy_zone_index` and `current_enemy_slot` — set when an enemy is chosen for the current level. `GameField` reads these to load the correct images.

### Folder structure

```
res://assets/images/enemies/zone_XX/enemy_YY/state.png
```

| Path segment | Mapping |
|---|---|
| `zone_01` | Zone index 0 (levels 1–10) |
| `zone_02` | Zone index 1 (levels 11–20) |
| `enemy_01` / `enemy_02` / `enemy_03` | Normal enemies 1–3 in ZONE_DATA |
| `elite_01` | Elite enemy |
| `boss_01` | Boss enemy |

### State files per enemy folder

`healthy.png`, `hit.png`, `wounded.png`, `defeated.png`

### Fallback chain

1. Exact enemy image (e.g. `zone_01/enemy_01/healthy.png`)
2. Default enemy image from GameAssetCatalog (`enemy.default.healthy`)
3. Placeholder color (white / blue / red / black)

Missing files never crash the game. All fallbacks are automatic.

### Adding enemy art

1. Place PNGs under `res://assets/images/enemies/zone_XX/enemy_YY/`.
2. File names must match the state: `healthy.png`, `hit.png`, `wounded.png`, `defeated.png`.
3. Run the game — the correct image loads automatically for that enemy when it spawns.

No code changes are needed unless a new zone or enemy slot type is added.

## Zone Background Image System

Zone backgrounds use a dedicated catalog separate from the general UI and enemy image systems.

- `scripts/ui/BackgroundAssetCatalog.gd` — static helpers for zone background paths and safe texture loading.
- `GameField.BackgroundImageHolder` — full-rect `ImageSlot` that displays the current zone background.
- Background changes automatically when `current_zone_index` changes (zone travel, prestige, save/load).

### Folder structure

```
res://assets/images/backgrounds/zone_XX/background.png
```

### Zone mapping

| Folder  | Levels | Zone name        |
|---------|--------|------------------|
| zone_01 | 1–10   | Training Grounds |
| zone_02 | 11–20  | Forest Path      |
| zone_03 | 21–30  | Stone Valley     |
| zone_04 | 31–40  | Shadow Camp      |

### Recommended image format

- Minimum: 720×1600 PNG or WebP
- Recommended: 1080×2400 (portrait 9:20)
- Keep important elements in the central 80% safe area
- No UI, text, or icons in the image

### Fallback chain

1. `backgrounds/zone_XX/background.png` — zone-specific background
2. `GameAssetCatalog "game.field_background"` — global default
3. Muted green `Color(0.25, 0.42, 0.25, 1)` placeholder

Missing files never crash the game.

### Adding a zone background

1. Place the PNG at `res://assets/images/backgrounds/zone_XX/background.png`.
2. Run the game — the background loads automatically when that zone is entered.

No code changes are needed.

## Web Export Notes

The project is intended for Yandex Games Web export. Keep the 720x1280 portrait setup, GL Compatibility renderer, and Web-friendly Control-based UI layout.

YandexBridge is present for future platform integration, but real ads, payments, cloud saves, cloud features, authentication, heroes, loot/items, and additional enemy systems should not be added until explicitly requested.

## Android Export Notes

An Android export preset is configured in `export_presets.cfg` targeting `arm64-v8a`. The export path is `../../godot_apk/narclick/naruto.apk`. No Android-specific APIs are used; the GL Compatibility renderer and Control-based UI are compatible with Android.

## BuildConfig and Release Checklist

`res://scripts/game/BuildConfig.gd` is registered as a global autoload and controls app version and debug/release visibility:

- `APP_VERSION: String = "0.1.0"` — displayed in SettingsWindow.
- `IS_DEBUG_BUILD: bool = true` — set to `false` before public release.

**Debug mode** (`IS_DEBUG_BUILD = true`):
- Shop shows the "Prototype: Get 50 Gems" button.
- SettingsWindow shows "Version 0.1.0-dev".
- F5/F9/F10 keyboard shortcuts (save/load/delete save) are active.

**Release mode** (`IS_DEBUG_BUILD = false`):
- Shop hides the Prototype Gems button; no empty spacing is left.
- SettingsWindow shows "Version 0.1.0".
- Keyboard debug shortcuts are disabled.

**Before public release:**
1. Set `IS_DEBUG_BUILD = false` in `BuildConfig.gd`.
2. Verify the Shop has no dev buttons.
3. Verify SettingsWindow shows the plain version string.
4. Export for Web and/or Android.

Real ads, payments, and cloud saves are still not implemented.
