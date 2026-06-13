extends Control

signal reward_ad_requested

enum BannerState { AVAILABLE, LOADING, COOLDOWN, ERROR }

var _current_state: BannerState = BannerState.AVAILABLE

@onready var _button: Button = $Button
@onready var _label: Label = $Button/Label


func _ready() -> void:
	_button.pressed.connect(_on_button_pressed)
	_refresh_view()


func set_banner_state(new_state: BannerState) -> void:
	_current_state = new_state
	_refresh_view()


func _on_button_pressed() -> void:
	if _current_state == BannerState.AVAILABLE:
		reward_ad_requested.emit()


func _refresh_view() -> void:
	match _current_state:
		BannerState.AVAILABLE:
			_label.text = LocalizationManager.tr_key("rewarded_ad.banner.available")
			_button.disabled = false
			modulate = Color(1.0, 1.0, 1.0, 1.0)
		BannerState.LOADING:
			_label.text = LocalizationManager.tr_key("rewarded_ad.banner.loading")
			_button.disabled = true
			modulate = Color(0.85, 0.85, 0.85, 1.0)
		BannerState.COOLDOWN:
			_label.text = LocalizationManager.tr_key("rewarded_ad.banner.cooldown")
			_button.disabled = true
			modulate = Color(0.7, 0.7, 0.7, 1.0)
		BannerState.ERROR:
			_label.text = LocalizationManager.tr_key("rewarded_ad.banner.error")
			_button.disabled = true
			modulate = Color(0.6, 0.6, 0.6, 1.0)
