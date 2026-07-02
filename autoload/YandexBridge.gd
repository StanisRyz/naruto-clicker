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
signal payment_catalog_loaded(products: Array)
signal payment_catalog_error(message: String)

signal platform_pause_requested
signal platform_resume_requested

signal cloud_save_loaded(data: Dictionary)
signal cloud_save_load_error(message: String)
signal cloud_save_completed
signal cloud_save_error(message: String)
signal cloud_save_deleted
signal cloud_save_delete_error(message: String)

const CLOUD_SAVE_KEY: String = "save_v1"
const CLOUD_SAVE_SCHEMA_VERSION: int = 1
const SDK_READY_RETRY_DELAY_SEC: float = 0.5
const SDK_READY_MAX_RETRY_ATTEMPTS: int = 60
const PLATFORM_EVENTS_RETRY_DELAY_SEC: float = 0.5
const PLATFORM_EVENTS_MAX_RETRY_ATTEMPTS: int = 20

var is_web: bool = false
var is_yandex_available: bool = false

var _rewarded_ad_in_progress: bool = false
var _fullscreen_ad_in_progress: bool = false
var _payment_js_callbacks_setup: bool = false
var _platform_pause_cb = null
var _platform_resume_cb = null
var _platform_subscribed_cb = null
var _platform_sub_error_cb = null
var _platform_events_setup: bool = false
var _platform_events_subscribed: bool = false
var _last_platform_event_name: String = ""
var _platform_pause_event_count: int = 0
var _platform_resume_event_count: int = 0

var _rewarded_open_cb = null
var _rewarded_reward_cb = null
var _rewarded_close_cb = null
var _rewarded_error_cb = null

var _fullscreen_open_cb = null
var _fullscreen_close_cb = null
var _fullscreen_error_cb = null

var _payment_success_cb = null
var _payment_cancel_cb = null
var _payment_error_cb = null

var _catalog_js_callbacks_setup: bool = false
var _catalog_loaded_js_cb = null
var _catalog_error_js_cb = null
var _catalog_cache: Dictionary = {}

var _cloud_loaded_cb = null
var _cloud_load_err_cb = null
var _cloud_completed_cb = null
var _cloud_error_cb = null
var _cloud_deleted_cb = null
var _cloud_delete_err_cb = null

var _unprocessed_found_cb = null
var _unprocessed_completed_cb = null
var _unprocessed_error_cb = null

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
	var sdk_ready := _is_ysdk_ready()
	print("YandexBridge: game_ready attempt=%d sdk_ready=%s" % [attempt, str(sdk_ready)])
	if not sdk_ready:
		_retry_game_ready(attempt)
		return

	_setup_platform_event_callbacks()
	JavaScriptBridge.eval("""
		if (window.ysdk && window.ysdk.features && window.ysdk.features.LoadingAPI) {
			window.ysdk.features.LoadingAPI.ready();
			console.log("YandexBridge: LoadingAPI.ready() called");
		} else {
			console.log("YandexBridge: LoadingAPI not available at game_ready");
		}
	""")


func is_ad_in_progress() -> bool:
	return _rewarded_ad_in_progress or _fullscreen_ad_in_progress


func gameplay_start(attempt: int = 0) -> void:
	if not _is_ysdk_ready():
		_retry_gameplay_start(attempt)
		return

	_setup_platform_event_callbacks()
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
		push_warning("YandexBridge: game_ready retry exhausted after %d attempts" % attempt)
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
			try {
				if (!window.ysdk || !window.ysdk.adv || typeof window.ysdk.adv.showRewardedVideo !== 'function') {
					if (window._godot_rewarded_ad_error) window._godot_rewarded_ad_error('showRewardedVideo not available');
					return;
				}
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
			} catch(e) {
				if (window._godot_rewarded_ad_error) window._godot_rewarded_ad_error(String(e));
			}
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
	_rewarded_open_cb = JavaScriptBridge.create_callback(_on_js_rewarded_ad_open)
	_rewarded_reward_cb = JavaScriptBridge.create_callback(_on_js_rewarded_ad_rewarded)
	_rewarded_close_cb = JavaScriptBridge.create_callback(func(args): _on_js_rewarded_ad_close(int(args[0])))
	_rewarded_error_cb = JavaScriptBridge.create_callback(func(args): _on_js_rewarded_ad_error(str(args[0])))
	var _win := JavaScriptBridge.get_interface("window")
	_win._godot_rewarded_ad_open = _rewarded_open_cb
	_win._godot_rewarded_ad_rewarded = _rewarded_reward_cb
	_win._godot_rewarded_ad_close = _rewarded_close_cb
	_win._godot_rewarded_ad_error = _rewarded_error_cb
	if BuildConfig.is_debug_features_enabled():
		print("YandexBridge: rewarded ad callbacks registered on window")
	_setup_fullscreen_ad_js_callbacks()
	_setup_cloud_save_js_callbacks()
	_setup_unprocessed_purchase_js_callbacks()
	_setup_platform_event_callbacks()


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
			try {
				if (!window.ysdk || !window.ysdk.adv || typeof window.ysdk.adv.showFullscreenAdv !== 'function') {
					if (window._godot_fullscreen_ad_error) window._godot_fullscreen_ad_error('showFullscreenAdv not available');
					return;
				}
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
			} catch(e) {
				if (window._godot_fullscreen_ad_error) window._godot_fullscreen_ad_error(String(e));
			}
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
	_fullscreen_open_cb = JavaScriptBridge.create_callback(_on_js_fullscreen_ad_open)
	_fullscreen_close_cb = JavaScriptBridge.create_callback(func(args): _on_js_fullscreen_ad_close(int(args[0])))
	_fullscreen_error_cb = JavaScriptBridge.create_callback(func(args): _on_js_fullscreen_ad_error(str(args[0])))
	var _win := JavaScriptBridge.get_interface("window")
	_win._godot_fullscreen_ad_open = _fullscreen_open_cb
	_win._godot_fullscreen_ad_close = _fullscreen_close_cb
	_win._godot_fullscreen_ad_error = _fullscreen_error_cb
	if BuildConfig.is_debug_features_enabled():
		print("YandexBridge: fullscreen ad callbacks registered on window")


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
			try {
				var localId = %s;
				var yandexId = %s;

				if (!window.ysdk || typeof window.ysdk.getPayments !== "function") {
					if (window._godot_payment_error) window._godot_payment_error(localId, "getPayments not available");
					return;
				}

				window.ysdk.getPayments().then(function(payments) {
					if (!payments || typeof payments.purchase !== "function") {
						if (window._godot_payment_error) window._godot_payment_error(localId, "payments.purchase not available");
						return;
					}

					return payments.purchase({ id: yandexId }).then(function(purchase) {
						var token = purchase && purchase.purchaseToken ? purchase.purchaseToken : "";
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
			} catch(e) {
				if (window._godot_payment_error) window._godot_payment_error(localId, String(e));
			}
		})();
	""" % [JSON.stringify(local_product_id), JSON.stringify(yandex_product_id)])


func consume_purchase(purchase_token: String) -> void:
	if not _is_ysdk_ready() or purchase_token == "":
		return

	JavaScriptBridge.eval("""
		(function() {
			try {
				var token = %s;
				if (!window.ysdk || typeof window.ysdk.getPayments !== "function") {
					console.warn("YandexBridge: getPayments not available for consume");
					return;
				}
				window.ysdk.getPayments().then(function(payments) {
					if (!payments || typeof payments.consumePurchase !== "function") {
						console.warn("YandexBridge: consumePurchase not available");
						return;
					}
					payments.consumePurchase(token).catch(function(err) {
						console.warn("YandexBridge: consumePurchase failed:", err);
					});
				}).catch(function(err) {
					console.warn("YandexBridge: getPayments for consume failed:", err);
				});
			} catch(e) {
				console.warn("YandexBridge: consume exception:", e);
			}
		})();
	""" % JSON.stringify(purchase_token))


func check_unprocessed_purchases() -> void:
	if not _is_ysdk_ready():
		unprocessed_purchase_check_error.emit("Yandex SDK is not ready")
		return

	JavaScriptBridge.eval("""
		(function() {
			try {
				window.ysdk.getPayments().then(function(payments) {
					return payments.getPurchases();
				}).then(function(purchases) {
					if (!Array.isArray(purchases)) {
						console.warn("YandexBridge: getPurchases result is not an array:", purchases);
						if (window._godot_unprocessed_purchase_check_error) {
							window._godot_unprocessed_purchase_check_error("getPurchases returned unexpected type");
						}
						return;
					}
					purchases.forEach(function(purchase) {
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
	_payment_success_cb = JavaScriptBridge.create_callback(func(args): _on_js_payment_success(str(args[0]), str(args[1])))
	_payment_cancel_cb = JavaScriptBridge.create_callback(func(args): _on_js_payment_cancelled(str(args[0])))
	_payment_error_cb = JavaScriptBridge.create_callback(func(args): _on_js_payment_error(str(args[0]), str(args[1])))
	var _win := JavaScriptBridge.get_interface("window")
	_win._godot_payment_success = _payment_success_cb
	_win._godot_payment_cancelled = _payment_cancel_cb
	_win._godot_payment_error = _payment_error_cb
	if BuildConfig.is_debug_features_enabled():
		print("YandexBridge: payment callbacks registered on window")


func _simulate_payment_debug(local_product_id: String) -> void:
	await Engine.get_main_loop().create_timer(0.5).timeout
	payment_purchase_success.emit(local_product_id, "debug_token_%d" % Time.get_ticks_usec())


# ── Payment catalog ───────────────────────────────────────────────────────────

func load_payment_catalog() -> void:
	if not _is_ysdk_ready():
		payment_catalog_error.emit("Yandex SDK is not ready")
		return

	if not _catalog_js_callbacks_setup:
		_setup_catalog_js_callbacks()

	JavaScriptBridge.eval("""
		(function() {
			try {
				window.ysdk.getPayments().then(function(payments) {
					return payments.getCatalog();
				}).then(function(catalog) {
					var safe = (Array.isArray(catalog) ? catalog : []).map(function(p) {
						return {
							id: (p && p.id) ? String(p.id) : "",
							title: (p && p.title) ? String(p.title) : "",
							description: (p && p.description) ? String(p.description) : "",
							price: (p && p.price) ? String(p.price) : "",
							priceValue: (p && p.priceValue) ? String(p.priceValue) : "",
							priceCurrencyCode: (p && p.priceCurrencyCode) ? String(p.priceCurrencyCode) : "",
							priceCurrencyImage: (p && p.getPriceCurrencyImage) ? String(p.getPriceCurrencyImage("medium") || "") : ""
						};
					});
					if (window._godot_payment_catalog_loaded) {
						window._godot_payment_catalog_loaded(JSON.stringify(safe));
					}
				}).catch(function(err) {
					if (window._godot_payment_catalog_error) window._godot_payment_catalog_error(String(err));
				});
			} catch(e) {
				if (window._godot_payment_catalog_error) window._godot_payment_catalog_error(String(e));
			}
		})();
	""")


func get_cached_payment_catalog() -> Dictionary:
	return _catalog_cache


func get_catalog_product(local_product_id: String) -> Dictionary:
	var yandex_product_id: String = GemPurchaseConfig.get_platform_product_id(local_product_id, "yandex")
	if yandex_product_id == "":
		return {}
	var product: Dictionary = _catalog_cache.get(yandex_product_id, {})
	if product.is_empty() and BuildConfig.is_debug_features_enabled():
		print("YandexBridge: catalog product missing for local='%s' yandex_id='%s'" % [local_product_id, yandex_product_id])
	return product


func _on_js_payment_catalog_loaded(json_str: String) -> void:
	var json: JSON = JSON.new()
	var parse_err: int = json.parse(json_str)
	if parse_err != OK or not json.data is Array:
		push_warning("YandexBridge: catalog parse failed")
		payment_catalog_error.emit("Catalog parse failed")
		return
	var products: Array = json.data
	_catalog_cache.clear()
	for entry in products:
		if entry is Dictionary:
			var pid: String = String(entry.get("id", ""))
			if pid != "":
				_catalog_cache[pid] = entry
	if BuildConfig.is_debug_features_enabled():
		print("YandexBridge: catalog loaded, %d product(s)" % _catalog_cache.size())
	payment_catalog_loaded.emit(products)


func _on_js_payment_catalog_error(message: String) -> void:
	push_warning("YandexBridge: catalog load error — %s" % message)
	payment_catalog_error.emit(message)


func _setup_catalog_js_callbacks() -> void:
	_catalog_js_callbacks_setup = true
	_catalog_loaded_js_cb = JavaScriptBridge.create_callback(func(args): _on_js_payment_catalog_loaded(str(args[0])))
	_catalog_error_js_cb = JavaScriptBridge.create_callback(func(args): _on_js_payment_catalog_error(str(args[0])))
	var _win := JavaScriptBridge.get_interface("window")
	_win._godot_payment_catalog_loaded = _catalog_loaded_js_cb
	_win._godot_payment_catalog_error = _catalog_error_js_cb
	if BuildConfig.is_debug_features_enabled():
		print("YandexBridge: payment catalog callbacks registered on window")


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
	_cloud_loaded_cb = JavaScriptBridge.create_callback(func(args): _on_js_cloud_save_loaded(str(args[0])))
	_cloud_load_err_cb = JavaScriptBridge.create_callback(func(args): _on_js_cloud_save_load_error(str(args[0])))
	_cloud_completed_cb = JavaScriptBridge.create_callback(_on_js_cloud_save_completed)
	_cloud_error_cb = JavaScriptBridge.create_callback(func(args): _on_js_cloud_save_error(str(args[0])))
	_cloud_deleted_cb = JavaScriptBridge.create_callback(_on_js_cloud_save_deleted)
	_cloud_delete_err_cb = JavaScriptBridge.create_callback(func(args): _on_js_cloud_save_delete_error(str(args[0])))
	var _win := JavaScriptBridge.get_interface("window")
	_win._godot_cloud_save_loaded = _cloud_loaded_cb
	_win._godot_cloud_save_load_error = _cloud_load_err_cb
	_win._godot_cloud_save_completed = _cloud_completed_cb
	_win._godot_cloud_save_error = _cloud_error_cb
	_win._godot_cloud_save_deleted = _cloud_deleted_cb
	_win._godot_cloud_save_delete_error = _cloud_delete_err_cb
	if BuildConfig.is_debug_features_enabled():
		print("YandexBridge: cloud save callbacks registered on window")


func _on_js_unprocessed_purchase_found(product_id: String, purchase_token: String) -> void:
	unprocessed_purchase_found.emit(product_id, purchase_token)


func _on_js_unprocessed_purchase_check_completed() -> void:
	unprocessed_purchase_check_completed.emit()


func _on_js_unprocessed_purchase_check_error(message: String) -> void:
	unprocessed_purchase_check_error.emit(message)


func _setup_unprocessed_purchase_js_callbacks() -> void:
	_unprocessed_found_cb = JavaScriptBridge.create_callback(func(args): _on_js_unprocessed_purchase_found(str(args[0]), str(args[1])))
	_unprocessed_completed_cb = JavaScriptBridge.create_callback(_on_js_unprocessed_purchase_check_completed)
	_unprocessed_error_cb = JavaScriptBridge.create_callback(func(args): _on_js_unprocessed_purchase_check_error(str(args[0])))
	var _win := JavaScriptBridge.get_interface("window")
	_win._godot_unprocessed_purchase_found = _unprocessed_found_cb
	_win._godot_unprocessed_purchase_check_completed = _unprocessed_completed_cb
	_win._godot_unprocessed_purchase_check_error = _unprocessed_error_cb
	if BuildConfig.is_debug_features_enabled():
		print("YandexBridge: unprocessed purchase callbacks registered on window")


func is_platform_events_subscribed() -> bool:
	return _platform_events_subscribed


func get_platform_event_debug_state() -> Dictionary:
	return {
		"subscribed": _platform_events_subscribed,
		"last_event": _last_platform_event_name,
		"pause_count": _platform_pause_event_count,
		"resume_count": _platform_resume_event_count,
	}


func _on_js_platform_pause() -> void:
	_platform_pause_event_count += 1
	_last_platform_event_name = "game_api_pause"
	if BuildConfig.is_debug_features_enabled():
		print("YandexBridge: game_api_pause received (total=%d)" % _platform_pause_event_count)
	platform_pause_requested.emit()


func _on_js_platform_resume() -> void:
	_platform_resume_event_count += 1
	_last_platform_event_name = "game_api_resume"
	if BuildConfig.is_debug_features_enabled():
		print("YandexBridge: game_api_resume received (total=%d)" % _platform_resume_event_count)
	platform_resume_requested.emit()


func _on_js_platform_events_subscribed() -> void:
	_platform_events_subscribed = true
	if BuildConfig.is_debug_features_enabled():
		print("YandexBridge: platform events subscribed successfully")


func _on_js_platform_events_subscription_error(message: String) -> void:
	push_warning("YandexBridge: platform event subscription error — %s" % message)


func _setup_platform_event_callbacks(attempt: int = 0) -> void:
	if not is_web:
		return
	if _platform_events_setup:
		return
	if not _is_ysdk_ready():
		if attempt >= PLATFORM_EVENTS_MAX_RETRY_ATTEMPTS:
			push_warning("YandexBridge: platform event setup gave up after %d attempts — SDK never became ready" % attempt)
			return
		await get_tree().create_timer(PLATFORM_EVENTS_RETRY_DELAY_SEC).timeout
		_setup_platform_event_callbacks(attempt + 1)
		return
	var has_on = JavaScriptBridge.eval("""
		(function() {
			try { return !!(window.ysdk && typeof window.ysdk.on === 'function'); } catch(e) { return false; }
		})();
	""")
	if has_on != true:
		push_warning("YandexBridge: ysdk.on not available — game_api_pause/resume not subscribed")
		_platform_events_setup = true
		return
	if _platform_pause_cb == null:
		_platform_pause_cb = JavaScriptBridge.create_callback(func(_args): _on_js_platform_pause())
		_platform_resume_cb = JavaScriptBridge.create_callback(func(_args): _on_js_platform_resume())
		_platform_subscribed_cb = JavaScriptBridge.create_callback(func(_args): _on_js_platform_events_subscribed())
		_platform_sub_error_cb = JavaScriptBridge.create_callback(func(args): _on_js_platform_events_subscription_error(str(args[0])))
	var _win := JavaScriptBridge.get_interface("window")
	_win._godot_platform_pause_fn = _platform_pause_cb
	_win._godot_platform_resume_fn = _platform_resume_cb
	_win._godot_platform_events_subscribed = _platform_subscribed_cb
	_win._godot_platform_events_subscription_error = _platform_sub_error_cb
	JavaScriptBridge.eval("""
		(function() {
			try {
				window.ysdk.on('game_api_pause', window._godot_platform_pause_fn);
				window.ysdk.on('game_api_resume', window._godot_platform_resume_fn);
				console.log('YandexBridge: game_api_pause/resume subscribed');
				if (window._godot_platform_events_subscribed) window._godot_platform_events_subscribed();
			} catch(e) {
				console.warn('YandexBridge: platform event subscription failed:', e);
				if (window._godot_platform_events_subscription_error) window._godot_platform_events_subscription_error(String(e));
			}
		})();
	""")
	_platform_events_setup = true
