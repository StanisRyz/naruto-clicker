# AGENTS.md

Development rules for AI coding agents working on this repository.

## Project Context

Naruto Clicker is a vertical idle/clicker game targeting Web / Yandex Games, with an Android export also configured. The project should stay small, stable, and easy to validate.

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
- Keep runtime player state and the public gameplay API in `scripts/game/ClickerState.gd`. Pure formulas live in `scripts/game/calculators/`. Task and shop runtime logic live in `scripts/game/runtime/`. Save serialization lives in `scripts/game/save/`. UI formatting lives in `scripts/game/presentation/`.
- Keep static game definitions (zone data, skill definitions, task definitions, shop products) in `scripts/game/config/`.
- Config files must contain only static data — no runtime player state, no SaveManager calls, no scene references.
- To add a new task, partner skill, or shop product, edit the matching config file in `scripts/game/config/`.
- Do not add new static data arrays to ClickerState.gd; put them in the appropriate config file instead.
- Numeric balance values (costs, DPS, multipliers) belong in BalanceConfig, not in config files.
- Save serialization (building/reading save dictionaries) lives in `scripts/game/save/ClickerStateSaveAdapter.gd`. Do not add save field logic to ClickerState or SaveManager directly.
- Save field names (keys in the save dictionary) are part of Save System v1 and must not be renamed without a migration.
- Pure formula logic (cost curves, milestone math, enemy scaling) lives in `scripts/game/calculators/`. Calculator files must be stateless — no runtime state, no SaveManager calls, no scene references. ClickerState delegates to them internally; public API stays in ClickerState.
- UI-facing formatting, description strings, skill state labels, and view-data builders live in `scripts/game/presentation/ClickerStatePresentation.gd`. It must not mutate ClickerState, trigger purchases, or change save data. UI panels call ClickerState public methods; ClickerState delegates to the presentation layer internally.
- Task runtime operations (initialization, progress tracking, reward calculation, claim/rotation, validation) live in `scripts/game/runtime/TaskRuntime.gd`. It reads and mutates ClickerState task fields through a passed `state: ClickerState` parameter. It must not call SaveManager, UI, or scene nodes. ClickerState owns the task state fields (active_task_ids, inactive_task_ids, active_task_states) for save compatibility. TasksWindow continues calling ClickerState public methods unchanged.
- Shop runtime behavior (Gems helpers, product lookup, purchase logic) lives in `scripts/game/runtime/ShopRuntime.gd`. Prototype-only — it must not implement real payments. It must not call SaveManager or UI nodes. ClickerState owns shop state fields (gems, boss_retry_tokens, task_reward_boost_multiplier) for save compatibility. ShopPanel continues calling ClickerState public methods unchanged.
- Keep `PrimaryStatsPanel`, `ProgressInfoPanel`, `GameField`, and `UpgradePanel` as focused UI components.
- Main screen primary stats and progress info are independent UI components; do not use a combined `StatsPanel` for new main screen UI.
- `PrimaryStatsPanel` shows only gold, Gems, character level, click damage, and partner DPS numeric stat cards.
- `PrimaryStatsPanel` is an independent compact top-centered overlay and should not be placed inside stretch containers.
- `PrimaryStatsPanel` should be centered on the viewport vertical axis and must not stretch full width.
- `PrimaryStatsPanel` uses horizontal stat cards from left to right in this order: gold, Gems, character level, click damage, partner DPS.
- Primary stat cards show only a temporary white `ColorRect` placeholder and the value; card backgrounds should stay transparent/invisible.
- `PrimaryStatsPanel` includes a white-square `SettingsButton` that opens `SettingsWindow`.
- `SettingsWindow` is a modal overlay with Sound and Music placeholder toggles, Save Now, and Reset Progress.
- Sound and Music toggles are persisted but do not affect audio yet because audio is not implemented.
- Reset Progress must require confirmation, delete the local save, reset all game progress, and save a fresh new-game state.
- The main screen does not use a general `StatusLabel`; status text may be ignored or routed through a no-op helper until a dedicated UI is requested.
- `ProgressInfoPanel` shows level, zone name, enemies progress, enemy name, enemy HP, and a compact enemy HP bar directly under the HP text.
- `ComboPanel` shows the runtime-only Manual Combo / Chakra Meter as a right-side vertically centered meter and should not be placed inside `PrimaryStatsPanel`, `ProgressInfoPanel`, `GameField`, bottom sheets, or bottom tabs.
- `TasksButton` is a textless white square directly above `ComboPanel`.
- `TasksWindow` shows exactly 5 active tasks from a repeatable pool of 10 total tasks, with the other 5 task ids inactive.
- Active tasks snapshot a baseline when activated; inactive tasks must not calculate or accumulate progress.
- Claiming a completed task gives dynamic gold, moves the claimed task back to the inactive pool, and activates one random inactive task with a fresh baseline.
- Claimed tasks can rotate back later; tasks must never be permanently exhausted.
- Level tasks are delta tasks such as "Reach 10 more levels", and hero level tasks use "Gain 10 Hero Levels".
- Task rewards use `current normal enemy reward * reward_scale`, include current zone reward scaling, and are recalculated when displayed or claimed.
- Task rewards must not include elite/boss reward multipliers, Boss Shrine, Market, Trade Routes, or Gold Bonus.
- Keep task definitions on `reward_scale` values rather than fixed `reward_gold` values.
- Tasks can be closed with the Close button or by clicking/tapping outside the task panel.
- `TasksWindow` is modal while open: it must block `GameField` attacks, consume inside-panel input, and consume the outside click/tap that closes it.
- Task claim refreshes must be deferred or otherwise input-safe so task rows are not rebuilt while the clicked Claim button is still handling input.
- Tasks do not add daily timers, ads, monetization, or new currencies yet.
- Gems are a prototype premium currency for runtime testing only; they are not connected to real Yandex payments.
- The Shop is the fifth bottom tab after Prestige and spends Gems on prototype gameplay rewards.
- Shop products are Small Gold Pack, Large Gold Pack, Instant Combo, Boss Retry, and Task Reward Boost.
- `Prototype: Get 50 Gems` is temporary/dev-only and must not be treated as a real payment flow.
- Boss Retry tokens automatically retry the same failed boss level once per token.
- Task Reward Boost doubles the next claimed task reward only once, then resets to x1.
- Gems, Boss Retry tokens, and Task Reward Boost are local-save prototype state until real payments/save integration are explicitly added.
- Do not add real payments, ads, authentication, or cloud save integration for Gems until explicitly requested.
- Only manual player clicks fill the combo meter. Autoclick and partner DPS must not fill it.
- Manual clicks add +1% meter charge, the meter decays by 1% per second, and every 1% meter charge gives +1% manual click damage only.
- At 100% meter charge, an empowered state starts: manual click damage is x3 for 10 seconds, the meter stays full during the state, and the meter resets to 0 when the state ends.
- Combo resets on prestige, is runtime-only, and must not be added to `ClickerState` persistence/state.
- Autoclick and partner DPS must not receive combo damage bonuses.
- Prestige and settlement details belong in their tabs, not on the main screen.
- Keep `UpgradePanel` responsible only for upgrade controls.
- Use `BottomBar` to open `UpgradeSheet`, `PartnerSheet`, `SettlementSheet`, and `PrestigeSheet`; do not keep sheet controls permanently in the main gameplay flow.
- BottomBar must remain visible and clickable while any bottom sheet is open.
- Opening a BottomBar tab should switch directly to that sheet without requiring the current sheet to close first.
- Clicking the currently active BottomBar tab should close its sheet, clear `active_bottom_tab`, and return bottom bar labels to normal.
- Keep `UpgradeSheet` to the bottom half of the screen so visible `GameField` space remains clickable while it is open.
- Bottom sheets must not cover BottomBar; they should end above it.
- Bottom sheet headers and close buttons should remain fixed while content scrolls vertically.
- `UpgradeSheet`, `PartnerSheet`, and `SettlementSheet` headers show a white `ImageHolder` placeholder and current gold beside the title.
- `PrestigeSheet` header shows a white `ImageHolder` placeholder and current available prestige points beside the title.
- `ShopSheet` header shows a white `ImageHolder` placeholder and current Gems beside the title.
- `PrestigePanel` should not show a separate `Prestige Points` label; available points belong in the `PrestigeSheet` header.
- `ShopPanel` should not show separate Gems, Boss Retry token, or Task Reward Boost summary rows; Boss Retry tokens and Task Reward Boost remain runtime mechanics.
- `BuyModeSelector` is the reusable UI for `x1`, `x10`, `x100`, and `Max` purchase modes.
- `BuyModeSelector` must stay fixed under the sheet header in `UpgradeSheet`, `PartnerSheet`, and `SettlementSheet`; purchase lists should scroll independently below it.
- `UpgradePanel` should use the same VBoxContainer-based root layout as `PartnerPanel`; do not use a full-rect Control wrapper that can overlap the fixed `BuyModeSelector`.
- In `UpgradeSheet`, `BuyModeSelector` affects only the Hero Level card; ability buy/upgrade actions must never use bulk-buy modes.
- Do not add `BuyModeSelector` to `PrestigeSheet`.
- Purchase tabs use card-style rows with a temporary white `ColorRect` image placeholder, right-side info rows, skill icons where applicable, and a full-height action button in its own right column.
- Keep `GameField` as the fullscreen bottom clickable layer in `ClickerScreen`.
- `GameField` uses a muted green `BackgroundImageHolder` placeholder and should not pulse or blink on click.
- `EnemyImageHolder` is a centered placeholder square: healthy white, hit blue for 0.3 seconds, wounded red, defeated black for 0.2 seconds.
- Blue hit feedback should only play for player-origin damage: manual clicks and Autoclick. Partner DPS should update HP/wounded state and defeat state, but should not turn the enemy blue.
- `GameField` should not display enemy name or HP text; those belong in `ProgressInfoPanel`.
- A 0.2 second enemy transition lock after defeat must keep enemy HP at 0 and block manual clicks, autoclick, and partner damage; reward, defeated count, level changes, and next enemy setup happen only after the lock ends.
- Keep visible UI overlays clickable above `GameField`, and make passive text/containers ignore mouse input.
- Keep `GameField` responsible only for tap/click input and simple visual feedback.
- Keep `AbilityBar` separate from `GameField` on the left-middle screen edge.
- Abilities must be purchased in `UpgradeSheet` before activation.
- AbilityBar buttons are placeholder ImageHolder-style controls: textless white squares until real icons are added.
- AbilityBar state should be represented by disabled/color feedback or optional tiny labels outside the square, not text inside the button.
- Active abilities are unlocked once through the large card button, then have passive ranks 0–5 from gold-purchased skill icons on the ability card. Prestige resets purchased abilities and passive ranks to 0.
- Ability skill purchases must never use BuyModeSelector; each skill icon purchase buys exactly one rank through `UpgradeSkillPopup`, and ClickerScreen routes purchases to `buy_ability_skill()`.
- Ability unlocks use the existing base costs; passive skill costs use `ability_skill_cost_multipliers`.
- Autoclick unlocks at character level 15, base cost 50 gold. Base: 20 hits/sec for 15 s, 60 s cooldown. Each passive rank adds +15% attack rate (via get_autoclick_rank_rate_multiplier()) and +2 s duration.
- Gold Bonus unlocks at character level 30, base cost 150 gold. Base multiplier is x2.00 plus +0.25 per passive rank, 45 s, 300 s cooldown.
- Focus Burst unlocks at character level 60, base cost 500 gold. Base multiplier is x2.00 plus +0.25 per passive rank, 20 s, 120 s cooldown.
- Rally unlocks at character level 80, base cost 1000 gold. Base multiplier is x2.00 plus +0.25 per passive rank, 30 s, 180 s cooldown.
- get_focus_burst_multiplier() and get_rally_multiplier() return rank-scaled values when active; get_gold_bonus_multiplier() does the same. All three return 1.0 when inactive.
- AbilityBar uses `is_ability_purchased(ability_id)` to determine purchased state; passive skill rank alone must not unlock activation.
- Make sure ability buttons do not trigger attacks.
- Partners provide passive DPS through `ClickerState` state and `ClickerScreen` ticking.
- Partner tiers are data-driven: Partner 1 (10 DPS), Partner 2 (20), Partner 3 (35), Field Scout (65), Spear Guard (120), Iron Defender (220), Battle Monk (410), Elite Samurai (750), Shadow Captain (1400), War Sage (2600), Beast Tamer (4800), Blade Master (9000), and Legendary Commander (16500).
- Partner initial costs are `[10, 50, 150, 400, 900, 1800, 3500, 7000, 14000, 28000, 56000, 110000, 220000]`.
- Partner costs use each tier's base and step values plus a controlled non-linear power curve.
- Partner milestone target counts `[10, 25, 50, 100, 250, 500]` cost x3 independently per tier.
- Hero and partner bulk-buy costs must include milestone price spikes when the package crosses milestone targets.
- Each partner tier requires at least one of the previous tier.
- Base partner DPS includes partner tiers and partner milestones only.
- Final partner DPS adds Command Aura, Training Camp, and Rally. UI should display final partner DPS without contextual Boss Hunter; partner damage ticks include Boss Hunter during boss fights.
- Partner damage ticks every 0.1 seconds for final partner DPS / 10 damage.
- Partner purchases use horizontal bulk mode buttons `x1`, `x10`, `x100`, and `Max`; displayed costs must show total package cost.
- Partner `x10` and `x100` purchases are strict all-or-nothing packages; `Max` buys as many as current gold allows.
- PartnerPanel should not show a Total DPS summary line above partner rows.
- PartnerPanel uses progressive reveal: show Partner 1, all currently available partner cards, and exactly one next locked requirement card; deeper locked cards stay hidden and should not take scroll space.
- Partner rows use three vertical info rows on the right: partner name/count/total tier DPS, per-purchase DPS plus next x2 milestone, then the partner skill icon.
- Partner row first lines show `Partner Name | Count | DPS X`, where DPS is this tier's total DPS contribution only.
- Partner row second lines show per-purchase DPS and next x2 milestone, formatted `+%d DPS | Next x2 at %d` or `+%d DPS | Max milestones`.
- Partner row second lines must not include `for each PartnerName`.
- Partner rows show a horizontal row of 5 small clickable skill ImageHolder icons (32×32) below the DPS/milestone line, not Partner Mastery text.
- Partner main ImageHolders stay square and visually fill the taller card; partner skill icons stay small fixed squares.
- Partner skills are purchasable gold upgrades, not automatic unlocks. Reaching the required partner count only makes the skill available to buy.
- Each partner has 5 purchasable skill icons that unlock at partner counts 10, 25, 50, 100, and 250. The 500 milestone is reserved for a future ultimate skill and must not be used for partner skills yet.
- Partner skill icon states are gray for locked, blue for available to buy, and white for purchased.
- Clicking any partner skill icon opens a compact non-modal popup with the skill name, description, required count, current count vs requirement, gold cost, and Buy button.
- Partner skill popup Buy button states: locked → disabled "Locked"; available but not enough gold → disabled "Buy: N"; available and affordable → enabled "Buy: N"; purchased → disabled "Purchased".
- Partner skill popups must fit content height and must not stretch vertically to the screen bottom.
- PartnerSkillPopup closes when clicking outside the popup panel and switches to the new skill when clicking another skill icon; clicking another icon must not just close the popup.
- PartnerSkillPopup uses _input (not an overlay ColorRect) for outside-close detection; _input calls hide() without consuming the event so skill icon buttons below still receive the click and emit their pressed signal in the same frame.
- PartnerSkillPopup root mouse_filter must be IGNORE (2); OutsideClickArea mouse_filter must be IGNORE (2); PanelContainer mouse_filter must be STOP (0).
- PanelContainer must consume mouse/touch events via _on_panel_container_gui_input so clicks inside the popup do not close it or fall through to GameField.
- PartnerSkillPopup panel sizing must be deferred after content changes (show_skill, refresh_view) by awaiting one process frame before reading combined minimum size to avoid first-open vertical stretching.
- Partner skill bonuses apply only after purchase and reset on prestige with normal partner progress.
- Skill categories and distribution:
  - Partner 1 (index 0) and Field Scout (index 3): bonus_type "click_damage" — Click Training I–V (+20%/+25%/+50%/+100%/+100%).
  - Spear Guard (index 4): bonus_type "partner_dps" — Team Command I–V (+25%/+40%/+60%/+60%/+100%) affecting total final Partner DPS.
  - Iron Defender (index 5): bonus_type "gold" — Gold Sense I–V (+25%/+50%/+50%/+50%/+50%) affecting gold rewards.
  - All other partners (indices 1, 2, 6–12): bonus_type "own_partner_dps" — Personal Mastery I–V (+50%/+50%/+50%/+100%/+100%) affecting only that partner tier's DPS via get_own_partner_skill_multiplier(partner_index).
- own_partner_dps bonuses must not be applied globally; they are multiplied per tier in get_partner_tier_total_dps and must never be passed to get_partner_skill_bonus_multiplier for global use.
- Skill costs use partner_skill_cost_multipliers [3, 5, 8, 12, 20] applied to the base milestone cost: _get_partner_cost_for_count(partner_index, unlock_count - 1) * multiplier[skill_level - 1].
- Skill IDs use the format "p{index}_s{level}" e.g. "p0_s1" through "p0_s5".
- Total/final Partner DPS belongs in `PrimaryStatsPanel`; partner rows may show only their own tier total DPS on the first line and per-purchase DPS plus next milestone info on the second line.
- PartnerPanel should always show the required package cost when prerequisites are met; "Not enough gold" belongs in status handling after a failed purchase, not in partner button text.
- Keep `PartnerSheet`, `SettlementSheet`, and `PrestigeSheet` as separate bottom-half overlays from `UpgradeSheet`.
- Settlement tab sits between `Partners` and `Prestige` in the bottom bar.
- Settlement buildings are Training Camp (+1% final partner DPS per level), Market (+1% final gold gain per level), Knight Hut (+1% final click damage per level), War Banner (+1% Focus Burst/Rally duration per level), Clock Tower (+1% cooldown efficiency per level), and Boss Shrine (+1% boss reward gold per level).
- Builder Wisdom increases settlement building bonus effectiveness.
- Training Camp affects displayed final Partner DPS and partner tick damage.
- Market affects normal, elite, and boss final gold gain.
- Knight Hut affects displayed click damage and manual/autoclick damage; manual combo stays in `ClickerScreen`.
- War Banner affects Focus Burst and Rally duration only when those abilities are activated.
- Clock Tower affects Autoclick, Gold Bonus, Focus Burst, and Rally cooldowns when cooldown starts using diminishing returns.
- Boss Shrine affects boss rewards only and stacks with Market, Trade Routes, and Gold Bonus.
- Settlement rows use a temporary white `ColorRect` image placeholder, two text lines for name/count and per-purchase effect, and a buy button.
- SettlementPanel should not show a combined settlement bonus summary line above building rows.
- SettlementPanel uses progressive reveal: show Training Camp, all currently available building cards, and exactly one next locked requirement card; deeper locked cards stay hidden and should not take scroll space.
- Settlement building rows show per-purchase effect and next x2 milestone, formatted like `+1% DPS | Next x2 at 10` or `+1% DPS | Max milestones`.
- Settlement building rows should not show total owned effect; total bonuses belong in stats or summary UI.
- Each settlement building requires at least one of the previous building.
- Settlement initial costs are `[25, 75, 150, 500, 1200, 3000]`.
- Settlement costs scale by adding `[25, 50, 100, 250, 600, 1500]` per owned building.
- Settlement purchases use bulk modes `x1`, `x10`, `x100`, and `Max` with the same strict all-or-nothing behavior as partners for `x10` and `x100`.
- Settlement buildings reset on prestige.
- Settlement buildings use independent milestone multipliers at `[10, 25, 50, 100, 250, 500]`.
- Each reached settlement building milestone doubles the total accumulated effect of that building type.
- Builder Wisdom applies after the settlement building milestone multiplier.
- Settlement effects use two scaling types: positive additive bonuses and diminishing reduction bonuses.
- Positive settlement bonuses can grow above 100%.
- Reduction bonuses use `final_multiplier = 100 / (100 + raw_bonus)` and must never reduce cooldowns, costs, or future timers to 0.
- Clock Tower uses cooldown efficiency through the diminishing formula. Future cost-reduction buildings must use the same helper.
- Character level replaces the old damage upgrade; base hero damage starts from character level and is boosted by hero milestones.
- Hero base damage is `character_level * hero milestone multiplier` before Focus Burst, settlement Knight Hut, prestige talents, combo manual multiplier, and Boss Hunter.
- Hero level and each partner tier use milestone levels `[10, 25, 50, 100, 250, 500]`.
- Each reached milestone doubles the total accumulated contribution of that source, applying to all owned levels rather than only future purchases.
- Hero and every partner tier track milestone multipliers independently.
- Partner tier base DPS is `owned count * tier DPS * tier milestone multiplier` before settlement Training Camp, prestige Command Aura, Rally, and Boss Hunter.
- Hero level upgrade costs use a controlled non-linear formula with affordable early levels and harder later levels.
- Hero milestone target levels `[10, 25, 50, 100, 250, 500]` cost x3 for the purchase that reaches the milestone.
- UpgradePanel cards match the Partner card structure and approximate sizes: large square `ImageHolder` on the left, right-side title/effect rows, a row of 5 small skill icons, and a full-height action button in its own right column.
- Hero Level first line shows `Hero Level | Level X | Damage Y`; the second line still shows damage plus next x2 milestone or max milestones.
- Hero Level keeps its bulk-buy button and BuyModeSelector behavior separate from hero skill purchases.
- Hero Level has 5 purchasable passive skill icons unlocked by character level.
- Ability cards are unlocked once through the main card button and then have 5 purchasable passive rank skill icons unlocked by character level.
- Upgrade skill icon states match partner skills: gray = locked, blue = available to buy, white = purchased.
- Ability activation is derived from the purchased flag; passive ability rank/effects are derived from purchased ability skill icons and require the ability to be purchased first.
- Hero skills and ability skills reset on prestige with normal progression.
- Character level upgrades use horizontal bulk mode buttons `x1`, `x10`, `x100`, and `Max`; displayed costs must show total package cost.
- Character level `x10` and `x100` purchases are strict all-or-nothing packages; `Max` buys as many as current gold allows.
- Autoclick base unlock cost is 50 gold; passive skill costs use ability skill cost multipliers.
- Gold Bonus base unlock cost is 150 gold; Focus Burst 500 gold; Rally 1000 gold.
- Treat economy formulas as prototype balance values.
- Autoclick unlocks at character level 15; Gold Bonus at 30; Focus Burst at 60; Rally at 80.
- Keep UI animation details out of `ClickerState`.
- Let `ClickerScreen` coordinate state results into UI feedback calls.
- Keep the main attack input on the `GameField` tap/click area, not a separate Attack button.
- Keep level progression simple: 10 enemies defeated per level, then advance the level.
- Keep every 10th level as a boss level with exactly one boss.
- Boss levels must use a 30 second timer and return to the previous level on failure.
- Each zone has three normal enemies, one elite enemy, and one boss.
- Normal enemies are randomly selected when each new non-boss target is created.
- Elite enemies have a 7% spawn chance on non-boss targets, count as one defeated enemy, have 3x normal HP, and give 5x normal base reward.
- Elite enemies must never appear on boss levels, and boss HP/reward behavior must remain boss-only.
- Scale enemy HP and gold reward by level with deterministic formulas.
- Prestige lives in a separate `PrestigeSheet` opened by the `PrestigeButton` bottom tab; do not keep prestige controls inside `UpgradeSheet`.
- PrestigePanel should stay compact; detailed prestige calculation belongs in the confirmation dialog, not the main PrestigePanel.
- PrestigePanel shows only a card-style prestige action and card-style talent rows.
- Prestige reward formula is `floor(current_level / 50) + floor(character_level / 100)` points.
- Prestige confirmation dialog (`PrestigeConfirmDialog`) is an overlay child of `PrestigeSheet` and must be fully opaque so underlying UI text is not visible through it.
- Signal flow: PrestigePanel `prestige_requested` -> PrestigeSheet `prestige_requested` -> ClickerScreen calls `show_prestige_confirm(state)`; dialog `confirmed` -> ClickerScreen calls `perform_prestige()`.
- `perform_prestige()` resets all normal progress except available prestige points, total earned prestige points, prestige talents, and `total_prestiges`.
- Prestige points are split into available points and total earned points; spending talents subtracts only from available points.
- Prestige points do not provide passive damage or gold bonuses by themselves; only purchased prestige talents provide prestige-related bonuses.
- Prestige talents are Focus Training (+5% click/autoclick damage per level), Trade Routes (+5% gold gain per level), Command Aura (+5% partner DPS per level), Quick Hands (+5% Autoclick attack rate per level, minimum interval 0.02 seconds), Builder Wisdom (+5% settlement bonus effectiveness per level), and Boss Hunter (+5% boss damage per level).
- Prestige talent next cost is `1 + current talent level`.
- Prestige reset does not reset prestige talents.
- Apply Focus Training prestige talent in `_update_character_state()` so `click_damage` reflects effective non-boss click damage.
- Apply Command Aura prestige talent in `get_final_partner_dps()`, and use contextual Boss Hunter only for partner tick damage against bosses.
- Raw prestige points do not provide passive gold bonuses; Trade Routes applies to gold gain, Boss Shrine applies only to boss reward gold, Market applies to normal/elite/boss rewards, and Gold Bonus doubles final reward while active.
- Zone data lives in `ZONE_DATA` const in `ClickerState.gd`; do not move it to separate files yet.
- Zones group levels 1–10, 11–20, 21–30, 31–40. Level 41+ stays in Zone 4.
- Zone HP multipliers: 1.0, 1.4, 1.9, 2.5. Zone reward multipliers: 1.0, 1.3, 1.7, 2.2.
- Apply zone multipliers after the base HP/reward formula, before the boss ×5 multiplier.
- Enemy formulas use `stage = current_level - 1`.
- Base HP formula is `10 + 8.0 * stage + 1.15 * stage^2.10`.
- Base reward formula is `5 + 3.0 * stage + 0.22 * stage^1.80`.
- HP grows faster than rewards so later progression leans on milestones, partners, settlement, prestige talents, and abilities.
- Elite and boss multipliers are applied after base level and zone scaling.
- Enemy, elite enemy, and boss names come from the active zone; do not hard-code "Enemy" or "Boss" strings.
- Zone transition is detected in `attack_with_damage()` and included in the result dict as `zone_changed` and `zone_name`.
- Status text priority on level-up: zone change > boss defeated > normal level up.
- No audio assets should be added for zones yet; audio is not implemented.
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
- Do not add ads, payments, cloud saves, cloud features, or authentication until explicitly requested.
- Make sure editor and desktop preview runs do not crash when Web-only APIs are unavailable.

## What Not To Add Yet

- Cloud save system
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
- UpgradeSheet header shows title, white `ImageHolder`, current gold, spacer, and Close button.
- SettlementSheet should match UpgradeSheet and PartnerSheet spacing between header, fixed `BuyModeSelector`, and scroll content.
- UpgradePanel uses Partner-style Hero Level and ability rows with white `ColorRect` image placeholders.
- Hero Level card shows the current character level and selected bulk upgrade cost.
- Hero Level card shows current damage and the next milestone, or Max milestones when all milestones are reached.
- Hero Level card shows exactly 5 small skill icon squares in a horizontal row.
- Ability cards show rank text and exactly 5 small skill icon squares in a horizontal row.
- Ability unlocks are purchased through the large card button; passive ranks are purchased through skill icons and the `UpgradeSkillPopup`.
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
- BottomBar has `Upgrades`, `Partners`, `Settlement`, `Prestige`, and `Shop` buttons on one row.
- Partner 1 starts at 10 gold.
- PartnerPanel uses card-style partner rows with white `ColorRect` image placeholders.
- PartnerSheet keeps `BuyModeSelector` fixed under the header while partner rows scroll.
- PartnerSheet header shows title, white `ImageHolder`, current gold, spacer, and Close button.
- With no partners bought, PartnerPanel shows Partner 1 and locked Partner 2 only.
- Partner 3 and deeper locked partner cards are hidden until revealed.
- After buying Partner 1, Partner 2 is available and locked Partner 3 appears.
- Partner 2 starts at 50 gold.
- Partner 3 starts at 150 gold.
- Partner 2 cannot be bought before at least one Partner 1.
- Partner 3 cannot be bought before at least one Partner 2.
- All 13 partner tiers are progressively revealed through scrolling and each tier requires the previous tier.
- Partner costs increase after purchase.
- Partner counts update after purchase.
- Total Partner DPS updates correctly.
- Partner rows show name/count, per-purchase DPS with next x2 milestone, and the 5-icon skill row as three vertical info rows.
- Partner main ImageHolders remain square and visually fill the taller card.
- Partner skill icons are small square (32×32) placeholders and do not stretch.
- Each partner card shows exactly 5 skill icon squares in a horizontal row.
- Locked skill icons are gray, available icons are blue, purchased icons are white.
- Partner rows show clickable partner skill icons, not Partner Mastery text.
- Partner skill popups show name, description, required count, current count vs required, gold cost, and Buy button without stretching vertically to the screen bottom.
- Skill 1 becomes available at partner count 10, skill 2 at 25, skill 3 at 50, skill 4 at 100, skill 5 at 250.
- Partner rows do not show accumulated tier DPS or total/final Partner DPS.
- Partner milestones apply independently per tier.
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
- Pressing the active BottomBar tab closes its current sheet.
- `AbilityBar` is a left-middle screen overlay.
- Ability buttons do not pulse with `GameField` feedback.
- Ability buttons do not attack the enemy.
- Ability buttons should not show text inside the square.
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
- Hero upgrade costs increase non-linearly over time.
- Hero target levels 10, 25, 50, 100, 250, and 500 cost x3.
- Hero x10, x100, and Max costs include milestone x3 price spikes.
- Partner x10 and x100 modes buy the full package or buy nothing if gold is insufficient.
- Partner Max buys as many partners as current gold allows.
- Partner costs increase non-linearly over time.
- Partner target counts 10, 25, 50, 100, 250, and 500 cost x3 independently per tier.
- Partner x10, x100, and Max costs include milestone x3 price spikes.
- Upgrade, Partner, and Settlement bulk mode UI uses horizontal buttons, not dropdowns.
- Settlement opens `SettlementSheet`.
- SettlementSheet header shows title, white `ImageHolder`, current gold, spacer, and Close button.
- Training Camp can be bought when enough gold.
- Market requires at least one Training Camp.
- Knight Hut requires at least one Market.
- With no settlement buildings bought, SettlementPanel shows Training Camp and locked Market only.
- Knight Hut and deeper locked building cards are hidden until revealed.
- After buying Training Camp, Market is available and locked Knight Hut appears.
- War Banner, Clock Tower, and Boss Shrine are progressively revealed through scrolling and follow the building chain requirement.
- Settlement x1, x10, x100, and Max modes work like partners.
- Settlement buttons always show required cost when prerequisites are met.
- Training Camp increases partner DPS/tick damage.
- Training Camp x10 with 200 base partner DPS displays 220 final Partner DPS.
- Training Camp x25 with 200 base partner DPS displays 400 final Partner DPS.
- Training Camp x100 with 200 base partner DPS displays 3400 final Partner DPS.
- Market increases gold rewards.
- Market affects normal, elite, and boss rewards.
- Knight Hut increases manual click and autoclick damage.
- Knight Hut x10 increases displayed click damage by about 20%.
- War Banner increases Focus Burst and Rally duration.
- War Banner x10 makes Focus Burst last about 24 seconds and Rally last about 36 seconds.
- Clock Tower reduces ability cooldowns with diminishing returns.
- Clock Tower x10 has 20 raw cooldown efficiency, making Autoclick cooldown about 50 seconds and Gold Bonus cooldown about 250 seconds.
- Clock Tower x25 has 100 raw cooldown efficiency, making ability cooldowns about half length but not 0.
- Boss Shrine increases boss reward gold.
- Boss Shrine does not change normal or elite rewards by itself.
- Target defeat gives gold.
- Defeating 10 enemies advances to the next level.
- Level text updates correctly.
- Enemies defeated counter updates correctly.
- Enemy HP and reward increase after level up.
- Levels 10, 20, 30, etc. are boss levels.
- Levels 5, 15, 25, etc. are normal non-boss levels.
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
- "Naruto Clicker" title label is gone from the main screen.
- StageNavigator appears at the top of MainContent showing 7 square buttons.
- Stage 1 / current stage button is blue on start.
- Locked future stages are gray and unclickable.
- Clicking a gray locked stage does nothing.
- Clicking the current blue stage does nothing.
- Clicking an unlocked white stage travels to that stage without granting gold.
- ProgressInfoPanel updates correctly after travel.
- Traveling to a previous boss level restarts the boss timer.
- Traveling to a non-boss level stops/clears the boss timer.
- Boss fail does not reduce max_unlocked_level.
- Prestige resets max_unlocked_level to 1.
- StageNavigator scroll left stops when stage 1 is leftmost visible.
- StageNavigator scroll right stops when rightmost visible is max_unlocked_level + 3.
- Manually scrolling left from current level does not snap the view back to current level.
- Player can scroll all the way back to stage 1 even when current level is high.
- Mouse wheel over StageNavigator scrolls the strip and does not attack the enemy.
- Dragging/swiping StageNavigator horizontally scrolls the strip without triggering stage travel.
- Drag right reveals earlier stages; drag left reveals later stages.
- StageNavigator clicks do not attack the enemy.
- Enemy transition lock blocks travel requests.
- Hero level 9 has damage 9 before other multipliers.
- Buying level 10 changes hero damage to 20.
- Hero level 25 changes hero damage to 100.
- Hero level 50 changes hero damage to 400.
- Hero bulk-buy updates milestone damage correctly.
- Partner 1 count 9 gives 90 DPS.
- Partner 1 count 10 gives 200 DPS.
- Partner 1 count 25 gives 1000 DPS.
- Partner 1 count 50 gives 4000 DPS.
- Partner 2 milestones are independent from Partner 1.
- Partner bulk-buy updates milestone DPS correctly.
- Partner tick damage uses milestone-boosted DPS.
- UI shows next milestone info for hero and partners.
- Level 1 starts in Training Grounds with a random normal enemy or a 7% elite enemy roll.
- Level 5 is a normal level.
- Level 10 boss is named "Training Master".
- Reaching level 11 transitions to Forest Path; ProgressInfoPanel shows "Forest Path" and defeat feedback shows "New Zone!".
- Level 11 uses one of the Forest Path normal enemies or its 7% elite enemy roll; level 15 boss is "Forest Guardian".
- ProgressInfoPanel updates zone name, enemy name, and enemy HP.
- ProgressInfoPanel shows zone name without the zone level range.
- ComboPanel appears on the right side, vertically centered.
- TasksButton appears directly above ComboPanel as a textless white square.
- TasksButton opens TasksWindow and does not attack the enemy.
- TasksWindow shows 5 unique active tasks and the inactive pool has the other 5 task ids.
- TasksWindow closes with Close button and outside-panel clicks.
- Clicking inside TasksWindow does not close it unless Close is pressed and does not attack the enemy.
- Clicking outside TasksWindow to close it consumes the click and does not attack the enemy.
- Clicking Claim works on the first click, gives gold once, and cannot double-claim from rapid clicking.
- Claim refreshes task rows only after button input handling is safe.
- Completed tasks have enabled Claim buttons, add dynamic level-scaled gold when claimed, move back to inactive, and are replaced by random inactive tasks.
- Claimed tasks can rotate back later with progress reset from a fresh activation baseline.
- Inactive tasks do not progress from past actions before activation.
- Task rewards scale from the current level's normal enemy reward plus zone reward multiplier, excluding elite/boss multipliers, settlement reward bonuses, prestige reward bonuses, Boss Shrine, and Gold Bonus.
- Manual damage task progresses only from manual click damage.
- Autoclick task progresses when Autoclick is activated.
- Combo task progresses when combo empowered state starts.
- Combo meter is vertical.
- Multiplier text is below the meter.
- Manual click increases meter by 1%.
- Meter decays by 1% per second.
- At 25% meter, manual click damage is approximately x1.25.
- At 50% meter, manual click damage is approximately x1.50.
- At 100% meter, empowered state starts.
- During empowered state, manual click damage is x3.
- Empowered state lasts 10 seconds.
- After empowered state ends, meter instantly resets to 0.
- Manual clicks do not refill meter during empowered state.
- Autoclick does not fill meter.
- Autoclick does not receive combo damage bonus.
- Partner DPS does not fill meter.
- Partner DPS does not receive combo damage bonus.
- Prestige resets combo meter and empowered state.
- ComboPanel updates correctly.
- HP and reward values are higher in later zones than the base formula alone.
- Zone defeat feedback shows "New Zone!" flash when zone changes.
- Prestige button is not visible inside UpgradeSheet.
- `PrestigeButton` opens `PrestigeSheet`.
- PrestigeSheet is hidden by default and can be closed.
- PrestigeSheet has no `BuyModeSelector`.
- PrestigeSheet header shows title, white `ImageHolder`, available prestige points, spacer, and Close button.
- `ShopButton` opens `ShopSheet` as the fifth bottom tab after Prestige.
- ShopSheet is hidden by default and can be closed.
- ShopSheet has no `BuyModeSelector`.
- ShopSheet header shows title, white `ImageHolder`, current Gems, spacer, and Close button.
- ShopPanel shows product cards and the temporary Gems button without separate Gems, Boss Retry token, or Task Reward Boost summary rows.
- `Prototype: Get 50 Gems` increases Gems and is temporary/dev-only.
- Shop product buttons are disabled when Gems are insufficient and enabled when affordable.
- Small Gold Pack and Large Gold Pack add stage-scaled gold.
- Instant Combo fills the combo meter and starts the empowered combo state.
- Boss Retry adds a token, and a failed boss consumes one token to retry the same boss level.
- Task Reward Boost doubles the next claimed task reward only once.
- Gems and shop reward state do not reset on prestige.
- PrestigePanel does not show a separate `Prestige Points` label.
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
- PrimaryStatsPanel and ProgressInfoPanel do not show Prestige points or total runs; prestige details belong in PrestigeSheet.
- After prestige, all timers (boss, autoclick, gold bonus, ability cooldowns, accumulators) are reset in ClickerScreen.

## Stage Navigator Rules

- `StageNavigator` replaces the "Naruto Clicker" `TitleLabel` in `MainContent/VBoxContainer`.
- It shows exactly 7 stage buttons (60×60 ImageSlot-backed squares) at a time.
- Button color states: blue = current stage, white = unlocked, gray = locked.
- Clicking an unlocked (white) stage emits `stage_selected(level)` and triggers `travel_to_level` in `ClickerScreen`.
- Clicking the current (blue) stage or a locked (gray) stage does nothing.
- `StageNavigator` clicks, wheel, and drag must not propagate to `GameField` and must not trigger attacks.
- There are no left/right step-scroll arrow buttons. The strip is scrolled only via mouse wheel and drag/swipe.
- To the right of the 7 stage buttons: a **latest button** (`>>`, yellow) and an **auto-transition button** (`A`, green/gray).
- The latest button emits `latest_requested`; `ClickerScreen` responds by calling `stage_navigator.center_on_latest_level()`.
- The auto-transition button emits `auto_transition_popup_requested(anchor_global_position: Vector2, button_global_rect: Rect2)` with its own global position; `ClickerScreen` immediately toggles `auto_stage_advance_enabled`, updates the navigator color, and opens `AutoTransitionPopup` as an info popup.
- `center_on_latest_level()` sets `visible_center_level = max_unlocked_level`, clamps, and refreshes.
- `set_auto_transition_enabled(enabled)` updates `_auto_btn_rect.color`: green when ON, gray when OFF.
- `max_unlocked_level` in `ClickerState` tracks the highest stage naturally reached.
- `max_unlocked_level` updates with `maxi(max_unlocked_level, current_level + 1)` when stage objective is cleared in `resolve_defeated_target()`, regardless of `auto_stage_advance_enabled`.
- Only `current_level + 1` is ever unlocked per clear; farming the same cleared level cannot unlock levels beyond the immediately next one.
- `max_unlocked_level` is not reduced by traveling backward, boss fail, or anything other than prestige.
- `max_unlocked_level` resets to 1 on prestige alongside `current_level`.
- `can_travel_to_level(level)` returns true when `level >= 1` and `level <= max_unlocked_level`.
- `travel_to_level(level)` sets `current_level`, resets `enemies_defeated_on_level` to 0, calls `setup_current_level()`, and returns a result dict with `"travelled": true`.
- Traveling does not grant gold, does not count defeated enemies, and does not modify character/partner/settlement/prestige state.
- After travel in `ClickerScreen._on_stage_selected`: reset `partner_damage_accumulator` and `autoclick_accumulator`, increment `enemy_transition_token`, then call `_sync_boss_timer()`, `_update_ui()`, and `game_field.update_view(state)`. Do NOT call `center_on_level` after manual travel.
- After prestige in `ClickerScreen._on_prestige_confirmed`: call `stage_navigator.center_on_level(1)` before `_update_ui()`.
- `update_view(current_level, max_unlocked_level)` must NOT auto-snap `visible_center_level` on every call. It sets the center only once via the `_has_initialized_view` guard, then only clamps and refreshes.
- `center_on_level(level)` is called ONLY when the player actually advances to a new level via gameplay: when `resolve_defeated_target()` returns `advanced_to_next_level: true`, ClickerScreen calls `stage_navigator.center_on_level(state.current_level)`.
- `ClickerScreen._update_ui()` calls `stage_navigator.update_view(state.current_level, state.max_unlocked_level)` and `stage_navigator.set_auto_transition_enabled(state.auto_stage_advance_enabled)`.
- Drag threshold for scroll step is 36 px; drag movement threshold to suppress button click is 8 px.
- Dragging must not accidentally emit `stage_selected`; the `_drag_moved` flag suppresses button presses when drag distance exceeds the movement threshold.
- Mouse wheel is handled via `_gui_input` with `accept_event()` to prevent wheel events from reaching `GameField`.
- Drag is tracked via `_input` using `get_global_rect().has_point` to restrict drag initiation to the navigator area.

## Auto-transition Rules

- `ClickerState.auto_stage_advance_enabled: bool = true` — saved locally, not reset on prestige.
- `set_auto_stage_advance_enabled(enabled)` is the only setter.
- When `auto_stage_advance_enabled` is ON and `resolve_defeated_target()` detects `did_level_up`: `current_level += 1`, `setup_current_level()`, returns `advanced_to_next_level: true`.
- When `auto_stage_advance_enabled` is OFF and `resolve_defeated_target()` detects `did_level_up`: next level is unlocked (`max_unlocked_level` updated), `enemies_defeated_on_level = 0`, `setup_current_level()` resets the same level's target for farming, returns `advanced_to_next_level: false`.
- Reward gold is always granted on defeat regardless of auto-transition setting.
- `resolve_defeated_target()` result always includes `advanced_to_next_level: bool`, `level_unlocked: bool`, `unlocked_level: int`.
- Boss defeated with auto OFF: boss target resets, boss timer restarts via `_sync_boss_timer()` in `_finish_enemy_transition_after_delay`.
- Task counters (`total_enemies_defeated`, `total_bosses_defeated`, etc.) are always incremented regardless of auto-transition.
- `game_level_delta` tasks track `current_level`; farming the same level with auto OFF does not advance these tasks.
- `AutoTransitionPopup` is a full-screen Control overlay (mouse_filter STOP when visible, PASS when hidden). The inner PanelContainer has mouse_filter STOP. Outside clicks close the popup via `_gui_input` checking `_panel.get_global_rect().has_point`.
- The popup is info-only: it shows current ON/OFF status and has only a close button. There is no toggle button inside the popup.
- Pressing the `A` button triggers `ClickerScreen._toggle_auto_transition_and_show_popup()`, which immediately toggles `auto_stage_advance_enabled`, calls `stage_navigator.set_auto_transition_enabled()`, `_update_ui()`, and then opens the popup.
- Popup signals: `auto_button_pressed_through(anchor: Vector2, button_global_rect: Rect2)` — emitted when the user clicks the `A` button area while the popup is already visible, re-triggering the same toggle+show flow.

## Image Asset System Rules

- `scripts/ui/GameAssetCatalog.gd` is the single source of truth for all image slot keys and file paths.
- `scripts/ui/ImageSlot.gd` is the reusable component that replaces ColorRect image placeholders.
- `ImageSlot extends ColorRect` — it is a drop-in replacement with identical layout behavior.
- Every ImageHolder-style placeholder (ColorRect used as an image slot) must be converted to `ImageSlot`.
- Do not hardcode image paths in UI panels or scenes; always register keys in `GameAssetCatalog.ASSET_PATHS`.
- Missing image files must never crash the game; `ImageSlot` falls back to `fallback_color` when the file is absent.
- Keep placeholder fallback colors in place until final art is ready.
- To add a new image slot: add the key/path to `ASSET_PATHS`, create the `ImageSlot` node, set `asset_key`.
- Use the catalog helper methods for dynamic keys: `partner_icon_key`, `partner_skill_key`, `ability_skill_key`, `hero_skill_key`, `building_icon_key`, `prestige_talent_icon_key`, `shop_product_icon_key`, `task_icon_key`.
- In scripts that create `ImageSlot` dynamically, use `const ImageSlotClass = preload("res://scripts/ui/ImageSlot.gd")` to avoid relying on class_name indexing in the LSP. Do NOT add `const GameAssetCatalog = preload(...)` — `GameAssetCatalog` is a global class_name and a local const with the same name causes SHADOWED_GLOBAL_IDENTIFIER warnings.
- Skill icon fallback colors must still reflect state: gray = locked, blue = available, white = purchased. Use `set_fallback_color(color)` instead of `.color = color` on `ImageSlot` nodes.
- Enemy state asset keys (GameAssetCatalog defaults): `enemy.default.healthy`, `enemy.default.hit`, `enemy.default.wounded`, `enemy.default.defeated`. These are fallbacks only — `GameField` now loads per-enemy textures via `EnemyAssetCatalog` first.
- Stage navigator slot keys: `stage.current`, `stage.unlocked`, `stage.locked`, `stage.latest`, `stage.auto_on`, `stage.auto_off`.
- Sheet header slot keys: `header.gold` (Upgrade/Partner/Settlement), `header.prestige_points` (Prestige), `header.gems` (Shop).
- Asset image files go under `res://assets/images/` and its subdirectories, which already exist.
- Do not add `.gdignore` to asset image directories.

## Enemy Image System Rules

- `scripts/ui/EnemyAssetCatalog.gd` is the dedicated catalog for per-enemy, per-state image paths. It is separate from `GameAssetCatalog` because enemy images scale with zones and enemy counts.
- Every enemy has 4 visual state images: `healthy.png`, `hit.png`, `wounded.png`, `defeated.png`.
- Folder structure: `res://assets/images/enemies/zone_XX/enemy_YY/state.png`.
- Zone folders are 1-based: zone index 0 → `zone_01`, zone index 1 → `zone_02`, etc.
- Normal enemy folders are 1-based by ZONE_DATA enemies array index: enemy_index 0 → `enemy_01`, 1 → `enemy_02`, 2 → `enemy_03`.
- Elite enemy folder: `elite_01`. Boss enemy folder: `boss_01`.
- `ClickerState` stores `current_enemy_zone_index` (int) and `current_enemy_slot` (String) set in `choose_enemy_for_current_level()`. These are runtime-only; do not save them.
- `GameField` reads `state.current_enemy_zone_index` and `state.current_enemy_slot` and calls `EnemyAssetCatalog.load_enemy_texture()`.
- Fallback chain in `GameField._load_enemy_tex_with_fallback()`:
  1. Try exact enemy image via `EnemyAssetCatalog.load_enemy_texture(zone_index, enemy_slot, state)`.
  2. If null, try default via `GameAssetCatalog.load_texture("enemy.default." + state)`.
  3. If null, `set_direct_texture(null, fallback_color)` shows the placeholder color.
- `GameField` caches textures per enemy identity (`_cached_zone_index`, `_cached_enemy_slot`). Textures are reloaded only when the enemy changes, not every frame.
- `ImageSlot.set_direct_texture(texture, fallback_color)` applies a pre-loaded Texture2D directly without going through `GameAssetCatalog`.
- Hit feedback still only triggers for manual clicks and Autoclick — not partner DPS.
- Partner DPS must not show the hit (blue) state.
- Defeated state shows during transition lock regardless of enemy identity.
- Missing enemy image files must never crash the game.
- Do not hardcode enemy image paths in `GameField`; all path logic belongs in `EnemyAssetCatalog`.
- Do not save `current_enemy_slot` or `current_enemy_zone_index` to the save file; they are re-derived on each `choose_enemy_for_current_level()` call.
- When adding a new zone, add its folder under `res://assets/images/enemies/` and extend zone data in `ClickerState.ZONE_DATA`.

## Background Image System Rules

- `scripts/ui/BackgroundAssetCatalog.gd` is the dedicated catalog for zone background image paths. It is separate from `GameAssetCatalog` and `EnemyAssetCatalog`.
- Folder structure: `res://assets/images/backgrounds/zone_XX/background.png`.
- Zone folders are 1-based: zone index 0 → `zone_01`, zone index 1 → `zone_02`, etc.
- `BackgroundAssetCatalog.load_zone_background(zone_index)` returns `Texture2D` or `null`. Never crashes on missing files.
- Fallback chain: zone background → `GameAssetCatalog "game.field_background"` → muted green `Color(0.25, 0.42, 0.25, 1)`.
- `GameField.BackgroundImageHolder` is an `ImageSlot` with `stretch_mode = STRETCH_KEEP_ASPECT_COVERED` and `mouse_filter = IGNORE`.
- `GameField._update_background_visual(state)` is called from `update_view(state)`. It caches the zone index in `_cached_background_zone_index` and only reloads when the zone changes.
- Background uses `set_direct_texture(texture, BACKGROUND_FALLBACK_COLOR, false)` — transparent behind texture when image exists, muted green when image is missing.
- `ClickerState.get_current_zone_index()` is the public helper used by `GameField` for zone-index-to-background mapping.
- Do not hardcode background paths in `GameField`; all path logic belongs in `BackgroundAssetCatalog`.
- Missing background files must never crash the game.
- When adding a new zone, add its folder under `res://assets/images/backgrounds/` and extend zone data in `ClickerState.ZONE_DATA`.
- Do not add `const BackgroundAssetCatalog = preload(...)` in `GameField` — `BackgroundAssetCatalog` is a global class_name and a local const with the same name causes `SHADOWED_GLOBAL_IDENTIFIER` warnings. The LSP "not declared" error after creating the file is transient and resolves when Godot rescans `scripts/ui/`.
- Recommended image size: 720×1600 minimum, 1080×2400 recommended, portrait 9:20 safe.

## BalanceConfig Rules

`BalanceConfig` lives at `res://scripts/game/BalanceConfig.gd`. It is a plain `class_name` script (not an autoload). Reference it directly as `BalanceConfig.X` — do **not** add a local `const BalanceConfig = preload(...)`, as that shadows the global class name and produces `SHADOWED_GLOBAL_IDENTIFIER` warnings in Godot 4.5.1.

- All economy numbers belong in `BalanceConfig`. Do not scatter magic numbers across `ClickerState`.
- `ClickerState` reads BalanceConfig scalars at field initialisation time via `var x = BalanceConfig.X`.
- Large arrays (`PARTNER_DPS_VALUES`, skill definitions, etc.) are documented in `BalanceConfig` but kept as typed literals in `ClickerState` to avoid typed-array conversion risk.
- Do not add runtime mutable state to `BalanceConfig` — consts only.
- See `docs/BALANCE.md` for the full tuning guide.

## ProgressionSimulator Rules

`ProgressionSimulator` lives at `res://scripts/game/ProgressionSimulator.gd`. It is debug-only tooling.

- It creates a local `ClickerState` instance and simulates progression without touching `SaveManager` or the real player save.
- It is only invoked from `ClickerScreen._run_balance_simulation()`, which is guarded by `BuildConfig.IS_DEBUG_BUILD`.
- Press **F8** in debug mode to print progression tables to the Godot console and export `user://balance_simulation.csv`.
- Do not expose the simulator in any player-facing UI.
- See `docs/BALANCE.md` for output format and tuning workflow.

## BuildConfig Rules

`BuildConfig` is a global autoload registered in `project.godot`. It lives at `res://scripts/game/BuildConfig.gd`.

- `APP_VERSION` — the human-readable version string shown in SettingsWindow.
- `IS_DEBUG_BUILD` — controls all dev-only visibility. Do not rely on `OS.is_debug_build()` for this purpose: Web and Android test builds need manual control.

**Debug mode** (`IS_DEBUG_BUILD = true`):
- Shop `TestGemsButton` ("Prototype: Get 50 Gems") is visible.
- SettingsWindow version label reads "Version X.Y.Z-dev".
- `ClickerScreen._input` F5/F9/F10 debug shortcuts are active.

**Release mode** (`IS_DEBUG_BUILD = false`):
- `TestGemsButton` is hidden; VBoxContainer layout collapses the gap automatically.
- SettingsWindow version label reads "Version X.Y.Z".
- All keyboard debug shortcuts are disabled.

**Rules:**
- Do not remove `_on_test_gems_requested` or the `test_gems_requested` signal — they are used during development.
- Do not add new debug tools without wrapping them in `if BuildConfig.IS_DEBUG_BUILD`.
- Before public release, set `IS_DEBUG_BUILD = false` and verify no dev UI is visible.
- Real ads, payments, and cloud saves are still not implemented.

## Documentation Update Rules

Update this file when adding important systems, scenes, architecture decisions, workflow rules, or validation requirements. Keep README.md aligned with major project setup or workflow changes.
