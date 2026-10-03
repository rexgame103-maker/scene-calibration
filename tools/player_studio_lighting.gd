extends RefCounted

static func spot(parent: Node3D, label: String, at: Vector3, target: Vector3, color: Color, energy: float, distance: float, angle: float) -> void:
	var light := SpotLight3D.new()
	light.name = label
	light.transform = Transform3D(Basis.IDENTITY, at).looking_at(target)
	light.light_color = color
	light.light_energy = energy
	light.spot_range = distance
	light.spot_angle = angle
	light.spot_attenuation = 0.7
	light.spot_angle_attenuation = 1.5
	light.shadow_enabled = true
	light.shadow_bias = 0.035
	light.shadow_normal_bias = 0.15
	parent.add_child(light)

static func apply(scene: Node3D) -> void:
	var old := scene.get_node_or_null("WorkspaceLighting")
	if old != null:
		old.free()
	var lighting := Node3D.new()
	lighting.name = "WorkspaceLighting"
	scene.add_child(lighting)
	# Local fill keeps the window cool without washing out the room shadows.
	spot(lighting, "WindowCoolFill", Vector3(-4.65,2.15,-0.9), Vector3(-1.7,0.75,-1.1), Color("aecce3"), 0.85, 5.2, 62)
	var board: Node3D = scene.get_node("EvidenceBoard")
	spot(lighting, "EvidenceBoardWarmWash", board.position+Vector3(-0.8,0.55,1.05), board.position+Vector3(0,-0.1,0), Color("ffdbac"), 0.32, 2.9, 65)
	var bench: Node3D = scene.get_node("MiniatureWorkbench")
	spot(lighting, "ModelShelfWarmPool", bench.position+Vector3(0.1,1.84,-0.37), bench.position+Vector3(0,1.05,0.25), Color("ffe1b0"), 1.3, 2.6, 61)
	var desk: Node3D = scene.get_node("InvestigationDesk")
	var screen := OmniLight3D.new()
	screen.name = "MonitorCoolBounce"
	screen.position = desk.position+Vector3(-0.18,1.65,0.30)
	screen.light_color = Color("82c8df")
	screen.light_energy = 0.12
	screen.omni_range = 1.6
	screen.omni_attenuation = 1.4
	screen.shadow_enabled = true
	screen.shadow_bias = 0.025
	screen.shadow_normal_bias = 0.1
	lighting.add_child(screen)
	var lamp: SpotLight3D = desk.get_node("DeskLampPool")
	lamp.light_energy = 1.2
	lamp.spot_attenuation = 0.8
	lamp.spot_angle_attenuation = 1.3
	print("STUDIO_LIGHTING: cool window/screen, warm desk/board/model pools")

