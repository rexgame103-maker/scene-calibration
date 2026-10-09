extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var computer := StudioComputerUI.new()
	computer.setup(root.get_node("PlayerProfile"))
	root.add_child(computer)
	await process_frame
	computer.open_desktop()
	computer.call("_open_app", "mail")
	await process_frame
	await process_frame
	var mail_dock := computer.find_child("MailDockButton", true, false) as Button
	var debug_money := computer.find_child("ComputerDebugAddMoneyButton", true, false) as Button
	assert(is_instance_valid(mail_dock))
	assert(is_instance_valid(debug_money))
	assert((debug_money.get_theme_stylebox("normal") as StyleBoxTexture).texture is AtlasTexture)
	var dock_icon := mail_dock.get_node("Icon") as TextureRect
	var window_icon := computer.find_child("WindowAppIcon", true, false) as TextureRect
	assert(not dock_icon.texture is AtlasTexture)
	assert(dock_icon.texture.get_size() == Vector2(256, 256))
	assert(window_icon.texture == dock_icon.texture)
	var expected_titles := {
		"album": "现场相册",
		"shop": "设备商店",
		"cases": "案件索引",
		"minigame": "小游戏 / 信号校准",
		"system": "系统工具",
		"mail": "邮箱",
	}
	for app_id: String in expected_titles:
		computer.call("_show_app", app_id)
		await process_frame
		assert((computer.get("_title") as Label).text == expected_titles[app_id])
	await create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	screenshot.save_png("res://tests/computer_terminal_ui_preview.png")
	print("COMPUTER_TERMINAL_UI_RENDER_OK")
	quit(0)
