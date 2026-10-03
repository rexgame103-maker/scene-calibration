extends SceneTree
## Keep editable scene nodes while storing mesh data in compressed resources.

func _initialize() -> void:
	var path := "res://scenes/main.tscn"
	var scene := load(path) as PackedScene
	var state := scene.get_state()
	var output := "res://assets/office_scene_meshes"
	DirAccess.make_dir_recursive_absolute(output)
	var meshes: Dictionary = {}
	for i in state.get_node_count():
		for j in state.get_node_property_count(i):
			var value: Variant = state.get_node_property_value(i, j)
			if not (value is Mesh or value is Material): continue
			var mesh := value as Resource
			if meshes.has(mesh.get_instance_id()): continue
			if not mesh.resource_path.is_empty() and not mesh.resource_path.contains("::"): continue
			var name_key := (String(state.get_node_path(i)) + String(state.get_node_property_name(i, j))).md5_text().substr(0, 16)
			var mesh_path := output + "/resource_" + name_key + ".res"
			assert(ResourceSaver.save(mesh, mesh_path, ResourceSaver.FLAG_COMPRESS | ResourceSaver.FLAG_CHANGE_PATH) == OK)
			mesh.take_over_path(mesh_path)
			meshes[mesh.get_instance_id()] = mesh_path
	var root := scene.instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	var packed := PackedScene.new()
	assert(packed.pack(root) == OK)
	assert(ResourceSaver.save(packed, path) == OK)
	root.free()
	var reloaded := ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	assert(reloaded != null and reloaded.get_state().get_node_count() == state.get_node_count())
	var check := reloaded.instantiate()
	assert(check.has_node("EditorOfficePreview/Computer/Keyboard/Key"))
	assert(check.get_node("ReconstructionZones").get_child_count() == 5)
	check.free()
	print("MAIN_MESH_RESOURCES_OK: ", meshes.size(), " external resources; scene bytes=", FileAccess.get_file_as_bytes(path).size())
	quit()
