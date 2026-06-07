class_name ButtonVisualUtils
extends RefCounted


static func disable_focus_artifact(button: Button) -> void:
	if button == null:
		return
	var empty_focus := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("focus", empty_focus)
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
