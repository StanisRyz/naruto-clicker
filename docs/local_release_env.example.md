# Local Release Environment Template

This file documents the local paths and credentials the developer must configure
manually before building a release APK. **Do not commit real values.**

Copy the fields below into a local file (e.g. `local_release_env.sh` or a
password manager note) and fill in the correct values for your machine.
Never commit the file with real values to git.

---

## Fields

```
# Path to the Godot editor binary on your machine.
# Example: /home/user/godot/Godot_v4.5.1-stable_linux.x86_64
#          C:/Godot/Godot_v4.5.1-stable_win64.exe
GODOT_BINARY=

# Absolute path to the release keystore file (.jks or .keystore).
# Keep this outside the repository directory.
# Example: /home/user/android_keys/shinobi_clicker_idle_release.jks
#          C:/Users/YourName/android_keys/shinobi_clicker_idle_release.jks
ANDROID_RELEASE_KEYSTORE=

# Alias of the release key inside the keystore.
ANDROID_RELEASE_KEY_ALIAS=

# Desired output path for the exported release APK.
# Example: /home/user/builds/shinobi_clicker_idle_release.apk
#          C:/builds/shinobi_clicker_idle_release.apk
ANDROID_RELEASE_OUTPUT_APK=
```

---

## Notes

- Keystore password and key password are entered interactively in the Godot
  export dialog. Do not store them in plaintext files.
- `GODOT_BINARY` is only needed for headless CLI exports. The Godot editor can
  also export via **Project → Export**.
- `ANDROID_RELEASE_KEYSTORE` must point to the persistent release keystore that
  was used for the first RuStore upload. Switching keystores after the first
  upload will break future updates.
- These values are machine-specific. Each developer configures them locally.

---

## .gitignore reminder

Ensure the following are in `.gitignore`:

```
*.jks
*.keystore
*.p12
local.properties
local_release_env.sh
local_release_env.ps1
```
