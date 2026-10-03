extends RefCounted

static func resize_box(node: MeshInstance3D, size: Vector3) -> void:
	node.mesh = node.mesh.duplicate()
	(node.mesh as BoxMesh).size = size
	if node.material_override is ShaderMaterial:
		node.material_override = node.material_override.duplicate()
		node.material_override.set_shader_parameter("half_size", size * 0.5)

static func apply(scene: Node3D) -> void:
	if scene.has_meta("studio_layout_v2"):
		return
	var architecture := scene.get_node("Architecture")
	var removed := 0
	for child in architecture.get_children():
		if not child is MeshInstance3D or not child.mesh is BoxMesh:
			continue
		var size: Vector3 = child.mesh.size
		# The old tiles have anonymous generated names; identify their geometry.
		if size.is_equal_approx(Vector3(0.985, 0.045, 0.685)):
			child.free()
			removed += 1
			continue
		if child.name == "Foundation":
			resize_box(child, size + Vector3(0, 0, 1.4))
			child.position.z -= 0.7
		elif child.name in ["WindowWallLower", "WindowWallUpper", "WindowWallBackPier"] or (is_equal_approx(size.x, 0.08) and is_equal_approx(size.z, 7.0)):
			resize_box(child, size + Vector3(0, 0, 1.4))
			child.position.z -= 0.7
		elif child.position.z < -3.2:
			child.position.z -= 1.4
	# Keep the desk in place and move the rear work/storage zone back.
	for child in scene.get_children():
		if not child is Node3D:
			continue
		if child.name in ["MiniatureWorkbench", "ArchiveBookcase", "PrinterCabinet"] or child.position.z < -2.9:
			child.position.z -= 1.4
	var floor_group := scene.get_node("WoodFloor")
	for plank in floor_group.get_children():
		if plank.position.z < -2.2:
			var extension := plank.duplicate() as Node3D
			extension.name = "ExtendedFloorboard"
			extension.position.z -= 1.4
			floor_group.add_child(extension, true)
	var ceiling := scene.get_node("CeilingLightBlocker") as MeshInstance3D
	resize_box(ceiling, (ceiling.mesh as BoxMesh).size + Vector3(0, 0, 1.4))
	ceiling.position.z -= 0.7
	scene.get_node("Camera3D").size = 15.5
	scene.set_meta("studio_layout_v2", true)
	print("STUDIO_LAYOUT_FIXED: removed ", removed, " overlapping tiles; rear wall/workbench moved 1.4m")
