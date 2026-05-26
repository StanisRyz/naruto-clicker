class_name SettlementPanel
extends VBoxContainer

signal building_purchase_requested(building_index: int, mode: String)

const BUY_MODES: Array[String] = ["x1", "x10", "x100", "max"]

var selected_buy_mode: String = "x1"
var current_state: ClickerState = null
var building_rows: Array[Dictionary] = []

@onready var bonuses_label: Label = $BonusesLabel
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
	_ensure_building_rows(state)
	_update_buy_mode_buttons()
	bonuses_label.text = "DPS +%d%% | Gold +%d%% | Click +%d%% | Dur +%d%% | CD -%d%% | Boss Gold +%d%%" % [
		state.get_settlement_partner_dps_bonus_percent(),
		state.get_settlement_gold_bonus_percent(),
		state.get_settlement_click_damage_bonus_percent(),
		state.get_settlement_ability_duration_bonus_percent(),
		state.get_settlement_cooldown_reduction_percent(),
		state.get_settlement_boss_gold_bonus_percent(),
	]

	for building_index in range(building_rows.size()):
		_update_building_row(state, building_index, building_rows[building_index])


func _ensure_building_rows(state: ClickerState) -> void:
	while building_rows.size() < state.building_names.size():
		var building_index: int = building_rows.size()
		building_rows.append(_create_building_row(building_index))


func _create_building_row(building_index: int) -> Dictionary:
	var row := HBoxContainer.new()
	row.name = "Building%dRow" % (building_index + 1)
	row.add_theme_constant_override("separation", 12)
	rows_container.add_child(row)

	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(label)

	var button := Button.new()
	button.custom_minimum_size = Vector2(330, 58)
	button.pressed.connect(func() -> void: building_purchase_requested.emit(building_index, selected_buy_mode))
	row.add_child(button)

	return {"label": label, "button": button}


func _update_building_row(state: ClickerState, building_index: int, row: Dictionary) -> void:
	var label: Label = row["label"]
	var button: Button = row["button"]
	var building_name: String = state.building_names[building_index]
	var owned_count: int = state.building_counts[building_index]
	var total_bonus: int = state.get_building_bonus_percent(building_index)
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
