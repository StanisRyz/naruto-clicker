# Tasks

## Task pool file

```
res://scripts/game/config/TaskConfig.gd
```

All task definitions live here. This is the single source of truth for the task pool.

`TaskConfig.ACTIVE_TASK_COUNT` controls how many tasks are shown at once (currently 5).

---

## How to add a task

1. Add an entry to `TASK_DEFINITIONS` in `TaskConfig.gd`:

```gdscript
{
    "id": "your_task_id",           # stable save id — never rename after release
    "title": "English fallback",    # debug/fallback text
    "title_key": "task.your_task_id.title",  # localization key
    "goal_type": "enemies_defeated_delta",   # one of GOAL_TYPES
    "target_delta": 50,             # progress required when task becomes active
    "reward_scale": 8,              # multiplier on the current reward unit
}
```

2. Add the localization key to `res://localization/game_text.csv`:

```
task.your_task_id.title,Your task condition text,Ваш текст задачи,TasksWindow task card row 1,
```

3. Add the task icon asset and catalog entry:

   - Place icon at: `res://assets/images/tasks/your_task_id.png`
   - Add to `GameAssetCatalog.gd` asset map:
     ```
     "task.your_task_id": "res://assets/images/tasks/your_task_id.png",
     ```
   - Key format: `task.<id>` (automatically resolved by `GameAssetCatalog.task_icon_key(id)`)

4. If using a new goal type:

   - Add it to `TaskConfig.GOAL_TYPES`
   - Implement it in `TaskRuntime._get_task_current_value()`

5. Run validation:

```
godot --headless --script res://scripts/tools/ValidateTaskConfig.gd
```

---

## Supported goal types

| Goal type | Tracks |
|---|---|
| `manual_damage_delta` | Total manual click damage dealt |
| `enemies_defeated_delta` | Total enemies defeated |
| `elite_enemies_defeated_delta` | Total elite enemies defeated |
| `bosses_defeated_delta` | Total bosses defeated |
| `hero_level_delta` | Character level gained |
| `partners_total_delta` | Total partner hires (across all partners) |
| `buildings_total_delta` | Total buildings built (across all buildings) |
| `autoclick_activations_delta` | Times autoclick was activated |
| `game_level_delta` | Game levels advanced |

All delta types snapshot the current counter when the task becomes active and track progress from that point.

---

## Validation script

```
godot --headless --script res://scripts/tools/ValidateTaskConfig.gd
```

Checks:
- No empty or duplicate task ids
- All `title_key` values are non-empty and present in `game_text.csv` with a non-empty English string
- All `goal_type` values are in `TaskConfig.GOAL_TYPES`
- All `target_delta` and `reward_scale` values are positive
- Pool has at least `ACTIVE_TASK_COUNT` definitions
- All task ids resolve to a valid path in `GameAssetCatalog`
- Missing PNG files are reported as warnings (art pending is allowed)

Exits 0 on pass, 1 on any error.

---

## Runtime ownership

| Concern | Owner |
|---|---|
| Task definitions | `TaskConfig.gd` |
| Active task count | `TaskConfig.ACTIVE_TASK_COUNT` |
| Progress tracking | `TaskRuntime.gd` |
| Reward calculation | `TaskRuntime.gd` |
| Claim / rotation | `TaskRuntime.gd` |
| Task icon paths | `GameAssetCatalog.gd` |
| Task card UI | `TasksWindow.gd` |
