@tool
class_name CaseLightDevice
extends Node3D


signal settings_changed(device: CaseLightDevice)

@export var device_role := ""
@export_range(0.0, 4.0, 0.01) var light_energy := 0.0
@export_range(1800.0, 12000.0, 100.0) var temperature_kelvin := 4200.0
@export_range(-180.0, 180.0, 1.0) var head_yaw_degrees := 0.0
@export_range(-85.0, 20.0, 1.0) var head_pitch_degrees := -35.0
@export var light_range := 6.0
@export var spot_angle_degrees := 48.0
@export var casts_shadow := false

var effective_energy := 0.0
var light_local_position := Vector3.ZERO
var _aim_pivot: Node3D
var _spot_light: SpotLight3D


func configure(
	role: String,
	energy: float,
	temperature: float,
	yaw_degrees: float,
	pitch_degrees: float,
	range_value: float,
	spot_angle: float,
	shadow_enabled: bool,
	light_position: Vector3
) -> void:
	device_role = role
	light_energy = energy
	temperature_kelvin = temperature
	head_yaw_degrees = yaw_degrees
	head_pitch_degrees = pitch_degrees
	light_range = range_value
	spot_angle_degrees = spot_angle
	casts_shadow = shadow_enabled
	light_local_position = light_position
	_ensure_light(light_position)
	_apply_settings(false)


func set_enabled(enabled: bool) -> void:
	_ensure_light(light_local_position)
	if is_instance_valid(_spot_light):
		_spot_light.visible = enabled


func set_energy(value: float, emit_change := true) -> void:
	var was_on := light_energy > 0.01
	light_energy = clampf(value, 0.0, 4.0)
	if emit_change and not Engine.is_editor_hint() and was_on != (light_energy > 0.01):
		var audio := get_node_or_null("/root/GameAudio")
		if audio != null:
			audio.call("play", "lamp_toggle", global_position)
	_apply_settings(emit_change)


func set_temperature(value: float, emit_change := true) -> void:
	temperature_kelvin = clampf(value, 1800.0, 12000.0)
	_apply_settings(emit_change)


func set_head_yaw(value: float, emit_change := true) -> void:
	head_yaw_degrees = wrapf(value, -180.0, 180.0)
	_apply_settings(emit_change)


func set_head_pitch(value: float, emit_change := true) -> void:
	head_pitch_degrees = clampf(value, -85.0, 20.0)
	_apply_settings(emit_change)


func apply_debug_values(values: Dictionary) -> void:
	if values.has("energy"):
		light_energy = float(values["energy"])
	if values.has("temperature"):
		temperature_kelvin = float(values["temperature"])
	if values.has("yaw"):
		head_yaw_degrees = float(values["yaw"])
	if values.has("pitch"):
		head_pitch_degrees = float(values["pitch"])
	_apply_settings(true)


func set_reflected_light(target_position: Vector3, strength: float, source_temperature: float) -> void:
	effective_energy = maxf(0.0, strength)
	light_energy = effective_energy
	temperature_kelvin = lerpf(source_temperature, 5200.0, 0.28)
	_apply_settings(false)
	if is_instance_valid(_aim_pivot):
		_aim_pivot.look_at(target_position, Vector3.UP)


func get_light_origin() -> Vector3:
	return _aim_pivot.global_position if is_instance_valid(_aim_pivot) else global_position


func get_light_direction() -> Vector3:
	return -_aim_pivot.global_basis.z.normalized() if is_instance_valid(_aim_pivot) else -global_basis.z.normalized()


func get_effective_energy() -> float:
	return effective_energy if device_role == "reflector" else light_energy


func _ensure_light(light_position: Vector3) -> void:
	_aim_pivot = get_node_or_null("AimPivot") as Node3D
	if not is_instance_valid(_aim_pivot):
		_aim_pivot = Node3D.new()
		_aim_pivot.name = "AimPivot"
		add_child(_aim_pivot)
	_aim_pivot.position = light_position
	_spot_light = _aim_pivot.get_node_or_null("SpotLight3D") as SpotLight3D
	if not is_instance_valid(_spot_light):
		_spot_light = SpotLight3D.new()
		_spot_light.name = "SpotLight3D"
		_aim_pivot.add_child(_spot_light)


func _apply_settings(emit_change: bool) -> void:
	if not is_instance_valid(_aim_pivot) or not is_instance_valid(_spot_light):
		return
	if device_role != "reflector":
		_aim_pivot.rotation_degrees = Vector3(head_pitch_degrees, head_yaw_degrees, 0.0)
	_spot_light.light_energy = light_energy
	_spot_light.light_color = _temperature_to_color(temperature_kelvin)
	_spot_light.spot_range = light_range
	_spot_light.spot_angle = spot_angle_degrees
	_spot_light.spot_attenuation = 1.15
	_spot_light.shadow_enabled = casts_shadow
	_spot_light.shadow_blur = 0.8 if device_role == "cold_panel" else 0.18
	if emit_change:
		settings_changed.emit(self)


static func _temperature_to_color(kelvin: float) -> Color:
	var temperature := clampf(kelvin, 1000.0, 40000.0) / 100.0
	var red := 255.0
	var green := 255.0
	var blue := 255.0
	if temperature <= 66.0:
		red = 255.0
		green = 99.4708025861 * log(temperature) - 161.1195681661
		blue = 0.0 if temperature <= 19.0 else 138.5177312231 * log(temperature - 10.0) - 305.0447927307
	else:
		red = 329.698727446 * pow(temperature - 60.0, -0.1332047592)
		green = 288.1221695283 * pow(temperature - 60.0, -0.0755148492)
		blue = 255.0
	return Color(
		clampf(red, 0.0, 255.0) / 255.0,
		clampf(green, 0.0, 255.0) / 255.0,
		clampf(blue, 0.0, 255.0) / 255.0
	)
