extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	for case_id: String in ["office_case_001", "gallery_case_002"]:
		root.get_node("CaseManager").call("load_case", "res://data/cases/" + case_id + ".json")
		var scene := (load("res://scenes/main.tscn") as PackedScene).instantiate()
		root.add_child(scene)
		current_scene = scene
		await process_frame
		var flow: Node = scene.get("first_case_flow_ui") as Node
		flow.call("_on_accept_pressed")
		await create_timer(1.2).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/" + case_id + "_hud_paper.png")
		var manager := root.get_node("CaseManager")
		for evidence: Dictionary in manager.call("get_available_evidence"):
			manager.call("view_evidence", evidence.id)
		await process_frame
		await process_frame
		if case_id == "gallery_case_002":
			# Exercise the real unlock flow before checking the calibration panel.
			for step: int in range(32):
				(scene.get("case_file_ui") as CaseFileUI).close_files()
				(scene.get("scene_clue_popup") as SceneCluePopup).close()
				if not (scene.get("case_light_toggle_button") as Button).disabled:
					break
				scene.call("_debug_advance_next_step")
				for frame: int in range(180):
					await process_frame
					if not (scene.get("debug_hint_button") as Button).disabled and not bool(scene.get("camera_transitioning")):
						break
			scene.call("_toggle_case_light_editor")
			if not (scene.get("case_light_editor_panel") as Control).visible:
				push_error("Gallery calibration panel did not open")
				quit(1)
				return
		else:
			scene.call("_toggle_lighting_editor")
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/" + case_id + "_hud_controls.png")
		root.remove_child(scene)
		scene.free()
		await process_frame
	print("CASE_HUD_PAPER_OK")
	quit(0)
