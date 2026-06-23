## Godot editor plugin for the RuStore Pay SDK Android bridge.
## Enable this plugin via Project → Project Settings → Plugins → AndroidRuStorePay.
## The plugin wires the compiled plugin AAR into the Godot Android Gradle export.
##
## Before exporting to Android, build the AAR:
##   cd addons/android_rustore_pay/android/AndroidRuStorePayPlugin
##   ./gradlew assembleRelease        (release export)
##   ./gradlew assembleDebug          (debug export)
## The AAR is produced at:
##   build/outputs/aar/AndroidRuStorePayPlugin-{debug,release}.aar
##
## RuStore Pay SDK dependency:
##   The SDK AAR is NOT bundled here. Add the official RuStore Pay SDK
##   Maven coordinate to _get_android_dependencies() once you have it from
##   RuStore developer documentation, or drop the SDK AAR into android/plugins/.
##   See docs/rustore_pay_integration.md for the full integration checklist.
@tool
extends EditorPlugin

var _export_plugin: _AndroidRuStorePayExportPlugin


func _enter_tree() -> void:
	_export_plugin = _AndroidRuStorePayExportPlugin.new()
	add_export_plugin(_export_plugin)


func _exit_tree() -> void:
	remove_export_plugin(_export_plugin)
	_export_plugin = null


class _AndroidRuStorePayExportPlugin extends EditorExportPlugin:
	const _AAR_BASE: String = "res://addons/android_rustore_pay/android/AndroidRuStorePayPlugin/build/outputs/aar/"

	func _get_name() -> String:
		return "AndroidRuStorePay"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform.get_os_name() == "Android"

	# TODO: Add the official RuStore Pay SDK Maven coordinate here once confirmed
	# from RuStore developer documentation. Example (verify before using):
	#   return PackedStringArray(["ru.rustore.sdk:pay:X.Y.Z"])
	func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray()

	# TODO: Add the RuStore Maven repository URL here if the SDK is hosted on Maven.
	# Example (verify from official docs):
	#   return PackedStringArray(["https://artifactory.rustore.ru/artifactory/apps/"])
	func _get_android_maven_repos(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray()

	# Points Godot to the compiled plugin AAR. Returns empty if the AAR has not
	# been built yet — export will still proceed but the plugin will be absent.
	func _get_android_libraries(_platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		var build_type: String = "debug" if debug else "release"
		var res_path: String = _AAR_BASE + "AndroidRuStorePayPlugin-%s.aar" % build_type
		if not FileAccess.file_exists(res_path):
			return PackedStringArray()
		var abs_path: String = ProjectSettings.globalize_path(res_path)
		return PackedStringArray([abs_path])
