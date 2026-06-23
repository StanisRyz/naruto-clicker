## Godot editor plugin for Android Yandex Mobile Ads SDK.
## Enable this plugin via Project → Project Settings → Plugins → AndroidYandexAds.
## The plugin wires the Yandex Mobile Ads SDK dependency and the compiled plugin
## AAR into the Godot Android Gradle export automatically.
##
## Before exporting to Android, build the AAR:
##   cd addons/android_yandex_ads/android/AndroidYandexAdsPlugin
##   ./gradlew assembleRelease        (release export)
##   ./gradlew assembleDebug          (debug export)
## The AAR is produced at:
##   build/outputs/aar/AndroidYandexAdsPlugin-{debug,release}.aar
@tool
extends EditorPlugin

var _export_plugin: _AndroidYandexAdsExportPlugin


func _enter_tree() -> void:
	_export_plugin = _AndroidYandexAdsExportPlugin.new()
	add_export_plugin(_export_plugin)


func _exit_tree() -> void:
	remove_export_plugin(_export_plugin)
	_export_plugin = null


class _AndroidYandexAdsExportPlugin extends EditorExportPlugin:
	const _AAR_BASE: String = "res://addons/android_yandex_ads/android/AndroidYandexAdsPlugin/build/outputs/aar/"

	func _get_name() -> String:
		return "AndroidYandexAds"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform.get_os_name() == "Android"

	# Adds Yandex Mobile Ads SDK as a Gradle Maven dependency in the Android build.
	func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray(["com.yandex.android:mobileads:8.1.0"])

	# Adds the Yandex Maven repository so Gradle can resolve mobileads.
	func _get_android_maven_repos(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray(["https://maven.yandex.ru/"])

	# Points Godot to the compiled plugin AAR for inclusion in the Android build.
	func _get_android_libraries(_platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		var build_type: String = "debug" if debug else "release"
		var res_path: String = _AAR_BASE + "AndroidYandexAdsPlugin-%s.aar" % build_type
		var abs_path: String = ProjectSettings.globalize_path(res_path)
		return PackedStringArray([abs_path])
