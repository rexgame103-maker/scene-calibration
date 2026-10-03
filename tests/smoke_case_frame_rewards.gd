extends SceneTree


var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var profile := root.get_node_or_null("PlayerProfile")
	_expect(is_instance_valid(profile), "PlayerProfile should exist")
	if not is_instance_valid(profile):
		_finish()
		return
	profile.call("reset_profile", false)
	for reward: Dictionary in [
		{"case_id":"office_case_001", "kind":"case_frame_office"},
		{"case_id":"gallery_case_002", "kind":"case_frame_gallery"},
		{"case_id":"apartment_case_003", "kind":"case_frame_apartment"}
	]:
		profile.call("complete_case", String(reward.case_id), "", false)
		_expect(int((profile.get("owned_furniture") as Dictionary).get(String(reward.kind), 0)) == 1, "%s should grant one frame" % reward.case_id)
	profile.call("complete_case", "office_case_001", "", false)
	_expect(int((profile.get("owned_furniture") as Dictionary).get("case_frame_office", 0)) == 1, "Replaying a case should not duplicate its frame")

	var frame_info := StudioFurnitureFactory.get_info("case_frame_office")
	_expect(bool(frame_info.get("wall_item", false)), "Case frames should be marked as wall-only furniture")
	var frame_model := StudioFurnitureFactory.build("case_frame_office")
	var photo_mesh := frame_model.find_child("CasePhoto", true, false) as MeshInstance3D
	_expect(is_instance_valid(photo_mesh) and is_instance_valid(photo_mesh.material_override) and is_instance_valid((photo_mesh.material_override as StandardMaterial3D).albedo_texture), "Case frame should display the archived or fallback case image")
	_expect(is_instance_valid(photo_mesh) and photo_mesh.mesh is QuadMesh, "Case frame should map its image onto a single UV quad")
	if is_instance_valid(photo_mesh) and photo_mesh.mesh is QuadMesh:
		var quad := photo_mesh.mesh as QuadMesh
		var texture := (photo_mesh.material_override as StandardMaterial3D).albedo_texture
		if is_instance_valid(texture) and texture.get_height() > 0:
			var displayed_aspect := quad.size.x / quad.size.y
			var texture_aspect := float(texture.get_width()) / float(texture.get_height())
			_expect(absf(displayed_aspect - texture_aspect) < 0.01, "Case frame should preserve the source photo aspect ratio")
	frame_model.free()

	var studio := (load("res://scenes/studio/calibrator_studio.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(studio)
	current_scene = studio
	await process_frame
	await process_frame
	var furniture_root := studio.get_node("StudioFurniture") as Node3D
	var size := frame_info.get("size", Vector3.ONE) as Vector3
	var back_snap := studio.call("_find_wall_snap", Vector3(0, 1.6, 5), Vector3(0, 0, -1), size, 0) as Dictionary
	var left_snap := studio.call("_find_wall_snap", Vector3(5, 1.6, 0), Vector3(-1, 0, 0), size, 0) as Dictionary
	_expect(String(back_snap.get("side", "")) == "back" and is_equal_approx(float(back_snap.get("yaw", 0.0)), 180.0), "Frame should snap to and face away from the back wall")
	_expect(String(left_snap.get("side", "")) == "left" and is_equal_approx(float(left_snap.get("yaw", 0.0)), -90.0), "Frame should snap to and face away from the left wall")

	var placed := StudioFurnitureFactory.build("case_frame_office")
	furniture_root.add_child(placed)
	placed.global_position = back_snap.get("position", Vector3.ZERO)
	placed.rotation_degrees.y = float(back_snap.get("yaw", 0.0))
	placed.set_meta("studio_floor", 0)
	placed.set_meta("wall_side", "back")
	placed.set_meta("wall_room", 0)
	_expect(not bool(studio.call("_wall_placement_clear", placed.global_position, size, null, back_snap)), "A second frame must not overlap an existing wall frame")

	studio.set("selected_furniture", placed)
	studio.call("_enter_rotation_mode")
	_expect(not bool(studio.get("rotation_mode")), "Wall frames should not enter free XYZ rotation mode")
	studio.call("_focus_selected_furniture")
	_expect(bool(studio.get("camera_focused")), "Inspecting a frame should enter the close-up camera")

	placed.position += Vector3(2.0, 3.0, 2.0)
	studio.call("_clamp_restored_node", placed)
	_expect(String(placed.get_meta("wall_side", "")) == "back" and absf(placed.position.z - float(back_snap.get("plane", 0.0))) < 0.01, "Restored frames should be clamped back onto their saved wall")
	studio.call("_save_layout")
	var saved_layout := profile.get("placed_studio_layout") as Array
	_expect(not saved_layout.is_empty() and String((saved_layout[0] as Dictionary).get("wall_side", "")) == "back", "Studio save data should preserve frame wall attachment")
	_finish()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures.append(message)
	push_error("CASE FRAME REWARD SMOKE: %s" % message)


func _finish() -> void:
	if failures.is_empty():
		print("CASE_FRAME_REWARD_SMOKE_OK")
		quit(0)
	else:
		print("CASE_FRAME_REWARD_SMOKE_FAILED: %s" % [failures])
		quit(1)
