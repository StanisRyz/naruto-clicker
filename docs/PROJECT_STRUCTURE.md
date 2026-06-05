# Project Structure

Reference guide for the Naruto Clicker project layout. Intended for future refactors and onboarding.

## Directory Map

```
naruto-clicker/
├── autoload/               # Godot autoloads (always-available singletons)
│   ├── SaveManager.gd      # Local save: atomic JSON write, version check, migration hook
│   └── YandexBridge.gd     # Yandex Games SDK placeholder; no-ops outside Web export
│
├── scripts/
│   ├── game/
│   │   ├── ClickerState.gd         # Runtime state, economy formulas, and gameplay API
│   │   ├── BalanceConfig.gd        # Central economy coefficients; ClickerState and config files read from here
│   │   ├── ProgressionSimulator.gd # Debug-only: estimates progression curves without saving
│   │   ├── config/                 # Static game definitions (no runtime state, no SaveManager)
│   │   │   ├── ZoneConfig.gd       # ZONE_DATA: zone names, level ranges, enemy lists, multipliers
│   │   │   ├── PartnerConfig.gd    # Partner names; DPS/costs delegate to BalanceConfig
│   │   │   ├── PartnerSkillConfig.gd # All 65 partner skill definitions (13 partners × 5 skills)
│   │   │   ├── HeroSkillConfig.gd  # 5 hero passive skill definitions
│   │   │   ├── AbilityConfig.gd    # 20 ability rank skill definitions + unlock/cost helpers
│   │   │   ├── SettlementConfig.gd # Building names and bonus types; costs delegate to BalanceConfig
│   │   │   ├── PrestigeConfig.gd   # Prestige talent names and bonus types
│   │   │   ├── TaskConfig.gd       # 10 task definitions (id, goal type, target delta, reward scale)
│   │   │   └── ShopConfig.gd       # 5 shop product definitions
│   │   ├── save/                   # Save serialization layer (no gameplay logic, no file IO)
│   │   │   └── ClickerStateSaveAdapter.gd # Builds and applies Save System v1 dictionaries
│   │   ├── calculators/            # Pure formula functions (no state, no side effects)
│   │   │   ├── MilestoneCalculator.gd     # Milestone multiplier and cost-spike logic
│   │   │   ├── CostCalculator.gd          # Hero/partner/building cost formulas
│   │   │   └── EnemyScalingCalculator.gd  # Base HP/reward formulas + zone/boss/elite scaling
│   │   ├── presentation/           # UI-facing formatting and view-data builders (read-only)
│   │   │   └── ClickerStatePresentation.gd # Descriptions, skill states, task/shop view data
│   │   └── runtime/                # Runtime services: task and shop logic
│   │       ├── TaskRuntime.gd      # Task init, progress, claim, rotation; no UI/SaveManager calls
│   │       └── ShopRuntime.gd      # Local shop purchases, Gems helpers; no real payments/UI calls
│   └── ui/
│       ├── GameAssetCatalog.gd       # Central registry: all UI image keys → file paths
│       ├── ImageSlot.gd              # Drop-in ColorRect with texture + fallback color
│       ├── EnemyAssetCatalog.gd      # Per-enemy/per-state image path helpers
│       ├── BackgroundAssetCatalog.gd # Per-zone background image path helpers
│       ├── LocalizationManager.gd    # Autoload: loads game_text.csv, provides tr_key/format_key, language_changed signal
│       └── NumberFormatter.gd        # Number formatting utilities
│
├── scenes/
│   ├── main/
│   │   ├── Main.tscn   # App/root scene
│   │   └── Main.gd     # Root startup: YandexBridge ready/gameplay calls
│   ├── game/
│   │   ├── ClickerScreen.tscn  # Main gameplay screen and layout
│   │   └── ClickerScreen.gd    # Owns gameplay flow and all UI update calls
│   └── ui/             # All UI panels, sheets, and popups (see below)
│
├── assets/
│   └── images/
│       ├── ui/           # Core UI icons (gold, gems, hero level, etc.)
│       ├── game/         # Game-field images (field background, enemy defaults)
│       ├── abilities/    # Ability button icons
│       ├── upgrades/     # Upgrade card icons
│       ├── partners/
│       │   ├── partner_01/ … partner_28/  # Per-partner icon: partner.png
│       │   └── Skills/   # Shared skill icons: skill1.png – skill5.png
│       ├── buildings/    # Settlement building icons
│       ├── prestige/     # Prestige action + talent icons
│       ├── shop/         # Shop product icons
│       ├── tasks/        # Task type icons
│       ├── enemies/
│       │   ├── zone_01/  # Non-boss pool for gameplay zones 1–10 (enemy_01–15, elite_01–04, boss_01)
│       │   ├── zone_11/  # Non-boss pool for gameplay zones 11–20 (enemy_01–15, elite_01–05, boss_01)
│       │   ├── zone_21/  # Non-boss pool for zone 21 (enemy_01–03, elite_01, boss_01)
│       │   └── zone_02/ … zone_20/  # boss_01/ only (non-boss enemy/elite slots are obsolete)
│       └── backgrounds/
│           ├── zone_01/  # background.png for Training Grounds
│           ├── zone_02/  # Forest Path
│           ├── zone_03/  # Stone Valley
│           └── zone_04/  # Shadow Camp
│
├── docs/
│   ├── PROJECT_STRUCTURE.md  # This file
│   └── BALANCE.md            # Balance tuning guide and simulator instructions
│
├── localization/
│   └── game_text.csv       # Single editable source of all player-facing strings (key / en / ru / context / notes)
│
├── export_presets.cfg   # Web (Yandex) and Android export configurations
├── project.godot        # Engine settings, autoloads, display, renderer
├── README.md            # Gameplay documentation and system reference
└── AGENTS.md            # Development rules for AI coding agents
```

## scenes/ui/ — UI component inventory

| File | Purpose |
|------|---------|
| `PrimaryStatsPanel.tscn/.gd` | Compact top-centered stat overlay (gold, gems, level, damage, DPS, settings) |
| `ProgressInfoPanel.tscn/.gd` | Level, zone, enemy name, HP bar |
| `ComboPanel.tscn/.gd` | Right-side vertical combo/chakra meter |
| `GameField.tscn/.gd` | Fullscreen tap/click layer; enemy and background visuals |
| `AbilityBar.tscn/.gd` | Left-side active ability buttons |
| `StageNavigator.tscn/.gd` | Horizontal 7-button stage strip with scroll/drag |
| `AutoTransitionPopup.tscn/.gd` | Info-only popup showing auto-transition ON/OFF status |
| `SettingsWindow.tscn/.gd` | Modal: sound/music toggles, Save Now, Reset Progress |
| `TasksWindow.tscn/.gd` | Modal: 5 active tasks, claim rewards, rotation |
| `BuyModeSelector.tscn/.gd` | Reusable x1/x10/x100/Max purchase mode selector |
| `UpgradePanel.tscn/.gd` | Hero level + ability upgrade cards with skill icon rows |
| `UpgradeSheet.tscn/.gd` | Bottom-half sheet hosting UpgradePanel |
| `UpgradeSkillPopup.tscn/.gd` | Compact popup for hero/ability skill purchases |
| `PartnerPanel.tscn/.gd` | Partner hire cards with skill icon rows |
| `PartnerSheet.tscn/.gd` | Bottom-half sheet hosting PartnerPanel |
| `PartnerSkillPopup.tscn/.gd` | Compact popup for partner skill purchases |
| `SettlementPanel.tscn/.gd` | Settlement building cards |
| `SettlementSheet.tscn/.gd` | Bottom-half sheet hosting SettlementPanel |
| `PrestigePanel.tscn/.gd` | Prestige action card + talent rows |
| `PrestigeSheet.tscn/.gd` | Bottom-half sheet hosting PrestigePanel |
| `PrestigeConfirmDialog.tscn/.gd` | Fully opaque prestige confirmation overlay |
| `ShopPanel.tscn/.gd` | Shop product cards + dev gems button |
| `ShopSheet.tscn/.gd` | Bottom-half sheet hosting ShopPanel |

## Localization

All player-facing strings are stored in `res://localization/game_text.csv` (key / en / ru / context / notes).

The `LocalizationManager` autoload (added to `project.godot`) loads this file at startup and exposes:
- `tr_key(key)` — returns translation for current language, falls back to English if Russian is empty
- `format_key(key, values)` — same but replaces `{placeholder}` tokens
- `set_language(code)` / `get_language()` — runtime language switch; emits `language_changed`

Selected language is saved in `state.language` alongside `sound_enabled` / `music_enabled`.
Language switch in **Settings → Language** button; UI refreshes immediately.

See `docs/LOCALIZATION.md` for the full guide, fallback rules, and known gaps.

## Key architectural rules

- **ClickerState** owns runtime player state, economy formulas, and the gameplay API. It has no UI references.
- **Config files** (`scripts/game/config/`) hold static definitions only — no runtime player state, no SaveManager calls, no scene references.
- **BalanceConfig** owns numeric economy coefficients. Config files delegate to it for numeric arrays (DPS, costs, multipliers).
- **ClickerScreen** owns all gameplay flow: processes timers, calls state methods, and pushes results to UI components.
- **UI components** are read-only from the state's perspective; they emit signals upward to ClickerScreen.
- **UI components** that need only static config data (partner names, building names, talent names) read directly from config classes — they do not need to go through ClickerState.
- **Asset catalogs** (GameAssetCatalog, EnemyAssetCatalog, BackgroundAssetCatalog) are stateless helpers — they build paths and load textures but hold no runtime state.
- **ImageSlot** is a drop-in ColorRect replacement. Missing image files never crash — it falls back to the placeholder color.
- **SaveManager** writes atomically: temp file then rename. It validates `save_version` and exposes `migrate_save_data()` for future format upgrades.
- **ClickerStateSaveAdapter** (`scripts/game/save/`) handles serialization only — it builds and applies Save System v1 dictionaries. ClickerState keeps the public `get_save_data`/`apply_save_data` API; callers do not need to know about the adapter.
- **Calculators** (`scripts/game/calculators/`) contain pure formula functions — no runtime state, no side effects, no SaveManager calls. ClickerState delegates internal cost/milestone/enemy-scaling math to them.
- **Presentation** (`scripts/game/presentation/`) contains UI-facing formatting, description strings, skill state labels, and view-data dictionary builders. Read-only access to ClickerState; must not mutate state or perform gameplay actions. UI panels continue calling ClickerState public methods, which delegate internally.
- **TaskRuntime** (`scripts/game/runtime/`) owns task runtime operations: initialization, progress tracking, reward calculation, claim/rotation, and validation. Reads and mutates ClickerState task fields through a passed state reference. Must not call SaveManager, UI, or scene nodes. ClickerState owns the task state fields (active_task_ids, inactive_task_ids, active_task_states) for save compatibility. TasksWindow continues calling ClickerState public methods.
- **ShopRuntime** (`scripts/game/runtime/`) owns local shop runtime behavior: Gems helpers, product lookup, and purchase logic. Prototype-only; does not implement real payments. Must not call SaveManager or UI nodes. ClickerState owns shop state fields (gems, boss_retry_tokens, task_reward_boost_multiplier) for save compatibility. ShopPanel continues calling ClickerState public methods.

## Config file rules

- Config files must not store runtime player state.
- Config files must not call SaveManager.
- Config files must not hold scene or node references.
- Save field names, task ids, skill ids, product ids, and ability ids must not change.
- To add a new task, skill, or shop product: edit the matching config file only.
- Numeric balance values (DPS, costs, multipliers) live in BalanceConfig, not in config files.
