extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var scene := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	var flow := scene.get("first_case_flow_ui") as FirstCaseFlowUI
	assert(flow.briefing_panel.visible)
	var page := flow.briefing_panel.get_node("Margin/Column/NewspaperPage") as TextureRect
	assert(page.texture is AtlasTexture)
	assert((page.texture as AtlasTexture).atlas.resource_path == "res://assets/ui/case_briefing_newspaper/newspaper_modules.png")
	var accept := flow.briefing_panel.get_node("Margin/Column/AcceptButton") as Button
	var accept_style := accept.get_theme_stylebox("normal") as StyleBoxTexture
	assert(accept_style != null)
	assert((accept_style.texture as AtlasTexture).atlas.resource_path == "res://assets/ui/case_briefing_newspaper/newspaper_modules.png")
	var texture := root.get_texture()
	if texture != null:
		var image := texture.get_image()
		if image != null and not image.is_empty():
			image.save_png("res://tests/first_case_briefing_preview.png")
	print("FIRST_CASE_VISUAL_SMOKE_OK")
	quit(0)
