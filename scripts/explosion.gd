class_name Explosion
extends Node3D
## Realistic-looking explosion: flash, fireball, smoke column, sparks, debris, shockwave,
## scorch mark, sound and screen shake. Also deals area damage.

static var _soft_tex: GradientTexture2D
static var _scorch_tex: GradientTexture2D
static var _fire_mat: StandardMaterial3D
static var _smoke_mat: StandardMaterial3D

var radius := 4.0
var _life := 0.0


static func _soft() -> GradientTexture2D:
	if _soft_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.45, Color(1, 1, 1, 0.75))
		_soft_tex = GradientTexture2D.new()
		_soft_tex.gradient = g
		_soft_tex.fill = GradientTexture2D.FILL_RADIAL
		_soft_tex.fill_from = Vector2(0.5, 0.5)
		_soft_tex.fill_to = Vector2(0.5, 0.0)
		_soft_tex.width = 64
		_soft_tex.height = 64
	return _soft_tex


static func _particle_mat(additive: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = _soft()
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if additive:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	return m


static func _ramp(colors: Array, offsets: Array) -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(offsets)
	g.colors = PackedColorArray(colors)
	return g


static func _curve(points: Array) -> Curve:
	var c := Curve.new()
	for p: Vector2 in points:
		c.add_point(p)
	return c


## Spawns an explosion. source: "player" (hurts enemies), "enemy" (hurts player),
## "barrel" (hurts everyone). Returns the node.
static func spawn(world: Node, pos: Vector3, blast_radius: float, damage: float, source: String, fire_color := Color(1.0, 0.55, 0.15)) -> Explosion:
	var e := Explosion.new()
	e.radius = blast_radius
	world.add_child(e)
	e.global_position = pos
	e._build(world, fire_color)
	e._apply_damage(world, damage, source)
	return e


func _build(world: Node, fire_color: Color) -> void:
	var r := radius
	if _fire_mat == null:
		_fire_mat = _particle_mat(false)
		_smoke_mat = _particle_mat(false)
	# bright additive core on top of the solid fireball
	var core := CPUParticles3D.new()
	var cq := QuadMesh.new()
	cq.size = Vector2.ONE
	core.mesh = cq
	core.material_override = _particle_mat(true)
	core.amount = 8
	core.lifetime = 0.35
	core.one_shot = true
	core.explosiveness = 1.0
	core.spread = 180.0
	core.initial_velocity_min = r * 0.5
	core.initial_velocity_max = r * 1.2
	core.gravity = Vector3.ZERO
	core.scale_amount_min = r * 0.9
	core.scale_amount_max = r * 1.5
	core.color_ramp = _ramp([Color(1, 0.95, 0.75, 1), Color(1, 0.6, 0.2, 0.6), Color(1, 0.3, 0.05, 0)], [0.0, 0.4, 1.0])
	core.position.y = 0.6
	add_child(core)
	core.emitting = true
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE

	# flash
	var light := OmniLight3D.new()
	light.light_color = fire_color.lerp(Color(1, 0.9, 0.7), 0.4)
	light.light_energy = 14.0
	light.omni_range = r * 5.0
	light.position.y = 1.0
	add_child(light)
	var tw := light.create_tween()
	tw.tween_property(light, "light_energy", 0.0, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)

	# fireball
	var fire := CPUParticles3D.new()
	fire.mesh = quad
	fire.material_override = _fire_mat
	fire.amount = int(18 + r * 6)
	fire.lifetime = 0.7
	fire.one_shot = true
	fire.explosiveness = 0.95
	fire.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	fire.emission_sphere_radius = r * 0.25
	fire.direction = Vector3.UP
	fire.spread = 180.0
	fire.initial_velocity_min = r * 1.2
	fire.initial_velocity_max = r * 2.6
	fire.damping_min = r * 2.0
	fire.damping_max = r * 3.0
	fire.gravity = Vector3(0, 2.0, 0)
	fire.scale_amount_min = r * 0.7
	fire.scale_amount_max = r * 1.3
	fire.scale_amount_curve = _curve([Vector2(0, 0.3), Vector2(0.25, 1.0), Vector2(1, 1.3)])
	fire.color_ramp = _ramp([Color(1, 0.85, 0.45, 1), fire_color.lerp(Color(1, 0.7, 0.2), 0.4), fire_color.darkened(0.15), Color(0.35, 0.12, 0.05, 0.85), Color(0.12, 0.08, 0.06, 0)], [0.0, 0.15, 0.4, 0.7, 1.0])
	fire.position.y = 0.6
	add_child(fire)
	fire.emitting = true

	# smoke column
	var smoke := CPUParticles3D.new()
	smoke.mesh = quad
	smoke.material_override = _smoke_mat
	smoke.amount = int(14 + r * 4)
	smoke.lifetime = 3.5
	smoke.one_shot = true
	smoke.explosiveness = 0.8
	smoke.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	smoke.emission_sphere_radius = r * 0.3
	smoke.direction = Vector3.UP
	smoke.spread = 60.0
	smoke.initial_velocity_min = r * 0.4
	smoke.initial_velocity_max = r * 1.0
	smoke.damping_min = 0.6
	smoke.damping_max = 1.2
	smoke.gravity = Vector3(0.3, 0.9, 0)
	smoke.scale_amount_min = r * 0.8
	smoke.scale_amount_max = r * 1.4
	smoke.scale_amount_curve = _curve([Vector2(0, 0.4), Vector2(1, 2.2)])
	smoke.color_ramp = _ramp([Color(0.25, 0.22, 0.2, 0), Color(0.22, 0.2, 0.18, 0.75), Color(0.35, 0.33, 0.32, 0.45), Color(0.45, 0.45, 0.45, 0)], [0.0, 0.15, 0.6, 1.0])
	smoke.position.y = 0.8
	add_child(smoke)
	smoke.emitting = true

	# sparks
	var sparks := CPUParticles3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.03, 0.03, 0.25)
	sm.material = MeshKit.unshaded(Color(1.0, 0.75, 0.35))
	sparks.mesh = sm
	sparks.amount = int(20 + r * 6)
	sparks.lifetime = 1.2
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.direction = Vector3.UP
	sparks.spread = 80.0
	sparks.initial_velocity_min = r * 3.0
	sparks.initial_velocity_max = r * 6.0
	sparks.gravity = Vector3(0, -9.8, 0)
	sparks.particle_flag_align_y = true
	sparks.position.y = 0.5
	add_child(sparks)
	sparks.emitting = true

	# debris chunks
	var debris := CPUParticles3D.new()
	var dm := BoxMesh.new()
	dm.size = Vector3(0.12, 0.1, 0.14)
	dm.material = MeshKit.mat(Color(0.2, 0.16, 0.12))
	debris.mesh = dm
	debris.amount = int(10 + r * 3)
	debris.lifetime = 1.6
	debris.one_shot = true
	debris.explosiveness = 1.0
	debris.direction = Vector3.UP
	debris.spread = 50.0
	debris.initial_velocity_min = r * 1.5
	debris.initial_velocity_max = r * 3.5
	debris.gravity = Vector3(0, -12.0, 0)
	debris.angular_velocity_min = -400.0
	debris.angular_velocity_max = 400.0
	debris.scale_amount_min = 0.6
	debris.scale_amount_max = 1.8
	debris.position.y = 0.3
	add_child(debris)
	debris.emitting = true

	# shockwave ring
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.93
	tm.outer_radius = 1.0
	tm.rings = 32
	tm.ring_segments = 6
	ring.mesh = tm
	var rm := StandardMaterial3D.new()
	rm.albedo_color = Color(1.0, 0.8, 0.55, 0.22)
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	ring.material_override = rm
	ring.scale = Vector3(0.3, 0.05, 0.3)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)
	# the shockwave runs along the ground even when the blast is in the air
	ring.global_position.y = world.ground(global_position.x, global_position.z) + 0.15
	var rt := ring.create_tween().set_parallel(true)
	rt.tween_property(ring, "scale", Vector3(r * 1.6, 0.05, r * 1.6), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	rt.tween_property(rm, "albedo_color:a", 0.0, 0.45)

	# scorch mark
	if _scorch_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(0.02, 0.02, 0.02, 0.9))
		g.set_color(1, Color(0.05, 0.04, 0.03, 0.0))
		g.add_point(0.6, Color(0.05, 0.04, 0.03, 0.6))
		_scorch_tex = GradientTexture2D.new()
		_scorch_tex.gradient = g
		_scorch_tex.fill = GradientTexture2D.FILL_RADIAL
		_scorch_tex.fill_from = Vector2(0.5, 0.5)
		_scorch_tex.fill_to = Vector2(0.5, 0.0)
	var decal := Decal.new()
	decal.texture_albedo = _scorch_tex
	decal.size = Vector3(r * 1.6, 3.0, r * 1.6)
	decal.cull_mask = 1
	world.add_child(decal)
	decal.global_position = global_position
	var dt := decal.create_tween()
	dt.tween_interval(14.0)
	dt.tween_property(decal, "modulate:a", 0.0, 4.0)
	dt.tween_callback(decal.queue_free)

	Game.play_sound("explosion", global_position, clampf(r * 2.0, 2.0, 12.0), 1.15 - minf(r, 7.0) * 0.06)
	var player: Player = world.player
	if player:
		var d := player.global_position.distance_to(global_position)
		player.shake(clampf((r * 4.0 - d) / (r * 4.0), 0.0, 1.0) * 0.6)


func _apply_damage(world: Node, damage: float, source: String) -> void:
	if damage <= 0.0:
		return
	if source != "enemy":
		for node in get_tree().get_nodes_in_group("damageable"):
			var e: Node3D = node
			var d := e.global_position.distance_to(global_position)
			if d <= radius + 0.5:
				var fall := 1.0 - clampf(d / (radius + 0.5), 0.0, 1.0) * 0.6
				var killed: bool = e.take_damage(damage * fall, e.global_position + Vector3(0, 1.2, 0), (e.global_position - global_position).normalized(), "fire")
				if not killed and source == "player" and e.has_method("apply_burn"):
					e.apply_burn(damage * 0.08, 4.0)
		for b in get_tree().get_nodes_in_group("barrels"):
			if b.global_position.distance_to(global_position) <= radius + 1.0:
				b.call_deferred("ignite")
	if source != "player":
		var p: Player = world.player
		if p and p.global_position.distance_to(global_position) <= radius:
			var fall := 1.0 - clampf(p.global_position.distance_to(global_position) / radius, 0.0, 1.0) * 0.6
			p.take_damage(damage * fall * (0.5 if source == "barrel" else 1.0), global_position)


func _process(delta: float) -> void:
	_life += delta
	if _life > 4.0:
		queue_free()
