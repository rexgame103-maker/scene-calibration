extends SceneTree
## Bake curved leaf blades and petioles once; gameplay loads two shared meshes.

const OUTPUT := "res://assets/models/plants/"
const LENGTH_STEPS := 14
const WIDTH_STEPS := 6
const STEM_STEPS := 8
const STEM_SIDES := 6
var leaf_vertex_count := 0
var stem_vertex_count := 0
# angle, blade length, full width, blade base height, base radius, tilt, tip droop, twist
const LEAVES := [
	[8.0,   0.47, 0.20, 0.25, 0.11,  8.0, 0.10,  0.025],
	[83.0,  0.43, 0.19, 0.28, 0.10, 14.0, 0.09, -0.020],
	[159.0, 0.45, 0.21, 0.27, 0.11, 10.0, 0.10,  0.020],
	[238.0, 0.42, 0.19, 0.26, 0.12, 13.0, 0.09, -0.025],
	[307.0, 0.45, 0.20, 0.31, 0.09, 17.0, 0.10,  0.015],
	[47.0,  0.45, 0.19, 0.43, 0.08, 28.0, 0.11, -0.025],
	[124.0, 0.42, 0.19, 0.44, 0.07, 34.0, 0.10,  0.020],
	[202.0, 0.44, 0.18, 0.40, 0.08, 29.0, 0.10, -0.020],
	[280.0, 0.43, 0.20, 0.42, 0.07, 32.0, 0.09,  0.025],
	[26.0,  0.43, 0.16, 0.52, 0.04, 58.0, 0.04,  0.015],
	[169.0, 0.41, 0.15, 0.53, 0.03, 68.0, 0.04, -0.012],
	[266.0, 0.38, 0.14, 0.49, 0.04, 57.0, 0.04,  0.010],
]

func _initialize() -> void:
	call_deferred("build")

func build() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var blades := SurfaceTool.new()
	var stems := SurfaceTool.new()
	blades.begin(Mesh.PRIMITIVE_TRIANGLES)
	stems.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in range(LEAVES.size()):
		add_leaf(blades, LEAVES[i], i)
		add_petiole(stems, LEAVES[i])
	var leaf_mesh := blades.commit()
	var stem_mesh := stems.commit()
	leaf_mesh.resource_name = "Curved lanceolate leaves"
	stem_mesh.resource_name = "Tapered curved petioles"
	assert(ResourceSaver.save(leaf_mesh, OUTPUT + "indoor_leaves.res", ResourceSaver.FLAG_COMPRESS) == OK)
	assert(ResourceSaver.save(stem_mesh, OUTPUT + "indoor_stems.res", ResourceSaver.FLAG_COMPRESS) == OK)
	print("INDOOR_FOLIAGE_BAKED leaves=", LEAVES.size(), " bounds=", leaf_mesh.get_aabb(),
		" triangles=", (leaf_mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX].size() + stem_mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX].size()) / 3)
	quit()

func leaf_position(spec: Array, t: float, u: float) -> Vector3:
	var angle := deg_to_rad(float(spec[0]))
	var radial := Vector3(cos(angle), 0, sin(angle))
	var across := Vector3(-sin(angle), 0, cos(angle))
	var length := float(spec[1])
	var tilt := deg_to_rad(float(spec[5]))
	var shape := pow(maxf(0.0, sin(PI * t)), 0.80) * (1.0 - 0.16 * t)
	var width := float(spec[2]) * 0.5 * shape
	var bend := float(spec[6]) * t * t
	var ridge := 0.020 * shape * (1.0 - u * u)
	var twist := float(spec[7]) * u * shape * t
	return radial * (float(spec[4]) + length * cos(tilt) * t) \
		+ across * (u * width + 0.014 * sin(PI * t) * sin(angle * 2.0)) \
		+ Vector3.UP * (float(spec[3]) + length * sin(tilt) * t - bend + ridge + twist)

func leaf_vertex(tool: SurfaceTool, spec: Array, t: float, u: float, color: Color) -> void:
	var along := leaf_position(spec, t + 0.001, u) - leaf_position(spec, t - 0.001, u)
	var across := leaf_position(spec, t, u + 0.001) - leaf_position(spec, t, u - 0.001)
	var normal := across.cross(along).normalized()
	if normal.is_zero_approx(): normal = Vector3.UP
	tool.set_normal(normal)
	tool.set_uv(Vector2(u * 0.5 + 0.5, t))
	tool.set_color(color)
	tool.add_vertex(leaf_position(spec, t, u))
	leaf_vertex_count += 1

func add_leaf(tool: SurfaceTool, spec: Array, leaf_index: int) -> void:
	var start := leaf_vertex_count
	var tint := Color(0.92 + (leaf_index % 4) * 0.035, 0.94 + (leaf_index % 3) * 0.035, 0.92, 1)
	leaf_vertex(tool, spec, 0.0, 0.0, tint)
	for row: int in range(1, LENGTH_STEPS):
		for col: int in range(WIDTH_STEPS + 1):
			leaf_vertex(tool, spec, float(row) / LENGTH_STEPS, float(col) / WIDTH_STEPS * 2.0 - 1.0, tint)
	var tip := leaf_vertex_count
	leaf_vertex(tool, spec, 1.0, 0.0, tint)
	for col: int in range(WIDTH_STEPS):
		triangle(tool, start, start + 1 + col, start + 2 + col)
		var last := start + 1 + (LENGTH_STEPS - 2) * (WIDTH_STEPS + 1) + col
		triangle(tool, last, tip, last + 1)
	for row: int in range(LENGTH_STEPS - 2):
		for col: int in range(WIDTH_STEPS):
			var a := start + 1 + row * (WIDTH_STEPS + 1) + col
			var b := a + WIDTH_STEPS + 1
			triangle(tool, a, b, a + 1)
			triangle(tool, a + 1, b, b + 1)

func add_petiole(tool: SurfaceTool, spec: Array) -> void:
	var angle := deg_to_rad(float(spec[0]))
	var radial := Vector3(cos(angle), 0, sin(angle))
	var across := Vector3(-sin(angle), 0, cos(angle))
	var end := leaf_position(spec, 0.0, 0.0)
	var start_point := radial * 0.028
	var handle := radial * (float(spec[4]) * 0.18) + Vector3.UP * (float(spec[3]) * 0.65)
	var start := stem_vertex_count
	for row: int in range(STEM_STEPS + 1):
		var t := float(row) / STEM_STEPS
		var center := start_point * pow(1.0 - t, 2) + handle * (2.0 * t * (1.0 - t)) + end * t * t
		var tangent := ((handle - start_point) * (1.0 - t) + (end - handle) * t).normalized()
		var other := tangent.cross(across).normalized()
		for side: int in range(STEM_SIDES):
			var normal := across * cos(TAU * side / STEM_SIDES) + other * sin(TAU * side / STEM_SIDES)
			tool.set_normal(normal)
			tool.add_vertex(center + normal * lerpf(0.012, 0.004, t))
			stem_vertex_count += 1
	for row: int in range(STEM_STEPS):
		for side: int in range(STEM_SIDES):
			var a := start + row * STEM_SIDES + side
			var b := start + row * STEM_SIDES + (side + 1) % STEM_SIDES
			triangle(tool, a, a + STEM_SIDES, b)
			triangle(tool, b, a + STEM_SIDES, b + STEM_SIDES)

func triangle(tool: SurfaceTool, a: int, b: int, c: int) -> void:
	tool.add_index(a)
	tool.add_index(b)
	tool.add_index(c)
