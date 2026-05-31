class_name NumberFormatter
extends RefCounted

# Standard compact thresholds: K from 1 000, M from 1 000 000, B from 1 000 000 000, T from 1 000 000 000 000.
# Example: 304 400 shows as 304.4K.
static func compact(value: int) -> String:
	var abs_value: float = abs(float(value))
	var sign_str: String = "-" if value < 0 else ""
	if abs_value >= 1_000_000_000_000.0:
		return "%s%.1fT" % [sign_str, abs_value / 1_000_000_000_000.0]
	if abs_value >= 1_000_000_000.0:
		return "%s%.1fB" % [sign_str, abs_value / 1_000_000_000.0]
	if abs_value >= 1_000_000.0:
		return "%s%.1fM" % [sign_str, abs_value / 1_000_000.0]
	if abs_value >= 1_000.0:
		return "%s%.1fK" % [sign_str, abs_value / 1_000.0]
	return str(value)
