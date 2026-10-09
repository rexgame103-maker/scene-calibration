extends SceneTree

var failures: Array[String] = []
var played: Array[String] = []
var audio: Node

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func _heard(id: String, _spatial: bool, _position: Vector3) -> void:
	played.append(id)

func click(button: Button) -> void:
	for down: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = button.get_global_rect().get_center()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)
		await process_frame

func _run() -> void:
	root.size = Vector2i(1280, 720)
	audio = root.get_node("GameAudio")
	audio.connect("sound_played", _heard)
	# A short-lived UI button may disappear before deferred audio binding runs.
	var transient := Button.new()
	root.add_child(transient)
	var transient_id := transient.get_instance_id()
	transient.free()
	await process_frame
	check(not is_instance_id_valid(transient_id), "Freed UI buttons are safely skipped by deferred audio binding")
	for bus: String in ["Effects", "UI", "SFX", "Ambience"]:
		check(AudioServer.get_bus_index(bus) >= 0, "Missing bus: " + bus)
	check(not audio.call("play", "missing") and not audio.call("play", "amb_office"), "Unknown and loop events cannot be one-shots")
	check(audio.call("play", "paper_click"), "Paper sample starts")
	var variant: int = audio.get("_last_variant")["paper_click"]
	check(not audio.call("play", "paper_click"), "Rapid repeats obey cooldown")
	await create_timer(0.25).timeout
	audio.call("play", "paper_click")
	check(variant != int(audio.get("_last_variant")["paper_click"]), "Variants alternate without immediate repetition")

	# Allow the real initial scene fade to release GUI input.
	await create_timer(0.9).timeout
	var holder := Control.new()
	root.add_child(holder)
	var button := Button.new()
	button.position = Vector2(100, 100)
	button.size = Vector2(160, 50)
	button.text = "Audio input test"
	holder.add_child(button)
	await process_frame
	await process_frame
	await create_timer(0.25).timeout
	played.clear()
	await click(button)
	check(played == ["paper_click"], "Real mouse press plays exactly one paper click")
	button.disabled = true
	played.clear()
	await click(button)
	check(played.is_empty(), "Disabled buttons are silent")
	button.disabled = false
	holder.add_to_group("audio_terminal_ui")
	await create_timer(0.25).timeout
	await click(button)
	check(played == ["terminal_click"], "Terminal descendants use terminal clicks")
	audio.call("bind_button", button, "")
	played.clear()
	await click(button)
	check(played.is_empty(), "Explicit semantic hooks suppress the generic click")
	holder.queue_free()
	await process_frame

	audio.call("set_level", "effects", 0.0)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Effects")), "Zero effects volume mutes UI and SFX")
	audio.call("set_level", "effects", 0.7)
	audio.call("set_level", "ambience", 0.4)
	check(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Effects")), "Effects unmute independently")
	audio.call("set_ambience", "amb_office", 0.05)
	await create_timer(0.1).timeout
	paused = true
	played.clear()
	check(not audio.call("play", "place_wood", Vector3.ZERO), "World effects cannot start during pause")
	check(audio.call("play", "paper_cancel"), "Pause menu effects remain usable")
	await create_timer(0.25).timeout
	var base := linear_to_db(0.4)
	check(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Ambience")) - (base - 12.0)) < 0.1, "Pause ducks ambience without changing the preference")
	paused = false
	await create_timer(0.25).timeout
	check(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Ambience")) - base) < 0.1, "Resume restores ambience volume")
	check(is_equal_approx(float(audio.call("get_level", "ambience")), 0.4), "Ducking preserves user volume")
	audio.call("set_ambience", "amb_gallery", 0.05)
	await create_timer(0.1).timeout
	var loops := 0
	for voice: AudioStreamPlayer in audio.get("_ambience_players"):
		if voice.playing: loops += 1
	check(loops == 1, "Crossfade leaves one environment loop")
	for kind: String in ["small_shelf", "restoration_stool", "cold_light_panel", "ordinary_file_01"]:
		played.clear()
		audio.call("play_placement", kind, Vector3.ZERO)
		var expected := {"small_shelf": "place_cabinet", "restoration_stool": "place_chair", "cold_light_panel": "place_metal", "ordinary_file_01": "place_paper"}
		check(played == [expected[kind]], "Material event for " + kind)

	# Real scenes, modal buttons and setting signals; the test runner isolates user://.
	check(change_scene_to_file("res://scenes/start_menu/start_menu_office.tscn") == OK, "Start menu loads")
	await process_frame
	await process_frame
	check(audio.call("get_ambience_event") == "amb_studio", "Start menu uses studio ambience")
	var menu := current_scene
	menu.call("_open_settings")
	var effects := menu.find_child("EffectsVolume", true, false) as HSlider
	var ambience := menu.find_child("AmbienceVolume", true, false) as HSlider
	check(effects != null and ambience != null, "Both audio sliders exist")
	if effects != null and ambience != null:
		effects.value = 0.23
		ambience.value = 0.61
		check(is_equal_approx(float(audio.call("get_level", "effects")), 0.23), "Effects slider controls Effects")
		check(is_equal_approx(float(audio.call("get_level", "ambience")), 0.61), "Ambience slider controls Ambience")
		var options := ConfigFile.new()
		check(options.load("user://the_scene_options.cfg") == OK, "Audio preferences are saved")
		check(is_equal_approx(float(options.get_value("audio", "effects")), 0.23) and is_equal_approx(float(options.get_value("audio", "ambience")), 0.61), "Both channel preferences persist")
	for case_path: String in ["res://data/cases/office_case_001.json", "res://data/cases/gallery_case_002.json"]:
		root.get_node("CaseManager").call("load_case", case_path)
		check(change_scene_to_file("res://scenes/main.tscn") == OK, "Case scene loads")
		await process_frame
		await process_frame
		check(audio.call("get_ambience_event") == ("amb_gallery" if "gallery" in case_path else "amb_office"), "Case ambience follows the active case")
		var flow: Control = current_scene.get("first_case_flow_ui")
		flow.call("_on_accept_pressed")
		if "office" in case_path:
			var manager := root.get_node("CaseManager")
			var files: Control = current_scene.get("case_file_ui")
			files.call("open_files")
			played.clear()
			files.call("_select_evidence", "mail_photo_01")
			check("photo_pick" in played and "clue_collect" in played, "New photo plays handling and newly awarded clue sounds")
			await create_timer(0.3).timeout
			played.clear()
			files.call("_select_evidence", "mail_photo_01")
			check("photo_pick" in played and not "clue_collect" in played, "Reopening a viewed photo does not replay clue collection")
			files.call("close_files")
			var main := current_scene
			main.set_process(false)
			await create_timer(0.3).timeout
			played.clear()
			main.call("_begin_placement", "desk")
			var preview: Node3D = main.get("active_preview")
			check(is_instance_valid(preview) and "furniture_pickup" in played, "Inventory pickup starts furniture sound")
			if is_instance_valid(preview):
				preview.position = Vector3(0, 0, 0)
				preview.visible = true
				main.set("placement_valid", true)
				played.clear()
				main.call("_finish_placement")
				check("place_wood" in played and String(main.get("active_kind")).is_empty(), "Committed placement plays its material and ends the drag")
			await create_timer(0.3).timeout
			played.clear()
			main.call("_begin_placement", "chair")
			main.set("placement_valid", false)
			main.call("_finish_placement")
			check("placement_invalid" in played and not "place_chair" in played, "Rejected placement plays failure without material success")
			played.clear()
			flow.call("show_settlement")
			flow.call("show_settlement")
			check(played.count("case_complete") == 1, "Visible settlement does not replay completion")
		root.get_node("PauseMenu").call("open_pause_menu")
		check(paused, "Pause screen pauses gameplay")
		root.get_node("PauseMenu").call("close_pause_menu")
		check(not paused, "Pause screen resumes gameplay")
	check(change_scene_to_file("res://scenes/studio/calibrator_studio.tscn") == OK, "Studio scene loads")
	await process_frame
	await process_frame
	check(audio.call("get_ambience_event") == "amb_studio", "Studio ambience starts after case exit")
	var desktop: Control = current_scene.get("computer_ui")
	if desktop != null:
		played.clear()
		desktop.call("open_desktop")
		desktop.call("open_desktop")
		check(played.count("crt_boot") == 1, "Terminal boot sounds once per opening")
		desktop.call("close_desktop")
		check("terminal_window_close" in played, "Terminal close plays its semantic sound")
	current_scene.queue_free()
	await process_frame
	await create_timer(0.4).timeout
	check(audio.call("get_ambience_event") == "", "Scene exit clears ambience")
	check((audio.get("_drag_positions") as Dictionary).is_empty(), "Scene exit clears drag tracking")
	audio.call("stop_all")
	await create_timer(0.15).timeout
	print("GAME_AUDIO_OK: input, material events, pause, fades, settings and real scenes" if failures.is_empty() else str(failures))
	quit(0 if failures.is_empty() else 1)
