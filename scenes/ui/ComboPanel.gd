class_name ComboPanel
extends Control

@onready var combo_progress_bar: ProgressBar = $VBoxContainer/ComboProgressBar
@onready var combo_multiplier_label: Label = $VBoxContainer/ComboMultiplierLabel


func update_view(
	meter_value: float,
	combo_multiplier: float,
	empowered_active: bool,
	empowered_time_left: float
) -> void:
	combo_progress_bar.max_value = 100.0
	combo_progress_bar.value = clampf(meter_value, 0.0, combo_progress_bar.max_value)
	combo_multiplier_label.text = "x%.2f" % combo_multiplier
	if empowered_active:
		combo_multiplier_label.text = "x%.2f %.0fs" % [
			combo_multiplier,
			ceilf(empowered_time_left),
		]
