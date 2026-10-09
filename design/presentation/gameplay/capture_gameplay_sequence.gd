extends SceneTree
## Actual runtime captures. Run in an isolated user directory, never a player save.

const OUTPUT := "res://design/presentation/gameplay/screenshots/"
var manager: Node
var profile: Node
var captures: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1600, 900)
	root.get_node("GameLanguage").set_language("en")
	profile = root.get_node("PlayerProfile")
	profile.reset_profile(false)
	manager = root.get_node("CaseManager")
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var studio := load("res://scenes/studio/calibrator_studio.tscn").instantiate() as Node3D
	root.add_child(studio)
	current_scene = studio
	await create_timer(0.9).timeout
	await capture("studio", "Player studio: the investigation hub")
	var desktop: Control = studio.get("computer_ui")
	desktop.open_desktop()
	desktop.call("_show_app", "mail")
	await create_timer(0.5).timeout
	await capture("mail", "01: read and accept the office assignment")
	var office_mail := String(profile.get_available_mail()[0].mail_id)
	profile.accept_mail(office_mail)
	if not await root.get_node("GameFlow").start_case("office_case_001"):
		fail("Office assignment failed to start")
		return
	var office := current_scene as Node3D
	await create_timer(0.5).timeout
	await capture("briefing", "Office briefing after accepting the assignment")
	office.get("first_case_flow_ui").call("_on_accept_pressed")
	office.get("case_file_ui").debug_open_evidence("mail_photo_01")
	await create_timer(0.4).timeout
	await capture("evidence", "02: photograph reveals three clues and furniture")
	office.get("case_file_ui").close_files()
	var reconstruction := root.get_node("ReconstructionManager")
	office.call("_debug_place_furniture_in_zone", reconstruction.zones["zone_desk_original"])
	office.call("_begin_placement", "chair")
	# Use the normal pointer projection and placement validator for the preview.
	var chair_zone: Node3D = reconstruction.zones["zone_chair_at_desk"]
	var camera: Camera3D = office.get("camera")
	var pointer := camera.unproject_position(Vector3(chair_zone.global_position.x, 0.0, chair_zone.global_position.z))
	Input.warp_mouse(pointer)
	await process_frame
	var motion := InputEventMouseMotion.new()
	motion.position = pointer
	root.push_input(motion, true)
	await process_frame
	office.call("_update_active_preview")
	# The capture window is off-screen, so OS pointer warping can be clamped.
	# Stage the preview at the authored position but retain the real validator.
	office.set_process(false)
	var chair_info: Dictionary = office.call("_furniture_info", "chair")
	var chair_size: Vector3 = chair_info.size
	var chair_rotation := Vector3.ZERO
	chair_rotation.y = chair_zone.global_rotation_degrees.y + chair_zone.target_yaw_degrees
	var chair_origin := chair_zone.global_position
	var preview: Node3D = office.get("active_preview")
	preview.rotation_degrees = chair_rotation
	preview.global_position = Vector3(chair_origin.x, float(office.call("_ground_offset_for_rotation", chair_size, chair_rotation)) + 0.045, chair_origin.z)
	preview.show()
	var bounds: Vector2 = office.call("_projected_bounds_size", chair_size, chair_rotation)
	var offset: Vector2 = office.call("_projected_bounds_offset", chair_size, chair_rotation)
	office.set("preview_rotation_degrees", chair_rotation)
	office.set("preview_bounds_size", bounds)
	office.set("preview_bounds_offset", offset)
	office.set("preview_surface_height", 0.0)
	office.set("preview_support_node", null)
	var valid := bool(office.call("_can_place_at", chair_origin, bounds, offset))
	if not valid:
		fail("Staged chair preview failed the normal placement validator")
		return
	office.set("placement_valid", valid)
	office.set("_has_preview_tint", false)
	office.call("_update_preview_bounds_marker", chair_origin)
	office.call("_update_preview_tint", valid)
	office.call("_set_drag_status", "Q/E 每次旋转 90° · 松开放置并启用重力", Color("98e3b4"))
	await capture("placement", "03: staged chair preview passes the normal bounds and overlap validator")
	office.call("_cancel_placement", false)
	office.set_process(true)
	for id: String in ["zone_chair_at_desk", "zone_computer_on_desk"]:
		office.call("_debug_place_furniture_in_zone", reconstruction.zones[id])
	var desk := office.call("_debug_find_placed_furniture_by_id", "desk") as Node3D
	office.call("_select_item", office.call("_find_entry_by_node", desk))
	office.call("_focus_selected_furniture")
	await create_timer(0.9).timeout
	office.set("focus_target_yaw", 45.0)
	office.set("focus_target_pitch", -22.0)
	office.call("_update_focus_camera", 10.0)
	await process_frame
	await physics_frame
	var point := desk.get_node("DeskSideWearClue") as SceneCluePoint
	if not point.investigate():
		fail("Desk-side clue did not pass the camera visibility gate")
		return
	await create_timer(5.0).timeout
	await capture("inspection", "04: visible desk-side wear is investigated and collected")
	point.collect_clue()
	office.get("scene_clue_popup").close()
	await create_timer(0.5).timeout
	if not await complete_runtime_case(office):
		fail("Office did not satisfy its actual final reconstruction")
		return
	office.call("_focus_overview")
	await create_timer(0.9).timeout
	await capture("office-restored-ui", "Office restored: full gameplay interface")
	# The hero retains game geometry/materials/lighting. Only the HUD is hidden.
	office.get("ui_root").hide()
	await capture("office-restored", "Restored office hero: same runtime camera with HUD hidden")
	office.get("ui_root").show()
	office.call("_submit_first_case_reconstruction")
	await create_timer(0.4).timeout
	if not office.get("first_case_flow_ui").settlement_panel.visible:
		fail("Valid office reconstruction did not open its settlement")
		return
	await capture("settlement", "06: submit the reconstruction and receive the case conclusion")
	await office.call("_capture_and_archive_case")
	await create_timer(0.3).timeout
	if not bool(profile.completed_cases.get("office_case_001", false)) or profile.album_entries.is_empty():
		fail("Office photograph and completion were not archived")
		return
	if not await root.get_node("GameFlow").return_to_studio():
		fail("Returning to studio failed")
		return
	studio = current_scene
	await create_timer(0.5).timeout
	desktop = studio.get("computer_ui")
	desktop.open_desktop()
	desktop.call("_show_app", "album")
	await create_timer(0.4).timeout
	await capture("album", "07: restored photograph appears in the studio album")
	if not await root.get_node("GameFlow").start_case("gallery_case_002"):
		fail("Restoration room failed to start")
		return
	var restoration := current_scene as Node3D
	await create_timer(0.4).timeout
	restoration.get("first_case_flow_ui").call("_on_accept_pressed")
	if not await complete_runtime_case(restoration):
		fail("Restoration room did not satisfy its actual final reconstruction")
		return
	restoration.call("_focus_overview")
	await create_timer(0.9).timeout
	restoration.call("_toggle_case_light_editor")
	await create_timer(0.4).timeout
	await capture("calibration", "05: restoration room light, color temperature and shadow calibration")
	var manifest := FileAccess.open("res://design/presentation/gameplay/capture-manifest.json", FileAccess.WRITE)
	manifest.store_string(JSON.stringify({"engine": Engine.get_version_info().string, "resolution": [1600, 900], "captures": captures, "method": "Fresh Godot runtime captures in an isolated profile. Existing debug helpers stage placement and calibration; real visibility, reconstruction, submission and album checks remain active. Hero capture hides only the HUD."}, "\t"))
	root.get_node("GameAudio").stop_all()
	await process_frame
	print("GAMEPLAY_SEQUENCE_CAPTURES_OK: two formal cases; actual visibility, submission, photo archive and studio return verified")
	quit()

func complete_runtime_case(scene: Node3D) -> bool:
	for iteration: int in range(60):
		if scene.get("case_file_ui").visible:
			scene.get("case_file_ui").close_files()
		var popup: Control = scene.get("scene_clue_popup")
		if popup.visible:
			popup.get("point").collect_clue()
			popup.close()
			await create_timer(0.46).timeout
		if bool(scene.call("_debug_case_flow_finished")):
			return true
		scene.call("_debug_advance_next_step")
		for frame: int in range(180):
			await process_frame
			if not scene.get("debug_hint_button").disabled and not scene.get("camera_transitioning"):
				break
	return bool(scene.call("_debug_case_flow_finished"))

func capture(id: String, state: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image.save_png(OUTPUT + id + ".png") != OK:
		fail("Cannot save capture " + id)
		return
	captures.append({"image": "screenshots/" + id + ".png", "state": state, "case_id": String(manager.get_case_summary().get("case_id", ""))})
	print("CAPTURED ", id)

func fail(message: String) -> void:
	push_error(message)
	root.get_node("GameAudio").stop_all()
	quit(1)
