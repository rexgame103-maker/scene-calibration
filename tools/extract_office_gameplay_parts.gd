extends SceneTree

const DIR := "res://scenes/cases/office_parts/"
var source: Node3D

func _initialize() -> void:
	call_deferred("_extract")

func _own(node: Node, owner_root: Node) -> void:
	node.scene_file_path = ""
	for child in node.get_children():
		child.owner = owner_root
		_own(child, owner_root)

func _save(node: Node, path: String) -> void:
	_own(node,node)
	var packed := PackedScene.new()
	assert(packed.pack(node) == OK)
	assert(ResourceSaver.save(packed,path) == OK)

func _take(path: String) -> Node3D:
	var node := source.get_node(path) as Node3D
	_clear_owner(node)
	node.get_parent().remove_child(node)
	return node

func _clear_owner(node: Node) -> void:
	node.owner = null
	for child in node.get_children(): _clear_owner(child)

func _part(path: String, kind: String, preserve_rotation := false) -> void:
	var node := _take(path)
	node.position = Vector3.ZERO
	if not preserve_rotation: node.rotation = Vector3.ZERO
	var art := Node3D.new()
	art.name = "Model"
	art.add_child(node)
	_save(art,DIR+kind+".tscn")
	art.free()

func _extract() -> void:
	source = (load("res://scenes/cases/office_restored_concept.tscn") as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	var computer := Node3D.new()
	computer.name = "Model"
	for name: String in ["Computer","Keyboard","Mouse"]:
		var component := _take("WritingDesk/"+name)
		component.position -= Vector3(0,1.21,0)
		computer.add_child(component)
	_save(computer,DIR+"computer.tscn")
	computer.free()
	# The rubbing evidence belongs to the desk, not to a fixed floor position.
	var trace_root := source.get_node("FloorAndContactTraces")
	var desk := source.get_node("WritingDesk") as Node3D
	var wear := desk.get_node_or_null("SideWearMarks") as Node3D
	if wear == null:
		wear = Node3D.new()
		wear.name = "SideWearMarks"
		desk.add_child(wear)
	for trace in trace_root.get_children():
		if str(trace.name).begins_with("CabinetContactWear") or (trace is MeshInstance3D and trace.position.y > 0.6 and absf(trace.position.x - 1.80) < 0.01):
			_clear_owner(trace)
			trace_root.remove_child(trace)
			trace.position -= desk.position
			trace.position.x = 1.601
			wear.add_child(trace)
	_part("WritingDesk","desk")
	_part("OfficeChair","chair",true)
	_part("DeskSideIvoryCabinet","small_shelf")
	_part("TallFilingShelf/RedBinder","red_file")
	_part("TallFilingShelf/GrayBinder","gray_file")
	_part("TallFilingShelf/BeigeBinder","ordinary_file_01")
	_part("TallFilingShelf","shelf")
	_part("WaterDispenser","water_dispenser")
	_part("PrinterStation","printer")
	# Room shell contains only fixed scenery, never a duplicate of unlockable furniture.
	source.get_node("Camera3D").free()
	source.get_node("WorldEnvironment").free()
	var fill := source.get_node("Lighting/WarmWallFill")
	_clear_owner(fill)
	fill.get_parent().remove_child(fill)
	source.add_child(fill)
	source.get_node("Lighting").free()
	source.name = "ConceptOfficeShell"
	_save(source,DIR+"room.tscn")
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	var room := main.get_node("PrimitiveRoom")
	for child in room.get_children(): child.free()
	_clear_owner(source)
	room.add_child(source)
	for child in main.get_node("PlacedFurniture").get_children(): child.free()
	var camera := main.get_node("IsometricCamera") as Camera3D
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 28.0
	camera.transform = Transform3D(Basis.IDENTITY,Vector3(-7.8,16.7,19.25)).looking_at(Vector3(0,0.7,-0.25))
	var key := main.get_node("KeyLight") as DirectionalLight3D
	key.rotation_degrees = Vector3(-35,118,0)
	key.light_color = Color("ffe2b1")
	key.light_energy = 0.9
	key.shadow_enabled = true
	key.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	key.directional_shadow_max_distance = 35
	key.shadow_normal_bias = 0.5
	key.shadow_bias = 0.12
	var env := main.get_node("SceneEnvironment") as WorldEnvironment
	env.environment = env.environment.duplicate()
	env.environment.background_color = Color("17130f")
	env.environment.background_energy_multiplier = 1.0
	env.environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	main.get_node("HandDrawnPostProcess").set("effect_enabled",false)
	main.get_node("HandDrawnPostProcess").set("show_toggle_hint",false)
	main.get_node("HandDrawnPostProcess").set("allow_runtime_toggle",false)
	preload("res://scripts/office_editor_preview.gd").populate(main)
	_save(main,"res://scenes/main.tscn")
	main.free()
	print("OFFICE_PARTS_EXTRACTED: 10 grouped items and replaced main office shell")
	quit()
