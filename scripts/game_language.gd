extends Node
## UI locale preference. Save-game identifiers and case data remain unchanged.

signal language_changed(language: String)

const OPTIONS_PATH := "user://the_scene_options.cfg"
const CATALOG_PATH := "res://data/localization/en.json"
const DEFAULT_LANGUAGE := "en"
const LANGUAGES: Array[String] = ["en", "zh_CN"]
const UITranslation = preload("res://scripts/ui_translation.gd")

var current_language := DEFAULT_LANGUAGE
var _translations: Array[Translation] = []


func _ready() -> void:
	var catalog: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	if not catalog is Dictionary:
		push_error("Could not load UI translation catalog: " + CATALOG_PATH)
		return
	for language in LANGUAGES:
		var translation := UITranslation.new()
		translation.configure(language, catalog)
		TranslationServer.add_translation(translation)
		_translations.append(translation)
	var preferences := ConfigFile.new()
	preferences.load(OPTIONS_PATH)
	set_language(String(preferences.get_value("interface", "language", DEFAULT_LANGUAGE)), false)


func set_language(language: String, persist := true) -> void:
	current_language = language if language in LANGUAGES else DEFAULT_LANGUAGE
	TranslationServer.set_locale(current_language)
	if persist:
		var preferences := ConfigFile.new()
		preferences.load(OPTIONS_PATH)
		preferences.set_value("interface", "language", current_language)
		var error := preferences.save(OPTIONS_PATH)
		if error != OK:
			push_warning("Could not save language preference: " + error_string(error))
	language_changed.emit(current_language)


func _exit_tree() -> void:
	# Release script-backed translations before the scripting runtime shuts down.
	for translation in _translations:
		TranslationServer.remove_translation(translation)
	_translations.clear()
