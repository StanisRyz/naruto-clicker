extends Node

signal rewarded_ad_opened
signal rewarded_ad_rewarded
signal rewarded_ad_closed(was_shown: bool)
signal rewarded_ad_error(message: String)

var is_web: bool = false
var is_yandex_available: bool = false

var _rewarded_ad_in_progress: bool = false

func _ready() -> void:
	is_web = OS.has_feature("web")

	if not is_web:
		print("YandexBridge: running outside Web export")
		return

	_check_yandex_sdk()
	_setup_js_callbacks()


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


func show_rewarded_ad() -> void:
	if _rewarded_ad_in_progress:
		return
	_rewarded_ad_in_progress = true

	if not is_web or not is_yandex_available:
		_simulate_rewarded_ad_debug()
		return

	JavaScriptBridge.eval("""
		(function() {
			window.ysdk.adv.showRewardedVideo({
				callbacks: {
					onOpen: function() {
						if (window._godot_rewarded_ad_open) window._godot_rewarded_ad_open();
					},
					onRewarded: function() {
						if (window._godot_rewarded_ad_rewarded) window._godot_rewarded_ad_rewarded();
					},
					onClose: function(wasShown) {
						if (window._godot_rewarded_ad_close) window._godot_rewarded_ad_close(wasShown ? 1 : 0);
					},
					onError: function(err) {
						if (window._godot_rewarded_ad_error) window._godot_rewarded_ad_error(String(err));
					}
				}
			});
		})();
	""")


func _on_js_rewarded_ad_open() -> void:
	rewarded_ad_opened.emit()


func _on_js_rewarded_ad_rewarded() -> void:
	rewarded_ad_rewarded.emit()


func _on_js_rewarded_ad_close(was_shown_int: int) -> void:
	_rewarded_ad_in_progress = false
	rewarded_ad_closed.emit(was_shown_int != 0)


func _on_js_rewarded_ad_error(message: String) -> void:
	_rewarded_ad_in_progress = false
	rewarded_ad_error.emit(message)


func _setup_js_callbacks() -> void:
	if not is_web:
		return
	var open_cb := JavaScriptBridge.create_callback(_on_js_rewarded_ad_open)
	var reward_cb := JavaScriptBridge.create_callback(_on_js_rewarded_ad_rewarded)
	var close_cb := JavaScriptBridge.create_callback(func(args): _on_js_rewarded_ad_close(int(args[0])))
	var error_cb := JavaScriptBridge.create_callback(func(args): _on_js_rewarded_ad_error(str(args[0])))
	JavaScriptBridge.eval("window._godot_rewarded_ad_open = %s;" % open_cb)
	JavaScriptBridge.eval("window._godot_rewarded_ad_rewarded = %s;" % reward_cb)
	JavaScriptBridge.eval("window._godot_rewarded_ad_close = %s;" % close_cb)
	JavaScriptBridge.eval("window._godot_rewarded_ad_error = %s;" % error_cb)


func _simulate_rewarded_ad_debug() -> void:
	rewarded_ad_opened.emit()
	await Engine.get_main_loop().create_timer(0.5).timeout
	rewarded_ad_rewarded.emit()
	await Engine.get_main_loop().create_timer(0.1).timeout
	_rewarded_ad_in_progress = false
	rewarded_ad_closed.emit(true)
