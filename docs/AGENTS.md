# Agent & Implementation Notes

## Backend API Client (scripts/platform/backend/)

- `BackendAuthStore.gd` — auth-only persistence class (`user://backend_auth.json`).
  No Node inheritance; instantiate directly. Never log `session_token`.
- `BackendApiClient.gd` — extends Node; owns one `HTTPRequest` child.
  One active request at a time. Call `set_auth_store(store)` and `configure(url)` before use.
- All backend operations must be accessed through `Platform`, not directly from gameplay or UI.
- `AndroidRuStorePlatform.gd` is the Android/RuStore backend implementation.
  It creates `BackendAuthStore` + `BackendApiClient` in `_ready()` and delegates all
  `Platform.backend_*` calls to the client. It is the only place backend SDK calls may live.
- Web/Yandex Games cloud-save uses `YandexBridge`/`WebYandexPlatform` — entirely separate.
  Backend operations on Web fail with `not_supported` via inherited `PlatformServices` stubs.
- The backend stores a raw JSON blob. `save_version` and `last_save_unix_time` must
  be present in the save data; the backend validates them. The client does not.
- Backend error strings are passed through verbatim. UI layers translate them for display.
- `configure_from_project_settings()` reads `application/cloud_save/backend_url` from
  `ProjectSettings`. This URL is committed in `project.godot` as a public endpoint — not a secret.
- **Never log backend passwords, session tokens, reset codes, verification codes, or full save JSON.**
- **Do not commit backend secrets.** Only the public API Gateway URL belongs in `project.godot`.

---

## Android Auth Gate (scenes/auth/AuthGateScreen)

- `AuthGateScreen` is shown on Android startup before gameplay, instantiated by `Main.gd`.
- It is **not** shown on Web/Yandex or in the editor/LocalDebug — the `OS.has_feature("android")`
  check in `Main._should_show_android_auth_gate()` is the single gate.
- `AuthGateScreen` must call backend only through `Platform` — never call `BackendApiClient` directly.
- `AuthGateScreen` must not call `SaveManager` and must not know cloud-save internals.
- Guest mode (`auth_gate_completed("guest")`) enters gameplay with local save only. Backend
  cloud-save is not wired to `SaveManager` yet — guest and account modes are both local-only.
- `Platform.backend_clear_local_auth()` — local-only token removal, no network request.
  Call it when `get_me` returns `unauthorized` so the stale token is cleared before showing login.
- Do not add account settings panel UI in the same patch as the auth gate.
- Do not auto-upload guest save after login in the same patch as the auth gate.
- Do not implement save conflict resolution in the same patch as the auth gate.
- Web/Yandex startup must never be blocked by backend auth checks.
- **Never log passwords, session tokens, reset codes, or verification codes anywhere in the auth flow.**

## Main.tscn / Main.gd startup ordering

- **`Main.tscn` must NOT contain a pre-instanced `ClickerScreen` child.** In Godot 4,
  child `_ready()` runs before parent `_ready()`. A pre-instanced `ClickerScreen` would
  initialize gameplay (load save, start music, emit `startup_completed`) before `Main._ready()`
  can show the AuthGate.
- `Main.gd` instantiates `ClickerScreen` lazily via `_instantiate_clicker_screen()`.
  - Android: `ClickerScreen` is added only after `auth_gate_completed` fires.
  - Web / Editor: `ClickerScreen` is added immediately in `_ready()` via `_start_game_after_auth_gate("web_or_local")`.
- Do not call `YandexBridge` directly from `Main.gd`. All platform calls go through `Platform`.
- The `_startup_started` flag in `Main.gd` prevents double-instantiation of `ClickerScreen`.
- `get_startup_auth_mode()` returns `"account"`, `"guest"`, or `"web_or_local"` for future
  save-wiring use. Do not use it to gate gameplay in this patch.

---

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

## Settlement buildings — always unlocked, equal base cost

All six Settlement buildings are visible and purchasable immediately. There are no prerequisites or progressive-reveal rules.

`ClickerState.can_buy_building(index)` returns `true` for any valid index regardless of what else the player owns.

`BalanceConfig.BUILDING_BASE_COST = 500` — single value, all buildings share it. `BUILDING_BASE_COSTS` is an array of six identical copies. `BUILDING_COST_GROWTH = 1.22` is shared.

`settlement.requires` localization key was removed — do not reference it.

Validation: `godot --headless --script res://scripts/tools/ValidateSettlementBalance.gd`

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

---

## Android ad unit ids — rules

- **Ad unit ids live only in `scripts/game/config/AdPlacementConfig.gd`** (`android_ad_unit_id` field per placement). Do not hardcode ids anywhere else.
- **Do not grant rewards in Kotlin/Java plugin code.** The `AndroidYandexAdsPlugin` emits `rewarded_ad_rewarded`; the reward is applied exclusively in `ClickerScreen._on_rewarded_ad_rewarded()`.
- **Do not add new ad formats** (e.g. banner, app-open) without an explicit request. Only `rewarded` and `fullscreen` types exist.
- **Do not change reward logic when updating ad unit ids.** Updating `android_ad_unit_id` values must never touch reward amounts, reward types, or reward handler code.
