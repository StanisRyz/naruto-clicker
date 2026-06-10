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


static func disable_focus_artifacts_in_tree(root: Node) -> void:
	if root == null:
		return
	if root is Button:
		disable_focus_artifact(root as Button)
	for child in root.get_children():
		disable_focus_artifacts_in_tree(child)
