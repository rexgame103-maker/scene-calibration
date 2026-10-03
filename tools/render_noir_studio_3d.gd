extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(1536, 960)
	var packed := load("res://scenes/studio/noir/noir_studio_3d.tscn") as PackedScene
	if packed == null:
		quit(1)
		return
	var studio := packed.instantiate()
	root.add_child(studio)
	current_scene = studio
	await create_timer(1.3).timeout
	await RenderingServer.frame_post_draw
	assert(studio is Node3D)
	assert(studio.get_node("WritingDesk/Desktop") is MeshInstance3D)
	assert(studio.get_node("EvidenceBoard/RedThread") is MeshInstance3D)
	var light := studio.get_node("Lighting/DeskLight") as SpotLight3D
	var key := InputEventKey.new()
	key.keycode = KEY_L
	key.pressed = true
	studio.call("_unhandled_input", key)
	assert(not light.visible)
	studio.call("_unhandled_input", key)
	assert(light.visible)
	assert(root.get_texture().get_image().save_png("res://tests/noir_studio_3d_preview.png") == OK)
	studio.set("yaw", -22.0)
	studio.call("_update_camera")
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://tests/noir_studio_3d_orbit.png") == OK)
	print("NOIR_3D_OK: true 3D meshes, saved scene, lamp toggle, rendered main and orbit views")
	quit(0)
