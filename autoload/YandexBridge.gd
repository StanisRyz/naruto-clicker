extends Node

signal rewarded_ad_opened
signal rewarded_ad_rewarded
signal rewarded_ad_closed(was_shown: bool)
signal rewarded_ad_error(message: String)

signal fullscreen_ad_opened
signal fullscreen_ad_closed(was_shown: bool)
signal fullscreen_ad_error(message: String)

signal payment_purchase_started(product_id: String)
signal payment_purchase_success(product_id: String, purchase_token: String)
signal payment_purchase_cancelled(product_id: String)
signal payment_purchase_error(product_id: String, message: String)
signal unprocessed_purchase_found(product_id: String, purchase_token: String)
signal unprocessed_purchase_check_completed
signal unprocessed_purchase_check_error(message: String)

signal cloud_save_loaded(data: Dictionary)
signal cloud_save_load_error(message: String)
signal cloud_save_completed
signal cloud_save_error(message: String)
signal cloud_save_deleted
signal cloud_save_delete_error(message: String)

const CLOUD_SAVE_KEY: String = "save_v1"
const CLOUD_SAVE_SCHEMA_VERSION: int = 1
const SDK_READY_RETRY_DELAY_SEC: float = 0.5
const SDK_READY_MAX_RETRY_ATTEMPTS: int = 20

var is_web: bool = false
var is_yandex_available: bool = false

var _rewarded_ad_in_progress: bool = false
var _fullscreen_ad_in_progress: bool = false
var _payment_js_callbacks_setup: bool = false

func _ready() -> void:
	is_web = OS.has_feature("web")

	if not is_web:
		print("YandexBridge: running outside Web export")
		return

	_check_yandex_sdk()
	_setup_js_callbacks()


func get_yandex_language() -> String:
	if not _is_ysdk_ready():
		return ""
	var result = JavaScriptBridge.eval("""
		(function() {
			try {
				if (!window.ysdk || !window.ysdk.environment || !window.ysdk.environment.i18n) return "";
				var lang = window.ysdk.environment.i18n.lang;
				return (typeof lang === "string") ? lang.toLowerCase() : "";
			} catch(e) {
				return "";
			}
		})();
	""")
	if result == null or not (result is String):
		return ""
	return str(result)


func _check_yandex_sdk() -> void:
	refresh_yandex_sdk_ready()

	if is_yandex_available:
		print("YandexBridge: Yandex SDK is ready")
	else:
		print("YandexBridge: Yandex SDK is not ready")


func refresh_yandex_sdk_ready() -> bool:
	if not is_web:
		is_yandex_available = false
		return false
	var result = JavaScriptBridge.eval("""
		(function() {
			try {
				return !!(window.ysdk && (window.ysdkReady === undefined || window.ysdkReady === true));
			} catch(e) {
				return false;
			}
		})();
	""")
	is_yandex_available = result == true
	return is_yandex_available


func _is_ysdk_ready() -> bool:
	return refresh_yandex_sdk_ready()


func game_ready(attempt: int = 0) -> void:
	if not _is_ysdk_ready():
		_retry_game_ready(attempt)
		return

	JavaScriptBridge.eval("""
		if (window.ysdk && window.ysdk.features && window.ysdk.features.LoadingAPI) {
			window.ysdk.features.LoadingAPI.ready();
			console.log("Yandex LoadingAPI.ready() called");
		} else {
			console.log("Yandex SDK is not initialized yet");
		}
	""")


func is_ad_in_progress() -> bool:
	return _rewarded_ad_in_progress or _fullscreen_ad_in_progress


func gameplay_start(attempt: int = 0) -> void:
	if not _is_ysdk_ready():
		_retry_gameplay_start(attempt)
		return

	JavaScriptBridge.eval("""
		if (window.ysdk && window.ysdk.features && window.ysdk.features.GameplayAPI) {
			window.ysdk.features.GameplayAPI.start();
		}
	""")


func gameplay_stop() -> void:
	if not _is_ysdk_ready():
		return

	JavaScriptBridge.eval("""
		if (window.ysdk && window.ysdk.features && window.ysdk.features.GameplayAPI) {
			window.ysdk.features.GameplayAPI.stop();
		}
	""")


func _retry_game_ready(attempt: int) -> void:
	if not is_web or attempt >= SDK_READY_MAX_RETRY_ATTEMPTS:
		return
	await get_tree().create_timer(SDK_READY_RETRY_DELAY_SEC).timeout
	game_ready(attempt + 1)


func _retry_gameplay_start(attempt: int) -> void:
	if not is_web or attempt >= SDK_READY_MAX_RETRY_ATTEMPTS:
		return
	await get_tree().create_timer(SDK_READY_RETRY_DELAY_SEC).timeout
	gameplay_start(attempt + 1)


func show_rewarded_ad() -> void:
	if _rewarded_ad_in_progress:
		return
	_rewarded_ad_in_progress = true

	if not _is_ysdk_ready():
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
	_setup_fullscreen_ad_js_callbacks()
	_setup_cloud_save_js_callbacks()
	_setup_unprocessed_purchase_js_callbacks()


func _simulate_rewarded_ad_debug() -> void:
	rewarded_ad_opened.emit()
	await Engine.get_main_loop().create_timer(0.5).timeout
	rewarded_ad_rewarded.emit()
	await Engine.get_main_loop().create_timer(0.1).timeout
	_rewarded_ad_in_progress = false
	rewarded_ad_closed.emit(true)


# ── Fullscreen ad ─────────────────────────────────────────────────────────────

func show_fullscreen_ad() -> void:
	if _fullscreen_ad_in_progress:
		return
	_fullscreen_ad_in_progress = true

	if not _is_ysdk_ready():
		_fullscreen_ad_in_progress = false
		fullscreen_ad_error.emit("Fullscreen ad unavailable outside Yandex Games")
		return

	JavaScriptBridge.eval("""
		(function() {
			window.ysdk.adv.showFullscreenAdv({
				callbacks: {
					onOpen: function() {
						if (window._godot_fullscreen_ad_open) window._godot_fullscreen_ad_open();
					},
					onClose: function(wasShown) {
						if (window._godot_fullscreen_ad_close) window._godot_fullscreen_ad_close(wasShown ? 1 : 0);
					},
					onError: function(err) {
						if (window._godot_fullscreen_ad_error) window._godot_fullscreen_ad_error(String(err));
					}
				}
			});
		})();
	""")


func _on_js_fullscreen_ad_open() -> void:
	fullscreen_ad_opened.emit()


func _on_js_fullscreen_ad_close(was_shown_int: int) -> void:
	_fullscreen_ad_in_progress = false
	fullscreen_ad_closed.emit(was_shown_int != 0)


func _on_js_fullscreen_ad_error(message: String) -> void:
	_fullscreen_ad_in_progress = false
	fullscreen_ad_error.emit(message)


func _setup_fullscreen_ad_js_callbacks() -> void:
	var open_cb := JavaScriptBridge.create_callback(_on_js_fullscreen_ad_open)
	var close_cb := JavaScriptBridge.create_callback(func(args): _on_js_fullscreen_ad_close(int(args[0])))
	var error_cb := JavaScriptBridge.create_callback(func(args): _on_js_fullscreen_ad_error(str(args[0])))
	JavaScriptBridge.eval("window._godot_fullscreen_ad_open = %s;" % open_cb)
	JavaScriptBridge.eval("window._godot_fullscreen_ad_close = %s;" % close_cb)
	JavaScriptBridge.eval("window._godot_fullscreen_ad_error = %s;" % error_cb)


func purchase_product(yandex_product_id: String, local_product_id: String) -> void:
	payment_purchase_started.emit(local_product_id)

	if not _is_ysdk_ready():
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
	if not _is_ysdk_ready() or purchase_token == "":
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


func check_unprocessed_purchases() -> void:
	if not _is_ysdk_ready():
		unprocessed_purchase_check_error.emit("Yandex SDK is not ready")
		return

	JavaScriptBridge.eval("""
		(function() {
			try {
				window.ysdk.getPayments({ signed: true }).then(function(payments) {
					return payments.getPurchases();
				}).then(function(purchases) {
					var list = Array.isArray(purchases) ? purchases : [];
					list.forEach(function(purchase) {
						var productId = "";
						var token = "";
						if (purchase) {
							productId = purchase.productID || purchase.productId || purchase.product_id || purchase.id || "";
							token = purchase.purchaseToken || purchase.purchase_token || purchase.token || "";
						}
						if (productId && token && window._godot_unprocessed_purchase_found) {
							window._godot_unprocessed_purchase_found(String(productId), String(token));
						}
					});
					if (window._godot_unprocessed_purchase_check_completed) {
						window._godot_unprocessed_purchase_check_completed();
					}
				}).catch(function(err) {
					console.warn("YandexBridge: getPurchases failed:", err);
					if (window._godot_unprocessed_purchase_check_error) {
						window._godot_unprocessed_purchase_check_error(String(err));
					}
				});
			} catch(e) {
				console.warn("YandexBridge: getPurchases exception:", e);
				if (window._godot_unprocessed_purchase_check_error) {
					window._godot_unprocessed_purchase_check_error(String(e));
				}
			}
		})();
	""")


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
	payment_purchase_success.emit(local_product_id, "debug_token_%d" % Time.get_ticks_usec())


# ── Cloud save ────────────────────────────────────────────────────────────────

func is_cloud_save_available() -> bool:
	return _is_ysdk_ready()


func load_cloud_save() -> void:
	if not _is_ysdk_ready():
		cloud_save_loaded.emit({})
		return

	var js_key: String = JSON.stringify(CLOUD_SAVE_KEY)
	JavaScriptBridge.eval("""
		(function() {
			try {
				window.ysdk.getPlayer({ scopes: false }).then(function(player) {
					window._godot_yandex_player = player;
					return player.getData([%s]);
				}).then(function(data) {
					var entry = data[%s];
					var jsonStr = (entry && typeof entry === 'object') ? JSON.stringify(entry) : '{}';
					if (window._godot_cloud_save_loaded) window._godot_cloud_save_loaded(jsonStr);
				}).catch(function(err) {
					console.warn("YandexBridge: cloud load error:", err);
					if (window._godot_cloud_save_load_error) window._godot_cloud_save_load_error(String(err));
				});
			} catch(e) {
				console.warn("YandexBridge: cloud load exception:", e);
				if (window._godot_cloud_save_load_error) window._godot_cloud_save_load_error(String(e));
			}
		})();
	""" % [js_key, js_key])


func save_cloud_save(data: Dictionary, flush: bool = false) -> void:
	if not _is_ysdk_ready():
		return

	var json_string: String = JSON.stringify(data)
	var js_data_literal: String = JSON.stringify(json_string)
	var js_flush: String = "true" if flush else "false"
	var js_key: String = JSON.stringify(CLOUD_SAVE_KEY)

	JavaScriptBridge.eval("""
		(function() {
			try {
				var rawData = JSON.parse(%s);
				var payload = {};
				payload[%s] = rawData;
				var doSave = function(player) {
					player.setData(payload, %s).then(function() {
						if (window._godot_cloud_save_completed) window._godot_cloud_save_completed();
					}).catch(function(err) {
						console.warn("YandexBridge: cloud save error:", err);
						if (window._godot_cloud_save_error) window._godot_cloud_save_error(String(err));
					});
				};
				if (window._godot_yandex_player) {
					doSave(window._godot_yandex_player);
				} else {
					window.ysdk.getPlayer({ scopes: false }).then(function(player) {
						window._godot_yandex_player = player;
						doSave(player);
					}).catch(function(err) {
						console.warn("YandexBridge: getPlayer error on save:", err);
						if (window._godot_cloud_save_error) window._godot_cloud_save_error(String(err));
					});
				}
			} catch(e) {
				console.warn("YandexBridge: cloud save exception:", e);
				if (window._godot_cloud_save_error) window._godot_cloud_save_error(String(e));
			}
		})();
	""" % [js_data_literal, js_key, js_flush])


func delete_cloud_save() -> void:
	if not _is_ysdk_ready():
		cloud_save_deleted.emit()
		return

	var js_key: String = JSON.stringify(CLOUD_SAVE_KEY)

	JavaScriptBridge.eval("""
		(function() {
			try {
				var payload = {};
				payload[%s] = {};
				var doDelete = function(player) {
					player.setData(payload, true).then(function() {
						if (window._godot_cloud_save_deleted) window._godot_cloud_save_deleted();
					}).catch(function(err) {
						console.warn("YandexBridge: cloud delete error:", err);
						if (window._godot_cloud_save_delete_error) window._godot_cloud_save_delete_error(String(err));
					});
				};
				if (window._godot_yandex_player) {
					doDelete(window._godot_yandex_player);
				} else {
					window.ysdk.getPlayer({ scopes: false }).then(function(player) {
						window._godot_yandex_player = player;
						doDelete(player);
					}).catch(function(err) {
						console.warn("YandexBridge: getPlayer error on delete:", err);
						if (window._godot_cloud_save_delete_error) window._godot_cloud_save_delete_error(String(err));
					});
				}
			} catch(e) {
				console.warn("YandexBridge: cloud delete exception:", e);
				if (window._godot_cloud_save_delete_error) window._godot_cloud_save_delete_error(String(e));
			}
		})();
	""" % js_key)


func _on_js_cloud_save_loaded(json_str: String) -> void:
	if json_str == "" or json_str == "{}":
		cloud_save_loaded.emit({})
		return
	var json: JSON = JSON.new()
	var parse_err: int = json.parse(json_str)
	if parse_err != OK or not json.data is Dictionary:
		push_warning("YandexBridge: cloud save parse failed — %s" % json_str.left(120))
		cloud_save_load_error.emit("Cloud save JSON parse failed")
		return
	cloud_save_loaded.emit(json.data)


func _on_js_cloud_save_load_error(message: String) -> void:
	push_warning("YandexBridge: cloud load error — %s" % message)
	cloud_save_load_error.emit(message)


func _on_js_cloud_save_completed() -> void:
	cloud_save_completed.emit()


func _on_js_cloud_save_error(message: String) -> void:
	push_warning("YandexBridge: cloud save error — %s" % message)
	cloud_save_error.emit(message)


func _on_js_cloud_save_deleted() -> void:
	cloud_save_deleted.emit()


func _on_js_cloud_save_delete_error(message: String) -> void:
	push_warning("YandexBridge: cloud delete error — %s" % message)
	cloud_save_delete_error.emit(message)


func _setup_cloud_save_js_callbacks() -> void:
	var loaded_cb := JavaScriptBridge.create_callback(func(args): _on_js_cloud_save_loaded(str(args[0])))
	var load_err_cb := JavaScriptBridge.create_callback(func(args): _on_js_cloud_save_load_error(str(args[0])))
	var completed_cb := JavaScriptBridge.create_callback(_on_js_cloud_save_completed)
	var save_err_cb := JavaScriptBridge.create_callback(func(args): _on_js_cloud_save_error(str(args[0])))
	var deleted_cb := JavaScriptBridge.create_callback(_on_js_cloud_save_deleted)
	var delete_err_cb := JavaScriptBridge.create_callback(func(args): _on_js_cloud_save_delete_error(str(args[0])))
	JavaScriptBridge.eval("window._godot_cloud_save_loaded = %s;" % loaded_cb)
	JavaScriptBridge.eval("window._godot_cloud_save_load_error = %s;" % load_err_cb)
	JavaScriptBridge.eval("window._godot_cloud_save_completed = %s;" % completed_cb)
	JavaScriptBridge.eval("window._godot_cloud_save_error = %s;" % save_err_cb)
	JavaScriptBridge.eval("window._godot_cloud_save_deleted = %s;" % deleted_cb)
	JavaScriptBridge.eval("window._godot_cloud_save_delete_error = %s;" % delete_err_cb)


func _on_js_unprocessed_purchase_found(product_id: String, purchase_token: String) -> void:
	unprocessed_purchase_found.emit(product_id, purchase_token)


func _on_js_unprocessed_purchase_check_completed() -> void:
	unprocessed_purchase_check_completed.emit()


func _on_js_unprocessed_purchase_check_error(message: String) -> void:
	unprocessed_purchase_check_error.emit(message)


func _setup_unprocessed_purchase_js_callbacks() -> void:
	var found_cb := JavaScriptBridge.create_callback(func(args): _on_js_unprocessed_purchase_found(str(args[0]), str(args[1])))
	var completed_cb := JavaScriptBridge.create_callback(_on_js_unprocessed_purchase_check_completed)
	var error_cb := JavaScriptBridge.create_callback(func(args): _on_js_unprocessed_purchase_check_error(str(args[0])))
	JavaScriptBridge.eval("window._godot_unprocessed_purchase_found = %s;" % found_cb)
	JavaScriptBridge.eval("window._godot_unprocessed_purchase_check_completed = %s;" % completed_cb)
	JavaScriptBridge.eval("window._godot_unprocessed_purchase_check_error = %s;" % error_cb)
