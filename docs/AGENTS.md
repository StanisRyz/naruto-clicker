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
