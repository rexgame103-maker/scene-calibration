extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(1280,720)
	root.msaa_3d=Viewport.MSAA_4X
	await check_edited_camera()
	var menu := (load("res://scenes/start_menu/start_menu_office.tscn") as PackedScene).instantiate()
	var camera := menu.get_node("StartCamera") as Camera3D
	var authored_transform := camera.transform
	var authored_fov := camera.fov
	root.add_child(menu)
	current_scene=menu
	assert(camera.transform.is_equal_approx(authored_transform))
	await create_timer(1.1).timeout
	assert(menu.has_node("StudioBackground/InvestigationDesk"))
	assert(menu.get_node("StartCamera").current)
	var buttons := menu.get_node("StartMenuUI/UIRoot/MenuLayout/MenuColumn")
	assert(buttons.get_child_count()==4)
	assert(buttons.get_node("StartButton").text=="开始游戏")
	assert(not menu.has_node("StartMenuUI/UIRoot/Portrait"))
	for removed in ["WindowCurtain", "WindowExterior", "WindowDaylight"]:
		assert(not menu.has_node(removed))
	assert(menu.get_node("StudioBackground/WindowLightMist").visible)
	assert(menu.get_node("StudioBackground/Architecture/NorthWindow/BlueGlass").material_override is ShaderMaterial)
	assert(not camera.transform.is_equal_approx(authored_transform))
	menu.set("camera_motion_enabled", false)
	await process_frame
	await process_frame
	assert(camera.transform.is_equal_approx(authored_transform))
	menu.set("camera_motion_enabled", true)
	# Sample fixed motion times without the frame callback advancing them.
	menu.set_process(false)
	menu.call("update_camera",0.0)
	assert(camera.transform.is_equal_approx(authored_transform))
	var far := camera.position
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/start_menu_window_far.png")
	var cycle: float = menu.get("travel_cycle_seconds")
	menu.call("update_camera",cycle*0.5)
	var near := camera.position
	var push_distance: float = menu.get("loop_push_in_distance")
	assert(is_equal_approx((near-far).dot(-authored_transform.basis.z), push_distance))
	assert(not camera.basis.is_equal_approx(authored_transform.basis))
	for i in 1001:
		menu.call("update_camera",float(i)*cycle/100)
		var relative := authored_transform.affine_inverse()*camera.transform
		assert(relative.origin.z>=-push_distance-0.0001 and relative.origin.z<=0.0001)
		assert(absf(relative.origin.x)<=menu.get("sway_distance")+0.0001)
		assert(absf(relative.origin.y)<=menu.get("sway_distance")*0.48+0.0001)
		assert(relative.basis.get_rotation_quaternion().angle_to(Quaternion.IDENTITY)<deg_to_rad(1.0))
		assert(camera.fov==authored_fov)
	# Returning at the loop boundary must not jump or reset the sway.
	menu.call("update_camera",cycle-0.001)
	var before_boundary := camera.transform
	menu.call("update_camera",cycle+0.001)
	assert(camera.position.distance_to(before_boundary.origin)<0.001)
	assert(camera.quaternion.angle_to(before_boundary.basis.get_rotation_quaternion())<0.001)
	menu.call("update_camera",cycle*0.5)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/start_menu_window_near.png")
	buttons.get_node("SettingsButton").pressed.emit()
	assert(menu.get_node("StartMenuUI/UIRoot/Settings").visible)
	var movement := menu.get_node("StartMenuUI/UIRoot/Settings/Panel/Margin/Column/CameraMotion") as CheckButton
	movement.button_pressed=false
	assert(camera.transform.is_equal_approx(authored_transform))
	movement.button_pressed=true
	assert(camera.transform.is_equal_approx(authored_transform))
	menu.get_node("StartMenuUI/UIRoot/Settings/Panel/Margin/Column/Close").pressed.emit()
	assert(not menu.get_node("StartMenuUI/UIRoot/Settings").visible)
	assert(not root.get_node("PauseMenu").call("open_pause_menu"))
	if menu.call("_has_save"):
		var before := FileAccess.get_file_as_string("user://calibrator_profile.json")
		buttons.get_node("StartButton").pressed.emit()
		assert(menu.get("_reset_overlay").visible)
		menu.call("_close_reset_confirmation")
		assert(FileAccess.get_file_as_string("user://calibrator_profile.json")==before)
	root.size=Vector2i(960,720)
	await process_frame
	menu.call("_layout")
	var ui: Control = menu.get_node("StartMenuUI/UIRoot")
	var visible_size := root.get_visible_rect().size
	assert(ui.position.x>=-0.01 and ui.position.y>=-0.01)
	assert(ui.position.x+1280*ui.scale.x<=visible_size.x+0.1)
	assert(ui.position.y+720*ui.scale.y<=visible_size.y+0.1)
	menu.set("fade_out_duration",0.2)
	menu.set("fade_in_duration",0.1)
	menu.set_process(true)
	# Once entry starts, background motion must yield the camera to the tween.
	menu.set("_starting_game",true)
	var entry_pose := camera.transform
	menu.call("_process",10.0)
	assert(camera.transform.is_equal_approx(entry_pose))
	menu.set("_starting_game",false)
	# Exercise entry without invoking the destructive new-game confirmation.
	menu.call("_enter_studio")
	await process_frame
	assert(buttons.get_node("StartButton").disabled and buttons.get_node("ContinueButton").disabled)
	await create_timer(1.1).timeout
	assert(current_scene.scene_file_path=="res://scenes/studio/calibrator_studio.tscn")
	print("THE_SCENE_MENU_OK: authored camera pose/FOV, local sway and slow push, smooth bounded loop, motion setting, layout, transition")
	root.get_node("GameAudio").call("stop_all")
	current_scene.queue_free()
	await process_frame
	await process_frame
	await create_timer(0.15).timeout
	quit()

func check_edited_camera() -> void:
	# Simulate saving another position and angle in the editor before startup.
	var menu := (load("res://scenes/start_menu/start_menu_office.tscn") as PackedScene).instantiate()
	var camera := menu.get_node("StartCamera") as Camera3D
	var edited_pose := Transform3D(Basis.from_euler(Vector3(-0.23, 1.12, 0.04)), Vector3(1.5, 2.8, 3.7))
	camera.transform=edited_pose
	camera.fov=51.0
	menu.transform=Transform3D(Basis.from_euler(Vector3(0.0, 0.35, 0.0)), Vector3(2.0, 0.0, -1.0))
	menu.camera_motion_enabled=false
	root.add_child(menu)
	assert(camera.transform.is_equal_approx(edited_pose))
	await process_frame
	assert(camera.transform.is_equal_approx(edited_pose))
	menu.camera_motion_enabled=true
	menu.call("update_camera",menu.travel_cycle_seconds*0.25)
	var relative := edited_pose.affine_inverse()*camera.transform
	assert(is_equal_approx(relative.origin.z,-menu.loop_push_in_distance*0.5))
	assert(camera.fov==51.0)
	menu.camera_motion_enabled=false
	menu.call("update_camera",10.0)
	assert(camera.transform.is_equal_approx(edited_pose))
	menu.queue_free()
	await process_frame
	await process_frame
