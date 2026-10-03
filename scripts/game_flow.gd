extends Node


const STUDIO_SCENE := "res://scenes/studio/calibrator_studio.tscn"
const CASE_SCENE := "res://scenes/main.tscn"
const START_MENU_SCENE := "res://scenes/start_menu/start_menu_office.tscn"


func start_case(case_id: String) -> bool:
	var profile := get_node_or_null("/root/PlayerProfile")
	var case_manager := get_node_or_null("/root/CaseManager")
	if not is_instance_valid(profile) or not is_instance_valid(case_manager):
		return false
	var definition: Dictionary = profile.call("get_case_definition", case_id)
	var data_path := String(definition.get("data_path", ""))
	if data_path.is_empty() or not bool(case_manager.call("load_case", data_path)):
		return false
	profile.set("active_case_id", case_id)
	profile.call("save_profile")
	return await _transition(CASE_SCENE)


func return_to_studio() -> bool:
	return await _transition(STUDIO_SCENE)


func return_to_start_menu() -> bool:
	return await _transition(START_MENU_SCENE)


func reset_game_progress(return_to_start_menu := true, save_after := true) -> bool:
	var profile := get_node_or_null("/root/PlayerProfile")
	var case_manager := get_node_or_null("/root/CaseManager")
	var reconstruction_manager := get_node_or_null("/root/ReconstructionManager")
	if not is_instance_valid(profile) or not is_instance_valid(case_manager):
		return false
	if not bool(profile.call("reset_game_progress", save_after)):
		return false
	# Restore the default case data as well, so no clues from the last opened
	# case remain inside the Autoload after the profile has been wiped.
	if not bool(case_manager.call("load_case")):
		return false
	if is_instance_valid(reconstruction_manager):
		reconstruction_manager.call("reset_runtime_state")
	if return_to_start_menu:
		return await _transition(START_MENU_SCENE)
	return true


func _transition(path: String) -> bool:
	get_tree().paused = false
	var transition := get_node_or_null("/root/SceneTransition")
	if is_instance_valid(transition):
		return bool(await transition.call("transition_to_scene", path))
	return get_tree().change_scene_to_file(path) == OK
