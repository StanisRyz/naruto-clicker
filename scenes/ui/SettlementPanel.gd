class_name SettlementPanel
extends VBoxContainer

signal building_purchase_requested(building_index: int, mode: String)

const BUY_MODES: Array[String] = ["x1", "x10", "x100", "max"]

var selected_buy_mode: String = "x1"
var current_state: ClickerState = null

@onready var bonuses_label: Label = $BonusesLabel
@onready var buy_mode_buttons: Array[Button] = [
	$BuyModeRow/X1Button,
	$BuyModeRow/X10Button,
	$BuyModeRow/X100Button,
	$BuyModeRow/MaxButton,
]
@onready var building_1_label: Label = $Building1Row/Building1Label
@onready var building_1_button: Button = $Building1Row/Building1Button
@onready var building_2_label: Label = $Building2Row/Building2Label
@onready var building_2_button: Button = $Building2Row/Building2Button
@onready var building_3_label: Label = $Building3Row/Building3Label
@onready var building_3_button: Button = $Building3Row/Building3Button


func _ready() -> void:
	buy_mode_buttons[0].pressed.connect(func() -> void: _select_buy_mode("x1"))
	buy_mode_buttons[1].pressed.connect(func() -> void: _select_buy_mode("x10"))
	buy_mode_buttons[2].pressed.connect(func() -> void: _select_buy_mode("x100"))
	buy_mode_buttons[3].pressed.connect(func() -> void: _select_buy_mode("max"))
	building_1_button.pressed.connect(func() -> void: building_purchase_requested.emit(0, selected_buy_mode))
	building_2_button.pressed.connect(func() -> void: building_purchase_requested.emit(1, selected_buy_mode))
	building_3_button.pressed.connect(func() -> void: building_purchase_requested.emit(2, selected_buy_mode))
	_update_buy_mode_buttons()


func update_view(state: ClickerState) -> void:
	current_state = state
	_update_buy_mode_buttons()
	bonuses_label.text = "DPS +%d%% | Gold +%d%% | Click +%d%%" % [
		state.get_settlement_partner_dps_bonus_percent(),
		state.get_settlement_gold_bonus_percent(),
		state.get_settlement_click_damage_bonus_percent(),
	]
	_update_building_row(state, 0, building_1_label, building_1_button)
	_update_building_row(state, 1, building_2_label, building_2_button)
	_update_building_row(state, 2, building_3_label, building_3_button)


func _update_building_row(state: ClickerState, building_index: int, label: Label, button: Button) -> void:
	var building_name: String = state.building_names[building_index]
	var owned_count: int = state.building_counts[building_index]
	var total_bonus: int = owned_count * state.building_bonus_percent_per_level
	label.text = "%s: %d | +%d%% each | +%d%% total" % [
		building_name,
		owned_count,
		state.building_bonus_percent_per_level,
		total_bonus,
	]

	if not state.can_buy_building(building_index):
		button.disabled = true
		button.text = "Requires %s" % state.building_names[building_index - 1]
		return

	var bulk_count: int = state.get_building_bulk_display_count(building_index, selected_buy_mode)
	var bulk_cost: int = state.get_building_bulk_display_cost(building_index, selected_buy_mode)
	button.disabled = false
	button.text = "Build %s x%d - Cost: %d" % [building_name, bulk_count, bulk_cost]


func _select_buy_mode(mode: String) -> void:
	selected_buy_mode = mode
	_update_buy_mode_buttons()
	if current_state != null:
		update_view(current_state)


func _update_buy_mode_buttons() -> void:
	for i in range(buy_mode_buttons.size()):
		var mode: String = BUY_MODES[i]
		var button: Button = buy_mode_buttons[i]
		button.disabled = mode == selected_buy_mode
		button.text = _get_buy_mode_label(mode, button.disabled)


func _get_buy_mode_label(mode: String, selected: bool) -> String:
	var label: String = "Max" if mode == "max" else mode
	return "[%s]" % label if selected else label
