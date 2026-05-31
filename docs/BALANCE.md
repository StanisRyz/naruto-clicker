# Balance Tuning Guide

All economy coefficients live in `res://scripts/game/BalanceConfig.gd`.
Change a value there; calculators and runtime services pick it up automatically.
Do not edit formula vars directly in ClickerState.gd.

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
