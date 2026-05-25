extends Node

var is_web: bool = false
var is_yandex_available: bool = false

func _ready() -> void:
	is_web = OS.has_feature("web")

	if not is_web:
		print("YandexBridge: running outside Web export")
		return

	_check_yandex_sdk()


func _check_yandex_sdk() -> void:
	var result = JavaScriptBridge.eval("""
		typeof YaGames !== 'undefined';
	""")

	is_yandex_available = result == true

	if is_yandex_available:
		print("YandexBridge: Yandex SDK is available")
	else:
		print("YandexBridge: Yandex SDK is not available")


func game_ready() -> void:
	if not is_web:
		return

	JavaScriptBridge.eval("""
		if (window.ysdk && window.ysdk.features && window.ysdk.features.LoadingAPI) {
			window.ysdk.features.LoadingAPI.ready();
			console.log("Yandex LoadingAPI.ready() called");
		} else {
			console.log("Yandex SDK is not initialized yet");
		}
	""")


func gameplay_start() -> void:
	if not is_web:
		return

	JavaScriptBridge.eval("""
		if (window.ysdk && window.ysdk.features && window.ysdk.features.GameplayAPI) {
			window.ysdk.features.GameplayAPI.start();
		}
	""")


func gameplay_stop() -> void:
	if not is_web:
		return

	JavaScriptBridge.eval("""
		if (window.ysdk && window.ysdk.features && window.ysdk.features.GameplayAPI) {
			window.ysdk.features.GameplayAPI.stop();
		}
	""")
