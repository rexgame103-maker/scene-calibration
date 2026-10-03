extends SceneTree


var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var profile := root.get_node_or_null("PlayerProfile")
	var case_manager := root.get_node_or_null("CaseManager")
	var game_flow := root.get_node_or_null("GameFlow")

	profile.set("money", 9999)
	profile.set("studio_tier", 3)
	profile.set("studio_rooms", {"0": 4, "1": 4})
	profile.set("completed_cases", {"office_case_001": true})
	profile.set("album_entries", [{"case_id":"office_case_001"}])
	profile.set("placed_studio_layout", [{"kind":"studio_desk"}])
	profile.set("active_case_id", "office_case_001")
	_expect(bool(await game_flow.call("reset_game_progress", false, false)), "Global reset should succeed without changing scenes")
	_expect(int(profile.get("money")) == 700, "Global reset should restore starting money")
	_expect(int(profile.get("studio_tier")) == 1, "Global reset should restore the first studio tier")
	_expect(int(profile.call("get_studio_room_count", 0)) == 1, "Global reset should restore one first-floor room")
	_expect(int(profile.call("get_studio_room_count", 1)) == 0, "Global reset should remove the second floor")
	_expect((profile.get("completed_cases") as Dictionary).is_empty(), "Global reset should clear completed cases")
	_expect((profile.get("album_entries") as Array).is_empty(), "Global reset should clear album records")
	_expect((profile.get("placed_studio_layout") as Array).is_empty(), "Global reset should clear the studio layout")
	_expect(String(profile.get("active_case_id")).is_empty(), "Global reset should clear the active case")
	_expect(String((case_manager.call("get_case_summary") as Dictionary).get("case_id", "")) == "office_case_001", "Global reset should restore default case data")

	var start_scene := (load("res://scenes/start_menu/start_menu_office.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(start_scene)
	await process_frame
	var start_reset := start_scene.get_node_or_null("StartMenuUI/UIRoot/ResetGameButton") as Button
	_expect(is_instance_valid(start_reset), "Start menu should expose the global reset button")
	start_scene.call("_open_reset_confirmation")
	var start_overlay := start_scene.get("_reset_overlay") as Control
	_expect(is_instance_valid(start_overlay) and start_overlay.visible, "Start menu reset should require confirmation")
	start_scene.call("_close_reset_confirmation")
	root.remove_child(start_scene)
	start_scene.free()
	await process_frame

	# Completed cases remain replayable without granting their reward twice.
	profile.set("completed_cases", {"office_case_001": true})
	profile.set("active_case_id", "office_case_001")
	var money_before := int(profile.get("money"))
	profile.call("complete_case", "office_case_001", "", false)
	_expect(int(profile.get("money")) == money_before, "Replay completion should not grant duplicate money")
	_expect(String(profile.get("active_case_id")).is_empty(), "Replay completion should close the active case session")

	var computer := StudioComputerUI.new()
	computer.setup(profile)
	root.add_child(computer)
	await process_frame
	computer.open_desktop()
	computer.call("_show_app", "mail")
	await process_frame
	_expect(_has_button_text(computer, "重新调查"), "Completed case mail should offer replay")
	computer.call("_show_app", "cases")
	await process_frame
	_expect(_has_button_text(computer, "重新进入现场（无重复奖励）"), "Case index should offer replay without a furniture skill")
	computer.call("_show_app", "system")
	await process_frame
	_expect(_has_button_text(computer, "重置全部游戏进度"), "Studio computer system tools should expose global reset")
	root.remove_child(computer)
	computer.free()
	await process_frame

	var main_scene := (load("res://scenes/main.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(main_scene)
	await process_frame
	await physics_frame
	_expect(main_scene.find_child("ResetCaseButton", true, false) == null, "Case HUD should not contain a per-level reset button")
	var rotation_overlay := main_scene.get("rotation_mode_overlay") as Control
	var flow_ui := main_scene.get("first_case_flow_ui") as FirstCaseFlowUI
	var files_ui := main_scene.get("case_file_ui") as CaseFileUI
	var clue_popup := main_scene.get("scene_clue_popup") as SceneCluePopup
	_expect(rotation_overlay.z_index < flow_ui.z_index, "Case modal should cover rotation controls")
	_expect(flow_ui.z_index < files_ui.z_index, "Case files should cover ordinary case-flow buttons")
	_expect(files_ui.z_index < clue_popup.z_index, "Scene clue popup should be the highest case content modal")
	root.remove_child(main_scene)
	main_scene.free()
	await process_frame

	_finish()


func _has_button_text(node: Node, expected_text: String) -> bool:
	if node is Button and (node as Button).text == expected_text:
		return true
	for child: Node in node.get_children():
		if _has_button_text(child, expected_text):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures.append(message)
	push_error("GLOBAL RESET REPLAY SMOKE: %s" % message)


func _finish() -> void:
	if failures.is_empty():
		print("GLOBAL_RESET_REPLAY_SMOKE_OK")
		quit(0)
	else:
		print("GLOBAL_RESET_REPLAY_SMOKE_FAILED: %s" % [failures])
		quit(1)
