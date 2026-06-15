# BigNumber sanity tests. Run from editor or a tool script.
# Each check prints PASS/FAIL to the console.
class_name BigNumberSanityTest
extends RefCounted

static func run_all() -> void:
	var failures: int = 0
	failures += _check("zero is zero", BigNumber.zero().is_zero())
	failures += _check("one is positive", BigNumber.one().is_positive())
	failures += _check("zero not positive", not BigNumber.zero().is_positive())

	# from_int round-trip
	var bn5 := BigNumber.from_int(5)
	failures += _check("from_int(5) floor", bn5.floor_to_int_safe() == 5)

	# normalize: 1500 -> 1.5 * 1000^1
	var bn1500 := BigNumber.from_int(1500)
	failures += _check("1500 mantissa", abs(bn1500.mantissa - 1.5) < 0.0001)
	failures += _check("1500 exponent", bn1500.exponent == 1)

	# add
	var a := BigNumber.from_int(500)
	var b := BigNumber.from_int(700)
	var sum := a.add(b)
	failures += _check("500+700=1200", sum.floor_to_int_safe() == 1200)

	# subtract
	var diff := b.subtract(a)
	failures += _check("700-500=200", diff.floor_to_int_safe() == 200)

	# subtract clamp to zero
	var clamped := a.subtract(b)
	failures += _check("500-700 clamped to zero", clamped.is_zero())

	# multiply_int
	var m := BigNumber.from_int(100).multiply_int(12)
	failures += _check("100*12=1200", m.floor_to_int_safe() == 1200)

	# multiply_float
	var mf := BigNumber.from_int(200).multiply_float(1.5)
	failures += _check("200*1.5=300", abs(mf.to_float_approx() - 300.0) < 0.5)

	# divide_float
	var dv := BigNumber.from_int(600).divide_float(4.0)
	failures += _check("600/4=150", abs(dv.to_float_approx() - 150.0) < 0.5)

	# compare_to
	failures += _check("compare 5<10", BigNumber.from_int(5).compare_to(BigNumber.from_int(10)) == -1)
	failures += _check("compare 10>5", BigNumber.from_int(10).compare_to(BigNumber.from_int(5)) == 1)
	failures += _check("compare 7==7", BigNumber.from_int(7).compare_to(BigNumber.from_int(7)) == 0)

	# pow_float: 12^2 = 144
	var p := BigNumber.pow_float(12.0, 2)
	failures += _check("12^2=144", abs(p.to_float_approx() - 144.0) < 1.0)

	# pow_float: 11^0 = 1
	var p0 := BigNumber.pow_float(11.0, 0)
	failures += _check("11^0=1", abs(p0.to_float_approx() - 1.0) < 0.01)

	# large exponent doesn't overflow: 12^27
	var big := BigNumber.pow_float(12.0, 27)
	failures += _check("12^27 is positive", big.is_positive())
	failures += _check("12^27 exponent >= 1", big.exponent >= 1)

	# save/load round-trip (dict form)
	var original := BigNumber.from_parts(3.14, 5)
	var saved := original.to_save_dict()
	var loaded := BigNumber.from_save_dict(saved)
	failures += _check("save/load mantissa", abs(loaded.mantissa - original.mantissa) < 0.0001)
	failures += _check("save/load exponent", loaded.exponent == original.exponent)

	# save migration: old int save -> BigNumber
	var migrated := BigNumber.from_save_dict(500)
	failures += _check("int migration=500", migrated.floor_to_int_safe() == 500)

	# save migration: old float save
	var migrated_f := BigNumber.from_save_dict(1234.5)
	failures += _check("float migration approx", abs(migrated_f.to_float_approx() - 1234.5) < 1.0)

	# NumberFormatter integration
	var bn_million := BigNumber.from_parts(1.0, 2)  # 1 * 1000^2 = 1M
	var fmt := NumberFormatter.compact(bn_million)
	failures += _check("compact 1M contains M", fmt.contains("M") or fmt.contains("m"))

	# BalanceConfig partner formula sanity
	var cost0 := BalanceConfig.get_partner_cost_bignum(0)
	failures += _check("partner 0 cost positive", cost0.is_positive())
	var cost17 := BalanceConfig.get_partner_cost_bignum(17)
	failures += _check("partner 17 cost positive", cost17.is_positive())
	var cost27 := BalanceConfig.get_partner_cost_bignum(27)
	failures += _check("partner 27 cost > partner 17 cost", cost27.compare_to(cost17) > 0)

	var dps0 := BalanceConfig.get_partner_dps_bignum(0)
	failures += _check("partner 0 dps positive", dps0.is_positive())
	var dps27 := BalanceConfig.get_partner_dps_bignum(27)
	failures += _check("partner 27 dps > partner 0 dps", dps27.compare_to(dps0) > 0)

	if failures == 0:
		print("BigNumberSanityTest: ALL PASSED")
	else:
		push_error("BigNumberSanityTest: %d FAILURE(S)" % failures)


static func _check(label: String, condition: bool) -> int:
	if condition:
		print("  PASS  %s" % label)
		return 0
	else:
		push_error("  FAIL  %s" % label)
		return 1
