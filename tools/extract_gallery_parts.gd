extends SceneTree
func own_all(node: Node, owner_root: Node) -> void:
	node.scene_file_path = ""
	for child in node.get_children():
		child.owner = owner_root
		own_all(child,owner_root)
func save(node: Node, path: String) -> void:
	own_all(node,node)
	var packed := PackedScene.new()
	assert(packed.pack(node) == OK)
	assert(ResourceSaver.save(packed,path) == OK)
func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://scenes/cases/gallery_parts")
	var room := (load("res://scenes/cases/gallery_restored_concept.tscn") as PackedScene).instantiate()
	var parts := {"RestorationTable":"restoration_table","RestorationStool":"restoration_stool","StandardColdLight":"cold_light_panel","HalogenInspectionLamp":"halogen_inspection_lamp","MetalReflector":"metal_reflector","PhotographyTripod":"camera_tripod"}
	for name_value in parts:
		var part := room.get_node(NodePath(name_value)) as Node3D
		room.remove_child(part)
		part.position = Vector3.ZERO
		if part.has_node("CoolWorkLight"): part.get_node("CoolWorkLight").free()
		save(part,"res://scenes/cases/gallery_parts/"+parts[name_value]+".tscn")
		part.free()
	room.get_node("Camera3D").free()
	room.name = "GalleryShell"
	save(room,"res://scenes/cases/gallery_parts/room.tscn")
	room.free()
	print("GALLERY_PARTS_OK")
	quit()
