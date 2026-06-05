extends SceneTree

# Run with: godot --headless --script res://scripts/tools/ValidateNumberFormatter.gd

const CASES: Array = [
	[0,                          "0"],
	[1,                          "1"],
	[999,                        "999"],
	[1000,                       "1.0K"],
	[1500,                       "1.5K"],
	[1_000_000,                  "1.0M"],
	[1_000_000_000,              "1.0B"],
	[1_000_000_000_000,          "1.0T"],
	[1_000_000_000_000_000,      "1.0Qa"],
	[10_000_000_000_000_000,     "10.0Qa"],
	[1_000_000_000_000_000_000,  "1.0Qi"],
	[-1000,                      "-1.0K"],
	[-1_000_000_000_000_000,     "-1.0Qa"],
]


func _init() -> void:
	var failed: int = 0

	for c in CASES:
		var input: int = int(c[0])
		var expected: String = str(c[1])
		var got: String = NumberFormatter.compact(input)
		if got != expected:
			print("[FAIL] compact(%d) => '%s'  expected '%s'" % [input, got, expected])
			failed += 1
		else:
			print("[PASS] compact(%d) => '%s'" % [input, got])

	print("")
	if failed == 0:
		print("All %d cases passed." % CASES.size())
		quit(0)
	else:
		print("%d / %d cases FAILED." % [failed, CASES.size()])
		quit(1)
