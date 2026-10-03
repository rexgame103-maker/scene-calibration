extends RefCounted
const DIR := "res://scenes/cases/gallery_parts/"
const SIZES := {"restoration_table":Vector3(2.9,1.7,1.55),"restoration_stool":Vector3(0.72,0.85,0.72),"cold_light_panel":Vector3(2.9,2.55,1.1),"halogen_inspection_lamp":Vector3(0.72,1.93,0.72),"metal_reflector":Vector3(1.4,2.3,0.8),"camera_tripod":Vector3(1.15,1.72,1.15)}
static func get_info(kind: String) -> Dictionary:
	var info := FurnitureFactory.get_info(kind).duplicate(true)
	if SIZES.has(kind): info.size = SIZES[kind]
	return info
static func build(kind: String, preview: bool, overrides: Dictionary = {}) -> Node3D:
	if not SIZES.has(kind): return FurnitureFactory.build(kind,preview,overrides)
	var physics := overrides.duplicate()
	if not physics.has("size"): physics.size = SIZES[kind]
	var body := FurnitureFactory.build(kind,preview,physics)
	# Keep the established calibration objects and device logic, replacing shell meshes.
	var evidence_names := ["EvidenceGlossPatch","ScalpelTool"]
	for child in body.get_children():
		if child is MeshInstance3D:
			if kind == "restoration_table" and evidence_names.has(String(child.name)):
				child.position.y += 0.19
			else: child.free()
	var art := (load(DIR+kind+".tscn") as PackedScene).instantiate() as Node3D
	art.name = "ConceptModel"
	if kind == "restoration_table":
		for child in art.get_children():
			if String(child.name) == "ScalpelTool": child.free()
		art.get_node("PanelPainting/Panel").name = "ArtworkSurface"
	if kind == "metal_reflector":
		var back := art.get_node("ReflectingSurface").duplicate() as MeshInstance3D
		back.name = "ReflectingBack"
		back.position.z *= -1
		art.add_child(back)
	if kind in ["cold_light_panel","halogen_inspection_lamp","metal_reflector"]:
		art.rotation.y = PI
	body.add_child(art)
	var device := body.get_node_or_null("CaseLightDevice") as CaseLightDevice
	if device != null:
		if kind == "cold_light_panel": device.configure("cold_panel",1.35,6800,0,-50,2.7,43,true,Vector3(0,2.26,-0.54))
		if kind == "halogen_inspection_lamp": device.configure("halogen",0.0,3200,0,-24,5.2,48,true,Vector3(0,1.73,-0.23))
		if kind == "metal_reflector": device.configure("reflector",0,4200,0,0,4.5,62,false,Vector3(0,1.35,-0.09))
		device.set_enabled(not preview)
	if not preview:
		for area in body.get_children():
			if area is Area3D:
				for shape in area.get_children():
					if shape is CollisionShape3D and shape.shape is BoxShape3D:
						shape.shape = shape.shape.duplicate()
						shape.shape.size = SIZES[kind]
						shape.position.y = SIZES[kind].y*0.5
	return body
