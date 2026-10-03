extends "res://tools/build_noir_studio_3d.gd"
## Uses mesh-authoring helpers only. The saved office has no runtime script.

func _build() -> void:
	rng.seed = 912071
	scene = Node3D.new()
	scene.name = "OfficeRestoredConcept"
	_build_room()
	_build_workstation()
	_build_storage()
	_build_window()
	_build_printer()
	_build_traces()
	plant(Vector3(3.55, 0.06, 2.25))
	_setup()
	scene.get_node("HUD").free()
	var camera := scene.get_node("Camera3D") as Camera3D
	camera.size = 11.8
	camera.transform = Transform3D(Basis.IDENTITY, Vector3(-6.0, 12.5, 15.0)).looking_at(Vector3(0, 0.7, -0.25))
	var key := scene.get_node("Lighting/AmberKey") as DirectionalLight3D
	key.rotation_degrees = Vector3(-35, 118, 0)
	key.light_energy = 0.9
	key.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	key.shadow_normal_bias = 0.08
	key.shadow_bias = 0.04
	(scene.get_node("Lighting/WarmWallFill") as DirectionalLight3D).light_energy = 0.40
	var light := scene.get_node("Lighting/DeskLight") as SpotLight3D
	light.position = Vector3(1.2, 2.4, -2.55)
	light.light_energy = 0.7
	_own(scene)
	var packed := PackedScene.new()
	assert(packed.pack(scene) == OK)
	assert(ResourceSaver.save(packed, "res://scenes/cases/office_restored_concept.tscn") == OK)
	print("OFFICE_CONCEPT_BUILT: ", scene.find_children("*", "MeshInstance3D", true, false).size(), " meshes; no runtime script")
	scene.free()
	quit()

func _build_room() -> void:
	var room := group("Architecture", scene)
	box(room, "Foundation", Vector3(0, -0.15, 0), Vector3(8.6, 0.25, 7.2), INK)
	for row in range(18):
		for col in range(6):
			var x := -4.25 + col * 1.7 - (0.85 if row % 2 else 0.0)
			var a := maxf(-4.25, x)
			var b := minf(4.25, x + 1.7)
			if b - a < 0.03: continue
			var plank := box(room, "OakPlank", Vector3((a+b)*0.5, 0, -3.38 + row * 0.397), Vector3(b-a-0.014, 0.08, 0.383), Color("80613b").lightened(rng.randf_range(-0.15, 0.09)))
			for i in range(2):
				var p := Vector3(rng.randf_range(-0.3, 0.04), 0.043, rng.randf_range(-0.13, 0.13))
				rod(plank, "GrainStroke", p, p+Vector3(rng.randf_range(0.12,0.30),0,0.01), 0.004, Color("4d3a25"))
	box(room, "BackWall", Vector3(0,1.65,-3.6), Vector3(8.6,3.3,0.16), Color("8b734d"))
	box(room, "LeftCutaway", Vector3(-4.3,0.5,0), Vector3(0.16,1.0,7.2), Color("74603f"))
	box(room, "RightSillWall", Vector3(4.3,0.6,0), Vector3(0.16,1.2,7.2), Color("8b734d"))
	for y: float in [0.18, 1.0, 3.26]:
		box(room, "BackTrim", Vector3(0,y,-3.48), Vector3(8.6,0.08,0.09), INK)
	for x: float in [-4.18,-2.8,-1.0,0.8,2.6,4.18]:
		box(room,"WallBatten",Vector3(x,1.67,-3.49),Vector3(0.045,3.14,0.05),Color("443422"))
	box(room,"LeftSkirting",Vector3(-4.18,0.16,0),Vector3(0.1,0.18,7.1),INK)
	box(room,"RightSkirting",Vector3(4.18,0.16,0),Vector3(0.1,0.18,7.1),INK)
	box(room,"FrontCutaway",Vector3(1.45,0.3,3.57),Vector3(5.6,0.6,0.14),Color("897452"))
	box(room,"FrontLeftCutaway",Vector3(-3.93,0.3,3.57),Vector3(0.6,0.6,0.14),Color("897452"))
	var door := group("OpenEntryDoor",room,Vector3(-3.55,0,3.5))
	door.rotation_degrees.y = -42
	box(door,"DoorLeaf",Vector3(0.7,1.24,0),Vector3(1.4,2.48,0.11),Color("6d4e29"))
	for y: float in [0.58,1.78]:
		box(door,"InsetPanel",Vector3(0.7,y,-0.064),Vector3(1.1,0.94,0.025),Color("4e3923"))
	cylinder(door,"Handle",Vector3(1.24,1.12,-0.13),0.06,0.14,GOLD).rotation_degrees.x=90

func _build_workstation() -> void:
	_desk()
	var desk := scene.get_node("WritingDesk") as Node3D
	desk.position = Vector3(0.1,0,-2.26)
	desk.get_node("CassetteRecorder").free()
	var page_index := 0
	for child in desk.get_children():
		if str(child.name).begins_with("CaseNotes") or str(child.name).begins_with("CasePhotograph"):
			child.position = Vector3(-1.10 + (page_index % 2) * 0.22, 1.224 + page_index * 0.009, -0.34 + (page_index % 3) * 0.21)
			page_index += 1
	var chair := scene.get_node("OfficeChair") as Node3D
	chair.position = Vector3(0.15,0.08,-0.62)
	chair.rotation_degrees.y = 172
	var monitor := group("Computer",desk,Vector3(-0.05,1.23,-0.43))
	box(monitor,"Foot",Vector3(0,0.025,0.06),Vector3(0.52,0.045,0.35),INK)
	box(monitor,"Stand",Vector3(0,0.20,-0.02),Vector3(0.11,0.36,0.1),INK)
	box(monitor,"MonitorFrame",Vector3(0,0.63,0),Vector3(1.46,0.91,0.09),INK)
	box(monitor,"Screen",Vector3(0,0.64,0.052),Vector3(1.32,0.77,0.015),Color("397e8a"),0.35)
	box(monitor,"Window",Vector3(0.2,0.60,0.063),Vector3(0.66,0.46,0.005),Color("80b4b2"),0.2)
	for i in range(6):
		box(monitor,"LogEntry",Vector3(-0.43,0.88-i*0.09,0.064),Vector3(0.26,0.021,0.004),Color("92b9ab"),0.12)
	var keyboard := group("Keyboard",desk,Vector3(-0.03,1.24,0.26))
	box(keyboard,"Body",Vector3.ZERO,Vector3(1.02,0.045,0.37),Color("39372a"))
	for row in range(4):
		for col in range(12):
			box(keyboard,"Key",Vector3(-0.455+col*0.082,0.033,-0.128+row*0.078),Vector3(0.064,0.02,0.055),Color("9a8c61"))
	box(keyboard,"Spacebar",Vector3(0,0.047,0.115),Vector3(0.37,0.016,0.047),Color("b4a377"))
	cylinder(desk,"Mouse",Vector3(0.72,1.27,0.26),0.105,0.055,Color("3b392d")).scale.z=1.4
	var cabinet := group("DeskSideIvoryCabinet",scene,Vector3(2.30,0.07,-2.26))
	box(cabinet,"Body",Vector3(0,0.53,0),Vector3(0.92,1.06,1.47),Color("c3b380"))
	box(cabinet,"Top",Vector3(0,1.10,0),Vector3(1.00,0.12,1.57),Color("d1be88"))
	for y: float in [0.22,0.57,0.91]:
		box(cabinet,"Drawer",Vector3(0,y,0.755),Vector3(0.83,0.28,0.055),Color("c2b185"))
		box(cabinet,"PullRecess",Vector3(0,y+0.04,0.79),Vector3(0.28,0.08,0.025),INK)
		rod(cabinet,"MetalPull",Vector3(-0.12,y+0.055,0.82),Vector3(0.12,y+0.055,0.82),0.019,GOLD)
	for i in range(3):
		box(cabinet,"StackedFolder",Vector3(-0.04,1.2+i*0.07,-0.17),Vector3(0.56,0.055,0.72),Color("49412d") if i==2 else PAPER)
	var board := group("OfficeNoticeboard",scene,Vector3(0.2,2.34,-3.43))
	box(board,"Frame",Vector3.ZERO,Vector3(2.7,1.15,0.075),INK)
	box(board,"Cork",Vector3(0,0,0.05),Vector3(2.57,1.02,0.025),Color("96713a"))
	for i in range(5):
		var page := group("PinnedMemo",board,Vector3(-1.0+i*0.48,rng.randf_range(-0.15,0.15),0.08))
		page.rotation_degrees.x=90
		paper(page,Vector3.ZERO,rng.randf_range(-7,7),i%3==0)
	var bin := group("Wastebasket",scene,Vector3(-1.85,0.06,-1.47))
	cylinder(bin,"Basket",Vector3(0,0.28,0),0.24,0.56,Color("3d3e31"),0.30)
	cylinder(bin,"Opening",Vector3(0,0.565,0),0.265,0.009,INK)
	for i in range(5):
		var scrap := box(bin,"Scrap",Vector3(rng.randf_range(-0.16,0.16),0.59,rng.randf_range(-0.16,0.16)),Vector3(0.16,0.03,0.12),PAPER)
		scrap.rotation_degrees=Vector3(rng.randf_range(-25,25),i*41,12)

func _build_storage() -> void:
	var shelf := group("TallFilingShelf",scene,Vector3(-3.37,0.06,-2.55))
	box(shelf,"Back",Vector3(0,1.48,-0.36),Vector3(1.28,2.96,0.1),INK)
	for x: float in [-0.66,0.66]:
		box(shelf,"Side",Vector3(x,1.48,0),Vector3(0.1,2.96,0.86),Color("735630"))
	for y: float in [0.08,0.66,1.21,2.18,2.94]:
		box(shelf,"Shelf",Vector3(0,y,0),Vector3(1.39,0.09,0.88),WOOD)
	for i in range(3):
		var binder := group(["RedBinder","GrayBinder","BeigeBinder"][i],shelf,Vector3(-0.41+i*0.39,1.27,0.12))
		var color: Color = [Color("a23826"),Color("717570"),Color("c4ad7d")][i]
		box(binder,"Cover",Vector3(0,0.37,0),Vector3(0.30,0.74,0.49),color)
		box(binder,"SpineLabel",Vector3(0,0.58,0.251),Vector3(0.18,0.11,0.016),color.lightened(0.14))
		cylinder(binder,"FingerHole",Vector3(0,0.18,0.259),0.057,0.014,INK).rotation_degrees.x=90
	for y: float in [0.35,2.46]:
		var carton := box(shelf,"ArchiveBox",Vector3(-0.09,y,0.07),Vector3(0.94,0.43,0.62),Color("a38c56"))
		box(carton,"Lid",Vector3(0,0.205,0),Vector3(1.0,0.055,0.66),Color("806437"))
		box(carton,"HandleSlot",Vector3(0,0.045,0.322),Vector3(0.33,0.065,0.02),INK)
	for i in range(5):
		box(shelf,"StackedPaper",Vector3(-0.24,0.75+i*0.07,0.1),Vector3(0.64,0.05,0.58),PAPER)
	var water := group("WaterDispenser",scene,Vector3(-2.21,0.06,-2.49))
	box(water,"IvoryBody",Vector3(0,0.64,0),Vector3(0.65,1.28,0.70),Color("cbb985"))
	box(water,"TapRecess",Vector3(0,0.85,0.363),Vector3(0.43,0.39,0.025),Color("3b4032"))
	for x: float in [-0.13,0.13]:
		cylinder(water,"Tap",Vector3(x,0.85,0.42),0.045,0.15,Color("9e9368")).rotation_degrees.x=90
		box(water,"TapButton",Vector3(x,0.96,0.405),Vector3(0.065,0.045,0.055),Color("a44b2d") if x<0 else Color("528c9e"))
	cylinder(water,"BottleNeck",Vector3(0,1.37,0),0.14,0.2,Color("36798b"))
	cylinder(water,"BlueWaterBottle",Vector3(0,1.88,0),0.32,0.88,Color("367f96"),0.30)
	for y: float in [1.49,1.68,1.89,2.11,2.30]:
		cylinder(water,"BottleRib",Vector3(0,y,0),0.327,0.045,Color("579cb0"))
	rod(water,"BottleHighlight",Vector3(0.20,1.69,0.23),Vector3(0.20,2.12,0.23),0.022,Color("a5c8bf"))

func _build_window() -> void:
	var window := group("WindowAndVenetianBlinds",scene,Vector3(4.23,0,-1.0))
	for z: float in [-1.95,1.95]:
		box(window,"WindowPost",Vector3(0,2.05,z),Vector3(0.18,2.12,0.13),INK)
	for y: float in [1.08,3.09]:
		box(window,"WindowRail",Vector3(0,y,0),Vector3(0.18,0.13,4.0),INK)
	box(window,"Sill",Vector3(-0.14,1.07,0),Vector3(0.42,0.10,4.1),GOLD)
	var glass := box(window,"AmberGlass",Vector3(0.10,2.1,0),Vector3(0.025,1.9,3.82),Color("b99b59"),0.45)
	glass.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	box(window,"Mullion",Vector3(-0.08,2.1,0),Vector3(0.1,1.95,0.08),INK)
	for i in range(12):
		var slat := box(window,"BlindSlat",Vector3(-0.14,1.30+i*0.151,0),Vector3(0.085,0.018,3.85),Color("74663c"))
		slat.rotation_degrees.z=-25
	for z: float in [-1.30,1.30]:
		rod(window,"BlindCord",Vector3(-0.27,1.20,z),Vector3(-0.27,3.09,z),0.009,INK)

func _build_printer() -> void:
	var printer := group("PrinterStation",scene,Vector3(3.14,0.08,1.0))
	printer.rotation_degrees.y=-17
	box(printer,"Stand",Vector3(0,0.57,0),Vector3(1.1,1.14,1.06),Color("605b42"))
	box(printer,"DoorPanel",Vector3(0,0.55,0.546),Vector3(0.98,0.94,0.028),Color("777057"))
	box(printer,"PrinterBody",Vector3(0,1.42,0),Vector3(1.0,0.55,0.91),Color("505750"))
	box(printer,"ScannerLid",Vector3(0,1.72,-0.09),Vector3(0.92,0.08,0.65),Color("7b8174"))
	box(printer,"OutputSlot",Vector3(0,1.49,0.468),Vector3(0.71,0.075,0.022),INK)
	var tray := group("PrintedLayoutPhoto",printer,Vector3(0,1.29,0.68))
	tray.rotation_degrees.x=-17
	box(tray,"Tray",Vector3.ZERO,Vector3(0.80,0.04,0.65),INK)
	box(tray,"Sheet",Vector3(0,0.024,0),Vector3(0.63,0.009,0.55),PAPER.lightened(0.12))
	box(tray,"Photograph",Vector3(0,0.031,-0.03),Vector3(0.52,0.003,0.34),Color("696857"))
	box(tray,"PhotoDesk",Vector3(0.08,0.035,-0.015),Vector3(0.25,0.003,0.12),Color("aeaa90"))
	box(tray,"PhotoCabinet",Vector3(-0.16,0.035,-0.04),Vector3(0.10,0.003,0.24),Color("33362d"))
	for i in range(3):
		box(tray,"CaptionLine",Vector3(0,0.033,0.18+i*0.022),Vector3(0.43-i*0.05,0.002,0.006),Color("615c46"))

func _build_traces() -> void:
	var traces := group("FloorAndContactTraces",scene)
	for radius: float in [0.73,0.80,0.89]:
		for i in range(72):
			if rng.randf()<0.22: continue
			var a := i*TAU/72
			var b := (i+0.8)*TAU/72
			rod(traces,"ChairCasterScuff",Vector3(0.15+cos(a)*radius,0.047,-0.62+sin(a)*radius),Vector3(0.15+cos(b)*radius,0.047,-0.62+sin(b)*radius),0.006,Color("4e422c"))
	for ring in range(3):
		var center := Vector3(-2.55+ring*0.29,0.048,-1.80+ring*0.07)
		for i in range(28):
			if rng.randf()<0.15: continue
			var a := i*TAU/28
			var b := (i+1)*TAU/28
			rod(traces,"WaterRing",center+Vector3(cos(a)*0.13,0,sin(a)*0.11),center+Vector3(cos(b)*0.13,0,sin(b)*0.11),0.008,Color("554d35"))
	var wear := group("SideWearMarks", scene.get_node("WritingDesk"))
	for i in range(7):
		var mark := box(wear,"ContactScratch%d" % (i+1),Vector3(1.601,0.72+i*0.024,0.26),Vector3(0.003,0.009,0.37+(i%3)*0.045),Color("352d20"))
		mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
