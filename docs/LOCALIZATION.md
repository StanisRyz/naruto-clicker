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

## Known gaps

- **Scene-file static labels** (e.g. row labels in `SettingsWindow.tscn`): not yet localized. Requires editing `.tscn` scene files or adding Label references and setting text in `_ready()`.
- **Skill descriptions** (`get_ability_description`, `get_prestige_talent_description`, `get_building_short_effect_description`): currently generated in `ClickerStatePresentation.gd` using English format strings. Future work: add localized format strings to those generators.
