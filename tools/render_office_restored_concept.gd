extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(1536,1024)
	root.msaa_3d = Viewport.MSAA_4X
	var packed := load("res://scenes/cases/office_restored_concept.tscn") as PackedScene
	assert(packed != null)
	var editable := packed.instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	assert(editable.get_script() == null)
	assert(editable.get_node("OfficeChair/NormalizedModel/chair").get_child_count() == 1)
	var roundtrip := PackedScene.new()
	assert(roundtrip.pack(editable) == OK)
	assert(ResourceSaver.save(roundtrip,"user://office_concept_roundtrip.tscn") == OK)
	editable.free()
	var reloaded := ResourceLoader.load("user://office_concept_roundtrip.tscn","PackedScene",ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	var check := reloaded.instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	assert(check.get_node("TallFilingShelf/RedBinder").position.x < check.get_node("TallFilingShelf/GrayBinder").position.x)
	assert(check.get_node("TallFilingShelf/GrayBinder").position.x < check.get_node("TallFilingShelf/BeigeBinder").position.x)
	check.free()
	var office := packed.instantiate()
	root.add_child(office)
	current_scene=office
	await create_timer(1.4).timeout
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://tests/office_restored_concept_preview.png") == OK)
	print("OFFICE_CONCEPT_OK: editor roundtrip, binder order, single chair mesh, no scene script, rendered")
	quit()
