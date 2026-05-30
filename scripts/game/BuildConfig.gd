extends Node

const APP_VERSION: String = "0.1.0"

# Set to false before public release to hide dev-only tools.
# Do not rely solely on OS.is_debug_build() — Web/Android test builds
# may need manual control over dev feature visibility.
const IS_DEBUG_BUILD: bool = true
