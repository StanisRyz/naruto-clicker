extends Control

signal reward_ad_requested

enum BannerState { AVAILABLE, LOADING, COOLDOWN, ERROR }

const _REWARD_BANNER_KEYS: Dictionary = {
	"all_damage_x2": "rewarded_ad.banner.all_damage",
	"gems_5":        "rewarded_ad.banner.gems",
	"gold_x4":       "rewarded_ad.banner.gold",
}

const _REWARD_ASSET_KEYS: Dictionary = {
	"all_damage_x2": "rewarded_ad.banner.all_damage",
	"gems_5":        "rewarded_ad.banner.gems",
	"gold_x4":       "rewarded_ad.banner.gold",
}

var _current_state: BannerState = BannerState.AVAILABLE
var _current_reward_id: String = ""

@onready var _button: Button = $Button
@onready var _label: Label = $Button/Label
@onready var _image: ImageSlot = $Button/ImageHolder


func _ready() -> void:
	_label.visible = false
	_button.pressed.connect(_on_button_pressed)
	_refresh_view()


func set_banner_state(new_state: BannerState) -> void:
	_current_state = new_state
	_refresh_view()


func set_reward_id(reward_id: String) -> void:
	_current_reward_id = reward_id
	_refresh_view()


func _on_button_pressed() -> void:
	if _current_state == BannerState.AVAILABLE:
		reward_ad_requested.emit()


func _refresh_view() -> void:
	match _current_state:
		BannerState.AVAILABLE:
			var asset_key: String = _REWARD_ASSET_KEYS.get(_current_reward_id, "")
			if asset_key != "":
				_image.set_asset_key(asset_key, Color.TRANSPARENT)
			else:
				_image.set_asset_key("", Color.TRANSPARENT)
			_button.disabled = false
			modulate = Color(1.0, 1.0, 1.0, 1.0)
		BannerState.LOADING:
			_button.disabled = true
			modulate = Color(0.85, 0.85, 0.85, 1.0)
		BannerState.COOLDOWN:
			_button.disabled = true
			modulate = Color(0.7, 0.7, 0.7, 1.0)
		BannerState.ERROR:
			_button.disabled = true
			modulate = Color(0.6, 0.6, 0.6, 1.0)
