extends RefCounted

static func apply(scene: Node3D) -> void:
	var board := scene.get_node("EvidenceBoard") as Node3D
	for child in board.get_children():
		if child.name not in ["BlackFrame", "Cork"]:
			child.free()
	var display := MeshInstance3D.new()
	display.name="ClueCollage"
	var quad := QuadMesh.new()
	quad.size=Vector2(3.48,1.62)
	display.mesh=quad
	display.position.z=0.12
	var mat := StandardMaterial3D.new()
	mat.albedo_texture=load("res://assets/player_studio/clue_board/collage.png")
	mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.alpha_scissor_threshold=0.5
	mat.roughness=1.0
	mat.specular_mode=BaseMaterial3D.SPECULAR_DISABLED
	mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	display.material_override=mat
	display.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	board.add_child(display)

