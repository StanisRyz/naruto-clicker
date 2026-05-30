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
│   │   └── config/                 # Static game definitions (no runtime state, no SaveManager)
│   │       ├── ZoneConfig.gd       # ZONE_DATA: zone names, level ranges, enemy lists, multipliers
│   │       ├── PartnerConfig.gd    # Partner names; DPS/costs delegate to BalanceConfig
│   │       ├── PartnerSkillConfig.gd # All 65 partner skill definitions (13 partners × 5 skills)
│   │       ├── HeroSkillConfig.gd  # 5 hero passive skill definitions
│   │       ├── AbilityConfig.gd    # 20 ability rank skill definitions + unlock/cost helpers
│   │       ├── SettlementConfig.gd # Building names and bonus types; costs delegate to BalanceConfig
│   │       ├── PrestigeConfig.gd   # Prestige talent names and bonus types
│   │       ├── TaskConfig.gd       # 10 task definitions (id, goal type, target delta, reward scale)
│   │       └── ShopConfig.gd       # 5 shop product definitions
│   └── ui/
│       ├── GameAssetCatalog.gd       # Central registry: all UI image keys → file paths
│       ├── ImageSlot.gd              # Drop-in ColorRect with texture + fallback color
│       ├── EnemyAssetCatalog.gd      # Per-enemy/per-state image path helpers
│       └── BackgroundAssetCatalog.gd # Per-zone background image path helpers
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
│       │   └── skills/   # Partner skill icons
│       ├── buildings/    # Settlement building icons
│       ├── prestige/     # Prestige action + talent icons
│       ├── shop/         # Shop product icons
│       ├── tasks/        # Task type icons
│       ├── enemies/
│       │   ├── zone_01/  # Zone 1 (levels 1–10)
│       │   │   ├── enemy_01/ … enemy_03/   # Normal enemies (healthy/hit/wounded/defeated)
│       │   │   ├── elite_01/               # Elite enemy
│       │   │   └── boss_01/                # Boss
│       │   ├── zone_02/ … zone_04/         # Same structure for each zone
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

## Config file rules

- Config files must not store runtime player state.
- Config files must not call SaveManager.
- Config files must not hold scene or node references.
- Save field names, task ids, skill ids, product ids, and ability ids must not change.
- To add a new task, skill, or shop product: edit the matching config file only.
- Numeric balance values (DPS, costs, multipliers) live in BalanceConfig, not in config files.
