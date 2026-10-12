class_name Projectile
extends Node3D
## Physical player projectiles: crossbow bolts (fast, slight drop, stick into what they hit)
## and grenades (arc, bounce once, explode).

var kind := "bolt"
var damage := 100.0
var world: Node
var velocity := Vector3.ZERO
var _life := 6.0
var _bounced := false
var _mesh: Node3D


func _ready() -> void:
	_mesh = Node3D.new()
	add_child(_mesh)
	if kind == "bolt":
		var wood := MeshKit.mat(Color(0.45, 0.3, 0.18))
		MeshKit.cyl(_mesh, 0.008, 0.008, 0.5, Vector3.ZERO, wood, Vector3(90, 0, 0), 6)
		MeshKit.cyl(_mesh, 0.0, 0.016, 0.06, Vector3(0, 0, -0.28), MeshKit.mat(Color(0.6, 0.6, 0.62), 0.3, 0.9), Vector3(-90, 0, 0), 6)
		for s in [-1.0, 1.0]:
			MeshKit.box(_mesh, Vector3(0.003, 0.03, 0.07), Vector3(s * 0.01, 0.01, 0.22), MeshKit.mat(Color(0.8, 0.15, 0.1)))
	else:
		MeshKit.sphere(_mesh, 0.05, Vector3.ZERO, MeshKit.mat(Color(0.25, 0.3, 0.2), 0.6, 0.3), Vector3(1, 1, 1.4))
		MeshKit.cyl(_mesh, 0.02, 0.02, 0.03, Vector3(0, 0, -0.065), MeshKit.mat(Color(0.8, 0.65, 0.2), 0.3, 0.9), Vector3(90, 0, 0), 8)


func launch(from: Vector3, dir: Vector3) -> void:
	global_position = from
	velocity = dir * (80.0 if kind == "bolt" else 32.0) + (Vector3.UP * 3.0 if kind == "grenade" else Vector3.ZERO)
	_orient()


func _orient() -> void:
	if velocity.length() > 0.1:
		var up := Vector3.UP if absf(velocity.normalized().y) < 0.98 else Vector3.FORWARD
		look_at(global_position + velocity, up)


func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		if kind == "grenade":
			_explode(global_position)
		queue_free()
		return
	velocity.y -= (3.0 if kind == "bolt" else 14.0) * delta
	var from := global_position
	var to := from + velocity * delta
	var q := PhysicsRayQueryParameters3D.create(from, to, 1 | 4 | 16)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		global_position = to
		_orient()
		return
	var col: Object = hit["collider"]
	var pos: Vector3 = hit["position"]
	if kind == "grenade":
		if col and col.has_method("take_damage") or _bounced:
			_explode(pos)
			queue_free()
			return
		# bounce once off the ground / walls
		_bounced = true
		var n: Vector3 = hit["normal"]
		velocity = velocity.bounce(n) * 0.45
		global_position = pos + n * 0.08
		Game.play_sound("impact_stone", pos, -8.0, 0.7)
		return
	# bolt
	if col and col.has_method("take_damage") and not col is Player:
		var headshot: bool = col.has_method("is_head_hit") and col.is_head_hit(pos)
		var p: Player = world.player
		var dmg := damage * (2.5 if headshot else 1.0) * p.crit_roll()
		var killed: bool = col.take_damage(dmg, pos, velocity.normalized(), "crit" if headshot else "bullet")
		world.hud.hit_marker(killed, headshot)
		Game.play_sound("flesh", pos, -2.0)
		Fx.burst(world, pos, Color(0.6, 0.05, 0.05), 14, 3.0, 0.035, 0.5)
		queue_free()
		return
	Game.play_sound("impact_wood", pos, -4.0, 1.3)
	global_position = pos - velocity.normalized() * 0.2
	set_physics_process(false)
	var tw := create_tween()
	tw.tween_interval(8.0)
	tw.tween_callback(queue_free)


func _explode(pos: Vector3) -> void:
	Explosion.spawn(world, pos, 5.0, damage, "player")
