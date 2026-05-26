class_name PartnerPanel
extends VBoxContainer

signal partner_purchase_requested(partner_index: int, mode: String)

const BUY_MODES: Array[String] = ["x1", "x10", "x100", "max"]

var selected_buy_mode: String = "x1"
var current_state: ClickerState = null
var partner_rows: Array[Dictionary] = []

@onready var total_dps_label: Label = $TotalDpsLabel
@onready var buy_mode_buttons: Array[Button] = [
	$BuyModeRow/X1Button,
	$BuyModeRow/X10Button,
	$BuyModeRow/X100Button,
	$BuyModeRow/MaxButton,
]
@onready var rows_container: VBoxContainer = $RowsContainer


func _ready() -> void:
	buy_mode_buttons[0].pressed.connect(func() -> void: _select_buy_mode("x1"))
	buy_mode_buttons[1].pressed.connect(func() -> void: _select_buy_mode("x10"))
	buy_mode_buttons[2].pressed.connect(func() -> void: _select_buy_mode("x100"))
	buy_mode_buttons[3].pressed.connect(func() -> void: _select_buy_mode("max"))
	_update_buy_mode_buttons()


func update_view(state: ClickerState) -> void:
	current_state = state
	_ensure_partner_rows(state)
	_update_buy_mode_buttons()
	total_dps_label.text = "Total DPS: %d" % state.get_total_partner_dps()

	for partner_index in range(partner_rows.size()):
		_update_partner_row(state, partner_index, partner_rows[partner_index])


func _ensure_partner_rows(state: ClickerState) -> void:
	while partner_rows.size() < state.partner_names.size():
		var partner_index: int = partner_rows.size()
		partner_rows.append(_create_partner_row(partner_index))


func _create_partner_row(partner_index: int) -> Dictionary:
	var row := HBoxContainer.new()
	row.name = "Partner%dRow" % (partner_index + 1)
	row.add_theme_constant_override("separation", 12)
	rows_container.add_child(row)

	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(label)

	var button := Button.new()
	button.custom_minimum_size = Vector2(360, 58)
	button.pressed.connect(func() -> void: partner_purchase_requested.emit(partner_index, selected_buy_mode))
	row.add_child(button)

	return {"label": label, "button": button}


func _update_partner_row(state: ClickerState, partner_index: int, row: Dictionary) -> void:
	var label: Label = row["label"]
	var button: Button = row["button"]
	var partner_name: String = state.partner_names[partner_index]
	label.text = "%s: %d | DPS %d" % [
		partner_name,
		state.partner_counts[partner_index],
		state.partner_dps_values[partner_index],
	]

	if not state.can_buy_partner(partner_index):
		button.disabled = true
		button.text = "Requires %s" % state.partner_names[partner_index - 1]
		return

	var bulk_count: int = state.get_partner_bulk_display_count(partner_index, selected_buy_mode)
	var bulk_cost: int = state.get_partner_bulk_display_cost(partner_index, selected_buy_mode)
	button.disabled = false
	button.text = "Hire %s x%d - Cost: %d" % [partner_name, bulk_count, bulk_cost]


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
