# Balance Tuning Guide

All economy coefficients live in `res://scripts/game/BalanceConfig.gd`.
Change a value there; `ClickerState` picks it up automatically on next run.
Do not edit scattered `var` declarations in `ClickerState.gd` directly.

---

## What BalanceConfig controls

| Section | Key constants |
|---------|--------------|
| Hero cost | `HERO_COST_BASE`, `HERO_COST_LINEAR`, `HERO_COST_CURVE`, `HERO_COST_POWER` |
| Milestones | `MILESTONE_LEVELS`, `MILESTONE_MULTIPLIER_PER_REACHED`, `MILESTONE_COST_MULTIPLIER` |
| Partner cost | `PARTNER_BASE_COSTS`, `PARTNER_COST_STEPS`, `PARTNER_COST_CURVE_MULT`, `PARTNER_COST_POWER` |
| Partner DPS | `PARTNER_DPS_VALUES` |
| Abilities | unlock levels, purchase costs, `ABILITY_MAX_RANK` |
| Settlement | `BUILDING_BASE_COSTS`, `BUILDING_COST_STEPS`, `BUILDING_BONUS_PERCENT_PER_LEVEL` |
| Enemies | HP formula, reward formula, elite/boss multipliers, boss timer |
| Prestige | `PRESTIGE_REQUIRED_LEVEL`, `PRESTIGE_TALENT_BONUS_PERCENT_PER_LEVEL` |
| Shop | gold pack scales, boost multipliers |

---

## Major formulas

### Hero level cost
```
progress = hero_level - 1
cost = HERO_COST_BASE + HERO_COST_LINEAR*progress + HERO_COST_CURVE*progress^HERO_COST_POWER
```
Milestone target levels (10, 25, 50, …) apply an additional ×`MILESTONE_COST_MULTIPLIER` spike.

### Enemy HP
```
stage = level - 1
hp = ENEMY_HP_BASE + ENEMY_HP_LINEAR*stage + ENEMY_HP_CURVE*stage^ENEMY_HP_POWER
```

### Enemy reward
```
reward = ENEMY_REWARD_BASE + ENEMY_REWARD_LINEAR*stage + ENEMY_REWARD_CURVE*stage^ENEMY_REWARD_POWER
```

### Partner cost
```
cost = base + step*count + base*PARTNER_COST_CURVE_MULT*count^PARTNER_COST_POWER
```

---

## Tuning early game (levels 1–15)

**Make it faster:**
- Lower `HERO_COST_BASE` (e.g. 3 instead of 5).
- Lower `HERO_COST_LINEAR` (e.g. 1.5).
- Raise `PARTNER_DPS_VALUES[0]` (Partner 1 DPS).

**Make it slower:**
- Raise `HERO_COST_LINEAR` or `HERO_COST_CURVE`.
- Raise `ENEMY_HP_LINEAR`.

---

## Tuning mid game (levels 15–50)

**Partner milestone spikes** control the main power inflection points.
- `MILESTONE_LEVELS = [10, 25, 50, 100, 250, 500]` — each adds ×2 DPS.
- Lower first milestone (e.g. to 8) to let the first spike arrive sooner.
- Raise `MILESTONE_MULTIPLIER_PER_REACHED` (e.g. to 3) for bigger spikes.

**Ability unlock gates:**
- `AUTOCLICK_UNLOCK_LEVEL = 15` — first major power spike. Lower to 10 for faster feel.
- `GOLD_BONUS_UNLOCK_LEVEL = 30` — gold economy inflection.

---

## Tuning late game friction (levels 50–40)

- Raise `ENEMY_HP_POWER` (e.g. 2.2) for steeper HP wall.
- Raise `HERO_COST_POWER` (e.g. 2.5) for steeper hero cost curve.
- Raise `PARTNER_COST_CURVE_MULT` (e.g. 0.02) for heavier partner cost scaling.

---

## Tuning task reward value

Task reward = `current_task_reward_unit × reward_scale`.
`reward_scale` is defined per-task in `ClickerState.task_definitions`.

- Higher `reward_scale` on easy tasks makes tasks feel more valuable.
- The reward unit tracks the current zone reward so tasks scale with progression automatically.

---

## Tuning shop reward value

Shop gold packs use `SHOP_GOLD_SMALL_SCALE` and `SHOP_GOLD_LARGE_SCALE` as a time-multiplier:
```
gold = current_task_reward_unit × scale
```
- Scale = 120 ≈ 2 minutes of current gold income.
- Scale = 350 ≈ 6 minutes. Raise both to make packs feel more impactful.

---

## Tuning prestige speed

- `PRESTIGE_REQUIRED_LEVEL = 50` — stage threshold for first prestige point.
  Lower to 30 for faster first prestige.
- `PRESTIGE_CHARACTER_INTERVAL = 100` — hero levels per prestige point.
  Lower to 75 for more character-level contribution.
- `PRESTIGE_TALENT_BONUS_PERCENT_PER_LEVEL = 5` — power per talent level.
  Raise to 7–8 if prestige feels unrewarding.

---

## Bosses

- `BOSS_HP_MULTIPLIER = 5` — boss HP vs normal enemy at same level.
- `BOSS_REWARD_MULTIPLIER = 5` — boss gold vs normal.
- `BOSS_TIME_LIMIT = 30.0` — seconds to kill boss before fail.
  Raise to 45 for a more forgiving early game.

---

## Debug Progression Simulator

### Running it

In debug mode (`BuildConfig.IS_DEBUG_BUILD = true`), press **F8** while the game is running.

Output prints to the Godot console. Three profiles are simulated:
- **F2P_CASUAL** — 0.5 clicks/sec, conservative spending.
- **AD_WATCHER** — 1.0 clicks/sec, moderate spending.
- **LIGHT_SPENDER** — 2.0 clicks/sec, aggressive spending.

Snapshots at: 5, 15, 30, 60, 180, 1440 minutes.

### Reading the output

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

### CSV output

A CSV is written to `user://balance_simulation.csv` after each F8 press.
Open in a spreadsheet to plot progression curves across all three profiles.

On Windows the user:// path is typically:
`%APPDATA%\Godot\app_userdata\<project-name>\balance_simulation.csv`

The simulator does **not** touch the real save file (`user://save_v1.json`).
