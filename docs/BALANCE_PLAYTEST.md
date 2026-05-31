# Balance Playtest Guide

Local debug telemetry for real gameplay balance testing.
This is NOT the progression simulator (F8). This records actual in-game events.

No data leaves the device. Release builds disable all logging automatically.

---

## Setup

1. Open `res://scripts/game/BuildConfig.gd` and confirm `IS_DEBUG_BUILD = true`.
2. Delete your save (`user://save_v1.json`) or use F10 in-game to start fresh.
3. Launch the game from Godot editor.
4. Play normally — the logger runs automatically.

---

## Debug Keys (debug build only)

| Key | Action |
|-----|--------|
| F5 | Save game |
| F6 | **Export balance CSV** → `user://balance_playtest.csv` |
| F7 | **Print session summary** to Godot output console |
| F8 | Run progression simulator (separate tool) |
| F9 | Reload save from disk |
| F10 | Delete save file |
| F11 | **Clear logger and restart session** |

---

## Playtest Log

### Session 02 — 2026-05-31 (after Balance Adjustment Pass v1)

- Duration: ~8m 8s
- Reset: yes. Debug gems: no. Play style: almost idle.
- Highest level: 60. Enemies killed: 556. Bosses: 16 killed / 0 fails.
- Avg enemy TTK: 0.622s. Median: 0.500s.
- Avg boss TTK: 9.387s. Median: 9.047s.
- Income: kills 87%, tasks 12%, shop 0%.
- Purchases: 53. Tasks claimed: 20. Abilities used: 0.

**Verdict:** Task and boss fixes from Pass v1 held. Overall pace still too fast — early levels vanish instantly. Patch applied: Balance Adjustment Pass v2 (HP curve reshape).

---

### Session 01 — 2026-05-31 (pre-patch baseline)

- Duration: ~4m 20s
- Reset: yes. Debug gems: no. Play style: almost idle.
- Highest level: 62. Enemies killed: 562. Bosses: 6 killed / 0 fails.
- Avg enemy TTK: 0.449s. Median: 0.423s.
- Avg boss TTK: 1.780s. Median: 1.845s.
- Income: kills 41%, tasks 58%, shop 0%.
- Gold spent: 1,263,510. Purchases: 34. Tasks claimed: 13. Abilities used: 0.

**Verdict:** Progression far too fast. Tasks dominated. Bosses trivial. Patch applied: Balance Adjustment Pass v1.

---

## Recommended Playtest Sessions

### Session A — Early game (5–15 min)
Play from a fresh save. Stop at 5 minutes and export. Then keep playing to 15 minutes and export again.

Check for:
- First level cleared in under 60 seconds
- First partner purchased before level 5
- Enemy TTK under 2s for levels 1–5
- Hero upgrade purchased multiple times in first 5 minutes
- No dead stops (TTK > 30s in first 10 levels)

### Session B — First boss (15–30 min)
Keep the Session A save. Play until you hit the level 10 boss.

Check for:
- Boss HP feels challenging but clearable with abilities
- If failed: was it close (boss HP < 20% remaining)?
- Auto-transition disabled correctly on boss fail
- Boss retry token useful if purchased

### Session C — Mid game (30–60 min)
Continue or start fresh. Play to level 20+.

Check for:
- Abilities being used strategically (not ignored)
- Tasks/shop providing meaningful gold share (>10% of total income)
- Settlement buildings feeling useful at level 15+
- Combo empowered triggered at least a few times per session

### Session D — Friction and prestige window (60+ min)
Play until progression noticeably slows.

Check for:
- Average enemy TTK creeping above 5s as friction signal
- Prestige button becoming tempting (level 50)
- Gold per minute still growing despite friction
- No infinite stall where progress feels impossible

---

## CSV Output

CSV written to `user://balance_playtest.csv` when you press F6.

On Windows, open `user://` by running `%APPDATA%\Godot\app_userdata\naruto-clicker\` in Explorer.

### Event Types

| event_type | When logged |
|---|---|
| `session_start` | On game start or F11 reset |
| `enemy_defeated` | Every enemy kill |
| `boss_failed` | Boss timer ran out |
| `purchase` | Any buy action (success or fail) |
| `task_claimed` | Task reward collected |
| `ability_used` | Active ability activated |
| `level_changed` | Stage advanced via combat |

### Key Columns

| Column | Notes |
|---|---|
| `timestamp_sec` | Seconds since session start |
| `enemy_ttk_sec` | Time to kill that enemy (seconds) |
| `was_boss` | True if this was a boss kill |
| `defeated_on_level` | Which level the enemy was on (use this, not current_level, for boss analysis) |
| `level_changed` | True if auto-transition fired after this kill |
| `boss_hp_remaining` | HP at boss failure moment |
| `retry_will_be_used` | True if a retry token absorbed the failure |
| `purchase_category` | hero_level / partner / building / shop / etc. |
| `cost` | Gold spent (or gems for shop, PP for prestige_talent) |
| `gold_earned_on_level` | Cumulative gold earned while on that stage |
| `level_time_sec` | Total time spent on that stage before advancing |

---

## What to Look For

### Enemy TTK trend
Filter `event_type = enemy_defeated`, plot `enemy_ttk_sec` over `timestamp_sec`.
- Should start near 0.5–2s, creep up toward 5–10s at level 20+.
- If TTK stays near 0 forever → too easy, raise HP growth.
- If TTK spikes above 30s early → too hard, lower HP growth.

### Boss TTK vs normal TTK
Filter `was_boss = True`. Boss TTK should be 3–8× the normal TTK at that level.
- `BOSS_HP_MULTIPLIER = 8`, so expect ~8× TTK baseline.
- Abilities should visibly reduce boss TTK in the CSV.

### Purchase timing
Filter `event_type = purchase, success = True`. Look at `timestamp_sec` gaps.
- Frequent early purchases = good early-game feel.
- Long gaps with no purchases = friction wall (check what level and gold amount).

### Gold income breakdown
Sum `enemy_reward_gold` (kills), `task_reward_gold` (tasks), and shop reward from purchase rows.
- Task + shop share should be >10% after 20 minutes to feel meaningful.
- If task share < 5%, task rewards may need raising.

### Ability usage
Filter `event_type = ability_used`. Count per ability per 10-minute window.
- If autoclick never appears → player isn't using it (UI clarity issue or cooldown too long).
- If focus_burst used on every boss → working as intended.
- If no ability ever used → abilities may be unnoticed or feel too expensive.

### Boss fail rate
Count `boss_failed` rows. 0–1 fails per boss is healthy friction.
- 0 fails at every boss → too easy, consider raising HP multiplier.
- 3+ fails at first boss → too hard, lower to `BOSS_HP_MULTIPLIER = 6`.

---

## Python Graph Helper (optional)

Install: `pip install pandas matplotlib`

```python
import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv("balance_playtest.csv")
df["timestamp_sec"] = df["timestamp_sec"].astype(float)

fig, axes = plt.subplots(2, 3, figsize=(16, 10))
fig.suptitle("Balance Playtest Session")

# Level over time
kills = df[df["event_type"] == "enemy_defeated"].copy()
kills["current_level"] = kills["current_level"].astype(int)
axes[0, 0].plot(kills["timestamp_sec"], kills["current_level"])
axes[0, 0].set_title("Level over Time")
axes[0, 0].set_xlabel("Session sec")
axes[0, 0].set_ylabel("Level")

# Enemy TTK over time
axes[0, 1].scatter(kills["timestamp_sec"], kills["enemy_ttk_sec"].astype(float),
                   c=kills["was_boss"].map({"True": "red", "False": "blue"}), s=10, alpha=0.5)
axes[0, 1].set_title("Enemy TTK (red=boss)")
axes[0, 1].set_xlabel("Session sec")
axes[0, 1].set_ylabel("TTK sec")

# Gold over time
axes[0, 2].plot(df["timestamp_sec"].astype(float), df["gold"].astype(float))
axes[0, 2].set_title("Gold Balance over Time")
axes[0, 2].set_xlabel("Session sec")
axes[0, 2].set_ylabel("Gold")

# Purchase categories
purchases = df[(df["event_type"] == "purchase") & (df["success"] == "True")]
cat_counts = purchases["purchase_category"].value_counts()
axes[1, 0].bar(cat_counts.index, cat_counts.values)
axes[1, 0].set_title("Purchase Count by Category")
axes[1, 0].tick_params(axis="x", rotation=45)

# Task reward gold over time
tasks = df[df["event_type"] == "task_claimed"].copy()
tasks["task_reward_gold"] = tasks["task_reward_gold"].astype(float)
axes[1, 1].bar(tasks["timestamp_sec"].astype(float), tasks["task_reward_gold"])
axes[1, 1].set_title("Task Rewards over Time")
axes[1, 1].set_xlabel("Session sec")
axes[1, 1].set_ylabel("Gold")

# Ability usage
abilities = df[df["event_type"] == "ability_used"]
ab_counts = abilities["ability_id"].value_counts()
axes[1, 2].bar(ab_counts.index, ab_counts.values)
axes[1, 2].set_title("Ability Usage Count")
axes[1, 2].tick_params(axis="x", rotation=45)

plt.tight_layout()
plt.savefig("balance_playtest_graphs.png", dpi=150)
plt.show()
print("Saved to balance_playtest_graphs.png")
```

Run from the directory containing `balance_playtest.csv`.

---

## Tuning Decisions

| Observation | Possible tuning |
|---|---|
| Early TTK too long (>5s at level 1) | Lower `ENEMY_HP_BASE` or `ENEMY_HP_GROWTH` |
| Late TTK never slows down | Raise `ENEMY_HP_GROWTH` slightly |
| First boss too easy | Raise `BOSS_HP_MULTIPLIER` from 8 to 10 |
| First boss too hard | Lower `BOSS_HP_MULTIPLIER` from 8 to 6 |
| Autoclick never used | Lower `AUTOCLICK_COOLDOWN_SEC` |
| Gold Bonus feels irrelevant | Raise `GOLD_BONUS_BASE_DURATION_SEC` |
| Combo rarely empowers | Lower `COMBO_DECAY_PER_SECOND` |
| Combo trivializes bosses | Raise `COMBO_DECAY_PER_SECOND` |
| Tasks ignored | Raise task `reward_scale` in TaskConfig |
| Prestige too late / too early | Adjust `PRESTIGE_REQUIRED_LEVEL` |

All constants live in `res://scripts/game/BalanceConfig.gd`.

---

## Offline Analyzer (recommended)

After pressing F6 to export the CSV, use the Balance CSV Analyzer for automated metrics, graphs, and tuning hints.

### Find user:// on your system

| Platform | Path |
|----------|------|
| Windows | `%APPDATA%\Godot\app_userdata\naruto-clicker\` |
| macOS | `~/Library/Application Support/Godot/app_userdata/naruto-clicker/` |
| Linux | `~/.local/share/godot/app_userdata/naruto-clicker/` |

### Run the analyzer

Copy `balance_playtest.csv` from user:// and run:

```
python tools/analyze_balance_playtest.py balance_playtest.csv
```

Custom output directory:
```
python tools/analyze_balance_playtest.py balance_playtest.csv --out session_01/
```

Requires Python 3.10+. Install `matplotlib` for graphs:
```
pip install matplotlib
```

### Expected output files in `balance_report/`

| File | Contents |
|------|----------|
| `summary.txt` | Session metrics, friction milestones, tuning hints |
| `enemy_events.csv` | Enemy defeat rows |
| `boss_events.csv` | Boss kills and fails |
| `purchase_events.csv` | Successful purchases |
| `task_events.csv` | Task claim rewards |
| `ability_events.csv` | Ability activations |
| `level_over_time.png` | Level curve (requires matplotlib) |
| `enemy_ttk_over_time.png` | TTK scatter with reference lines |
| `gold_over_time.png` | Gold balance curve |
| `gold_income_events.png` | Cumulative income by source |
| `purchase_timeline.png` | Purchases by category |
| `boss_friction.png` | Boss kills + fails over time |

### How to read summary.txt

Open `balance_report/summary.txt`. Key sections:

- **FRICTION MILESTONES** — when TTK first hit 3 s and 8 s, and when the first boss fail occurred. If TTK never hit 3 s: game is too easy. If it hit 3 s in the first 2 minutes: too hard.
- **GOLD ECONOMY** — if task rewards are above 30% of total income, task scaling may be too generous.
- **TUNING HINTS** — automated suggestions. These are starting points; always confirm with playfeel.

Full analyzer documentation: `tools/README.md`
