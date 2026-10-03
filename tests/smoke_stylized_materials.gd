extends SceneTree


var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := (load("res://scenes/main.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(scene)
	current_scene = scene
	await process_frame
	var controller := scene.get_node_or_null("StylizedMaterialController") as StylizedMaterialController
	_expect(is_instance_valid(controller), "Main scene should have a stylized material controller")
	var floor_model := scene.get_node_or_null("PrimitiveRoom/ImportedArchitecture/FloorModel")
	_expect(_contains_stylized_mesh(floor_model), "Architecture should use stylized materials")

	var desk := scene.call("_build_furniture", "desk", false) as Node3D
	_expect(is_instance_valid(desk), "Dynamic furniture should still be generated")
	_expect(_contains_stylized_mesh(desk), "Dynamic furniture should receive stylized materials")
	desk.free()

	controller.set_style_enabled(false)
	_expect(not _contains_stylized_mesh(floor_model), "Disabling style should restore original materials")
	controller.set_style_enabled(true)
	_expect(_contains_stylized_mesh(floor_model), "Re-enabling style should restore stylized materials")
	_finish()


func _contains_stylized_mesh(root_node: Node) -> bool:
	if not is_instance_valid(root_node):
		return false
	var candidates: Array[Node] = []
	if root_node is MeshInstance3D:
		candidates.append(root_node)
	candidates.append_array(root_node.find_children("*", "MeshInstance3D", true, false))
	for candidate: Node in candidates:
		var mesh_instance := candidate as MeshInstance3D
		if bool(mesh_instance.get_meta("stylized_material_applied", false)):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("STYLIZED MATERIAL SMOKE: %s" % message)


func _finish() -> void:
	if failures.is_empty():
		print("STYLIZED_MATERIAL_SMOKE_OK")
		quit(0)
	else:
		print("STYLIZED_MATERIAL_SMOKE_FAILED: %s" % [failures])
		quit(1)
