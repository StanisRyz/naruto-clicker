# Android Auth Gate — Startup Order Validation Checklist

Patch: C3.1 — Fix Android AuthGate startup ordering (ClickerScreen lazy instantiation)
Date: 2026-06-28

## Problem this patch fixes

In Godot 4, child `_ready()` runs before parent `_ready()`. The original C3
implementation kept `ClickerScreen` as a pre-instanced child in `Main.tscn`.
This meant `ClickerScreen._ready()` (which loads local save, initializes gameplay,
starts music, and emits `startup_completed`) ran **before** `Main._ready()` could
show the AuthGate. The auth gate was visually overlaying an already-initialized game.

## What changed

- `Main.tscn` — removed pre-instanced `ClickerScreen` child node and its `ext_resource`.
- `Main.gd` — `ClickerScreen` is now instantiated lazily:
  - Android: only after `auth_gate_completed` fires.
  - Web / Editor: immediately in `_ready()`, preserving existing behavior.

---

## Static checks

```bash
# Confirm LocalizationData.gd is still fresh
godot --headless --script res://scripts/tools/ValidateLocalizationDataFreshness.gd

# Confirm required keys exist and export presets include the CSV
godot --headless --script res://scripts/tools/ValidateLocalizationExport.gd

# Confirm editor opens without errors
godot --headless --editor --quit

git status
git diff --stat
```

> Note: headless validation cannot be run in the current environment (no PATH `godot` binary).
> Run in the Godot editor manually.

---

## Manual checklist

### Main.tscn structure

- [ ] Open `scenes/main/Main.tscn` in the editor.
      Scene tree shows only `Main` (Control) with no children.
      No `ClickerScreen` child node exists in the scene file.

### Web / Editor (no auth gate — behavior unchanged)

- [ ] Start the game in the Godot editor (LocalDebug platform).
      `ClickerScreen` appears immediately; gameplay starts normally.
      No AuthGate shown.
- [ ] Start the exported Web build.
      `ClickerScreen` appears immediately; gameplay starts normally.
      No AuthGate shown.
- [ ] Yandex `notify_yandex_game_ready()` is still called after `startup_completed`.
- [ ] `Platform.game_ready()` is still called correctly for non-Yandex Web.

### Android — auth gate appears BEFORE gameplay initializes

- [ ] Launch on Android with no stored session (fresh install).
- [ ] AuthGateScreen appears over a dark background.
      Game music has NOT started. Save has NOT been loaded. Gameplay is NOT visible.
- [ ] Logcat: no "ClickerScreen" `_ready` log lines appear before auth gate completes.

### Android — guest mode ordering

- [ ] Tap "Continue as Guest" on AuthGate.
- [ ] AuthGate is removed.
- [ ] `ClickerScreen` is instantiated and added to the scene tree.
- [ ] `ClickerScreen._ready()` runs: save is loaded, music starts, gameplay appears.
- [ ] `startup_completed` / `game_ready` flow completes normally.

### Android — login ordering

- [ ] Enter valid credentials and tap Sign In.
- [ ] On `auth_gate_completed("account")`, AuthGate removed, `ClickerScreen` instantiated.
- [ ] Gameplay initializes and starts normally after login.

### Android — valid existing session ordering

- [ ] Existing valid token present.
- [ ] AuthGate shows "Checking account..." briefly.
- [ ] `get_me` succeeds → `auth_gate_completed("account")` → `ClickerScreen` instantiated.
- [ ] No double initialization (no double `startup_completed`).

### Android — invalid stored token

- [ ] Corrupt token in `user://backend_auth.json`.
- [ ] AuthGate shows checking state, then "Session expired. Please sign in."
- [ ] Login form appears. `ClickerScreen` is NOT instantiated yet.
- [ ] After login success, `ClickerScreen` is instantiated once.

### Double-init guard

- [ ] Rapidly trigger multiple auth gate completions (if possible in test).
      `ClickerScreen` is instantiated only once (`_startup_started` guard).

### SaveManager isolation

- [ ] Confirm `SaveManager` does not call `Platform.backend_load_save()` or
      `Platform.backend_save_save()` in this patch.
- [ ] Local save loads correctly in all modes (guest, account, web, editor).

### Security / logging

- [ ] No passwords, session tokens, or reset codes appear in Logcat.

---

## Files changed in C3.1

| File | Change |
|------|--------|
| `scenes/main/Main.tscn` | Removed pre-instanced ClickerScreen child + ext_resource |
| `scenes/main/Main.gd` | Lazy ClickerScreen instantiation; `_start_game_after_auth_gate`; `get_startup_auth_mode()` |
| `README.md` | Updated C3 section with C3.1 ordering fix |
| `docs/AGENTS.md` | Added Main.tscn/Main.gd startup ordering rules |
| `docs/validation/android_auth_gate_startup_order_validation.md` | This file |

## Not changed in C3.1

- `scenes/auth/AuthGateScreen.gd` / `.tscn` — unchanged.
- `ClickerScreen.gd` / `.tscn` — unchanged.
- Platform layer, SaveManager, backend client — unchanged.
- Gameplay, ads, payments, balance — unchanged.
- Web/Yandex/LocalDebug platform implementations — unchanged.
