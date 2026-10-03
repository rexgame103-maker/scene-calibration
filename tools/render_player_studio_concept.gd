extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	root.size=Vector2i(1536,1024)
	root.msaa_3d=Viewport.MSAA_4X
	var scene := (load("res://scenes/studio/player_studio_concept.tscn") as PackedScene).instantiate()
	assert(scene.get_script()==null)
	for part in ["InvestigationDesk","DeskChair","ArchiveBookcase","MiniatureWorkbench","LeatherSofa","CoffeeTable","FloorLamp"]:
		assert(scene.has_node(part))
	assert(scene.get_node("CeilingLightBlocker").cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY)
	root.add_child(scene)
	current_scene=scene
	var packed := PackedScene.new()
	assert(packed.pack(scene)==OK)
	await create_timer(1).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/player_studio_concept_preview.png")
	print("PLAYER_STUDIO_OK: grouped furniture, shadow-only ceiling, scene roundtrip, rendered")
	quit()
