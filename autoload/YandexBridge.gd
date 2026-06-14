extends Node

signal rewarded_ad_opened
signal rewarded_ad_rewarded
signal rewarded_ad_closed(was_shown: bool)
signal rewarded_ad_error(message: String)

signal payment_purchase_started(product_id: String)
signal payment_purchase_success(product_id: String, purchase_token: String)
signal payment_purchase_cancelled(product_id: String)
signal payment_purchase_error(product_id: String, message: String)

var is_web: bool = false
var is_yandex_available: bool = false

var _rewarded_ad_in_progress: bool = false
var _payment_js_callbacks_setup: bool = false

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
		if BuildConfig.is_debug_features_enabled():
			_simulate_rewarded_ad_debug()
		else:
			_rewarded_ad_in_progress = false
			rewarded_ad_error.emit("Rewarded ad unavailable outside Yandex Games")
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


func purchase_product(yandex_product_id: String, local_product_id: String) -> void:
	payment_purchase_started.emit(local_product_id)

	if not is_web or not is_yandex_available:
		if BuildConfig.is_debug_features_enabled():
			_simulate_payment_debug(local_product_id)
		else:
			payment_purchase_error.emit(local_product_id, "Payments unavailable outside Yandex Games")
		return

	if not _payment_js_callbacks_setup:
		_setup_payment_js_callbacks()

	JavaScriptBridge.eval("""
		(function() {
			var localId = %s;
			var yandexId = %s;
			window.ysdk.getPayments({ signed: true }).then(function(payments) {
				payments.purchase({ id: yandexId }).then(function(purchase) {
					var token = purchase.purchaseToken || "";
					if (window._godot_payment_success) window._godot_payment_success(localId, token);
				}).catch(function(err) {
					var msg = String(err);
					if (msg.indexOf("cancel") !== -1 || msg.indexOf("Cancel") !== -1) {
						if (window._godot_payment_cancelled) window._godot_payment_cancelled(localId);
					} else {
						if (window._godot_payment_error) window._godot_payment_error(localId, msg);
					}
				});
			}).catch(function(err) {
				if (window._godot_payment_error) window._godot_payment_error(localId, String(err));
			});
		})();
	""" % [JSON.stringify(local_product_id), JSON.stringify(yandex_product_id)])


func consume_purchase(purchase_token: String) -> void:
	if not is_web or not is_yandex_available or purchase_token == "":
		return

	JavaScriptBridge.eval("""
		(function() {
			var token = %s;
			window.ysdk.getPayments({ signed: true }).then(function(payments) {
				payments.consumePurchase(token).catch(function(err) {
					console.warn("YandexBridge: consumePurchase failed:", err);
				});
			}).catch(function(err) {
				console.warn("YandexBridge: getPayments for consume failed:", err);
			});
		})();
	""" % JSON.stringify(purchase_token))


func _on_js_payment_success(local_product_id: String, purchase_token: String) -> void:
	payment_purchase_success.emit(local_product_id, purchase_token)


func _on_js_payment_cancelled(local_product_id: String) -> void:
	payment_purchase_cancelled.emit(local_product_id)


func _on_js_payment_error(local_product_id: String, message: String) -> void:
	payment_purchase_error.emit(local_product_id, message)


func _setup_payment_js_callbacks() -> void:
	_payment_js_callbacks_setup = true
	var success_cb := JavaScriptBridge.create_callback(func(args): _on_js_payment_success(str(args[0]), str(args[1])))
	var cancel_cb := JavaScriptBridge.create_callback(func(args): _on_js_payment_cancelled(str(args[0])))
	var error_cb := JavaScriptBridge.create_callback(func(args): _on_js_payment_error(str(args[0]), str(args[1])))
	JavaScriptBridge.eval("window._godot_payment_success = %s;" % success_cb)
	JavaScriptBridge.eval("window._godot_payment_cancelled = %s;" % cancel_cb)
	JavaScriptBridge.eval("window._godot_payment_error = %s;" % error_cb)


func _simulate_payment_debug(local_product_id: String) -> void:
	await Engine.get_main_loop().create_timer(0.5).timeout
	payment_purchase_success.emit(local_product_id, "debug_token")
