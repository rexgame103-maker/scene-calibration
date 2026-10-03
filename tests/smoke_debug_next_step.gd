extends SceneTree


const CASE_PATHS: Array[String] = [
	"res://data/cases/office_case_001.json",
	"res://data/cases/gallery_case_002.json",
	"res://data/cases/apartment_case_003.json"
]

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var case_manager := root.get_node_or_null("CaseManager")
	var reconstruction_manager := root.get_node_or_null("ReconstructionManager")
	for case_path: String in CASE_PATHS:
		_expect(bool(case_manager.call("load_case", case_path)), "Case should load: %s" % case_path)
		await process_frame
		var scene := (load("res://scenes/main.tscn") as PackedScene).instantiate() as Node3D
		root.add_child(scene)
		current_scene = scene
		await process_frame
		await physics_frame
		var flow := scene.get("first_case_flow_ui") as FirstCaseFlowUI
		flow.call("_on_accept_pressed")
		await process_frame

		var opened_evidence := 0
		var investigated_scene_clues := 0
		for press_index: int in range(32):
			var case_file_ui := scene.get("case_file_ui") as CaseFileUI
			var scene_clue_popup := scene.get("scene_clue_popup") as SceneCluePopup
			if case_file_ui.visible:
				opened_evidence += 1
				case_file_ui.close_files()
			if scene_clue_popup.visible:
				investigated_scene_clues += 1
				scene_clue_popup.close()
			if bool(scene.call("_debug_case_flow_finished")):
				break

			scene.call("_debug_advance_next_step")
			await _wait_for_debug_action(scene)

		var case_id := String((case_manager.call("get_case_summary") as Dictionary).get("case_id", ""))
		if not bool(scene.call("_debug_case_flow_finished")):
			var zone_states: Array[String] = []
			for zone_value: Variant in (reconstruction_manager.get("zones") as Dictionary).values():
				var debug_zone := zone_value as ReconstructionZone
				if is_instance_valid(debug_zone):
					zone_states.append("%s=%s" % [debug_zone.zone_id, debug_zone.is_satisfied])
			print("DEBUG_CASE_STATE %s clues=%s inventory=%s zones=%s" % [
				case_id,
				case_manager.get("discovered_clues"),
				scene.get("inventory_counts"),
				zone_states
			])
		_expect(bool(scene.call("_debug_case_flow_finished")), "%s should finish through DEBUG next-step actions" % case_id)
		var completion := case_manager.call("get_completion_data") as Dictionary
		_expect(
			bool(reconstruction_manager.call("is_step_satisfied", String(completion.get("required_reconstruction_step_id", "")))),
			"%s final reconstruction step should be satisfied" % case_id
		)
		_expect(opened_evidence > 0, "%s should automatically open case evidence" % case_id)
		if case_id == "office_case_001":
			_expect(investigated_scene_clues >= 2, "Office case should automatically inspect both scene clue points")
			for photo_id: String in ["mail_photo_01", "printer_layout_photo"]:
				var photo_data := case_manager.call("get_evidence_data", photo_id) as Dictionary
				var image_path := String(photo_data.get("image_path", ""))
				_expect(not image_path.is_empty() and ResourceLoader.exists(image_path), "Office evidence should use a rendered solved-scene image: %s" % photo_id)
			var office_case_file_ui := scene.get("case_file_ui") as CaseFileUI
			office_case_file_ui.debug_open_evidence("mail_photo_01")
			await process_frame
			var office_photo_view := office_case_file_ui.get("_photo_texture") as TextureRect
			_expect(is_instance_valid(office_photo_view) and office_photo_view.visible and is_instance_valid(office_photo_view.texture), "Office case file UI should display the rendered mail photo")
			office_case_file_ui.close_files()
			var office_reference_tray := scene.get("photo_reference_tray") as ReferencePhotoTray
			office_reference_tray.call("_toggle_photo", "mail_photo_01")
			var office_floating_cards := office_reference_tray.get("_floating_cards") as Dictionary
			var office_floating_photo := office_floating_cards.get("mail_photo_01", null) as Control
			_expect(is_instance_valid(office_floating_photo) and not office_floating_photo.find_children("*", "TextureRect", true, false).is_empty(), "Dragged office reference should use the rendered mail photo texture")
			office_reference_tray.call("_toggle_photo", "mail_photo_01")
			var file_shelf := scene.call("_debug_find_placed_furniture_by_id", "file_shelf") as Node3D
			_expect(is_instance_valid(file_shelf), "Office DEBUG should place the tall file cabinet")
			if is_instance_valid(file_shelf):
				var shelf_yaw := fposmod(file_shelf.global_rotation_degrees.y, 360.0)
				_expect(absf(shelf_yaw - 90.0) < 0.5, "Office DEBUG should rotate the tall cabinet 90 degrees along the wall")
				var shelf_info := FurnitureFactory.get_info("shelf")
				var shelf_depth := float((shelf_info.get("size", Vector3.ONE) as Vector3).z)
				_expect(file_shelf.global_position.x - shelf_depth * 0.5 > -3.34, "Office DEBUG cabinet should remain inside the left wall")
				var office_desk := scene.call("_debug_find_placed_furniture_by_id", "desk") as Node3D
				_expect(is_instance_valid(office_desk), "Office DEBUG should keep the desk available for overlap validation")
				if is_instance_valid(office_desk):
					var desk_info := FurnitureFactory.get_info("desk")
					var desk_bounds := scene.call("_projected_bounds_size", desk_info.get("size", Vector3.ONE), office_desk.rotation_degrees) as Vector2
					var shelf_bounds := scene.call("_projected_bounds_size", shelf_info.get("size", Vector3.ONE), file_shelf.rotation_degrees) as Vector2
					var desk_rect := Rect2(Vector2(office_desk.global_position.x, office_desk.global_position.z) - desk_bounds * 0.5, desk_bounds)
					var shelf_rect := Rect2(Vector2(file_shelf.global_position.x, file_shelf.global_position.z) - shelf_bounds * 0.5, shelf_bounds)
					_expect(not desk_rect.intersects(shelf_rect), "Office DEBUG cabinet should not intersect the desk")
		elif case_id == "gallery_case_002":
			_expect(investigated_scene_clues >= 1, "Gallery case should inspect the reconstructed heat-damage point")
			var gallery_items := scene.get("placed_items") as Array
			_expect(gallery_items.size() == 6, "Gallery second phase should move the same six devices instead of duplicating them")
			var gallery_kinds: Array[String] = []
			for gallery_entry: Dictionary in gallery_items:
				gallery_kinds.append(String(gallery_entry.get("kind", "")))
			for expected_kind: String in ["restoration_table", "restoration_stool", "cold_light_panel", "halogen_inspection_lamp", "metal_reflector", "camera_tripod"]:
				_expect(gallery_kinds.has(expected_kind), "Gallery should use primitive-only kind: %s" % expected_kind)
			_expect(not gallery_kinds.has("desk") and not gallery_kinds.has("chair") and not gallery_kinds.has("lamp"), "Gallery must not reuse office furniture kinds")
			var table := scene.call("_debug_find_placed_furniture_by_id", "restoration_table") as Node3D
			var halogen := scene.call("_find_case_light_device", "halogen_lamp") as CaseLightDevice
			var cold_panel := scene.call("_find_case_light_device", "standard_cold_light") as CaseLightDevice
			var reflector := scene.call("_find_case_light_device", "metal_reflector") as CaseLightDevice
			_expect(is_instance_valid(table) and is_instance_valid(table.find_child("ScalpelTool", true, false)), "Restoration table should contain a real scalpel shadow caster")
			_expect(is_instance_valid(table) and is_instance_valid(table.find_child("CalibrationRuler", true, false)), "Restoration table should contain a calibration ruler")
			_expect(is_instance_valid(halogen) and halogen.casts_shadow, "Halogen lamp should cast the sharp case shadow")
			_expect(is_instance_valid(cold_panel) and not cold_panel.casts_shadow, "Cold panel should remain a broad non-shadow fill for the two-light performance budget")
			_expect(is_instance_valid(reflector) and reflector.get_effective_energy() >= 0.10, "Reflector should create a visible secondary response in the solved layout")
			var case_light_toolbar := scene.get("case_light_toolbar") as PanelContainer
			var atmosphere_toolbar := scene.get("lighting_toolbar") as PanelContainer
			var case_light_button := scene.get("case_light_toggle_button") as Button
			var scene_environment := scene.get("scene_environment") as Environment
			var scene_key := scene.get("key_light") as DirectionalLight3D
			var scene_fill := scene.get("fill_light") as OmniLight3D
			var scene_accent := scene.get("accent_light") as OmniLight3D
			_expect(is_instance_valid(case_light_toolbar) and case_light_toolbar.visible, "Gallery should expose its case-specific light calibration toolbar")
			_expect(is_instance_valid(atmosphere_toolbar) and not atmosphere_toolbar.visible, "Unrestricted atmosphere lighting should be hidden during the light puzzle")
			_expect(is_instance_valid(case_light_button) and not case_light_button.disabled, "Light calibration should unlock after all three process photos are reviewed")
			_expect(is_equal_approx(scene_environment.ambient_light_energy, 0.22), "Gallery should apply its neutral case ambient light")
			_expect(is_equal_approx(scene_key.light_energy, 0.55) and not scene_key.shadow_enabled, "Gallery key light should remain neutral and non-shadowing")
			_expect(is_equal_approx(scene_fill.light_energy, 0.30) and is_zero_approx(scene_accent.light_energy), "Gallery should use cool fill without the misleading global warm accent")
			for photo_id: String in ["standard_layout_photo", "process_photo_cleaning", "process_photo_retouching", "process_photo_coating"]:
				var photo_data := case_manager.call("get_evidence_data", photo_id) as Dictionary
				var image_path := String(photo_data.get("image_path", ""))
				_expect(not image_path.is_empty() and ResourceLoader.exists(image_path), "Gallery process evidence should use a rendered scene image: %s" % photo_id)
			var case_file_ui := scene.get("case_file_ui") as CaseFileUI
			case_file_ui.debug_open_evidence("process_photo_cleaning")
			await process_frame
			var rendered_photo_view := case_file_ui.get("_photo_texture") as TextureRect
			_expect(is_instance_valid(rendered_photo_view) and rendered_photo_view.visible and is_instance_valid(rendered_photo_view.texture), "Case file UI should display the rendered process photo instead of the abstract sketch")
			case_file_ui.close_files()
			var reference_tray := scene.get("photo_reference_tray") as ReferencePhotoTray
			reference_tray.call("_toggle_photo", "process_photo_cleaning")
			var floating_cards := reference_tray.get("_floating_cards") as Dictionary
			var floating_photo := floating_cards.get("process_photo_cleaning", null) as Control
			_expect(is_instance_valid(floating_photo) and not floating_photo.find_children("*", "TextureRect", true, false).is_empty(), "Dragged gallery reference should use the rendered photo texture")
			reference_tray.call("_toggle_photo", "process_photo_cleaning")
			halogen.set_energy(0.20)
			scene.call("_update_case_light_visuals", 0.0, true)
			reconstruction_manager.call("evaluate_all")
			_expect(not bool(reconstruction_manager.call("is_step_satisfied", "actual_restoration_layout")), "Correct furniture positions alone must not satisfy the gallery case with incorrect light energy")
			halogen.apply_debug_values({"energy":1.05,"temperature":3100.0,"yaw":0.0,"pitch":-24.0})
			scene.call("_update_case_light_visuals", 0.0, true)
			reconstruction_manager.call("evaluate_all")
			_expect(bool(reconstruction_manager.call("is_step_satisfied", "actual_restoration_layout")), "Restoring target light and shadow parameters should satisfy the gallery case again")
			cold_panel.set_energy(0.50)
			halogen.apply_debug_values({"energy":0.55,"temperature":4500.0,"yaw":30.0,"pitch":-4.0})
			scene.call("_update_case_light_visuals", 0.0, true)
			reconstruction_manager.call("evaluate_all")
			_expect(bool(reconstruction_manager.call("is_step_satisfied", "actual_restoration_layout")), "Broad visually plausible light values should still satisfy the gallery reconstruction")
			cold_panel.set_energy(0.08)
			halogen.apply_debug_values({"energy":1.05,"temperature":3100.0,"yaw":0.0,"pitch":-24.0})
			scene.call("_update_case_light_visuals", 0.0, true)
			reconstruction_manager.call("evaluate_all")
		elif case_id == "apartment_case_003":
			for photo_id: String in ["guest_room_photo", "archive_shift_photo"]:
				var photo_data := case_manager.call("get_evidence_data", photo_id) as Dictionary
				var image_path := String(photo_data.get("image_path", ""))
				_expect(not image_path.is_empty() and ResourceLoader.exists(image_path), "Apartment initial evidence should use a rendered solved-scene image: %s" % photo_id)

		var placed_before := (scene.get("placed_items") as Array).size()
		scene.call("_debug_advance_next_step")
		await process_frame
		_expect((scene.get("placed_items") as Array).size() == placed_before, "%s finished DEBUG button should be a no-op" % case_id)

		root.remove_child(scene)
		scene.free()
		current_scene = null
		await process_frame

	_finish()


func _wait_for_debug_action(scene: Node) -> void:
	for frame_index: int in range(180):
		await process_frame
		var button := scene.get("debug_hint_button") as Button
		if is_instance_valid(button) and not button.disabled and not bool(scene.get("camera_transitioning")):
			return
	_expect(false, "DEBUG action timed out")


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures.append(message)
	push_error("DEBUG NEXT STEP SMOKE: %s" % message)


func _finish() -> void:
	if failures.is_empty():
		print("DEBUG_NEXT_STEP_SMOKE_OK")
		quit(0)
	else:
		print("DEBUG_NEXT_STEP_SMOKE_FAILED: %s" % [failures])
		quit(1)
