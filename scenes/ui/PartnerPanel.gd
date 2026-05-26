class_name PartnerPanel
extends VBoxContainer

signal partner_purchase_requested(partner_index: int, mode: String)

const BUY_MODES: Array[String] = ["x1", "x10", "x100", "max"]

@onready var total_dps_label: Label = $TotalDpsLabel
@onready var buy_mode_option: OptionButton = $BuyModeRow/BuyModeOption
@onready var partner_1_label: Label = $Partner1Row/Partner1Label
@onready var partner_1_button: Button = $Partner1Row/Partner1Button
@onready var partner_2_label: Label = $Partner2Row/Partner2Label
@onready var partner_2_button: Button = $Partner2Row/Partner2Button
@onready var partner_3_label: Label = $Partner3Row/Partner3Label
@onready var partner_3_button: Button = $Partner3Row/Partner3Button


func _ready() -> void:
	_setup_buy_mode_option()
	partner_1_button.pressed.connect(func() -> void: partner_purchase_requested.emit(0, _get_buy_mode()))
	partner_2_button.pressed.connect(func() -> void: partner_purchase_requested.emit(1, _get_buy_mode()))
	partner_3_button.pressed.connect(func() -> void: partner_purchase_requested.emit(2, _get_buy_mode()))


func update_view(state: ClickerState) -> void:
	total_dps_label.text = "Total DPS: %d" % state.get_total_partner_dps()
	partner_1_label.text = "Partner 1: %d | DPS %d" % [state.partner_counts[0], state.partner_dps_values[0]]
	partner_2_label.text = "Partner 2: %d | DPS %d" % [state.partner_counts[1], state.partner_dps_values[1]]
	partner_3_label.text = "Partner 3: %d | DPS %d" % [state.partner_counts[2], state.partner_dps_values[2]]

	partner_1_button.disabled = false
	partner_1_button.text = "Hire Partner 1 - Cost: %d" % state.partner_purchase_costs[0]

	partner_2_button.disabled = not state.can_buy_partner(1)
	partner_2_button.text = "Requires Partner 1" if partner_2_button.disabled else "Hire Partner 2 - Cost: %d" % state.partner_purchase_costs[1]

	partner_3_button.disabled = not state.can_buy_partner(2)
	partner_3_button.text = "Requires Partner 2" if partner_3_button.disabled else "Hire Partner 3 - Cost: %d" % state.partner_purchase_costs[2]


func _setup_buy_mode_option() -> void:
	if buy_mode_option.get_item_count() > 0:
		return

	buy_mode_option.add_item("x1")
	buy_mode_option.add_item("x10")
	buy_mode_option.add_item("x100")
	buy_mode_option.add_item("Max")
	buy_mode_option.select(0)


func _get_buy_mode() -> String:
	var selected: int = buy_mode_option.selected
	if selected < 0 or selected >= BUY_MODES.size():
		return "x1"

	return BUY_MODES[selected]
