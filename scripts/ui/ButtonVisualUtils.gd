class_name ButtonVisualUtils
extends RefCounted

const ImageSlotClass = preload("res://scripts/ui/ImageSlot.gd")


static func setup_image_button(
		button: Button,
		image_asset_key: String,
		fallback_color: Color) -> Dictionary:
	if button == null:
		return {}
	clear_image_button_styles(button)
	button.text = ""
	var existing_image = button.find_child("ButtonImageHolder", false, false)
	var image_holder: ImageSlotClass
	if existing_image != null:
		image_holder = existing_image
	else:
		image_holder = ImageSlotClass.new()
		image_holder.name = "ButtonImageHolder"
		image_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		image_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(image_holder)
	image_holder.fallback_color = fallback_color
	image_holder.show_fallback_behind_texture = false
	image_holder.stretch_mode = TextureRect.STRETCH_SCALE
	image_holder.set_asset_key(image_asset_key, fallback_color)
	var existing_label = button.find_child("ButtonTextLabel", false, false)
	if existing_label != null:
		existing_label.visible = false
		existing_label.text = ""
	return {"image_holder": image_holder}


static func setup_image_text_button(
		button: Button,
		image_asset_key: String,
		fallback_color: Color,
		text_value: String) -> Dictionary:
	if button == null:
		return {}
	clear_image_button_styles(button)
	button.text = ""
	var existing_image = button.find_child("ButtonImageHolder", false, false)
	var image_holder: ImageSlotClass
	if existing_image != null:
		image_holder = existing_image
	else:
		image_holder = ImageSlotClass.new()
		image_holder.name = "ButtonImageHolder"
		image_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		image_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(image_holder)
	image_holder.fallback_color = fallback_color
	image_holder.show_fallback_behind_texture = false
	image_holder.stretch_mode = TextureRect.STRETCH_SCALE
	image_holder.set_asset_key(image_asset_key, fallback_color)
	var existing_label = button.find_child("ButtonTextLabel", false, false)
	var text_label: Label
	if existing_label != null:
		text_label = existing_label
	else:
		text_label = Label.new()
		text_label.name = "ButtonTextLabel"
		text_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		text_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.add_child(text_label)
	text_label.text = text_value
	return {"image_holder": image_holder, "text_label": text_label}


static func disable_focus_artifact(button: Button) -> void:
	if button == null:
		return
	var empty_focus := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("focus", empty_focus)
	button.focus_mode = Control.FOCUS_NONE


static func clear_text_button_background(button: Button) -> void:
	if button == null:
		return
	var empty_style := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty_style)
	button.add_theme_stylebox_override("hover", empty_style)
	button.add_theme_stylebox_override("pressed", empty_style)
	button.add_theme_stylebox_override("disabled", empty_style)
	button.add_theme_stylebox_override("focus", empty_style)
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE


static func clear_image_button_styles(button: Button) -> void:
	if button == null:
		return
	var empty_style := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty_style)
	button.add_theme_stylebox_override("hover", empty_style)
	button.add_theme_stylebox_override("pressed", empty_style)
	button.add_theme_stylebox_override("disabled", empty_style)
	button.add_theme_stylebox_override("focus", empty_style)
	button.focus_mode = Control.FOCUS_NONE
	button.flat = true


static func release_button_focus(button: Button) -> void:
	if button != null:
		button.release_focus()


static func flash_button_image_holder(
		image_holder,
		normal_asset_key: String,
		pressed_asset_key: String = "ui.popup.button.pressed",
		duration_sec: float = 0.2) -> void:
	if image_holder == null:
		return
	image_holder.set_asset_key(pressed_asset_key, Color.WHITE)
	await image_holder.get_tree().create_timer(duration_sec).timeout
	if is_instance_valid(image_holder):
		image_holder.set_asset_key(normal_asset_key, Color.WHITE)


static func set_button_pressed_visual(image_holder, pressed: bool, normal_asset_key: String) -> void:
	if image_holder == null:
		return
	var key: String = "ui.popup.button.pressed" if pressed else normal_asset_key
	image_holder.set_asset_key(key, Color.WHITE)


static func set_image_button_asset(button: Button, asset_key: String, fallback_color: Color = Color.WHITE) -> void:
	if button == null:
		return
	var holder = button.find_child("ButtonImageHolder", false, false)
	if holder == null:
		return
	if holder.has_method("set_asset_key"):
		holder.set_asset_key(asset_key, fallback_color)


static func disable_focus_artifacts_in_tree(root: Node) -> void:
	if root == null:
		return
	if root is Button:
		disable_focus_artifact(root as Button)
	for child in root.get_children():
		disable_focus_artifacts_in_tree(child)


static func setup_close_button(
		button: Button,
		normal_asset_key: String = "ui.sheet.close_button",
		fallback_color: Color = Color.WHITE) -> Dictionary:
	return setup_image_button(button, normal_asset_key, fallback_color)


static func play_pressed_then_call(
		button: Button,
		callback: Callable,
		normal_asset_key: String,
		pressed_asset_key: String,
		duration_sec: float = 0.2,
		fallback_color: Color = Color.WHITE) -> void:
	if button == null:
		if callback.is_valid():
			callback.call()
		return

	if button.has_meta("close_action_pending") and bool(button.get_meta("close_action_pending")):
		return

	button.set_meta("close_action_pending", true)

	var holder = button.find_child("ButtonImageHolder", false, false)
	if holder != null and holder.has_method("set_asset_key"):
		holder.set_asset_key(pressed_asset_key, fallback_color)

	await button.get_tree().create_timer(duration_sec).timeout

	if is_instance_valid(button):
		button.set_meta("close_action_pending", false)
		var h = button.find_child("ButtonImageHolder", false, false)
		if h != null and h.has_method("set_asset_key"):
			h.set_asset_key(normal_asset_key, fallback_color)

	if callback.is_valid():
		callback.call()
