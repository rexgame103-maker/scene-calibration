extends Node


signal clue_discovered(clue: Dictionary)
signal evidence_viewed(evidence: Dictionary)
signal furniture_unlocked(furniture: Dictionary)
signal case_loaded(case_id: String)

const DEFAULT_CASE_PATH := "res://data/cases/office_case_001.json"

var current_case_path := DEFAULT_CASE_PATH
var current_case_data: Dictionary = {}
var clues: Dictionary = {}
var evidence: Dictionary = {}
var furniture: Dictionary = {}


func _ready() -> void:
	load_case(DEFAULT_CASE_PATH)


func load_case(case_path: String = DEFAULT_CASE_PATH) -> bool:
	if not FileAccess.file_exists(case_path):
		push_error("Case data does not exist: %s" % case_path)
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(case_path))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Case data is not a valid JSON object: %s" % case_path)
		return false

	current_case_path = case_path
	current_case_data = (parsed as Dictionary).duplicate(true)
	clues.clear()
	evidence.clear()
	furniture.clear()

	for clue_value: Variant in current_case_data.get("clues", []):
		if typeof(clue_value) != TYPE_DICTIONARY:
			continue
		var clue: Dictionary = (clue_value as Dictionary).duplicate(true)
		var clue_id := String(clue.get("id", ""))
		if clue_id.is_empty():
			continue
		clue["id"] = clue_id
		clue["title"] = String(clue.get("title", clue_id))
		clue["description"] = String(clue.get("description", ""))
		clue["type"] = String(clue.get("type", "general"))
		clue["is_discovered"] = bool(clue.get("is_discovered", false))
		clues[clue_id] = clue

	for evidence_value: Variant in current_case_data.get("evidence", []):
		if typeof(evidence_value) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = (evidence_value as Dictionary).duplicate(true)
		var evidence_id := String(item.get("id", ""))
		if evidence_id.is_empty():
			continue
		item["id"] = evidence_id
		item["is_viewed"] = bool(item.get("is_viewed", false))
		evidence[evidence_id] = item

	for furniture_value: Variant in current_case_data.get("furniture_unlocks", []):
		if typeof(furniture_value) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = (furniture_value as Dictionary).duplicate(true)
		var furniture_id := String(item.get("furniture_id", ""))
		if furniture_id.is_empty():
			continue
		item["furniture_id"] = furniture_id
		item["display_name"] = String(item.get("display_name", furniture_id))
		item["is_unlocked"] = bool(item.get("is_unlocked", false))
		furniture[furniture_id] = item

	case_loaded.emit(String(current_case_data.get("case_id", "")))
	return true


func reset_current_case() -> bool:
	return load_case(current_case_path)


func discover_clue(clue_id: String) -> bool:
	if not clues.has(clue_id):
		push_warning("Unknown clue id: %s" % clue_id)
		return false
	var clue: Dictionary = clues[clue_id]
	if bool(clue.get("is_discovered", false)):
		return false
	clue["is_discovered"] = true
	clues[clue_id] = clue
	clue_discovered.emit(clue.duplicate(true))
	_evaluate_furniture_unlocks()
	return true


func has_clue(clue_id: String) -> bool:
	if not clues.has(clue_id):
		return false
	return bool((clues[clue_id] as Dictionary).get("is_discovered", false))


func get_clue_data(clue_id: String) -> Dictionary:
	if not clues.has(clue_id):
		return {}
	return (clues[clue_id] as Dictionary).duplicate(true)


func get_discovered_clues() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for clue_value: Variant in clues.values():
		var clue := clue_value as Dictionary
		if bool(clue.get("is_discovered", false)):
			result.append(clue.duplicate(true))
	return result


func get_case_summary() -> Dictionary:
	return {
		"case_id": String(current_case_data.get("case_id", "")),
		"title": String(current_case_data.get("title", "案件资料")),
		"subtitle": String(current_case_data.get("subtitle", ""))
	}


func get_briefing_data() -> Dictionary:
	var briefing_value: Variant = current_case_data.get("briefing", {})
	if briefing_value is Dictionary:
		return (briefing_value as Dictionary).duplicate(true)
	return {}


func get_completion_data() -> Dictionary:
	var completion_value: Variant = current_case_data.get("completion", {})
	if completion_value is Dictionary:
		return (completion_value as Dictionary).duplicate(true)
	return {}


func get_scene_layout() -> Dictionary:
	var value: Variant = current_case_data.get("scene_layout", {})
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}


func get_reconstruction_zones() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value: Variant in current_case_data.get("reconstruction_zones", []):
		if value is Dictionary:
			result.append((value as Dictionary).duplicate(true))
	return result


func get_scene_clue_points() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value: Variant in current_case_data.get("scene_clue_points", []):
		if value is Dictionary:
			result.append((value as Dictionary).duplicate(true))
	return result


func are_clues_discovered(clue_ids: Array) -> bool:
	if clue_ids.is_empty():
		return true
	for clue_id_value: Variant in clue_ids:
		if not has_clue(String(clue_id_value)):
			return false
	return true


func get_available_evidence() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var ordered_ids: Array = current_case_data.get("evidence", [])
	for source_value: Variant in ordered_ids:
		if typeof(source_value) != TYPE_DICTIONARY:
			continue
		var evidence_id := String((source_value as Dictionary).get("id", ""))
		if not evidence.has(evidence_id):
			continue
		var item := evidence[evidence_id] as Dictionary
		if not bool(item.get("is_initially_available", true)):
			if not _requirements_met(item.get("required_clues", []), "all"):
				continue
		result.append(item.duplicate(true))
	return result


func get_evidence_data(evidence_id: String) -> Dictionary:
	if not evidence.has(evidence_id):
		return {}
	return (evidence[evidence_id] as Dictionary).duplicate(true)


func view_evidence(evidence_id: String) -> Array[String]:
	var discovered_ids: Array[String] = []
	if not evidence.has(evidence_id):
		push_warning("Unknown evidence id: %s" % evidence_id)
		return discovered_ids
	var item := evidence[evidence_id] as Dictionary
	item["is_viewed"] = true
	evidence[evidence_id] = item
	for clue_value: Variant in item.get("clue_ids", []):
		var clue_id := String(clue_value)
		if discover_clue(clue_id):
			discovered_ids.append(clue_id)
	evidence_viewed.emit(item.duplicate(true))
	return discovered_ids


func is_furniture_unlocked(furniture_id: String) -> bool:
	if not furniture.has(furniture_id):
		return false
	return bool((furniture[furniture_id] as Dictionary).get("is_unlocked", false))


func is_catalog_kind_unlocked(catalog_kind: String) -> bool:
	for furniture_value: Variant in furniture.values():
		var item := furniture_value as Dictionary
		if String(item.get("catalog_kind", "")) == catalog_kind:
			return bool(item.get("is_unlocked", false))
	return false


func get_furniture_data(furniture_id: String) -> Dictionary:
	if not furniture.has(furniture_id):
		return {}
	return (furniture[furniture_id] as Dictionary).duplicate(true)


func get_furniture_by_catalog_kind(catalog_kind: String) -> Dictionary:
	for furniture_value: Variant in furniture.values():
		var item := furniture_value as Dictionary
		if String(item.get("catalog_kind", "")) == catalog_kind:
			return item.duplicate(true)
	return {}


func get_unlocked_furniture() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for furniture_value: Variant in furniture.values():
		var item := furniture_value as Dictionary
		if bool(item.get("is_unlocked", false)):
			result.append(item.duplicate(true))
	return result


func get_reconstruction_steps() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for step_value: Variant in current_case_data.get("reconstruction_steps", []):
		if typeof(step_value) == TYPE_DICTIONARY:
			result.append((step_value as Dictionary).duplicate(true))
	return result


func _evaluate_furniture_unlocks() -> void:
	for furniture_id_value: Variant in furniture.keys():
		var furniture_id := String(furniture_id_value)
		var item := furniture[furniture_id] as Dictionary
		if bool(item.get("is_unlocked", false)):
			continue
		var required_clues: Variant = item.get("required_clues", [])
		var unlock_mode := String(item.get("unlock_mode", "all"))
		if not _requirements_met(required_clues, unlock_mode):
			continue
		item["is_unlocked"] = true
		furniture[furniture_id] = item
		furniture_unlocked.emit(item.duplicate(true))


func _requirements_met(required_value: Variant, mode: String) -> bool:
	if not required_value is Array:
		return false
	var required := required_value as Array
	if required.is_empty():
		return false
	if mode == "any":
		for clue_value: Variant in required:
			if has_clue(String(clue_value)):
				return true
		return false
	for clue_value: Variant in required:
		if not has_clue(String(clue_value)):
			return false
	return true
