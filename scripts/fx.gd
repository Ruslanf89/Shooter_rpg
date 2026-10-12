class_name Fx
extends RefCounted
## One-shot visual effects: particle bursts and light flashes.

static var _meshes: Dictionary = {}


static func _particle_mesh(color: Color, size: float) -> Mesh:
	var key := "%s|%.3f" % [color.to_html(), size]
	if _meshes.has(key):
		return _meshes[key]
	var m := SphereMesh.new()
	m.radius = size
	m.height = size * 2.0
	m.radial_segments = 6
	m.rings = 3
	m.material = MeshKit.unshaded(color)
	_meshes[key] = m
	return m


static func burst(parent: Node, pos: Vector3, color: Color, amount := 12, speed := 3.0, size := 0.05, life := 0.5, gravity := 9.8) -> void:
	var p := CPUParticles3D.new()
	p.mesh = _particle_mesh(color, size)
	p.amount = amount
	p.lifetime = life
	p.one_shot = true
	p.explosiveness = 1.0
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, -gravity, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.2
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)


static func light_flash(parent: Node, pos: Vector3, color: Color, energy := 3.0, light_range := 6.0, duration := 0.3) -> void:
	var l := OmniLight3D.new()
	l.light_color = color
	l.light_energy = energy
	l.omni_range = light_range
	parent.add_child(l)
	l.global_position = pos
	var tw := l.create_tween()
	tw.tween_property(l, "light_energy", 0.0, duration)
	tw.tween_callback(l.queue_free)


## Short-lived cone of flame particles (flamethrower).
static func flame_spray(parent: Node, pos: Vector3, dir: Vector3) -> void:
	var p := CPUParticles3D.new()
	p.mesh = _particle_mesh(Color(1.0, 0.55, 0.15), 0.12)
	p.amount = 14
	p.lifetime = 0.45
	p.one_shot = true
	p.explosiveness = 0.9
	p.direction = dir
	p.spread = 9.0
	p.initial_velocity_min = 14.0
	p.initial_velocity_max = 20.0
	p.gravity = Vector3(0, 2.0, 0)
	p.damping_min = 8.0
	p.damping_max = 14.0
	p.scale_amount_min = 0.6
	p.scale_amount_max = 2.4
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	g.colors = PackedColorArray([Color(1.0, 0.9, 0.5), Color(1.0, 0.45, 0.1), Color(0.25, 0.2, 0.2, 0.0)])
	p.color_ramp = g
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1, 1, 1, 0.55)
	m.vertex_color_use_as_albedo = true
	var mesh: SphereMesh = p.mesh.duplicate()
	mesh.material = m
	p.mesh = mesh
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)