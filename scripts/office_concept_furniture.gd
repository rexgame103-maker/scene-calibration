extends RefCounted

const DIR := "res://scenes/cases/office_parts/"
const SIZES := {
	"desk":Vector3(3.45,1.21,1.55), "computer":Vector3(1.75,1.16,1.15),
	"chair":Vector3(1.0,1.35,1.0), "small_shelf":Vector3(1.0,1.16,1.57),
	"shelf":Vector3(1.39,2.99,0.88), "printer":Vector3(1.1,1.76,1.36),
	"water_dispenser":Vector3(0.67,2.33,0.85),
	"red_file":Vector3(0.30,0.74,0.55), "gray_file":Vector3(0.30,0.74,0.55),
	"ordinary_file_01":Vector3(0.30,0.74,0.55)
}

static func get_info(kind: String) -> Dictionary:
	var info := FurnitureFactory.get_info(kind).duplicate(true)
	if SIZES.has(kind): info["size"] = SIZES[kind]
	if kind == "computer":
		info["label"] = "电脑（显示器与键盘）"
		info["surface_inset"] = Vector2.ZERO
	if kind == "desk": info["surface_inset"] = Vector2.ZERO
	return info

static func build(kind: String, preview: bool) -> Node3D:
	if not SIZES.has(kind): return FurnitureFactory.build(kind,preview)
	var art := (load(DIR+kind+".tscn") as PackedScene).instantiate() as Node3D
	if preview:
		art.set_meta("furniture_kind",kind)
		return art
	var body: RigidBody3D
	if kind == "desk":
		body = FurnitureFactory.DESK_FURNITURE_SCENE.instantiate() as RigidBody3D
		body.get_node("Model").free()
		body.set("collision_size",SIZES[kind])
		body.set("collision_offset",Vector3.ZERO)
		body.set_meta("concept_interaction_size",SIZES[kind])
		body.get_node("ChairRelationZone").position = Vector3(0.05,0.50,1.64)
		body.get_node("ChairRelationZone").set("zone_size",Vector3(1.35,1.4,1.0))
		body.get_node("ComputerRelationZone").position = Vector3(0,1.24,0)
		body.get_node("ComputerRelationZone").set("zone_size",Vector3(0.75,0.50,0.65))
		body.get_node("DeskSideWearClue").position = Vector3(1.61,0.9,0.28)
		body.get_node("DeskSideWearClue").set("detail_view_offset",Vector3(1.5,0.32,1.0))
	elif kind == "shelf":
		body = FurnitureFactory.SHELF_FURNITURE_SCENE.instantiate() as RigidBody3D
		body.get_node("Model").free()
		body.set("use_shared_profile",false)
		body.set("collision_size",SIZES[kind])
		body.set("shelf_surface_size",Vector2(1.18,0.72))
		body.set("shelf_surface_offset",Vector2(0,0.06))
		body.set("layer_1_height",0.705)
		body.set("layer_2_height",1.255)
		body.set("layer_3_height",2.225)
		body.set_meta("concept_interaction_size",SIZES[kind])
		body.get_node("MissingBlueFileClue").free()
		body.get_node("OrdinaryFile02Slot").free()
		var names := ["RedFileSlot","GrayFileSlot","OrdinaryFile01Slot"]
		for i in range(3):
			var zone := body.get_node(names[i]) as ReconstructionZone
			zone.transform = Transform3D(Basis.IDENTITY,Vector3(-0.41+i*0.39,1.30,0.12))
			zone.zone_size = Vector3(0.30,0.38,0.40)
	else:
		body = RigidBody3D.new()
		body.collision_layer = 4
		body.collision_mask = 5
		body.mass = 2.0
		body.linear_damp = 1.1
		body.angular_damp = 1.8
		var shape := CollisionShape3D.new()
		shape.name = "FurniturePhysicsShape"
		shape.shape = BoxShape3D.new()
		(shape.shape as BoxShape3D).size = SIZES[kind]
		shape.position.y = (SIZES[kind] as Vector3).y*0.5
		body.add_child(shape)
		var hit := Area3D.new()
		hit.name = "FurnitureHitArea"
		hit.collision_layer = 2
		hit.collision_mask = 0
		hit.set_meta("furniture_root",body)
		var hit_shape := shape.duplicate() as CollisionShape3D
		hit_shape.name = "InteractionShape"
		hit.add_child(hit_shape)
		body.add_child(hit)
	body.name = kind.to_pascal_case()+"Furniture"
	body.set_meta("furniture_kind",kind)
	body.add_child(art)
	if kind == "desk":
		var lamp := SpotLight3D.new()
		lamp.name = "AttachedDeskLight"
		lamp.position = Vector3(0.8,1.79,-0.46)
		lamp.rotation_degrees.x = -90
		lamp.light_color = Color("ffd36b")
		lamp.light_energy = 1.1
		lamp.spot_range = 4.0
		lamp.spot_angle = 50
		body.add_child(lamp)
	return body
