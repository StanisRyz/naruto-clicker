class_name AbilityBar
extends VBoxContainer

signal autoclick_requested
signal gold_bonus_requested
signal focus_burst_requested
signal rally_requested

@onready var autoclick_button: Button = $AutoclickButton
@onready var gold_bonus_button: Button = $GoldBonusButton
@onready var focus_burst_button: Button = $FocusBurstButton
@onready var rally_button: Button = $RallyButton
@onready var autoclick_icon: ImageSlot = $AutoclickButton/ImageHolder
@onready var gold_bonus_icon: ImageSlot = $GoldBonusButton/ImageHolder
@onready var focus_burst_icon: ImageSlot = $FocusBurstButton/ImageHolder
@onready var rally_icon: ImageSlot = $RallyButton/ImageHolder
@onready var autoclick_active_radial_overlay: AbilityCooldownOverlay = $AutoclickButton/ActiveRadialOverlay
@onready var gold_bonus_active_radial_overlay: AbilityCooldownOverlay = $GoldBonusButton/ActiveRadialOverlay
@onready var focus_burst_active_radial_overlay: AbilityCooldownOverlay = $FocusBurstButton/ActiveRadialOverlay
@onready var rally_active_radial_overlay: AbilityCooldownOverlay = $RallyButton/ActiveRadialOverlay
@onready var autoclick_cooldown_overlay: AbilityCooldownOverlay = $AutoclickButton/CooldownOverlay
@onready var gold_bonus_cooldown_overlay: AbilityCooldownOverlay = $GoldBonusButton/CooldownOverlay
@onready var focus_burst_cooldown_overlay: AbilityCooldownOverlay = $FocusBurstButton/CooldownOverlay
@onready var rally_cooldown_overlay: AbilityCooldownOverlay = $RallyButton/CooldownOverlay
@onready var autoclick_active_overlay: ImageSlot = $AutoclickButton/ActiveOverlay
@onready var gold_bonus_active_overlay: ImageSlot = $GoldBonusButton/ActiveOverlay
@onready var focus_burst_active_overlay: ImageSlot = $FocusBurstButton/ActiveOverlay
@onready var rally_active_overlay: ImageSlot = $RallyButton/ActiveOverlay
@onready var autoclick_countdown_label: Label = $AutoclickButton/CountdownLabel
@onready var gold_bonus_countdown_label: Label = $GoldBonusButton/CountdownLabel
@onready var focus_burst_countdown_label: Label = $FocusBurstButton/CountdownLabel
@onready var rally_countdown_label: Label = $RallyButton/CountdownLabel


func _ready() -> void:
	autoclick_button.pressed.connect(_on_autoclick_button_pressed)
	gold_bonus_button.pressed.connect(_on_gold_bonus_button_pressed)
	focus_burst_button.pressed.connect(_on_focus_burst_button_pressed)
	rally_button.pressed.connect(_on_rally_button_pressed)

	_clear_button_visual_styles(autoclick_button)
	_clear_button_visual_styles(gold_bonus_button)
	_clear_button_visual_styles(focus_burst_button)
	_clear_button_visual_styles(rally_button)

	autoclick_icon.set_asset_key(GameAssetCatalog.ability_icon_key("autoclick"), Color(0.25, 0.25, 0.25, 0.65))
	gold_bonus_icon.set_asset_key(GameAssetCatalog.ability_icon_key("gold_bonus"), Color(0.25, 0.25, 0.25, 0.65))
	focus_burst_icon.set_asset_key(GameAssetCatalog.ability_icon_key("focus_burst"), Color(0.25, 0.25, 0.25, 0.65))
	rally_icon.set_asset_key(GameAssetCatalog.ability_icon_key("rally"), Color(0.25, 0.25, 0.25, 0.65))

	for overlay: ImageSlot in [autoclick_active_overlay, gold_bonus_active_overlay, focus_burst_active_overlay, rally_active_overlay]:
		overlay.set_asset_key("ability.active_overlay", Color.TRANSPARENT)
		overlay.show_fallback_behind_texture = false
		overlay.visible = false

	for lbl: Label in [autoclick_countdown_label, gold_bonus_countdown_label, focus_burst_countdown_label, rally_countdown_label]:
		_style_countdown_label(lbl)
		lbl.visible = false


func update_view(
	state: ClickerState,
	autoclick_time_left: float,
	gold_bonus_time_left: float,
	autoclick_cooldown_left: float,
	gold_bonus_cooldown_left: float,
	focus_burst_time_left: float,
	rally_time_left: float,
	focus_burst_cooldown_left: float,
	rally_cooldown_left: float,
	autoclick_cooldown_duration: float,
	gold_bonus_cooldown_duration: float,
	focus_burst_cooldown_duration: float,
	rally_cooldown_duration: float,
	autoclick_active_duration: float,
	gold_bonus_active_duration: float,
	focus_burst_active_duration: float,
	rally_active_duration: float
) -> void:
	_update_ability_button(
		autoclick_button, autoclick_icon,
		autoclick_active_radial_overlay, autoclick_cooldown_overlay, autoclick_active_overlay, autoclick_countdown_label,
		state.is_ability_purchased("autoclick"),
		state.autoclick_active, autoclick_time_left, autoclick_active_duration,
		autoclick_cooldown_left, autoclick_cooldown_duration
	)
	_update_ability_button(
		gold_bonus_button, gold_bonus_icon,
		gold_bonus_active_radial_overlay, gold_bonus_cooldown_overlay, gold_bonus_active_overlay, gold_bonus_countdown_label,
		state.is_ability_purchased("gold_bonus"),
		state.gold_bonus_active, gold_bonus_time_left, gold_bonus_active_duration,
		gold_bonus_cooldown_left, gold_bonus_cooldown_duration
	)
	_update_ability_button(
		focus_burst_button, focus_burst_icon,
		focus_burst_active_radial_overlay, focus_burst_cooldown_overlay, focus_burst_active_overlay, focus_burst_countdown_label,
		state.is_ability_purchased("focus_burst"),
		state.focus_burst_active, focus_burst_time_left, focus_burst_active_duration,
		focus_burst_cooldown_left, focus_burst_cooldown_duration
	)
	_update_ability_button(
		rally_button, rally_icon,
		rally_active_radial_overlay, rally_cooldown_overlay, rally_active_overlay, rally_countdown_label,
		state.is_ability_purchased("rally"),
		state.rally_active, rally_time_left, rally_active_duration,
		rally_cooldown_left, rally_cooldown_duration
	)


func _on_autoclick_button_pressed() -> void:
	_release_ability_button_focuses()
	autoclick_requested.emit()


func _on_gold_bonus_button_pressed() -> void:
	_release_ability_button_focuses()
	gold_bonus_requested.emit()


func _on_focus_burst_button_pressed() -> void:
	_release_ability_button_focuses()
	focus_burst_requested.emit()


func _on_rally_button_pressed() -> void:
	_release_ability_button_focuses()
	rally_requested.emit()


func _update_ability_button(
	button: Button,
	icon: ImageSlot,
	active_radial_overlay: AbilityCooldownOverlay,
	cooldown_overlay: AbilityCooldownOverlay,
	active_overlay: ImageSlot,
	countdown_label: Label,
	purchased: bool,
	active: bool,
	active_time_left: float,
	active_duration: float,
	cooldown_left: float,
	cooldown_duration: float
) -> void:
	button.visible = purchased
	button.disabled = not purchased or active or cooldown_left > 0.0
	if not purchased:
		icon.modulate = Color.WHITE
		active_radial_overlay.clear()
		cooldown_overlay.clear()
		active_overlay.visible = false
		countdown_label.visible = false
		return

	if active:
		icon.modulate = Color.WHITE
		var active_ratio: float = clampf(active_time_left / maxf(active_duration, 0.001), 0.0, 1.0)
		active_radial_overlay.set_active_ratio(active_ratio)
		cooldown_overlay.clear()
		active_overlay.visible = true
		countdown_label.visible = true
		countdown_label.text = _format_countdown(active_time_left)
		return

	if cooldown_left > 0.0:
		icon.modulate = Color.WHITE
		active_radial_overlay.clear()
		var cooldown_ratio: float = clampf(cooldown_left / maxf(cooldown_duration, 0.001), 0.0, 1.0)
		cooldown_overlay.set_cooldown_ratio(cooldown_ratio)
		active_overlay.visible = false
		countdown_label.visible = true
		countdown_label.text = _format_countdown(cooldown_left)
		return

	icon.modulate = Color.WHITE
	active_radial_overlay.clear()
	cooldown_overlay.clear()
	active_overlay.visible = false
	countdown_label.visible = false


func _clear_button_visual_styles(button: Button) -> void:
	var empty_style := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty_style)
	button.add_theme_stylebox_override("hover", empty_style)
	button.add_theme_stylebox_override("pressed", empty_style)
	button.add_theme_stylebox_override("disabled", empty_style)
	button.add_theme_stylebox_override("focus", empty_style)
	button.focus_mode = Control.FOCUS_NONE


func _release_ability_button_focuses() -> void:
	autoclick_button.release_focus()
	gold_bonus_button.release_focus()
	focus_burst_button.release_focus()
	rally_button.release_focus()


func _format_countdown(seconds_left: float) -> String:
	return str(ceili(maxf(seconds_left, 0.0)))


func _style_countdown_label(label: Label) -> void:
	UiFontConfig.apply_label_font_size(label, UiFontConfig.ABILITY_BAR_COUNTDOWN_FONT_SIZE)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
