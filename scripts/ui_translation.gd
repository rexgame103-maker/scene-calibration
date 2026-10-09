extends Translation
## Translates UI strings while keeping their original values available to game logic.
## Some existing controls receive formatted text rather than a translation template.

var _messages: Dictionary = {}
var _templates: Array[Dictionary] = []
var _placeholder := RegEx.new()
var _chinese := RegEx.new()
var _source_language := false


func configure(language: String, messages: Dictionary) -> void:
	locale = language
	_source_language = language == "zh_CN"
	_messages = messages
	_placeholder.compile("%[dsf]")
	_chinese.compile("[\\x{3400}-\\x{9fff}]")
	for source: String in messages:
		var tokens := _placeholder.search_all(source)
		if tokens.is_empty():
			continue
		var expression := "(?s)^"
		var cursor := 0
		for token: RegExMatch in tokens:
			expression += _escape_pattern(source.substr(cursor, token.get_start() - cursor))
			expression += "(-?[0-9]+)" if token.get_string() == "%d" else "(.*?)"
			cursor = token.get_end()
		expression += _escape_pattern(source.substr(cursor)) + "$"
		var pattern := RegEx.new()
		if pattern.compile(expression) == OK:
			_templates.append({"pattern": pattern, "target": messages[source],
				"specificity": source.length() - tokens.size() * 2})
	_templates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.specificity) > int(b.specificity))


func _get_message(source: StringName, _context: StringName) -> StringName:
	if _source_language:
		return source
	var original := String(source)
	var translated := _translate(original, 0)
	return StringName(translated) if translated != original else StringName()


func _translate(source: String, depth: int) -> String:
	if _messages.has(source):
		return String(_messages[source])
	if depth > 8 or _chinese.search(source) == null:
		return source
	# The archive inserts paragraph spacing after Chinese full stops.
	var normalized := source.replace("。\n\n", "。")
	if _messages.has(normalized):
		return String(_messages[normalized])
	for entry: Dictionary in _templates:
		var match_result: RegExMatch = entry.pattern.search(source)
		if match_result == null:
			continue
		var target := String(entry.target)
		var result := ""
		var cursor := 0
		var capture := 1
		for token: RegExMatch in _placeholder.search_all(target):
			result += target.substr(cursor, token.get_start() - cursor)
			result += _translate(match_result.get_string(capture), depth + 1)
			cursor = token.get_end()
			capture += 1
		return result + target.substr(cursor)
	# Preserve state markers and translate the document/furniture name after them.
	for prefix: String in ["✓  ", "●  ", "✓ ", "● "]:
		if source.begins_with(prefix):
			return prefix + _translate(source.substr(prefix.length()), depth + 1)
	if source.contains(" · 来源："):
		var parts := source.split(" · 来源：", true, 1)
		return _translate(parts[0], depth + 1) + " · Source: " + _translate(parts[1], depth + 1)
	# These separators are used by document rows, equipment counts and clue lists.
	for separator: String in ["\n", " × ", "、", " · ", "  ", " / "]:
		if not source.contains(separator):
			continue
		var parts := source.split(separator)
		var changed := false
		for index in parts.size():
			var translated := _translate(parts[index], depth + 1)
			changed = changed or translated != parts[index]
			parts[index] = translated
		if changed:
			return (", " if separator == "、" else separator).join(parts)
	return source


func _escape_pattern(value: String) -> String:
	var escaped := ""
	for character in value:
		escaped += "\\" + character if character in "\\.^$|?*+()[]{}" else character
	return escaped
