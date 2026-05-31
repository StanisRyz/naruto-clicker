# Balance Tuning Guide

---

## Zone Content Patch v2 (2026-05-31)

Corrected ZoneConfig from 20 zones to 21 zones (levels 1–210). Inserted new Zone 6 "Scorched Outpost" after Zone 5, shifting old zones 6–20 to new zones 7–21. Corrected asset reuse mapping across all zones.

### Zone coverage

- Zones 1–5: levels 1–50 (unchanged)
- Zone 6: levels 51–60 (new — Scorched Outpost, reuses zone 5 assets)
- Zones 7–21: levels 61–210 (shifted from old zones 6–20)
- Each zone covers 10 levels; boss on every 10th level (unchanged).
- Level 211+ safely clamps to the last zone (zone 21) via existing fallback behavior.

### Zone hp/reward multipliers

| Zone | Levels  | hp_multiplier | reward_multiplier |
|------|---------|---------------|-------------------|
| 1    | 1–10    | 1.0           | 1.0               |
| 2    | 11–20   | 1.4           | 1.3               |
| 3    | 21–30   | 1.9           | 1.7               |
| 4    | 31–40   | 2.5           | 2.2               |
| 5    | 41–50   | 3.2           | 2.8               |
| 6    | 51–60   | 3.6           | 3.1               |
| 7    | 61–70   | 4.2           | 3.6               |
| 8    | 71–80   | 5.1           | 4.3               |
| 9    | 81–90   | 6.3           | 5.2               |
| 10   | 91–100  | 7.7           | 6.2               |
| 11   | 101–110 | 9.3           | 7.4               |
| 12   | 111–120 | 11.1          | 8.7               |
| 13   | 121–130 | 13.1          | 10.1              |
| 14   | 131–140 | 15.3          | 11.7              |
| 15   | 141–150 | 17.7          | 13.4              |
| 16   | 151–160 | 20.3          | 15.2              |
| 17   | 161–170 | 23.1          | 17.1              |
| 18   | 171–180 | 26.1          | 19.1              |
| 19   | 181–190 | 29.3          | 21.2              |
| 20   | 191–200 | 32.7          | 23.4              |
| 21   | 201–210 | 36.3          | 25.7              |

These are first-pass content scaling values. Global enemy HP/reward formulas were not changed.

### Asset reuse

Normal and elite enemy textures and backgrounds are shared across zones. See `docs/ASSET_MAP.md`.
Boss textures are unique per gameplay zone (21 unique boss folders required).

### Intentionally not changed

- Global enemy HP/reward formulas (`ENEMY_HP_BASE`, `ENEMY_HP_GROWTH`, etc.)
- Save format and save_version
- Public ClickerState API (two helpers added: `get_current_background_zone_index()`, plus ZoneConfig helpers)
- UI layout
- Boss every 10th level logic
- Android/Web export settings

---

## Zone Content Patch v1 (2026-05-31)

Extended ZoneConfig from 4 zones (levels 1–40) to 20 zones (levels 1–200). Superseded by Patch v2 above.

---

---

## Partner & Settlement Economy Pass v1 (2026-05-31)

Latest session: ~7m 10s, level 40, 94% kill income, 5% task income, avg TTK 0.62s, boss TTK 6.6s, 0 boss fails, 0 abilities used.

### Diagnosis

- Partner 1 had too much DPS for its cost — made manual clicks irrelevant early.
- Repeated Partner 1 purchases created a fast idle DPS snowball.
- Later partners were not proportionally attractive vs massing Partner 1.
- Settlement buildings were cheap relative to their % bonuses once partner DPS scaled.

### Changes made

**Partner DPS values** — reshaped to shift value toward mid/late partners:

| Tier | Old DPS | New DPS |
|------|---------|---------|
| 1 | 10 | 4 |
| 2 | 20 | 12 |
| 3 | 35 | 30 |
| 4 | 65 | 70 |
| 5 | 120 | 150 |
| 6 | 220 | 320 |
| 7 | 410 | 680 |
| 8 | 750 | 1,450 |
| 9 | 1,400 | 3,100 |
| 10 | 2,600 | 6,600 |
| 11 | 4,800 | 14,000 |
| 12 | 9,000 | 30,000 |
| 13 | 16,500 | 64,000 |

**Partner base costs** — raised across the board:

| Tier | Old | New |
|------|-----|-----|
| 1 | 10 | 35 |
| 2 | 50 | 110 |
| 3 | 150 | 300 |
| 4 | 400 | 750 |
| 5 | 900 | 1,700 |
| 6 | 1,800 | 3,800 |
| 7 | 3,500 | 8,500 |
| 8 | 7,000 | 19,000 |
| 9 | 14,000 | 43,000 |
| 10 | 28,000 | 96,000 |
| 11 | 56,000 | 215,000 |
| 12 | 110,000 | 480,000 |
| 13 | 220,000 | 1,050,000 |

**Partner cost growth** — slightly steeper:

| Constant | Old | New |
|----------|-----|-----|
| `PARTNER_COST_GROWTH_EARLY` | 1.10 | 1.12 |
| `PARTNER_COST_GROWTH_MID` | 1.13 | 1.145 |
| `PARTNER_COST_GROWTH_LATE` | 1.16 | 1.17 |

**Settlement building base costs** — raised to match % bonus value:

| Building | Old | New |
|----------|-----|-----|
| Training Camp | 25 | 500 |
| Market | 75 | 750 |
| Knight Hut | 150 | 1,000 |
| War Banner | 500 | 1,800 |
| Clock Tower | 1,200 | 2,600 |
| Boss Shrine | 3,000 | 4,000 |

**Building cost growth**: 1.18 → **1.22**

### Intentionally not changed

- Partner count, names, IDs, skill IDs, milestone levels.
- Building names, bonus types, effect per level (+1%/level).
- Enemy HP/reward curves.
- Task reward scales.
- Hero cost growth, ability costs/durations, combo, shop, prestige.

### Target metrics for next test

- Manual clicks should remain relevant for the first several minutes.
- Partner DPS should grow more gradually.
- Later partner unlocks should feel attractive vs massing early ones.
- Settlement buildings should feel like a mid-game investment.
- Level ~25–35 in 7–10 minutes of almost-idle play.

---

## Balance Adjustment Pass v2 (2026-05-31)

Second real playtest after Pass v1. Same setup: fresh save, almost idle, ~8 minutes.

### Playtest results

| Metric | Pass v1 baseline | This session |
|--------|-----------------|--------------|
| Session duration | ~4m 20s | ~8m 8s |
| Highest level | 62 | 60 |
| Enemies killed | 562 | 556 |
| Bosses killed / fails | 6 / 0 | 16 / 0 |
| Avg enemy TTK | 0.449s | 0.622s |
| Avg boss TTK | 1.780s | 9.387s |
| Task income share | 58% | 12% |
| Kill income share | 41% | 87% |
| Abilities used | 0 | 0 |

### Diagnosis

- Task nerf from Pass v1 worked — income share dropped from 58% to 12%.
- Boss friction is healthy — TTK jumped from 1.78s to 9.4s.
- Overall pace still too fast: level 60 in ~8 minutes from fresh save.
- Curve shape is the problem: early levels vanish too quickly, flat nerf would hurt late game.
- Fix: raise HP base to slow early game, lower HP growth to ease level 50+.

### Changes made

| System | Constant | Old | New |
|--------|----------|-----|-----|
| Enemy HP | `ENEMY_HP_BASE` | 10.0 | 18.0 |
| Enemy HP | `ENEMY_HP_GROWTH` | 1.18 | 1.165 |
| Enemy reward | `ENEMY_REWARD_BASE` | 5.0 | 4.0 |
| Enemy reward | `ENEMY_REWARD_GROWTH` | 1.11 | 1.115 |

Expected effect:
- Level 1–10: noticeably slower (higher base HP).
- Level 20–40: controlled.
- Level 50+: slightly smoother than Pass v1 (lower growth rate).
- Early kill gold: slightly lower (lower reward base).
- Later kill gold: recovers slightly (slightly higher reward growth).

### Intentionally not changed

- `BOSS_HP_MULTIPLIER` / `BOSS_REWARD_MULTIPLIER` — boss TTK is healthy at ~9s.
- Task reward scales — 12% income share is within the 10–25% target.
- Hero / partner cost growth — isolate one lever at a time.
- Abilities, shop, prestige — still no evidence to act on.

### Target metrics for next test

- 5-min almost-idle highest level: ~25–40 (was 60).
- Early enemy TTK (level 1–5): more noticeable, not near-instant.
- Task income share: remain 10–25%.
- Boss TTK: remain meaningful (~5–15s range).
- Level 50+ pacing: slightly smoother than Pass v1.

### Next step

Repeat the same 5-minute almost-idle session from a fresh save. Export CSV. Run analyzer. Compare.

---

## Balance Adjustment Pass v1 (2026-05-31)

First real 5-minute almost-idle playtest from fresh save. No debug gems.

### Playtest results

| Metric | Value |
|--------|-------|
| Session duration | ~4m 20s |
| Highest level | 62 |
| Total enemies killed | 562 |
| Bosses killed / fails | 6 / 0 |
| Avg enemy TTK | 0.449s |
| Avg boss TTK | 1.780s |
| Kill income share | 41% |
| Task income share | 58% |
| Shop income share | 0% |

### Diagnosis

- Tasks dominated income at 58% — reward scales were far too high.
- Bosses were not meaningful checkpoints — 6 kills, 0 fails, avg 1.78s TTK.
- Enemy HP scaling was too soft — level 60 enemies died in under 0.5s.
- Hero and partner costs ramped too slowly, enabling runaway DPS.
- Abilities were never needed because idle DPS was sufficient.

### Changes made

| System | Constant | Old | New |
|--------|----------|-----|-----|
| Enemy HP | `ENEMY_HP_GROWTH` | 1.14 | 1.18 |
| Boss HP | `BOSS_HP_MULTIPLIER` | 8 | 20 |
| Boss reward | `BOSS_REWARD_MULTIPLIER` | 10 | 15 |
| Hero cost (early) | `HERO_COST_GROWTH_EARLY` | 1.05 | 1.08 |
| Hero cost (mid) | `HERO_COST_GROWTH_MID` | 1.10 | 1.13 |
| Hero cost (late) | `HERO_COST_GROWTH_LATE` | 1.15 | 1.18 |
| Partner cost (early) | `PARTNER_COST_GROWTH_EARLY` | 1.07 | 1.10 |
| Partner cost (mid) | `PARTNER_COST_GROWTH_MID` | 1.10 | 1.13 |
| Partner cost (late) | `PARTNER_COST_GROWTH_LATE` | 1.13 | 1.16 |
| Task reward scales | (all 10 tasks) | 20–120 | 4–16 |

### Intentionally not changed

- Abilities — not used in test; need friction first before tuning them.
- Shop — contributed 0% income; no evidence to act on.
- Prestige — session too short; prestige not yet reached.
- `PARTNER_DPS_VALUES` — slowing purchase cost is the correct first lever.
- `ENEMY_HP_BASE` — growth change affects later levels more; base left at 10.
- Boss timer, boss fail/retry behavior, boss frequency — unchanged.

### Target metrics for next test

- 5-min almost-idle highest level: ~15–25 (was 62).
- Task income share: ≤25% (was 58%).
- Avg enemy TTK: 0.8–2.0s (was 0.449s).
- Early boss TTK: ≥5s (was 1.78s).
- Some friction visible before level 30–40.

### Next step

Repeat the same 5-minute almost-idle session from a fresh save. Export CSV. Run analyzer. Compare against the metrics above.

---

All economy coefficients live in `res://scripts/game/BalanceConfig.gd`.
Change a value there; calculators and runtime services pick it up automatically.
Do not edit formula vars directly in ClickerState.gd.

---

## Balance Playtest Toolkit v1 (implemented 2026-05-31)

Local debug telemetry. Records actual gameplay events during a real play session.
This is NOT the progression simulator (F8). This is real-play data.

**No data leaves the device. Release builds (`IS_DEBUG_BUILD = false`) disable everything.**

### CSV output

`user://balance_playtest.csv` — written on demand with F6.

On Windows: `%APPDATA%\Godot\app_userdata\naruto-clicker\balance_playtest.csv`

### Debug keys

| Key | Action |
|-----|--------|
| F6 | Export balance CSV |
| F7 | Print session summary to Godot output |
| F11 | Clear logger and restart session |

(F5 = save, F8 = simulator, F9 = load, F10 = delete save — unchanged)

### Event types logged

`session_start`, `enemy_defeated`, `boss_failed`, `purchase`, `task_claimed`, `ability_used`, `level_changed`

### Key metrics in CSV

- `enemy_ttk_sec` — time-to-kill, the primary pacing signal
- `was_boss` — filter boss vs normal TTK
- `defeated_on_level` — the level the enemy was on (reliable even when auto-transition fires)
- `boss_hp_remaining` — how close the player was when the boss timer ran out
- `purchase_category` — hero_level / partner / building / shop / prestige_talent / etc.
- `gold_earned_on_level`, `level_time_sec` — stage pacing signals

### How to use for tuning

1. Play a 30-minute session from a fresh save.
2. Press F6 to export.
3. Open CSV in Excel / Python / Google Sheets.
4. Plot `enemy_ttk_sec` over `timestamp_sec` — should trend gently upward.
5. Look at boss rows: TTK should be 3–8× normal at the same level.
6. Check purchase gaps: long gaps with no purchases signal friction walls.
7. Compare task/shop gold share against kill income.
8. Adjust one constant at a time in BalanceConfig; re-run a fresh session.

Full playtest guide: `res://docs/BALANCE_PLAYTEST.md`

---

## Active Systems & Friction Pass v1 (implemented 2026-05-31)

Goals:
- Centralize all ability duration, cooldown, and combo constants into BalanceConfig
- Tune ability timings to match design identity (early helper vs farming vs boss tool vs DPS burst)
- Tune combo decay to require active play for empowered state
- Confirm boss friction, settlement, prestige, and task/shop values are consistent

### Ability timing constants

All durations and cooldowns are now defined in BalanceConfig and read by ClickerScreen.

| Ability | Duration | Cooldown | Rank bonus | Multiplier formula |
|---------|----------|----------|------------|-------------------|
| Autoclick | 15s base | 90s | +2s/rank | rate ×(1 + 0.15×rank) |
| Gold Bonus | 30s | 180s | — | 2.0 + 0.25×rank |
| Focus Burst | 12s | 120s | War Banner | 2.0 + 0.25×rank |
| Rally | 20s | 150s | War Banner | 2.0 + 0.25×rank |

Ability identity:
- **Autoclick** — early active helper; fills combo and helps beat early bosses.
- **Gold Bonus** — farming/economy accelerator; 30s on, 3 min off.
- **Focus Burst** — boss/checkpoint click damage burst; 12s on, 2 min off. Multiplier applied at activation.
- **Rally** — partner DPS burst for sustained fights; 20s on, 2.5 min off.

Previous untuned values (before this pass):
- Autoclick cooldown: 60s (too short — felt free)
- Gold Bonus: 45s duration, 300s cooldown (too long duration, too long cooldown)
- Focus Burst: 20s duration (too long for a burst tool)
- Rally: 30s duration, 180s cooldown

### Combo constants

| Constant | Value | Notes |
|----------|-------|-------|
| `COMBO_FILL_PER_CLICK` | 1.0 | Each manual click fills 1% |
| `COMBO_DECAY_PER_SECOND` | 5.0 | Idle decay — 20s to empty from full |
| `COMBO_DAMAGE_PER_PERCENT` | 0.01 | +1% damage per 1% combo fill |
| `COMBO_EMPOWERED_MULTIPLIER` | 3.0 | ×3 click damage at 100% |
| `COMBO_EMPOWERED_DURATION_SEC` | 10.0 | Empowered lasts 10s then resets |

Decay changed from 1.0/s to 5.0/s so casual slow tapping stays below 50% and only active clicking or autoclick reaches empowered. Partner DPS does not fill combo.

Damage formula: `multiplier = 1.0 + meter_value × COMBO_DAMAGE_PER_PERCENT`
At 50%: ×1.5. At 100% (empowered): ×3.0 for 10s.

### Boss friction (unchanged, confirmed correct)

- Boss every 10th level; boss HP ×8, reward ×10, timer 30s.
- Boss fail: returns one level back, disables auto-transition.
- Boss Retry Token: prevents failure once (resets boss timer instead).
- Boss HP multiplier was softened from research ×10 to ×8 for first pass. Raise after playtesting.

### Settlement buildings (confirmed correct, unchanged)

| Index | Name | Effect |
|-------|------|--------|
| 0 | Training Camp | +1%/level partner DPS (additive) |
| 1 | Market | +1%/level gold from enemies (additive) |
| 2 | Knight Hut | +1%/level click damage (additive) |
| 3 | War Banner | +1%/level ability duration (additive) |
| 4 | Clock Tower | cooldown reduction via diminishing returns: 100/(100+raw%) |
| 5 | Boss Shrine | +1%/level boss gold reward (additive) |

Settlement is meaningful after early game but not mandatory. Clock Tower cooldown reduction correctly uses diminishing returns (can never reach 0).

### Prestige timing (unchanged, confirmed reasonable)

- `PRESTIGE_REQUIRED_LEVEL = 50` — first prestige point available at stage 50.
- `PRESTIGE_CHARACTER_INTERVAL = 100` — +1 point per 100 hero levels.
- `PRESTIGE_TALENT_BONUS_PERCENT_PER_LEVEL = 5` — 5% bonus per talent level.

First prestige expected at 1–3 hours depending on play style. Not changed in this pass.

### Task and shop rewards (unchanged, confirmed consistent)

- Task reward scales with current zone enemy reward × reward_scale coefficient.
- Task Reward Boost (shop) applies once to next claimed task then resets to ×1.
- Gold Bonus ability affects **enemy gold only**, not shop or task rewards.
- Shop ETV values kept conservative: Small = 5 min ETV, Large = 20 min ETV.

### Intentionally not changed in this pass

- No new abilities, buildings, partners, or currencies.
- No ability ×5 multiplier — current ×2.0–×3.25 range is safer for first test.
- No real ads, Yandex payments, cloud saves, or analytics.
- No save format changes.
- No UI layout changes.
- Prestige required level unchanged (50); lower to 40 only if first prestige proves too late.
- Boss HP multiplier unchanged (×8); raise only after manual testing confirms game is too easy.
- Shop ETV values unchanged; raise after real monetization pass.

---

## Power Progression Model C v1 (implemented 2026-05-30)

Goals:
- Hero click damage formula centralised into BalanceConfig constants
- Ability purchase costs tuned to new exponential economy
- Skill cost multipliers adjusted to make skills reachable at their unlock points
- Ability multiplier magic numbers extracted into BalanceConfig constants
- Partner DPS values unchanged — current ~1.85× per tier is within the 1.7–2.2× target

### Hero damage formula

```
base_damage = HERO_BASE_DAMAGE + character_level * HERO_DAMAGE_PER_LEVEL
click_damage = base_damage * milestone_multiplier * passive_multipliers
```

| Constant | Value | Note |
|----------|-------|------|
| `HERO_BASE_DAMAGE` | 1.0 | Flat base (gives level 1 = 2 damage instead of 1) |
| `HERO_DAMAGE_PER_LEVEL` | 1.0 | Linear per-level contribution |

The +1 base makes the very first clicks feel slightly more impactful.

### Ability purchase costs (tuned for new economy)

| Ability | Old cost | New cost | Target feeling |
|---------|----------|----------|----------------|
| Autoclick | 50 | 300 | Reachable near first wall |
| Gold Bonus | 150 | 1200 | Reachable after first farming loop |
| Focus Burst | 500 | 5000 | Mid-game boss/checkpoint tool |
| Rally | 1000 | 15000 | Mid-game partner accelerator |

### Ability multiplier constants

```
focus_burst / rally / gold_bonus: multiplier = ABILITY_BASE_MULTIPLIER + ABILITY_RANK_MULTIPLIER_STEP * rank
autoclick rate: 1.0 + AUTOCLICK_RANK_RATE_STEP * rank
```

| Constant | Value |
|----------|-------|
| `ABILITY_BASE_MULTIPLIER` | 2.0 |
| `ABILITY_RANK_MULTIPLIER_STEP` | 0.25 |
| `AUTOCLICK_BASE_HITS_PER_SEC` | 20.0 |
| `AUTOCLICK_BASE_DURATION_SEC` | 15 |
| `AUTOCLICK_RANK_DURATION_BONUS_SEC` | 2 |
| `AUTOCLICK_RANK_RATE_STEP` | 0.15 |

Behavior unchanged from previous values — only magic numbers centralised.

### Skill cost multipliers (minor adjustments)

| Array | Old | New | Direction |
|-------|-----|-----|-----------|
| `HERO_SKILL_COST_MULTIPLIERS` | [5, 8, 12, 18, 30] | [4, 7, 11, 17, 26] | Slightly cheaper |
| `PARTNER_SKILL_COST_MULTIPLIERS` | [3, 5, 8, 12, 20] | [4, 6, 9, 14, 22] | Skill 1 slightly pricier, rest adjusted |
| `ABILITY_SKILL_COST_MULTIPLIERS` | [1, 4, 9, 16, 25] | [1, 3, 7, 13, 22] | Ranks 2–5 more accessible |

### Intentionally not changed in this pass

- Partner DPS values — ~1.85× per tier, within the 1.7–2.2× target range
- Milestone levels and multipliers — unchanged
- Settlement building effects — unchanged (1% per level)
- Prestige talent bonus — unchanged (5% per level)
- Ability max rank and base multiplier behavior — unchanged
- Research suggested ability ×5 multiplier — deferred; current ×2.0–×3.25 safer for first test

---

## Core Economy Model C v1 (implemented 2026-05-30)

Goals:
- Explosive early game — first ~10 levels feel fast
- Smoother mid-game slowdown
- Harder late-game friction through cost acceleration
- HP grows faster than rewards to create increasing friction

All values below are **first-pass tuning values** expected to change after playtesting.

---

## Hero level cost — segmented adaptive exponential

```
cost(L → L+1):
  L < 101   → HERO_BASE_COST * HERO_COST_GROWTH_EARLY^(L-1)
  101–500   → continuous from L=100, × HERO_COST_GROWTH_MID per level
  501+      → continuous from L=500, × HERO_COST_GROWTH_LATE per level
```

| Constant | Value | Effect |
|----------|-------|--------|
| `HERO_BASE_COST` | 5.0 | Cost of first upgrade |
| `HERO_COST_GROWTH_EARLY` | 1.05 | +5% per level, levels 1–100 |
| `HERO_COST_GROWTH_MID` | 1.10 | +10% per level, levels 101–500 |
| `HERO_COST_GROWTH_LATE` | 1.15 | +15% per level, levels 501+ |

Milestone target levels (10, 25, 50, 100, 250, 500) cost ×`MILESTONE_COST_MULTIPLIER` (×3).

**Sample costs (no milestone spike):**
- Level 1→2: 5 gold
- Level 10→11: ~8 gold (×3 spike at 10 = ~24)
- Level 25→26: ~16 gold (×3 = ~48)
- Level 50→51: ~55 gold (×3 = ~165)
- Level 100→101: ~657 gold (×3 = ~1971)

**Tuning:**
- Make early cheaper: lower `HERO_COST_GROWTH_EARLY` (e.g. 1.04)
- Make mid harder: raise `HERO_COST_GROWTH_MID` (e.g. 1.12)
- Shift segments: adjust `HERO_COST_MID_START_LEVEL` / `HERO_COST_LATE_START_LEVEL`

---

## Partner cost — segmented adaptive exponential by owned count

```
cost(count → count+1):
  count < 100   → base_cost * PARTNER_COST_GROWTH_EARLY^count
  100–249       → continuous from count=99, × PARTNER_COST_GROWTH_MID per count
  250+          → continuous from count=249, × PARTNER_COST_GROWTH_LATE per count
```

| Constant | Value |
|----------|-------|
| `PARTNER_COST_GROWTH_EARLY` | 1.07 |
| `PARTNER_COST_GROWTH_MID` | 1.10 |
| `PARTNER_COST_GROWTH_LATE` | 1.13 |
| `PARTNER_COST_MID_START_COUNT` | 100 |
| `PARTNER_COST_LATE_START_COUNT` | 250 |

Milestone target counts (10, 25, 50, 100, 250, 500) cost ×3.
Base costs per partner tier live in `PARTNER_BASE_COSTS` (range: 10 → 220,000).

---

## Building cost — exponential growth

```
cost(count) = BUILDING_BASE_COSTS[i] * BUILDING_COST_GROWTH^count
```

| Constant | Value |
|----------|-------|
| `BUILDING_COST_GROWTH` | 1.18 |

No milestone cost spikes on buildings.

**Sample (Training Camp, base 25):**
- Count 0: 25 gold
- Count 10: ~130 gold
- Count 50: ~44,750 gold

---

## Enemy HP and rewards — exponential

```
hp(level)     = ENEMY_HP_BASE     × ENEMY_HP_GROWTH^(level-1)
reward(level) = ENEMY_REWARD_BASE × ENEMY_REWARD_GROWTH^(level-1)
```

| Constant | Value | Note |
|----------|-------|------|
| `ENEMY_HP_BASE` | 10.0 | Level 1 HP |
| `ENEMY_HP_GROWTH` | 1.14 | +14% HP per level |
| `ENEMY_REWARD_BASE` | 5.0 | Level 1 reward |
| `ENEMY_REWARD_GROWTH` | 1.11 | +11% reward per level |

HP grows faster than rewards (1.14 vs 1.11) — increasing friction over time.

**Sample values:**
| Level | Base HP | Boss HP (×8) | Base Reward | Boss Reward (×10) |
|-------|---------|--------------|-------------|-------------------|
| 1 | 10 | 80 | 5 | 50 |
| 5 | ~19 | ~152 | ~8 | ~80 |
| 10 | ~37 | ~296 | ~14 | ~140 |
| 25 | ~205 | ~1640 | ~68 | ~680 |
| 50 | ~5430 | ~43440 | ~925 | ~9250 |
| 100 | ~2.95M | ~23.6M | ~134k | ~1.34M |

**Tuning:**
- More early-game HP: raise `ENEMY_HP_BASE` (e.g. 12) or lower `ENEMY_HP_GROWTH` (e.g. 1.12)
- Less HP vs reward gap: bring `ENEMY_HP_GROWTH` closer to `ENEMY_REWARD_GROWTH`

---

## Boss and elite multipliers

| Constant | Value | Research recommendation |
|----------|-------|------------------------|
| `BOSS_HP_MULTIPLIER` | 8 | ×10 (softened for first pass) |
| `BOSS_REWARD_MULTIPLIER` | 10 | ×15 (softened for first pass) |
| `ELITE_HP_MULTIPLIER` | 3 | unchanged |
| `ELITE_REWARD_MULTIPLIER` | 5 | unchanged |
| `BOSS_TIME_LIMIT` | 30.0s | unchanged |

Boss multipliers were softened from research values to avoid creating an early hard wall before playtesting. Raise after manual validation.

---

## Task rewards — ETV-inspired baseline

```
task_reward = current_task_reward_unit × reward_scale × partner_skill_multiplier
current_task_reward_unit = zone_scaled_enemy_reward (one enemy kill's gold)
```

ETV constants (for future formula evolution):
- `TASK_BASELINE_TTK_SECONDS` = 2.0 — assumed seconds to kill one enemy
- `TASK_REWARD_SECONDS_BASE` = 60.0 — equivalent seconds of income per reward_scale unit

Current formula is equivalent to ETV when `reward_scale_normalized = reward_scale / TASK_REWARD_SECONDS_BASE`.

Task `reward_scale` values (in TaskConfig): 20, 30, 40, 50, 60, 70, 80, 90, 100, 120.

---

## Shop gold packs — ETV seconds

```
shop_gold = (current_enemy_reward / TASK_BASELINE_TTK_SECONDS) × etv_seconds
```

| Product | ETV Seconds | ~Equivalent income time |
|---------|-------------|------------------------|
| Small Gold Pack | 300s | 5 minutes |
| Large Gold Pack | 1200s | 20 minutes |

These are conservative first-pass values. Research suggests 1 hour / 8 hours.
Raise after playtesting confirms the economy feels rewarding enough.

---

## Milestones (unchanged from prototype)

- `MILESTONE_LEVELS` = [10, 25, 50, 100, 250, 500]
- `MILESTONE_MULTIPLIER_PER_REACHED` = 2 — DPS/contribution ×2 per reached milestone
- `MILESTONE_COST_MULTIPLIER` = 3 — purchase cost ×3 at milestone target

---

## Prestige (unchanged from prototype)

- First prestige point at game level 50 (`PRESTIGE_REQUIRED_LEVEL`)
- Hero contributes 1 point per 100 levels (`PRESTIGE_CHARACTER_INTERVAL`)
- Each talent level gives +5% bonus (`PRESTIGE_TALENT_BONUS_PERCENT_PER_LEVEL`)

---

## Debug Progression Simulator

In debug mode (`BuildConfig.IS_DEBUG_BUILD = true`), press **F8** while the game is running.

Three profiles simulated: **F2P_CASUAL** (0.5 clicks/sec), **AD_WATCHER** (1.0 clicks/sec), **LIGHT_SPENDER** (2.0 clicks/sec).

Snapshots at: 5, 15, 30, 60, 180, 1440 minutes.

Output columns:
```
  60min | Lv12  | Hero240  | Dmg1800   | PDPS3500   | EHP420     | +18000 g/min | 2.3s/lvl | 0 pp
```

| Column | Meaning |
|--------|---------|
| `min` | Simulated time |
| `Lv` | Game level reached |
| `Hero` | Hero level |
| `Dmg` | Click damage |
| `PDPS` | Partner DPS |
| `EHP` | Current enemy HP |
| `g/min` | Estimated gold income |
| `s/lvl` | Seconds to clear current level |
| `pp` | Prestige points available |

CSV output written to `user://balance_simulation.csv` after each F8 press.
The simulator does **not** touch the real save file (`user://save_v1.json`).
