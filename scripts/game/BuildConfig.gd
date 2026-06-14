extends Node

const APP_VERSION: String = "0.1.0"

# Reflects OS.is_debug_build() at runtime: true in editor/debug exports, false in release exports.
var IS_DEBUG_BUILD: bool = OS.is_debug_build()


func is_debug_features_enabled() -> bool:
	return OS.is_debug_build()
