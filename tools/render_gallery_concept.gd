extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(1536,1024)
	root.msaa_3d = Viewport.MSAA_4X
	var packed := load("res://scenes/cases/gallery_restored_concept.tscn") as PackedScene
	var room := packed.instantiate()
	assert(room.get_script() == null)
	var ceiling := room.get_node("Architecture/CeilingLightBlocker") as MeshInstance3D
	assert(ceiling.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY)
	assert((room.get_node("Architecture/RearWall") as MeshInstance3D).cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON)
	assert((room.get_node("StandardColdLight/CoolWorkLight") as SpotLight3D).shadow_enabled)
	for part in ["RestorationTable","RestorationStool","StandardColdLight","MetalReflector","HalogenInspectionLamp","PhotographyTripod","SupplyTrolley"]:
		assert(room.has_node(part))
	assert(room.find_children("*","CollisionObject3D",true,false).is_empty())
	root.add_child(room)
	current_scene=room
	var check := PackedScene.new()
	assert(check.pack(room) == OK)
	await create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/gallery_concept_preview.png")
	print("GALLERY_SCENE_OK: editable groups, no interactions, scene roundtrip, rendered")
	quit()
