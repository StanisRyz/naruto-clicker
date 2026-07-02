# Yandex Submission Checklist

Practical pre-submission / resubmission checklist. Most items here are
console or media work, not code — see `docs/yandex/yandex_draft_metadata.md`
for the field templates and `docs/yandex/yandex_media_requirements.md` for
media rules.

## Draft / metadata

- [ ] Game title is identical across: Yandex draft title field, short
      description, full description, and any promo material that displays
      the title as text. See `docs/yandex/yandex_draft_metadata.md`.
- [ ] Category/genre is set to `Казуальные` (Casual) — unless intentionally
      changed, this must match what prior moderation expected.
- [ ] RU fields are genuinely Russian (not machine-placeholder text, not
      copy-pasted EN).
- [ ] EN fields are genuinely English.
- [ ] No untranslated placeholder text (e.g. `<fill manually>`, `TODO`,
      `Lorem ipsum`) remains in any field submitted to Yandex.
- [ ] Short description follows the Yandex draft field's own length/format
      rules (checked live in the console — see reminder in
      `yandex_draft_metadata.md`).
- [ ] Full description follows the Yandex draft field's own length/format
      rules (checked live in the console).

## Screenshots / media

- [ ] Screenshots attached to the RU locale show RU in-game UI text.
- [ ] Screenshots attached to the EN locale show EN in-game UI text.
- [ ] Promo materials (icon, cover, banner) have no baked rounded corners.
- [ ] Promo materials have no baked frames/borders.
- [ ] See `docs/yandex/yandex_media_requirements.md` for the full media
      rule set before exporting new promo assets.

## Products / monetization

- [ ] All 4 gem products exist in the Yandex draft with ids matching
      `GemPurchaseConfig.gd` exactly. See
      `docs/yandex/yandex_products_checklist.md` for the per-product
      checklist.
- [ ] Products are enabled/published in the draft, not left disabled.
- [ ] Purchases are enabled in Partner/monetization settings for this game.

## Build / technical smoke test

- [ ] Web archive built from the current code
      (`godot --headless --export-release "Web" …`), release mode, not
      debug.
- [ ] `index.html` is at the archive root.
- [ ] Archive tested via the Yandex preview/debug panel (not `file://`).
- [ ] SDK readiness confirmed (`window.ysdk` / `window.ysdkReady`).
- [ ] Language auto-apply tested — confirm the game starts in the language
      reported by `ysdk.environment.i18n.lang` (already implemented, see
      Y1/Y2 audit).
- [ ] Yandex Player save tested — save/load round-trips through
      `player.getData`/`setData` (already implemented, see Y1/Y3 audit).
- [ ] Rewarded and fullscreen ads tested end-to-end.
- [ ] Purchases tested — catalog price display, successful purchase,
      cancel/error paths, and unprocessed-purchase recovery (see Y4 doc:
      `docs/validation/yandex_payments_catalog_price_display.md`).

## What this checklist does not cover

This checklist does not fill in the draft, upload media, or configure
products — those are manual actions in the Yandex Games developer console.
Nothing in this repository can complete them automatically.
