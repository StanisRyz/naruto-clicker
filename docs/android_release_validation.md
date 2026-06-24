# Android Release Validation Checklist

Pre-upload checklist. Work through every item before submitting the APK to RuStore.

---

## 1. Build the Android Ads plugin AAR

Must be done before every Android export.

```bash
cp android/build/libs/release/godot-lib.template_release.aar \
   addons/android_yandex_ads/android/AndroidYandexAdsPlugin/libs/

cd addons/android_yandex_ads/android/AndroidYandexAdsPlugin
./gradlew assembleRelease
```

Expected output:

```
addons/android_yandex_ads/android/AndroidYandexAdsPlugin/build/outputs/aar/AndroidYandexAdsPlugin-release.aar
```

See `docs/android_ads_build.md` for full details.

---

## 2. Export the release APK

```bash
godot --headless --export-release "Android" <ANDROID_RELEASE_OUTPUT_APK>
```

Replace `<ANDROID_RELEASE_OUTPUT_APK>` with the output path configured locally
(see `docs/local_release_env.example.md`). The Godot export preset uses
`export_path` from `export_presets.cfg` as the default.

---

## 3. Verify the APK file exists

```bash
ls -lh <ANDROID_RELEASE_OUTPUT_APK>
```

The file must be present and non-zero size. A failed export may produce a
zero-byte file or no file at all.

---

## 4. Verify package name

```bash
aapt dump badging <ANDROID_RELEASE_OUTPUT_APK> | grep "^package:"
```

Expected:

```
package: name='com.stanis.shinobiclickeridle' ...
```

The package name must match what is registered in the RuStore developer console.
It must never change after the first upload.

---

## 5. Verify versionCode

```bash
aapt dump badging <ANDROID_RELEASE_OUTPUT_APK> | grep versionCode
```

Expected: a value strictly greater than the previously uploaded versionCode.
For the first upload: `versionCode='1'`.

---

## 6. Verify versionName

```bash
aapt dump badging <ANDROID_RELEASE_OUTPUT_APK> | grep versionName
```

Expected: `versionName='1.0.0'` (or the current release version).

---

## 7. Verify APK signature

```bash
apksigner verify --verbose <ANDROID_RELEASE_OUTPUT_APK>
```

Expected output must include:

```
Verified using v2 scheme (APK Signature Scheme v2): true
```

If the APK is unsigned or signed with a debug key, RuStore will reject it.

---

## 8. Install APK on device

```bash
adb install -r <ANDROID_RELEASE_OUTPUT_APK>
```

`-r` reinstalls over an existing installation. Remove `-r` for a clean install.

If multiple devices are connected, specify the target:

```bash
adb -s <DEVICE_SERIAL> install -r <ANDROID_RELEASE_OUTPUT_APK>
```

---

## 9. Launch the app

```bash
adb shell am start -n com.stanis.shinobiclickeridle/com.godot.game.GodotApp
```

Or tap the app icon on the device.

Confirm:
- App launches without crash.
- Loading screen appears.
- Main game screen loads.

---

## 10. Check app name and icon

On the device home screen / app drawer:

- App name displays as **Shinobi Clicker: Idle**.
- App icon displays correctly (not a default Godot icon).

The icon is configured in `export_presets.cfg`:

```
launcher_icons/main_192x192="res://assets/images/app/app_icon.png"
```

---

## 11. Smoke-test save and load

1. Play for a few seconds (earn some gold, click the enemy).
2. Force-close the app:
   ```bash
   adb shell am force-stop com.stanis.shinobiclickeridle
   ```
3. Relaunch the app.
4. Confirm gold and progress are restored from the saved state.

---

## 12. Smoke-test rewarded / interstitial ad safe failure

If `android_ad_unit_id` fields in `AdPlacementConfig.gd` are empty (no real ad unit ids
registered yet):

1. Tap the rewarded ad button in the shop (+3 gems via ad).
2. Confirm no crash occurs.
3. Confirm a clean error is shown or the button simply does nothing.
4. Confirm the game does not remain in a paused/stuck state.

Check Logcat:

```bash
adb logcat -s AndroidYandexAds
```

Expected: an error log line from the plugin, no signal stuck open.

---

## 13. Smoke-test purchase safe failure (RuStore Pay SDK missing)

Tap any gem purchase button in the Shop:

1. Confirm no crash occurs.
2. Confirm no gems are granted.
3. Confirm the game does not remain in a paused/stuck state.
4. Confirm the purchase button becomes active again after failure.

RuStore Pay SDK stubs emit `purchase_error` cleanly when the real SDK AAR is not
bundled. This is the expected behavior until the SDK is integrated.

---

## Logcat monitoring

```bash
adb logcat -s AndroidYandexAds AndroidRuStorePay GodotApp
```

Watch for unhandled exceptions or unexpected signal states during smoke tests.

---

## Post-checklist

After all checks pass:

1. Upload the signed release APK to the RuStore developer console.
2. Increment `version/code` in `export_presets.cfg` before the next release.
3. Update `version/name` to match the new release.

See also:
- [docs/android_release_signing.md](android_release_signing.md)
- [docs/rustore_readiness_checklist.md](rustore_readiness_checklist.md)
