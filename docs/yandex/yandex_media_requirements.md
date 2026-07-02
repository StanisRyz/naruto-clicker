# Yandex Media Requirements

Rules for promo/media assets submitted to the Yandex Games developer
console. Prior moderation flagged media with rounded corners and baked
frames — this doc exists so future media exports don't repeat that mistake.

No promo/media assets currently exist in this repository (no `promo*`
files, no icon/cover exports found under `assets/`). This doc is
preparation only — it does not create or generate any image.

## Rules

- **Promo images must not have baked rounded corners.** Yandex applies its
  own corner rounding in the storefront UI; a promo image that already has
  rounded corners baked into the pixels will show double-rounding or
  visible artifacts and has previously caused a moderation rejection.
- **Promo images must not have baked frames or borders.** Same reasoning —
  Yandex adds its own chrome around the image.
- **Screenshots must not show UI language that mismatches the locale they're
  attached to.** A screenshot attached to the RU listing must show RU
  in-game UI text; a screenshot attached to the EN listing must show EN
  in-game UI text. Use the in-game language switch
  (`settings.language` / `LocalizationManager.set_language()`) to capture
  matching screenshots before exporting.
- **Any text baked into a screenshot or promo image must be localized to
  match the target locale.** Don't reuse an EN-captioned screenshot for the
  RU listing (or vice versa).
- **Existing in-game UI assets may legitimately have frames/borders as part
  of the game's own art style** (buttons, panels, dialog backgrounds) —
  that is normal UI chrome and is not what this rule is about. This rule
  applies specifically to **external Yandex promo/media materials**: the
  store icon, cover image, banner, and screenshots submitted to the
  console, which must not have platform-disallowed chrome baked in on top
  of (or instead of) Yandex's own storefront framing.
- **If an existing promo/media export is found to have rounded corners or a
  black border baked in, prepare a separate, clean export specifically for
  Yandex** rather than reusing an asset built for a different store (e.g. an
  Android/RuStore icon that already has platform-specific corner rounding
  applied) — different stores round/frame assets differently, and an asset
  correct for one store is not necessarily correct for another.

## Not covered here

This doc does not generate, edit, or commit any image asset. Producing the
actual clean media exports (icon, cover, banner, localized screenshots) is
manual creative/design work outside this repository's code.
