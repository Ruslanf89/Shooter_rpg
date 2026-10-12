class_name FrostBolt
extends Node3D
## Player spell projectile. kind "frost": Frost Arrow (freeze + frost DoT).
## kind "fire": Fireball (explodes, burns).

var kind := "frost"
var damage := 28.0
var freeze_time := 3.0
var dot_dps := 7.0
var dot_time := 6.0
var blast_radius := 4.0
var direction := Vector3.FORWARD
var world: Node
var _speed := 45.0
var _life := 2.0


func _ready() -> void:
	var fire := kind == "fire"
	_speed = 32.0 if fire else 45.0
	var core := Color(1.0, 0.85, 0.5) if fire else Color(0.85, 0.95, 1.0)
	var glow := Color(1.0, 0.45, 0.1, 0.7) if fire else Color(0.4, 0.75, 1.0, 0.6)
	var shard := Node3D.new()
	add_child(shard)
	if fire:
		MeshKit.sphere(shard, 0.18, Vector3.ZERO, MeshKit.unshaded(core))
		MeshKit.sphere(shard, 0.38, Vector3.ZERO, MeshKit.glow(glow), Vector3(1, 1, 1.6))
	else:
		MeshKit.cyl(shard, 0.0, 0.07, 0.8, Vector3(0, 0, -0.1), MeshKit.unshaded(core), Vector3(-90, 0, 0), 6)
		MeshKit.sphere(shard, 0.16, Vector3(0, 0, 0.15), MeshKit.glow(glow), Vector3(1, 1, 3))
	var light := OmniLight3D.new()
	light.light_color = glow
	light.light_energy = 3.0 if fire else 2.0
	light.omni_range = 6.0
	add_child(light)
	var trail := CPUParticles3D.new()
	var tm := SphereMesh.new()
	tm.radius = 0.12 if fire else 0.06
	tm.height = tm.radius * 2.0
	tm.radial_segments = 6
	tm.rings = 3
	tm.material = MeshKit.glow(glow)
	trail.mesh = tm
	trail.amount = 60 if fire else 50
	trail.lifetime = 0.5 if fire else 0.4
	trail.local_coords = false
	trail.gravity = Vector3(0, 1.5, 0) if fire else Vector3(0, -1.0, 0)
	trail.spread = 180.0
	trail.initial_velocity_min = 0.2
	trail.initial_velocity_max = 1.0
	trail.scale_amount_min = 0.5
	trail.scale_amount_max = 1.4
	add_child(trail)
	trail.emitting = true


## Call after add_child.
func launch(from: Vector3, dir: Vector3) -> void:
	direction = dir.normalized()
	global_position = from
	look_at(from + direction, Vector3.UP if absf(direction.y) < 0.99 else Vector3.FORWARD)


func _physics_process(delta: float) -> void:
	var step := direction * _speed * delta
	var q := PhysicsRayQueryParameters3D.create(global_position, global_position + step, 1 | 4)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		_impact(hit["position"], hit["collider"])
		return
	global_position += step
	_life -= delta
	if _life <= 0.0:
		if kind == "fire":
			_impact(global_position, null)
		else:
			queue_free()


func _impact(pos: Vector3, collider: Object) -> void:
	var enemy := collider as Enemy
	if kind == "fire":
		if collider and collider.has_method("ignite"):
			collider.ignite()
		Explosion.spawn(world, pos, blast_radius, damage, "player")
		if enemy:
			world.hud.hit_marker(false, false)
			world.shots_hit += 1
		queue_free()
		return
	if enemy:
		var killed := enemy.take_damage(damage * randf_range(0.9, 1.1), pos, direction, "frost")
		if not killed:
			enemy.apply_frost(freeze_time, dot_dps, dot_time)
		world.hud.hit_marker(killed, false)
		world.shots_hit += 1
	Fx.burst(world, pos, Color(0.75, 0.92, 1.0), 22, 5.0, 0.05, 0.6, 4.0)
	Fx.light_flash(world, pos, Color(0.5, 0.8, 1.0), 4.0, 7.0, 0.35)
	Game.play_sound("frost_hit", pos, -2.0)
	queue_free()
