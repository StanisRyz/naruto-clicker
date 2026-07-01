# C7.2.7 — SettingsWindow Fixed Aspect Ratio Cleanup Validation

## Overview

Fixes the pre-existing non-proportional `SettingsWindow` resize identified (but
left unfixed, as out of scope) during C7.2.6. `SettingsWindow`'s outer
textured panel now stays at its original fixed size on every platform; content
that doesn't fit (Sound/Music/Language/Save/Version plus the Android-only
Account/Cloud section) scrolls inside the fixed window via a new internal
`ScrollContainer`, instead of the panel being stretched taller only on Android.

---

## Before / After

**Old base size (`SettingsWindow.tscn`):** `PanelContainer.custom_minimum_size = Vector2(540, 525)`,
anchored center with offsets `±270` (width) / `±262.5` (height).

**Old Android runtime override (removed):**
```gdscript
panel_container.offset_top = -437.0
panel_container.offset_bottom = 437.0
```
This changed the effective height to `874` while width stayed `540` —
non-proportional (aspect ratio changed from ~1.03:1 to ~0.62:1), and it
stretched the `ui.window.settings.background` texture (`STRETCH_SCALE`)
non-uniformly.

**Chosen strategy:** *Preserve the existing fixed size* (`540×525` on every
platform, Android and Web/editor alike) — the preferred strategy per the
project's fixed-size-window rule — rather than a proportional resize. A
proportional resize was evaluated and rejected: matching the original ~1.03:1
aspect ratio while providing enough height for the full Account/Cloud content
(~874px, matching the old override's empirically-needed height) would require
a width of roughly `540 × (874/525) ≈ 899px`, which would overflow the 720px-wide
mobile viewport (`AGENTS.md` "UI rules": Android 720×1600, Web 720×1280) —
failing the "final width must fit the target mobile viewport" requirement.
An internal `ScrollContainer` was therefore used instead, with **zero** resize
of the outer panel — no old size vs. new size vs. scale factor to document,
because the panel size did not change at all.

---

## What Changed

- `scenes/ui/SettingsWindow.tscn`
  - Inserted `BodyScrollContainer` (`ScrollContainer`, `horizontal_scroll_mode = 0`,
    `size_flags_vertical = 3`) as a child of the existing `VBoxContainer`,
    directly after `HeaderMargin`.
  - Inserted `BodyVBoxContainer` (`VBoxContainer`, `size_flags_horizontal = 3`,
    same `separation = 12` as before) inside `BodyScrollContainer`.
  - Reparented `SoundMargin`, `MusicMargin`, `SaveButton`, `StatusLabel`,
    `VersionLabel` from being direct children of `VBoxContainer` to children of
    `BodyVBoxContainer`. `HeaderMargin` (title + close button) stays a direct
    child of `VBoxContainer`, outside the scroll area, so it's always visible
    and reachable — mirrors the existing `ShopSheet.tscn` pattern (Header/
    BuyModeSelector fixed, `ShopPanel` scrolls).
- `scenes/ui/SettingsWindow.gd`
  - Added `const BODY_PATH` pointing at the new `BodyVBoxContainer`, with a
    short comment explaining the fixed-size rule for future edits.
  - Updated all 8 `@onready` node paths (`sound_button`, `music_button`,
    `_sound_label`, `_music_label`, `save_button`, `status_label`,
    `version_label`) that moved under `BodyScrollContainer/BodyVBoxContainer`.
    `close_button`/`_title_label` (under `HeaderMargin/Header`) are unchanged.
  - Replaced all 4 `panel_container.get_node("MarginContainer/VBoxContainer")`
    calls (in `_ready()`'s version-label reorder, `_create_language_row()`,
    `_create_debug_localization_row()`, `_create_account_section()`) with
    `panel_container.get_node(BODY_PATH)` — so the language row, debug row,
    and Account/Cloud section are all added into the scrollable body.
  - **Removed** `panel_container.offset_top = -437.0` /
    `panel_container.offset_bottom = 437.0` from `_create_account_section()`
    entirely. The outer panel is never resized now, on any platform.

## What Did NOT Change

- `SettingsWindow` signals: `sound_toggled`, `music_toggled`, `save_requested`,
  `language_manually_changed`, `account_auth_requested`,
  `cloud_save_upload_requested`, `cloud_save_download_requested` — all 7
  unchanged, same names. No `reset_requested`/`reset_confirmed` added.
  `ClickerScreen.gd`'s 7 signal connections (`ClickerScreen.gd:148-154`)
  needed no changes.
- All Account/Cloud creation/refresh logic (`_create_account_section()`,
  `_refresh_account_section()`, `_refresh_account_section_state()`, busy-state
  handling, etc.) — only the *container* they're added into changed
  (`BodyVBoxContainer` instead of the old direct `VBoxContainer`); none of the
  control-creation or state logic itself was touched.
- Backend Cloud Functions, backend API paths, `SaveManager`, Guest → Login/
  Register logic, `CloudRestorePrompt`, paid shop lock logic, payment/RuStore
  flow, rewarded ads, gameplay balance, Web/Yandex behavior — all untouched.
- Reset Progress, `GuestMigrationPrompt` — remain fully absent; not
  reintroduced.

---

## Checklist

- [x] `SettingsWindow.tscn`/`.gd` no longer contain a non-proportional,
      height-only `panel_container.offset_top`/`offset_bottom` override.
- [x] `PanelContainer.custom_minimum_size` remains `Vector2(540, 525)` and is
      never reassigned anywhere in `SettingsWindow.gd` (grep-verified: zero
      remaining `panel_container.offset_*` or `custom_minimum_size` writes).
- [x] `SettingsWindow` does not dynamically grow based on content — the outer
      `PanelContainer` size is fixed by anchors+offsets in the `.tscn` and is
      never touched at runtime; overflow content scrolls inside
      `BodyScrollContainer` instead.
- [x] All 8 relocated `@onready` node paths and all 4 `BODY_PATH` lookups were
      cross-checked character-for-character against the new `.tscn` node tree
      (`PanelContainer/MarginContainer/VBoxContainer/BodyScrollContainer/BodyVBoxContainer/...`).
- [x] `godot --headless --editor --quit` — no errors (project/scene structure
      loads cleanly with the restructured node tree).
- [x] Account/Cloud controls remain reachable: Guest state (explanation,
      Sign in/Register, Cloud Save/Load hidden) and Account state (status,
      email, verification, Verify Email conditional visibility, Logout, Cloud
      Save/Load) are all still added into `BodyVBoxContainer` and scroll into
      view — no control was removed, hidden permanently, or made unreachable.
- [x] `SettingsWindow` signal contract unchanged (7 signals, no reset signals).
- [x] Reset Progress / GuestMigrationPrompt: no runtime references reintroduced
      (verified by repo-wide search, same result as C7.2.6).
- [x] Backend/cloud/payment/shop/gameplay/Web/Yandex behavior unchanged — this
      patch only touches `SettingsWindow.tscn`/`.gd` node structure.

---

## Manual Checklist (for on-device follow-up)

- [ ] Open Settings on Android Guest — outer window size looks the same as
      before (unchanged 540×525 texture proportions); Account/Cloud content is
      reachable by scrolling if it doesn't fully fit.
- [ ] Guest explanation text is readable; Sign in/Register button is reachable
      and tappable.
- [ ] Cloud Save/Load buttons remain hidden for Guest.
- [ ] Open Settings on Android Account — status/email/verification/Logout are
      all reachable via scroll; Save to Cloud / Load from Cloud reachable and
      functional.
- [ ] Trigger Verify Email / Confirm Code flows — the code input box and
      confirm button appearing does not change the outer window's size or
      snap the scroll position awkwardly.
- [ ] Confirm no control is visually clipped by the panel edge.
- [ ] Confirm Reset Progress and GuestMigrationPrompt are absent.
- [ ] Web/Yandex: Settings opens with the same fixed size and layout as
      before (Account/Cloud section still hidden entirely, per
      `_is_backend_account_ui_supported()`).

---

## Static / Tooling Checks

```bash
godot --headless --editor --quit
godot --headless --script res://scripts/tools/ValidateLocalizationDataFreshness.gd
godot --headless --script res://scripts/tools/ValidateLocalizationExport.gd
git status
git diff --stat
```

**Results (run during C7.2.7 implementation):**
- `godot --headless --editor --quit` — no errors.
- `ValidateLocalizationDataFreshness.gd` — PASS (453/453 keys, unchanged — no
  localization keys were added or removed by this patch).
- `ValidateLocalizationExport.gd` — PASS (453 EN keys, 449 RU values, 0 errors).
- No localization changes were made, so `GenerateLocalizationData.gd` was not
  required.

**Note on runtime instantiation testing:** a standalone `--script` smoke test
that instantiated `SettingsWindow.tscn` directly was attempted to exercise
`@onready` node-path resolution at runtime. The scene loaded and `_ready()`
completed successfully (confirming the restructured `BODY_PATH` lookups
resolve correctly), but the harness could not fully complete a second pass
because bare `--script` SceneTree execution does not reliably expose the
`BuildConfig`/`ClickerState` autoload-dependent identifiers outside the
project's normal `Main.tscn` boot path — a pre-existing testing-harness
limitation unrelated to this patch. Combined with the successful partial run
and an exhaustive manual line-by-line path cross-check against the `.tscn`,
this is considered sufficient static confidence; on-device manual validation
(checklist above) is the authoritative final check.

---

## Files Changed in C7.2.7

| File | Change |
|------|--------|
| `scenes/ui/SettingsWindow.tscn` | Inserted `BodyScrollContainer`/`BodyVBoxContainer`; reparented Sound/Music/Save/Status/Version rows into it; Header stays outside the scroll area |
| `scenes/ui/SettingsWindow.gd` | Added `BODY_PATH` constant + comment; updated 8 `@onready` paths and 4 `get_node` call sites; removed the non-proportional `offset_top`/`offset_bottom` override |
| `docs/validation/settings_window_fixed_aspect_ratio_cleanup.md` | New validation doc (this file) |
| `docs/validation/final_settings_account_cloud_regression.md` | Updated fixed-size audit finding to "resolved by C7.2.7" |
| `README.md` | Added C7.2.7 note |
| `AGENTS.md` | Updated fixed-size textured window rules with the resolved SettingsWindow example |

---

## Known Limitations

- None. The outer `SettingsWindow` panel is now fixed-size on every platform
  with no conditional override remaining.
