extends SceneTree

func _initialize() -> void:
	for path: String in ["res://scenes/main.tscn", "res://scenes/cases/office_parts/room.tscn", "res://scenes/cases/office_parts/desk.tscn", "res://scenes/cases/office_restored_concept.tscn"]:
		var root := (load(path) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
		var desk := root.get_node_or_null("EditorOfficePreview/Desk/WritingDesk") as Node3D
		if desk == null: desk = root.get_node_or_null("WritingDesk") as Node3D
		var traces := root.get_node_or_null("PrimitiveRoom/ConceptOfficeShell/FloorAndContactTraces")
		if traces == null: traces = root.get_node_or_null("FloorAndContactTraces")
		var wear: Node3D
		if desk != null:
			wear = desk.get_node_or_null("SideWearMarks") as Node3D
			if wear == null:
				wear = Node3D.new()
				wear.name = "SideWearMarks"
				desk.add_child(wear)
				wear.owner = root
		if traces != null:
			for mark in traces.get_children():
				# Legacy duplicate rod names were auto-renamed by Godot.
				if not mark is MeshInstance3D or mark.position.y < 0.6 or absf(mark.position.x - 1.8) > 0.01: continue
				mark.free()
		if wear != null:
			# Rebuild all seven strokes as one assembly on the cabinet side.
			for child in wear.get_children(): child.free()
			for i in range(7):
				var mark := MeshInstance3D.new()
				mark.name = "ContactScratch%d" % (i + 1)
				var mesh := BoxMesh.new()
				mesh.size = Vector3(0.003, 0.009, 0.37 + (i % 3) * 0.045)
				mark.mesh = mesh
				var material := StandardMaterial3D.new()
				material.albedo_color = Color("352d20")
				material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				mark.material_override = material
				mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				mark.position = Vector3(1.601, 0.72 + i * 0.024, 0.26)
				wear.add_child(mark)
				mark.owner = root
			assert(wear.get_child_count() == 7)
		var packed := PackedScene.new()
		assert(packed.pack(root) == OK)
		assert(ResourceSaver.save(packed, path) == OK)
		root.free()
		print("DESK_WEAR_FIXED: ", path)
	quit()
