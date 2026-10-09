extends "res://tools/build_gallery_restored_concept.gd"
func _build() -> void:
	rng.seed=30071
	scene=Node3D.new()
	scene.name="PlayerStudioConcept"
	architecture()
	var architecture_root := scene.get_node("Architecture")
	for child in architecture_root.get_children():
		if str(child.name).begins_with("StoneTile") or str(child.name).begins_with("Calibration") or str(child.name).begins_with("Rail") or str(child.name).begins_with("WallPower"):
			child.free()
	var floor_group := group("WoodFloor",scene)
	for row in 20:
		for col in 8:
			var start := maxf(-4.98,-5+col*1.4-(0.7 if row%2 else 0))
			var end := minf(4.98,-5+(col+1)*1.4-(0.7 if row%2 else 0))
			if end<=start: continue
			var plank := box(floor_group,"Floorboard",Vector3((start+end)/2,0,-3.32+row*0.35),Vector3(end-start-0.015,0.045,0.34),Color("785b3e").lightened(rng.randf_range(-0.1,0.1)))
			plank.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			plank.material_override.set_shader_parameter("ink_width",0.003)
			for i in 2:
				var p := Vector3(rng.randf_range(-0.22,0.06),0.025,rng.randf_range(-0.12,0.12))
				rod(plank,"WoodGrain",p,p+Vector3(0.18,0,0.006),0.003,Color("4f3c28"))
	var window := scene.get_node("Architecture/NorthWindow")
	for i in 9:
		box(window,"BlindSlat",Vector3(0.11,0.80-i*0.082,0),Vector3(0.13,0.022,3.04),Color("3b3d34")).rotation_degrees.z=-18
	for i in 13:
		cylinder(window,"RadiatorFin",Vector3(0.2,-1.60,-1.15+i*0.19),0.055,0.62,Color("a9a58c"))
	rod(window,"RadiatorPipe",Vector3(0.2,-1.77,-1.3),Vector3(0.2,-1.77,1.3),0.04,METAL)
	studio_desk()
	_board()
	scene.get_node("EvidenceBoard").position=Vector3(-2.0,2.26,-3.36)
	shelves()
	model_station()
	living_area()
	plant(Vector3(-4.35,0.91,1.50))
	plant(Vector3(4.30,0.50,2.0))
	studio_lights()
	# Lower self illumination than the first office, keeping pools of lamp light.
	var mats: Dictionary={}
	for mesh in scene.find_children("*","MeshInstance3D",true,false):
		if bool(mesh.get_meta("stylized_material_locked", false)):
			continue
		var mat := mesh.material_override as ShaderMaterial
		if mat!=null:
			if not mats.has(mat):
				var copy := mat.duplicate() as ShaderMaterial
				copy.shader=load("res://shaders/gallery_toon.gdshader")
				mats[mat]=copy
			mesh.material_override=mats[mat]
	for plank in floor_group.get_children():
		for mark in plank.get_children():
			mark.material_override=mark.material_override.duplicate()
			mark.material_override.next_pass=null
			mark.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	load("res://tools/player_studio_layout_fix.gd").apply(scene)
	load("res://tools/player_studio_lighting.gd").apply(scene)
	load("res://tools/player_studio_mist.gd").apply(scene)
	load("res://tools/player_studio_clue_collage.gd").apply(scene)
	_own(scene)
	# Externalize mesh resources so imported chair data doesn't bloat the text scene.
	DirAccess.make_dir_recursive_absolute("res://assets/player_studio/meshes")
	var meshes: Dictionary={}
	for item in scene.find_children("*","MeshInstance3D",true,false):
		if bool(item.get_meta("stylized_material_locked", false)):
			continue
		if item.mesh is ArrayMesh and not meshes.has(item.mesh):
			var path := "res://assets/player_studio/meshes/mesh_%02d.res"%meshes.size()
			ResourceSaver.save(item.mesh,path)
			item.mesh.take_over_path(path)
			meshes[item.mesh]=true
	var saved_materials: Dictionary={}
	for item in scene.find_children("*","MeshInstance3D",true,false):
		if bool(item.get_meta("stylized_material_locked", false)):
			continue
		if item.material_override!=null and not saved_materials.has(item.material_override):
			var path := "res://assets/player_studio/meshes/material_%04d.res"%saved_materials.size()
			ResourceSaver.save(item.material_override,path)
			item.material_override.take_over_path(path)
			saved_materials[item.material_override]=true
	var packed := PackedScene.new()
	assert(packed.pack(scene)==OK)
	assert(ResourceSaver.save(packed,"res://scenes/studio/player_studio_concept.tscn")==OK)
	print("PLAYER_STUDIO_BUILT ",scene.find_children("*","MeshInstance3D",true,false).size()," meshes")
	scene.free()
	quit()

func import_part(kind: String, label: String, at: Vector3) -> Node3D:
	var holder := group(label,scene,at)
	var part := (load("res://scenes/cases/office_parts/"+kind+".tscn") as PackedScene).instantiate()
	holder.add_child(part)
	part.scene_file_path=""
	return holder

func studio_desk() -> void:
	var desk := import_part("desk","InvestigationDesk",Vector3(-2,0,-1.65))
	var art := desk.get_node("Model/WritingDesk")
	if art.has_node("SideWearMarks"): art.get_node("SideWearMarks").free()
	var lamp := art.get_node("ArticulatedDeskLamp") as Node3D
	lamp.position.x=-1.2
	var computer := (load("res://scenes/cases/office_parts/computer.tscn") as PackedScene).instantiate() as Node3D
	computer.scene_file_path=""
	computer.name="ComputerAndKeyboard"
	computer.position=Vector3(-0.18,1.21,0)
	desk.add_child(computer)
	var chair := import_part("chair","DeskChair",Vector3(-2,0,0.05))
	chair.rotation_degrees.y=0
	var light := SpotLight3D.new()
	light.name="DeskLampPool"
	light.position=Vector3(-1.2,2.02,-0.22)
	light.rotation_degrees=Vector3(-78,0,0)
	light.light_color=Color("ffd08a")
	light.light_energy=2.3
	light.spot_range=2.5
	light.spot_angle=64
	light.shadow_enabled=true
	light.shadow_bias=0.04
	desk.add_child(light)
	cup(desk,Vector3(-0.75,1.22,0.27))
	var journal := group("OpenJournal",desk,Vector3(0.65,1.23,0.35))
	for x in [-0.16,0.16]:
		box(journal,"Page",Vector3(x,0,0),Vector3(0.31,0.015,0.42),Color("d2bd91"))
		for i in 5:
			box(journal,"TextLine",Vector3(x,0.01,-0.13+i*0.05),Vector3(0.23,0.003,0.004),METAL)

func shelves() -> void:
	var shelf := group("ArchiveBookcase",scene,Vector3(3.4,0,-3.02))
	box(shelf,"Back",Vector3(0,1.45,-0.26),Vector3(2.30,2.9,0.08),Color("332b20"))
	for x in [-1.15,0,1.15]:
		box(shelf,"Upright",Vector3(x,1.45,0),Vector3(0.08,2.9,0.65),Color("65482d"))
	for level in 5:
		var y := 0.10+level*0.67
		box(shelf,"Shelf",Vector3(0,y,0),Vector3(2.40,0.08,0.70),Color("755535"))
		if level==4: continue
		for i in 2:
			if (level+i)%2==0:
				for b in 7:
					var book := box(shelf,"Book",Vector3(-1.02+i*1.16+b*0.145,y+0.28,0),Vector3(0.11,0.46,0.45),[Color("3f514a"),Color("70573d"),Color("989078")][b%3])
					box(book,"SpineLabel",Vector3(0,0.09,0.231),Vector3(0.07,0.06,0.01),CREAM)
			else:
				var carton := box(shelf,"ArchiveBox",Vector3(-0.57+i*1.16,y+0.24,0),Vector3(0.92,0.41,0.48),Color("94805b"))
				box(carton,"Label",Vector3(0,0,0.25),Vector3(0.33,0.13,0.014),CREAM)
				box(carton,"Lid",Vector3(0,0.19,0),Vector3(0.96,0.05,0.52),Color("6c593e"))
	var cabinet := cabinet("PrinterCabinet",Vector3(1.85,0,-2.92),0.86,1.40,4)
	box(cabinet,"Printer",Vector3(0,1.59,0),Vector3(0.70,0.27,0.48),METAL)
	box(cabinet,"PaperFeed",Vector3(0,1.78,-0.1),Vector3(0.39,0.29,0.025),CREAM).rotation_degrees.x=-15
	box(cabinet,"PaperSlot",Vector3(0,1.53,0.251),Vector3(0.42,0.05,0.01),INK)
	var low := group("WindowBookcase",scene,Vector3(-4.43,0,1.43))
	low.rotation_degrees.y=90
	for y in [0.08,0.48,0.88]:
		box(low,"Shelf",Vector3(0,y,0),Vector3(1.5,0.07,0.68),Color("6d5032"))
	for x in [-0.72,0.72]:
		box(low,"Side",Vector3(x,0.46,0),Vector3(0.08,0.88,0.68),Color("6d5032"))
	for i in 9:
		box(low,"Book",Vector3(-0.57+i*0.14,0.28,0),Vector3(0.11,0.32,0.45),Color("7e775c"))
	for i in 2:
		box(low,"Box",Vector3(-0.36+i*0.70,0.68,0),Vector3(0.61,0.30,0.46),Color("9b8761"))

func model_station() -> void:
	var g := group("MiniatureWorkbench",scene,Vector3(0.40,0,-2.42))
	box(g,"Top",Vector3(0,1.08,0),Vector3(1.9,0.10,0.94),CREAM)
	for x in [-0.82,0.82]:
		for z in [-0.37,0.37]:
			box(g,"Leg",Vector3(x,0.52,z),Vector3(0.07,1.04,0.07),METAL)
	box(g,"CuttingMat",Vector3(0,1.14,0),Vector3(1.45,0.02,0.72),Color("49675d"))
	var model := group("MiniatureRoom",g,Vector3(0,1.17,0))
	box(model,"Floor",Vector3.ZERO,Vector3(0.93,0.035,0.62),Color("b1a58a"))
	box(model,"RearWall",Vector3(0,0.16,-0.3),Vector3(0.93,0.31,0.035),CREAM)
	box(model,"SideWall",Vector3(-0.45,0.16,0),Vector3(0.035,0.31,0.62),CREAM)
	for i in 3:
		box(model,"MiniCabinet",Vector3(-0.25+i*0.23,0.10,-0.17),Vector3(0.18,0.16,0.13),Color("796a50"))
	box(model,"MiniDesk",Vector3(0,0.08,0.10),Vector3(0.33,0.12,0.18),Color("8b7551"))
	brushcup(g,Vector3(0.8,1.14,-0.21))
	box(g,"Ruler",Vector3(0.20,1.16,0.38),Vector3(0.7,0.02,0.045),GOLD)
	cylinder(g,"StoolSeat",Vector3(0,0.67,0.85),0.22,0.09,Color("5d5a42"))
	for x in [-0.14,0.14]:
		for z in [0.72,0.98]: rod(g,"StoolLeg",Vector3(x,0.03,z),Vector3(x*0.7,0.64,z),0.025,INK)
	for i in 3:
		var frame := group("CaseSouvenir",scene,Vector3(-0.15+i*0.66,2.48,-3.37))
		box(frame,"DarkFrame",Vector3.ZERO,Vector3(0.54,0.55,0.04),Color("3c3226"))
		box(frame,"PhotoMount",Vector3(0,0,0.03),Vector3(0.47,0.48,0.013),CREAM)
		box(frame,"Photo",Vector3(0,0,0.041),Vector3(0.36,0.33,0.006),Color("646650"))
	box(scene,"DisplayShelf",Vector3(0.5,1.91,-3.12),Vector3(1.95,0.08,0.40),Color("644d34"))
	for i in 3:
		cylinder(scene,"RolledFloorplan",Vector3(-0.70+i*0.10,1.16,-2.93),0.042,1.1,CREAM).rotation_degrees.z=-6+i*5
	var coat := group("WallCoat",scene,Vector3(4.72,1.1,-3.26))
	box(coat,"HookBoard",Vector3(0,1.02,0),Vector3(0.34,0.15,0.06),WOOD)
	box(coat,"CoatBody",Vector3(0,0.35,0.08),Vector3(0.36,1.12,0.17),Color("3b4134"))
	for x in [-0.24,0.24]:
		rod(coat,"Sleeve",Vector3(x*0.5,0.82,0.09),Vector3(x,0.19,0.13),0.07,Color("3b4134"))

func living_area() -> void:
	_sofa()
	var sofa := scene.get_node("LeatherSofa") as Node3D
	sofa.position=Vector3(3.05,0.08,0.45)
	sofa.rotation=Vector3.ZERO
	for child in sofa.get_children():
		if child is MeshInstance3D:
			var color := Color("5d6040") if "Cushion" in str(child.name) else Color("44482e")
			child.material_override=material(color,(child.mesh as BoxMesh).size if child.mesh is BoxMesh else Vector3.ZERO)
	var table := scene.get_node("CoffeeTable") as Node3D
	table.position=Vector3(2.85,0.05,2.03)
	table.rotation_degrees.y=90
	var rug := group("SofaRug",scene,Vector3(2.9,0.03,1.55))
	box(rug,"Border",Vector3.ZERO,Vector3(3.7,0.015,2.85),Color("403626"))
	box(rug,"WovenCenter",Vector3(0,0.01,0),Vector3(3.43,0.009,2.58),Color("6f4930"))
	for x in range(10):
		for z in range(7):
			var stitch := box(rug,"PatternDiamond",Vector3(-1.5+x*0.33,0.019,-1.04+z*0.34),Vector3(0.09,0.003,0.09),Color("927b4e"))
			stitch.rotation_degrees.y=45
	var lamp := group("FloorLamp",scene,Vector3(4.5,0,0.78))
	cylinder(lamp,"Base",Vector3(0,0.06,0),0.27,0.10,INK)
	rod(lamp,"Stem",Vector3(0,0.1,0),Vector3(0,1.66,0),0.027,GOLD)
	var shade := cylinder(lamp,"LinenShade",Vector3(0,1.76,0),0.35,0.50,Color("cfab6c"),0.23)
	shade.material_override=material(Color("e3b86d"),Vector3.ZERO,1.1)
	var warm := OmniLight3D.new()
	warm.name="SofaLampPool"
	warm.position=Vector3(-0.18,1.43,0.08)
	warm.light_color=Color("ffd391")
	warm.light_energy=1.9
	warm.omni_range=3.5
	warm.omni_attenuation=0.6
	warm.shadow_enabled=true
	lamp.add_child(warm)
	box(scene,"PlantStand",Vector3(4.3,0.25,2.0),Vector3(0.6,0.48,0.6),Color("6e5237"))

func studio_lights() -> void:
	setup_view()
	var key := scene.get_node("WarmKey") as DirectionalLight3D
	key.rotation_degrees=Vector3(-24,-100,0)
	key.light_energy=1.45
	key.light_color=Color("ffe0ac")
	key.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	key.shadow_normal_bias=0.6
	var fill := scene.get_node("CoolFill") as DirectionalLight3D
	fill.rotation_degrees=Vector3(-25,35,0)
	fill.light_energy=0.32
	fill.light_color=Color("c3c5bd")
	var ceiling := box(scene,"CeilingLightBlocker",Vector3(0,3.52,0),Vector3(10.2,0.22,7.2),INK)
	ceiling.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	scene.get_node("Architecture/NorthWindow/BlueGlass").cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


