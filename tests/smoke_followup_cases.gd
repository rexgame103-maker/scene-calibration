extends SceneTree


var failures: Array[String] = []
var case_manager: Node
var reconstruction_manager: Node


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	case_manager = root.get_node_or_null("CaseManager")
	reconstruction_manager = root.get_node_or_null("ReconstructionManager")
	for case_path: String in ["res://data/cases/gallery_case_002.json", "res://data/cases/apartment_case_003.json"]:
		_expect(bool(case_manager.call("load_case", case_path)), "Case should load: %s" % case_path)
		await process_frame
		var scene := (load("res://scenes/main.tscn") as PackedScene).instantiate() as Node3D
		root.add_child(scene)
		current_scene = scene
		await process_frame
		await physics_frame
		var flow := scene.get("first_case_flow_ui") as FirstCaseFlowUI
		flow.call("_on_accept_pressed")
		for press_index: int in range(40):
			var case_file_ui := scene.get("case_file_ui") as CaseFileUI
			var scene_clue_popup := scene.get("scene_clue_popup") as SceneCluePopup
			if case_file_ui.visible:
				case_file_ui.close_files()
			if scene_clue_popup.visible:
				scene_clue_popup.close()
			if bool(scene.call("_debug_case_flow_finished")):
				break
			scene.call("_debug_advance_next_step")
			await _wait_for_debug_action(scene)
		var completion := case_manager.call("get_completion_data") as Dictionary
		var required_step := String(completion.get("required_reconstruction_step_id", ""))
		_expect(bool(reconstruction_manager.call("is_step_satisfied", required_step)), "%s should satisfy its final step" % String((case_manager.call("get_case_summary") as Dictionary).get("case_id", "")))
		scene.call("_submit_first_case_reconstruction")
		_expect(flow.settlement_panel.visible, "Follow-up case should open settlement")
		root.remove_child(scene)
		scene.free()
		await process_frame
	_finish()


func _wait_for_debug_action(scene: Node) -> void:
	for frame_index: int in range(180):
		await process_frame
		var button := scene.get("debug_hint_button") as Button
		if is_instance_valid(button) and not button.disabled and not bool(scene.get("camera_transitioning")):
			return
	_expect(false, "Follow-up DEBUG action timed out")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("FOLLOWUP SMOKE: %s" % message)


func _finish() -> void:
	if failures.is_empty():
		print("FOLLOWUP_CASES_SMOKE_OK")
		quit(0)
	else:
		print("FOLLOWUP_CASES_SMOKE_FAILED: %s" % [failures])
		quit(1)
