extends SceneTree

var failures: Array[String] = []
var computer: Control
var profile: Node

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280, 720)
	profile = root.get_node("PlayerProfile")
	computer = load("res://scripts/studio_computer_ui.gd").new()
	computer.setup(profile)
	root.add_child(computer)
	computer.open_desktop()
	await create_timer(1.0).timeout
	await open_app("album")
	check(find_label("尚无完成现场。结案后拍摄的复原照片会保存在这里。") != null, "Album explains its empty state")
	var photo := load("res://assets/case_photos/office/mail_photo_01.png") as Texture2D
	photo.get_image().save_png("user://terminal_test_album.png")
	profile.complete_case("office_case_001", "user://terminal_test_album.png", false)
	for mail: Dictionary in profile.get_available_mail():
		profile.mark_mail_read(mail.mail_id)
	await settle()
	for app: String in ["album", "shop", "cases", "minigame", "system"]:
		await open_app(app)
		check(computer.get("_content_panel").get_global_rect().end.x <= root.get_visible_rect().end.x, "App fits the viewport: " + app)
		audit_content(computer.get("_content"))
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/terminal_classic_" + app + ".png")
	await open_app("shop")
	var old_money: int = profile.money
	var old_desks := int(profile.owned_furniture.get("studio_desk", 0))
	await click(find_button("购买  ¥260"))
	check(profile.money == old_money - 260, "Purchase button deducts the correct price")
	check(int(profile.owned_furniture.get("studio_desk", 0)) == old_desks + 1, "Purchase adds furniture to inventory")
	await click(find_button("扩建一楼"))
	check(profile.is_studio_room_purchase_unlocked(0), "Expansion button unlocks the next room")
	check(find_button("购买一楼第 2 个房间　¥900") != null, "Expansion offers the room purchase afterward")
	await open_app("minigame")
	await click(find_button("进行一次毫无意义的校准"))
	check(find_button("校准结果：非常准确（大概）") != null, "Mini-game button still responds")
	await open_app("system")
	await click(find_button("重置全部游戏进度"))
	var overlay: Control = computer.get("_reset_overlay")
	check(overlay.visible, "Reset still opens confirmation")
	await click(overlay.get_node("Note/CancelButton") as Button)
	check(not overlay.visible and profile.completed_cases.has("office_case_001"), "Cancel closes reset without clearing progress")
	root.get_node("GameLanguage").set_language("zh_CN")
	await open_app("shop")
	audit_content(computer.get("_content"))
	root.get_node("GameLanguage").set_language("en")
	computer.close_desktop()
	root.get_node("GameAudio").stop_all()
	computer.queue_free()
	await settle()
	await create_timer(0.2).timeout
	print("TERMINAL_APPS_OK: five classic applications, native app/purchase/expansion/calibration/reset clicks" if failures.is_empty() else "TERMINAL_APPS_FAILED: " + str(failures))
	quit(0 if failures.is_empty() else 1)

func open_app(app: String) -> void:
	await click(computer.find_child("DesktopStartButton", true, false) as Button)
	await click(computer.find_child(app.capitalize() + "StartMenuButton", true, false) as Button)
	check(computer.get("_current_app") == app, "Shortcut opens " + app)

func find_button(source: String) -> Button:
	return find_text(computer.get("_content"), source, true) as Button

func find_label(source: String) -> Label:
	return find_text(computer.get("_content"), source, false) as Label

func find_text(node: Node, source: String, button: bool) -> Control:
	if ((button and node is Button) or (not button and node is Label)) and node.text == source:
		return node
	for child: Node in node.get_children():
		var found := find_text(child, source, button)
		if found != null: return found
	return null

func click(button: Button) -> void:
	if button == null:
		check(false, "Missing requested button")
		return
	var scroll: ScrollContainer = computer.get("_content_scroll")
	if scroll != null and scroll.is_ancestor_of(button):
		scroll.ensure_control_visible(button)
		await settle()
	var at := button.get_global_transform_with_canvas() * (button.size * 0.5)
	var motion := InputEventMouseMotion.new()
	motion.position = at
	root.push_input(motion, true)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = at
	press.pressed = true
	root.push_input(press, true)
	var release := press.duplicate() as InputEventMouseButton
	release.pressed = false
	root.push_input(release, true)
	await settle()

func audit_content(node: Node) -> void:
	if node is Label:
		check(node.get_theme_color("font_color").get_luminance() < 0.5, "Readable dark text on the light desktop: " + node.text)
	for child: Node in node.get_children():
		audit_content(child)

func settle() -> void:
	await process_frame
	await process_frame
	await process_frame

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)
