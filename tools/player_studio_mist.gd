extends RefCounted

static func apply(scene: Node3D) -> void:
	var old := scene.get_node_or_null("WindowLightMist")
	if old != null:
		old.free()
	var mist := MeshInstance3D.new()
	mist.name = "WindowLightMist"
	mist.position = Vector3(-2.4, 1.5, -0.9)
	var box := BoxMesh.new()
	box.size = Vector3(4.8, 3.0, 3.0)
	mist.mesh = box
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/studio_window_mist.gdshader")
	mat.set_shader_parameter("density", 0.22)
	mist.material_override = mat
	mist.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	scene.add_child(mist)

