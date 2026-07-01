# C7.2.1 — Reset Progress Removal Validation

## Overview

- Reset Progress button, confirmation dialog, and signal flow removed from
  `SettingsWindow.tscn` / `SettingsWindow.gd`.
- `ClickerScreen.gd` no longer connects to a Settings reset signal and no longer
  calls `SaveManager.delete_save()` from any production UI path.
- Reset-progress-only localization keys removed from `localization/game_text.csv`;
  `scripts/ui/LocalizationData.gd` regenerated.
- Internal reset/runtime helpers, prestige reset logic, and clean-account-save
  logic (Guest → Login with no cloud save) are unchanged.
- Web/Yandex behavior, backend Cloud Functions, and gameplay balance are unchanged.

---

## Cleanup Checklist

- [x] `SettingsWindow.tscn` has no `ResetButton` node under the main panel.
- [x] `SettingsWindow.tscn` has no `ResetConfirmDialog` node.
- [x] `SettingsWindow.tscn` `load_steps` reduced (unused `reset_panel` / `reset_button`
      style boxes removed).
- [x] `SettingsWindow.gd` has no `reset_requested` / `reset_confirmed` signals.
- [x] `SettingsWindow.gd` has no `reset_button`, `reset_confirm_dialog`,
      `reset_cancel_button`, `reset_confirm_button` references.
- [x] `SettingsWindow.gd` has no `_on_reset_button_pressed`, `_hide_reset_confirm`,
      `_on_reset_cancel_pressed`, `_on_reset_confirm_button_pressed`,
      `_on_reset_confirm_overlay_gui_input` methods.
- [x] `ClickerScreen.gd` has no `settings_window.reset_requested.connect(...)` line.
- [x] `ClickerScreen.gd` has no `_on_settings_reset_confirmed()` method.
- [x] No production UI handler calls `SaveManager.delete_save()`.
- [x] `localization/game_text.csv` has no `settings.reset_progress`,
      `settings.confirm_reset`, `settings.progress_reset`, `settings.reset`,
      `settings.reset_confirm_title`, `settings.reset_confirm_description` rows.
- [x] `GameAssetCatalog.gd` has no `ui.window.settings.reset_confirm_background` key.
- [x] Save/Account/Cloud Save/Sound/Music/Language controls in `SettingsWindow` unchanged.
- [x] `_reset_runtime_state_for_new_game()`, `state.reset_to_new_game()`,
      `state.get_reset_progress_preserved_snapshot()`,
      `state.apply_reset_progress_preserved_snapshot()` remain in the codebase
      (used by prestige and clean account save paths).
- [x] `SaveManager.delete_save()` remains defined (internal/tool use); no production
      caller remains.

---

## Manual Checklist

### Android Guest
- [ ] Open Settings on Android Guest session.
- [ ] Reset Progress button/section is not visible.
- [ ] Save/Cloud Save/Sound/Music/Language controls still work.

### Android Account
- [ ] Open Settings on Android Account session.
- [ ] Reset Progress button/section is not visible.
- [ ] Save to Cloud / Load from Cloud still work.
- [ ] Login/Register/Logout controls still work.

### Prestige
- [ ] Prestige still resets current level, max unlocked level, and normal run
      progress as before; prestige points/talents survive.

### Guest → Login with no cloud save
- [ ] Login from Guest with an account that has no cloud save still starts a clean
      account save (no guest progress carried over).

### Debug-only save deletion
- [x] No production UI path (Settings or otherwise) can delete or reset the save.
- [x] `ClickerScreen._input()` `KEY_F10 → SaveManager.delete_save()` debug hotkey
      (`scenes/game/ClickerScreen.gd:1749-1751`) remains gated behind
      `if not BuildConfig.IS_DEBUG_BUILD: return` (line 1715) — unavailable in a
      release build. Untouched by this patch.

### Web / Yandex
- [ ] Web build Settings window unaffected beyond Reset Progress removal (same
      behavior as Android for sound/music/language/save).
- [ ] Yandex cloud-save behavior unchanged.

---

## Static / Tooling Checks

```bash
# Confirm no compile errors
godot --headless --editor --quit

# Regenerate and validate localization
godot --headless --script res://scripts/tools/GenerateLocalizationData.gd
godot --headless --script res://scripts/tools/ValidateLocalizationDataFreshness.gd
godot --headless --script res://scripts/tools/ValidateLocalizationExport.gd

# Review changed files
git status
git diff --stat
```

**Results (run during C7.2.1 implementation):**
- `godot --headless --editor --quit` — no errors.
- `GenerateLocalizationData.gd` — generated 455 keys.
- `ValidateLocalizationDataFreshness.gd` — PASS (455/455 keys, 0 errors, 0 warnings).
- `ValidateLocalizationExport.gd` — PASS (455 EN keys, 451 RU values, 0 errors).

---

## Files Changed in C7.2.1

| File | Change |
|------|--------|
| `scenes/ui/SettingsWindow.tscn` | Removed `ResetButton` node, `ResetConfirmDialog` subtree, and unused reset style boxes |
| `scenes/ui/SettingsWindow.gd` | Removed `reset_requested`/`reset_confirmed` signals, reset button/dialog `@onready` vars, reset button labels, and all reset handler methods |
| `scenes/game/ClickerScreen.gd` | Removed `settings_window.reset_requested.connect(...)` and `_on_settings_reset_confirmed()` |
| `localization/game_text.csv` | Removed 6 reset-progress-only keys |
| `scripts/ui/LocalizationData.gd` | Regenerated from CSV (455 keys) |
| `scripts/ui/GameAssetCatalog.gd` | Removed `ui.window.settings.reset_confirm_background` asset key |
| `docs/ASSET_MAP.md` | Removed reset confirm background/button references |
| `docs/PROJECT_STRUCTURE.md` | Updated `SettingsWindow` row description |
| `README.md` | Added C7.2.1 section, updated QA checklist and Save/reset rules |
| `AGENTS.md` | Added rule against reintroducing production-UI reset |

---

## Known Limitations

- ~~`assets/images/ui/windows/settings/reset_confirm_background.png` (and its
  `.import` file) are left on disk but are no longer referenced by any asset key~~
  — **removed in C7.2.5** (`docs/validation/obsolete_reset_and_guest_migration_cleanup.md`).
- ~~`GuestMigrationPrompt.gd/.tscn` (unrelated, retained from C7.1.1) are unaffected
  by this patch~~ — **`GuestMigrationPrompt.gd/.tscn` deleted in C7.2.5** (confirmed
  unreferenced at runtime since C7.1.1); see
  `docs/validation/obsolete_reset_and_guest_migration_cleanup.md`.
