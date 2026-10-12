class_name DroneFlyer
extends Node3D
## One of VesPer's FPV drones patrolling over a village: lazy figure-eights over the square,
## tilting into the turns, props spinning, buzzing.

var center := Vector3.ZERO
var radius := 14.0
var height := 11.0
var speed := 0.22
var _t := randf() * TAU
var _model: Node3D
var _rotors: Array = []
var _prev := Vector3.ZERO


func _ready() -> void:
	_model = TechProps.drone_model(self)
	_model.scale = Vector3.ONE * 1.6
	_rotors = _model.get_meta("rotors")
	TechProps.loop_sound(self, "drone_buzz", -8.0, 35.0)
	global_position = _pos(_t)
	_prev = global_position


func _pos(t: float) -> Vector3:
	return center + Vector3(sin(t) * radius, height + sin(t * 3.0) * 1.5, sin(t * 2.0) * radius * 0.5)


func _process(delta: float) -> void:
	for i in _rotors.size():
		_rotors[i].rotation.y += delta * (90.0 if i % 2 == 0 else -90.0)
	_t += delta * speed
	var p := _pos(_t)
	var v := (p - _prev) / maxf(delta, 0.001)
	global_position = p
	_prev = p
	if v.length() > 0.1:
		var yaw := atan2(-v.x, -v.z)
		rotation.y = lerp_angle(rotation.y, yaw, minf(1.0, 4.0 * delta))
		_model.rotation.x = lerpf(_model.rotation.x, -0.25, minf(1.0, 3.0 * delta))
		var turn := wrapf(yaw - rotation.y, -PI, PI)
		_model.rotation.z = lerpf(_model.rotation.z, clampf(turn * 2.0, -0.5, 0.5), minf(1.0, 3.0 * delta))
