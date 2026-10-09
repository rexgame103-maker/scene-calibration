extends SceneTree

const TEXT_FIT := preload("res://tests/ui_text_fit_audit.gd")
var failures: Array[String] = []
var computer: Control
var profile: Node

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280, 720)
	profile = root.get_node("PlayerProfile")
	root.get_node("GameLanguage").set_language("en")
	computer = load("res://scripts/studio_computer_ui.gd").new()
	computer.setup(profile)
	root.add_child(computer)
	computer.open_desktop()
	await create_timer(1.4).timeout
	check(computer.get("_windows").is_empty(), "Computer opens on the desktop without launching mail")
	var unread: int = profile.get_unread_mail_count()
	check(unread > 0, "The desktop leaves new mail unread")
	await capture("terminal_desktop")
	await click(computer.find_child("MailDockButton", true, false))
	var mail := window("mail")
	check(mail != null and mail.visible, "Clicking the mail shortcut launches its window")
	await capture("terminal_desktop_window")
	var reader: TerminalMailClient = computer.get("_mail_host").get_child(0)
	var selected := reader.selected_mail_id
	var original := Rect2(mail.position, mail.size)
	await click(mail.find_child("WindowMaximizeButton", true, false))
	check(mail.is_maximized and mail.position == Vector2.ZERO and mail.size == computer.get("_workspace").size,
		"Maximize fills the usable desktop above the taskbar")
	await capture("terminal_desktop_mail")
	await click(mail.find_child("WindowMaximizeButton", true, false))
	check(not mail.is_maximized and Rect2(mail.position, mail.size) == original, "Restore returns to the original window bounds: %s / %s (minimum %s)" % [Rect2(mail.position, mail.size), original, mail.get_combined_minimum_size()])
	var title: Control = mail.get_child(0).get_child(0)
	var drag_start := title.get_global_rect().position + Vector2(170, 18)
	await drag(drag_start, drag_start + Vector2(-48, -6))
	check(mail.position.distance_to(original.position) > 20, "Title bar pointer drag moves the window")
	check(Rect2(Vector2.ZERO, computer.get("_workspace").size).encloses(Rect2(mail.position, mail.size)), "Dragged window stays inside the desktop")
	reader.body_scroll.scroll_vertical = int(reader.body_scroll.get_v_scroll_bar().max_value)
	await click(mail.find_child("WindowMinimizeButton", true, false))
	check(not mail.visible and mail.is_minimized, "Minimize hides the app and retains its task")
	profile.add_debug_money(1)
	await create_timer(1.4).timeout
	check(not mail.visible and profile.get_unread_mail_count() == unread, "Profile updates do not restore or read minimized mail")
	await click(computer.find_child("MailTaskButton", true, false))
	check(mail.visible and not mail.is_minimized, "Taskbar restores minimized mail")
	check(computer.get("_mail_host").get_child(0) == reader and reader.selected_mail_id == selected,
		"Restoring preserves the reader and selected message")
	await launch("shop")
	await create_timer(1.4).timeout
	check(profile.get_unread_mail_count() == unread, "Mail covered by another app remains unread")
	await click(computer.find_child("MailTaskButton", true, false))
	reader.body_scroll.scroll_vertical = int(reader.body_scroll.get_v_scroll_bar().max_value)
	await create_timer(1.4).timeout
	check(profile.get_unread_mail_count() == 0, "Reading restored mail clears the unread state")
	check(not computer.find_child("MailUnreadDot", true, false).visible, "The last unread dot disappears")
	for app: String in ["album", "cases", "minigame", "system"]:
		await launch(app)
	check(computer.get("_windows").size() == 6 and computer.get("_task_buttons").get_child_count() == 6,
		"All six applications have independent windows and taskbar entries")
	for locale: String in ["zh_CN", "en"]:
		root.get_node("GameLanguage").set_language(locale)
		for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1024, 600)]:
			root.size = resolution
			await settle()
			for app: String in ["mail", "album", "shop", "cases", "minigame", "system"]:
				await click(computer.find_child(app.capitalize() + "TaskButton", true, false))
				var app_window := window(app)
				if not app_window.is_maximized:
					await click(app_window.find_child("WindowMaximizeButton", true, false))
				var workspace: Control = computer.get("_workspace")
				check(workspace.get_global_rect().encloses(app_window.get_global_rect()), "Window fits viewport: %s/%s = %s / %s (minimum %s)" % [app, locale, app_window.get_global_rect(), workspace.get_global_rect(), app_window.get_combined_minimum_size()])
				var issues: Array[Dictionary] = []
				TEXT_FIT.audit(app_window, issues, app + "/" + locale)
				check(issues.is_empty(), "Window text fits: " + str(issues))
	root.size = Vector2i(1280, 720)
	await settle()
	for app: String in ["system", "minigame", "cases", "shop", "album", "mail"]:
		# Clicking an inactive task activates it; an active task minimizes it.
		if computer.get("_current_app") != app:
			await click(computer.find_child(app.capitalize() + "TaskButton", true, false))
		await click(window(app).find_child("WindowCloseButton", true, false))
		check(not computer.get("_windows").has(app), "Close removes only the requested app: " + app)
	check(computer.visible and computer.get("_current_app") == "" and computer.get("_task_buttons").get_child_count() == 0,
		"Closing the last window returns to the desktop without leaving the computer")
	await click(computer.find_child("MailDockButton", true, false))
	check(window("mail") != null, "A closed application can be launched again")
	computer.close_desktop()
	computer.open_desktop()
	await settle()
	check(computer.get("_current_app") == "" and not window("mail").visible, "Reentering the computer starts on its desktop")
	computer.close_desktop()
	root.get_node("GameAudio").stop_all()
	computer.queue_free()
	await settle()
	await create_timer(0.2).timeout
	print("TERMINAL_DESKTOP_OK: desktop launch, real window/taskbar/drag input, retained state, unread visibility, six bilingual apps at two resolutions" if failures.is_empty() else "TERMINAL_DESKTOP_FAILED: " + str(failures))
	quit(0 if failures.is_empty() else 1)

func window(app: String) -> Control:
	return computer.get("_windows").get(app, {}).get("window", null)

func launch(app: String) -> void:
	await click(computer.find_child("DesktopStartButton", true, false))
	await click(computer.find_child(app.capitalize() + "StartMenuButton", true, false))
	check(computer.get("_current_app") == app, "Start menu launches " + app)

func click(button: Control) -> void:
	if button == null:
		check(false, "Requested control is missing")
		return
	await pointer_button(button.get_global_rect().get_center(), true)
	await pointer_button(button.get_global_rect().get_center(), false)
	await settle()

func drag(from: Vector2, to: Vector2) -> void:
	await pointer_button(from, true)
	var motion := InputEventMouseMotion.new()
	motion.position = to
	motion.relative = to - from
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(motion, true)
	await pointer_button(to, false)
	await settle()

func pointer_button(at: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = at
	event.pressed = pressed
	root.push_input(event, true)
	await process_frame

func capture(file_name: String) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/" + file_name + ".png")

func settle() -> void:
	await process_frame
	await process_frame
	await process_frame

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)
