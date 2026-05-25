# AGENTS.md

Development rules for AI coding agents working on this repository.

## Project Context

Naruto Clicker is an early setup/prototype for a vertical idle/clicker game targeting Web / Yandex Games. The project should stay small, stable, and easy to validate.

## Tech Stack

- Use Godot 4.5.1.
- Use GDScript only.
- Do not add C#.
- Keep the project compatible with Web export.
- Keep renderer compatibility with Web export, currently GL Compatibility.

## Current Priorities

- Keep the main scene stable and Control-based.
- Preserve the 720x1280 portrait layout.
- Keep YandexBridge as a future integration point.
- Keep the current temporary gameplay state in `scenes/main/Main.gd`.
- Prefer small, safe, isolated patches.
- Preserve existing project settings unless the task requires a specific change.

## Coding Rules

- Use GDScript only.
- Keep scripts simple and focused.
- Avoid large architectural rewrites.
- Do not add external plugins.
- Do not add external assets unless explicitly requested.
- Do not introduce gameplay systems beyond the requested task.
- Do not extract gameplay state into services until the prototype loop becomes larger or explicitly requested.
- Keep patches easy to review.

## Scene/UI Rules

- Use Control-based UI for the main scene and other screen layouts.
- Keep the game vertical and Web-export friendly.
- Prefer containers and anchors over Node2D positioning for UI.
- Preserve the main scene UID unless unavoidable.
- Keep placeholder UI simple until specific gameplay/UI work is requested.

## Yandex Games / Web Export Rules

- Keep YandexBridge registered as an Autoload unless a task explicitly changes that integration.
- Preserve existing YandexBridge public methods:
  - `game_ready()`
  - `gameplay_start()`
  - `gameplay_stop()`
- Do not add ads, payments, saves, cloud features, or authentication until explicitly requested.
- Make sure editor and desktop preview runs do not crash when Web-only APIs are unavailable.

## What Not To Add Yet

- Save system
- Monetization
- Ads
- Payments
- Cloud saves
- Player authentication
- Complex gameplay systems
- External assets
- External plugins
- Copyrighted images, audio, fonts, or other third-party assets

## Validation Checklist

After each patch, validate manually in Godot:

- Project opens without scene/script inheritance errors.
- `scenes/main/Main.tscn` opens in the editor.
- Main root node is `Control`.
- `scenes/main/Main.gd` is attached to the Main root node.
- Clicker UI is visible.
- Attack button reduces target HP.
- Target defeat gives gold.
- Damage upgrade spends gold and increases damage.
- Upgrade cannot be bought without enough gold.
- Scene can be run from Godot.
- No error appears because `Main.gd` extends `Control`.
- YandexBridge calls do not crash in non-Web/editor runs.
- `project.godot` still points to the main scene.
- Project remains configured for 720x1280 portrait layout.
- Renderer remains GL Compatibility.
- No missing scene/script errors.
- No external plugins/assets were added.

## Documentation Update Rules

Update this file when adding important systems, scenes, architecture decisions, workflow rules, or validation requirements. Keep README.md aligned with major project setup or workflow changes.
