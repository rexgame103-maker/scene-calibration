extends SceneTree


const OFFICE_CASE_PATH := "res://data/cases/office_case_001.json"
const MAIL_OUTPUT := "res://assets/case_photos/office/mail_photo_01.png"
const PRINTER_OUTPUT := "res://assets/case_photos/office/printer_layout_photo.png"

var office_scene: Node3D
var camera: Camera3D


func _init() -> void:
	call_deferred("_render_all")


func _render_all() -> void:
	Engine.max_fps = 60
	root.size = Vector2i(960, 600)
	var case_manager := root.get_node_or_null("CaseManager")
	if not is_instance_valid(case_manager) or not bool(case_manager.call("load_case", OFFICE_CASE_PATH)):
		push_error("Could not load the office case for evidence rendering")
		quit(1)
		return
	office_scene = (load("res://scenes/main.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(office_scene)
	current_scene = office_scene
	await process_frame
	await physics_frame
	if not await _complete_office_with_debug():
		quit(1)
		return
	_hide_runtime_ui()
	camera = office_scene.get_node_or_null("IsometricCamera") as Camera3D
	if not is_instance_valid(camera):
		push_error("Office evidence camera is missing")
		quit(1)
		return
	camera.current = true
	camera.near = 0.05

	# The first mail attachment concentrates on the workstation.  The cabinet
	# side remains outside the frame, matching the written evidence description.
	_set_photo_subjects(["desk", "office_chair", "office_computer"])
	_set_camera(Vector3(1.65, 2.75, 1.55), Vector3(-0.70, 1.02, -1.72), 29.0)
	if not await _capture(MAIL_OUTPUT):
		quit(1)
		return

	# The later printer photo is a tighter archival shot of the equipment wall,
	# shelf tiers and neighbouring water dispenser.
	_set_photo_subjects(["file_shelf", "water_dispenser", "red_case_file", "gray_case_file", "ordinary_file_01"])
	_set_camera(Vector3(1.55, 4.75, 4.45), Vector3(-2.15, 1.50, 0.65), 25.0)
	if not await _capture(PRINTER_OUTPUT):
		quit(1)
		return
	quit(0)


func _complete_office_with_debug() -> bool:
	var flow := office_scene.get("first_case_flow_ui") as FirstCaseFlowUI
	if not is_instance_valid(flow):
		push_error("Office briefing UI is unavailable")
		return false
	flow.call("_on_accept_pressed")
	await process_frame
	for _press_index: int in range(36):
		var case_file_ui := office_scene.get("case_file_ui") as CaseFileUI
		var clue_popup := office_scene.get("scene_clue_popup") as SceneCluePopup
		if is_instance_valid(case_file_ui) and case_file_ui.visible:
			case_file_ui.close_files()
		if is_instance_valid(clue_popup) and clue_popup.visible:
			clue_popup.close()
		if bool(office_scene.call("_debug_case_flow_finished")):
			return true
		office_scene.call("_debug_advance_next_step")
		if not await _wait_for_debug_action():
			return false
	push_error("Office evidence render could not complete the reconstruction")
	return false


func _wait_for_debug_action() -> bool:
	for _frame_index: int in range(360):
		await process_frame
		var button := office_scene.get("debug_hint_button") as Button
		if is_instance_valid(button) and not button.disabled and not bool(office_scene.get("camera_transitioning")):
			return true
	push_error("Office evidence DEBUG action timed out")
	return false


func _hide_runtime_ui() -> void:
	for child: Node in office_scene.get_children():
		if child is CanvasLayer:
			(child as CanvasLayer).visible = false
	var hand_drawn := office_scene.get_node_or_null("HandDrawnPostProcess") as CanvasLayer
	if is_instance_valid(hand_drawn):
		hand_drawn.visible = false


func _set_camera(camera_position: Vector3, target: Vector3, fov: float) -> void:
	camera.global_position = camera_position
	camera.fov = fov
	camera.look_at(target, Vector3.UP)


func _set_photo_subjects(visible_furniture_ids: Array[String]) -> void:
	for entry_value: Variant in office_scene.get("placed_items") as Array:
		if not entry_value is Dictionary:
			continue
		var entry := entry_value as Dictionary
		var furniture := entry.get("node", null) as Node3D
		if not is_instance_valid(furniture):
			continue
		var furniture_id := String(entry.get("furniture_id", ""))
		if furniture_id.is_empty():
			furniture_id = String(furniture.get_meta("furniture_id", ""))
		furniture.visible = visible_furniture_ids.has(furniture_id)


func _capture(output_path: String) -> bool:
	for _frame: int in range(12):
		await process_frame
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("Office evidence render returned an empty image: %s" % output_path)
		return false
	var result := image.save_png(output_path)
	if result != OK:
		push_error("Could not save office evidence image: %s" % output_path)
		return false
	print("RENDERED_OFFICE_EVIDENCE ", output_path)
	return true
