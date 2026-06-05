# Localization

## Overview

The game supports English (en) and Russian (ru). All player-facing strings live in a single CSV file. The `LocalizationManager` autoload loads that file at startup and provides runtime text lookup.

**Default language:** English (`en`).  
**Russian column:** initially empty — fill manually as needed.

---

## Source file

```
res://localization/game_text.csv
```

**Columns:**

| Column | Purpose |
|--------|---------|
| `key` | Stable localization key used by code. Never rename after first use. |
| `en` | English text (source of truth). |
| `ru` | Russian translation. Leave empty to auto-fallback to English. |
| `context` | Where this text appears (helps translators). |
| `notes` | Optional format notes, placeholder names, etc. |

**Example rows:**

```
key,en,ru,context,notes
ui.tab.upgrades,Upgrades,,Bottom navigation,
ui.progress.boss_time,Boss Time: {time}s,,ProgressInfoPanel boss timer,{time} = seconds as float string
```

---

## How to add new text

1. Add a row to `res://localization/game_text.csv`:
   ```
   my.new.key,English text,,Where it appears,
   ```
2. Use it in code:
   ```gdscript
   label.text = LocalizationManager.tr_key("my.new.key")
   ```
3. For strings with dynamic values, use placeholders `{name}` and `format_key`:
   ```gdscript
   label.text = LocalizationManager.format_key("ui.progress.hp_pair", {
       "current": NumberFormatter.compact(state.target_hp),
       "max": NumberFormatter.compact(state.target_max_hp),
   })
   ```

---

## API

**`LocalizationManager.tr_key(key: String) -> String`**  
Returns the translation for `key` in the current language. Falls back to English if Russian is empty. Returns `key` itself if missing (prints a debug warning in debug builds).

**`LocalizationManager.format_key(key: String, values: Dictionary = {}) -> String`**  
Same as `tr_key` but replaces `{placeholder}` tokens with values from the dictionary.

**`LocalizationManager.set_language(language_code: String) -> void`**  
Switches language. Emits `language_changed`. ClickerScreen listens and calls `_update_ui()`.

**`LocalizationManager.get_language() -> String`**  
Returns `"en"` or `"ru"`.

**`LocalizationManager.get_available_languages() -> Array[String]`**  
Returns `["en", "ru"]`.

**`LocalizationManager.language_changed` (signal)**  
Emitted after language switch. UI panels react via `_update_ui()` in ClickerScreen.

---

## Fallback behavior

| Situation | Result |
|-----------|--------|
| Russian selected, `ru` column empty | Falls back to English text |
| Key missing entirely | Returns the key string; debug warning in debug builds |
| Unsupported language code | Clamped to `"en"` |

---

## Language persistence

Selected language is saved in `state.language` alongside `sound_enabled` / `music_enabled` in the existing save file (`user://save_v1.json`). No save version bump — old saves load without `language` and default to `"en"`.

Applied on startup in `ClickerScreen._ready()` before the first `_update_ui()` call.

---

## Switching language at runtime

Open **Settings → Language** and tap the language button to cycle between English and Русский. The UI refreshes immediately; the choice is saved automatically.

---

## What NOT to localize

Do not create localization keys for:

- Save keys (field names in JSON)
- Config IDs (`"autoclick"`, `"gold_pack_small"`, etc.)
- Asset keys (`"upgrade.hero"`, `"stage.auto_on"`, etc.)
- Debug console output
- CSV logger headers
- Analytics/logger field names
- Internal task/partner/ability IDs

---

## Adding Russian translations

Open `res://localization/game_text.csv` in any text editor or spreadsheet. Fill the `ru` column. No code changes needed — the fallback chain handles empty fields during development.

Keep the file UTF-8 encoded. Quote any field that contains a comma: `"text, with comma"`.

---

## Partner name keys

Partner names use keys `partner.01.name` through `partner.28.name` in `game_text.csv`.

28 partner name keys are defined. Partners 14–28 have English text only; Russian column is empty and falls back to English automatically.

---

## Enemy name keys

Enemy names are resolved through localization keys at display time.

| Enemy type | Key format | Example |
|------------|-----------|---------|
| Normal enemy | `enemy.pool_XX.enemy_YY.name` | `enemy.pool_01.enemy_03.name` |
| Elite enemy  | `enemy.pool_XX.elite_YY.name` | `enemy.pool_11.elite_02.name` |
| Boss         | `zone.XX.boss`                | `zone.07.boss` |

Pool numbers match the shared pool folder: `pool_01`, `pool_11`, `pool_17`.

`ClickerState.enemy_name_key` is set by `choose_enemy_for_current_level()` whenever a new enemy is selected. It is **runtime-derived and not saved** — it is always recalculated from the selected candidate on `setup_current_level()` / `reset_target()`.

`ProgressInfoPanel` resolves the display name with this priority:
1. `LocalizationManager.tr_key(enemy_name_key)` — if the key resolves to something other than the key itself.
2. `state.enemy_name` — raw English fallback from config.

When adding a new enemy slot to `EnemyPoolConfig`, add a matching `name_key` field and a corresponding row in `game_text.csv`.

### Validating enemy localization keys

```
godot --headless --script res://scripts/tools/ValidateLocalization.gd
```

Checks all `enemy.pool_XX.*` and `zone.XX.boss` keys exist in the CSV. Missing `en` values are errors (exit 1); missing `ru` values are warnings (exit 0).

---

## Export requirements and built-in fallback

`game_text.csv` is the editable source of truth, but raw CSV files are not guaranteed to be readable via `FileAccess` in all Android export configurations.

To ensure translations are always available, `LocalizationManager` uses a two-source load strategy:

### Runtime load order

1. **Built-in `LocalizationData.gd`** — loaded first via `preload`. Because it is a GDScript file, it is always included in Android and Web exports automatically.
2. **CSV override from `localization/game_text.csv`** — loaded second if available. If it loads successfully, its values replace the built-in values (allowing hotfix without a full re-export).

If the CSV is unavailable, the built-in data is used silently. The game displays correctly on all platforms.

### Keeping LocalizationData.gd in sync

`LocalizationData.gd` is auto-generated from `game_text.csv`. After editing the CSV, regenerate it:

```
godot --headless --script res://scripts/tools/GenerateLocalizationData.gd
```

Commit the updated `LocalizationData.gd` to the repository.

**Do not edit `LocalizationData.gd` by hand.** It will be overwritten by the generator.

### Export presets

Both Web and Android export presets also include the CSV via `include_filter`:

```
include_filter="localization/*.csv"
```

This gives the CSV a chance to load at runtime, but is not the primary reliability mechanism — `LocalizationData.gd` is.

### Startup diagnostics

In debug builds, `LocalizationManager` prints:

```
LocalizationManager: built-in keys en=234 ru=120, csv_loaded=true/false
```

If translations fail to load entirely, `ClickerScreen` pushes:

```
No localization translations loaded. UI will display keys. builtin=true csv=false en=0 ru=0
```

This appears in Android logcat and the browser console.

### Validation command

```
godot --headless --script res://scripts/tools/ValidateLocalizationExport.gd
```

Checks:
- `LocalizationData.gd` built-in data has required keys with non-empty English values
- CSV exists, can be opened, and has required columns and keys
- CSV key count matches built-in key count (flags out-of-sync)
- Both Web and Android export presets include `localization/*.csv` in `include_filter`

---

## Current 4-row card localization keys

### PartnerPanel

| Key | Usage |
|-----|-------|
| `partner.name_count` | Row 1 — partner name and owned count |
| `partner.damage_summary` | Row 2 — DPS gain and total |
| `partner.milestone_next` | Row 3 — next x2 milestone level |
| `partner.milestone_max` | Row 3 — shown when all milestones are reached |
| `partner.hire_button` | Hire button text |

### UpgradePanel (Hero)

| Key | Usage |
|-----|-------|
| `upgrade.hero.name_level_short` | Row 1 — hero level |
| `upgrade.hero.damage_summary` | Row 2 — damage gain and current damage |
| `upgrade.hero.milestone_next` | Row 3 — next x2 milestone level |
| `upgrade.hero.milestone_max` | Row 3 — shown when all milestones are reached |
| `upgrade.hero.button` | Upgrade button text |

### UpgradePanel (Ability)

Active ability cards show 4 text rows. Hero card is intentionally unchanged.

| Key | Usage |
|-----|-------|
| `upgrade.ability.card.name` | Row 1 — ability name |
| `upgrade.ability.card.rank` | Row 2 — rank/max rank |
| `upgrade.ability.card.effect` | Row 3 — effect (passthrough `{effect}`) |
| `upgrade.ability.card.duration` | Row 4 — duration (passthrough `{duration}`) |
| `upgrade.ability.duration_seconds` | Duration string: "Duration {seconds}s" |
| `upgrade.ability.unlock_with_duration` | Row 4 for locked abilities: "Unlock at Lv {level} \| {duration}" |
| `upgrade.ability.purchased` | Button label when already purchased |
| `upgrade.ability.requires_level` | Button label when locked by level |
| `upgrade.ability.buy` | Button label when available to purchase |

### Deprecated 3-row card keys (removed)

These keys were used in the old compact card layout and have been removed:

- `partner.name_header` — replaced by `partner.name_count`
- `partner.dps_next_milestone` — replaced by `partner.damage_summary` + `partner.milestone_next`
- `partner.dps_max` — replaced by `partner.milestone_max`
- `partner.requires_previous` — hiring no longer requires previous partner ownership
- `upgrade.hero.name_level` — replaced by `upgrade.hero.name_level_short`
- `upgrade.hero.damage_info` — replaced by `upgrade.hero.damage_summary` + `upgrade.hero.milestone_next`
- `upgrade.hero.damage_max` — replaced by `upgrade.hero.milestone_max`

Do not use these keys in new UI code.

---

## Known gaps

- **Scene-file static labels** (e.g. row labels in `SettingsWindow.tscn`): not yet localized. Requires editing `.tscn` scene files or adding Label references and setting text in `_ready()`.
- **Skill descriptions** (`get_ability_description`, `get_prestige_talent_description`, `get_building_short_effect_description`): currently generated in `ClickerStatePresentation.gd` using English format strings. Future work: add localized format strings to those generators.
