# Y5-code — Yandex Submission Metadata and Compliance Docs

Docs-only patch. Prepares the repository-side part of Yandex Games
resubmission after Y1–Y4: canonical title documentation, draft field
templates, product id checklist, and media compliance checklist. No
gameplay, payment, save, or ad logic was touched.

## Files inspected

- `project.godot` — `config/name`.
- `export_presets.cfg` — Web preset (SDK init, unchanged), Android preset
  `package/name` / `package/unique_name`.
- `README.md`, `AGENTS.md`.
- `localization/game_text.csv`, `scripts/ui/LocalizationData.gd`.
- `scripts/game/config/GemPurchaseConfig.gd`.
- `docs/validation/yandex_release_audit_platform_separation.md` (Y1).
- `docs/validation/yandex_payments_catalog_price_display.md` (Y4).
- `docs/ASSET_MAP.md`, `docs/PROJECT_STRUCTURE.md` (checked for existing
  media/promo doc references — none found).
- `docs/rustore_readiness_checklist.md`, `docs/android_release_validation.md`
  (checked for existing app-title references, cross-platform consistency).

## Title consistency search summary

Searched the repo for game title strings: `project.godot`,
`export_presets.cfg`, `README.md`, `docs/*.md`, and
`localization/game_text.csv` (grepped for `title`/`app_name`/`game_name`
keys).

Findings:

- **No in-game visible title** — no `LocalizationManager` key, splash
  screen, or menu label shows the game's name to the player. All
  title-shaped localization keys found (`settings.title`, `shop.gem_purchase.title`,
  `auth.title`, etc.) are UI panel headers ("Settings", "Buy Gems", "Sign
  In"), not the game's own title.
- **`Shinobi Clicker: Idle`** is the established EN store/app title —
  configured in `project.godot` (`config/name`) and `export_presets.cfg`
  (Android `package/name`), and already used consistently in
  `docs/rustore_readiness_checklist.md` and `docs/android_release_validation.md`
  for the Android/RuStore submission.
- **`README.md` line 1 and `docs/PROJECT_STRUCTURE.md`** reference "Naruto
  Clicker" / "Anime Ninja Idle Clicker" — this is internal repo/dev naming
  only (predates the current store title), not shown to players, and not
  referenced anywhere in the Yandex or Android submission pipeline.
- **No RU title exists anywhere in the repository.** Must be filled in
  manually before Yandex submission.

Full findings and the copy/paste RU/EN draft templates are in
`docs/yandex/yandex_draft_metadata.md`. No file was renamed and no title was
invented — the doc documents what's already established and marks what
still needs a human decision.

## Docs created

- `docs/yandex/yandex_draft_metadata.md` — canonical title findings above,
  plus RU/EN draft field templates (title, short description, full
  description, additional localized fields).
- `docs/yandex/yandex_submission_checklist.md` — full pre-submission
  checklist: draft/metadata, screenshots/media, products/monetization,
  build/technical smoke test.
- `docs/yandex/yandex_products_checklist.md` — per-product table (`gems_25`,
  `gems_150`, `gems_500`, `gems_1500` with their `yandex_product_id` and
  reference `price_rub`) plus an 8-item checklist repeated for each product,
  and a pointer to the `YandexBridge.get_catalog_product()` debug warning
  for diagnosing an id mismatch.
- `docs/yandex/yandex_media_requirements.md` — promo/media chrome rules (no
  baked rounded corners/frames), screenshot locale-matching rules, and a
  note distinguishing in-game UI chrome (fine) from external promo material
  chrome (not fine). Confirmed no promo/media assets currently exist in the
  repo (`promo*`, icon/cover exports) — this doc is preparation only.

## Code-side vs console-side vs media-side split

| Category | What | Status |
|---|---|---|
| Code-side | Yandex catalog price display, purchase/consume/recovery logic | Done in Y4, unchanged by Y5 |
| Docs-side (this patch) | Title findings, draft field templates, submission/product/media checklists | Done |
| Console-side (manual, outstanding) | Filling the Yandex draft title/description fields, setting category, creating/enabling/pricing products, enabling monetization | Not started — requires the Yandex developer console |
| Media-side (manual, outstanding) | Producing clean icon/cover/banner exports (no rounded corners/frames), capturing locale-matched screenshots | Not started — no promo assets exist in the repo yet |

## Remaining manual checklist

See `docs/yandex/yandex_submission_checklist.md` for the full list. Summary:

1. Open Yandex draft, fill canonical RU/EN title (RU still needs a human
   decision — no RU title exists in the repo).
2. Ensure title is identical across draft, descriptions, and promo
   materials.
3. Set category to `Казуальные` / Casual.
4. Fill RU fields in Russian, EN fields in English.
5. Check each field's length/format live in the Yandex draft form.
6. Create/attach screenshots matching each locale.
7. Replace any promo/media files that have rounded corners or baked frames
   (none currently exist in-repo, so this applies once media is produced).
8. Create products with ids matching `GemPurchaseConfig.gd`
   (`gems_25`, `gems_150`, `gems_500`, `gems_1500`).
9. Enable products and configure prices.
10. Enable purchases/monetization in Yandex/partner settings.
11. Run the Yandex preview smoke-test after a Web export (Y6).

## Confirmation: no gameplay/payment/save/ad logic changed

This patch only added/edited documentation and Markdown files:
- Added: `docs/yandex/yandex_draft_metadata.md`,
  `docs/yandex/yandex_submission_checklist.md`,
  `docs/yandex/yandex_products_checklist.md`,
  `docs/yandex/yandex_media_requirements.md`,
  `docs/validation/yandex_submission_metadata_media_compliance.md` (this
  file).
- Edited: `README.md`, `AGENTS.md`,
  `docs/validation/yandex_release_audit_platform_separation.md`,
  `docs/validation/yandex_payments_catalog_price_display.md`.

No `.gd` file was touched. `GemPurchaseConfig.gd` product ids/rewards/prices
are unchanged (only referenced/read for the products checklist table).
`YandexBridge.gd` purchase/consume/recovery logic, save logic, ad logic, and
Android/RuStore/AuthGate/AccountWindow/backend code are untouched.

## Validation commands run

```bash
godot --headless --editor --quit
godot --headless --script res://scripts/tools/ValidateLocalizationDataFreshness.gd
godot --headless --script res://scripts/tools/ValidateLocalizationExport.gd
git status
git diff --stat
```

No localization keys were changed by this patch (no new UI strings — the
new docs are plain Markdown, not in-game text), so
`GenerateLocalizationData.gd` was not run.
