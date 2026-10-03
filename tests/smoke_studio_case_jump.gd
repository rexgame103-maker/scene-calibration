extends SceneTree


var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	Engine.max_fps = 60
	root.size = Vector2i(1280, 720)
	var profile := root.get_node_or_null("PlayerProfile")
	var flow := root.get_node_or_null("GameFlow")
	var case_manager := root.get_node_or_null("CaseManager")
	_expect(is_instance_valid(profile) and is_instance_valid(flow) and is_instance_valid(case_manager), "Jump test requires campaign autoloads")
	if not failures.is_empty():
		_finish()
		return
	profile.call("reset_profile", false)
	var studio := (load("res://scenes/studio/calibrator_studio.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(studio)
	current_scene = studio
	await process_frame
	await process_frame

	var first_button := studio.find_child("DebugJumpFirstCaseButton", true, false) as Button
	_expect(is_instance_valid(first_button), "First-case jump button should exist")
	if is_instance_valid(first_button):
		first_button.pressed.emit()
		_expect(await _wait_for_case("office_case_001", case_manager), "First jump button should load office_case_001")

	if current_scene != null:
		_expect(bool(await flow.call("return_to_studio")), "Jump test should return to studio")
	await process_frame
	var second_studio := current_scene as Node3D
	var second_button := second_studio.find_child("DebugJumpSecondCaseButton", true, false) as Button if is_instance_valid(second_studio) else null
	_expect(is_instance_valid(second_button), "Second-case jump button should exist after returning")
	if is_instance_valid(second_button):
		second_button.pressed.emit()
		_expect(await _wait_for_case("gallery_case_002", case_manager), "Second jump button should load gallery_case_002")
	_finish()


func _wait_for_case(case_id: String, case_manager: Node) -> bool:
	for _frame_index: int in range(360):
		await process_frame
		var summary := case_manager.call("get_case_summary") as Dictionary
		var transition := root.get_node_or_null("SceneTransition")
		var transition_finished := not is_instance_valid(transition) or not bool(transition.get("is_transitioning"))
		if String(summary.get("case_id", "")) == case_id and is_instance_valid(current_scene) and current_scene.scene_file_path == "res://scenes/main.tscn" and transition_finished:
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures.append(message)
	push_error("STUDIO CASE JUMP SMOKE: %s" % message)


func _finish() -> void:
	if failures.is_empty():
		print("STUDIO_CASE_JUMP_SMOKE_OK")
		quit(0)
	else:
		print("STUDIO_CASE_JUMP_SMOKE_FAILED: %s" % [failures])
		quit(1)
