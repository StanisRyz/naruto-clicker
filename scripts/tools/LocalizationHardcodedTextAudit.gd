extends SceneTree

# Dev-only tool — not connected to game runtime.
# Run with: godot --headless --script res://scripts/tools/LocalizationHardcodedTextAudit.gd
#
# Scans .gd and .tscn files for likely hardcoded visible text.
# Reports candidate lines to the console.

const SCAN_DIRS: Array[String] = [
	"res://scenes",
	"res://scripts",
	"res://autoload",
]

# Files whose hardcoded strings are intentional or generated — skip entirely.
const SKIP_FILES: Array[String] = [
	"LocalizationData.gd",
	"LocalizationHardcodedTextAudit.gd",
	"GenerateLocalizationData.gd",
	"BalanceAuditReport.gd",
	"game_text.csv",
]

# Patterns that indicate a line is already safe or not player-visible.
const SAFE_PATTERNS: Array[String] = [
	"tr_key(",
	"format_key(",
	"print(",
	"push_warning(",
	"push_error(",
	"printerr(",
	"printraw(",
	"res://",
	"class_name ",
	"signal ",
	"func ",
	"#",
	"var ",
	"const ",
	"@",
	"LocalizationManager",
	"NumberFormatter",
	"BuildConfig",
	".name =",
	"node_name",
	"asset_key",
	"holder_name",
	"group(",
	".add_to_group(",
	".set_name(",
]

# Patterns that look like visible text assignments worth flagging.
const SUSPECT_PATTERNS_GD: Array[String] = [
	'.text = "',
	'status_text = "',
	'title = "',
	'description = "',
	'placeholder_text = "',
	'tooltip_text = "',
]

const SUSPECT_PATTERNS_TSCN: Array[String] = [
	'text = "',
	'placeholder_text = "',
	'tooltip_text = "',
]

var _findings: Array[Dictionary] = []


func _init() -> void:
	for dir_path in SCAN_DIRS:
		_scan_directory(dir_path)

	if _findings.is_empty():
		print("LocalizationHardcodedTextAudit: no candidates found.")
	else:
		print("LocalizationHardcodedTextAudit: %d candidate(s) found:" % _findings.size())
		for f in _findings:
			print("  %s:%d  %s" % [f["file"], f["line"], f["text"].strip_edges()])

	quit(0)


func _scan_directory(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry == "." or entry == "..":
			entry = dir.get_next()
			continue
		var full_path: String = dir_path.path_join(entry)
		if dir.current_is_dir():
			_scan_directory(full_path)
		elif entry.ends_with(".gd"):
			_scan_file(full_path, false)
		elif entry.ends_with(".tscn"):
			_scan_file(full_path, true)
		entry = dir.get_next()
	dir.list_dir_end()


func _scan_file(path: String, is_tscn: bool) -> void:
	var filename: String = path.get_file()
	for skip in SKIP_FILES:
		if filename == skip:
			return

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return

	var patterns: Array[String] = SUSPECT_PATTERNS_TSCN if is_tscn else SUSPECT_PATTERNS_GD
	var line_number: int = 0

	while not file.eof_reached():
		var line: String = file.get_line()
		line_number += 1

		# Skip empty lines and pure whitespace.
		var stripped: String = line.strip_edges()
		if stripped.is_empty():
			continue

		# Check if any suspect pattern matches.
		var matched_pattern: bool = false
		for pattern in patterns:
			if stripped.contains(pattern):
				matched_pattern = true
				break
		if not matched_pattern:
			continue

		# Skip lines that match any safe pattern.
		var is_safe: bool = false
		for safe in SAFE_PATTERNS:
			if stripped.contains(safe):
				is_safe = true
				break
		if is_safe:
			continue

		# Skip empty string literals: text = ""
		if stripped.ends_with('= ""') or stripped.ends_with('= "":'):
			continue

		# Skip pure numeric string literals: text = "0", text = "1", etc.
		var quote_start: int = stripped.find('"')
		var quote_end: int = stripped.rfind('"')
		if quote_start >= 0 and quote_end > quote_start:
			var literal: String = stripped.substr(quote_start + 1, quote_end - quote_start - 1)
			if literal.is_valid_int() or literal.is_valid_float():
				continue
			# Skip single-char universal symbols that are not language-specific.
			if literal in ["x1", "x2", "x3", "x4", "x10", "x100", "[x1]", "[x2]", "[x3]", "[x4]", "[x10]", "[x100]", "X"]:
				continue

		_findings.append({"file": path, "line": line_number, "text": stripped})
