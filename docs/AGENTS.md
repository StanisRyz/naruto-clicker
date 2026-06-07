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

### Export hook (mandatory — primary mechanism)

`addons/localization_sync/LocalizationSyncPlugin.gd` registers an `EditorExportPlugin` that regenerates `LocalizationData.gd` immediately before every export begins. This runs for Android, Web, and all other platforms.

You will see this in the Output panel during export:

```
LocalizationSyncPlugin: regenerating LocalizationData.gd before export...
LocalizationSyncPlugin: generated N localization keys.
```

Android/Web builds cannot ship stale localization as long as the plugin is enabled (`Project → Project Settings → Plugins → Localization Sync`).

### Editor file watcher (convenience — not the reliability mechanism)

The same plugin polls `game_text.csv` every 2 seconds while the editor is open and regenerates `LocalizationData.gd` on change. This is for development convenience — the export hook is the mandatory protection.

### Why LocalizationData.gd freshness matters for Android/Web

On Android and Web, `FileAccess` may not be able to read raw files from `res://`. The CSV is included in exports via `include_filter` as an optional overlay, but it is not guaranteed to be readable on device.

`LocalizationData.gd` is a GDScript file compiled into the export PCK — it is always available. If it is stale at export time, Android/Web users see old text. The export hook prevents this.

**Commit both `game_text.csv` and `LocalizationData.gd` together every time you edit strings.**

### Validation before export

```
# Confirm LocalizationData.gd matches CSV exactly
godot --headless --script res://scripts/tools/ValidateLocalizationDataFreshness.gd

# Confirm required keys exist and export presets include the CSV
godot --headless --script res://scripts/tools/ValidateLocalizationExport.gd
```

Exit 0 = pass. Exit 1 = fix required before exporting.

### Adding or changing localization keys

1. Add/edit a row in `res://localization/game_text.csv`.
2. Save — the file watcher regenerates `LocalizationData.gd` within 2 seconds.
3. Reference the key in code via `LocalizationManager.tr_key("key")` or `format_key("key", {...})`.
4. Run `ValidateLocalizationDataFreshness.gd` to confirm sync.
5. Commit both files.
6. Export — the export hook regenerates again immediately before packaging.

See `docs/LOCALIZATION.md` for key naming conventions, the full API, and the Android troubleshooting checklist.
