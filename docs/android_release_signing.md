# Android Release Signing

## Why the release keystore is critical

Android requires every APK uploaded to a store to be signed with the same keystore
for the lifetime of that app listing. RuStore (and Google Play) use the signing
certificate as the permanent identity of your app. If you sign the first upload
with keystore A and then lose it, you **cannot** publish any future update — the
only way forward is to create a new listing and lose all ratings and installs.

Keep the release keystore safe and backed up in a location outside the repository.

---

## How to generate a release keystore

```bash
keytool -genkey -v \
  -keystore <KEYSTORE_PATH> \
  -alias <KEY_ALIAS> \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

Prompted fields:

- Keystore password → `<KEYSTORE_PASSWORD>`
- Key password → `<KEY_PASSWORD>` (may be the same as keystore password)
- Distinguished name (name, org, city, country) — fill in or leave blank

`-validity 10000` gives roughly 27 years. Use at least 10 000 days for a store key.

---

## Where to store the keystore locally

Keep the `.jks` / `.keystore` file in a directory **outside** the repository,
for example:

```
~/android_keys/shinobi_clicker_idle_release.jks
```

Back it up to an offline location (USB drive, encrypted cloud storage). The file
must not be committed to git at any point.

---

## What must never be committed

| What | Why |
|---|---|
| `*.jks` / `*.keystore` files | Contains the private key — loss = cannot update app |
| Keystore password | Credential |
| Key alias | Credential |
| Key password | Credential |
| Any local absolute path containing user/machine details | Machine-specific and potentially sensitive |

Add to `.gitignore`:

```
*.jks
*.keystore
*.p12
local.properties
```

---

## Configuring signing in the Godot export preset

Open **Project → Export → Android** and fill in the **Keystore** section:

| Field | Value |
|---|---|
| Release Keystore | `<KEYSTORE_PATH>` |
| Release User | `<KEY_ALIAS>` |
| Release Password | `<KEYSTORE_PASSWORD>` |

These values are stored in `export_presets.cfg`. Godot **does write passwords to
this file in plaintext**. If `export_presets.cfg` is committed, make sure it
does not contain real credentials — use Godot's "Export" dialog and fill in
credentials only locally, or set `package/signed=false` in the committed file and
configure signing separately in CI.

The current repo has `package/signed=true` set but no keystore paths or
passwords committed. Fill in the paths locally before exporting a release APK.

---

## Verifying that the APK is signed

After export, verify the signature with `apksigner` (part of Android SDK
Build-Tools):

```bash
apksigner verify --verbose <APK_PATH>
```

Expected output includes:

```
Verified using v1 scheme (JAR signing): true
Verified using v2 scheme (APK Signature Scheme v2): true
```

Or use `jarsigner`:

```bash
jarsigner -verify -verbose -certs <APK_PATH>
```

---

## Checking APK package name and version

```bash
# Using aapt (Android SDK Build-Tools)
aapt dump badging <APK_PATH> | grep -E "package:|versionCode|versionName"

# Expected output:
# package: name='com.stanis.shinobiclickeridle' versionCode='1' versionName='1.0.0'
```

Or with `aapt2`:

```bash
aapt2 dump badging <APK_PATH>
```

---

## Warning: losing the keystore blocks future updates

If the release keystore is lost:

- You **cannot** sign a new APK that matches the existing store listing.
- RuStore will reject the update (certificate mismatch).
- The only recovery is to unpublish the old listing and create a new one from scratch.

Back up the keystore to at least two separate locations before the first RuStore upload.

---

## Version code rule

- The first upload may use `version/code=1`.
- Every subsequent upload must use a strictly larger integer.
- Never reuse or decrease `version/code` after an upload.
- Increment `version/code` in `export_presets.cfg` before every release export.

See also: [docs/android_release_validation.md](android_release_validation.md)
