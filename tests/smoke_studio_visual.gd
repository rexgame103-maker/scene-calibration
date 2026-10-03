extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var studio := (load("res://scenes/studio/calibrator_studio.tscn") as PackedScene).instantiate()
	root.add_child(studio)
	current_scene = studio
	await process_frame
	await process_frame
	var furniture_root := studio.get_node_or_null("StudioFurniture")
	print("STUDIO_FURNITURE_COUNT=", furniture_root.get_child_count() if is_instance_valid(furniture_root) else -1)
	await create_timer(1.2).timeout
	var texture := root.get_texture()
	if texture != null:
		var image := texture.get_image()
		if image != null and not image.is_empty():
			image.save_png("res://tests/studio_preview.png")
	print("STUDIO_VISUAL_SMOKE_OK")
	quit(0)
