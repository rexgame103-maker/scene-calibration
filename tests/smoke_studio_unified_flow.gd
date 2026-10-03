extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var packed := load("res://scenes/studio/calibrator_studio.tscn") as PackedScene
	var studio := packed.instantiate()
	root.add_child(studio)
	current_scene = studio
	await process_frame
	await process_frame

	var failures: Array[String] = []
	var hud := studio.get_node_or_null("StudioUI/UIRoot/StudioHUD") as Control
	var ui_root := studio.get_node_or_null("StudioUI/UIRoot") as Control
	var computer_ui := ui_root.get_node_or_null("StudioComputerUI") as Control
	if not is_instance_valid(hud) or not hud.visible:
		failures.append("studio HUD missing")
	if not is_instance_valid(studio.get("catalog_panel")):
		failures.append("right catalog missing")
	else:
		var catalog_panel := studio.get("catalog_panel") as PanelContainer
		if catalog_panel.anchor_left < 0.99:
			failures.append("catalog is not right aligned")
	var first_case_jump := studio.find_child("DebugJumpFirstCaseButton", true, false) as Button
	var second_case_jump := studio.find_child("DebugJumpSecondCaseButton", true, false) as Button
	if not is_instance_valid(first_case_jump) or String(first_case_jump.get_meta("case_id", "")) != "office_case_001":
		failures.append("first-case debug jump button is missing or targets the wrong case")
	if not is_instance_valid(second_case_jump) or String(second_case_jump.get_meta("case_id", "")) != "gallery_case_002":
		failures.append("second-case debug jump button is missing or targets the wrong case")

	var furniture_root := studio.get_node_or_null("StudioFurniture")
	var desk: Node3D
	var computer: Node3D
	for child: Node in furniture_root.get_children():
		if child is Node3D:
			match String(child.get_meta("studio_kind", "")):
				"studio_desk": desk = child as Node3D
				"studio_computer": computer = child as Node3D
	if is_instance_valid(computer):
		if not is_instance_valid(desk):
			failures.append("computer has no desk")
		elif String(computer.get_meta("support_uid", "")).is_empty():
			failures.append("computer is not attached to desk")
		elif absf(computer.global_position.y - desk.to_global(Vector3(0, 1.21, 0)).y) > 0.02:
			failures.append("computer is floating")
	for child: Node in furniture_root.get_children():
		if not child is Node3D:
			continue
		var node := child as Node3D
		var info := StudioFurnitureFactory.get_info(String(node.get_meta("studio_kind", "")))
		var projected := studio.call("_projected_box", info.size, node.rotation_degrees) as Dictionary
		if not bool(studio.call("_inside_floor", node.global_position, projected, int(node.get_meta("studio_floor", 0)))):
			failures.append("furniture remains outside room: %s" % String(node.get_meta("studio_kind", "")))

	computer_ui.call("open_desktop")
	await process_frame
	if hud.visible:
		failures.append("studio HUD remains visible over desktop")
	var has_continue := _find_button_text(computer_ui, "继续委托")
	var has_accept := _find_button_text(computer_ui, "接取委托")
	if not has_continue and not has_accept:
		failures.append("mail has no case entry button")
	computer_ui.call("close_desktop")
	await process_frame
	if not hud.visible:
		failures.append("studio HUD did not restore")

	if failures.is_empty():
		print("STUDIO_UNIFIED_FLOW_SMOKE_OK")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)


func _find_button_text(root_node: Node, text_value: String) -> bool:
	for child: Node in root_node.get_children():
		if child is Button and (child as Button).text == text_value:
			return true
		if _find_button_text(child, text_value):
			return true
	return false
