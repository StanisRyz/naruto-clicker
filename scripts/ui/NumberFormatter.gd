class_name NumberFormatter
extends RefCounted

const COMPACT_SUFFIXES: Array[String] = [
	"",
	"K",
	"M",
	"B",
	"T",
	"Qa",
	"Qi",
	"Sx",
	"Sp",
	"Oc",
	"No",
	"Dc",
	"Ud",
	"Dd",
	"Td",
	"Qad",
	"Qid",
	"Sxd",
	"Spd",
	"Ocd",
	"Nod",
	"Vg",
]


static func compact(value: int) -> String:
	return compact_float(float(value))


static func compact_percent(value: float) -> String:
	if abs(value) < 100.0:
		return "%.1f" % value
	return compact_float(value)


static func compact_float(value: float) -> String:
	var sign_str: String = "-" if value < 0.0 else ""
	var scaled: float = abs(value)
	var index: int = 0

	while scaled >= 1000.0 and index < COMPACT_SUFFIXES.size() - 1:
		scaled /= 1000.0
		index += 1

	if index == 0:
		return str(int(value))

	return "%s%.1f%s" % [sign_str, scaled, COMPACT_SUFFIXES[index]]
