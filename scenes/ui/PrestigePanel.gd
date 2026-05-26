class_name PrestigePanel
extends VBoxContainer

signal prestige_requested
signal prestige_talent_purchase_requested(talent_index: int)

var talent_rows: Array[Dictionary] = []

@onready var available_points_label: Label = $InfoGrid/AvailablePointsLabel
@onready var total_points_earned_label: Label = $InfoGrid/TotalPointsEarnedLabel
@onready var prestige_button: Button = $PrestigeButton
@onready var talents_container: VBoxContainer = $TalentsContainer


func _ready() -> void:
	prestige_button.pressed.connect(_on_prestige_button_pressed)


func update_view(state: ClickerState) -> void:
	_ensure_talent_rows(state)
	var total_reward: int = state.get_prestige_reward()

	available_points_label.text = "Available Points: %d" % state.prestige_points_available
	total_points_earned_label.text = "Total Earned: %d" % state.prestige_points_total_earned

	prestige_button.disabled = total_reward <= 0
	prestige_button.text = "Prestige - Gain %d Points" % total_reward

	for talent_index in range(talent_rows.size()):
		_update_talent_row(state, talent_index, talent_rows[talent_index])


func _ensure_talent_rows(state: ClickerState) -> void:
	while talent_rows.size() < state.prestige_talent_names.size():
		var talent_index: int = talent_rows.size()
		talent_rows.append(_create_talent_row(talent_index))


func _create_talent_row(talent_index: int) -> Dictionary:
	var row := HBoxContainer.new()
	row.name = "Talent%dRow" % (talent_index + 1)
	row.add_theme_constant_override("separation", 12)
	talents_container.add_child(row)

	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(label)

	var button := Button.new()
	button.custom_minimum_size = Vector2(180, 56)
	button.pressed.connect(func() -> void: prestige_talent_purchase_requested.emit(talent_index))
	row.add_child(button)

	return {"label": label, "button": button}


func _on_prestige_button_pressed() -> void:
	prestige_requested.emit()


func _update_talent_row(state: ClickerState, talent_index: int, row: Dictionary) -> void:
	var label: Label = row["label"]
	var button: Button = row["button"]
	var level: int = state.prestige_talent_levels[talent_index]
	var total_bonus: int = level * state.prestige_talent_bonus_percent_per_level
	var cost: int = state.get_prestige_talent_cost(talent_index)
	label.text = "%s: Lv %d | +%d%% each | +%d%% total" % [
		state.prestige_talent_names[talent_index],
		level,
		state.prestige_talent_bonus_percent_per_level,
		total_bonus,
	]
	button.disabled = state.prestige_points_available < cost
	button.text = "Upgrade - Cost: %d" % cost
