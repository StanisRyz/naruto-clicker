extends SceneTree

# Run with: godot --headless --script res://scripts/tools/ValidateSettlementBalance.gd
# Checks Settlement building balance invariants after the equal-cost / always-unlocked rework.
# Exit 0 = pass, Exit 1 = fail.


func _init() -> void:
	var errors: Array[String] = []
	var warnings: Array[String] = []

	var building_count: int = SettlementConfig.BUILDING_NAMES.size()
	var costs: Array = BalanceConfig.BUILDING_BASE_COSTS
	var base_cost: int = BalanceConfig.BUILDING_BASE_COST
	var growth: float = BalanceConfig.BUILDING_COST_GROWTH

	# 1. BUILDING_BASE_COSTS size matches building count
	if costs.size() != building_count:
		errors.append("BUILDING_BASE_COSTS.size() is %d but SettlementConfig.BUILDING_NAMES.size() is %d" % [costs.size(), building_count])

	# 2. Every value in BUILDING_BASE_COSTS equals BUILDING_BASE_COST
	for i in range(costs.size()):
		if int(costs[i]) != base_cost:
			errors.append("BUILDING_BASE_COSTS[%d] is %d, expected BUILDING_BASE_COST=%d" % [i, costs[i], base_cost])

	# 3. BUILDING_BASE_COST > 0
	if base_cost <= 0:
		errors.append("BUILDING_BASE_COST must be > 0, got %d" % base_cost)

	# 4. BUILDING_COST_GROWTH > 1.0
	if growth <= 1.0:
		errors.append("BUILDING_COST_GROWTH must be > 1.0, got %f" % growth)

	# 5. ClickerState.can_buy_building() accepts every valid index, rejects invalid ones
	var state: ClickerState = ClickerState.new()
	if state == null:
		errors.append("ClickerState.new() returned null")
	else:
		for i in range(building_count):
			if not state.can_buy_building(i):
				errors.append("can_buy_building(%d) returned false on a fresh state — all buildings must be immediately available" % i)

		# 6. Invalid indexes return false
		if state.can_buy_building(-1):
			errors.append("can_buy_building(-1) returned true — should return false")
		if state.can_buy_building(building_count):
			errors.append("can_buy_building(%d) returned true — out-of-range index should return false" % building_count)

	# 7. buy_buildings() with "Invalid building" guard still works
	if state != null:
		var bad_result: Dictionary = state.buy_buildings(-1, "x1")
		if bad_result.get("success", false):
			errors.append("buy_buildings(-1, 'x1') returned success=true — invalid index must fail")

	# Report
	print("")
	print("=== Settlement Balance Validation ===")
	print("")

	if errors.is_empty() and warnings.is_empty():
		print("All checks passed.")
		print("")

	if not errors.is_empty():
		print("ERRORS (%d):" % errors.size())
		for e in errors:
			print("  [ERROR] " + e)
		print("")

	if not warnings.is_empty():
		print("WARNINGS (%d):" % warnings.size())
		for w in warnings:
			print("  [WARN]  " + w)
		print("")

	print("--- Summary ---")
	print("Building count:      %d" % building_count)
	print("BUILDING_BASE_COST:  %d" % base_cost)
	print("BUILDING_COST_GROWTH:%s" % str(growth))
	print("BUILDING_BASE_COSTS: %s" % str(costs))
	print("Errors:              %d" % errors.size())
	print("Warnings:            %d" % warnings.size())
	print("")

	if errors.is_empty():
		print("RESULT: PASS")
		quit(0)
	else:
		print("RESULT: FAIL")
		quit(1)
