class_name ShopPanel
extends VBoxContainer

signal product_purchase_requested(product_id: String)
signal test_gems_requested

var product_rows: Dictionary = {}

@onready var gems_label: Label = $GemsLabel
@onready var tokens_label: Label = $TokensLabel
@onready var boost_label: Label = $BoostLabel
@onready var test_gems_button: Button = $TestGemsButton
@onready var products_container: VBoxContainer = $ProductsContainer


func _ready() -> void:
	test_gems_button.pressed.connect(func() -> void: test_gems_requested.emit())


func update_view(state: ClickerState) -> void:
	gems_label.text = "Gems: %d" % state.gems
	tokens_label.text = "Boss Retry Tokens: %d" % state.boss_retry_tokens
	if state.task_reward_boost_multiplier > 1.0:
		boost_label.text = "Task Reward Boost: x%.1f active" % state.task_reward_boost_multiplier
	else:
		boost_label.text = "Task Reward Boost: inactive"
	_ensure_product_rows(state)

	for product_data: Dictionary in state.get_shop_product_view_data():
		var product_id: String = String(product_data.get("id", ""))
		if product_rows.has(product_id):
			_update_product_row(product_data, product_rows[product_id])


func _ensure_product_rows(state: ClickerState) -> void:
	for product_data: Dictionary in state.get_shop_product_view_data():
		var product_id: String = String(product_data.get("id", ""))
		if product_id != "" and not product_rows.has(product_id):
			product_rows[product_id] = _create_product_row(product_id)


func _create_product_row(product_id: String) -> Dictionary:
	var row := PanelContainer.new()
	row.name = "%sRow" % product_id
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_stylebox_override("panel", _create_row_stylebox())
	products_container.add_child(row)

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

	var image_holder := ColorRect.new()
	image_holder.name = "ImageHolder"
	image_holder.color = Color.WHITE
	image_holder.custom_minimum_size = Vector2(72, 72)
	content.add_child(image_holder)

	var info_container := VBoxContainer.new()
	info_container.name = "InfoContainer"
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_container.add_theme_constant_override("separation", 4)
	content.add_child(info_container)

	var name_cost_label := Label.new()
	name_cost_label.name = "NameCostLabel"
	name_cost_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_cost_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	info_container.add_child(name_cost_label)

	var description_label := Label.new()
	description_label.name = "DescriptionLabel"
	description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_container.add_child(description_label)

	var button := Button.new()
	button.name = "BuyButton"
	button.custom_minimum_size = Vector2(140, 64)
	button.text = "Buy"
	button.pressed.connect(func() -> void: product_purchase_requested.emit(product_id))
	content.add_child(button)

	return {
		"name_cost_label": name_cost_label,
		"description_label": description_label,
		"button": button,
	}


func _update_product_row(product_data: Dictionary, row: Dictionary) -> void:
	var name_cost_label: Label = row["name_cost_label"]
	var description_label: Label = row["description_label"]
	var button: Button = row["button"]
	var cost_gems: int = int(product_data.get("cost_gems", 0))

	name_cost_label.text = "%s | %d Gems" % [String(product_data.get("name", "")), cost_gems]
	description_label.text = String(product_data.get("description", ""))
	button.disabled = not bool(product_data.get("can_buy", false))
	button.text = "Buy"


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
