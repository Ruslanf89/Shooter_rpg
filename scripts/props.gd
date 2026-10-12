class_name Props
extends RefCounted
## Reusable buildings and props. Every function takes the world (for ground height and
## registries) and a world-space position; y is snapped to the ground.

static func wood() -> Material:
	return MeshKit.textured("Planks021", Color(1.05, 0.78, 0.52), 0.7, 0.55, 0.95)


static func dark_wood() -> Material:
	return MeshKit.textured("Planks021", Color(0.62, 0.45, 0.32), 0.7, 0.55, 0.9)


static func stone(tint := Color(1.1, 1.03, 0.9), scale := 0.32) -> Material:
	# cut-stone blocks; level tints are softened so buildings keep a natural colour
	return MeshKit.textured("Bricks066", Color(1, 1, 1).lerp(tint, 0.6) * Color(1.05, 1.0, 0.92), scale * 0.9, 0.0, 0.95)


static func roof(tint: Color) -> Material:
	return MeshKit.textured("RoofingTiles014A", Color(1, 1, 1).lerp(tint, 0.3), 0.45, 0.4, 0.9)


static func rock_mat(tint := Color(1.3, 1.2, 1.05)) -> Material:
	return MeshKit.textured("Rock030", tint, 0.35, 0.3)


static func ground_at(w: Node3D, p: Vector3) -> Vector3:
	return Vector3(p.x, w.ground(p.x, p.z) + p.y, p.z)


static func pivot(w: Node3D, p: Vector3, yaw_deg := 0.0) -> Node3D:
	var n := Node3D.new()
	w.add_child(n)
	n.position = ground_at(w, p)
	n.rotation_degrees.y = yaw_deg
	return n


static func house(w: Node3D, p: Vector3, yaw_deg: float, size: Vector3, roof_tint: Color, wall := Color(0.93, 0.89, 0.8)) -> Node3D:
	return Buildings.house(w, p, yaw_deg, size, roof_tint, wall)


static func fence(w: Node3D, a: Vector3, b: Vector3, mat: Material = null) -> void:
	var m := mat if mat else wood()
	var d := b - a
	var length := Vector2(d.x, d.z).length()
	var n := pivot(w, (a + b) * 0.5, rad_to_deg(atan2(d.x, d.z)))
	var count := maxi(1, int(length / 2.5))
	for i in count + 1:
		var z := -length * 0.5 + i * length / count
		var gp := ground_at(w, n.global_transform * Vector3(0, 0, z)) - n.position
		MeshKit.box(n, Vector3(0.18, 1.3, 0.18), Vector3(0, gp.y + 0.6, z), m)
	MeshKit.box(n, Vector3(0.08, 0.12, length), Vector3(0, 1.0, 0), m)
	MeshKit.box(n, Vector3(0.08, 0.12, length), Vector3(0, 0.55, 0), m)
	MeshKit.collider_box(n, Vector3(0.3, 1.4, length), Vector3(0, 0.7, 0))


static func iron_fence(w: Node3D, a: Vector3, b: Vector3) -> void:
	var iron := MeshKit.mat(Color(0.12, 0.12, 0.13), 0.5, 0.6)
	var d := b - a
	var length := Vector2(d.x, d.z).length()
	var n := pivot(w, (a + b) * 0.5, rad_to_deg(atan2(d.x, d.z)))
	var count := int(length / 0.35)
	for i in count + 1:
		var z := -length * 0.5 + i * length / count
		MeshKit.box(n, Vector3(0.05, 1.6, 0.05), Vector3(0, 0.8, z), iron)
		MeshKit.cyl(n, 0.0, 0.05, 0.15, Vector3(0, 1.67, z), iron, Vector3.ZERO, 4)
	MeshKit.box(n, Vector3(0.06, 0.06, length), Vector3(0, 1.4, 0), iron)
	MeshKit.box(n, Vector3(0.06, 0.06, length), Vector3(0, 0.3, 0), iron)
	MeshKit.collider_box(n, Vector3(0.2, 1.7, length), Vector3(0, 0.85, 0))


static func lantern(w: Node3D, p: Vector3) -> void:
	var n := pivot(w, p)
	MeshKit.static_box(n, Vector3(0.16, 2.6, 0.16), Vector3(0, 1.3, 0), dark_wood())
	var lamp_at := Vector3(0.45, 2.2, 0)
	if PropKit.enabled():
		# the kit's iron wall lantern hung on the post (its bracket points along +z: turn it to +x)
		PropKit.put(n, "Lantern_Wall", Vector3(0.08, 1.3, 0), 90.0)
		lamp_at = Vector3(0.9, 1.75, 0)
	else:
		MeshKit.box(n, Vector3(0.6, 0.1, 0.1), Vector3(0.25, 2.55, 0), dark_wood())
		MeshKit.box(n, Vector3(0.3, 0.38, 0.3), Vector3(0.45, 2.3, 0), MeshKit.mat(Color(1.0, 0.8, 0.45), 0.5, 0.0, 2.5))
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.78, 0.45)
	l.light_energy = 1.4
	l.omni_range = 9.0
	l.position = lamp_at
	Buildings.fade(l, 70.0)
	n.add_child(l)
	w.flicker_lights.append([l, l.light_energy])


static func torch(w: Node3D, p: Vector3, color := Color(1.0, 0.6, 0.25)) -> void:
	var n := pivot(w, p)
	MeshKit.static_box(n, Vector3(0.14, 2.2, 0.14), Vector3(0, 1.1, 0), dark_wood())
	MeshKit.cyl(n, 0.0, 0.16, 0.45, Vector3(0, 2.4, 0), MeshKit.unshaded(color), Vector3.ZERO, 6)
	MeshKit.cyl(n, 0.0, 0.08, 0.3, Vector3(0, 2.35, 0), MeshKit.unshaded(Color(1, 0.95, 0.6)), Vector3.ZERO, 6)
	var l := OmniLight3D.new()
	l.light_color = color
	l.omni_range = 9.0
	l.position = Vector3(0, 2.5, 0)
	n.add_child(l)
	w.fire_lights.append(l)


static func crate(w: Node3D, p: Vector3, yaw := 0.0) -> void:
	var n := pivot(w, p, yaw)
	if PropKit.enabled():
		PropKit.put(n, "Crate_Wooden" if int(absf(p.x * 3.0 + p.z * 7.0)) % 4 != 0 else "Crate_Metal", Vector3.ZERO, 0.0, Vector3.ONE * 1.02, true)
		return
	MeshKit.static_box(n, Vector3(0.9, 0.9, 0.9), Vector3(0, 0.45, 0), MeshKit.textured("WoodSiding008", Color(1.25, 1.05, 0.85), 1.1))
	MeshKit.box(n, Vector3(0.95, 0.12, 0.95), Vector3(0, 0.84, 0), dark_wood())
	MeshKit.box(n, Vector3(0.95, 0.12, 0.95), Vector3(0, 0.06, 0), dark_wood())


static func barrel(w: Node3D, p: Vector3) -> void:
	var n := pivot(w, p)
	if PropKit.enabled():
		var apples := int(absf(p.x * 5.0 + p.z * 3.0)) % 5 == 0
		PropKit.put(n, "Barrel_Apples" if apples else "Barrel", Vector3.ZERO, absf(p.x * 37.0) , Vector3.ONE * 1.12, true)
		return
	MeshKit.static_cyl(n, 0.42, 1.0, Vector3(0, 0.5, 0), MeshKit.mat(Color(0.48, 0.3, 0.15)))
	var band := MeshKit.mat(Color(0.3, 0.3, 0.32), 0.5, 0.6)
	MeshKit.cyl(n, 0.44, 0.44, 0.06, Vector3(0, 0.8, 0), band)
	MeshKit.cyl(n, 0.44, 0.44, 0.06, Vector3(0, 0.2, 0), band)


static func campfire(w: Node3D, p: Vector3) -> void:
	var n := pivot(w, p)
	var st := rock_mat()
	for i in 9:
		var a := TAU * i / 9.0
		MeshKit.sphere(n, 0.24, Vector3(cos(a) * 0.85, 0.1, sin(a) * 0.85), st)
	MeshKit.cyl(n, 0.1, 0.1, 1.3, Vector3(0, 0.15, 0), dark_wood(), Vector3(90, 30, 0), 6)
	MeshKit.cyl(n, 0.1, 0.1, 1.3, Vector3(0, 0.15, 0), dark_wood(), Vector3(90, -40, 0), 6)
	MeshKit.cyl(n, 0.0, 0.45, 1.1, Vector3(0, 0.65, 0), MeshKit.unshaded(Color(1.0, 0.45, 0.1)), Vector3.ZERO, 7)
	MeshKit.cyl(n, 0.0, 0.25, 0.75, Vector3(0, 0.5, 0), MeshKit.unshaded(Color(1.0, 0.85, 0.3)), Vector3.ZERO, 7)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.6, 0.25)
	l.omni_range = 13.0
	l.position = Vector3(0, 1.3, 0)
	l.shadow_enabled = false
	n.add_child(l)
	w.fire_lights.append(l)
	var embers := CPUParticles3D.new()
	var em := SphereMesh.new()
	em.radius = 0.03
	em.height = 0.06
	em.radial_segments = 4
	em.rings = 2
	em.material = MeshKit.unshaded(Color(1.0, 0.6, 0.2))
	embers.mesh = em
	embers.amount = 24
	embers.lifetime = 1.6
	embers.direction = Vector3.UP
	embers.spread = 20.0
	embers.gravity = Vector3(0, 0.6, 0)
	embers.initial_velocity_min = 0.8
	embers.initial_velocity_max = 1.6
	embers.position = Vector3(0, 0.6, 0)
	n.add_child(embers)
	var smoke := CPUParticles3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.35
	sm.height = 0.7
	sm.radial_segments = 6
	sm.rings = 3
	sm.material = MeshKit.glow(Color(0.25, 0.25, 0.25, 0.25))
	smoke.mesh = sm
	smoke.amount = 12
	smoke.lifetime = 4.0
	smoke.direction = Vector3.UP
	smoke.spread = 10.0
	smoke.gravity = Vector3(0.15, 0.5, 0)
	smoke.initial_velocity_min = 0.6
	smoke.initial_velocity_max = 1.0
	smoke.scale_amount_min = 0.6
	smoke.scale_amount_max = 2.0
	smoke.position = Vector3(0, 1.4, 0)
	n.add_child(smoke)
	if PropKit.enabled():
		# a cooking pot by the fire and the campers' things around it
		PropKit.put(n, "Pot_1_Lid", Vector3(1.05, 0.0, 0.35), 20.0)
		var rng := RandomNumberGenerator.new()
		rng.seed = int(p.x * 13.0 + p.z * 7.0)
		PropKit.camp_clutter(w, p, rng, 2.8)


static func tent(w: Node3D, p: Vector3, yaw: float, cloth: Color) -> void:
	var n := pivot(w, p, yaw)
	MeshKit.prism(n, Vector3(4, 2.8, 5), Vector3(0, 1.4, 0), MeshKit.mat(cloth))
	MeshKit.box(n, Vector3(1.0, 1.8, 0.05), Vector3(0, 0.9, 2.52), MeshKit.mat(Color(0.08, 0.06, 0.05)))
	MeshKit.cyl(n, 0.05, 0.05, 3.4, Vector3(0, 1.5, 2.55), dark_wood())
	MeshKit.collider_box(n, Vector3(3.2, 2.2, 4.8), Vector3(0, 1.1, 0))


static func palisade(w: Node3D, center: Vector3, radius: float, from_deg: float, to_deg: float) -> void:
	var wd := dark_wood()
	var a := from_deg
	while a <= to_deg:
		var r := deg_to_rad(a)
		var p := center + Vector3(cos(r), 0, sin(r)) * radius
		var n := pivot(w, p)
		MeshKit.static_cyl(n, 0.3, 3.4, Vector3(0, 1.5, 0), wd, 7)
		MeshKit.cyl(n, 0.0, 0.3, 0.5, Vector3(0, 3.45, 0), wd, Vector3.ZERO, 7)
		a += 4.0


static func tombstone(w: Node3D, p: Vector3, yaw: float, rng: RandomNumberGenerator) -> void:
	var n := pivot(w, p, yaw)
	var st := stone(Color(0.85, 0.85, 0.9), 0.8)
	n.rotation_degrees.z = rng.randf_range(-8, 8)
	match rng.randi() % 3:
		0:
			MeshKit.static_box(n, Vector3(0.8, 1.1, 0.2), Vector3(0, 0.5, 0), st)
			MeshKit.cyl(n, 0.4, 0.4, 0.2, Vector3(0, 1.05, 0), st, Vector3(90, 0, 0), 12)
		1:
			MeshKit.static_box(n, Vector3(0.18, 1.6, 0.18), Vector3(0, 0.8, 0), st)
			MeshKit.box(n, Vector3(0.8, 0.18, 0.18), Vector3(0, 1.15, 0), st)
		_:
			MeshKit.static_box(n, Vector3(0.9, 0.7, 0.25), Vector3(0, 0.33, 0), st)
	MeshKit.box(n, Vector3(0.9, 0.08, 1.8), Vector3(0, 0.02, 1.0), MeshKit.mat(Color(0.3, 0.24, 0.18)))


static func ruined_wall(w: Node3D, p: Vector3, yaw: float, length: float, height: float, rng: RandomNumberGenerator) -> void:
	var n := pivot(w, p, yaw)
	var st := stone(Color(1.0, 0.95, 0.9))
	var seg := 1.6
	var count := int(length / seg)
	for i in count:
		var h := height * rng.randf_range(0.3, 1.0)
		MeshKit.static_box(n, Vector3(seg, h, 1.0), Vector3(-length * 0.5 + seg * (i + 0.5), h * 0.5, 0), st)


static func windmill(w: Node3D, p: Vector3, yaw: float) -> void:
	var n := pivot(w, p, yaw)
	var st := stone(Color(1.2, 1.1, 0.95))
	n.scale = Vector3.ONE * 1.3
	Buildings.windmill_room(w, n, 0.0)
	w.building_areas.append([Vector2(n.global_position.x, n.global_position.z), 4.6])
	MeshKit.cyl(n, 0.0, 3.1, 3.5, Vector3(0, 12.7, 0), roof(Color(0.6, 0.25, 0.15)), Vector3.ZERO, 12)
	var hub := Node3D.new()
	hub.position = Vector3(0, 9.5, 3.0)
	n.add_child(hub)
	MeshKit.cyl(hub, 0.35, 0.35, 0.8, Vector3.ZERO, dark_wood(), Vector3(90, 0, 0), 8)
	var sail := MeshKit.mat(Color(0.92, 0.88, 0.78))
	for i in 4:
		var arm := Node3D.new()
		arm.rotation.z = TAU * i / 4.0
		hub.add_child(arm)
		MeshKit.box(arm, Vector3(0.18, 7.5, 0.12), Vector3(0, 3.9, 0.3), dark_wood())
		MeshKit.box(arm, Vector3(1.6, 5.5, 0.05), Vector3(0.9, 4.6, 0.3), sail)
	w.spinners.append([hub, Vector3(0, 0, 0.5)])


static func haystack(w: Node3D, p: Vector3) -> void:
	var n := pivot(w, p)
	var hay := MeshKit.mat(Color(0.92, 0.76, 0.35))
	MeshKit.cyl(n, 0.4, 1.5, 2.2, Vector3(0, 1.1, 0), hay, Vector3.ZERO, 10)
	MeshKit.sphere(n, 0.5, Vector3(0, 2.2, 0), hay)
	var cs := CylinderShape3D.new()
	cs.radius = 1.2
	cs.height = 2.2
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	c.shape = cs
	c.position.y = 1.1
	body.add_child(c)
	n.add_child(body)


static func hay_bale(w: Node3D, p: Vector3, yaw := 0.0) -> void:
	var n := pivot(w, p, yaw)
	MeshKit.static_box(n, Vector3(1.6, 1.0, 1.0), Vector3(0, 0.5, 0), MeshKit.mat(Color(0.88, 0.74, 0.36)))


static func scarecrow(w: Node3D, p: Vector3, yaw: float) -> void:
	var n := pivot(w, p, yaw)
	MeshKit.box(n, Vector3(0.12, 2.6, 0.12), Vector3(0, 1.3, 0), dark_wood())
	MeshKit.box(n, Vector3(1.8, 0.1, 0.1), Vector3(0, 1.9, 0), dark_wood())
	MeshKit.box(n, Vector3(0.6, 0.8, 0.3), Vector3(0, 1.75, 0), MeshKit.mat(Color(0.5, 0.3, 0.3)))
	MeshKit.sphere(n, 0.25, Vector3(0, 2.4, 0), MeshKit.mat(Color(0.85, 0.75, 0.5)))
	MeshKit.cyl(n, 0.1, 0.4, 0.3, Vector3(0, 2.65, 0), MeshKit.mat(Color(0.35, 0.25, 0.12)), Vector3.ZERO, 8)


static func web(w: Node3D, p: Vector3, yaw: float, size: float, height: float) -> void:
	var n := pivot(w, p, yaw)
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var m := StandardMaterial3D.new()
	m.albedo_texture = _web_texture()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.9, 0.9, 0.95, 0.8)
	MeshKit.inst(n, q, Vector3(0, height, 0), m)


static var _web_tex: ImageTexture


static func _web_texture() -> ImageTexture:
	if _web_tex:
		return _web_tex
	var s := 256
	var img := Image.create_empty(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	var c := Vector2(s, s) * 0.5
	for i in 12:
		var a := TAU * i / 12.0
		for r in range(0, s / 2):
			var p := c + Vector2(cos(a), sin(a)) * r
			img.set_pixelv(Vector2i(p), Color(1, 1, 1, 1))
	for ring in range(10, s / 2, 12):
		for k in 360:
			var a := TAU * k / 360.0
			var p := c + Vector2(cos(a), sin(a)) * ring * (0.92 + 0.08 * cos(a * 12.0))
			if p.x >= 0 and p.y >= 0 and p.x < s and p.y < s:
				img.set_pixelv(Vector2i(p), Color(1, 1, 1, 0.9))
	_web_tex = ImageTexture.create_from_image(img)
	return _web_tex


static func well(w: Node3D, p: Vector3) -> void:
	var n := pivot(w, p)
	MeshKit.static_cyl(n, 1.2, 1.0, Vector3(0, 0.5, 0), stone(), 12)
	MeshKit.cyl(n, 1.0, 1.0, 0.05, Vector3(0, 0.9, 0), MeshKit.mat(Color(0.05, 0.08, 0.1)), Vector3.ZERO, 12)
	MeshKit.box(n, Vector3(0.15, 2.2, 0.15), Vector3(-1.0, 1.6, 0), dark_wood())
	MeshKit.box(n, Vector3(0.15, 2.2, 0.15), Vector3(1.0, 1.6, 0), dark_wood())
	MeshKit.prism(n, Vector3(2.8, 0.9, 1.6), Vector3(0, 3.0, 0), roof(Color(0.35, 0.4, 0.7)))


## Glowing lava pool that burns the player (registered in w.lava_zones).
static func lava(w: Node3D, center: Vector3, radius: float, level: float) -> void:
	water(w, center, radius, level, Color(0.9, 0.2, 0.02), Color(1.0, 0.6, 0.1), 2.5)
	w.water_zones.pop_back()
	w.lava_zones.append([Vector2(center.x, center.z), radius * 1.1, level])
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.45, 0.1)
	l.light_energy = 3.0
	l.omni_range = radius * 2.5
	w.add_child(l)
	l.global_position = Vector3(center.x, level + 2.0, center.z)


## Large sea plane (for coasts).
static func sea(w: Node3D, center: Vector3, size: Vector2, level: float) -> void:
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/water.gdshader")
	m.set_shader_parameter("deep_color", Color(0.03, 0.14, 0.22))
	m.set_shader_parameter("shallow_color", Color(0.2, 0.55, 0.55))
	m.set_shader_parameter("noise_tex", _water_noise())
	m.set_shader_parameter("clarity", 2.5)
	var plane := PlaneMesh.new()
	plane.size = size
	plane.subdivide_width = 80
	plane.subdivide_depth = 80
	var mi := MeshInstance3D.new()
	mi.mesh = plane
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	w.add_child(mi)
	mi.position = Vector3(center.x, level, center.z)
	w.water_zones.append([Vector2(center.x, center.z), maxf(size.x, size.y), level])


## Point of interest to explore (a treasure chest is placed next to it by the world).
static func poi(w: Node3D, kind: String, p: Vector3, yaw: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(p.x * 13.0 + p.z * 7.0)
	match kind:
		"ruin":
			ruined_wall(w, p + Vector3(-4, 0, 0), yaw + 90, 8, 4.5, rng)
			ruined_wall(w, p + Vector3(0, 0, -4), yaw, 8, 5.0, rng)
			var n := pivot(w, p + Vector3(3, 0, 3), yaw)
			for i in 3:
				MeshKit.static_cyl(n, 0.45, rng.randf_range(2.0, 5.0), Vector3(i * 2.2, 1.5, 0), stone(), 10)
		"statue":
			var n := pivot(w, p, yaw)
			var st := stone(Color(0.95, 0.95, 0.9), 0.5)
			MeshKit.static_box(n, Vector3(3, 1.2, 3), Vector3(0, 0.6, 0), st)
			MeshKit.box(n, Vector3(1.0, 2.6, 0.7), Vector3(0, 2.5, 0), st)
			MeshKit.sphere(n, 0.45, Vector3(0, 4.2, 0), st)
			MeshKit.box(n, Vector3(0.3, 2.2, 0.3), Vector3(0.75, 3.0, 0), st, Vector3(0, 0, -20))
			MeshKit.box(n, Vector3(0.12, 3.2, 0.12), Vector3(1.2, 3.8, 0), MeshKit.mat(Color(0.5, 0.5, 0.55), 0.4, 0.7))
			MeshKit.box(n, Vector3(1.6, 0.4, 0.4), Vector3(-0.5, 0.2, 1.8), st, Vector3(0, 30, 70))
		"arch":
			var n := pivot(w, p, yaw)
			var rk := rock_mat()
			MeshKit.static_sphere(n, 2.6, Vector3(-4, 1.0, 0), rk)
			MeshKit.static_sphere(n, 2.6, Vector3(4, 1.0, 0), rk)
			MeshKit.static_box(n, Vector3(10, 2.0, 3), Vector3(0, 5.5, 0), rk, Vector3(0, 0, 4))
			MeshKit.static_sphere(n, 2.0, Vector3(-3, 3.5, 0), rk)
			MeshKit.static_sphere(n, 2.0, Vector3(3, 4.0, 0), rk)
		"camp":
			tent(w, p + Vector3(-2.5, 0, -2), yaw + 20, Color(0.4, 0.35, 0.25))
			campfire(w, p + Vector3(2, 0, 1))
			crate(w, p + Vector3(-4.5, 0, 1), 30)
			barrel(w, p + Vector3(-4, 0, 2.3))
		"cart":
			var n := pivot(w, p, yaw)
			MeshKit.static_box(n, Vector3(2.4, 0.9, 1.4), Vector3(0, 0.9, 0), wood(), Vector3(0, 0, -12))
			for x in [-0.8, 0.8]:
				MeshKit.cyl(n, 0.5, 0.5, 0.12, Vector3(x, 0.45, 0.78), dark_wood(), Vector3(90, 0, 0), 12)
			MeshKit.cyl(n, 0.5, 0.5, 0.12, Vector3(-0.8, 0.3, -0.78), dark_wood(), Vector3(90, 0, 50), 12)
			for i in 3:
				crate(w, p + Vector3(rng.randf_range(-3, 3), 0, rng.randf_range(2, 3.5)), rng.randf_range(0, 90))
		"shipwreck":
			var n := pivot(w, p, yaw)
			n.rotation_degrees.z = 18
			var hull := dark_wood()
			MeshKit.static_box(n, Vector3(4, 2.5, 14), Vector3(0, 0.8, 0), hull)
			MeshKit.prism(n, Vector3(4, 3, 3), Vector3(0, 1.0, 8.2), hull, Vector3(90, 0, 0))
			MeshKit.cyl(n, 0.25, 0.3, 11.0, Vector3(0, 6, -1), dark_wood(), Vector3(-12, 0, 0), 8)
			MeshKit.box(n, Vector3(5, 3.5, 0.06), Vector3(0, 8, -1.5), MeshKit.mat(Color(0.75, 0.7, 0.6)), Vector3(-12, 0, 0))
		"crystals":
			var n := pivot(w, p, yaw)
			var cm := MeshKit.mat(Color(0.5, 0.75, 1.0) if yaw >= 0.0 else Color(1.0, 0.4, 0.1), 0.15, 0.0, 1.8)
			for i in 9:
				var a := rng.randf() * TAU
				var d := rng.randf_range(0.5, 3.5)
				MeshKit.cyl(n, 0.0, rng.randf_range(0.3, 0.7), rng.randf_range(1.5, 4.0), Vector3(cos(a) * d, 0.8, sin(a) * d), cm, Vector3(rng.randf_range(-25, 25), 0, rng.randf_range(-25, 25)), 6)
			var l := OmniLight3D.new()
			l.light_color = Color(0.5, 0.75, 1.0)
			l.light_energy = 2.0
			l.omni_range = 9.0
			l.position.y = 2.0
			n.add_child(l)
		"obelisk":
			var n := pivot(w, p, yaw)
			var st := stone(Color(0.55, 0.52, 0.6), 0.5)
			MeshKit.static_box(n, Vector3(1.6, 8.0, 1.6), Vector3(0, 4, 0), st)
			MeshKit.cyl(n, 0.0, 1.15, 1.6, Vector3(0, 8.8, 0), st, Vector3(0, 45, 0), 4)
			MeshKit.box(n, Vector3(0.4, 4.0, 0.05), Vector3(0, 4.5, 0.82), MeshKit.mat(Color(0.4, 0.9, 1.0), 0.5, 0.0, 2.0))
		"cairn":
			var n := pivot(w, p, yaw)
			var rk := rock_mat(Color(1.4, 1.4, 1.5))
			for i in 5:
				MeshKit.static_sphere(n, 0.9 - i * 0.12, Vector3(0, 0.5 + i * 0.75, 0), rk)
			MeshKit.box(n, Vector3(0.1, 2.5, 0.1), Vector3(1.5, 1.25, 0), dark_wood())
			MeshKit.box(n, Vector3(0.9, 1.2, 0.03), Vector3(1.95, 2.0, 0), MeshKit.mat(Color(0.2, 0.35, 0.7)))


## Huge climbable oak with wooden rungs nailed to one side and an old plank platform in the
## crown. Returns the platform's world position (where things can be placed up there).
## `face_yaw` is the direction (degrees) the rung side faces.
static func climb_tree(w: Node3D, p: Vector3, platform_h := 11.0, face_yaw := 0.0) -> Vector3:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(p.x * 31.0 + p.z * 17.0)
	var n := pivot(w, p)
	var cfg: Dictionary = w.cfg
	var total_h := platform_h + 5.0
	var trunk := MeshKit.inst(n, Nature.trunk_mesh(rng, total_h, 1.0, 1.1, 0.6, 8, 6.0), Vector3.ZERO, Nature.bark_material(cfg.get("bark_tint", Color(1.2, 0.8, 0.45))))
	trunk.set_meta("surface", "wood")
	var leaves := Nature.card_material(Nature.LEAF_TEX, cfg["foliage"], Nature.LEAF_REF, cfg.get("leaf_snow", 0.0))
	# crown sits above the platform so the player has room up there
	var blobs := [[Vector3(0, total_h + 2.5, 0), 5.0], [Vector3(3.5, total_h + 1.5, 1.5), 3.4], [Vector3(-3.5, total_h + 1.8, -1.0), 3.6],
		[Vector3(0.5, total_h + 1.2, -3.5), 3.2], [Vector3(-1.0, total_h + 4.5, 2.5), 3.4], [Vector3(2.0, total_h + 4.0, -2.0), 3.2]]
	MeshKit.inst(n, Nature.leaf_crown(rng, blobs, 240, 2.6), Vector3.ZERO, leaves)
	var cs := CylinderShape3D.new()
	cs.radius = 0.95
	cs.height = total_h
	var body := StaticBody3D.new()
	body.set_meta("surface", "wood")
	var col := CollisionShape3D.new()
	col.shape = cs
	col.position.y = total_h * 0.5
	body.add_child(col)
	n.add_child(body)

	var face := deg_to_rad(face_yaw)
	var r_top := 1.0 * (1.0 - 0.55 * platform_h / total_h)
	# rungs: short planks nailed up the trunk
	var rung_mat := wood()
	var h := 0.6
	while h < platform_h - 0.3:
		var r := lerpf(1.0, r_top, h / platform_h) + 0.05
		var rp := Vector3(sin(face) * r, h, cos(face) * r)
		MeshKit.box(n, Vector3(0.7, 0.09, 0.12), rp, rung_mat, Vector3(0, face_yaw, rng.randf_range(-6, 6)))
		h += 0.55
	# platform on the side, a quarter turn from the rungs
	var side := face + PI * 0.5
	var pc := Vector3(sin(side) * 2.0, platform_h, cos(side) * 2.0)
	var plat := Node3D.new()
	plat.position = pc
	plat.rotation.y = side
	n.add_child(plat)
	MeshKit.static_box(plat, Vector3(3.2, 0.16, 2.6), Vector3(0, -0.08, 0), wood())
	for x in [-1.4, 1.4]:
		MeshKit.cyl(plat, 0.22, 0.28, 3.4, Vector3(x * 0.6, -0.35, 0.2), Nature.bark_material(cfg.get("bark_tint", Color(1.2, 0.8, 0.45))), Vector3(90, 0, 0), 8)
	for z in [-1.25, 1.25]:
		MeshKit.box(plat, Vector3(3.2, 0.08, 0.08), Vector3(0, 0.75, z), dark_wood())
	for c in [Vector3(-1.55, 0.4, -1.25), Vector3(1.55, 0.4, -1.25), Vector3(-1.55, 0.4, 1.25), Vector3(1.55, 0.4, 1.25)]:
		MeshKit.box(plat, Vector3(0.09, 0.8, 0.09), c, dark_wood())
	MeshKit.collider_box(plat, Vector3(3.2, 1.0, 0.15), Vector3(0, 0.5, 1.3))
	MeshKit.collider_box(plat, Vector3(3.2, 1.0, 0.15), Vector3(0, 0.5, -1.3))

	var base := n.global_position
	var top := base + pc + Vector3(0, 0.0, 0)
	for down in [false, true]:
		var s := ClimbSpot.new()
		s.world = w
		s.tree_base = base
		s.top_height = platform_h
		s.top_pos = top
		s.radius_bottom = 1.0
		s.radius_top = r_top
		s.face_angle = face
		s.down = down
		w.add_child(s)
		s.global_position = (top + Vector3(sin(side) * -0.6, 0.5, cos(side) * -0.6)) if down else (base + Vector3(sin(face) * 1.2, 0.5, cos(face) * 1.2))
	return top


static func water(w: Node3D, center: Vector3, radius: float, level: float, deep: Color, shallow: Color, glow := 0.0) -> void:
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/water.gdshader")
	m.set_shader_parameter("deep_color", deep)
	m.set_shader_parameter("shallow_color", shallow)
	m.set_shader_parameter("emission_strength", glow)
	m.set_shader_parameter("noise_tex", _water_noise())
	var plane := PlaneMesh.new()
	plane.size = Vector2(radius * 2.7, radius * 2.7)
	plane.subdivide_width = 40
	plane.subdivide_depth = 40
	var mi := MeshInstance3D.new()
	mi.mesh = plane
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	w.add_child(mi)
	mi.position = Vector3(center.x, level, center.z)
	w.water_zones.append([Vector2(center.x, center.z), radius * 1.3, level])


static var _wnoise: NoiseTexture2D


static func _water_noise() -> NoiseTexture2D:
	if _wnoise == null:
		var n := FastNoiseLite.new()
		n.frequency = 0.02
		n.fractal_octaves = 4
		_wnoise = NoiseTexture2D.new()
		_wnoise.width = 512
		_wnoise.height = 512
		_wnoise.seamless = true
		_wnoise.noise = n
		_wnoise.generate_mipmaps = true
	return _wnoise
