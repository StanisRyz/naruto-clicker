extends Node

signal language_changed

const CSV_PATH: String = "res://localization/game_text.csv"
const SUPPORTED_LANGUAGES: Array[String] = ["en", "ru"]
const DEFAULT_LANGUAGE: String = "en"

const BuiltinLocalizationData = preload("res://scripts/ui/LocalizationData.gd")

var _translations: Dictionary = {}
var _current_language: String = "en"
var _csv_loaded: bool = false


func _ready() -> void:
	_load_translations()


func _load_translations() -> void:
	_translations = BuiltinLocalizationData.get_translations()
	if not _translations.has("en"):
		_translations["en"] = {}
	if not _translations.has("ru"):
		_translations["ru"] = {}

	_csv_loaded = _try_load_csv()

	if OS.is_debug_build():
		var en_count: int = _translations["en"].size()
		var ru_count: int = 0
		for v: String in _translations["ru"].values():
			if v != "":
				ru_count += 1
		var source: String = "csv+builtin" if _csv_loaded else "builtin-only"
		print("LocalizationManager: source=%s en=%d ru_filled=%d" % [source, en_count, ru_count])
		if not _csv_loaded:
			print("LocalizationManager: CSV unavailable; using built-in LocalizationData.gd.")


func _try_load_csv() -> bool:
	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	if file == null:
		if _translations["en"].size() > 0:
			push_warning("LocalizationManager: CSV unavailable, using built-in localization fallback.")
		else:
			push_warning("LocalizationManager: No localization data loaded. UI will display keys. Check export include_filter for localization/*.csv")
		return false

	if file.eof_reached():
		file.close()
		return false

	file.get_line()

	while not file.eof_reached():
		var line: String = file.get_line()
		if line.strip_edges() == "":
			continue
		var fields: Array = _parse_csv_line(line)
		if fields.size() < 3:
			continue
		var key: String = fields[0].strip_edges()
		var en_text: String = fields[1]
		var ru_text: String = fields[2]
		if key == "":
			continue
		_translations["en"][key] = en_text
		_translations["ru"][key] = ru_text

	file.close()
	return true


func _parse_csv_line(line: String) -> Array:
	var fields: Array = []
	var current: String = ""
	var in_quotes: bool = false
	var i: int = 0
	while i < line.length():
		var c: String = line[i]
		if c == '"':
			if in_quotes and i + 1 < line.length() and line[i + 1] == '"':
				current += '"'
				i += 1
			else:
				in_quotes = not in_quotes
		elif c == "," and not in_quotes:
			fields.append(current)
			current = ""
		else:
			current += c
		i += 1
	fields.append(current)
	return fields


func tr_key(key: String) -> String:
	if _translations.has(_current_language):
		var lang_map: Dictionary = _translations[_current_language]
		if lang_map.has(key):
			var text: String = lang_map[key]
			if text != "":
				return text

	if _current_language != DEFAULT_LANGUAGE and _translations.has(DEFAULT_LANGUAGE):
		var en_map: Dictionary = _translations[DEFAULT_LANGUAGE]
		if en_map.has(key):
			var en_text: String = en_map[key]
			if en_text != "":
				return en_text

	if OS.is_debug_build():
		push_warning("LocalizationManager: missing key '%s'" % key)
	return key


func format_key(key: String, values: Dictionary = {}) -> String:
	var text := tr_key(key)
	for value_key in values.keys():
		text = text.replace("{" + str(value_key) + "}", str(values[value_key]))
	return text


func set_language(language_code: String) -> void:
	if not language_code in SUPPORTED_LANGUAGES:
		language_code = DEFAULT_LANGUAGE
	if _current_language == language_code:
		return
	_current_language = language_code
	TranslationServer.set_locale(language_code)
	language_changed.emit()


func get_language() -> String:
	return _current_language


func get_available_languages() -> Array[String]:
	return SUPPORTED_LANGUAGES.duplicate()


func get_loaded_translation_count(language_code: String = DEFAULT_LANGUAGE) -> int:
	if _translations.has(language_code):
		return _translations[language_code].size()
	return 0


func has_loaded_translations() -> bool:
	return get_loaded_translation_count(DEFAULT_LANGUAGE) > 0


func get_localization_source_status() -> String:
	var en_count: int = get_loaded_translation_count("en")
	var ru_count: int = 0
	if _translations.has("ru"):
		for v: String in _translations["ru"].values():
			if v != "":
				ru_count += 1
	var builtin_count: int = BuiltinLocalizationData.TRANSLATIONS["en"].size()
	var source: String = "csv+builtin" if _csv_loaded else "builtin-only"
	return "source=%s builtin_en=%d csv_loaded=%s final_en=%d ru_filled=%d" % [
		source, builtin_count, str(_csv_loaded), en_count, ru_count,
	]
