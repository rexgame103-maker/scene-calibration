extends SceneTree
## Render the saved plant part with an unobstructed close-up for visual review.

func _initialize() -> void:
	call_deferred("preview")

func preview() -> void:
	root.size = Vector2i(960, 960)
	var stage := Node3D.new()
	root.add_child(stage)
	current_scene = stage
	var arguments := OS.get_cmdline_user_args()
	var suffix := arguments[0] if not arguments.is_empty() else "after"
	var plant := load("res://scenes/studio/player_parts/studio_plant.scn").instantiate() as Node3D
	if suffix == "studio":
		plant.free()
		var studio := load("res://scenes/studio/player_studio_concept.tscn").instantiate() as Node3D
		stage.add_child(studio)
		plant = studio.get_node("PottedPlant")
	else:
		stage.add_child(plant)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200, 200)
	ground.mesh = plane
	ground.position.y = -0.008
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("6e6150")
	floor_material.roughness = 1.0
	ground.material_override = floor_material
	stage.add_child(ground)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-48, -32, 0)
	light.light_energy = 1.8
	light.light_color = Color("ffe2b5")
	light.shadow_enabled = true
	stage.add_child(light)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-35, 145, 0)
	fill.light_energy = 0.65
	fill.light_color = Color("c6dbc4")
	stage.add_child(fill)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("26251e")
	stage.add_child(environment)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 1.65
	stage.add_child(camera)
	camera.position = Vector3(1.7, 1.62, 2.8)
	camera.look_at(Vector3(0, 0.65, 0))
	if suffix == "studio":
		camera.position += plant.global_position
		camera.look_at(plant.global_position + Vector3(0, 0.65, 0))
		light.hide()
		fill.hide()
		ground.hide()
		environment.environment = null
	camera.current = true
	await create_timer(1.2).timeout
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/plant_model_" + suffix + ".png")
	print("PLANT_PREVIEW_SAVED: tests/plant_model_", suffix, ".png")
	root.get_node("GameAudio").stop_all()
	stage.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit()
