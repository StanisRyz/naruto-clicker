# C7.2.5 — Obsolete Reset Progress / GuestMigrationPrompt Cleanup Validation

## Overview

- Searched the whole repo for `Reset Progress`, `reset progress`,
  `settings.reset*`, `reset_confirm`, `reset_requested`, `GuestMigrationPrompt`,
  `guest_migration`, `save_guest_progress_confirmed`, and `not_now_confirmed`,
  and classified every hit (runtime code, scene/node, localization key, asset
  catalog reference, physical asset file, active docs, historical validation
  note).
- Confirmed the C7.2.1 Reset Progress runtime/localization removal was already
  complete — no code or CSV changes were needed there.
- Deleted the two files that were unreferenced-but-retained since C7.1.1
  (`GuestMigrationPrompt.gd`/`.tscn`) and the reset-confirm background image
  left over from C7.2.1, and removed the `guest_migration.*` localization keys
  that only that deleted script used.
- Updated active docs (`README.md`, `AGENTS.md`, `docs/rustore_readiness_checklist.md`,
  `docs/release_build_checklist.md`) so they no longer present Reset Progress or
  GuestMigrationPrompt as current production features.
- Added forward-pointer notes to historical validation docs that described the
  old flows, without rewriting their point-in-time content.

---

## Classification of Search Results

| Hit | Classification | Action |
|---|---|---|
| `scenes/ui/SettingsWindow.gd:324` comment "replaces Reset Progress" | Historical code comment | Kept — accurate context, not a live reference |
| `scripts/tools/SaveIntegrityDebugReport.gd:68` `"-- reset progress preservation --"` | Debug tool label for internal preserved-snapshot logic (unrelated to the removed UI) | Kept — not the removed feature |
| `scenes/auth/AuthGateScreen.gd` `_reset_confirm_box`, `_on_reset_confirm_submit`, `auth.reset_confirm_button` | Password-reset flow (unrelated "reset" meaning) | Kept — out of scope, do not touch |
| `localization/game_text.csv` reset keys (`settings.reset_progress`, etc.) | Localization key | Already absent (removed in C7.2.1); verified, no action needed |
| `scripts/ui/GameAssetCatalog.gd` reset_confirm_background key | Asset catalog reference | Already absent (removed in C7.2.1); verified, no action needed |
| `assets/images/ui/windows/settings/reset_confirm_background.png` (+`.import`) | Physical unused asset file | **Deleted** (no remaining code/catalog/doc reference required them) |
| `scenes/ui/GuestMigrationPrompt.gd`/`.tscn` (+`.gd.uid`) | Scene/script files, unreferenced since C7.1.1 | **Deleted** |
| `localization/game_text.csv` `guest_migration.*` (6 keys) | Localization keys, only used by the deleted script | **Deleted** |
| `README.md` / `AGENTS.md` prose describing Reset Progress / GuestMigrationPrompt as current | Active product documentation | **Rewritten** to reflect current state; historical changelog entries kept but marked superseded/obsolete |
| `docs/rustore_readiness_checklist.md`, `docs/release_build_checklist.md` | Active release checklists | **Updated** — no longer ask to test a removed UI feature |
| `docs/validation/reset_progress_removal.md`, `account_save_authority_guest_shop_lock.md`, `guest_to_account_migration_validation.md`, `backend_cloud_save_stabilization.md`, `manual_backend_cloud_sync_validation.md` | Historical validation notes | **Annotated** with forward-pointers marking the described flow as removed/obsolete; original point-in-time content preserved |
| `docs/ASSET_MAP.md`, `docs/PROJECT_STRUCTURE.md` | Active docs | Already clean (updated in C7.2.1); verified, no action needed |

---

## Checklist

- [x] `SettingsWindow.gd` has no `reset_requested` signal, no reset button
      handlers, no `reset_confirm_dialog`/`reset_confirm_button` references.
- [x] `SettingsWindow.tscn` has no Reset Progress button or reset confirmation
      dialog node.
- [x] `ClickerScreen.gd` has no Settings reset signal connection or
      `_on_settings_reset_confirmed()` method.
- [x] No production UI path calls `SaveManager.delete_save()` (only the
      `BuildConfig.IS_DEBUG_BUILD`-gated `KEY_F10` hotkey remains).
- [x] Reset-progress-only localization keys (`settings.reset_progress`,
      `settings.confirm_reset`, `settings.progress_reset`, `settings.reset`,
      `settings.reset_confirm_title`, `settings.reset_confirm_description`) are
      absent from `localization/game_text.csv` (confirmed already removed by
      C7.2.1; no new removal needed this patch).
- [x] `assets/images/ui/windows/settings/reset_confirm_background.png` and its
      `.import` file are deleted.
- [x] `scenes/ui/GuestMigrationPrompt.gd`, `.tscn`, and `.gd.uid` are deleted;
      no runtime references remain anywhere in the repo.
- [x] `localization/game_text.csv` has no `guest_migration.*` keys.
- [x] README does not describe Reset Progress or GuestMigrationPrompt as
      active/current features; historical changelog sections are marked
      superseded/removed where they describe those flows.
- [x] AGENTS.md protects against reintroducing both flows in production UI and
      documents Account/Cloud as the Reset Progress replacement.
- [x] Account / Cloud is documented in README as the current
      progress-management UI (Sound, Music, Language, Save Now, Account/Cloud,
      Version — no Reset Progress).
- [x] Backend Cloud Functions, backend API paths, `SaveManager` cloud-save
      logic, Guest → Login/Register logic, `CloudRestorePrompt`, paid shop lock
      logic, payment/RuStore flow, rewarded ads, gameplay balance, and
      Web/Yandex behavior are all unmodified by this patch (docs/localization/
      asset cleanup only).

---

## Static / Tooling Checks

```bash
godot --headless --editor --quit
godot --headless --script res://scripts/tools/GenerateLocalizationData.gd
godot --headless --script res://scripts/tools/ValidateLocalizationDataFreshness.gd
godot --headless --script res://scripts/tools/ValidateLocalizationExport.gd
git status
git diff --stat
```

**Results (run during C7.2.5 implementation):**
- `godot --headless --editor --quit` — no errors (confirms deleting
  `GuestMigrationPrompt.gd/.tscn` broke no scene references).
- `GenerateLocalizationData.gd` — generated 453 keys (459 → 453, 6
  `guest_migration.*` keys removed).
- `ValidateLocalizationDataFreshness.gd` — PASS (453/453 keys, 0 errors, 0 warnings).
- `ValidateLocalizationExport.gd` — PASS (453 EN keys, 449 RU values, 0 errors).

---

## Files Changed in C7.2.5

| File | Change |
|------|--------|
| `scenes/ui/GuestMigrationPrompt.gd` | Deleted (unreferenced since C7.1.1) |
| `scenes/ui/GuestMigrationPrompt.tscn` | Deleted (unreferenced since C7.1.1) |
| `scenes/ui/GuestMigrationPrompt.gd.uid` | Deleted |
| `assets/images/ui/windows/settings/reset_confirm_background.png` | Deleted (unreferenced since C7.2.1) |
| `assets/images/ui/windows/settings/reset_confirm_background.png.import` | Deleted |
| `localization/game_text.csv` | Removed 6 `guest_migration.*` keys |
| `scripts/ui/LocalizationData.gd` | Regenerated from CSV (453 keys) |
| `README.md` | Added "Current Settings model and account rules" summary; marked C5.4 section superseded |
| `AGENTS.md` | Updated GuestMigrationPrompt rule (files now deleted, not just unreferenced); added docs-cleanup-must-not-touch-backend-flow rule |
| `docs/rustore_readiness_checklist.md` | Reset Progress row updated to reflect removal |
| `docs/release_build_checklist.md` | Reset Progress checklist item updated to reflect removal |
| `docs/validation/reset_progress_removal.md` | Known Limitations updated — assets/files now confirmed deleted |
| `docs/validation/account_save_authority_guest_shop_lock.md` | GuestMigrationPrompt "retained" note updated to "deleted" |
| `docs/validation/guest_to_account_migration_validation.md` | Added obsolete/historical banner |
| `docs/validation/backend_cloud_save_stabilization.md` | Added obsolete/historical banner on section 5 |
| `docs/validation/manual_backend_cloud_sync_validation.md` | Reworded stale "Reset Progress" row |
| `docs/validation/obsolete_reset_and_guest_migration_cleanup.md` | New validation doc (this file) |

---

## Known Limitations

- None. This patch only removed confirmed-dead files/keys and updated
  documentation; no runtime behavior changed.
