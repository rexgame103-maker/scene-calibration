extends SceneTree
## Presentation captures in an isolated project/user directory. No scene files are edited.

const OUTPUT := "res://design/presentation/code/screenshots/"
var manager: Node

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1600, 900)
	root.get_node("GameLanguage").set_language("en")
	root.get_node("PlayerProfile").reset_profile(false)
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	manager = root.get_node("CaseManager")
	manager.load_case("res://data/cases/office_case_001.json")
	var office := load("res://scenes/main.tscn").instantiate() as Node3D
	root.add_child(office)
	current_scene = office
	await create_timer(0.4).timeout
	office.get("first_case_flow_ui").call("_on_accept_pressed")
	var files: Control = office.get("case_file_ui")
	files.debug_open_evidence("mail_photo_01")
	await create_timer(0.5).timeout
	await capture("evidence")
	files.close_files()
	var reconstruction := root.get_node("ReconstructionManager")
	for id: String in ["zone_desk_original", "zone_chair_at_desk", "zone_computer_on_desk"]:
		office.call("_debug_place_furniture_in_zone", reconstruction.get("zones")[id])
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
		push_error("Expected desk-side clue to be visible in the reachable inspection view")
		quit(1)
		return
	# Wait for the actual clue copy and collection button to finish revealing.
	await create_timer(5.0).timeout
	await capture("visible-clue")
	office.get("scene_clue_popup").close()
	office.queue_free()
	await process_frame
	await process_frame
	manager.load_case("res://data/cases/gallery_case_002.json")
	var restoration := load("res://scenes/main.tscn").instantiate() as Node3D
	root.add_child(restoration)
	current_scene = restoration
	await create_timer(0.4).timeout
	restoration.get("first_case_flow_ui").call("_on_accept_pressed")
	for iteration: int in range(50):
		if restoration.get("case_file_ui").visible:
			restoration.get("case_file_ui").close_files()
		var popup: Control = restoration.get("scene_clue_popup")
		if popup.visible:
			popup.get("point").collect_clue()
			popup.close()
		if bool(restoration.call("_debug_case_flow_finished")):
			break
		restoration.call("_debug_advance_next_step")
		for frame: int in range(180):
			await process_frame
			if not restoration.get("debug_hint_button").disabled and not restoration.get("camera_transitioning"):
				break
	if not bool(restoration.call("_debug_case_flow_finished")):
		push_error("Restoration case did not reach its validated final reconstruction")
		quit(1)
		return
	restoration.call("_focus_overview")
	await create_timer(0.9).timeout
	restoration.call("_toggle_case_light_editor")
	await create_timer(0.3).timeout
	await capture("reconstruction")
	restoration.queue_free()
	await process_frame
	await process_frame
	var desktop := load("res://scripts/studio_computer_ui.gd").new() as Control
	desktop.setup(root.get_node("PlayerProfile"))
	root.add_child(desktop)
	desktop.open_desktop()
	desktop.call("_show_app", "mail")
	await create_timer(0.5).timeout
	await capture("desktop")
	desktop.queue_free()
	root.get_node("GameAudio").stop_all()
	await process_frame
	print("CODE_PAGE_CAPTURES_OK: two formal cases and studio desktop; real visibility and final reconstruction checks")
	quit()

func capture(id: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT + id + ".png")
