class_name BigNumber
extends RefCounted

# Represents value = mantissa * 1000^exponent.
# Normalized: mantissa in [1.0, 1000.0) for positive non-zero values.
# Zero: mantissa = 0.0, exponent = 0.
# Negative mantissa is not used for currencies; subtract() clamps to zero.

var mantissa: float = 0.0
var exponent: int = 0


# ---- Constructors ----

static func zero() -> BigNumber:
	return BigNumber.new()  # defaults: mantissa=0.0, exponent=0


static func one() -> BigNumber:
	var bn := BigNumber.new()
	bn.mantissa = 1.0
	bn.exponent = 0
	return bn


static func from_int(value: int) -> BigNumber:
	return from_float(float(value))


static func from_float(value: float) -> BigNumber:
	var bn := BigNumber.new()
	if value == 0.0 or not is_finite(value):
		return bn
	var sign_val: float = 1.0 if value >= 0.0 else -1.0
	var abs_val: float = absf(value)
	var e: int = 0
	while abs_val >= 1000.0:
		abs_val /= 1000.0
		e += 1
	while abs_val > 0.0 and abs_val < 1.0:
		abs_val *= 1000.0
		e -= 1
	bn.mantissa = sign_val * abs_val
	bn.exponent = e
	return bn


static func from_parts(m: float, e: int) -> BigNumber:
	var bn := BigNumber.new()
	bn.mantissa = m
	bn.exponent = e
	return bn._normalize_self()


# ---- Clone / copy ----

func clone() -> BigNumber:
	var bn := BigNumber.new()
	bn.mantissa = mantissa
	bn.exponent = exponent
	return bn


# ---- Normalization ----

func normalized() -> BigNumber:
	return clone()._normalize_self()


func _normalize_self() -> BigNumber:
	if mantissa == 0.0 or not is_finite(mantissa):
		mantissa = 0.0
		exponent = 0
		return self
	var sign_val: float = 1.0 if mantissa >= 0.0 else -1.0
	var abs_m: float = absf(mantissa)
	while abs_m >= 1000.0:
		abs_m /= 1000.0
		exponent += 1
	while abs_m > 0.0 and abs_m < 1.0:
		abs_m *= 1000.0
		exponent -= 1
	mantissa = sign_val * abs_m
	return self


# ---- Predicates ----

func is_zero() -> bool:
	return mantissa == 0.0


func is_positive() -> bool:
	return mantissa > 0.0


# ---- Comparison ----

# Returns -1 if self < other, 0 if equal, 1 if self > other.
func compare_to(other: BigNumber) -> int:
	if mantissa <= 0.0 and other.mantissa <= 0.0:
		return 0
	if mantissa <= 0.0:
		return -1
	if other.mantissa <= 0.0:
		return 1
	if exponent != other.exponent:
		return -1 if exponent < other.exponent else 1
	if absf(mantissa - other.mantissa) < 1e-9 * maxf(absf(mantissa), 1.0):
		return 0
	return -1 if mantissa < other.mantissa else 1


# ---- Arithmetic ----

func add(other: BigNumber) -> BigNumber:
	if is_zero():
		return other.clone()
	if other.is_zero():
		return clone()
	var result := BigNumber.new()
	var exp_diff: int = exponent - other.exponent
	# If the exponents differ by >= 15, the smaller is negligible in float arithmetic.
	if exp_diff >= 15:
		return clone()
	if exp_diff <= -15:
		return other.clone()
	var combined: float
	if exp_diff >= 0:
		combined = mantissa + other.mantissa * pow(1000.0, float(-exp_diff))
		result.exponent = exponent
	else:
		combined = mantissa * pow(1000.0, float(exp_diff)) + other.mantissa
		result.exponent = other.exponent
	result.mantissa = combined
	return result._normalize_self()


# Subtract other from self, clamped to zero (for currencies / HP).
func subtract(other: BigNumber) -> BigNumber:
	if other.is_zero():
		return clone()
	if is_zero():
		return BigNumber.zero()
	var exp_diff: int = exponent - other.exponent
	if exp_diff > 15:
		return clone()  # other is negligible
	if exp_diff < -15:
		return BigNumber.zero()  # self is negligible vs other → clamp to 0
	var combined: float
	if exp_diff >= 0:
		combined = mantissa - other.mantissa * pow(1000.0, float(-exp_diff))
		var result := BigNumber.new()
		result.exponent = exponent
		if combined <= 0.0:
			return BigNumber.zero()
		result.mantissa = combined
		return result._normalize_self()
	else:
		combined = mantissa * pow(1000.0, float(exp_diff)) - other.mantissa
		var result := BigNumber.new()
		result.exponent = other.exponent
		if combined <= 0.0:
			return BigNumber.zero()
		result.mantissa = combined
		return result._normalize_self()


func multiply_float(m: float) -> BigNumber:
	if is_zero() or m == 0.0:
		return BigNumber.zero()
	var result := BigNumber.new()
	result.mantissa = mantissa * m
	result.exponent = exponent
	return result._normalize_self()


func multiply_int(m: int) -> BigNumber:
	return multiply_float(float(m))


func divide_float(d: float) -> BigNumber:
	if d == 0.0 or is_zero():
		return BigNumber.zero()
	return multiply_float(1.0 / d)


# Compute base_val^exp_val as BigNumber using log arithmetic — no int64 overflow.
static func pow_float(base_val: float, exp_val: int) -> BigNumber:
	if exp_val == 0:
		return BigNumber.one()
	if base_val <= 0.0 or exp_val < 0:
		return BigNumber.zero()
	# log_1000(base_val^exp_val) = exp_val * log(base_val) / log(1000)
	var log1000: float = log(1000.0)
	var log1000_val: float = float(exp_val) * log(base_val) / log1000
	var e: int = floori(log1000_val)
	var frac: float = log1000_val - float(e)
	var m: float = exp(frac * log1000)
	return BigNumber.from_parts(m, e)


# ---- Conversion ----

# Returns int clamped to [0, 9e18] to avoid int64 overflow.
func floor_to_int_safe() -> int:
	if is_zero() or mantissa <= 0.0:
		return 0
	# 9e18 as int is safe in int64 (< INT64_MAX ≈ 9.22e18)
	const SAFE_INT_MAX: int = 9000000000000000000
	if exponent >= 7:
		return SAFE_INT_MAX
	var approx: float = mantissa
	for _i in range(exponent):
		approx *= 1000.0
		if approx >= 9.0e18:
			return SAFE_INT_MAX
	if approx >= 9.0e18:
		return SAFE_INT_MAX
	return int(floor(approx))


func to_float_approx() -> float:
	if is_zero():
		return 0.0
	return mantissa * pow(1000.0, float(exponent))


# ---- Save / load ----

func to_save_dict() -> Dictionary:
	return {"m": mantissa, "e": exponent}


# Migrates from old int/float saves or loads a {"m":…,"e":…} dict.
static func from_save_dict(data) -> BigNumber:
	if data == null:
		return BigNumber.zero()
	if data is int:
		return BigNumber.from_int(data)
	if data is float:
		return BigNumber.from_float(data)
	if data is Dictionary:
		var raw_m = data.get("m", data.get("mantissa", null))
		var raw_e = data.get("e", data.get("exponent", null))
		if raw_m != null and raw_e != null:
			return BigNumber.from_parts(float(raw_m), int(raw_e))
	return BigNumber.zero()


# ---- Debug ----

func to_debug_string() -> String:
	if is_zero():
		return "BN(0)"
	return "BN(%.4f * 1000^%d)" % [mantissa, exponent]
