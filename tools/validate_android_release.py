"""
Read-only pre-upload Android release validator for Shinobi Clicker: Idle.

Usage:
    python tools/validate_android_release.py --apk <APK_PATH>

Exit codes:
    0  all checks passed
    1  one or more checks failed
"""

import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# Expected release identity — must match export_presets.cfg and RuStore listing
# ---------------------------------------------------------------------------
EXPECTED_PACKAGE = "com.stanis.shinobiclickeridle"
EXPECTED_VERSION_CODE = "1"
EXPECTED_VERSION_NAME = "1.0.0"

YANDEX_AAR_PATH = Path(
    "addons/android_yandex_ads/android/AndroidYandexAdsPlugin"
    "/build/outputs/aar/AndroidYandexAdsPlugin-release.aar"
)

EXPORT_PRESETS_PATH = Path("export_presets.cfg")

REQUIRED_PRESET_STRINGS = [
    'version/code=1',
    'version/name="1.0.0"',
    f'package/unique_name="{EXPECTED_PACKAGE}"',
    'package/name="Shinobi Clicker: Idle"',
    'gradle_build/use_gradle_build=true',
    'gradle_build/min_sdk="24"',
    'gradle_build/target_sdk="35"',
]

REQUIRED_GITIGNORE_PATTERNS = [
    "*.jks",
    "*.keystore",
    "*.p12",
    "*.apk",
    "*.aab",
    "local_release_env.sh",
    "local_release_env.ps1",
    "local_release_env.txt",
    "/builds/",
    "/godot_apk/",
    # Android build secrets — template source is tracked, secrets/generated dirs are not
    "android/build/local.properties",
    "android/local.properties",
]

ANDROID_TEMPLATE_FILES = [
    Path("android/build/AndroidManifest.xml"),
    Path("android/build/res/values/rustore_values.xml"),
    Path("android/build/src/com/godot/game/RuStoreIntentFilterActivity.java"),
]

RUSTORE_MANIFEST_TAGS = [
    "console_app_id_value",
    "internal_config_key",
    "sdk_pay_scheme_value",
    "RuStoreIntentFilterActivity",
]

MANIFEST_LITERAL_CHECKS = [
    ('android:versionName="1.0.0"', "versionName is 1.0.0"),
    ('android:screenOrientation="portrait"', "screenOrientation is portrait"),
]

GITIGNORE_PATH = Path(".gitignore")


# ---------------------------------------------------------------------------
# Result tracking
# ---------------------------------------------------------------------------

_failures: list[str] = []


def _pass(msg: str) -> None:
    print(f"PASS: {msg}")


def _fail(msg: str) -> None:
    print(f"FAIL: {msg}")
    _failures.append(msg)


def _skip(msg: str) -> None:
    print(f"SKIP: {msg}")


# ---------------------------------------------------------------------------
# Checks
# ---------------------------------------------------------------------------

def check_apk_exists(apk: Path) -> bool:
    if not apk.exists():
        _fail(f"APK not found: {apk}")
        return False
    if apk.stat().st_size == 0:
        _fail(f"APK is zero bytes: {apk}")
        return False
    _pass(f"APK exists ({apk.stat().st_size // 1024} KB): {apk}")
    return True


def _run_aapt(apk: Path) -> tuple[bool, str]:
    """Try aapt then aapt2. Return (success, output)."""
    for tool in ("aapt", "aapt2"):
        if shutil.which(tool) is None:
            continue
        result = subprocess.run(
            [tool, "dump", "badging", str(apk)],
            capture_output=True,
            text=True,
        )
        if result.returncode == 0:
            return True, result.stdout
        # aapt found but failed — still report the error
        return False, result.stderr or result.stdout
    return False, ""


def check_package_and_version(apk: Path) -> None:
    ok, output = _run_aapt(apk)

    if not ok and not output:
        _skip(
            "aapt/aapt2 not found in PATH — "
            "install Android SDK Build Tools and add aapt/aapt2 to PATH"
        )
        return

    if not ok:
        _fail(f"aapt/aapt2 failed: {output.strip()}")
        return

    # package name
    pkg_match = re.search(r"package: name='([^']+)'", output)
    if not pkg_match:
        _fail("Could not parse package name from aapt output")
    elif pkg_match.group(1) != EXPECTED_PACKAGE:
        _fail(
            f"package name mismatch: got '{pkg_match.group(1)}', "
            f"expected '{EXPECTED_PACKAGE}'"
        )
    else:
        _pass(f"package name {pkg_match.group(1)}")

    # versionCode
    vc_match = re.search(r"versionCode='([^']+)'", output)
    if not vc_match:
        _fail("Could not parse versionCode from aapt output")
    elif vc_match.group(1) != EXPECTED_VERSION_CODE:
        _fail(
            f"versionCode mismatch: got '{vc_match.group(1)}', "
            f"expected '{EXPECTED_VERSION_CODE}'"
        )
    else:
        _pass(f"versionCode {vc_match.group(1)}")

    # versionName
    vn_match = re.search(r"versionName='([^']+)'", output)
    if not vn_match:
        _fail("Could not parse versionName from aapt output")
    elif vn_match.group(1) != EXPECTED_VERSION_NAME:
        _fail(
            f"versionName mismatch: got '{vn_match.group(1)}', "
            f"expected '{EXPECTED_VERSION_NAME}'"
        )
    else:
        _pass(f"versionName {vn_match.group(1)}")


def check_apk_signature(apk: Path) -> None:
    if shutil.which("apksigner") is None:
        _skip(
            "apksigner not found in PATH — "
            "install Android SDK Build Tools and add apksigner to PATH"
        )
        return

    result = subprocess.run(
        ["apksigner", "verify", "--verbose", str(apk)],
        capture_output=True,
        text=True,
    )
    if result.returncode == 0:
        _pass("APK signature verified")
    else:
        _fail(
            f"APK signature verification failed: "
            f"{(result.stderr or result.stdout).strip()}"
        )


def check_yandex_aar() -> None:
    if YANDEX_AAR_PATH.exists():
        _pass("AndroidYandexAds release AAR exists")
    else:
        _fail(
            f"AndroidYandexAds release AAR not found: {YANDEX_AAR_PATH}\n"
            "  Build it first:\n"
            "    cp android/build/libs/release/godot-lib.template_release.aar"
            " addons/android_yandex_ads/android/AndroidYandexAdsPlugin/libs/\n"
            "    cd addons/android_yandex_ads/android/AndroidYandexAdsPlugin\n"
            "    ./gradlew assembleRelease"
        )


def check_export_presets() -> None:
    if not EXPORT_PRESETS_PATH.exists():
        _fail(f"{EXPORT_PRESETS_PATH} not found")
        return

    content = EXPORT_PRESETS_PATH.read_text(encoding="utf-8")
    missing = [s for s in REQUIRED_PRESET_STRINGS if s not in content]
    if missing:
        for m in missing:
            _fail(f"export_presets.cfg missing expected line: {m}")
    else:
        _pass("export_presets.cfg release identity ok")


def check_android_template_files() -> None:
    """Verify that required Android build template files are present on disk."""
    for path in ANDROID_TEMPLATE_FILES:
        if path.exists():
            _pass(f"Android template file present: {path}")
        else:
            _fail(f"Android template file missing: {path}")


def check_rustore_manifest() -> None:
    manifest = Path("android/build/AndroidManifest.xml")
    if not manifest.exists():
        _fail(f"{manifest} not found — cannot check RuStore Pay entries")
        return
    content = manifest.read_text(encoding="utf-8")
    for tag in RUSTORE_MANIFEST_TAGS:
        if tag in content:
            _pass(f"AndroidManifest.xml contains RuStore entry: {tag}")
        else:
            _fail(f"AndroidManifest.xml missing RuStore entry: {tag}")
    for literal, description in MANIFEST_LITERAL_CHECKS:
        if literal in content:
            _pass(f"AndroidManifest.xml {description}")
        else:
            _fail(f"AndroidManifest.xml expected '{literal}' ({description})")


def check_gitignore() -> None:
    if not GITIGNORE_PATH.exists():
        _fail(".gitignore not found")
        return

    content = GITIGNORE_PATH.read_text(encoding="utf-8")
    lines = {line.strip() for line in content.splitlines()}
    missing = [p for p in REQUIRED_GITIGNORE_PATTERNS if p not in lines]
    if missing:
        for m in missing:
            _fail(f".gitignore missing pattern: {m}")
    else:
        _pass(".gitignore release protections ok")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Read-only Android release validator for Shinobi Clicker: Idle."
    )
    parser.add_argument("--apk", required=True, help="Path to the release APK to validate")
    args = parser.parse_args()

    apk = Path(args.apk)

    print(f"Validating Android release APK: {apk}")
    print()

    apk_ok = check_apk_exists(apk)

    if apk_ok:
        check_package_and_version(apk)
        check_apk_signature(apk)
    else:
        _skip("package/version checks skipped — APK not found")
        _skip("signature check skipped — APK not found")

    check_yandex_aar()
    check_export_presets()
    check_gitignore()
    check_android_template_files()
    check_rustore_manifest()

    print()
    if _failures:
        print(f"Release validation FAILED ({len(_failures)} issue(s)).")
        sys.exit(1)
    else:
        print("Release validation passed.")
        sys.exit(0)


if __name__ == "__main__":
    main()
