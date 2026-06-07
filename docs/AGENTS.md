# Agent & Implementation Notes

## Bottom sheet vertical offset

All bottom sheet scenes (UpgradeSheet, PartnerSheet, SettlementSheet, PrestigeSheet, ShopSheet) use:

```
anchor_top = 0.5
anchor_bottom = 1.0
offset_bottom = -155.0
```

The `-155.0` offset keeps sheets above the 125×125 bottom tab buttons (BottomBar height ≈ 145px, 10px safe gap above).

If the bottom tab button height changes, update `offset_bottom` in all five sheet `.tscn` files together.

---

## Button focus cleanup — ButtonVisualUtils

`res://scripts/ui/ButtonVisualUtils.gd` provides static helpers for removing focus/pressed artifacts.

### Which method to use

| Button type | Method |
|-------------|--------|
| Image-only button (ImageSlot child fills it, no visible text) | `ButtonVisualUtils.clear_image_button_styles(button)` |
| Standard text button (Buy, Hire, Claim, Close, Save, Reset, etc.) | `ButtonVisualUtils.disable_focus_artifact(button)` |

### Rules

- `clear_image_button_styles()` removes **all** native Button visuals (normal, hover, pressed, disabled, focus) and sets `flat = true`. Use only for buttons whose entire visual is provided by a child `ImageSlot`.
- `disable_focus_artifact()` removes only the **focus** stylebox and sets `focus_mode = FOCUS_NONE`. Normal hover/pressed styling is preserved. Safe to call on text buttons.
- `disable_focus_artifacts_in_tree(root)` recursively calls `disable_focus_artifact` on every Button under `root`. Use after initial UI build or full panel rebuilds, not every frame.

### Where cleanup is applied

**Static image-only buttons** (applied in `ClickerScreen._ready()` via `_apply_button_visual_cleanup()`):
- `TasksButton`
- `UpgradesButton`, `PartnersButton`, `SettlementButton`, `PrestigeButton`, `ShopButton`

**Dynamic text buttons** (applied at creation time in each panel script):
- `UpgradePanel` — UpgradeButton / BuyButton (text), skill buttons (image → `clear_image_button_styles`)
- `PartnerPanel` — HireButton (text), skill buttons (image → `clear_image_button_styles`)
- `SettlementPanel` — BuyButton (text)
- `PrestigePanel` — PrestigeButton, UpgradeButton (text)
- `ShopPanel` — BuyButton (text)
- `TasksWindow` — claim_button (text)
- `BuyModeSelector` — X1/X10/X100/Max buttons (text, applied in `_ready()`)

**Tree-wide sweep** (applied in `ClickerScreen._ready()` after `_update_ui()`):
- `ButtonVisualUtils.disable_focus_artifacts_in_tree(self)` covers any remaining static buttons not handled individually.

### Adding new buttons

- New image-only button → call `ButtonVisualUtils.clear_image_button_styles(button)` after creating it.
- New text button → call `ButtonVisualUtils.disable_focus_artifact(button)` after creating it.

---

## Localization workflow

### Auto-sync plugin

`addons/localization_sync/LocalizationSyncPlugin.gd` runs inside the Godot editor and polls `game_text.csv` every 2 seconds. When it detects a file change it calls `LocalizationDataGenerator.generate()` and writes `scripts/ui/LocalizationData.gd`, then triggers a filesystem scan.

**Result:** editing and saving `game_text.csv` automatically regenerates `LocalizationData.gd` with no manual step.

If the plugin is not running (disabled, CI, headless), run the manual fallback:

```
godot --headless --script res://scripts/tools/GenerateLocalizationData.gd
```

### Why LocalizationData.gd freshness matters for Android/Web

On Android and Web, `FileAccess` may not be able to read raw files from `res://`. The CSV is included in the export via `include_filter` and loaded as an overlay when available, but it is not guaranteed to be readable.

`LocalizationData.gd` is a GDScript file — it is compiled into the export PCK and is always available. It is the primary reliability mechanism. If it is stale at export time, Android/Web users see old text.

**Commit both `game_text.csv` and `LocalizationData.gd` together every time you edit strings.** Never commit one without the other.

### Validation before export

Run these before every Android/Web export:

```
# Verify LocalizationData.gd matches CSV exactly
godot --headless --script res://scripts/tools/ValidateLocalizationDataFreshness.gd

# Verify required keys exist and export presets include the CSV
godot --headless --script res://scripts/tools/ValidateLocalizationExport.gd
```

Exit 0 = pass. Exit 1 = fix required before exporting.

### Adding or changing localization keys

1. Add/edit a row in `res://localization/game_text.csv`.
2. Save — the editor plugin regenerates `LocalizationData.gd` automatically.
3. Reference the key in code via `LocalizationManager.tr_key("key")` or `format_key("key", {...})`.
4. Run `ValidateLocalizationDataFreshness.gd` to confirm sync.
5. Commit both files.

See `docs/LOCALIZATION.md` for key naming conventions, the full API, and the Android troubleshooting checklist.
