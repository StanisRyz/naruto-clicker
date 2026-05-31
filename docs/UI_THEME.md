# UI Theme

## Global theme

Path: `res://themes/main_theme.tres`

Applied to the root `ClickerScreen` Control node. All descendant Labels, Buttons, and other themed controls inherit from it automatically.

## Font

Expected font file: `res://assets/fonts/main_font.ttf` (or `.otf`)

The font is not committed to the repository. To activate it:

1. Place a TTF or OTF file in `res://assets/fonts/`.
2. Open `res://themes/main_theme.tres` in the Godot editor.
3. Assign the font to the `default_font` slot and to `Label/fonts/font` and `Button/fonts/font`.

**Licensing:** use only fonts licensed for commercial use if releasing the game (e.g. SIL Open Font License fonts).

## Text outline

Outline is applied globally through the theme:

| Property | Value |
|---|---|
| `Label/colors/font_outline_color` | `Color(0, 0, 0, 1)` — black |
| `Label/constants/outline_size` | `2` |
| `Button/colors/font_outline_color` | `Color(0, 0, 0, 1)` — black |
| `Button/constants/outline_size` | `2` |

To increase outline thickness on specific labels (e.g. boss timer), add a local `theme_override_constants/outline_size` override on that node.

## Font size

Default sizes set in the theme:

| Control | Size |
|---|---|
| Label | 20 |
| Button | 20 |

Individual nodes can override with `theme_override_font_sizes/font_size`.

## Font color

Default: `Color(1, 1, 1, 1)` — white, readable against dark game backgrounds and with the black outline on lighter areas.
