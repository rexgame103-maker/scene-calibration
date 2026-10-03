extends Node


signal zone_satisfaction_changed(zone_id: String, is_satisfied: bool)
signal reconstruction_step_completed(step_id: String)

var zones: Dictionary = {}
var furniture_nodes: Array[Node3D] = []
var reconstruction_steps: Dictionary = {}
var completed_steps: Dictionary = {}
var _evaluation_queued := false


func _ready() -> void:
	var case_manager := _get_case_manager()
	if is_instance_valid(case_manager):
		var case_loaded_callback := Callable(self, "_on_case_loaded")
		if not case_manager.is_connected("case_loaded", case_loaded_callback):
			case_manager.connect("case_loaded", case_loaded_callback)
		var clue_callback := Callable(self, "_on_clue_discovered")
		if not case_manager.is_connected("clue_discovered", clue_callback):
			case_manager.connect("clue_discovered", clue_callback)
	_load_case_configuration()


func register_zone(zone: ReconstructionZone) -> void:
	if not is_instance_valid(zone) or zone.zone_id.is_empty():
		return
	var previous := zones.get(zone.zone_id, null) as ReconstructionZone
	if is_instance_valid(previous) and previous != zone:
		var previous_callback := Callable(self, "_on_zone_satisfaction_changed")
		if previous.is_connected("satisfaction_changed", previous_callback):
			previous.disconnect("satisfaction_changed", previous_callback)
	zones[zone.zone_id] = zone
	var callback := Callable(self, "_on_zone_satisfaction_changed")
	if not zone.is_connected("satisfaction_changed", callback):
		zone.connect("satisfaction_changed", callback)
	request_evaluation()


func unregister_zone(zone: ReconstructionZone) -> void:
	if not is_instance_valid(zone):
		return
	if zones.get(zone.zone_id, null) == zone:
		zones.erase(zone.zone_id)
	request_evaluation()


func register_furniture(furniture_node: Node3D) -> void:
	if not is_instance_valid(furniture_node) or furniture_nodes.has(furniture_node):
		return
	furniture_nodes.append(furniture_node)
	request_evaluation()


func unregister_furniture(furniture_node: Node3D) -> void:
	furniture_nodes.erase(furniture_node)
	request_evaluation()


func notify_furniture_placement_completed(furniture_node: Node3D) -> void:
	register_furniture(furniture_node)
	evaluate_all()


func request_evaluation() -> void:
	if _evaluation_queued:
		return
	_evaluation_queued = true
	call_deferred("evaluate_all")


func evaluate_all() -> void:
	_evaluation_queued = false
	_prune_invalid_nodes()
	for zone_value: Variant in zones.values():
		var zone := zone_value as ReconstructionZone
		if is_instance_valid(zone):
			zone.evaluate_candidates(furniture_nodes)
	_evaluate_steps()


func is_furniture_condition_satisfied(furniture_id: String) -> bool:
	for zone_value: Variant in zones.values():
		var zone := zone_value as ReconstructionZone
		if is_instance_valid(zone) and zone.required_furniture_id == furniture_id and zone.is_satisfied:
			return true
	return false


func is_zone_satisfied(zone_id: String) -> bool:
	var zone := zones.get(zone_id, null) as ReconstructionZone
	return is_instance_valid(zone) and zone.is_satisfied


func are_conditions_satisfied(zone_ids: Array) -> bool:
	if zone_ids.is_empty():
		return false
	for zone_id_value: Variant in zone_ids:
		if not is_zone_satisfied(String(zone_id_value)):
			return false
	return true


func is_step_satisfied(step_id: String) -> bool:
	if not reconstruction_steps.has(step_id):
		return false
	var step := reconstruction_steps[step_id] as Dictionary
	if not are_conditions_satisfied(step.get("zone_ids", [])):
		return false
	var required_clues: Array = step.get("required_clue_ids", [])
	if not required_clues.is_empty():
		var case_manager := _get_case_manager()
		if not is_instance_valid(case_manager) or not bool(case_manager.call("are_clues_discovered", required_clues)):
			return false
	return _are_lighting_conditions_satisfied(step.get("lighting_conditions", []))


func has_step_completed(step_id: String) -> bool:
	return bool(completed_steps.get(step_id, false))


func get_pending_lighting_conditions() -> Array:
	var case_manager := _get_case_manager()
	for step_id_value: Variant in reconstruction_steps.keys():
		var step_id := String(step_id_value)
		if bool(completed_steps.get(step_id, false)):
			continue
		var step := reconstruction_steps[step_id] as Dictionary
		var conditions: Array = step.get("lighting_conditions", [])
		if conditions.is_empty() or not are_conditions_satisfied(step.get("zone_ids", [])):
			continue
		var required_clues: Array = step.get("required_clue_ids", [])
		if not required_clues.is_empty():
			if not is_instance_valid(case_manager) or not bool(case_manager.call("are_clues_discovered", required_clues)):
				continue
		if not _are_lighting_conditions_satisfied(conditions):
			return conditions.duplicate(true)
	return []


func reset_runtime_state() -> void:
	completed_steps.clear()
	for zone_value: Variant in zones.values():
		var zone := zone_value as ReconstructionZone
		if is_instance_valid(zone):
			zone.call("_set_satisfied", false)
	request_evaluation()


func _on_case_loaded(_case_id: String) -> void:
	_load_case_configuration()
	completed_steps.clear()
	request_evaluation()


func _on_clue_discovered(_clue: Dictionary) -> void:
	request_evaluation()


func _load_case_configuration() -> void:
	reconstruction_steps.clear()
	var case_manager := _get_case_manager()
	if not is_instance_valid(case_manager):
		return
	var steps: Array = case_manager.call("get_reconstruction_steps")
	for step_value: Variant in steps:
		if typeof(step_value) != TYPE_DICTIONARY:
			continue
		var step := (step_value as Dictionary).duplicate(true)
		var step_id := String(step.get("step_id", ""))
		if not step_id.is_empty():
			reconstruction_steps[step_id] = step


func _evaluate_steps() -> void:
	for step_id_value: Variant in reconstruction_steps.keys():
		var step_id := String(step_id_value)
		if bool(completed_steps.get(step_id, false)):
			continue
		if not is_step_satisfied(step_id):
			continue
		completed_steps[step_id] = true
		reconstruction_step_completed.emit(step_id)
		_grant_step_rewards(reconstruction_steps[step_id] as Dictionary)


func _grant_step_rewards(step: Dictionary) -> void:
	var case_manager := _get_case_manager()
	if not is_instance_valid(case_manager):
		return
	for clue_id_value: Variant in step.get("reward_clue_ids", []):
		case_manager.call("discover_clue", String(clue_id_value))


func _on_zone_satisfaction_changed(zone_id: String, satisfied: bool) -> void:
	zone_satisfaction_changed.emit(zone_id, satisfied)


func _prune_invalid_nodes() -> void:
	for index: int in range(furniture_nodes.size() - 1, -1, -1):
		if not is_instance_valid(furniture_nodes[index]):
			furniture_nodes.remove_at(index)
	var invalid_zone_ids: Array[String] = []
	for zone_id_value: Variant in zones.keys():
		var zone_id := String(zone_id_value)
		if not is_instance_valid(zones[zone_id] as ReconstructionZone):
			invalid_zone_ids.append(zone_id)
	for zone_id: String in invalid_zone_ids:
		zones.erase(zone_id)


func _are_lighting_conditions_satisfied(conditions: Array) -> bool:
	for condition_value: Variant in conditions:
		if typeof(condition_value) != TYPE_DICTIONARY:
			continue
		if not _is_lighting_condition_satisfied(condition_value as Dictionary):
			return false
	return true


func _is_lighting_condition_satisfied(condition: Dictionary) -> bool:
	var condition_type := String(condition.get("type", "device_parameters"))
	match condition_type:
		"device_parameters":
			return _is_device_parameter_condition_satisfied(condition)
		"shadow_projection":
			return _is_shadow_projection_condition_satisfied(condition)
		"reflection_response":
			return _is_reflection_condition_satisfied(condition)
	return true


func _is_device_parameter_condition_satisfied(condition: Dictionary) -> bool:
	var device := _find_light_device(String(condition.get("furniture_id", "")))
	if not is_instance_valid(device):
		return false
	if condition.has("energy_range") and not _value_in_range(device.light_energy, condition["energy_range"] as Array):
		return false
	if condition.has("temperature_range") and not _value_in_range(device.temperature_kelvin, condition["temperature_range"] as Array):
		return false
	if condition.has("yaw_target"):
		var yaw_error := absf(wrapf(device.head_yaw_degrees - float(condition["yaw_target"]), -180.0, 180.0))
		if yaw_error > float(condition.get("yaw_tolerance", 8.0)):
			return false
	if condition.has("pitch_target"):
		if absf(device.head_pitch_degrees - float(condition["pitch_target"])) > float(condition.get("pitch_tolerance", 6.0)):
			return false
	return true


func _is_shadow_projection_condition_satisfied(condition: Dictionary) -> bool:
	var light_device := _find_light_device(String(condition.get("light_furniture_id", "")))
	var receiver := _find_furniture(String(condition.get("receiver_furniture_id", "")))
	if not is_instance_valid(light_device) or not is_instance_valid(receiver):
		return false
	var caster := receiver.find_child(String(condition.get("caster_node", "ScalpelTool")), true, false) as Node3D
	var surface := receiver.find_child(String(condition.get("surface_node", "ArtworkSurface")), true, false) as Node3D
	if not is_instance_valid(caster) or not is_instance_valid(surface):
		return false
	var light_origin := light_device.get_light_origin()
	var caster_position := caster.global_position
	var toward_caster := (caster_position - light_origin).normalized()
	if light_device.get_light_direction().dot(toward_caster) < float(condition.get("minimum_aim_dot", 0.90)):
		return false
	var horizontal_distance := Vector2(
		caster_position.x - light_origin.x,
		caster_position.z - light_origin.z
	).length()
	var vertical_distance := maxf(0.05, light_origin.y - caster_position.y)
	var caster_height := maxf(0.0, caster_position.y - surface.global_position.y)
	var approximate_shadow_length := caster_height * horizontal_distance / vertical_distance
	return _value_in_range(approximate_shadow_length, condition.get("length_range", [0.05, 1.5]) as Array)


func _is_reflection_condition_satisfied(condition: Dictionary) -> bool:
	var device := _find_light_device(String(condition.get("furniture_id", "")))
	if not is_instance_valid(device):
		return false
	return _value_in_range(device.get_effective_energy(), condition.get("energy_range", [0.05, 1.0]) as Array)


func _find_furniture(furniture_id: String) -> Node3D:
	for furniture: Node3D in furniture_nodes:
		if not is_instance_valid(furniture):
			continue
		if String(furniture.get_meta("furniture_id", furniture.get_meta("furniture_kind", ""))) == furniture_id:
			return furniture
	return null


func _find_light_device(furniture_id: String) -> CaseLightDevice:
	var furniture := _find_furniture(furniture_id)
	if not is_instance_valid(furniture):
		return null
	return furniture.find_child("CaseLightDevice", true, false) as CaseLightDevice


func _value_in_range(value: float, range_values: Array) -> bool:
	if range_values.size() < 2:
		return true
	return value >= float(range_values[0]) and value <= float(range_values[1])


func _get_case_manager() -> Node:
	return get_node_or_null("/root/CaseManager")
