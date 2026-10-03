@tool
class_name DeskFurniture
extends RigidBody3D


const INTERACTION_SIZE := Vector3(3.166877, 1.704236, 1.733879)


@export_group("Desk Collision")
@export var collision_size := Vector3(2.976864, 1.516, 1.629846):
	set(value):
		collision_size = Vector3(
			maxf(0.06, value.x),
			maxf(0.04, value.y),
			maxf(0.06, value.z)
		)
		if is_inside_tree():
			_sync_collision_and_preview()
@export var collision_offset := Vector3.ZERO:
	set(value):
		collision_offset = value
		if is_inside_tree():
			_sync_collision_and_preview()
@export var show_collision_preview := true:
	set(value):
		show_collision_preview = value
		if is_inside_tree():
			_sync_collision_and_preview()


func _ready() -> void:
	name = "DeskFurniture" if name.is_empty() else name
	set_meta("furniture_kind", "desk")
	_configure_physics()
	_sync_collision_and_preview()
	set_process(Engine.is_editor_hint())


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_sync_collision_and_preview()


func get_surface_height() -> float:
	return collision_offset.y + collision_size.y


func get_surface_size() -> Vector3:
	return collision_size


func get_surface_offset() -> Vector3:
	return collision_offset


func get_collision_profile() -> Dictionary:
	return {
		"size": collision_size,
		"offset": collision_offset
	}


func _configure_physics() -> void:
	collision_layer = 4
	collision_mask = 1 | 4
	mass = 8.0
	linear_damp = 1.1
	angular_damp = 1.8
	can_sleep = true
	continuous_cd = false
	if physics_material_override == null:
		var physics_material := PhysicsMaterial.new()
		physics_material.friction = 0.86
		physics_material.bounce = 0.04
		physics_material_override = physics_material


func _sync_collision_and_preview() -> void:
	var collision_center := collision_offset + Vector3(0.0, collision_size.y * 0.5, 0.0)
	var physics_shape := get_node_or_null("FurniturePhysicsShape") as CollisionShape3D
	if not is_instance_valid(physics_shape):
		physics_shape = CollisionShape3D.new()
		physics_shape.name = "FurniturePhysicsShape"
		add_child(physics_shape)
	var physics_box := physics_shape.shape as BoxShape3D
	if physics_box == null:
		physics_box = BoxShape3D.new()
		physics_shape.shape = physics_box
	physics_box.size = collision_size
	physics_shape.position = collision_center

	var hit_area := get_node_or_null("FurnitureHitArea") as Area3D
	if not is_instance_valid(hit_area):
		hit_area = Area3D.new()
		hit_area.name = "FurnitureHitArea"
		hit_area.collision_layer = 2
		hit_area.collision_mask = 0
		add_child(hit_area)
	hit_area.set_meta("furniture_root", self)
	var hit_shape := hit_area.get_node_or_null("InteractionShape") as CollisionShape3D
	if not is_instance_valid(hit_shape):
		hit_shape = CollisionShape3D.new()
		hit_shape.name = "InteractionShape"
		hit_area.add_child(hit_shape)
	var hit_box := hit_shape.shape as BoxShape3D
	if hit_box == null:
		hit_box = BoxShape3D.new()
		hit_shape.shape = hit_box
	var interaction_size: Vector3 = get_meta("concept_interaction_size", INTERACTION_SIZE)
	hit_box.size = Vector3(interaction_size.x * 0.96, interaction_size.y, interaction_size.z * 0.96)
	hit_shape.position = Vector3(0.0, interaction_size.y * 0.5, 0.0)

	var preview := get_node_or_null("CollisionPreview") as MeshInstance3D
	if not is_instance_valid(preview):
		preview = MeshInstance3D.new()
		preview.name = "CollisionPreview"
		preview.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.18, 0.82, 1.0, 0.22)
		material.emission_enabled = true
		material.emission = Color(0.08, 0.58, 0.90)
		material.emission_energy_multiplier = 0.65
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.no_depth_test = true
		preview.material_override = material
		add_child(preview)
	var preview_box := preview.mesh as BoxMesh
	if preview_box == null:
		preview_box = BoxMesh.new()
		preview.mesh = preview_box
	preview_box.size = collision_size
	preview.position = collision_center
	preview.visible = Engine.is_editor_hint() and show_collision_preview
