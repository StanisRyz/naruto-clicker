class_name TasksWindow
extends Control

signal task_claim_requested(task_id: String)

const ImageSlotClass = preload("res://scripts/ui/ImageSlot.gd")

@onready var outside_click_area: Control = $OutsideClickArea
@onready var panel_container: PanelContainer = $PanelContainer
@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/Header/CloseButton
@onready var tasks_container: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/TasksContainer

var pending_state: ClickerState = null
var rebuild_queued: bool = false
var task_rows_by_id: Dictionary = {}


func _ready() -> void:
	outside_click_area.gui_input.connect(_on_outside_click_area_gui_input)
	panel_container.gui_input.connect(_on_panel_container_gui_input)
	close_button.pressed.connect(hide_window)
	hide()


func show_window(state: ClickerState) -> void:
	_rebuild_rows(state)
	show()


func hide_window() -> void:
	hide()


func request_full_rebuild(state: ClickerState) -> void:
	pending_state = state
	if rebuild_queued:
		return

	rebuild_queued = true
	call_deferred("_rebuild_rows_deferred")


func refresh_progress_only(state: ClickerState) -> void:
	var active_task_data: Array = state.get_active_task_view_data()
	if active_task_data.size() != task_rows_by_id.size():
		return

	for task_data: Dictionary in active_task_data:
		var task_id: String = String(task_data.get("id", ""))
		if not task_rows_by_id.has(task_id):
			return

	for task_data: Dictionary in active_task_data:
		var task_id: String = String(task_data.get("id", ""))
		var row_data: Dictionary = task_rows_by_id[task_id]
		var title_label: Label = row_data["title_label"]
		var progress_label: Label = row_data["progress_label"]
		var claim_button: Button = row_data["claim_button"]
		var completed: bool = bool(task_data.get("completed", false))

		title_label.text = _get_task_title(task_data)
		progress_label.text = _format_progress_text(task_data)

		if claim_button.text == LocalizationManager.tr_key("task.claimed"):
			continue

		if completed == bool(row_data.get("completed", false)):
			continue

		row_data["completed"] = completed
		if completed:
			claim_button.disabled = false
			claim_button.text = LocalizationManager.tr_key("task.claim")
		else:
			claim_button.disabled = true
			claim_button.text = LocalizationManager.tr_key("task.in_progress")


func update_view(state: ClickerState) -> void:
	_rebuild_rows(state)


func _rebuild_rows(state: ClickerState) -> void:
	_clear_task_rows()

	for task_data: Dictionary in state.get_active_task_view_data():
		tasks_container.add_child(_create_task_row(task_data))


func _rebuild_rows_deferred() -> void:
	await get_tree().process_frame
	if pending_state != null:
		_rebuild_rows(pending_state)

	pending_state = null
	rebuild_queued = false


func _clear_task_rows() -> void:
	task_rows_by_id.clear()
	for child in tasks_container.get_children():
		tasks_container.remove_child(child)
		child.queue_free()


func _get_task_title(task_data: Dictionary) -> String:
	var task_id: String = String(task_data.get("id", ""))
	var task_config: Dictionary = TaskConfig.get_by_id(task_id)
	var title_key: String = String(task_config.get("title_key", ""))
	if title_key != "":
		return LocalizationManager.tr_key(title_key)
	return String(task_data.get("title", ""))


func _create_task_row(task_data: Dictionary) -> PanelContainer:
	var row := PanelContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.gui_input.connect(_on_panel_container_gui_input)
	row.add_theme_stylebox_override("panel", _create_row_stylebox())

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	row.add_child(margin)

	var content := HBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)

	var task_id: String = String(task_data.get("id", ""))

	var image_holder = ImageSlotClass.new()
	image_holder.name = "ImageHolder"
	image_holder.fallback_color = Color.WHITE
	image_holder.custom_minimum_size = Vector2(56, 56)
	image_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(image_holder)
	image_holder.set_asset_key(GameAssetCatalog.task_icon_key(task_id))

	var info_container := VBoxContainer.new()
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_container.add_theme_constant_override("separation", 4)
	content.add_child(info_container)

	var title_label := Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.text = _get_task_title(task_data)
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	info_container.add_child(title_label)

	var progress_label := Label.new()
	progress_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	progress_label.text = _format_progress_text(task_data)
	info_container.add_child(progress_label)

	var claim_button := Button.new()
	claim_button.custom_minimum_size = Vector2(160, 56)
	if bool(task_data.get("completed", false)):
		claim_button.disabled = false
		claim_button.text = LocalizationManager.tr_key("task.claim")
	else:
		claim_button.disabled = true
		claim_button.text = LocalizationManager.tr_key("task.in_progress")
	claim_button.pressed.connect(func() -> void:
		claim_button.disabled = true
		claim_button.text = LocalizationManager.tr_key("task.claimed")
		task_claim_requested.emit(task_id)
	)
	content.add_child(claim_button)

	task_rows_by_id[task_id] = {
		"row": row,
		"title_label": title_label,
		"progress_label": progress_label,
		"claim_button": claim_button,
		"completed": bool(task_data.get("completed", false)),
	}

	return row


func _format_progress_text(task_data: Dictionary) -> String:
	return LocalizationManager.format_key("task.progress", {
		"current": int(task_data.get("progress", 0)),
		"target": int(task_data.get("target", 0)),
		"reward": NumberFormatter.compact(int(task_data.get("reward_gold", 0))),
	})


func _on_outside_click_area_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			accept_event()
			hide_window()
	elif event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
		if touch_event.pressed:
			accept_event()
			hide_window()


func _on_panel_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		accept_event()
	elif event is InputEventScreenTouch:
		accept_event()


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
