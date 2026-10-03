extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(1280, 720)
	var scene := load("res://scenes/studio/noir/noir_studio.tscn") as PackedScene
	if scene == null:
		quit(1)
		return
	var studio := scene.instantiate()
	root.add_child(studio)
	current_scene = studio
	await process_frame
	await process_frame
	assert(studio.get_node("Artwork/Hotspots").get_child_count() == 6)
	var recorder := studio.get_node("Artwork/Hotspots/Recorder") as Polygon2D
	var artwork := studio.get_node("Artwork") as Node2D
	studio.call("_update_hover", artwork.to_global(Vector2(1180, 350)))
	assert(studio.get("hovered") == recorder, "Recorder should override the desk hotspot")
	studio.call("_show_selection", recorder)
	assert(studio.get_node("HUD/Panel/Margin/Column/Heading").text == "磁带录音机")
	studio.call("_reset_view")
	# Let the project's existing startup fade finish before visual verification.
	await create_timer(1.1).timeout
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png("res://tests/noir_studio_preview.png")
	if error != OK:
		quit(1)
		return
	print("NOIR_STUDIO_OK: loaded, recorder hit priority, inspection, reset, screenshot")
	quit(0)
