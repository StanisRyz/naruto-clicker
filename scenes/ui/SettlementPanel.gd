class_name SettlementPanel
extends VBoxContainer

signal building_purchase_requested(building_index: int, mode: String)

const BUY_MODES: Array[String] = ["x1", "x10", "x100", "max"]
const BUILDING_IMAGE_SIZE: Vector2 = Vector2(136, 136)
const BUILDING_BUTTON_SIZE: Vector2 = Vector2(210, 136)
const CARD_ROW_LABEL_COUNT: int = 5

const ImageSlotClass = preload("res://scripts/ui/ImageSlot.gd")

var selected_buy_mode: String = "x1"
var current_state: ClickerState = null
var building_rows: Array[Dictionary] = []

@onready var rows_container: VBoxContainer = $RowsContainer


func update_view(state: ClickerState) -> void:
	current_state = state
	_ensure_building_rows(state)

	for building_index in range(building_rows.size()):
		var panel_row: PanelContainer = building_rows[building_index]["row"]
		panel_row.visible = _should_show_building_row(state, building_index)
		_update_building_row(state, building_index, building_rows[building_index])


func _ensure_building_rows(_state: ClickerState) -> void:
	while building_rows.size() < SettlementConfig.BUILDING_NAMES.size():
		var building_index: int = building_rows.size()
		building_rows.append(_create_building_row(building_index))


func _create_building_row(building_index: int) -> Dictionary:
	var row := PanelContainer.new()
	row.name = "Building%dRow" % (building_index + 1)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_stylebox_override("panel", _create_row_stylebox())
	rows_container.add_child(row)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	row.add_child(margin)

	var content := HBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)

	var image_holder = ImageSlotClass.new()
	image_holder.name = "ImageHolder"
	image_holder.fallback_color = Color.WHITE
	image_holder.show_fallback_behind_texture = false
	image_holder.custom_minimum_size = BUILDING_IMAGE_SIZE
	content.add_child(image_holder)
	image_holder.set_asset_key(GameAssetCatalog.building_icon_key(building_index))

	var right_content := VBoxContainer.new()
	right_content.name = "RightContent"
	right_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_content.add_theme_constant_override("separation", 4)
	content.add_child(right_content)

	var building_name_label := Label.new()
	building_name_label.name = "BuildingNameLabel"
	building_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	building_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	UiFontConfig.apply_label_font_size(building_name_label, UiFontConfig.SETTLEMENT_NAME_FONT_SIZE)
	right_content.add_child(building_name_label)

	var building_count_label := Label.new()
	building_count_label.name = "BuildingCountLabel"
	building_count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiFontConfig.apply_label_font_size(building_count_label, UiFontConfig.SETTLEMENT_COUNT_FONT_SIZE)
	right_content.add_child(building_count_label)

	var purchase_bonus_gain_label := Label.new()
	purchase_bonus_gain_label.name = "PurchaseBonusGainLabel"
	purchase_bonus_gain_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiFontConfig.apply_label_font_size(purchase_bonus_gain_label, UiFontConfig.SETTLEMENT_PURCHASE_GAIN_FONT_SIZE)
	right_content.add_child(purchase_bonus_gain_label)

	var total_bonus_label := Label.new()
	total_bonus_label.name = "TotalBonusLabel"
	total_bonus_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiFontConfig.apply_label_font_size(total_bonus_label, UiFontConfig.SETTLEMENT_TOTAL_BONUS_FONT_SIZE)
	right_content.add_child(total_bonus_label)

	var milestone_label := Label.new()
	milestone_label.name = "MilestoneLabel"
	milestone_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiFontConfig.apply_label_font_size(milestone_label, UiFontConfig.SETTLEMENT_MILESTONE_FONT_SIZE)
	right_content.add_child(milestone_label)

	var button := Button.new()
	button.name = "BuyButton"
	button.custom_minimum_size = BUILDING_BUTTON_SIZE
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(func() -> void: building_purchase_requested.emit(building_index, selected_buy_mode))
	ButtonVisualUtils.disable_focus_artifact(button)
	UiFontConfig.apply_button_font_size(button, UiFontConfig.SETTLEMENT_BUTTON_FONT_SIZE)
	content.add_child(button)

	return {
		"row": row,
		"building_name_label": building_name_label,
		"building_count_label": building_count_label,
		"purchase_bonus_gain_label": purchase_bonus_gain_label,
		"total_bonus_label": total_bonus_label,
		"milestone_label": milestone_label,
		"button": button,
	}


func _update_building_row(state: ClickerState, building_index: int, row: Dictionary) -> void:
	var building_name_label: Label = row["building_name_label"]
	var building_count_label: Label = row["building_count_label"]
	var purchase_bonus_gain_label: Label = row["purchase_bonus_gain_label"]
	var total_bonus_label: Label = row["total_bonus_label"]
	var milestone_label: Label = row["milestone_label"]
	var button: Button = row["button"]

	var building_name: String = LocalizationManager.tr_key(SettlementConfig.get_name_key(building_index))
	var owned_count: int = state.building_counts[building_index]

	building_name_label.text = LocalizationManager.format_key("settlement.card.name", {"name": building_name})

	building_count_label.text = LocalizationManager.format_key("settlement.card.count", {"count": owned_count})

	purchase_bonus_gain_label.text = ClickerStatePresentation.get_building_purchase_bonus_gain_text(state, building_index, selected_buy_mode)

	total_bonus_label.text = ClickerStatePresentation.get_building_total_bonus_text(state, building_index)

	var next_milestone: int = state.get_next_milestone(owned_count)
	if next_milestone > 0:
		milestone_label.text = LocalizationManager.format_key("settlement.card.milestone_next", {"milestone": next_milestone})
	else:
		milestone_label.text = LocalizationManager.tr_key("settlement.card.milestone_max")

	var bulk_count: int = state.get_building_bulk_display_count(building_index, selected_buy_mode)
	var bulk_cost: int = state.get_building_bulk_display_cost(building_index, selected_buy_mode)
	button.disabled = not state.can_afford_building_bulk(building_index, selected_buy_mode)
	button.text = LocalizationManager.format_key("settlement.build_button", {
		"count": bulk_count,
		"cost": NumberFormatter.compact(bulk_cost),
	})


func set_buy_mode(mode: String) -> void:
	if not BUY_MODES.has(mode):
		return
	selected_buy_mode = mode


func _should_show_building_row(_state: ClickerState, building_index: int) -> bool:
	return building_index >= 0 and building_index < SettlementConfig.BUILDING_NAMES.size()


func _create_row_stylebox() -> StyleBoxFlat:
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = Color(0.12, 0.125, 0.145, 1.0)
	stylebox.border_width_left = 1
	stylebox.border_width_top = 1
	stylebox.border_width_right = 1
	stylebox.border_width_bottom = 1
	stylebox.border_color = Color(0.22, 0.23, 0.26, 1.0)
	stylebox.corner_radius_top_left = 6
	stylebox.corner_radius_top_right = 6
	stylebox.corner_radius_bottom_left = 6
	stylebox.corner_radius_bottom_right = 6
	return stylebox
