# Naruto Clicker

Naruto Clicker is a vertical idle/clicker game prototype for Yandex Games.

## Status

Early setup/prototype. The project currently has a basic playable clicker loop and a YandexBridge autoload as a future integration point.

Save systems, heroes, settlement features, and monetization are intentionally not implemented yet.

## Project Details

- Engine: Godot 4.5.1
- Language: GDScript
- Target platform: Web / Yandex Games
- Orientation: vertical / portrait
- Viewport: 720x1280
- Renderer: GL Compatibility

## Local Development

Open the project in Godot 4.5.1 and run the main scene from the editor. Keep changes small and verify the scene still opens and runs after each patch.

Do not add external plugins or external assets without explicit approval.

## Current Gameplay Prototype

The main scene contains the first local clicker loop:

- Press `Attack` to damage the current target.
- Target HP is shown with a label and progress bar.
- Defeating a target awards gold and creates a stronger next target.
- Gold can buy a single damage upgrade that increases click damage.

This state is temporary and kept in `scenes/main/Main.gd` while the prototype is small.

## Project Structure

- `project.godot` - Godot project settings, main scene, display, renderer, and autoload configuration.
- `autoload/YandexBridge.gd` - Yandex Games integration placeholder/autoload.
- `scenes/main/Main.tscn` - Main vertical UI scene.
- `scenes/main/Main.gd` - Main scene startup script.

## Web Export Notes

The project is intended for Yandex Games Web export. Keep the 720x1280 portrait setup, GL Compatibility renderer, and Web-friendly Control-based UI layout.

YandexBridge is present for future platform integration, but ads, payments, saves, cloud features, and authentication should not be added until explicitly requested.
