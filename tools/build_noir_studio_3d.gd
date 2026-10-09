extends SceneTree
## Authoring tool: writes a fully editable scene. No runtime procedural builder.

const SHADER = preload("res://shaders/noir_toon.gdshader")
const OUTLINE = preload("res://shaders/stylized_outline.gdshader")
const INK := Color("100d09")
const WOOD := Color("986126")
const GOLD := Color("b88732")
const PAPER := Color("d8b976")
var scene: Node3D
var rng := RandomNumberGenerator.new()
var cache: Dictionary = {}

func _initialize() -> void:
	call_deferred("_build")

func group(label: String, parent: Node3D, at := Vector3.ZERO) -> Node3D:
	var node := Node3D.new()
	node.name = label
	node.position = at
	parent.add_child(node)
	return node

func material(color: Color, dims := Vector3.ZERO, luminous := 0.0) -> ShaderMaterial:
	var key := str(color) + str(dims) + str(luminous)
	if cache.has(key): return cache[key]
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("paint", color)
	mat.set_shader_parameter("box_ink", dims != Vector3.ZERO)
	mat.set_shader_parameter("half_size", dims * 0.5)
	mat.set_shader_parameter("ink_width", minf(0.025, minf(dims.x, minf(dims.y, dims.z)) * 0.25) if dims != Vector3.ZERO else 0.015)
	mat.set_shader_parameter("glow", luminous)
	if dims == Vector3.ZERO and luminous == 0.0:
		var line := ShaderMaterial.new()
		line.shader = OUTLINE
		line.set_shader_parameter("outline_color", INK)
		line.set_shader_parameter("outline_width", 0.016)
		mat.next_pass = line
	cache[key] = mat
	return mat

func box(parent: Node3D, label: String, at: Vector3, dims: Vector3, color: Color, luminous := 0.0) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dims
	var item := MeshInstance3D.new()
	item.name = label
	item.mesh = mesh
	item.position = at
	item.material_override = material(color, dims, luminous)
	if label == "OakPlank":
		item.material_override.set_shader_parameter("ink_width", 0.005)
	parent.add_child(item)
	return item

func cylinder(parent: Node3D, label: String, at: Vector3, radius: float, height: float, color: Color, top := -1.0) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius if top < 0 else top
	mesh.height = height
	mesh.radial_segments = 12
	var item := MeshInstance3D.new()
	item.name = label
	item.mesh = mesh
	item.position = at
	item.material_override = material(color)
	parent.add_child(item)
	return item

func rod(parent: Node3D, label: String, a: Vector3, b: Vector3, radius: float, color: Color) -> void:
	var item := cylinder(parent, label, (a + b) * 0.5, radius, a.distance_to(b), color)
	item.quaternion = Quaternion(Vector3.UP, (b - a).normalized())

func _build() -> void:
	rng.seed = 83126
	scene = Node3D.new()
	scene.name = "NoirStudio3D"
	_shell()
	_desk()
	_board()
	_library()
	_sofa()
	_window()
	_props()
	_setup()
	scene.set_script(load("res://scripts/noir_studio/noir_studio_3d.gd"))
	_own(scene)
	var packed := PackedScene.new()
	assert(packed.pack(scene) == OK)
	assert(ResourceSaver.save(packed, "res://scenes/studio/noir/noir_studio_3d.tscn") == OK)
	print("BUILT_NOIR_3D nodes=", scene.find_children("*", "MeshInstance3D", true, false).size())
	scene.free()
	quit()

func _own(parent: Node) -> void:
	for child in parent.get_children():
		child.owner = scene
		_own(child)

func _shell() -> void:
	var room := group("RoomArchitecture", scene)
	box(room, "Foundation", Vector3(0, -0.18, 0), Vector3(9.0, 0.3, 7.5), INK)
	for row in range(18):
		for col in range(6):
			var x := -4.45 + col * 1.78 - (0.89 if row % 2 else 0.0)
			var start_x := maxf(-4.45, x)
			var end_x := minf(4.45, x + 1.78)
			if end_x - start_x < 0.02: continue
			var plank := box(room, "OakPlank", Vector3((start_x + end_x) * 0.5, 0, -3.53 + row * 0.415), Vector3(end_x - start_x - 0.015, 0.08, 0.399), Color("846038").lightened(rng.randf_range(-0.13, 0.1)))
			for mark in range(2):
				var start := Vector3(rng.randf_range(-0.3, 0.0), 0.043, rng.randf_range(-0.15, 0.15))
				rod(plank, "WoodInk", start, start + Vector3(rng.randf_range(0.12, 0.30), 0, 0.006), 0.005, Color("493920"))
	box(room, "BackWall", Vector3(0, 1.65, -3.75), Vector3(9.0, 3.3, 0.16), Color("77603b"))
	box(room, "LeftCutawayWall", Vector3(-4.5, 0.40, 0), Vector3(0.16, 0.80, 7.5), Color("55462d"))
	box(room, "RightLowWall", Vector3(4.5, 0.24, 0), Vector3(0.16, 0.48, 7.5), WOOD.darkened(0.4))
	for y: float in [0.18, 1.0, 3.27]:
		box(room, "BackTrim", Vector3(0, y, -3.62), Vector3(9, 0.10, 0.10), INK)
		if y < 1.01:
			box(room, "LeftTrim", Vector3(-4.39, minf(y, 0.8), 0), Vector3(0.10, 0.10, 7.5), INK)
	for x: float in [-4.4, -2.8, -0.9, 1.0, 2.9, 4.4]:
		box(room, "WallBatten", Vector3(x, 1.7, -3.61), Vector3(0.055, 3.1, 0.06), Color("342818"))
	var door := group("Door", room, Vector3(-3.45, 0, -3.5))
	box(door, "Frame", Vector3(0, 1.35, 0), Vector3(1.35, 2.7, 0.16), INK)
	box(door, "DoorLeaf", Vector3(0, 1.32, 0.1), Vector3(1.15, 2.54, 0.12), Color("674321"))
	for y: float in [0.62, 1.8]:
		box(door, "RecessedPanel", Vector3(0, y, 0.17), Vector3(0.86, 0.9, 0.024), Color("4e341e"))
	cylinder(door, "DoorHandle", Vector3(0.43, 1.12, 0.24), 0.065, 0.15, GOLD).rotation_degrees.x = 90
	box(room, "DoorMat", Vector3(-3.4, 0.06, -2.7), Vector3(1.4, 0.03, 0.7), Color("483125"))
	var rug := group("CentralRug", room, Vector3(0.2, 0.065, 0.45))
	box(rug, "InkBorder", Vector3.ZERO, Vector3(3.55, 0.025, 2.95), INK)
	box(rug, "GoldBorder", Vector3(0, 0.015, 0), Vector3(3.43, 0.015, 2.83), Color("8c783c"))
	box(rug, "WovenCenter", Vector3(0, 0.025, 0), Vector3(3.15, 0.015, 2.55), Color("625b39"))
	for i in range(35):
		for z: float in [-1.52, 1.52]:
			rod(rug, "Fringe", Vector3(-1.7 + i * 0.1, 0, z), Vector3(-1.69 + i * 0.1, 0, z + signf(z) * 0.1), 0.012, PAPER.darkened(0.25))

func _desk() -> void:
	var desk := group("WritingDesk", scene, Vector3(1.5, 0, -1.55))
	box(desk, "Desktop", Vector3(0, 1.13, 0), Vector3(3.45, 0.16, 1.55), GOLD)
	for x: float in [-1.28, 1.28]:
		box(desk, "Pedestal", Vector3(x, 0.55, 0.03), Vector3(0.64, 1.04, 1.28), WOOD.darkened(0.18))
		for y: float in [0.3, 0.62, 0.94]:
			box(desk, "Drawer", Vector3(x, y, 0.696), Vector3(0.57, 0.26, 0.045), WOOD)
			rod(desk, "BrassPull", Vector3(x - 0.10, y + 0.035, 0.755), Vector3(x + 0.10, y + 0.035, 0.755), 0.025, GOLD)
	for i in range(8):
		paper(desk, Vector3(rng.randf_range(-1.35, 0.6), 1.222 + i * 0.007, rng.randf_range(-0.5, 0.4)), rng.randf_range(-30, 30), i % 3 == 0)
	var folder := box(desk, "CaseFolder", Vector3(-1.1, 1.3, 0.15), Vector3(0.54, 0.10, 0.72), Color("38271d"))
	folder.rotation_degrees.y = -14
	box(folder, "ElasticBand", Vector3(0, 0.052, 0.12), Vector3(0.55, 0.012, 0.035), Color("9b3023"))
	var recorder := group("CassetteRecorder", desk, Vector3(0.99, 1.23, 0.19))
	recorder.rotation_degrees.y = -8
	box(recorder, "Body", Vector3(0, 0.12, 0), Vector3(0.42, 0.24, 0.64), Color("34372e"))
	box(recorder, "TapeWindow", Vector3(0, 0.246, -0.06), Vector3(0.31, 0.016, 0.25), Color("719896"))
	for x: float in [-0.087, 0.087]:
		cylinder(recorder, "TapeReel", Vector3(x, 0.266, -0.06), 0.058, 0.015, INK)
	for i in range(5):
		box(recorder, "PlaybackKey", Vector3(-0.14 + i * 0.07, 0.252, 0.235), Vector3(0.054, 0.03, 0.08), PAPER)
	cup(desk, Vector3(0.49, 1.23, 0.43))
	var lamp := group("ArticulatedDeskLamp", desk, Vector3(1.14, 1.22, -0.46))
	cylinder(lamp, "Foot", Vector3.ZERO, 0.23, 0.07, INK)
	rod(lamp, "LowerArm", Vector3.ZERO, Vector3(0.18, 0.48, 0), 0.035, INK)
	rod(lamp, "UpperArm", Vector3(0.18, 0.48, 0), Vector3(-0.30, 0.83, 0), 0.033, INK)
	cylinder(lamp, "Shade", Vector3(-0.34, 0.73, 0), 0.28, 0.26, Color("26261d"), 0.095)
	var bulb := cylinder(lamp, "WarmBulb", Vector3(-0.34, 0.59, 0), 0.22, 0.025, PAPER)
	bulb.material_override = material(Color("ffd26b"), Vector3.ZERO, 1.5)
	_import("OfficeChair", "chair/chair", Vector3(1.28, 0.1, 0.2), Vector3(1.0, 1.35, 1.0), Color("49452d"), -18)

func paper(parent: Node3D, at: Vector3, angle: float, photo: bool) -> void:
	var page := group("CasePhotograph" if photo else "CaseNotes", parent, at)
	page.rotation_degrees.y = angle
	box(page, "Paper", Vector3.ZERO, Vector3(0.40, 0.009, 0.52), PAPER.lightened(rng.randf_range(-0.08, 0.15)))
	if photo:
		box(page, "PhotoPrint", Vector3(0, 0.007, -0.015), Vector3(0.32, 0.006, 0.35), Color("4c4832"))
		cylinder(page, "PortraitHead", Vector3(0, 0.012, -0.07), 0.066, 0.008, Color("24241b"))
		box(page, "PortraitShoulders", Vector3(0, 0.012, 0.052), Vector3(0.20, 0.005, 0.12), Color("24241b"))
	else:
		for i in range(6):
			box(page, "WrittenLine", Vector3(-0.018, 0.007, -0.17 + i * 0.06), Vector3(rng.randf_range(0.18, 0.31), 0.002, 0.009), Color("645131"))

func cup(parent: Node3D, at: Vector3) -> void:
	var mug := group("CoffeeCup", parent, at)
	cylinder(mug, "Saucer", Vector3.ZERO, 0.18, 0.02, PAPER)
	cylinder(mug, "Ceramic", Vector3(0, 0.13, 0), 0.12, 0.24, PAPER)
	cylinder(mug, "Coffee", Vector3(0, 0.255, 0), 0.097, 0.006, INK)
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.049
	mesh.outer_radius = 0.087
	mesh.rings = 12
	mesh.ring_segments = 8
	var handle := MeshInstance3D.new()
	handle.mesh = mesh
	handle.position = Vector3(0.14, 0.14, 0)
	handle.rotation_degrees.x = 90
	handle.material_override = material(PAPER)
	mug.add_child(handle)

func _board() -> void:
	var board := group("EvidenceBoard", scene, Vector3(1.16, 2.15, -3.48))
	box(board, "BlackFrame", Vector3.ZERO, Vector3(3.7, 1.82, 0.10), INK)
	box(board, "Cork", Vector3(0, 0, 0.066), Vector3(3.52, 1.64, 0.03), Color("ac7e39"))
	var pins: Array[Vector3] = []
	for i in range(11):
		var at := Vector3(-1.4 + (i % 4) * 0.89 + rng.randf_range(-0.13, 0.13), 0.52 - (i / 4) * 0.47, 0.10 + i * 0.009)
		var sheet := group("PinnedEvidence", board, at)
		sheet.rotation_degrees.x = 90
		sheet.rotation_degrees.z = rng.randf_range(-10, 10)
		paper(sheet, Vector3.ZERO, 0, i % 2 == 0)
		var pin := at + Vector3(0, 0.19, 0.14)
		pins.append(pin)
		cylinder(board, "RedPin", pin, 0.045, 0.035, Color("bb3924")).rotation_degrees.x = 90
	for pair: Vector2i in [Vector2i(0, 6), Vector2i(6, 3), Vector2i(3, 8), Vector2i(8, 1), Vector2i(1, 10), Vector2i(10, 4), Vector2i(4, 2), Vector2i(2, 9)]:
		rod(board, "RedThread", pins[pair.x], pins[pair.y], 0.014, Color("b63422"))

func _library() -> void:
	var shelf := group("Bookcase", scene, Vector3(-1.8, 0, -3.20))
	box(shelf, "Backing", Vector3(0, 1.35, -0.24), Vector3(1.4, 2.7, 0.10), INK)
	for x: float in [-0.69, 0.69]:
		box(shelf, "Side", Vector3(x, 1.35, 0), Vector3(0.10, 2.7, 0.64), WOOD)
	for level in range(5):
		var y := 0.12 + level * 0.62
		box(shelf, "Shelf", Vector3(0, y, 0), Vector3(1.45, 0.09, 0.67), GOLD)
		if level == 4: continue
		for i in range(8):
			var height := rng.randf_range(0.3, 0.5)
			var book := box(shelf, "Book", Vector3(-0.54 + i * 0.15, y + height * 0.5 + 0.05, 0.01), Vector3(0.105, height, 0.4), [Color("645336"), Color("9a7947"), Color("463c2b"), Color("786748")][i % 4])
			book.rotation_degrees.z = rng.randf_range(-5, 5)
			box(book, "SpineStripe", Vector3(0, height * 0.26, 0.205), Vector3(0.076, 0.026, 0.012), PAPER.darkened(0.2))
	_import("ArchiveCabinet", "shelf/shelf", Vector3(-3.85, 0.08, -0.6), Vector3(1.05, 1.95, 0.63), Color("787052"), 0)
	_import("LowFileCabinet", "smallShelf/smallShelf", Vector3(3.8, 0.08, 2.4), Vector3(0.9, 1.22, 0.62), Color("8d7949"), -90)

func _sofa() -> void:
	var sofa := group("LeatherSofa", scene, Vector3(-3.58, 0.12, 1.92))
	sofa.rotation_degrees.y = 90
	box(sofa, "Base", Vector3(0, 0.24, 0), Vector3(2.66, 0.35, 0.94), Color("3d291e"))
	box(sofa, "Back", Vector3(0, 0.76, -0.36), Vector3(2.68, 0.93, 0.30), Color("634029")).rotation_degrees.x = -8
	for x: float in [-1.27, 1.27]:
		box(sofa, "Arm", Vector3(x, 0.62, 0.0), Vector3(0.26, 0.54, 1.0), Color("76482b"))
	for i in range(3):
		box(sofa, "SeatCushion", Vector3(-0.81 + i * 0.81, 0.53, 0.12), Vector3(0.77, 0.23, 0.67), Color("805331"))
		box(sofa, "BackCushion", Vector3(-0.81 + i * 0.81, 0.89, -0.17), Vector3(0.77, 0.61, 0.15), Color("755033")).rotation_degrees.x = -9
	var pillow := box(sofa, "LooseCushion", Vector3(-0.7, 0.79, 0.20), Vector3(0.51, 0.20, 0.46), Color("5e5d42"))
	pillow.rotation_degrees = Vector3(30, 15, -12)
	var table := group("CoffeeTable", scene, Vector3(-1.93, 0.10, 1.96))
	box(table, "Top", Vector3(0, 0.50, 0), Vector3(0.9, 0.11, 1.92), WOOD)
	for x: float in [-0.32, 0.32]:
		for z: float in [-0.75, 0.75]:
			box(table, "Leg", Vector3(x, 0.24, z), Vector3(0.09, 0.5, 0.09), INK)
	paper(table, Vector3(0.02, 0.57, 0.35), 22, false)
	cup(table, Vector3(0.12, 0.56, -0.55))
	box(table, "Book", Vector3(-0.04, 0.62, -0.08), Vector3(0.44, 0.10, 0.56), Color("a4883e")).rotation_degrees.y = -15

func _window() -> void:
	var window := group("MoonlitWindow", scene, Vector3(4.40, 0, -1.65))
	box(window, "WallSection", Vector3(0, 1.55, 0), Vector3(0.12, 3.1, 2.75), Color("6e5733"))
	box(window, "Frame", Vector3(-0.09, 1.92, 0), Vector3(0.13, 1.95, 2.36), INK)
	box(window, "BlueGlass", Vector3(-0.17, 1.92, 0), Vector3(0.035, 1.77, 2.17), Color("4c91a3"), 0.45)
	for z: float in [-1.15, 0, 1.15]:
		box(window, "WindowMullion", Vector3(-0.23, 1.92, z), Vector3(0.10, 1.96, 0.065), INK)
	box(window, "Crossbar", Vector3(-0.23, 1.8, 0), Vector3(0.1, 0.07, 2.4), INK)
	box(window, "Sill", Vector3(-0.26, 0.97, 0), Vector3(0.45, 0.1, 2.6), GOLD)
	for i in range(9):
		box(window, "BlindSlat", Vector3(-0.27, 2.81 - i * 0.09, 0), Vector3(0.15, 0.025, 2.36), Color("51492f")).rotation_degrees.z = -22
	for i in range(11):
		cylinder(window, "RadiatorFin", Vector3(-0.22, 0.49, -1.0 + i * 0.19), 0.065, 0.66, Color("b29d67"))
	rod(window, "HeatingPipe", Vector3(-0.22, 0.26, -1.11), Vector3(-0.22, 0.26, 1.12), 0.048, Color("726449"))

func plant(at: Vector3) -> void:
	var pot := group("PottedPlant", scene, at)
	cylinder(pot, "Terracotta", Vector3(0, 0.2, 0), 0.20, 0.4, Color("8e6335"), 0.28)
	cylinder(pot, "Soil", Vector3(0, 0.405, 0), 0.25, 0.02, INK)
	var foliage := preload("res://scenes/props/indoor_plant_foliage.tscn").instantiate() as Node3D
	foliage.name = "Foliage"
	foliage.position.y = 0.405
	pot.add_child(foliage)

func _props() -> void:
	plant(Vector3(3.82, 1.30, 2.38))
	plant(Vector3(-3.80, 0.05, 0.65))
	var lamp := group("FloorLamp", scene, Vector3(-3.30, 0.08, 3.12))
	cylinder(lamp, "Base", Vector3.ZERO, 0.30, 0.08, INK)
	rod(lamp, "Stem", Vector3.ZERO, Vector3(0, 1.62, 0), 0.035, INK)
	cylinder(lamp, "LinenShade", Vector3(0, 1.66, 0), 0.4, 0.48, GOLD, 0.28)
	var stacks := group("ArchiveBoxes", scene, Vector3(3.60, 0.08, -3.09))
	for i in range(3):
		var carton := box(stacks, "CardboardBox", Vector3(0, 0.22 + i * 0.45, 0), Vector3(0.9, 0.42, 0.7), Color("a18a50"))
		box(carton, "Label", Vector3(0, 0.03, 0.357), Vector3(0.36, 0.14, 0.012), PAPER)
		box(carton, "Lid", Vector3(0, 0.20, 0), Vector3(0.94, 0.05, 0.74), Color("695432"))
	var coat := group("CoatStand", scene, Vector3(-4.0, 0.1, -2.7))
	rod(coat, "Post", Vector3.ZERO, Vector3(0, 2.1, 0), 0.045, INK)
	for i in range(3):
		var tip := Vector3(cos(i * TAU / 3) * 0.3, 0.03, sin(i * TAU / 3) * 0.3)
		rod(coat, "Foot", Vector3(0, 0.15, 0), tip, 0.04, INK)
	box(coat, "HangingCoat", Vector3(0, 1.2, 0.1), Vector3(0.45, 1.32, 0.22), Color("33352a")).rotation_degrees.z = -7
	rod(coat, "Sleeve", Vector3(0.2, 1.76, 0.1), Vector3(0.38, 1.05, 0.16), 0.11, Color("33352a"))
	cylinder(coat, "HatBrim", Vector3(0, 2.08, 0), 0.29, 0.045, Color("3b3826"))
	cylinder(coat, "HatCrown", Vector3(0, 2.18, 0), 0.19, 0.22, Color("3b3826"), 0.16)

func _import(label: String, path: String, at: Vector3, dimensions: Vector3, color: Color, angle: float) -> void:
	var imported := (load("res://assets/models/furniture/" + path + ".glb") as PackedScene).instantiate() as Node3D
	var holder := group(label, scene, at)
	holder.rotation_degrees.y = angle
	var bounds := AABB()
	var meshes := imported.find_children("*", "MeshInstance3D", true, false)
	# Copy static mesh data into fresh nodes; do not serialize both a GLB
	# instance and locally owned copies of its children.
	var local_model := Node3D.new()
	local_model.name = imported.name
	var first := true
	for node in meshes:
		var mesh := node as MeshInstance3D
		var transform := mesh.transform
		var ancestor := mesh.get_parent()
		while ancestor != imported and ancestor is Node3D:
			transform = (ancestor as Node3D).transform * transform
			ancestor = ancestor.get_parent()
		var part := transform * mesh.get_aabb()
		bounds = part if first else bounds.merge(part)
		first = false
		var local_mesh := MeshInstance3D.new()
		local_mesh.name = mesh.name
		local_mesh.mesh = mesh.mesh
		local_mesh.transform = transform
		local_mesh.material_override = material(color)
		local_model.add_child(local_mesh, true)
	var scale_factor := dimensions / bounds.size
	var normalized := group("NormalizedModel", holder)
	normalized.scale = scale_factor
	normalized.add_child(local_model)
	local_model.position = -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z)
	imported.free()
	if label == "ArchiveCabinet" or label == "LowFileCabinet":
		var count := 5 if label == "ArchiveCabinet" else 3
		var drawer_height := (dimensions.y - 0.14) / count
		for i in range(count):
			var y := 0.07 + (i + 0.5) * drawer_height
			var z := dimensions.z * 0.5 + 0.025
			box(holder, "DrawerFront", Vector3(0, y, z), Vector3(dimensions.x - 0.08, drawer_height - 0.03, 0.045), color)
			box(holder, "LabelHolder", Vector3(0, y + 0.04, z + 0.03), Vector3(0.27, 0.105, 0.016), INK)
			box(holder, "LabelCard", Vector3(0, y + 0.04, z + 0.041), Vector3(0.21, 0.062, 0.008), PAPER)
			rod(holder, "DrawerPull", Vector3(-0.11, y - 0.08, z + 0.07), Vector3(0.11, y - 0.08, z + 0.07), 0.025, GOLD)

func _setup() -> void:
	var env := WorldEnvironment.new()
	env.name = "WorldEnvironment"
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("17130f")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
	env.environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	scene.add_child(env)
	var lighting := group("Lighting", scene)
	var key := DirectionalLight3D.new()
	key.name = "AmberKey"
	key.rotation_degrees = Vector3(-42, 145, 0)
	key.light_color = Color("ffe2b1")
	key.light_energy = 0.72
	key.shadow_enabled = true
	key.shadow_bias = 0.15
	key.directional_shadow_max_distance = 28
	lighting.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.name = "WarmWallFill"
	fill.rotation_degrees = Vector3(-58, -28, 0)
	fill.light_color = Color("e0c292")
	fill.light_energy = 0.32
	lighting.add_child(fill)
	var desk := SpotLight3D.new()
	desk.name = "DeskLight"
	desk.position = Vector3(2.3, 2.4, -2.0)
	desk.rotation_degrees.x = -90
	desk.light_color = Color("ffd36b")
	desk.light_energy = 1.5
	desk.spot_range = 5.5
	desk.spot_angle = 52
	desk.shadow_enabled = true
	lighting.add_child(desk)
	var moon := SpotLight3D.new()
	moon.name = "WindowLight"
	moon.position = Vector3(4.0, 2.5, -1.6)
	moon.rotation_degrees = Vector3(-38, 75, 0)
	moon.light_color = Color("79b7cc")
	moon.light_energy = 0.6
	moon.spot_range = 8.0
	moon.spot_angle = 57
	moon.shadow_enabled = true
	lighting.add_child(moon)
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12.2
	camera.current = true
	camera.position = Vector3(2.25, 14.4, 10.6)
	camera.position = Vector3(-3.12, 14.64, 10.89)
	camera.rotation_degrees = Vector3(-51, -16, 0)
	scene.add_child(camera)
	var hud := CanvasLayer.new()
	hud.name = "HUD"
	hud.layer = 10
	scene.add_child(hud)
	var label := Label.new()
	label.name = "Controls"
	label.text = "深夜工作室    /    右键旋转 · 滚轮缩放 · 中键平移 · L 台灯 · R 复位 · Tab 隐藏提示"
	label.position = Vector2(24, 18)
	label.add_theme_color_override("font_color", PAPER)
	label.add_theme_color_override("font_shadow_color", INK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_font_size_override("font_size", 16)
	hud.add_child(label)
