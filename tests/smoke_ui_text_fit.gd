extends SceneTree

const TEXT_FIT := preload("res://tests/ui_text_fit_audit.gd")
var issues: Array[Dictionary] = []
var states := 0
var checked_contexts: Array[String] = []
const WINDOW_SIZES := [Vector2i(1280, 720), Vector2i(1024, 600), Vector2i(2048, 1055)]

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280, 720)
	var language := root.get_node("GameLanguage")
	var manager := root.get_node("CaseManager")
	var profile := root.get_node("PlayerProfile")
	await check_audit_regression()
	for locale: String in ["en", "zh_CN"]:
		language.set_language(locale)
		profile.reset_profile(false)
		var menu := load("res://scenes/start_menu/start_menu_office.tscn").instantiate() as Node3D
		root.add_child(menu)
		current_scene = menu
		await audit(locale + "/start_menu")
		menu.call("_open_settings")
		await audit(locale + "/settings")
		menu.get("_settings").hide()
		menu.call("_open_reset_confirmation")
		await audit(locale + "/start_reset")
		menu.call("_close_reset_confirmation")
		menu.queue_free()
		await settle()
		profile.active_skills.assign(["extra_photo_slots", "evidence_source_hint", "trace_counter"])
		for case_id: String in ["office_case_001", "gallery_case_002", "apartment_case_003"]:
			manager.load_case("res://data/cases/" + case_id + ".json")
			var main := load("res://scenes/main.tscn").instantiate() as Node3D
			root.add_child(main)
			current_scene = main
			await settle()
			var flow: Control = main.get("first_case_flow_ui")
			await audit(locale + "/" + case_id + "/briefing")
			flow.call("_on_accept_pressed")
			await audit(locale + "/" + case_id + "/scene")
			# Unlock the complete case inventory and every document without touching player saves.
			for clue_id: String in manager.clues.keys():
				manager.discover_clue(clue_id)
			var files: Control = main.get("case_file_ui")
			for evidence: Dictionary in manager.get_available_evidence():
				files.debug_open_evidence(evidence.id)
				await audit(locale + "/" + case_id + "/" + evidence.id)
				if String(evidence.get("view_type", "text")) == "photo":
					files.get("_photo_texture").hide()
					files.get("_photo_canvas").show()
					await audit(locale + "/" + case_id + "/fallback/" + evidence.id)
			for category: int in 4:
				files.call("_select_journal_tab", category)
				await audit(locale + "/" + case_id + "/category/" + str(category))
			files.close_files()
			await audit(locale + "/" + case_id + "/inventory")
			var tray: Control = main.get("photo_reference_tray")
			for reference_id: String in tray.get("_references"):
				var reference_button: Button = tray.get("_button_row").get_node("Reference_" + reference_id)
				reference_button.pressed.emit()
				if not tray.get("_floating_cards").has(reference_id):
					issues.append({"context": locale + "/reference_button", "reason": "Reference button did not open its photograph: " + reference_id})
				await audit(locale + "/" + case_id + "/reference/" + reference_id)
			if locale == "en" and case_id == "office_case_001":
				await capture("ui_reference_fit_en")
			# Also exercise captions when a photograph is absent and the sketch
			# fallback is used. Editing these copies does not change case data.
			for reference_id: String in tray.get("_references"):
				if tray.get("_floating_cards").has(reference_id):
					tray.call("_toggle_photo", reference_id)
				var evidence: Dictionary = tray.get("_references")[reference_id]
				var image_path := String(evidence.get("image_path", ""))
				evidence["image_path"] = ""
				tray.call("_toggle_photo", reference_id)
				await audit(locale + "/" + case_id + "/reference_sketch/" + reference_id)
				evidence["image_path"] = image_path
			main.call("_toggle_lighting_editor")
			await audit(locale + "/" + case_id + "/lighting")
			main.call("_toggle_lighting_editor")
			var reconstruction := root.get_node("ReconstructionManager")
			for zone: Node3D in reconstruction.zones.values():
				main.call("_debug_place_furniture_in_zone", zone)
			await settle()
			for entry: Dictionary in main.get("placed_items"):
				main.call("_select_item", entry)
				main.call("_show_furniture_menu", Vector2(560, 400))
				await audit(locale + "/" + case_id + "/menu/" + String(entry.kind))
			main.call("_hide_furniture_menu")
			main.call("_focus_selected_furniture")
			await settle_camera(main)
			await audit(locale + "/" + case_id + "/inspection")
			main.call("_focus_overview")
			await settle_camera(main)
			for entry: Dictionary in main.get("placed_items"):
				if entry.node is RigidBody3D and not bool(entry.get("requires_collection", false)):
					main.call("_select_item", entry)
					break
			main.call("_enter_rotation_mode")
			if main.get("rotation_mode"):
				await audit(locale + "/" + case_id + "/rotation")
				main.call("_confirm_rotation_mode")
				await settle_camera(main)
			else:
				issues.append({"context": locale + "/" + case_id + "/rotation", "reason": "Rotation UI was not reached."})
			flow.set_submit_available(true)
			flow.show_submit_failure(String(manager.get_completion_data().get("failure_message", "当前现场还没有完成，请继续核对资料和家具位置。")))
			await audit(locale + "/" + case_id + "/submit_feedback")
			if main.call("_has_case_light_calibration"):
				main.call("_toggle_case_light_editor")
				await audit(locale + "/" + case_id + "/calibration")
				main.call("_toggle_case_light_editor")
			var popup: Control = main.get("scene_clue_popup")
			for point: Node3D in get_nodes_in_group("scene_clue_points"):
				popup.show_point(point)
				popup.elapsed = 100.0
				popup.call("_apply_intro")
				await audit(locale + "/" + case_id + "/clue/" + String(point.title))
				if locale == "en" and case_id == "gallery_case_002":
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png("res://tests/ui_text_fit_clue_en.png")
				popup.close()
			flow.show_settlement()
			await audit(locale + "/" + case_id + "/settlement")
			flow.finish_photo_capture(true)
			await audit(locale + "/" + case_id + "/photo_saved")
			flow.finish_photo_capture(false)
			await audit(locale + "/" + case_id + "/photo_failed")
			var pause := root.get_node("PauseMenu")
			if pause.open_pause_menu():
				await audit(locale + "/" + case_id + "/pause")
				pause.close_pause_menu()
			main.queue_free()
			await settle()
		for item: Dictionary in profile.catalog_data.get("items", []):
			profile.owned_furniture[String(item.furniture_kind)] = 10
		var studio := load("res://scenes/studio/calibrator_studio.tscn").instantiate() as Node3D
		root.add_child(studio)
		current_scene = studio
		await audit(locale + "/studio")
		for page: int in studio.call("_catalog_page_count"):
			studio.call("_set_catalog_page", page)
			await audit(locale + "/studio/catalog/" + str(page))
		for furniture: Node3D in studio.get("furniture_root").get_children():
			studio.call("_select_furniture", furniture)
			studio.call("_show_furniture_menu", Vector2(560, 400))
			await audit(locale + "/studio/menu/" + String(furniture.get_meta("studio_kind", "")))
		studio.call("_hide_furniture_menu")
		studio.call("_focus_selected_furniture")
		await settle_camera(studio)
		await audit(locale + "/studio/inspection")
		studio.call("_focus_overview")
		await settle_camera(studio)
		studio.call("_enter_rotation_mode")
		await audit(locale + "/studio/rotation")
		studio.call("_confirm_rotation_mode")
		await settle_camera(studio)
		studio.call("_enter_work_mode")
		await audit(locale + "/studio/work")
		var desktop: Control = studio.get("computer_ui")
		desktop.open_desktop()
		await audit(locale + "/terminal/desktop")
		desktop.get("_start_menu").show()
		await audit(locale + "/terminal/start")
		desktop.get("_start_menu").hide()
		for progress: String in ["fresh", "completed"]:
			if progress == "completed":
				for case_id: String in ["office_case_001", "gallery_case_002", "apartment_case_003"]:
					profile.complete_case(case_id, "", false)
				profile.studio_rooms = {"0": 4, "1": 3}
				profile.studio_room_purchase_unlocked = {"0": true, "1": true}
			for app: String in ["mail", "album", "shop", "cases", "minigame", "system"]:
				desktop.call("_show_app", app)
				await audit(locale + "/terminal/" + progress + "/" + app)
				var window: Control = desktop.get("_windows")[app].window
				window.call("toggle_maximized")
				await audit(locale + "/terminal/" + progress + "/" + app + "/maximized")
				window.call("toggle_maximized")
				desktop.call("_minimize_app", app)
				await audit(locale + "/terminal/" + progress + "/" + app + "/minimized")
		desktop.call("_open_reset_confirmation")
		await audit(locale + "/terminal/reset")
		desktop.call("_close_reset_confirmation")
		desktop.close_desktop()
		studio.call("_enter_build_mode")
		studio.call("_switch_floor", 1, false)
		await audit(locale + "/studio/second_floor")
		studio.queue_free()
		await settle()
	language.set_language("en")
	root.get_node("GameAudio").stop_all()
	await create_timer(0.2).timeout
	var report := FileAccess.open("res://tests/ui_text_fit_report.json", FileAccess.WRITE)
	report.store_string(JSON.stringify(issues, "\t"))
	var coverage := FileAccess.open("res://tests/ui_text_fit_coverage.json", FileAccess.WRITE)
	coverage.store_string(JSON.stringify({"states": states, "contexts": checked_contexts, "issues": issues}, "\t"))
	print("UI_TEXT_FIT: %d states, %d issues (tests/ui_text_fit_report.json)" % [states, issues.size()])
	for issue: Dictionary in issues.slice(0, 20): print(issue)
	quit(0 if issues.is_empty() else 1)

func audit(context: String) -> void:
	for window_size: Vector2i in WINDOW_SIZES:
		root.size = window_size
		await settle()
		var state := context + "/" + str(window_size)
		TEXT_FIT.audit(root, issues, state)
		checked_contexts.append(state)
		states += 1
	root.size = Vector2i(1280, 720)
	await settle()

func settle() -> void:
	await process_frame
	await process_frame
	await process_frame

func settle_camera(scene: Node3D) -> void:
	var tween: Tween = scene.get("camera_tween")
	if tween != null and tween.is_running(): await tween.finished
	await settle()

func capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/" + filename + ".png")

func check_audit_regression() -> void:
	var frame := Control.new()
	frame.size = Vector2(600, 160)
	root.add_child(frame)
	var button := Button.new()
	button.clip_text = true
	button.size = Vector2(480, 48)
	button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	button.text = "Drag Out Reference · Email Attachment · Before the Room Was Cleared"
	button.add_theme_font_size_override("font_size", 18)
	preload("res://scripts/investigation_ui_theme.gd").button(button, "wide")
	frame.add_child(button)
	await settle()
	var regression: Array[Dictionary] = []
	TEXT_FIT.audit(frame, regression, "original overflow")
	if not regression.any(func(issue: Dictionary) -> bool: return String(issue.reason).contains("button text wider")):
		issues.append({"context": "audit_regression", "reason": "The auditor missed the original overflowing reference button."})
	button.text = "First line\nSecond line\nThird line"
	button.size = Vector2(480, 30)
	regression.clear()
	TEXT_FIT.audit(frame, regression, "multiline overflow")
	if not regression.any(func(issue: Dictionary) -> bool: return String(issue.reason).contains("button text taller")):
		issues.append({"context": "audit_regression", "reason": "The auditor missed overflowing multiline button text."})
	frame.queue_free()
	await settle()
