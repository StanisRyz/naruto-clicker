class_name PartnerPanel
extends VBoxContainer

signal partner_purchase_requested(partner_index: int, mode: String)

const BUY_MODES: Array[String] = ["x1", "x10", "x100", "max"]

var selected_buy_mode: String = "x1"
var current_state: ClickerState = null

@onready var total_dps_label: Label = $TotalDpsLabel
@onready var buy_mode_buttons: Array[Button] = [
	$BuyModeRow/X1Button,
	$BuyModeRow/X10Button,
	$BuyModeRow/X100Button,
	$BuyModeRow/MaxButton,
]
@onready var partner_1_label: Label = $Partner1Row/Partner1Label
@onready var partner_1_button: Button = $Partner1Row/Partner1Button
@onready var partner_2_label: Label = $Partner2Row/Partner2Label
@onready var partner_2_button: Button = $Partner2Row/Partner2Button
@onready var partner_3_label: Label = $Partner3Row/Partner3Label
@onready var partner_3_button: Button = $Partner3Row/Partner3Button


func _ready() -> void:
	buy_mode_buttons[0].pressed.connect(func() -> void: _select_buy_mode("x1"))
	buy_mode_buttons[1].pressed.connect(func() -> void: _select_buy_mode("x10"))
	buy_mode_buttons[2].pressed.connect(func() -> void: _select_buy_mode("x100"))
	buy_mode_buttons[3].pressed.connect(func() -> void: _select_buy_mode("max"))
	partner_1_button.pressed.connect(func() -> void: partner_purchase_requested.emit(0, selected_buy_mode))
	partner_2_button.pressed.connect(func() -> void: partner_purchase_requested.emit(1, selected_buy_mode))
	partner_3_button.pressed.connect(func() -> void: partner_purchase_requested.emit(2, selected_buy_mode))
	_update_buy_mode_buttons()


func update_view(state: ClickerState) -> void:
	current_state = state
	_update_buy_mode_buttons()
	total_dps_label.text = "Total DPS: %d" % state.get_total_partner_dps()
	partner_1_label.text = "Partner 1: %d | DPS %d" % [state.partner_counts[0], state.partner_dps_values[0]]
	partner_2_label.text = "Partner 2: %d | DPS %d" % [state.partner_counts[1], state.partner_dps_values[1]]
	partner_3_label.text = "Partner 3: %d | DPS %d" % [state.partner_counts[2], state.partner_dps_values[2]]

	_update_partner_button(state, 0, partner_1_button)
	_update_partner_button(state, 1, partner_2_button)
	_update_partner_button(state, 2, partner_3_button)


func _update_partner_button(state: ClickerState, partner_index: int, button: Button) -> void:
	var label_index: int = partner_index + 1
	if not state.can_buy_partner(partner_index):
		button.disabled = true
		button.text = "Hire Partner %d x0 - Requires Partner %d" % [label_index, partner_index]
		return

	var bulk_count: int = state.get_partner_bulk_count(partner_index, selected_buy_mode)
	var bulk_cost: int = state.get_partner_bulk_cost(partner_index, selected_buy_mode)
	button.disabled = false
	if bulk_count <= 0:
		button.text = "Hire Partner %d x0 - Not enough gold" % label_index
	else:
		button.text = "Hire Partner %d x%d - Cost: %d" % [label_index, bulk_count, bulk_cost]


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
