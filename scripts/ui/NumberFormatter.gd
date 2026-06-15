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


# Accepts int, float, or BigNumber. Dispatches to the right formatter.
static func compact(value) -> String:
	if value is BigNumber:
		return compact_big(value)
	return compact_float(float(value))


static func compact_big(bn: BigNumber) -> String:
	if bn == null or bn.is_zero():
		return "0"
	if bn.mantissa <= 0.0:
		return "0"
	var m: float = bn.mantissa
	var e: int = bn.exponent
	# Adjust for any un-normalized mantissa
	while m >= 1000.0 and e < COMPACT_SUFFIXES.size() - 1:
		m /= 1000.0
		e += 1
	while m < 1.0 and e > 0 and m > 0.0:
		m *= 1000.0
		e -= 1
	if e < 0:
		return "0"
	if e >= COMPACT_SUFFIXES.size():
		# Scientific-like fallback: e.g. "1.23e45"
		return "%.2fe%d" % [bn.mantissa, bn.exponent * 3]
	if e == 0:
		return str(int(m))
	return "%.1f%s" % [m, COMPACT_SUFFIXES[e]]


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
