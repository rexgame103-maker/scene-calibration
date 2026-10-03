extends SceneTree


var failures: Array[String] = []
var profile: Node
var case_manager: Node
var reconstruction_manager: Node
var main: Node3D


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	profile = root.get_node_or_null("PlayerProfile")
	case_manager = root.get_node_or_null("CaseManager")
	reconstruction_manager = root.get_node_or_null("ReconstructionManager")
	_expect(is_instance_valid(profile), "PlayerProfile autoload should exist")
	_expect(is_instance_valid(case_manager), "CaseManager autoload should exist")
	_expect(is_instance_valid(reconstruction_manager), "ReconstructionManager autoload should exist")
	if not is_instance_valid(profile) or not is_instance_valid(case_manager):
		_finish()
		return

	profile.call("reset_profile", false)
	_expect(int(profile.get("money")) == 700, "New calibrator should start with 700 currency")
	_expect(int(profile.call("get_unread_mail_count")) == 1, "Only the first police commission should be unread initially")
	_expect(not bool(profile.call("has_studio_workstation")), "Empty studio must not enter work mode")
	profile.call("set_studio_layout", [
		{"kind":"studio_desk","position":[0,0,0],"rotation_y":0,"floor":0},
		{"kind":"studio_chair","position":[0,0,1.4],"rotation_y":0,"floor":0},
		{"kind":"studio_computer","position":[0,1.06,0],"rotation_y":0,"floor":0}
	])
	_expect(bool(profile.call("has_studio_workstation")), "Desk, chair and computer should unlock work mode")
	var case_id := String(profile.call("accept_mail", "mail_case_001"))
	_expect(case_id == "office_case_001", "First mail should accept blue document case")
	var definition := profile.call("get_case_definition", case_id) as Dictionary
	_expect(bool(case_manager.call("load_case", String(definition.get("data_path", "")))), "First case data should load")
	await process_frame

	main = (load("res://scenes/main.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(main)
	current_scene = main
	await process_frame
	await process_frame
	await physics_frame
	var flow := main.get("first_case_flow_ui") as FirstCaseFlowUI
	_expect(is_instance_valid(flow), "Case scene should create flow UI")
	flow.call("_on_accept_pressed")
	_view("mail_photo_01")
	_expect(_inventory("desk") == 1 and _inventory("chair") == 1 and _inventory("computer") == 1, "Mail photo should unlock desk, chair and computer")

	var desk := _place_zone("desk", "zone_desk_original")
	var chair_zone := desk.get_node("ChairRelationZone") as ReconstructionZone
	_place_global("chair", chair_zone.global_position)
	var computer_zone := desk.get_node("ComputerRelationZone") as ReconstructionZone
	var computer := _place_global("computer", computer_zone.global_position)
	_expect(bool(reconstruction_manager.call("has_step_completed", "office_workstation")), "Desk-chair-computer workstation should complete")
	var wear := desk.get_node("DeskSideWearClue") as SceneCluePoint
	wear.set_inspection_context(desk)
	wear.investigate()
	(main.get("scene_clue_popup") as SceneCluePopup).close()
	_expect(_inventory("small_shelf") == 1, "Desk wear should unlock white cabinet")
	_place_zone("small_shelf", "zone_small_cabinet_original")
	_expect(bool(reconstruction_manager.call("has_step_completed", "small_cabinet_restored")), "Cabinet should restore desk side")

	var work_log := computer.get_node_or_null("ComputerWorkLog") as SceneCluePoint
	_expect(is_instance_valid(work_log), "Computer should receive data-driven work log clue")
	work_log.set_inspection_context(computer)
	work_log.investigate()
	(main.get("scene_clue_popup") as SceneCluePopup).close()
	_expect(_inventory("shelf") == 1 and _inventory("printer") == 1, "Work log should unlock shelf and printer")
	var shelf := _place_zone("shelf", "zone_shelf_original")
	var printer := _place_zone("printer", "zone_printer_original")
	_expect(bool(reconstruction_manager.call("has_step_completed", "equipment_restored")), "Shelf and printer should restore equipment area")
	var printer_photo := printer.get_node_or_null("PrinterPhoto") as SceneCluePoint
	_expect(is_instance_valid(printer_photo), "Printer should receive data-driven printed photo clue")
	printer_photo.set_inspection_context(printer)
	printer_photo.investigate()
	(main.get("scene_clue_popup") as SceneCluePopup).close()
	_expect(_inventory("water_dispenser") == 1 and _inventory("red_file") == 1 and _inventory("gray_file") == 1 and _inventory("ordinary_file_01") == 1, "Printed photo should unlock final furniture and files")
	_place_zone("water_dispenser", "zone_water_dispenser_original")
	_place_global("red_file", (shelf.get_node("RedFileSlot") as ReconstructionZone).global_position)
	_place_global("gray_file", (shelf.get_node("GrayFileSlot") as ReconstructionZone).global_position)
	_place_global("ordinary_file_01", (shelf.get_node("OrdinaryFile01Slot") as ReconstructionZone).global_position)
	_expect(bool(reconstruction_manager.call("is_step_satisfied", "office_complete")), "Simplified office should be complete")
	main.call("_submit_first_case_reconstruction")
	_expect(flow.settlement_panel.visible, "Complete office should open settlement")

	profile.call("complete_case", "office_case_001", "")
	_expect(int(profile.get("money")) == 1900, "First case reward should be paid")
	_expect(int((profile.get("owned_furniture") as Dictionary).get("case_frame_office", 0)) == 1, "Completing the first case should grant its studio photo frame")
	_expect(int(profile.call("get_unread_mail_count")) == 3, "Reward mail and two follow-up cases should arrive")
	var unlocked_ids: Array[String] = []
	for shop_value: Variant in profile.call("get_shop_items"):
		var shop_item := shop_value as Dictionary
		if bool(shop_item.get("is_unlocked", false)):
			unlocked_ids.append(String(shop_item.get("item_id", "")))
	_expect(unlocked_ids.has("analysis_board") and unlocked_ids.has("reference_lightbox"), "First case should unlock functional furniture")
	_expect(bool(profile.call("purchase_item", "analysis_board")), "Analysis board should be purchasable with reward")
	var layout: Array = (profile.get("placed_studio_layout") as Array).duplicate(true)
	layout.append({"kind":"analysis_board","position":[2,0,0],"rotation_y":0,"floor":0})
	profile.call("set_studio_layout", layout)
	_expect(bool(profile.call("has_skill", "trace_counter")), "Placed analysis board should activate its skill")
	layout.pop_back()
	profile.call("set_studio_layout", layout)
	_expect(not bool(profile.call("has_skill", "trace_counter")), "Removing analysis board should remove its skill")

	for followup_id: String in ["gallery_case_002", "apartment_case_003"]:
		var followup := profile.call("get_case_definition", followup_id) as Dictionary
		_expect(bool(case_manager.call("load_case", String(followup.get("data_path", "")))), "%s should load" % followup_id)
		_expect(not (case_manager.call("get_reconstruction_zones") as Array).is_empty(), "%s should define reusable zones" % followup_id)
		var overview_pan := bool((case_manager.call("get_scene_layout") as Dictionary).get("overview_pan", false))
		if followup_id == "apartment_case_003":
			_expect(overview_pan, "Two-room apartment case should enable overview panning")
		else:
			_expect(not overview_pan, "Single-room restoration case should stay on one overview")
	_finish()


func _view(evidence_id: String) -> void:
	case_manager.call("view_evidence", evidence_id)


func _inventory(kind: String) -> int:
	return int((main.get("inventory_counts") as Dictionary).get(kind, 0))


func _place_zone(kind: String, zone_id: String) -> Node3D:
	var zone := (reconstruction_manager.get("zones") as Dictionary).get(zone_id, null) as ReconstructionZone
	_expect(is_instance_valid(zone), "Zone %s should exist" % zone_id)
	var node := _place_global(kind, zone.global_position)
	if is_instance_valid(zone) and (zone.require_orientation or not is_zero_approx(zone.target_yaw_degrees)):
		node.rotation_degrees.y = zone.global_rotation_degrees.y + zone.target_yaw_degrees
		reconstruction_manager.call("notify_furniture_placement_completed", node)
	return node


func _place_global(kind: String, position: Vector3) -> Node3D:
	var node := main.call("_build_furniture", kind) as Node3D
	main.get_node("PlacedFurniture").add_child(node)
	node.global_position = position
	var body := node as RigidBody3D
	if is_instance_valid(body):
		body.freeze = true
	reconstruction_manager.call("notify_furniture_placement_completed", node)
	return node


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("CAMPAIGN SMOKE: %s" % message)


func _finish() -> void:
	if is_instance_valid(profile):
		profile.call("reset_profile", true)
	if failures.is_empty():
		print("CAMPAIGN_FLOW_SMOKE_OK")
		quit(0)
	else:
		print("CAMPAIGN_FLOW_SMOKE_FAILED: %s" % [failures])
		quit(1)
