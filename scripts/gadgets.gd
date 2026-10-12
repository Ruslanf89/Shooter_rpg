class_name Gadgets
extends RefCounted
## The player's crafted tech: frag grenades, landmines, sentry turrets and FPV strike drones.
## Damage grows with the player's level like weapons do.


static func power(base: float) -> float:
	return base * Items.level_mult(int(Game.progress["level"]))


static func throw_grenade(p: Player) -> void:
	var g := Grenade.new()
	g.world = p.world
	var fwd := -p.camera.global_transform.basis.z
	p.world.add_child(g)
	g.global_position = p.camera.global_position + fwd * 0.6
	g.linear_velocity = fwd * 16.0 + Vector3(0, 3.5, 0) + p.velocity * 0.5
	Game.play_sound("swing", null, -4.0, 0.8)


static func place_mine(p: Player) -> void:
	var m := Mine.new()
	m.world = p.world
	p.world.add_child(m)
	var at := p.global_position - p.global_transform.basis.z * 1.2
	m.global_position = Vector3(at.x, p.world.ground(at.x, at.z) + 0.02, at.z)
	Game.play_sound("pickup_tech", m.global_position, -4.0)


static func place_turret(p: Player) -> void:
	var t := Turret.new()
	t.world = p.world
	p.world.add_child(t)
	var at := p.global_position - p.global_transform.basis.z * 2.0
	t.global_position = Vector3(at.x, p.world.ground(at.x, at.z), at.z)
	t.rotation.y = p.rotation.y
	Game.play_sound("pickup_tech", t.global_position, -2.0, 0.8)


static func launch_drone(p: Player) -> void:
	var d := StrikeDrone.new()
	d.world = p.world
	p.world.add_child(d)
	d.global_position = p.global_position + Vector3(0, 1.6, 0) - p.global_transform.basis.z * 0.8
	# target: the monster under the crosshair, else the nearest one in front
	var cam := p.camera
	var fwd := -cam.global_transform.basis.z
	var best: Enemy = null
	var bs := 0.0
	for e in p.get_tree().get_nodes_in_group("enemies"):
		if e.neutral or e.state == Enemy.State.DEAD:
			continue
		var to: Vector3 = e.global_position + Vector3(0, 1.0, 0) - cam.global_position
		var dist := to.length()
		if dist > 90.0:
			continue
		var s := fwd.dot(to / dist) - dist * 0.002
		if s > 0.8 and s > bs:
			bs = s
			best = e
	d.target = best
	d.aim_point = cam.global_position + fwd * 60.0


# --------------------------------------------------------------------------- grenade

class Grenade extends RigidBody3D:
	var world: Node
	var _fuse := 2.0

	func _ready() -> void:
		collision_layer = 0
		collision_mask = 1
		mass = 0.5
		var cs := CollisionShape3D.new()
		var sh := SphereShape3D.new()
		sh.radius = 0.08
		cs.shape = sh
		add_child(cs)
		MeshKit.sphere(self, 0.08, Vector3.ZERO, MeshKit.mat(Color(0.3, 0.35, 0.22), 0.6), Vector3(1, 1.2, 1))
		MeshKit.box(self, Vector3(0.04, 0.05, 0.04), Vector3(0, 0.1, 0), MeshKit.mat(Color(0.5, 0.5, 0.5), 0.4, 0.8))
		angular_velocity = Vector3(randf_range(-8, 8), randf_range(-8, 8), randf_range(-8, 8))

	func _physics_process(delta: float) -> void:
		_fuse -= delta
		if _fuse <= 0.0:
			Explosion.spawn(world, global_position + Vector3(0, 0.2, 0), 5.0, Gadgets.power(130.0), "player")
			queue_free()


# --------------------------------------------------------------------------- landmine

class Mine extends Node3D:
	var world: Node
	var _arm := 1.5
	var _blink := 0.0
	var _led: MeshInstance3D

	func _ready() -> void:
		MeshKit.cyl(self, 0.18, 0.2, 0.06, Vector3(0, 0.03, 0), MeshKit.mat(Color(0.32, 0.33, 0.25), 0.7, 0.3), Vector3.ZERO, 14)
		MeshKit.cyl(self, 0.05, 0.05, 0.03, Vector3(0, 0.075, 0), MeshKit.mat(Color(0.2, 0.2, 0.2), 0.5, 0.6), Vector3.ZERO, 8)
		_led = MeshKit.sphere(self, 0.015, Vector3(0.1, 0.07, 0), MeshKit.mat(Color(1.0, 0.1, 0.05), 0.5, 0.0, 4.0))
		var life := create_tween()
		life.tween_interval(300.0)
		life.tween_callback(queue_free)

	func _process(delta: float) -> void:
		_arm -= delta
		_blink += delta
		_led.visible = fmod(_blink, 1.0) < 0.15
		if _arm > 0.0:
			return
		for e in get_tree().get_nodes_in_group("enemies"):
			if not e.neutral and e.state != Enemy.State.DEAD and e.global_position.distance_to(global_position) < 2.2:
				Explosion.spawn(world, global_position + Vector3(0, 0.3, 0), 4.5, Gadgets.power(170.0), "player")
				queue_free()
				return


# --------------------------------------------------------------------------- sentry turret

class Turret extends Node3D:
	var world: Node
	var _head: Node3D
	var _life := 40.0
	var _cd := 0.0
	var _flash: OmniLight3D

	func _ready() -> void:
		var metal := MeshKit.mat(Color(0.35, 0.38, 0.32), 0.5, 0.6)
		var dark := MeshKit.mat(Color(0.12, 0.12, 0.13), 0.5, 0.7)
		for i in 3:
			var a := TAU * i / 3.0
			MeshKit.cyl(self, 0.025, 0.025, 0.9, Vector3(cos(a) * 0.25, 0.35, sin(a) * 0.25), dark, Vector3(-cos(a) * 25.0, 0, sin(a) * 25.0), 6)
		_head = Node3D.new()
		_head.position.y = 0.8
		add_child(_head)
		MeshKit.box(_head, Vector3(0.3, 0.22, 0.45), Vector3.ZERO, metal)
		MeshKit.cyl(_head, 0.025, 0.025, 0.6, Vector3(0, 0.02, -0.5), dark, Vector3(90, 0, 0), 8)
		MeshKit.box(_head, Vector3(0.16, 0.18, 0.2), Vector3(0.22, -0.04, 0.05), MeshKit.mat(Color(0.6, 0.5, 0.2), 0.5, 0.4))
		MeshKit.sphere(_head, 0.025, Vector3(0, 0.13, 0.1), MeshKit.mat(Color(0.2, 1.0, 0.3), 0.5, 0.0, 3.0))
		_flash = OmniLight3D.new()
		_flash.light_color = Color(1.0, 0.75, 0.35)
		_flash.light_energy = 0.0
		_flash.omni_range = 4.0
		_flash.position = Vector3(0, 0.02, -0.85)
		_head.add_child(_flash)

	func _process(delta: float) -> void:
		_life -= delta
		_flash.light_energy = maxf(0.0, _flash.light_energy - delta * 30.0)
		if _life <= 0.0:
			Fx.burst(world, global_position + Vector3(0, 0.8, 0), Color(0.6, 0.6, 0.6), 12, 2.0, 0.04, 0.5)
			queue_free()
			return
		var best: Enemy = null
		var bd := 28.0
		for e in get_tree().get_nodes_in_group("enemies"):
			if e.neutral or e.state == Enemy.State.DEAD:
				continue
			var d: float = e.global_position.distance_to(global_position)
			if d < bd:
				bd = d
				best = e
		if best == null:
			_head.rotation.y += delta * 0.6
			return
		var aim := best.global_position + Vector3(0, 1.0, 0)
		var to := aim - _head.global_position
		_head.rotation.y = lerp_angle(_head.rotation.y, atan2(-to.x, -to.z) - rotation.y, minf(1.0, 10.0 * delta))
		_cd -= delta
		if _cd <= 0.0:
			_cd = 0.22
			_flash.light_energy = 3.0
			Game.play_sound("shot", _head.global_position, -8.0, 1.3)
			var from := _head.global_transform * Vector3(0, 0.02, -0.85)
			var q := PhysicsRayQueryParameters3D.create(from, aim, 1)
			if world.get_world_3d().direct_space_state.intersect_ray(q).is_empty():
				best.take_damage(Gadgets.power(11.0), aim, to.normalized(), "bullet")
				Fx.burst(world, aim, best.blood_color, 5, 2.0, 0.03, 0.3)


# --------------------------------------------------------------------------- FPV strike drone

class StrikeDrone extends Node3D:
	var world: Node
	var target: Enemy
	var aim_point := Vector3.ZERO
	var _model: Node3D
	var _rotors: Array = []
	var _t := 0.0
	var _vel := Vector3.ZERO

	func _ready() -> void:
		_model = TechProps.drone_model(self)
		_model.scale = Vector3.ONE * 1.8
		_rotors = _model.get_meta("rotors")
		TechProps.loop_sound(self, "drone_buzz", 0.0, 50.0)
		_vel = Vector3(0, 4.0, 0)

	func _process(delta: float) -> void:
		_t += delta
		for r in _rotors:
			(r as Node3D).rotation.y += delta * 90.0
		var goal := aim_point
		if target and is_instance_valid(target) and target.state != Enemy.State.DEAD:
			goal = target.global_position + Vector3(0, 1.0, 0)
		# climb a little first, then dive in
		if _t < 0.6:
			goal = global_position + Vector3(0, 3.0, 0) + (goal - global_position).normalized() * 2.0
		var want := (goal - global_position).normalized() * (18.0 if _t > 0.6 else 8.0)
		_vel = _vel.lerp(want, minf(1.0, 4.0 * delta))
		global_position += _vel * delta
		if _vel.length() > 0.5:
			look_at(global_position + _vel, Vector3.UP)
		var hit := global_position.distance_to(goal) < 1.2 and _t > 0.6
		var ground_y: float = world.ground(global_position.x, global_position.z)
		if hit or global_position.y < ground_y + 0.2 or _t > 8.0:
			Explosion.spawn(world, global_position, 5.5, Gadgets.power(240.0), "player")
			queue_free()
