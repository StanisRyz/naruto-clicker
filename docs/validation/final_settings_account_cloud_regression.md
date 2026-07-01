# C7.2.6 — Final Settings / Account / Cloud / Shop Regression + Fixed-Size Window Audit

## Overview

Final hardening pass across the whole C7.2 series (C7.2.1–C7.2.5). This patch is
audit-and-document only: the code review found no functional regressions or
UI-state bugs requiring a fix, so **no `.gd`/`.tscn` files were changed**. It
also audits fixed-size textured windows against the "no dynamic resize based on
content" rule and records one pre-existing (non-C7.2) finding.

---

## 1. Obsolete-Flow Search

Searched the whole repo for `reset_requested`, `Reset Progress`, `settings.reset`,
`reset_confirm`, `GuestMigrationPrompt`, `guest_migration`,
`save_guest_progress_confirmed`, `not_now_confirmed`.

- [x] No runtime references to the Reset Progress user flow remain.
- [x] No runtime references to `GuestMigrationPrompt` remain (files deleted in C7.2.5).
- [x] Remaining hits are all false positives or historical docs:
  - `scenes/auth/AuthGateScreen.gd` `_reset_confirm_box` / `_on_reset_confirm_submit` /
    `auth.reset_confirm_button` — **password-reset** flow, unrelated "reset" meaning. Untouched.
  - `scripts/tools/SaveIntegrityDebugReport.gd:68` `"-- reset progress preservation --"` —
    debug label for the internal preserved-snapshot mechanism (prestige/clean-account-save),
    not the removed UI feature. Untouched.
  - `scenes/ui/SettingsWindow.gd:324` — historical code comment ("replaces Reset Progress"),
    accurate context, not a live reference.
  - All `docs/validation/*.md` and `README.md`/`AGENTS.md` hits describe the old flows
    as removed/obsolete (C7.2.1, C7.1.1, C7.2.5 banners) — no active-feature framing remains.

## 2. SettingsWindow Signal Contract

`scenes/ui/SettingsWindow.gd` declares exactly:
`sound_toggled`, `music_toggled`, `save_requested`, `language_manually_changed`,
`account_auth_requested`, `cloud_save_upload_requested`, `cloud_save_download_requested`.

- [x] No `reset_requested` / `reset_confirmed` signal present.
- [x] `scenes/game/ClickerScreen.gd` connects exactly these 7 signals
      (`ClickerScreen.gd:148-154`) — no extra, no missing, no reset connection.

## 3. Account / Cloud State Review (code-read verification)

**Android Guest** (`_refresh_account_section_state()` when `Platform.backend_has_session() == false`):
- [x] Account/Cloud section visible (gated by `_is_backend_account_ui_supported()` = Android only).
- [x] Guest explanation label visible (`_account_guest_warning_label.visible = not has_session`).
- [x] Sign in/Register button visible (`_account_sign_in_button.visible = not has_session`).
- [x] Cloud Save/Load buttons hidden (`_refresh_cloud_section()`: `visible = has_session`).
- [x] Paid shop locked (`ClickerScreen._is_paid_shop_available()` returns
      `Platform.backend_has_session()` on Android → `false` for Guest).

**Android Account** (`has_session == true`):
- [x] Account status visible ("Signed in").
- [x] Email visible (`_account_email_label.visible = has_session`).
- [x] Email verification state visible (`_account_verification_label.visible = has_session`).
- [x] Verify Email visible only when unverified (`has_session and not verified`).
- [x] Logout visible (`_account_logout_button.visible = has_session`).
- [x] Cloud Save/Load visible.
- [x] Paid shop available.

**After Logout** (`_on_account_backend_op_succeeded("logout")` /
`_on_account_backend_op_failed("logout")`):
- [x] `_clear_account_verification_input()` + `_refresh_account_section_state()` return
      Settings to Guest state (code-verified: `has_session` becomes `false`, cloud
      buttons re-hide via `_refresh_cloud_section()`).
- [x] Cloud Save/Load hide (same `_refresh_cloud_section()` call).
- [x] Paid shop locks again (`Platform.backend_auth_changed` fires on logout →
      `ClickerScreen._on_platform_backend_auth_changed` → `_update_shop_paid_availability()`).
- [x] No stale message bug: both the success and failure logout branches call the
      state-only `_refresh_account_section_state()` (not the full `_refresh_account_section()`)
      *before* showing their message, so "Logged out" / "Local session cleared" persists
      instead of being wiped (fixed in C7.2.3; re-verified here, still correct).
- [x] `GemPurchaseDialog` closes on logout if it was open
      (`_update_shop_paid_availability()`: `if not paid_available and ... gem_purchase_dialog.visible: hide_dialog()`).

## 4. Account/Cloud Busy-State

- [x] Verify Email / Confirm Code / Logout all guard re-entrancy via
      `if _account_action_busy: return` at the top of their handlers
      (`_on_account_verify_email_pressed`, `_on_account_confirm_code_pressed`,
      `_on_account_logout_pressed`).
- [x] `_set_account_actions_busy(true)` called before every backend call;
      `_set_account_actions_busy(false)` called in every success/failure branch of
      `_on_account_backend_op_succeeded`/`_on_account_backend_op_failed`, plus
      defensively in `_on_account_backend_auth_changed` — no path leaves buttons
      stuck disabled.
- [x] Save to Cloud / Load from Cloud buttons: `ClickerScreen` calls
      `settings_window.set_cloud_save_buttons_busy(true)` before
      `Platform.backend_save_save()`/`backend_load_save()` and `(false)` in every
      success/failure/timeout branch (7 call sites, balanced: 2 `true` starts, 5
      `false` releases across all exit paths — verified by grep, unchanged from C5.1–C6.1).
- [x] Account messages (`_account_action_label` via `_show_account_action()`) and
      Cloud messages (`_cloud_status_label` via `set_cloud_save_status()`) remain
      fully separate label instances; no cross-writes found in either direction.

## 5. AuthGate Overlay Entry Points

- **Settings → Sign in/Register** (`_on_account_sign_in_pressed()` → `account_auth_requested.emit()`
  → `ClickerScreen._on_settings_account_auth_requested()` → Main.gd overlay): unchanged, guarded
  by `_account_action_busy`.
- **Shop locked donation entry** (`ClickerScreen._on_shop_product_purchase_requested()`):
  shows `shop_sheet.show_status(...)` then calls `main.show_auth_gate_overlay()` — unchanged
  from C7.2.4.
- [x] Guest → Register uploads current guest save to new account cloud (C7.1,
      `on_account_registered_from_guest_overlay()` — untouched).
- [x] Guest → Login force-loads account cloud save, never uploads guest save (C7.1,
      `on_account_login_from_guest_overlay()` — untouched).
- [x] No `GuestMigrationPrompt` reference anywhere in either path (file deleted, C7.2.5).
- [x] `CloudRestorePrompt` is not shown during the Guest → Login overlay flow (unchanged
      rule: "Do not show `CloudRestorePrompt` for the Guest → Login force-load flow").

## 6. CloudRestorePrompt (Direct Account Startup)

- [x] `scenes/ui/CloudRestorePrompt.gd`/`.tscn` were not touched by any C7.2 patch —
      confirmed by diff history (C7.2.1–C7.2.5 touched only `SettingsWindow`,
      `ShopSheet`/`ShopPanel`, `ClickerScreen.gd` shop/settings sections, localization,
      and docs/deleted files).
  `AGENTS.md` §"CloudRestorePrompt" rules are unaffected. Startup restore, Load
  Cloud Progress, Keep Local, and backend auto-upload suspension/resume are all
  untouched by this series.

## 7. Shop Paid Lock Regression

Re-verified `scenes/ui/ShopPanel.gd`/`ShopSheet.gd`/`ClickerScreen.gd` (C7.2.4 code):

- [x] `donation_entry` card shows the locked/account-required visual
      (`shop.paid_guest_locked_action` button text + `shop.paid_guest_locked_short`
      description + muted tint) when `paid_shop_available == false`.
- [x] `rewarded_ad` and all other product types render exactly as before —
      `paid_shop_available` only branches on `product_type == "donation_entry"`.
- [x] Tapping the locked donation entry shows `shop_sheet.show_status(...)` then
      opens the AuthGate overlay; does not call `gem_purchase_dialog.show_dialog()`.
- [x] `_on_gem_product_purchase_requested()` guard
      (`if not _is_paid_shop_available(): return`) precedes any
      `Platform.purchase_product()` call — unreachable in Guest.
- [x] Android Account: donation entry opens `GemPurchaseDialog` normally.
- [x] After Guest → Register/Login, `_update_shop_paid_availability()` is called
      (existing C7.1 call sites), unlocking the card without needing to
      close/reopen the shop sheet.
- [x] After Logout, `_on_platform_backend_auth_changed` → `_update_shop_paid_availability()`
      locks the card again and hides `GemPurchaseDialog` if it was open.
- [x] Rewarded ads confirmed unaffected — no code path in C7.2.4 touches
      `_request_shop_rewarded_gems_ad()` or ad reward logic.

## 8. Fixed-Size Textured Window Audit

| Window | Background type | Sizing | Touched by C7.2.x? | Finding |
|---|---|---|---|---|
| `SettingsWindow.tscn`/`.gd` | Textured (`ImageSlot`, `ui.window.settings.background`) | `PanelContainer` fixed `custom_minimum_size = Vector2(540, 525)` in `.tscn` | ~~Runtime override to `offset_top/bottom = ∓437` (height 874) in `_create_account_section()` when Android~~ **RESOLVED in C7.2.7** — the non-proportional override was removed entirely; the panel now stays fixed at `540×525` on every platform. Overflowing content (Sound/Music/Language/Save/Version/Account/Cloud, below the header) scrolls inside a new internal `BodyScrollContainer` instead. See `docs/validation/settings_window_fixed_aspect_ratio_cleanup.md`. | **No longer applicable** — was a pre-existing, non-proportional resize predating the C7.2 series (from C4); fixed in C7.2.7 by preserving the fixed size and adding internal scrolling rather than a proportional resize (which would have required a ~899px width, exceeding the 720px mobile viewport). |
| `ShopSheet.tscn`/`.gd` | Textured (`ImageSlot`, `ui.sheet.standard`, `STRETCH_SCALE`) | Anchor-based bottom sheet (`anchors_preset = 12`, proportional to viewport, not a fixed pixel window) — this is the existing adaptive-bottom-sheet design, unrelated to the fixed-window rule | C7.2.4 added `_locked_status_label` inside the existing `VBoxContainer`; sheet outer bounds are anchor-driven, not content-driven | No regression — the new label sits above the existing `ScrollContainer` (`size_flags_vertical = 3`), which absorbs any extra content height; the sheet's outer anchor rect is unaffected by card/label content length. |
| `ShopPanel.gd` cards | Textured (`ImageSlot`, `ui.card.sheet` / button assets) | Fixed constants (`CARD_OUTER_HEIGHT = 156`, `CARD_BUTTON_SIZE = Vector2(210, 72)`, etc.) | C7.2.4 changed only `.text`/`.modulate` on existing labels/buttons — no size constant touched | No regression — card dimensions unchanged; locked-state text uses the same fixed-width, ellipsis-truncating labels as the normal state. |
| `GemPurchaseDialog.tscn` | Textured | Fixed `custom_minimum_size = Vector2(620, 620)` (square) | Not touched by any C7.2 patch — only `.hide_dialog()`/`.show_dialog()` called externally | No regression. |
| `CloudRestorePrompt.tscn` | Procedural `StyleBoxFlat` (no texture) | `custom_minimum_size = Vector2(500, 0)` | Not touched by any C7.2 patch | Out of scope for the textured-window aspect-ratio rule (no texture to distort); untouched regardless. |
| `AuthGateScreen.gd` | Procedural `StyleBoxFlat` (no texture) | `custom_minimum_size = Vector2(340, 520)` used as a **minimum**, not a hard cap — panel can grow with `_reset_request_box`/`_reset_confirm_box`/etc. content | Not touched by any C7.2 patch (only unrelated password-reset code lives here) | Out of scope for the textured-window rule (no texture); pre-existing minimum-size behavior, unaffected by this series. |
| `ShopPurchaseConfirmDialog.tscn`, `PrestigeConfirmDialog.tscn`, `UpgradeSkillPopup.tscn`, `PartnerSkillPopup.tscn`, `TasksWindow.tscn` | Textured | All fixed `custom_minimum_size` (e.g. 500×230, 500×350, 350×270, 350×270, 620×670) | Not touched by any C7.2 patch | No regression — confirmed unmodified by the whole C7.2 series. |

**Conclusion:** No new dynamic or content-driven textured-window resizing was
introduced by the C7.2 series. One pre-existing non-proportional resize
(`SettingsWindow` panel height override from C4) was identified and documented
here; it was **resolved in C7.2.7** by preserving the fixed panel size and
adding an internal `ScrollContainer`, rather than by a proportional resize
(which was evaluated and rejected — see
`docs/validation/settings_window_fixed_aspect_ratio_cleanup.md` for the full
analysis).

## 9. Web/Yandex Regression

- [x] `_is_backend_account_ui_supported()` (Android-only) and
      `_is_paid_shop_available()` (`true` unconditionally off-Android) both
      unchanged — Web/editor still show no Account/Cloud section and always
      have the paid shop available.
- [x] No Android backend auth gate introduced on Web (unchanged startup routing
      in `Main.gd`, untouched by C7.2 series).
- [x] Yandex SDK cloud-save path (`YandexBridge`/`WebYandexPlatform`) untouched.

## 10. Signal / Reference Cleanup Check

- [x] No references to deleted `GuestMigrationPrompt.gd`/`.tscn` remain anywhere
      (verified via repo-wide grep and `godot --headless --editor --quit`,
      which would fail to load `ClickerScreen.tscn` if a broken ext_resource existed).
- [x] No references to the deleted `reset_confirm_background` asset remain.
- [x] No broken `.tscn` external resources (editor headless load succeeds with
      no errors).
- [x] No duplicate backend/platform signal connections — `Platform.backend_auth_changed`,
      `backend_operation_succeeded`, `backend_operation_failed` are each connected
      exactly once in `ClickerScreen.gd` (guarded by `is_connected()`) and once in
      `SettingsWindow.gd` (guarded by `_account_signals_connected`).
- [x] No deleted localization key is still referenced — `ValidateLocalizationExport.gd`
      and `ValidateLocalizationDataFreshness.gd` both pass (453/453 keys).

---

## Static / Tooling Checks

```bash
godot --headless --editor --quit
godot --headless --script res://scripts/tools/ValidateLocalizationDataFreshness.gd
godot --headless --script res://scripts/tools/ValidateLocalizationExport.gd
git status
git diff --stat
```

**Results (run during C7.2.6 audit):**
- `godot --headless --editor --quit` — no errors.
- `ValidateLocalizationDataFreshness.gd` — PASS (453/453 keys, 0 errors, 0 warnings).
- `ValidateLocalizationExport.gd` — PASS (453 EN keys, 449 RU values, 0 errors).
- No localization keys were added/changed in this patch, so
  `GenerateLocalizationData.gd` was not required to run (ran anyway as a sanity
  check; produced no diff).

---

## Manual Checklist (for on-device follow-up)

- [ ] Android Guest opens Settings — Account/Cloud Guest state correct, Cloud
      Save/Load hidden.
- [ ] Android Guest opens Shop — donation entry locked, rewarded ad available.
- [ ] Locked donation entry opens AuthGate overlay with status message.
- [ ] Guest → Register uploads guest save and unlocks paid shop immediately.
- [ ] Guest → Login force-loads account cloud save and unlocks paid shop immediately.
- [ ] Android Account Settings shows email/status/cloud controls; Verify Email /
      Confirm Code / Logout busy-states behave correctly.
- [ ] Save to Cloud / Load from Cloud busy-states behave correctly.
- [ ] Logout returns Settings and Shop to Guest state; closes `GemPurchaseDialog`
      if open.
- [ ] Direct account startup `CloudRestorePrompt` still works (Load Cloud
      Progress / Keep Local, auto-upload suspension resumes).
- [ ] Reset Progress and GuestMigrationPrompt remain absent everywhere.
- [ ] Fixed-size windows (Settings, Shop, GemPurchaseDialog, confirm dialogs,
      skill popups, TasksWindow) do not visibly grow beyond their designed
      dimensions on any device/text-length combination.
- [ ] Web/Yandex Settings/Shop/cloud-save behavior unchanged.

---

## Files Changed in C7.2.6

| File | Change |
|------|--------|
| `docs/validation/final_settings_account_cloud_regression.md` | New validation doc (this file) — audit findings, no code changes required |
| `README.md` | Added C7.2.6 note |
| `AGENTS.md` | Added fixed-size textured window rules and Settings/UI-regression-must-not-touch-backend rule |

No `.gd`/`.tscn` files were modified — the audit found no functional
regressions or UI-state bugs in the C7.2.1–C7.2.5 series.

---

## Known Limitations

- ~~`SettingsWindow` panel height override (`offset_top/bottom = ∓437`) remains a
  non-proportional, pre-existing resize from C4... recommended as a follow-up
  patch if the product owner wants the aspect ratio corrected.~~ —
  **resolved in C7.2.7**: see
  `docs/validation/settings_window_fixed_aspect_ratio_cleanup.md`. The panel is
  now fixed-size on every platform; overflow content scrolls internally.
