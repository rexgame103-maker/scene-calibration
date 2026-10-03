class_name StudioMenuPreview
extends Node3D


signal preview_refreshed

const FLOOR_HEIGHT := 3.2
const ROOM_SIZE := Vector2(6.0, 6.0)
const ROOM_PLOT_SEQUENCE: Array[Vector2i] = [
	Vector2i(0, 0),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(1, 1)
]

@export_range(0, 1, 1) var preview_floor := 0

@onready var shell_root: Node3D = $StudioShell
@onready var furniture_root: Node3D = $StudioFurniture

var profile: Node


func _ready() -> void:
	profile = get_node_or_null("/root/PlayerProfile")
	if not is_instance_valid(profile):
		push_error("PlayerProfile Autoload is missing; the start-menu studio preview cannot be built")
		return
	_connect_profile_signals()
	refresh_preview()


func refresh_preview() -> void:
	if not is_instance_valid(profile) or not is_instance_valid(shell_root) or not is_instance_valid(furniture_root):
		return
	_build_shell()
	_restore_furniture()
	preview_refreshed.emit()


func _connect_profile_signals() -> void:
	var refresh_callable := Callable(self, "refresh_preview")
	if profile.has_signal("studio_layout_changed") and not profile.studio_layout_changed.is_connected(refresh_callable):
		profile.studio_layout_changed.connect(refresh_callable)
	var rooms_callable := Callable(self, "_on_studio_rooms_changed")
	if profile.has_signal("studio_rooms_changed") and not profile.studio_rooms_changed.is_connected(rooms_callable):
		profile.studio_rooms_changed.connect(rooms_callable)


func _on_studio_rooms_changed(floor_index: int, _room_count: int) -> void:
	if floor_index == preview_floor:
		refresh_preview()


func _build_shell() -> void:
	_clear_children(shell_root)
	var shell_data := profile.get("studio_shell") as Dictionary
	var wall_style := clampi(int(shell_data.get("wall_style", 0)), 0, 2)
	var floor_style := clampi(int(shell_data.get("floor_style", 0)), 0, 2)
	var floor_color: Color = [Color("5a6873"), Color("766252"), Color("57685b")][floor_style]
	var wall_color: Color = [Color("b8b5aa"), Color("8f9bab"), Color("b4a28d")][wall_style]
	var room_count := maxi(1, int(profile.call("get_studio_room_count", preview_floor)))
	var base_y := float(preview_floor) * FLOOR_HEIGHT
	for room_index: int in range(room_count):
		var plot := ROOM_PLOT_SEQUENCE[room_index]
		var center2 := _room_plot_center(room_index)
		var prefix := "Floor%02dRoom%02d" % [preview_floor + 1, room_index + 1]
		var room_floor_color := floor_color.lightened(0.06 * preview_floor)
		_add_shell_box(
			prefix + "Floor",
			Vector3(ROOM_SIZE.x - 0.08, 0.18, ROOM_SIZE.y - 0.08),
			Vector3(center2.x, base_y - 0.09, center2.y),
			room_floor_color
		)
		if plot.y == 0:
			_add_shell_box(
				prefix + "BackWall",
				Vector3(ROOM_SIZE.x, 3.0, 0.16),
				Vector3(center2.x, base_y + 1.5, center2.y - ROOM_SIZE.y * 0.5),
				wall_color
			)
		if plot.x == 0:
			_add_shell_box(
				prefix + "LeftWall",
				Vector3(0.16, 3.0, ROOM_SIZE.y),
				Vector3(center2.x - ROOM_SIZE.x * 0.5, base_y + 1.5, center2.y),
				wall_color.darkened(0.08)
			)
		if plot.x > 0:
			_add_shell_box(
				prefix + "XSeam",
				Vector3(0.055, 0.025, ROOM_SIZE.y - 0.20),
				Vector3(center2.x - ROOM_SIZE.x * 0.5, base_y + 0.013, center2.y),
				wall_color.darkened(0.18)
			)
		if plot.y > 0:
			_add_shell_box(
				prefix + "ZSeam",
				Vector3(ROOM_SIZE.x - 0.20, 0.025, 0.055),
				Vector3(center2.x, base_y + 0.013, center2.y - ROOM_SIZE.y * 0.5),
				wall_color.darkened(0.18)
			)


func _restore_furniture() -> void:
	_clear_children(furniture_root)
	for entry: Dictionary in profile.get("placed_studio_layout"):
		if int(entry.get("floor", 0)) != preview_floor:
			continue
		var kind := String(entry.get("kind", ""))
		if kind.is_empty():
			continue
		var furniture := StudioFurnitureFactory.build(kind)
		furniture.name = "Preview%s" % kind.to_pascal_case()
		furniture.set_meta("studio_floor", preview_floor)
		furniture.set_meta("studio_uid", String(entry.get("uid", "")))
		furniture_root.add_child(furniture)
		var values: Array = entry.get("position", [0.0, 0.0, 0.0])
		if values.size() >= 3:
			furniture.position = Vector3(float(values[0]), float(values[1]), float(values[2]))
		var rotations: Array = entry.get("rotation", [])
		if rotations.size() >= 3:
			furniture.rotation_degrees = Vector3(float(rotations[0]), float(rotations[1]), float(rotations[2]))
		else:
			furniture.rotation_degrees.y = float(entry.get("rotation_y", 0.0))


func _add_shell_box(node_name: String, size: Vector3, box_position: Vector3, color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = box_position
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	mesh_instance.material_override = material
	mesh_instance.set_meta("studio_floor", preview_floor)
	shell_root.add_child(mesh_instance)


func _room_plot_center(room_index: int) -> Vector2:
	var plot := ROOM_PLOT_SEQUENCE[clampi(room_index, 0, ROOM_PLOT_SEQUENCE.size() - 1)]
	return Vector2(float(plot.x) * ROOM_SIZE.x, float(plot.y) * ROOM_SIZE.y)


func _clear_children(root_node: Node) -> void:
	for child: Node in root_node.get_children():
		root_node.remove_child(child)
		child.free()
