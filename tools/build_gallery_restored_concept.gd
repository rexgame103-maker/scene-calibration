extends "res://tools/build_noir_studio_3d.gd"
const METAL := Color("444c49")
const TILE := Color("827a66")
const CREAM := Color("afa990")

func _build() -> void:
	rng.seed = 20071
	scene = Node3D.new()
	scene.name = "GalleryRestorationConcept"
	architecture()
	worktable()
	stool()
	cold_lamp()
	camera_stand()
	parked_equipment()
	storage()
	setup_view()
	for mesh in scene.get_node("Architecture").find_children("*","MeshInstance3D",true,false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if str(mesh.name).begins_with("StoneTile"):
			mesh.material_override.set_shader_parameter("ink_width",0.003)
	for mesh in scene.get_node("RestorationTable/PanelPainting").get_children():
		if str(mesh.name).begins_with("Landscape") or str(mesh.name).begins_with("Distant"):
			mesh.material_override.set_shader_parameter("ink_width",0.0)
	_own(scene)
	var packed := PackedScene.new()
	assert(packed.pack(scene) == OK)
	assert(ResourceSaver.save(packed,"res://scenes/cases/gallery_restored_concept.tscn") == OK)
	print("GALLERY_BUILT ",scene.find_children("*","MeshInstance3D",true,false).size()," editable meshes")
	scene.free()
	quit()

func architecture() -> void:
	var g := group("Architecture",scene)
	box(g,"Foundation",Vector3(0,-0.13,0),Vector3(10,0.25,7),INK)
	for z in 10:
		for x in 10:
			var tile := box(g,"StoneTile",Vector3(-4.5+x,0,-3.15+z*0.7),Vector3(0.985,0.045,0.685),TILE.lightened(rng.randf_range(-0.14,0.08)))
			if rng.randf()<0.5:
				var p := Vector3(rng.randf_range(-0.35,0.1),0.025,rng.randf_range(-0.25,0.25))
				rod(tile,"Wear",p,p+Vector3(0.15,0,0.02),0.003,Color("514c40"))
	box(g,"RearWall",Vector3(0,1.65,-3.5),Vector3(10,3.3,0.14),Color("8c8571"))
	box(g,"WindowWallLower",Vector3(-5,0.6,0),Vector3(0.14,1.2,7),Color("8c8571"))
	box(g,"WindowWallUpper",Vector3(-5,3.13,0),Vector3(0.14,0.34,7),Color("8c8571"))
	box(g,"WindowWallBackPier",Vector3(-5,2.08,-2.95),Vector3(0.14,1.76,1.1),Color("8c8571"))
	box(g,"WindowWallFrontPier",Vector3(-5,2.08,2.05),Vector3(0.14,1.76,2.9),Color("8c8571"))
	for y in [0.13,3.3]:
		box(g,"RearTrim",Vector3(0,y,-3.39),Vector3(10,0.07,0.08),INK)
		box(g,"SideTrim",Vector3(-4.9,y,0),Vector3(0.08,0.07,7),INK)
	for x in range(-4,5,2):
		box(g,"WallJoint",Vector3(x,1.65,-3.41),Vector3(0.025,3.2,0.02),Color("514d40"))
	var win := group("NorthWindow",g,Vector3(-4.94,2.08,-0.9))
	box(win,"BlueGlass",Vector3.ZERO,Vector3(0.035,1.7,3.0),Color("7096a5"),0.22)
	for z in [-1.53,-0.51,0.51,1.53]:
		box(win,"Mullion",Vector3(0.045,0,z),Vector3(0.10,1.8,0.055),METAL)
	for y in [-0.9,0,0.9]:
		box(win,"Crossbar",Vector3(0.045,y,0),Vector3(0.10,0.06,3.15),METAL)
	box(win,"Sill",Vector3(0.15,-0.95,0),Vector3(0.42,0.09,3.4),CREAM)
	box(g,"CalibrationRail",Vector3(-0.7,2.96,-3.29),Vector3(4.7,0.075,0.10),METAL)
	for x in [-2.7,-0.7,1.3]:
		box(g,"RailBracket",Vector3(x,2.95,-3.27),Vector3(0.12,0.25,0.15),INK)
	var outlet := group("WallPower",g,Vector3(4.3,0.5,-3.36))
	box(outlet,"Plate",Vector3.ZERO,Vector3(0.52,0.22,0.08),CREAM)
	for x in [-0.16,0,0.16]:
		cylinder(outlet,"Socket",Vector3(x,0,0.055),0.055,0.025,INK).rotation_degrees.x=90
	for i in 2:
		var memo := box(g,"CalibrationSheet",Vector3(1.1+i*0.65,1.9,-3.4),Vector3(0.47,0.7,0.015),CREAM)
		for k in 4:
			box(memo,"PrintedRule",Vector3(0,-0.1+k*0.08,0.012),Vector3(0.31,0.008,0.005),METAL)

func bottle(parent: Node3D, at: Vector3, index: int) -> void:
	var g := group("ConservationBottle",parent,at)
	var h := 0.17+0.035*(index%3)
	cylinder(g,"Bottle",Vector3(0,h/2,0),0.055,h,CREAM if index%2 else Color("64553d"))
	cylinder(g,"Cap",Vector3(0,h+0.018,0),0.038,0.045,INK)
	box(g,"Label",Vector3(0,h*0.55,0.055),Vector3(0.06,0.075,0.006),Color("d4c9a9"))

func brushcup(parent: Node3D, at: Vector3) -> void:
	cylinder(parent,"BrushPot",at+Vector3(0,0.09,0),0.085,0.18,METAL)
	for i in 7:
		var a := at+Vector3(rng.randf_range(-0.055,0.055),0.08,rng.randf_range(-0.05,0.05))
		var b := a+Vector3(rng.randf_range(-0.08,0.08),rng.randf_range(0.26,0.43),0)
		rod(parent,"BrushHandle",a,b,0.009,Color("866039"))
		rod(parent,"Bristles",b,b+Vector3(0,0.045,0),0.016,INK)

func worktable() -> void:
	var g := group("RestorationTable",scene,Vector3(-0.8,0,-0.25))
	box(g,"Worktop",Vector3(0,1.16,0),Vector3(2.9,0.12,1.55),CREAM)
	for x in [-1.27,1.27]:
		for z in [-0.62,0.62]:
			box(g,"Leg",Vector3(x,0.56,z),Vector3(0.075,1.12,0.075),METAL)
		box(g,"Brace",Vector3(x,0.32,0),Vector3(0.05,0.05,1.27),METAL)
	box(g,"SupportMat",Vector3(-0.2,1.23,-0.05),Vector3(1.95,0.018,1.15),Color("758f87"))
	var art := group("PanelPainting",g,Vector3(-0.2,1.26,-0.05))
	box(art,"Panel",Vector3.ZERO,Vector3(1.62,0.055,0.97),Color("b4a07c"))
	for z in [-0.5,0.5]:
		box(art,"FrameRail",Vector3(0,0.04,z),Vector3(1.78,0.065,0.065),Color("866335"))
	for x in [-0.86,0.86]:
		box(art,"FrameSide",Vector3(x,0.04,0),Vector3(0.065,0.065,1.03),Color("866335"))
	# Graphic landscape painted on the panel, built as thin colored shapes.
	for i in 15:
		var x := -0.74+i*0.10
		var depth := rng.randf_range(0.22,0.48)
		box(art,"LandscapeHill",Vector3(x,0.031,-0.12+depth/2),Vector3(0.105,0.003,depth),Color("595c47"))
	for i in 5:
		box(art,"DistantTrees",Vector3(-0.57+i*0.21,0.034,-0.16),Vector3(0.035,0.003,rng.randf_range(0.09,0.25)),Color("343e35"))
	box(g,"CalibrationRuler",Vector3(-0.25,1.245,-0.65),Vector3(1.25,0.02,0.06),Color("b7beb2"))
	for i in 20:
		box(g,"RulerTick",Vector3(-0.82+i*0.058,1.257,-0.65),Vector3(0.007,0.003,0.034),INK)
	rod(g,"ScalpelTool",Vector3(-1.22,1.25,-0.2),Vector3(-1.18,1.25,0.32),0.018,METAL)
	brushcup(g,Vector3(1.12,1.23,-0.45))
	bottle(g,Vector3(1.13,1.23,-0.1),1)
	for i in 4:
		box(g,"FoldedCloth",Vector3(1.0,1.24+i*0.013,0.5),Vector3(0.37,0.012,0.3),Color("c7b899"))
	var palette := box(g,"Palette",Vector3(0.89,1.24,0.19),Vector3(0.36,0.025,0.23),CREAM)
	for i in 6:
		cylinder(palette,"PaintWell",Vector3(-0.12+(i%3)*0.12,0.025,-0.065+(i/3)*0.13),0.033,0.008,[INK,Color("85663d"),Color("667464")][i%3])

func stool() -> void:
	var g := group("RestorationStool",scene,Vector3(-0.7,0,1.05))
	cylinder(g,"PaddedSeat",Vector3(0,0.78,0),0.29,0.1,Color("59686a"))
	cylinder(g,"SeatColumn",Vector3(0,0.41,0),0.043,0.65,METAL)
	for i in 5:
		var a := i*TAU/5
		var p := Vector3(cos(a)*0.31,0.1,sin(a)*0.31)
		rod(g,"Foot",Vector3(0,0.2,0),p,0.028,METAL)
		cylinder(g,"Caster",p-Vector3(0,0.035,0),0.065,0.06,INK).rotation_degrees.z=90
	for i in 16:
		var a := i*TAU/16
		var b := (i+1)*TAU/16
		rod(g,"FootRing",Vector3(cos(a)*0.22,0.38,sin(a)*0.22),Vector3(cos(b)*0.22,0.38,sin(b)*0.22),0.018,METAL)

func cold_lamp() -> void:
	var g := group("StandardColdLight",scene,Vector3(-0.8,0,-1.9))
	for x in [-1.4,1.4]:
		box(g,"Upright",Vector3(x,1.25,0),Vector3(0.06,2.5,0.065),METAL)
		box(g,"Foot",Vector3(x,0.12,0),Vector3(0.12,0.08,0.7),METAL)
		for z in [-0.26,0.26]:
			cylinder(g,"Caster",Vector3(x,0.07,z),0.07,0.06,INK).rotation_degrees.z=90
		rod(g,"Arm",Vector3(x,2.4,0),Vector3(x,2.4,0.52),0.035,METAL)
		box(g,"Clamp",Vector3(x,1.5,0),Vector3(0.10,0.16,0.12),Color("727e78"))
	box(g,"LampHousing",Vector3(0,2.4,0.52),Vector3(2.8,0.20,0.42),METAL)
	box(g,"Diffuser",Vector3(0,2.289,0.55),Vector3(2.58,0.025,0.33),Color("c0e8ec"),0.9)
	box(g,"FrontDiffuserEdge",Vector3(0,2.34,0.735),Vector3(2.58,0.08,0.012),Color("bde9ef"),0.8)
	var light := SpotLight3D.new()
	light.name="CoolWorkLight"
	light.position=Vector3(0,2.26,0.54)
	light.rotation_degrees.x=-70
	light.light_color=Color("c5e6ed")
	light.light_energy=0.7
	light.spot_range=4
	light.spot_angle=65
	g.add_child(light)

func camera_stand() -> void:
	var g := group("PhotographyTripod",scene,Vector3(-1.35,0,2.15))
	for i in 3:
		var a := i*TAU/3
		var p := Vector3(cos(a)*0.55,0.04,sin(a)*0.55)
		rod(g,"TripodLeg",Vector3(0,1.25,0),p,0.028,METAL)
		rod(g,"TripodBrace",Vector3(0,0.6,0),p.lerp(Vector3(0,1.25,0),0.35),0.014,METAL)
		cylinder(g,"RubberFoot",p,0.035,0.06,INK)
	cylinder(g,"CenterColumn",Vector3(0,1.22,0),0.038,0.5,METAL)
	box(g,"CameraBody",Vector3(0,1.52,0),Vector3(0.28,0.21,0.18),INK)
	cylinder(g,"Lens",Vector3(0,1.52,-0.15),0.08,0.19,METAL).rotation_degrees.x=90
	box(g,"Viewfinder",Vector3(0,1.66,0),Vector3(0.10,0.06,0.1),METAL)

func marking(at: Vector3, width: float, depth: float, color: Color) -> void:
	var g := group("StorageFloorMark",scene,at)
	for z in [-depth/2,depth/2]:
		box(g,"Tape",Vector3(0,0.028,z),Vector3(width,0.007,0.035),color)
	for x in [-width/2,width/2]:
		box(g,"Tape",Vector3(x,0.028,0),Vector3(0.035,0.007,depth),color)

func parked_equipment() -> void:
	var g := group("MetalReflector",scene,Vector3(2.3,0,-2.75))
	marking(g.position,1.6,1.0,CREAM)
	for x in [-0.64,0.64]:
		box(g,"Upright",Vector3(x,1.18,0),Vector3(0.045,2.1,0.05),METAL)
		box(g,"Foot",Vector3(x,0.13,0),Vector3(0.075,0.06,0.7),METAL)
		for z in [-0.28,0.28]:
			cylinder(g,"Wheel",Vector3(x,0.08,z),0.07,0.07,INK).rotation_degrees.z=90
	box(g,"Frame",Vector3(0,1.35,0),Vector3(1.3,1.85,0.06),INK)
	box(g,"ReflectingSurface",Vector3(0,1.35,0.038),Vector3(1.23,1.78,0.025),Color("939b95"))
	var lamp := group("HalogenInspectionLamp",scene,Vector3(3.95,0,-2.55))
	marking(lamp.position,0.95,0.95,Color("be853c"))
	cylinder(lamp,"Base",Vector3(0,0.07,0),0.33,0.10,INK)
	cylinder(lamp,"Stand",Vector3(0,0.85,0),0.037,1.6,METAL)
	box(lamp,"LampHousing",Vector3(0,1.73,0),Vector3(0.4,0.36,0.33),Color("b37936"))
	box(lamp,"DarkLens",Vector3(0,1.73,0.173),Vector3(0.31,0.26,0.012),Color("473e2d"))
	for x in [-0.16,0.16]:
		rod(lamp,"Guard",Vector3(x,1.57,0.20),Vector3(x,1.88,0.20),0.012,INK)
	rod(lamp,"PowerCable",Vector3(0,1.6,-0.1),Vector3(0,0.06,-0.38),0.014,INK)
	rod(lamp,"PowerCableFloor",Vector3(0,0.06,-0.38),Vector3(0.35,0.06,-0.78),0.014,INK)

func cabinet(name_value: String, at: Vector3, width: float, height: float, drawers: int) -> Node3D:
	var g := group(name_value,scene,at)
	box(g,"Body",Vector3(0,height/2,0),Vector3(width,height,0.7),Color("626454"))
	box(g,"Top",Vector3(0,height+0.04,0),Vector3(width+0.08,0.08,0.77),Color("8c8569"))
	for i in drawers:
		var y := 0.13+(height-0.16)/drawers*(i+0.5)
		box(g,"Drawer",Vector3(0,y,0.365),Vector3(width-0.10,(height-0.16)/drawers-0.027,0.025),Color("747461"))
		for x in [-width*0.28,width*0.28]:
			rod(g,"DrawerPull",Vector3(x-0.07,y,0.408),Vector3(x+0.07,y,0.408),0.014,INK)
	return g

func storage() -> void:
	var flat := cabinet("FlatFileCabinet",Vector3(-4.42,0,-0.7),2.35,0.95,6)
	flat.rotation_degrees.y=90
	for i in 5: bottle(flat,Vector3(-0.7+i*0.22,1.0,-0.1),i)
	box(flat,"ArchivePortfolio",Vector3(0.65,1.06,0.03),Vector3(0.7,0.09,0.47),Color("7b6343"))
	var rear := cabinet("MaterialsCabinet",Vector3(-3.25,0,-2.95),1.1,1.23,3)
	brushcup(rear,Vector3(-0.25,1.3,0))
	for i in 3: bottle(rear,Vector3(0.05+i*0.15,1.3,0),i)
	var rack := group("SpareFrameRack",scene,Vector3(-4.5,0,2.0))
	box(rack,"Base",Vector3(0,0.06,0),Vector3(0.65,0.1,1.35),METAL)
	for i in 2:
		var f := group("EmptyPaintingFrame",rack,Vector3(0,0.12,-0.34+i*0.65))
		f.rotation_degrees.z=8
		for y in [0.1,1.65]:
			box(f,"FrameRail",Vector3(0,y,0),Vector3(0.055,0.075,0.66),Color("886634"))
		for z in [-0.31,0.31]:
			box(f,"FrameStile",Vector3(0,0.88,z),Vector3(0.055,1.6,0.075),Color("886634"))
	var cart := group("SupplyTrolley",scene,Vector3(3.85,0,1.8))
	for y in [0.20,0.59,1.0]:
		box(cart,"Tray",Vector3(0,y,0),Vector3(1.05,0.045,0.6),Color("787760"))
		for z in [-0.29,0.29]:
			box(cart,"TrayLip",Vector3(0,y+0.05,z),Vector3(1.05,0.1,0.025),METAL)
	for x in [-0.49,0.49]:
		for z in [-0.25,0.25]:
			rod(cart,"Post",Vector3(x,0.1,z),Vector3(x,1.1,z),0.025,METAL)
			cylinder(cart,"Wheel",Vector3(x,0.08,z),0.075,0.065,INK).rotation_degrees.z=90
	for i in 5: bottle(cart,Vector3(-0.37+i*0.17,1.03,0),i)
	brushcup(cart,Vector3(0.2,1.04,0.16))
	for i in 3:
		box(cart,"SupplyBox",Vector3(-0.25+i*0.26,0.34,0),Vector3(0.23,0.24,0.37),Color("9a8761"))
	for i in 4:
		box(cart,"ClothStack",Vector3(0,0.63+i*0.025,0),Vector3(0.47,0.022,0.38),CREAM)
	var traces := group("TrolleyWheelScuffs",scene,Vector3(3.8,0.027,1.85))
	for i in 22:
		var a := float(i)/22*TAU
		rod(traces,"Scuff",Vector3(cos(a)*0.6,0,sin(a)*0.44),Vector3(cos(a+0.13)*0.6,0,sin(a+0.13)*0.44),0.006,Color("504e40"))

func setup_view() -> void:
	var env := WorldEnvironment.new()
	env.name="WorldEnvironment"
	env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color("15130f")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_DISABLED
	scene.add_child(env)
	var key := DirectionalLight3D.new()
	key.name="WarmKey"
	key.rotation_degrees=Vector3(-45,-38,0)
	key.light_color=Color("f0dfbd")
	key.light_energy=0.9
	key.shadow_enabled=true
	key.shadow_bias=0.08
	key.shadow_normal_bias=0.25
	key.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL
	key.directional_shadow_max_distance=30
	scene.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.name="CoolFill"
	fill.rotation_degrees=Vector3(-55,145,0)
	fill.light_color=Color("b6d5dc")
	fill.light_energy=0.32
	scene.add_child(fill)
	var camera := Camera3D.new()
	camera.name="Camera3D"
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=14.3
	camera.keep_aspect=Camera3D.KEEP_WIDTH
	camera.current=true
	camera.transform=Transform3D(Basis.IDENTITY,Vector3(11,10,15)).looking_at(Vector3(0,0.9,0))
	scene.add_child(camera)
