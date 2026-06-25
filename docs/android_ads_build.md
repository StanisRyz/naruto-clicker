# Android Ads Build Guide

## Overview

Android ads (rewarded and interstitial) are handled by the **AndroidYandexAds**
Godot 4 Android plugin. The plugin bridges the Yandex Mobile Ads SDK to GDScript
via `AndroidRuStorePlatform.gd`.

---

## Plugin location

```
addons/android_yandex_ads/
  plugin.cfg                          ← Godot editor plugin registration
  AndroidYandexAdsExportPlugin.gd     ← Declares Maven dep + AAR path for export
  android/AndroidYandexAdsPlugin/     ← Android library Gradle project
    build.gradle
    settings.gradle
    src/main/
      AndroidManifest.xml             ← Registers singleton via meta-data
      kotlin/com/shinobi/yandexads/
        AndroidYandexAdsPlugin.kt     ← GodotPlugin subclass
```

## Singleton name

```gdscript
Engine.get_singleton("AndroidYandexAds")
```

Available from GDScript only on Android exports with the plugin enabled.
Check `Engine.has_singleton("AndroidYandexAds")` before use.

---

## SDK dependency

```
com.yandex.android:mobileads:8.1.0
```

Maven repository: `https://maven.yandex.ru/`

The dependency is **not** bundled into the plugin AAR. It is injected into the
main Gradle build automatically by `AndroidYandexAdsExportPlugin.gd`
(`_get_android_dependencies` + `_get_android_maven_repos`) during every Android
export that has the plugin enabled.

---

## Required SDK values

| Setting | Value |
|---|---|
| min SDK | 24 (set in `export_presets.cfg` and `android/build/config.gradle`) |
| compile SDK | 35 |
| target SDK | 35 |
| Android Gradle Plugin | 8.7.0 (minimum required by Yandex Mobile Ads SDK 8) |
| Kotlin | 2.1.20 |
| Java | 17 |
| Gradle | 8.11.1 |

---

## Build the plugin AAR

The plugin AAR must be built once before the first Android export. Rebuild after
any change to `AndroidYandexAdsPlugin.kt`.

```bash
# 1. Copy the godot-lib AAR into the plugin libs/ directory
cp android/build/libs/release/godot-lib.template_release.aar \
   addons/android_yandex_ads/android/AndroidYandexAdsPlugin/libs/

# 2. Build the plugin
cd addons/android_yandex_ads/android/AndroidYandexAdsPlugin
./gradlew assembleRelease   # for release export
./gradlew assembleDebug     # for debug export
```

### Expected AAR paths

```
addons/android_yandex_ads/android/AndroidYandexAdsPlugin/build/outputs/aar/
  AndroidYandexAdsPlugin-release.aar
  AndroidYandexAdsPlugin-debug.aar
```

`AndroidYandexAdsExportPlugin.gd` reads these paths via
`ProjectSettings.globalize_path()` and passes them to Godot's Gradle build
automatically. No manual file copying is needed.

---

## Enable the Godot plugin

The plugin is enabled in `project.godot`:

```ini
[editor_plugins]
enabled=PackedStringArray(
    "res://addons/localization_sync/plugin.cfg",
    "res://addons/android_yandex_ads/plugin.cfg"
)
```

To enable manually via the editor: **Project → Project Settings → Plugins →
AndroidYandexAds → Enable**.

---

## Export Android APK

```bash
godot --headless --export-release "Android" /path/to/output.apk
```

The Godot export system calls `AndroidYandexAdsExportPlugin.gd` which injects:
1. The plugin AAR as a local Gradle dependency.
2. `com.yandex.android:mobileads:8.1.0` as a remote Maven dependency.
3. `https://maven.yandex.ru/` as an additional Maven repository.

Godot's `android/build/build.gradle` picks these up via
`getGodotPluginsLocalBinaries()`, `getGodotPluginsRemoteBinaries()`, and
`getGodotPluginsMavenRepos()`.

---

## Ad unit ids

Ad unit ids are configured in:

```
scripts/game/config/AdPlacementConfig.gd
```

Each logical placement has an `android_ad_unit_id` field. Real Yandex Mobile
Ads unit ids are configured in `AdPlacementConfig.gd`.

| Placement id | Type | Ad unit id |
|---|---|---|
| `rewarded_shop_gems` | rewarded | `R-M-19501283-1` |
| `rewarded_bonus_banner` | rewarded | `R-M-19501283-2` |
| `rewarded_offline_gold_x3` | rewarded | `R-M-19501283-3` |
| `fullscreen_auto_interstitial` | fullscreen | `R-M-19501283-4` |

---

## Logcat tags

```
adb logcat -s AndroidYandexAds MobileAds
```

| Tag | Meaning |
|---|---|
| `AndroidYandexAds` | Plugin lifecycle, ad load/show/dismiss, reward earned |
| `MobileAds` | Yandex SDK internal events |

Key log lines to look for:

```
D AndroidYandexAds: Yandex Mobile Ads SDK initialized successfully
D AndroidYandexAds: Loading rewarded ad: <unit_id>
D AndroidYandexAds: Rewarded ad loaded, showing
D AndroidYandexAds: Rewarded ad shown
D AndroidYandexAds: Rewarded ad reward earned: coins x1
D AndroidYandexAds: Rewarded ad dismissed, reward granted: true
D AndroidYandexAds: Loading interstitial ad: <unit_id>
D AndroidYandexAds: Interstitial ad dismissed
E AndroidYandexAds: Rewarded ad failed to load: <description> (code N)
```

---

## Reward grant contract

Rewarded rewards are **never** granted inside the Kotlin plugin. The plugin only
emits the `rewarded_ad_rewarded` signal. The reward is applied exclusively in:

```gdscript
# scenes/game/ClickerScreen.gd
func _on_rewarded_ad_rewarded() -> void:
    # grants gems / gold / damage buff depending on _rewarded_ad_request_context
```

---

## Failure modes

| Condition | Result |
|---|---|
| Plugin not loaded (`AndroidYandexAds` singleton absent) | `rewarded_ad_error` / `fullscreen_ad_error` emitted; no crash |
| Placement id unknown | error emitted; ad-in-progress flag never set |
| Ad unit id empty in `AdPlacementConfig` | error emitted; ad-in-progress flag never set |
| Kotlin ad load failure | `rewarded_ad_error` / `fullscreen_ad_error` emitted; flag cleared |
| Kotlin ad show failure | same as load failure; flag cleared via error callback |
| Network unavailable | Yandex SDK calls load listener `onAdFailedToLoad`; plugin emits error |
