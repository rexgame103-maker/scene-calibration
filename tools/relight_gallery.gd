extends SceneTree
func _initialize() -> void:
	var scene := (load("res://scenes/cases/gallery_restored_concept.tscn") as PackedScene).instantiate()
	var materials: Dictionary = {}
	for mesh in scene.find_children("*","MeshInstance3D",true,false):
		var original := mesh.material_override as ShaderMaterial
		if original == null: continue
		if not materials.has(original):
			var mat := original.duplicate() as ShaderMaterial
			mat.shader = load("res://shaders/gallery_toon.gdshader")
			materials[original] = mat
		mesh.material_override = materials[original]
		if mesh.name == "ReflectingSurface":
			mesh.material_override = mesh.material_override.duplicate()
			mesh.material_override.set_shader_parameter("glow",0.18)
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var key := scene.get_node("WarmKey") as DirectionalLight3D
	key.rotation_degrees = Vector3(-24,-100,0)
	key.light_energy = 0.95
	key.light_color = Color("ffdda8")
	key.shadow_bias = 0.08
	key.shadow_normal_bias = 0.6
	key.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	var fill := scene.get_node("CoolFill") as DirectionalLight3D
	fill.light_energy = 0.22
	fill.rotation_degrees = Vector3(-25,35,0)
	fill.light_color = Color("c1c6c4")
	var cold := scene.get_node("StandardColdLight/CoolWorkLight") as SpotLight3D
	cold.light_energy = 1.35
	cold.spot_attenuation = 0.6
	cold.spot_range = 2.7
	cold.spot_angle = 43
	cold.shadow_enabled = true
	cold.shadow_bias = 0.04
	cold.shadow_normal_bias = 0.35
	cold.rotation_degrees = Vector3(-50,180,0)
	var architecture := scene.get_node("Architecture")
	for mesh in architecture.find_children("*","MeshInstance3D",true,false):
		var label := String(mesh.name)
		if label.contains("Wall") or label.contains("Pier") or label.contains("Mullion") or label.contains("Crossbar"):
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	# Render only its shadow, keeping the overhead cutaway camera unobstructed.
	var ceiling := architecture.get_node_or_null("CeilingLightBlocker") as MeshInstance3D
	if ceiling == null:
		ceiling = MeshInstance3D.new()
		ceiling.name = "CeilingLightBlocker"
		architecture.add_child(ceiling)
		ceiling.owner = scene
	var ceiling_mesh := BoxMesh.new()
	ceiling_mesh.size = Vector3(10.2,0.2,7.2)
	ceiling.mesh = ceiling_mesh
	ceiling.position = Vector3(0,3.5,0)
	ceiling.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	var packed := PackedScene.new()
	assert(packed.pack(scene) == OK)
	assert(ResourceSaver.save(packed,"res://scenes/cases/gallery_restored_concept.tscn") == OK)
	scene.free()
	print("GALLERY_RELIT")
	quit()
