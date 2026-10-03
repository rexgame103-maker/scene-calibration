extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(1536,864)
	root.msaa_3d=Viewport.MSAA_4X
	var menu := (load("res://scenes/start_menu/start_menu_office.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	current_scene=menu
	await create_timer(1.1).timeout
	assert(menu.has_node("StudioBackground/InvestigationDesk"))
	assert(menu.get_node("StartCamera").current)
	var buttons := menu.get_node("StartMenuUI/UIRoot/MenuLayout/MenuColumn")
	assert(buttons.get_child_count()==4)
	assert(buttons.get_node("StartButton").text=="开始游戏")
	for name in ["face","ink","title","button"]:
		var asset := (load("res://assets/ui/the_scene_menu/"+name+".png") as Texture2D).get_image()
		assert(asset.detect_alpha()!=Image.ALPHA_NONE)
	menu.set("camera_motion_enabled",false)
	menu.set("motion_time",0.0)
	menu.call("update_camera",0.0)
	var far: Vector3 = menu.get_node("StartCamera").position
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/the_scene_menu_far.png")
	var cycle: float = menu.get("travel_cycle_seconds")
	menu.set("motion_time",cycle*0.5)
	menu.call("update_camera",cycle*0.5)
	var near: Vector3 = menu.get_node("StartCamera").position
	assert(far.distance_to(near)>0.8)
	for i in 101:
		menu.call("update_camera",float(i)*cycle/100)
		var distance: float = menu.get_node("StartCamera").position.distance_to(menu.get("camera_target"))
		assert(distance>=menu.get("nearest_distance")-0.2 and distance<=menu.get("farthest_distance")+0.2)
	menu.call("update_camera",cycle*0.5)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/the_scene_menu_near.png")
	buttons.get_node("SettingsButton").pressed.emit()
	assert(menu.get_node("StartMenuUI/UIRoot/Settings").visible)
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
	# Exercise entry without invoking the destructive new-game confirmation.
	menu.call("_enter_studio")
	await process_frame
	assert(buttons.get_node("StartButton").disabled and buttons.get_node("ContinueButton").disabled)
	await create_timer(1.1).timeout
	assert(current_scene.scene_file_path=="res://scenes/studio/calibrator_studio.tscn")
	print("THE_SCENE_MENU_OK: alpha assets, live studio, bounded camera cycle, settings, transition")
	quit()
