class_name ComboPanel
extends Control

@onready var combo_count_label: Label = $VBoxContainer/ComboCountLabel
@onready var combo_multiplier_label: Label = $VBoxContainer/ComboMultiplierLabel
@onready var combo_progress_bar: ProgressBar = $VBoxContainer/ComboProgressBar


func update_view(combo_count: int, combo_time_left: float, combo_timeout: float, combo_multiplier: float) -> void:
	combo_count_label.text = "Combo %d" % combo_count
	combo_multiplier_label.text = "x%.2f" % combo_multiplier
	combo_progress_bar.max_value = 100.0
	combo_progress_bar.value = clampf(float(combo_count), 0.0, combo_progress_bar.max_value)
	combo_progress_bar.tooltip_text = "%.1fs" % clampf(combo_time_left, 0.0, combo_timeout)
