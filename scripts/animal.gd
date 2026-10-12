class_name Animal
extends CharacterBody3D
## Harmless wildlife built from primitives: deer, rabbit, crow, chicken. Wanders near its home,
## flees from the player (crows fly away), can be shot. Shooting a farm chicken counts as a crime.

var world: Node
var kind := "deer"
var home := Vector3.ZERO
var owned := false              # farm animals: harming them is a crime
var hp := 20.0
var _target := Vector3.ZERO
var _wait := 0.0
var _flee_t := 0.0
var _scared_by := Vector3.INF
var _fly_t := 0.0
var _legs: Array[Node3D] = []
var _phase := randf() * TAU
var _body: Node3D
var _dead := false
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var blood_color := Color(0.55, 0.05, 0.05)

const SPEC := {
	"deer": {"speed": 2.0, "run": 9.0, "hp": 45.0, "flee": 22.0},
	"rabbit": {"speed": 1.5, "run": 7.0, "hp": 8.0, "flee": 10.0},
	"crow": {"speed": 0.8, "run": 8.0, "hp": 6.0, "flee": 9.0},
	"chicken": {"speed": 0.9, "run": 3.5, "hp": 8.0, "flee": 4.0},
}


func _ready() -> void:
	add_to_group("damageable")
	add_to_group("animals")
	collision_layer = 16
	collision_mask = 1
	hp = SPEC[kind]["hp"]
	var cs := CollisionShape3D.new()
	var sh := CapsuleShape3D.new()
	var size := {"deer": Vector2(0.45, 1.3), "rabbit": Vector2(0.15, 0.3), "crow": Vector2(0.12, 0.25), "chicken": Vector2(0.18, 0.4)}[kind] as Vector2
	sh.radius = size.x
	sh.height = maxf(size.y, size.x * 2.0 + 0.01)
	cs.shape = sh
	cs.position.y = size.y * 0.5
	add_child(cs)
	_body = Node3D.new()
	add_child(_body)
	match kind:
		"deer": _build_deer()
		"rabbit": _build_rabbit()
		"crow": _build_crow()
		_: _build_chicken()
	home = global_position
	_target = home
	_wait = randf_range(0.0, 4.0)


func _leg(pos: Vector3, length: float, thick: float, mat: Material) -> void:
	var l := Node3D.new()
	l.position = pos
	_body.add_child(l)
	MeshKit.cyl(l, thick * 0.7, thick, length, Vector3(0, -length * 0.5, 0), mat, Vector3.ZERO, 6)
	_legs.append(l)


func _build_deer() -> void:
	var fur := MeshKit.mat(Color(0.5, 0.33, 0.2), 0.95)
	var light := MeshKit.mat(Color(0.85, 0.78, 0.65), 0.95)
	MeshKit.sphere(_body, 0.35, Vector3(0, 1.0, 0), fur, Vector3(1.0, 0.95, 2.2))
	MeshKit.sphere(_body, 0.2, Vector3(0, 0.95, 0.35), light, Vector3(1.2, 0.8, 1.6))
	MeshKit.cyl(_body, 0.12, 0.17, 0.6, Vector3(0, 1.35, -0.7), fur, Vector3(-35, 0, 0), 8)
	MeshKit.sphere(_body, 0.15, Vector3(0, 1.62, -0.92), fur, Vector3(0.9, 0.9, 1.5))
	MeshKit.sphere(_body, 0.06, Vector3(0, 1.58, -1.12), MeshKit.mat(Color(0.1, 0.08, 0.07)))
	for s in [-1.0, 1.0]:
		MeshKit.sphere(_body, 0.05, Vector3(s * 0.12, 1.75, -0.85), fur, Vector3(0.6, 1.6, 0.4))
		var antler := MeshKit.mat(Color(0.75, 0.68, 0.55))
		MeshKit.cyl(_body, 0.015, 0.025, 0.4, Vector3(s * 0.08, 1.9, -0.88), antler, Vector3(-10, 0, s * -25.0), 5)
		MeshKit.cyl(_body, 0.012, 0.018, 0.2, Vector3(s * 0.15, 2.0, -0.95), antler, Vector3(-40, 0, s * -45.0), 5)
	MeshKit.sphere(_body, 0.07, Vector3(0, 1.1, 0.75), light, Vector3(1, 1, 0.8))
	for z in [-0.45, 0.5]:
		for s in [-1.0, 1.0]:
			_leg(Vector3(s * 0.15, 0.85, z), 0.85, 0.05, fur)


func _build_rabbit() -> void:
	var fur := MeshKit.mat(Color(0.55, 0.47, 0.38), 0.95)
	MeshKit.sphere(_body, 0.13, Vector3(0, 0.15, 0), fur, Vector3(1, 0.9, 1.4))
	MeshKit.sphere(_body, 0.08, Vector3(0, 0.25, -0.15), fur)
	for s in [-1.0, 1.0]:
		MeshKit.sphere(_body, 0.025, Vector3(s * 0.03, 0.38, -0.13), fur, Vector3(0.8, 3.0, 0.6))
	MeshKit.sphere(_body, 0.04, Vector3(0, 0.18, 0.18), MeshKit.mat(Color(0.95, 0.95, 0.92)))


func _build_crow() -> void:
	var black := MeshKit.mat(Color(0.05, 0.05, 0.07), 0.6)
	MeshKit.sphere(_body, 0.08, Vector3(0, 0.15, 0), black, Vector3(1, 0.9, 1.7))
	MeshKit.sphere(_body, 0.055, Vector3(0, 0.22, -0.11), black)
	MeshKit.cyl(_body, 0.0, 0.02, 0.06, Vector3(0, 0.21, -0.17), MeshKit.mat(Color(0.2, 0.2, 0.2)), Vector3(-90, 0, 0), 5)
	MeshKit.box(_body, Vector3(0.08, 0.02, 0.12), Vector3(0, 0.15, 0.16), black, Vector3(15, 0, 0))
	for s in [-1.0, 1.0]:
		var wing := Node3D.new()
		wing.position = Vector3(s * 0.06, 0.18, 0)
		_body.add_child(wing)
		MeshKit.box(wing, Vector3(0.22, 0.015, 0.12), Vector3(s * 0.11, 0, 0), black)
		_legs.append(wing)


func _build_chicken() -> void:
	var white := MeshKit.mat(Color(0.95, 0.93, 0.88), 0.9)
	MeshKit.sphere(_body, 0.15, Vector3(0, 0.28, 0), white, Vector3(1, 1, 1.3))
	MeshKit.sphere(_body, 0.08, Vector3(0, 0.45, -0.14), white)
	MeshKit.box(_body, Vector3(0.03, 0.06, 0.06), Vector3(0, 0.53, -0.14), MeshKit.mat(Color(0.85, 0.12, 0.1)))
	MeshKit.cyl(_body, 0.0, 0.025, 0.05, Vector3(0, 0.44, -0.23), MeshKit.mat(Color(0.95, 0.65, 0.15)), Vector3(-90, 0, 0), 5)
	for s in [-1.0, 1.0]:
		_leg(Vector3(s * 0.05, 0.15, 0), 0.15, 0.015, MeshKit.mat(Color(0.95, 0.65, 0.15)))


var _sleep_t := randf()


func _physics_process(delta: float) -> void:
	if _dead:
		return
	var spec: Dictionary = SPEC[kind]
	var p: Player = world.player
	var dist := global_position.distance_to(p.global_position) if p else 999.0
	# far away animals freeze (checked a few times per second)
	if dist > 70.0:
		_sleep_t -= delta
		return
	if _flee_t <= 0.0:
		_scared_by = Vector3.INF
	if p and dist < float(spec["flee"]) and _flee_t <= 0.0:
		_flee_t = randf_range(3.0, 6.0)
		if kind == "crow":
			_fly_t = 4.0
			Game.play_sound("cr_misc" if Game.sounds.has("cr_misc") else "swing", global_position, -8.0, 1.6)
	if kind == "crow" and _fly_t > 0.0:
		_fly_t -= delta
		var away := (global_position - p.global_position)
		away.y = 0.0
		velocity = away.normalized() * float(spec["run"]) + Vector3(0, 3.5, 0)
		global_position += velocity * delta
		for w in _legs:
			w.rotation.z = sin(Time.get_ticks_msec() * 0.03) * 0.8 * signf(w.position.x)
		if _fly_t <= 0.0:
			queue_free()
		return
	if not is_on_floor():
		velocity.y -= gravity * delta
	var dir := Vector3.ZERO
	var speed := 0.0
	if _flee_t > 0.0:
		_flee_t -= delta
		dir = (global_position - (_scared_by if _scared_by != Vector3.INF else p.global_position))
		dir.y = 0.0
		dir = dir.normalized()
		speed = spec["run"]
	else:
		if _wait > 0.0:
			_wait -= delta
		else:
			var to := _target - global_position
			to.y = 0.0
			if to.length() < 0.5:
				_wait = randf_range(2.0, 7.0)
				_target = home + Vector3(randf_range(-10, 10), 0, randf_range(-10, 10)) * (0.4 if kind == "chicken" else 1.0)
			else:
				dir = to.normalized()
				speed = spec["speed"]
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	if speed > 0.0:
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), minf(1.0, 6.0 * delta))
		_phase += delta * speed * 4.0
		if kind == "rabbit":
			_body.position.y = absf(sin(_phase)) * 0.15
		for i in _legs.size():
			_legs[i].rotation.x = sin(_phase + (PI if i % 2 == 0 else 0.0)) * 0.6
	move_and_slide()
	if is_on_wall():
		_target = home


## Something other than the player startles it (kids chasing chickens).
func scare(from: Vector3) -> void:
	if _dead or kind == "crow":
		return
	_scared_by = from
	_flee_t = randf_range(1.5, 3.0)


func take_damage(amount: float, _pos: Vector3, _dir: Vector3, _kind := "bullet") -> bool:
	if _dead:
		return false
	hp -= amount
	_flee_t = 6.0
	if owned:
		world.report_crime(1, global_position)
	if hp <= 0.0:
		_dead = true
		remove_from_group("damageable")
		collision_layer = 0
		Game.play_sound("creature_die", global_position, -6.0, 1.6)
		Fx.burst(world, global_position + Vector3(0, 0.4, 0), blood_color if kind != "chicken" else Color(0.95, 0.95, 0.9), 14, 2.5, 0.04, 0.6)
		var tw := create_tween()
		tw.tween_property(_body, "rotation:z", PI * 0.5, 0.3)
		tw.tween_interval(30.0)
		tw.tween_callback(queue_free)
		return true
	return false


func apply_burn(_d: float, _t: float) -> void:
	pass
