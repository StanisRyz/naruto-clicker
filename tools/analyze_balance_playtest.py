#!/usr/bin/env python3
"""
Balance Playtest CSV Analyzer v1
Reads balance_playtest.csv exported by BalancePlaytestLogger and produces:
  - balance_report/summary.txt      (metrics + tuning hints)
  - balance_report/*_events.csv     (filtered subsets)
  - balance_report/*.png            (graphs, if matplotlib is installed)

Usage:
  python tools/analyze_balance_playtest.py balance_playtest.csv
  python tools/analyze_balance_playtest.py balance_playtest.csv --out my_report/

Requires: Python 3.10+
Optional: matplotlib (pip install matplotlib) for PNG graphs
"""

from __future__ import annotations

import argparse
import csv
import io
import os
import statistics
import sys
from datetime import datetime
from pathlib import Path

# Force UTF-8 stdout/stderr so special characters don't crash on Windows cp1251.
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

# ---------------------------------------------------------------------------
# Optional matplotlib — degrade gracefully if missing
# ---------------------------------------------------------------------------
try:
    import matplotlib
    matplotlib.use("Agg")          # non-interactive backend, safe for scripts
    import matplotlib.pyplot as plt
    _MPL = True
except ImportError:
    _MPL = False


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _f(val, default: float = 0.0) -> float:
    try:
        return float(val)
    except (ValueError, TypeError):
        return default


def _i(val, default: int = 0) -> int:
    try:
        return int(float(val))
    except (ValueError, TypeError):
        return default


def _b(val) -> bool:
    return str(val).strip().lower() in ("true", "1", "yes")


def _fmt_sec(s: float) -> str:
    s = int(s)
    h, rem = divmod(s, 3600)
    m, sec = divmod(rem, 60)
    if h:
        return f"{h}h {m}m {sec}s"
    if m:
        return f"{m}m {sec}s"
    return f"{sec}s"


# ---------------------------------------------------------------------------
# CSV parsing
# ---------------------------------------------------------------------------

def parse_csv(path: str) -> tuple[list[dict], list[str]]:
    """Return (rows, fieldnames). Never raises; exits on unreadable file."""
    rows: list[dict] = []
    fieldnames: list[str] = []
    try:
        with open(path, newline="", encoding="utf-8") as fh:
            reader = csv.DictReader(fh)
            fieldnames = list(reader.fieldnames or [])
            for raw in reader:
                row = {
                    k.strip(): (v.strip() if v else "")
                    for k, v in raw.items()
                    if k is not None
                }
                if not any(row.values()):
                    continue
                rows.append(row)
    except FileNotFoundError:
        print(f"ERROR: file not found: {path}", file=sys.stderr)
        sys.exit(1)
    except Exception as exc:
        print(f"ERROR: cannot parse CSV: {exc}", file=sys.stderr)
        sys.exit(1)
    return rows, fieldnames


def _filter(rows: list[dict], event_type: str) -> list[dict]:
    return [r for r in rows if r.get("event_type") == event_type]


# ---------------------------------------------------------------------------
# Metrics
# ---------------------------------------------------------------------------

def compute_metrics(rows: list[dict]) -> dict:
    enemy_rows   = _filter(rows, "enemy_defeated")
    boss_rows    = [r for r in enemy_rows if _b(r.get("was_boss", "false"))]
    normal_rows  = [r for r in enemy_rows if not _b(r.get("was_boss", "false"))]
    fail_rows    = _filter(rows, "boss_failed")
    purchase_rows = [r for r in _filter(rows, "purchase") if _b(r.get("success", "false"))]
    task_rows    = _filter(rows, "task_claimed")
    ability_rows = _filter(rows, "ability_used")

    # Session duration
    timestamps = [_f(r.get("timestamp_sec", 0)) for r in rows if r.get("timestamp_sec")]
    session_sec = max(timestamps) if timestamps else 0.0

    # Level
    all_levels = [_i(r.get("new_level") or r.get("current_level", 0)) for r in rows]
    highest_level = max(all_levels) if all_levels else 0
    max_unlocked  = max((_i(r.get("max_unlocked_level", 0)) for r in rows), default=0)

    # TTK
    n_ttks = [_f(r.get("enemy_ttk_sec", 0)) for r in normal_rows]
    b_ttks = [_f(r.get("enemy_ttk_sec", 0)) for r in boss_rows]
    avg_n = statistics.mean(n_ttks)   if n_ttks else 0.0
    med_n = statistics.median(n_ttks) if n_ttks else 0.0
    avg_b = statistics.mean(b_ttks)   if b_ttks else 0.0
    med_b = statistics.median(b_ttks) if b_ttks else 0.0

    # Gold
    kill_gold  = sum(_i(r.get("enemy_reward_gold", 0)) for r in enemy_rows)
    task_gold  = sum(_i(r.get("task_reward_gold",  0)) for r in task_rows)
    shop_gold  = 0   # not directly stored; inferred separately if needed
    gold_spent = sum(
        _i(r.get("cost", 0)) for r in purchase_rows
        if r.get("purchase_category") not in ("shop", "prestige_talent")
    )

    # Friction milestones
    first_fail_ts  = _f(fail_rows[0].get("timestamp_sec", 0)) if fail_rows else None
    ttk_3s_ts  = next((
        _f(r["timestamp_sec"]) for r in normal_rows
        if _f(r.get("enemy_ttk_sec", 0)) >= 3.0
    ), None)
    ttk_8s_ts  = next((
        _f(r["timestamp_sec"]) for r in normal_rows
        if _f(r.get("enemy_ttk_sec", 0)) >= 8.0
    ), None)
    boss_20s_ts = next((
        _f(r["timestamp_sec"]) for r in boss_rows
        if _f(r.get("enemy_ttk_sec", 0)) >= 20.0
    ), None)

    # Early TTK (levels < 10)
    early = [
        _f(r.get("enemy_ttk_sec", 0)) for r in normal_rows
        if _i(r.get("defeated_on_level") or r.get("current_level", 99)) < 10
    ]
    avg_early = statistics.mean(early) if early else None

    # Purchase density
    purchases_10m = sum(
        1 for r in purchase_rows if _f(r.get("timestamp_sec", 0)) <= 600
    )

    return dict(
        session_sec=session_sec,
        highest_level=highest_level,
        max_unlocked=max_unlocked,
        total_enemies=len(enemy_rows),
        total_bosses=len(boss_rows),
        total_boss_fails=len(fail_rows),
        avg_n=avg_n, med_n=med_n,
        avg_b=avg_b, med_b=med_b,
        kill_gold=kill_gold, task_gold=task_gold,
        shop_gold=shop_gold, gold_spent=gold_spent,
        purchases=len(purchase_rows),
        tasks_claimed=len(task_rows),
        abilities_used=len(ability_rows),
        first_fail_ts=first_fail_ts,
        ttk_3s_ts=ttk_3s_ts,
        ttk_8s_ts=ttk_8s_ts,
        boss_20s_ts=boss_20s_ts,
        avg_early=avg_early,
        purchases_10m=purchases_10m,
        # raw row buckets for graphs / subsets
        all_rows=rows,
        enemy_rows=enemy_rows,
        normal_rows=normal_rows,
        boss_rows=boss_rows,
        fail_rows=fail_rows,
        purchase_rows=purchase_rows,
        task_rows=task_rows,
        ability_rows=ability_rows,
    )


# ---------------------------------------------------------------------------
# Tuning hints
# ---------------------------------------------------------------------------

def generate_hints(m: dict) -> list[str]:
    hints: list[str] = []

    # Early TTK
    if m["avg_early"] is not None:
        if m["avg_early"] < 0.2:
            hints.append(
                "Early enemy TTK is very low (<0.2 s before level 10). "
                "Consider raising ENEMY_HP_BASE or ENEMY_HP_GROWTH."
            )
        elif m["avg_early"] > 2.0:
            hints.append(
                f"Early enemy TTK is high ({m['avg_early']:.2f} s before level 10). "
                "Consider lowering ENEMY_HP_BASE or increasing hero/partner starting power."
            )

    # First boss fail timing
    if m["fail_rows"]:
        fail_level = _i(m["fail_rows"][0].get("current_level", 10))
        if fail_level <= 10:
            hints.append(
                f"First boss fail at level {fail_level} (very early). "
                "Consider lowering BOSS_HP_MULTIPLIER from 8 to 6, "
                "or reducing AUTOCLICK_PURCHASE_COST."
            )

    # No boss friction
    if m["total_boss_fails"] == 0 and m["total_bosses"] >= 3:
        hints.append(
            f"No boss fails across {m['total_bosses']} bosses. "
            "If the game feels too easy, raise BOSS_HP_MULTIPLIER (currently 8)."
        )

    # Task income share
    total_income = m["kill_gold"] + m["task_gold"] + m["shop_gold"]
    if total_income > 0:
        task_share = m["task_gold"] / total_income
        if task_share > 0.5:
            hints.append(
                f"Task rewards are {task_share*100:.0f}% of income (>50%). "
                "Consider reducing reward_scale values in TaskConfig."
            )
        elif task_share < 0.05 and m["tasks_claimed"] > 0:
            hints.append(
                f"Task rewards are only {task_share*100:.0f}% of income (<5%). "
                "Consider raising reward_scale values in TaskConfig."
            )
    if m["tasks_claimed"] == 0 and m["session_sec"] > 300:
        hints.append(
            "No tasks claimed in a session over 5 minutes. "
            "Player may not be noticing the tasks panel — check UI visibility."
        )

    # Purchase density
    if m["session_sec"] > 120 and m["purchases_10m"] == 0:
        hints.append(
            "No successful purchases in the first 10 minutes. "
            "Consider lowering HERO_BASE_COST or HERO_COST_GROWTH_EARLY."
        )
    elif m["session_sec"] >= 600 and m["purchases_10m"] < 3:
        hints.append(
            f"Only {m['purchases_10m']} purchase(s) in the first 10 minutes. "
            "Early economy may feel too slow."
        )

    # Level progression speed
    if m["session_sec"] > 300:
        lpm = m["highest_level"] / (m["session_sec"] / 60.0)
        if lpm > 5:
            hints.append(
                f"Player reached level {m['highest_level']} in "
                f"{m['session_sec']/60:.1f} min ({lpm:.1f} levels/min — fast). "
                "Consider raising ENEMY_HP_GROWTH or HERO_COST_GROWTH_EARLY."
            )

    # Late friction missing
    if (
        m["ttk_8s_ts"] is None
        and m["session_sec"] > 1800
        and m["highest_level"] > 20
    ):
        hints.append(
            f"Enemy TTK never hit 8 s in a {m['session_sec']/60:.0f}-min session "
            f"reaching level {m['highest_level']}. "
            "Consider raising ENEMY_HP_GROWTH for more late-game friction."
        )

    # Abilities never used
    if m["abilities_used"] == 0 and m["session_sec"] > 300:
        hints.append(
            "No active abilities used. Player may not have unlocked them "
            "or may not notice the ability bar — check unlock-level pacing."
        )

    if not hints:
        hints.append(
            "No obvious tuning issues detected. "
            "Tune further based on playfeel and TTK curve shape."
        )

    return hints


# ---------------------------------------------------------------------------
# Summary report
# ---------------------------------------------------------------------------

def write_summary(m: dict, hints: list[str], out_dir: str, csv_path: str) -> str:
    path = os.path.join(out_dir, "summary.txt")

    def row(label: str, value: str, width: int = 24) -> str:
        return f"  {label:<{width}}{value}"

    lines: list[str] = []
    lines += [
        "Balance Playtest Report",
        "=" * 60,
        row("Source:",         csv_path),
        row("Generated:",      datetime.now().strftime("%Y-%m-%d %H:%M:%S")),
        row("Total CSV rows:", str(len(m["all_rows"]))),
        "",
        "SESSION",
        "-" * 40,
        row("Duration:",        f"{_fmt_sec(m['session_sec'])}  ({m['session_sec']:.1f} s)"),
        row("Highest level:",   str(m["highest_level"])),
        row("Max unlocked:",    str(m["max_unlocked"])),
        "",
        "ENEMIES",
        "-" * 40,
        row("Total killed:",    str(m["total_enemies"])),
        row("Bosses killed:",   str(m["total_bosses"])),
        row("Boss fails:",      str(m["total_boss_fails"])),
        row("Avg enemy TTK:",   f"{m['avg_n']:.3f} s"),
        row("Median enemy TTK:",f"{m['med_n']:.3f} s"),
        row("Avg boss TTK:",    f"{m['avg_b']:.3f} s" if m["total_bosses"] else "n/a"),
        row("Median boss TTK:", f"{m['med_b']:.3f} s" if m["total_bosses"] else "n/a"),
        "",
        "FRICTION MILESTONES",
        "-" * 40,
        row("First boss fail:",    _fmt_sec(m["first_fail_ts"])  if m["first_fail_ts"]  is not None else "none"),
        row("TTK first hit 3 s:",  _fmt_sec(m["ttk_3s_ts"])      if m["ttk_3s_ts"]      is not None else "not reached"),
        row("TTK first hit 8 s:",  _fmt_sec(m["ttk_8s_ts"])      if m["ttk_8s_ts"]      is not None else "not reached"),
        row("Boss TTK hit 20 s:",  _fmt_sec(m["boss_20s_ts"])    if m["boss_20s_ts"]    is not None else "not reached"),
        "",
        "GOLD ECONOMY",
        "-" * 40,
    ]

    total_income = m["kill_gold"] + m["task_gold"] + m["shop_gold"]
    def pct(x: int) -> str:
        return f"({100*x//total_income}%)" if total_income else "(n/a)"

    lines += [
        row("Kill rewards:",   f"{m['kill_gold']:>12,}  {pct(m['kill_gold'])}"),
        row("Task rewards:",   f"{m['task_gold']:>12,}  {pct(m['task_gold'])}"),
        row("Shop rewards:",   f"{m['shop_gold']:>12,}  {pct(m['shop_gold'])}  (gold packs only)"),
        row("Gold spent:",     f"{m['gold_spent']:>12,}"),
        "",
        "PLAYER ACTIONS",
        "-" * 40,
        row("Purchases (ok):", str(m["purchases"])),
        row("Tasks claimed:",  str(m["tasks_claimed"])),
        row("Abilities used:", str(m["abilities_used"])),
        row("Purchases <10m:", str(m["purchases_10m"])),
        "",
        "TUNING HINTS",
        "-" * 40,
    ]
    for hint in hints:
        # Wrap long hints at ~75 chars
        words = hint.split()
        line = "  •"
        for word in words:
            if len(line) + len(word) + 1 > 78:
                lines.append(line)
                line = "    " + word
            else:
                line += " " + word
        lines.append(line)

    lines.append("")

    with open(path, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines) + "\n")

    return path


# ---------------------------------------------------------------------------
# Graphs
# ---------------------------------------------------------------------------

def _save_fig(fig, out_dir: str, filename: str) -> str | None:
    path = os.path.join(out_dir, filename)
    fig.savefig(path, dpi=150, bbox_inches="tight")
    plt.close(fig)
    return filename


def generate_graphs(m: dict, out_dir: str) -> list[str]:
    if not _MPL:
        print("  matplotlib not installed — skipping graphs.")
        print("  Install with:  pip install matplotlib")
        return []

    saved: list[str] = []

    # 1. Level over time ──────────────────────────────────────────────────
    try:
        rows = m["all_rows"]
        xs = [_f(r.get("timestamp_sec", 0)) for r in rows]
        ys = [_i(r.get("current_level", 0)) for r in rows]
        fig, ax = plt.subplots(figsize=(10, 4))
        ax.plot(xs, ys, linewidth=1.5, color="steelblue")
        ax.set_title("Level Over Time")
        ax.set_xlabel("Session time (s)")
        ax.set_ylabel("Current level")
        ax.grid(alpha=0.3)
        name = _save_fig(fig, out_dir, "level_over_time.png")
        if name:
            saved.append(name)
    except Exception as exc:
        print(f"  Warning: level_over_time.png failed: {exc}")

    # 2. Enemy TTK over time ──────────────────────────────────────────────
    try:
        n_xs   = [_f(r.get("timestamp_sec",  0)) for r in m["normal_rows"]]
        n_ttks = [_f(r.get("enemy_ttk_sec",  0)) for r in m["normal_rows"]]
        b_xs   = [_f(r.get("timestamp_sec",  0)) for r in m["boss_rows"]]
        b_ttks = [_f(r.get("enemy_ttk_sec",  0)) for r in m["boss_rows"]]
        fig, ax = plt.subplots(figsize=(10, 5))
        if n_xs:
            ax.scatter(n_xs, n_ttks, s=8, alpha=0.45, color="steelblue",  label="Normal enemy")
        if b_xs:
            ax.scatter(b_xs, b_ttks, s=60, alpha=0.85, color="crimson", marker="*", label="Boss kill")
        for y, color, label in [
            (1.0, "limegreen", "1 s (comfortable)"),
            (3.0, "orange",    "3 s (noticeable)"),
            (8.0, "red",       "8 s (friction)"),
        ]:
            ax.axhline(y=y, color=color, linestyle="--", linewidth=1, alpha=0.7, label=label)
        ax.set_title("Enemy Time-To-Kill Over Time")
        ax.set_xlabel("Session time (s)")
        ax.set_ylabel("TTK (s)")
        ax.legend(fontsize=8, loc="upper left")
        ax.grid(alpha=0.3)
        name = _save_fig(fig, out_dir, "enemy_ttk_over_time.png")
        if name:
            saved.append(name)
    except Exception as exc:
        print(f"  Warning: enemy_ttk_over_time.png failed: {exc}")

    # 3. Gold balance over time ───────────────────────────────────────────
    try:
        rows   = [r for r in m["all_rows"] if r.get("gold", "") != ""]
        g_xs   = [_f(r.get("timestamp_sec", 0)) for r in rows]
        g_vals = [_i(r.get("gold", 0))           for r in rows]
        fig, ax = plt.subplots(figsize=(10, 4))
        ax.plot(g_xs, g_vals, linewidth=1.5, color="goldenrod")
        ax.set_title("Gold Balance Over Time")
        ax.set_xlabel("Session time (s)")
        ax.set_ylabel("Gold")
        ax.grid(alpha=0.3)
        name = _save_fig(fig, out_dir, "gold_over_time.png")
        if name:
            saved.append(name)
    except Exception as exc:
        print(f"  Warning: gold_over_time.png failed: {exc}")

    # 4. Cumulative gold income by source ─────────────────────────────────
    try:
        fig, ax = plt.subplots(figsize=(10, 5))
        plotted = False

        def _cumsum_plot(xs, ys, label, color, ls="-"):
            if not xs:
                return
            acc, acc_list = 0, []
            for v in ys:
                acc += v
                acc_list.append(acc)
            ax.plot(xs, acc_list, label=label, color=color, linewidth=1.5, linestyle=ls)

        _cumsum_plot(
            [_f(r.get("timestamp_sec", 0)) for r in m["enemy_rows"]],
            [_i(r.get("enemy_reward_gold", 0)) for r in m["enemy_rows"]],
            "Kill rewards", "steelblue",
        )
        _cumsum_plot(
            [_f(r.get("timestamp_sec", 0)) for r in m["task_rows"]],
            [_i(r.get("task_reward_gold", 0)) for r in m["task_rows"]],
            "Task rewards", "seagreen", ls="--",
        )

        ax.set_title("Cumulative Gold Income by Source")
        ax.set_xlabel("Session time (s)")
        ax.set_ylabel("Cumulative gold")
        ax.legend(fontsize=9)
        ax.grid(alpha=0.3)
        name = _save_fig(fig, out_dir, "gold_income_events.png")
        if name:
            saved.append(name)
    except Exception as exc:
        print(f"  Warning: gold_income_events.png failed: {exc}")

    # 5. Purchase timeline ────────────────────────────────────────────────
    try:
        p_rows = m["purchase_rows"]
        if p_rows:
            cat_colors = {
                "hero_level":    "steelblue",
                "hero_skill":    "dodgerblue",
                "partner":       "seagreen",
                "partner_skill": "mediumseagreen",
                "building":      "darkorange",
                "ability_unlock":"crimson",
                "ability_rank":  "tomato",
                "shop":          "mediumpurple",
                "prestige_talent":"gold",
            }
            cats = sorted({r.get("purchase_category", "other") for r in p_rows})
            y_map = {c: i for i, c in enumerate(cats)}
            fig, ax = plt.subplots(figsize=(12, max(3, len(cats) * 0.55 + 1)))
            for r in p_rows:
                cat  = r.get("purchase_category", "other")
                ts   = _f(r.get("timestamp_sec", 0))
                color= cat_colors.get(cat, "gray")
                ax.scatter(ts, y_map.get(cat, len(cats)), s=35, color=color, alpha=0.75)
            ax.set_yticks(range(len(cats)))
            ax.set_yticklabels(cats, fontsize=9)
            ax.set_title("Purchase Timeline by Category")
            ax.set_xlabel("Session time (s)")
            ax.grid(alpha=0.3, axis="x")
            name = _save_fig(fig, out_dir, "purchase_timeline.png")
            if name:
                saved.append(name)
    except Exception as exc:
        print(f"  Warning: purchase_timeline.png failed: {exc}")

    # 6. Boss friction ────────────────────────────────────────────────────
    try:
        b_rows = m["boss_rows"]
        f_rows = m["fail_rows"]
        if b_rows or f_rows:
            fig, ax = plt.subplots(figsize=(10, 5))
            if b_rows:
                bk_xs  = [_f(r.get("timestamp_sec", 0)) for r in b_rows]
                bk_ttks= [_f(r.get("enemy_ttk_sec",  0)) for r in b_rows]
                bk_lvls= [_i(r.get("defeated_on_level") or r.get("current_level", 0)) for r in b_rows]
                ax.scatter(bk_xs, bk_ttks, s=90, color="steelblue", alpha=0.85,
                           marker="o", label="Boss defeated", zorder=3)
                for x, y, lvl in zip(bk_xs, bk_ttks, bk_lvls):
                    ax.annotate(f"L{lvl}", (x, y), xytext=(4, 4),
                                textcoords="offset points", fontsize=7, alpha=0.85)
            if f_rows:
                bf_xs  = [_f(r.get("timestamp_sec", 0)) for r in f_rows]
                bf_lvls= [_i(r.get("current_level", 0))  for r in f_rows]
                ax.scatter(bf_xs, [0] * len(bf_xs), s=130, color="crimson", alpha=0.9,
                           marker="X", label="Boss failed", zorder=3)
                for x, lvl in zip(bf_xs, bf_lvls):
                    ax.annotate(f"L{lvl} FAIL", (x, 0), xytext=(4, 6),
                                textcoords="offset points", fontsize=7,
                                color="crimson", alpha=0.9)
            ax.axhline(y=20, color="red", linestyle="--", linewidth=1,
                       alpha=0.5, label="20 s threshold")
            ax.set_title("Boss Friction — TTK and Fails Over Time")
            ax.set_xlabel("Session time (s)")
            ax.set_ylabel("Boss TTK (s)  |  0 = fail event")
            ax.legend(fontsize=9)
            ax.grid(alpha=0.3)
            name = _save_fig(fig, out_dir, "boss_friction.png")
            if name:
                saved.append(name)
    except Exception as exc:
        print(f"  Warning: boss_friction.png failed: {exc}")

    return saved


# ---------------------------------------------------------------------------
# Filtered subset CSVs
# ---------------------------------------------------------------------------

def write_subset_csvs(m: dict, out_dir: str, fieldnames: list[str]) -> list[str]:
    subsets = [
        ("enemy_events.csv",    m["enemy_rows"]),
        ("purchase_events.csv", m["purchase_rows"]),
        ("task_events.csv",     m["task_rows"]),
        ("ability_events.csv",  m["ability_rows"]),
        ("boss_events.csv",     m["boss_rows"] + m["fail_rows"]),
    ]
    written: list[str] = []
    for filename, rows in subsets:
        if not rows:
            continue
        # Prefer the canonical column order, then any extras found in these rows
        cols_seen: set[str] = set()
        for r in rows:
            cols_seen.update(r.keys())
        ordered = [c for c in fieldnames if c in cols_seen]
        extras  = sorted(cols_seen - set(ordered))
        final   = ordered + extras
        path    = os.path.join(out_dir, filename)
        try:
            with open(path, "w", newline="", encoding="utf-8") as fh:
                writer = csv.DictWriter(fh, fieldnames=final, extrasaction="ignore")
                writer.writeheader()
                writer.writerows(rows)
            written.append(filename)
        except Exception as exc:
            print(f"  Warning: could not write {filename}: {exc}")
    return written


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Analyze balance_playtest.csv from Godot debug logger."
    )
    parser.add_argument("csv_path", help="Path to balance_playtest.csv")
    parser.add_argument(
        "--out", default="balance_report",
        metavar="DIR", help="Output directory (default: balance_report/)"
    )
    args = parser.parse_args()

    csv_path = args.csv_path
    out_dir  = args.out

    # Validate input
    if not os.path.isfile(csv_path):
        print(f"ERROR: {csv_path} does not exist.", file=sys.stderr)
        sys.exit(1)

    # Prepare output dir
    os.makedirs(out_dir, exist_ok=True)

    print(f"Reading:  {csv_path}")
    rows, fieldnames = parse_csv(csv_path)
    print(f"  {len(rows)} rows, {len(fieldnames)} columns")

    if not rows:
        print("WARNING: CSV is empty — nothing to analyze.")
        sys.exit(0)

    print("Computing metrics ...")
    m = compute_metrics(rows)
    hints = generate_hints(m)

    print(f"Writing:  {out_dir}/summary.txt")
    write_summary(m, hints, out_dir, csv_path)

    print("Writing:  filtered subset CSVs ...")
    written_csvs = write_subset_csvs(m, out_dir, fieldnames)
    for f in written_csvs:
        print(f"  ->{f}")

    print("Generating graphs ...")
    saved_graphs = generate_graphs(m, out_dir)
    for g in saved_graphs:
        print(f"  ->{g}")

    # Console summary
    print()
    print("─" * 50)
    print(f"  Session     {_fmt_sec(m['session_sec'])}  ({m['session_sec']:.0f} s)")
    print(f"  Max level   {m['highest_level']}")
    print(f"  Enemies     {m['total_enemies']}  (bosses: {m['total_bosses']}, fails: {m['total_boss_fails']})")
    print(f"  Avg TTK     normal {m['avg_n']:.2f} s  |  boss {m['avg_b']:.2f} s")
    print(f"  Purchases   {m['purchases']}  tasks {m['tasks_claimed']}  abilities {m['abilities_used']}")
    print(f"  Hints       {len(hints)}")
    print("─" * 50)
    print(f"Report written to:  {Path(out_dir).resolve()}/")
    if not _MPL:
        print("  (install matplotlib for PNG graphs:  pip install matplotlib)")


if __name__ == "__main__":
    main()
