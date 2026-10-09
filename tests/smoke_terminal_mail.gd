extends SceneTree

var failures: Array[String] = []
var computer: Control
var profile: MailProfile

class MailProfile extends Node:
	signal money_changed(amount: int)
	signal mail_changed
	signal shop_changed
	var money := 700
	var completed_cases := {"office_case_001": true}
	var album_entries: Array = []
	var mails: Array = []
	var accepted_calls: Array[String] = []
	func _init() -> void:
		mails = JSON.parse_string(FileAccess.get_file_as_string("res://data/progression/campaign.json")).mail
		for mail: Dictionary in mails:
			mail.is_read = mail.mail_id in ["mail_case_001", "mail_case_003"]
			mail.is_accepted = mail.mail_id == "mail_case_003"
	func get_available_mail() -> Array:
		return mails.duplicate(true)
	func get_unread_mail_count() -> int:
		var count := 0
		for mail: Dictionary in mails:
			if not mail.is_read: count += 1
		return count
	func mark_mail_read(mail_id: String) -> void:
		for mail: Dictionary in mails:
			if mail.mail_id == mail_id: mail.is_read = true
		mail_changed.emit()
	func accept_mail(mail_id: String) -> String:
		accepted_calls.append(mail_id)
		mark_mail_read(mail_id)
		for mail: Dictionary in mails:
			if mail.mail_id == mail_id:
				mail.is_accepted = true
				mail_changed.emit()
				return mail.case_id
		return ""

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280, 720)
	profile = MailProfile.new()
	root.add_child(profile)
	# Load after autoloads exist; an inline subclass is parsed before GameAudio.
	computer = load("res://tests/fixtures/terminal_mail_test_computer.gd").new()
	computer.setup(profile)
	root.add_child(computer)
	computer.open_desktop()
	await settle()
	await create_timer(0.9).timeout
	await click(computer.find_child("MailDockButton", true, false) as Button)
	check(rows() == 4, "Inbox lists every available message")
	check(client().case_action.text == "重新调查", "Completed case offers replay")
	await click(client().case_action)
	check(computer.get("opened_cases") == ["office_case_001"], "Replay opens completed case without accepting or rewarding it")
	check(profile.accepted_calls.is_empty(), "Replay does not call accept_mail")
	await select_mail("mail_case_002")
	check(client().body_label.text == profile.mails[2].body, "Real row click previews the selected message")
	check(profile.get_unread_mail_count() == 2, "Preview does not mark mail read")
	check(client().case_action.text == "接取委托", "Unread assignment offers accept")
	await capture("terminal_mail_classic_en")
	await click(client().mark_read)
	check(profile.get_unread_mail_count() == 1, "Mark as read updates the profile")
	check(client().selected_mail_id == "mail_case_002", "Profile refresh keeps selected message")
	check(client().mark_read.disabled, "Already-read mail cannot be marked again")
	await click(client().case_action)
	check(profile.accepted_calls == ["mail_case_002"], "Accept acts on selected assignment")
	check(computer.get("opened_cases").back() == "gallery_case_002", "Accept opens the correct case")
	check(client().case_action.text == "继续委托", "Accepted mail becomes Continue Assignment")
	await click(client().case_action)
	check(profile.accepted_calls.size() == 1, "Continue does not accept twice")
	await select_mail("mail_reward_001")
	check(client().case_action.disabled, "Informational mail cannot start a case")
	await click(computer.find_child("MailFolderReadButton", true, false) as Button)
	check(rows() == 3, "Read folder filters messages")
	await click(computer.find_child("MailFolderArchivedButton", true, false) as Button)
	check(rows() == 1 and client().selected_mail_id == "mail_case_001", "Archive contains completed cases")
	profile.completed_cases.clear()
	profile.mail_changed.emit()
	await settle()
	check(rows() == 0, "Empty folder has no stale rows")
	check(client().mark_read.disabled and client().case_action.disabled, "Empty folder actions are disabled")
	check(client().body_label.text == "此文件夹中没有邮件。", "Empty folder has an explanation")
	await click(computer.find_child("MailFolderInboxButton", true, false) as Button)
	await select_mail("mail_case_001")
	root.get_node("GameLanguage").set_language("zh_CN")
	await settle()
	check(client().messages.get_column_title(0) == "发件人", "Live language switch updates Tree headers")
	check(client().messages.get_root().get_first_child().get_text(1).contains("办公室"), "Live language switch updates Tree rows")
	await capture("terminal_mail_classic_zh")
	root.get_node("GameLanguage").set_language("en")
	await settle()
	check(client().messages.get_column_title(0) == "From", "English Tree headers restored")
	check(client().messages.get_root().get_first_child().get_text(1).contains("Office"), "English row text restored")
	await click(client().get_node("Toolbar/CheckMail") as Button)
	check(client().selected_mail_id == "mail_case_001", "Check Mail refresh preserves selection")
	await select_mail("mail_reward_001")
	var reader := client()
	var dot := computer.find_child("MailUnreadDot", true, false) as Panel
	check(dot.visible and dot.size == Vector2(10, 10), "Unread mail uses a small dot without a number")
	check((computer.find_child("MailDockButton", true, false) as Control).get_global_rect().encloses(dot.get_global_rect()), "Dot stays inside the mail shortcut")
	await create_timer(1.4).timeout
	check(profile.get_unread_mail_count() == 0 and not dot.visible, "Reading the last unread mail clears the dot automatically")
	check(client() == reader, "Read update preserves the existing reading pane")
	var new_mail: Dictionary = profile.mails[1].duplicate(true)
	new_mail.mail_id = "mail_test_long"
	new_mail.is_read = false
	new_mail.body = (client().tr(profile.mails[1].body) + "\n\n").repeat(30)
	profile.mails.append(new_mail)
	profile.mail_changed.emit()
	await settle()
	check(dot.visible, "A new message shows the dot again")
	await select_mail("mail_test_long")
	await create_timer(1.4).timeout
	check(profile.get_unread_mail_count() == 1, "Unread long mail is not cleared before scrolling to its end")
	client().body_scroll.scroll_vertical = int(client().body_scroll.get_v_scroll_bar().max_value)
	await create_timer(1.4).timeout
	check(profile.get_unread_mail_count() == 0 and not dot.visible, "Reaching the end of long mail clears the last unread dot")
	check(client().body_scroll.scroll_vertical > 0, "Automatic read preserves the reader's scroll position")
	var hidden_mail: Dictionary = profile.mails[1].duplicate(true)
	hidden_mail.mail_id = "mail_test_hidden"
	hidden_mail.is_read = false
	profile.mails.append(hidden_mail)
	profile.mail_changed.emit()
	await select_mail("mail_test_hidden")
	computer.close_desktop()
	await create_timer(1.4).timeout
	check(profile.get_unread_mail_count() == 1, "Closing the reader cancels automatic marking")
	computer.open_desktop()
	await click(computer.find_child("MailDockButton", true, false) as Button)
	await create_timer(1.4).timeout
	check(profile.get_unread_mail_count() == 0 and not dot.visible, "Reopening and reading the message clears the dot")
	root.size = Vector2i(1024, 600)
	await settle()
	check_layout()
	await capture("terminal_mail_classic_small")
	computer.close_desktop()
	root.get_node("GameAudio").stop_all()
	computer.queue_free()
	profile.queue_free()
	await settle()
	await create_timer(0.2).timeout
	print("TERMINAL_MAIL_OK: real row/button clicks, read/archive filtering, selected message, accept/continue/replay, bilingual layout" if failures.is_empty() else "TERMINAL_MAIL_FAILED: " + str(failures))
	quit(0 if failures.is_empty() else 1)

func client() -> TerminalMailClient:
	return computer.get("_mail_host").get_child(0) as TerminalMailClient

func rows() -> int:
	return client().messages.get_root().get_child_count()

func select_mail(mail_id: String) -> void:
	var tree := client().messages
	for item: TreeItem in tree.get_root().get_children():
		if item.get_metadata(0) == mail_id:
			tree.scroll_to_item(item)
			await settle()
			var area := tree.get_item_area_rect(item, 1)
			await click_at(tree.get_global_transform_with_canvas() * area.get_center())
			check(client().selected_mail_id == mail_id, "Pointer selects mail row " + mail_id)
			return
	check(false, "Missing mail row " + mail_id)

func click(button: Button) -> void:
	check(button.get_global_rect().end.x <= root.size.x, "Button fits viewport: " + button.text)
	check(button.get_global_rect().end.y <= root.size.y, "Button fits viewport: " + button.text)
	await click_at(button.get_global_transform_with_canvas() * (button.size * 0.5))

func click_at(at: Vector2) -> void:
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

func settle() -> void:
	await process_frame
	await process_frame
	await process_frame

func check_layout() -> void:
	var viewport_end := root.get_visible_rect().end
	for control: Control in [client(), client().messages, client().get_node("Panes/Reader"), client().get_node("Status")]:
		check(control.get_global_rect().end.x <= viewport_end.x and control.get_global_rect().end.y <= viewport_end.y,
			"Mail pane fits the small viewport: " + control.name)
	check(client().subject_label.get_global_rect().end.y <= client().body_label.get_global_rect().position.y,
		"Long subject stays above the message body")

func capture(file_name: String) -> void:
	check_layout()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/" + file_name + ".png")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)
