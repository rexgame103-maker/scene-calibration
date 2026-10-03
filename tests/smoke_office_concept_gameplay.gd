extends SceneTree

var main: Node3D
var cm: Node
var rm: Node
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, reason: String) -> void:
	if not value:
		failures.append(reason)
		push_error(reason)

func place(zone_id: String) -> Node3D:
	var zone := (rm.get("zones") as Dictionary).get(zone_id) as ReconstructionZone
	check(zone != null,"Missing zone "+zone_id)
	if zone == null: return null
	check(main.call("_debug_place_furniture_in_zone",zone),"Place failed "+zone_id)
	return main.call("_debug_find_placed_furniture_by_id",zone.required_furniture_id) as Node3D

func inspect(item: Node3D, path: String) -> void:
	var clue := item.get_node(path) as SceneCluePoint
	clue.set_inspection_context(item)
	check(clue.is_unlocked,"Clue should unlock "+path)
	clue.investigate()
	(main.get("scene_clue_popup") as SceneCluePopup).close()

func _run() -> void:
	cm = root.get_node("CaseManager")
	rm = root.get_node("ReconstructionManager")
	cm.call("load_case","res://data/cases/office_case_001.json")
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	await physics_frame
	var flow := main.get("first_case_flow_ui") as FirstCaseFlowUI
	flow.call("_on_accept_pressed")
	check(main.get_node("PlacedFurniture").get_child_count()==0,"Office must begin cleared")
	check(not main.has_node("EditorOfficePreview"),"Editor furniture preview must not appear during gameplay")
	cm.call("view_evidence","mail_photo_01")
	# Exercise the actual inventory -> preview -> commit path, not just the debug placer.
	main.call("_begin_placement","desk")
	var preview := main.get("active_preview") as Node3D
	check(preview.has_node("WritingDesk/CaseNotes"),"Desk preview includes papers")
	preview.position=Vector3(0.1,0,-2.26)
	preview.visible=true
	main.set("placement_valid",true)
	main.set("preview_bounds_size",Vector2(3.45,1.55))
	main.set("preview_bounds_offset",Vector2.ZERO)
	main.call("_finish_placement")
	var desk := main.call("_debug_find_placed_furniture_by_id","desk") as RigidBody3D
	await create_timer(0.9).timeout
	check(absf(desk.position.y)<0.08,"Desk settles onto floor")
	desk.freeze=true
	rm.call("notify_furniture_placement_completed",desk)
	# A valid off-centre position in the edited scene must survive Debug.
	var desk_zone := (rm.get("zones") as Dictionary)["zone_desk_original"] as ReconstructionZone
	var saved_main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	var saved_zone := saved_main.get_node("ReconstructionZones/DeskOriginalZone") as ReconstructionZone
	check(desk_zone.zone_size.is_equal_approx(saved_zone.zone_size), "Runtime uses editor-authored desk bounds")
	check(desk_zone.transform.is_equal_approx(saved_zone.transform), "Runtime uses editor-authored desk transform")
	saved_main.free()
	var desk_start := desk.position
	desk.position.z = desk_zone.position.z + desk_zone.zone_size.z * 0.4
	var offset_position := desk.position
	check(desk_zone.contains_furniture(desk), "Off-centre desk origin is inside authored zone")
	desk_zone.is_satisfied = false
	var next_zone := main.call("_debug_find_next_placeable_zone") as ReconstructionZone
	check(next_zone != desk_zone, "Debug refreshes state and skips valid off-centre desk")
	await main.call("_debug_advance_next_step")
	check(desk.position.is_equal_approx(offset_position), "Debug next step does not recenter valid desk")
	desk.position = desk_start
	place("zone_chair_at_desk")
	main.call("_begin_placement","computer")
	preview=main.get("active_preview") as Node3D
	check(preview.has_node("Keyboard/Key") and preview.has_node("Computer"),"Computer drag preview includes keyboard keys")
	preview.position=desk.position+Vector3(0,1.218,0)
	preview.visible=true
	main.set("placement_valid",true)
	main.set("preview_bounds_size",Vector2(1.75,1.15))
	main.set("preview_bounds_offset",Vector2.ZERO)
	main.set("preview_surface_height",desk.position.y+1.21)
	main.set("preview_support_node",desk)
	main.set("preview_support_surface_id","surface")
	main.call("_finish_placement")
	var computer := main.call("_debug_find_placed_furniture_by_id","office_computer") as Node3D
	await physics_frame
	var key_position := (computer.get_node("Model/Keyboard/Key") as Node3D).global_position
	var query := PhysicsRayQueryParameters3D.create(key_position+Vector3.UP*3,key_position-Vector3.UP*0.1,2)
	query.collide_with_areas=true
	query.collide_with_bodies=false
	var hit := main.get_world_3d().direct_space_state.intersect_ray(query)
	check(not hit.is_empty() and hit.collider.get_meta("furniture_root",null)==computer,"Clicking keyboard picks computer assembly, not desk")
	check(desk.has_node("Model/WritingDesk/CaseNotes"),"Desk owns papers")
	var wear := desk.get_node("Model/WritingDesk/SideWearMarks") as Node3D
	check(wear.get_child_count() == 7, "Desk owns all seven contact scratches")
	var desk_transform := desk.transform
	desk.position += Vector3(0.4, 0, 0.2)
	desk.rotation.y += 0.6
	for mark: Node3D in wear.get_children():
		check(is_equal_approx(mark.position.x, 1.601), "Scratch lies on cabinet side")
		check(mark.global_position.is_equal_approx(desk.to_global(mark.position)), "Scratch follows desk translation and rotation")
	desk.transform = desk_transform
	for mark: Node3D in main.get_node("PrimitiveRoom/ConceptOfficeShell/FloorAndContactTraces").get_children():
		check(mark.position.y < 0.6, "No floating contact scratches remain in fixed room")
	check(not desk.has_node("Model/WritingDesk/Keyboard"),"Keyboard must not be baked into desk")
	check(computer.has_node("Model/Keyboard") and computer.has_node("Model/Computer"),"Computer owns keyboard and monitor")
	var snap: Dictionary = main.call("_find_surface_snap","computer",computer.position,main.call("_furniture_info","computer").size,Vector3.ZERO)
	check(not snap.is_empty() and snap.get("support")==desk,"Computer assembly must snap to desk")
	check(rm.call("has_step_completed","office_workstation"),"Workstation stage")
	inspect(desk,"DeskSideWearClue")
	place("zone_small_cabinet_original")
	inspect(computer,"ComputerWorkLog")
	var shelf := place("zone_shelf_original")
	var printer := place("zone_printer_original")
	inspect(printer,"PrinterPhoto")
	place("zone_water_dispenser_original")
	var red := place("zone_red_file_slot")
	place("zone_gray_file_slot")
	place("zone_ordinary_file_01_slot")
	check(rm.call("is_step_satisfied","office_complete"),"Office completion")
	var red_snap: Dictionary = main.call("_find_surface_snap","red_file",red.position,main.call("_furniture_info","red_file").size,Vector3.ZERO)
	check(red_snap.get("support")==shelf,"Files snap to new shelf")
	for entry: Dictionary in main.get("placed_items"):
		main.call("_prepare_moving_supported_items",entry.node,false)
		check(main.call("_can_place_at",entry.node.position,entry.bounds_size,entry.bounds_offset,entry.node,entry.get("support_node"),entry.get("support_surface_id","")),"Target blocked by overlap: "+str(entry.kind))
		main.call("_restore_moving_supported_items")
	var computer_origin := computer.global_position
	main.call("_prepare_moving_supported_items",desk,false)
	var moved := desk.global_transform
	moved.origin.x += 0.3
	main.call("_sync_moving_supported_items",moved,true)
	check(computer.global_position.is_equal_approx(computer_origin+Vector3(0.3,0,0)),"Moving desk carries supported computer assembly")
	main.call("_restore_moving_supported_items")
	# Moving a parent must carry all visual pieces, including every keyboard key.
	var key := computer.get_node("Model/Keyboard/Key") as Node3D
	var original := key.global_position
	computer.position.x += 0.25
	check(key.global_position.is_equal_approx(original+Vector3(0.25,0,0)),"Keyboard keys move as one assembly")
	computer.position.x -= 0.25
	# Right colour on the wrong slot must fail the final spatial relationship.
	var red_origin := red.position
	red.global_position = shelf.to_global(Vector3(0.37,1.27,0.12))
	rm.call("notify_furniture_placement_completed",red)
	check(not rm.call("is_step_satisfied","office_complete"),"Wrong binder order must fail")
	red.position=red_origin
	rm.call("notify_furniture_placement_completed",red)
	main.call("_submit_first_case_reconstruction")
	check(flow.settlement_panel.visible,"Submission opens settlement")
	if DisplayServer.get_name() != "headless":
		flow.settlement_panel.visible=false
		flow.modal_backdrop.visible=false
		for n in main.get_children():
			if n is CanvasLayer: n.visible=false
		root.size=Vector2i(1536,1024)
		await create_timer(1.2).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/office_gameplay_restored.png")
		# New evidence is photographed from the actual new assets.
		var camera := main.get_node("IsometricCamera") as Camera3D
		var original_camera := camera.transform
		var original_fov := camera.fov
		for item in main.get_node("PlacedFurniture").get_children():
			item.visible=str(item.get_meta("furniture_kind","")).is_empty() or str(item.get_meta("furniture_kind","")) in ["desk","chair","computer"]
		camera.transform=Transform3D(Basis.IDENTITY,Vector3(-4,7,8)).looking_at(Vector3(0,0.8,-2.1))
		camera.fov=29
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://assets/case_photos/office/concept_workstation.png")
		for item in main.get_node("PlacedFurniture").get_children():
			item.visible=str(item.get_meta("furniture_kind","")) in ["shelf","water_dispenser","red_file","gray_file","ordinary_file_01"]
		camera.transform=Transform3D(Basis.IDENTITY,Vector3(-1.8,4.5,3.5)).looking_at(Vector3(-2.9,1.45,-2.5))
		camera.fov=33
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://assets/case_photos/office/concept_equipment.png")
		camera.transform=original_camera
		camera.fov=original_fov
	print("OFFICE_GAMEPLAY_OK" if failures.is_empty() else "OFFICE_GAMEPLAY_FAILED: "+str(failures))
	quit(0 if failures.is_empty() else 1)
