extends SceneTree
## Capture the editor-authored menu camera without UI for the newspaper cover.

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(1920, 1080)
	root.msaa_3d = Viewport.MSAA_4X
	var menu := (load("res://scenes/start_menu/start_menu_office.tscn") as PackedScene).instantiate() as Node3D
	var camera := menu.get_node("StartCamera") as Camera3D
	var authored_transform := camera.transform
	root.add_child(menu)
	current_scene = menu
	menu.set_process(false)
	menu.set("camera_motion_enabled", false)
	menu.call("update_camera", 0.0)
	camera.make_current()
	menu.get_node("StartMenuUI").hide()
	await create_timer(1.2).timeout
	await RenderingServer.frame_post_draw
	var destination := "res://design/cover/start-camera-clean.png"
	var result := root.get_texture().get_image().save_png(destination)
	if result != OK or not camera.transform.is_equal_approx(authored_transform):
		push_error("The cover camera capture failed or changed the authored framing.")
		quit(1)
		return
	print("COVER_CAMERA_CAPTURED: %s, authored transform retained, FOV %.1f" % [destination, camera.fov])
	root.get_node("GameAudio").call("stop_all")
	menu.queue_free()
	await process_frame
	await process_frame
	quit(0)
