# Yandex Draft Metadata Template

Copy/paste-friendly templates for filling in the Yandex Games developer
console draft fields. This doc does not submit anything — it only prepares
the text so the console form can be filled out consistently in one pass.

## Canonical game title

```
RU title: <fill manually>
EN title: Shinobi Clicker: Idle
```

**Rule: the title must be identical everywhere it appears** — the Yandex
draft title field, the short/full description text (if the title is
mentioned there), and any screenshots/promo images that show the title as
text. Do not use a different title in the description than in the title
field.

### Where "the title" currently comes from (repo search)

The game has **no in-game visible title screen or title UI label** — there
is no `LocalizationManager` key for a game title, no splash screen text, and
no title shown inside `ClickerScreen` or any menu. The title only exists as
platform/store metadata:

| Source | Value | File |
|---|---|---|
| Godot project name (window title) | `Shinobi Clicker: Idle` | `project.godot` → `config/name` |
| Android package display name | `Shinobi Clicker: Idle` | `export_presets.cfg` → `[preset.1.options]` → `package/name` |
| Android RuStore readiness doc | `Shinobi Clicker: Idle` | `docs/rustore_readiness_checklist.md` |
| Android release validation doc | `Shinobi Clicker: Idle` | `docs/android_release_validation.md` |
| Repo/README heading (dev-facing only) | `Naruto Clicker / Anime Ninja Idle Clicker` | `README.md` line 1 |
| Internal structure doc (dev-facing only) | "Naruto Clicker project" | `docs/PROJECT_STRUCTURE.md` |

**Conclusion:** `Shinobi Clicker: Idle` is the established EN store/app name
— it is what's already configured for the Android/RuStore submission and is
what a player would see as the app/window title. The README/`PROJECT_STRUCTURE.md`
references to "Naruto Clicker" are internal repo naming only (this
repository predates the current store title) and are **not** shown to
players or referenced anywhere in the Yandex-facing pipeline. Use
`Shinobi Clicker: Idle` as the EN Yandex draft title unless a different
title is deliberately chosen for the Yandex listing specifically.

**No RU title exists anywhere in the repo.** This must be filled in
manually before submission — do not invent one here. Whatever RU title is
chosen must then be used consistently in the RU description and any RU
screenshots/promo text below.

## RU draft field template

```
Title:
<fill manually — see canonical title section above>

Short description:
<fill manually>

Full description:
<fill manually>

Additional localized fields (if the Yandex form has more, e.g. keywords/tags):
<fill manually as needed>
```

## EN draft field template

```
Title:
Shinobi Clicker: Idle

Short description:
<fill manually>

Full description:
<fill manually>

Additional localized fields (if the Yandex form has more, e.g. keywords/tags):
<fill manually as needed>
```

## Reminder

Field length and formatting limits (character counts, allowed formatting,
banned content) are **not duplicated here** because they can change and are
authoritative only in the Yandex draft form itself. Check the actual limit
shown next to each field in the console when filling it in — do not rely on
a remembered number.

Do not invent final marketing copy in this file. This is a template with
placeholders, not approved store copy.
