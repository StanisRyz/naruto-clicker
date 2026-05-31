# Balance Playtest Analyzer

Offline developer tool that reads `balance_playtest.csv` exported from the Godot debug build and produces a summary report, tuning hints, filtered CSV subsets, and graphs.

This tool is for development use only. It has no connection to the game runtime.

---

## Requirements

- Python 3.10 or newer
- `matplotlib` for PNG graphs (optional):
  ```
  pip install matplotlib
  ```

The script runs without matplotlib — it skips graphs and still produces all text and CSV output.

---

## Step 1: Export the CSV from Godot

1. Open `res://scripts/game/BuildConfig.gd` and confirm `IS_DEBUG_BUILD = true`.
2. Launch the game from Godot editor.
3. Play a session (5–60 minutes depending on what you're testing).
4. Press **F6** inside the game to export the CSV.

The CSV is written to `user://balance_playtest.csv`.

---

## Step 2: Find user:// on your system

| Platform | Path |
|----------|------|
| Windows | `%APPDATA%\Godot\app_userdata\naruto-clicker\` |
| macOS | `~/Library/Application Support/Godot/app_userdata/naruto-clicker/` |
| Linux | `~/.local/share/godot/app_userdata/naruto-clicker/` |

Copy `balance_playtest.csv` from that folder to a convenient location (e.g. next to this tools/ directory).

---

## Step 3: Run the analyzer

Basic usage (output goes to `balance_report/`):
```
python tools/analyze_balance_playtest.py balance_playtest.csv
```

Custom output directory:
```
python tools/analyze_balance_playtest.py balance_playtest.csv --out my_session_01/
```

Test with the included sample:
```
python tools/analyze_balance_playtest.py tools/sample_balance_playtest.csv --out tools/sample_report/
```

---

## Output Files

All outputs are written to the output directory (default: `balance_report/`).

| File | Description |
|------|-------------|
| `summary.txt` | Session metrics, friction milestones, gold economy, tuning hints |
| `enemy_events.csv` | All `enemy_defeated` rows |
| `boss_events.csv` | Boss kills + boss fail rows |
| `purchase_events.csv` | Successful purchase rows |
| `task_events.csv` | Task claim rows |
| `ability_events.csv` | Ability activation rows |
| `level_over_time.png` | Level progression curve |
| `enemy_ttk_over_time.png` | Time-to-kill scatter with reference lines |
| `gold_over_time.png` | Gold balance over session |
| `gold_income_events.png` | Cumulative kills vs task income |
| `purchase_timeline.png` | Purchases by category over time |
| `boss_friction.png` | Boss kills and fails with level labels |

---

## How to Read the Outputs

### summary.txt

- **Session duration** — total playtime in this exported CSV
- **Highest level** — how far the player progressed
- **Avg enemy TTK** — average time to kill a normal enemy; should trend from ~0.5s early to ~5–10s late
- **Boss TTK** — average time to kill a boss; should be 3–8× normal TTK at the same level
- **Friction milestones** — when the game first felt slow (TTK hit 3s, 8s, first boss fail)
- **Gold economy** — breakdown of income sources; task share should be 5–30%
- **Tuning hints** — automated suggestions based on thresholds

### enemy_ttk_over_time.png

The most important graph. Points trend upward as the game gets harder. Reference lines:
- **Green (1 s)** — comfortable, early-game feel
- **Orange (3 s)** — player starts noticing difficulty; abilities become useful
- **Red (8 s)** — genuine friction; boss-retry and farming mode become relevant

If the curve never reaches orange, the game may be too easy. If it hits red in the first 5 minutes, it's too hard.

### purchase_timeline.png

Scattered dots by purchase category. Dense early clusters = healthy economy.
Long horizontal gaps with no dots = friction wall.

### boss_friction.png

Stars = boss kills, X = boss fails. Level labels help identify which boss caused friction.
1–2 fails per boss is the target. 0 fails on all bosses = too easy.

---

## Metrics That Matter Most

| Metric | Healthy range | Action if wrong |
|--------|--------------|-----------------|
| Early TTK (level < 10) | 0.3–2.0 s | Adjust `ENEMY_HP_BASE` |
| Late TTK (level 20+) | 3–15 s | Adjust `ENEMY_HP_GROWTH` |
| Boss TTK vs normal TTK | 3–8× | Adjust `BOSS_HP_MULTIPLIER` |
| Boss fail count (first 3 bosses) | 0–2 | Adjust `BOSS_HP_MULTIPLIER` |
| Task income share | 5–30% | Adjust `reward_scale` in TaskConfig |
| Purchases in first 10 min | 5+ | Adjust `HERO_BASE_COST` |

All constants are in `res://scripts/game/BalanceConfig.gd`.

---

## Files in this directory

| File | Purpose |
|------|---------|
| `analyze_balance_playtest.py` | Main analyzer script |
| `sample_balance_playtest.csv` | Example CSV for testing the script |
| `sample_report/` | Output of running the script on the sample |
| `README.md` | This file |
