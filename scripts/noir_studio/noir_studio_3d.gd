extends Node3D

@onready var camera: Camera3D = $Camera3D
var yaw := -16.0
var pitch := 51.0
var target := Vector3(0.0, 0.65, 0.0)
var previous_msaa: int

func _ready() -> void:
	previous_msaa = get_viewport().msaa_3d
	get_viewport().msaa_3d = Viewport.MSAA_4X
	_update_camera()

func _exit_tree() -> void:
	get_viewport().msaa_3d = previous_msaa

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			yaw -= event.relative.x * 0.25
			pitch = clampf(pitch + event.relative.y * 0.2, 20.0, 80.0)
			_update_camera()
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			target += (-camera.global_basis.x * event.relative.x + camera.global_basis.y * event.relative.y) * camera.size / get_viewport().get_visible_rect().size.y
			_update_camera()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.size = maxf(5.0, camera.size - 0.6)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.size = minf(18.0, camera.size + 0.6)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			yaw = -16.0
			pitch = 51.0
			target = Vector3(0, 0.65, 0)
			camera.size = 12.2
			_update_camera()
		elif event.keycode == KEY_L:
			$Lighting/DeskLight.visible = not $Lighting/DeskLight.visible
		elif event.keycode == KEY_TAB:
			$HUD.visible = not $HUD.visible
			get_viewport().set_input_as_handled()

func _update_camera() -> void:
	var direction := Vector3(sin(deg_to_rad(yaw)) * cos(deg_to_rad(pitch)), sin(deg_to_rad(pitch)), cos(deg_to_rad(yaw)) * cos(deg_to_rad(pitch)))
	camera.position = target + direction * 18.0
	camera.look_at(target)
