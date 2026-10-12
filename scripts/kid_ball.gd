class_name KidBall
extends RigidBody3D
## Leather ball the village kids kick around the square. The player can kick it too by running
## into it. Bullets pass through it (layer 32); it goes back to the square if it rolls away.

var home := Vector3.ZERO
var world: Node


func _ready() -> void:
	add_to_group("kid_balls")
	collision_layer = 32
	collision_mask = 1
	mass = 0.45
	linear_damp = 0.6
	angular_damp = 0.8
	var pm := PhysicsMaterial.new()
	pm.bounce = 0.55
	pm.friction = 0.7
	physics_material_override = pm
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 0.12
	cs.shape = sh
	add_child(cs)
	var leather := MeshKit.mat(Color(0.55, 0.33, 0.18), 0.75)
	MeshKit.sphere(self, 0.12, Vector3.ZERO, leather)
	var seam := MeshKit.mat(Color(0.3, 0.18, 0.1), 0.9)
	MeshKit.cyl(self, 0.122, 0.122, 0.012, Vector3.ZERO, seam, Vector3.ZERO, 16)
	MeshKit.cyl(self, 0.122, 0.122, 0.012, Vector3.ZERO, seam, Vector3(90, 0, 0), 16)


## A kick towards `target` (kids aim at each other).
func kick(from: Vector3, target: Vector3, power := 3.5) -> void:
	var dir := target - global_position
	dir.y = 0.0
	if dir.length() < 0.1:
		dir = global_position - from
		dir.y = 0.0
	dir = dir.normalized()
	sleeping = false
	linear_velocity = Vector3.ZERO
	apply_central_impulse((dir * power + Vector3(0, power * 0.35, 0)) * mass)
	Game.play_sound("hit", global_position, -14.0, 0.45)


func _physics_process(_delta: float) -> void:
	if world == null:
		return
	if global_position.distance_to(home) > 26.0 or global_position.y < home.y - 10.0:
		global_position = home + Vector3(0, 0.5, 0)
		linear_velocity = Vector3.ZERO
	var p: Player = world.player
	if p and not p.dead:
		var to := global_position - p.global_position
		to.y = 0.0
		var pv := Vector2(p.velocity.x, p.velocity.z).length()
		if to.length() < 0.75 and pv > 1.0 and linear_velocity.length() < 2.0:
			kick(p.global_position, global_position + to * 10.0, 2.0 + pv * 0.6)
