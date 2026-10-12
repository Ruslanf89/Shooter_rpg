class_name TechProps
extends RefCounted
## Things the villages build once they learn technology from the player (world.tech_level):
##   1+ VesPer's FPV drones circle over the square
##   2+ a radio mast with a blinking light
##   3+ a petrol generator, electric street lamps and wires
## Also the FPV drone model used by the cinematics.


## Small quadcopter (about 25 cm). Rotors are returned in meta "rotors" for spinning.
static func drone_model(parent: Node3D, glow := true) -> Node3D:
	var d := Node3D.new()
	parent.add_child(d)
	var carbon := MeshKit.mat(Color(0.08, 0.08, 0.09), 0.5, 0.3)
	var red := MeshKit.mat(Color(0.75, 0.1, 0.08), 0.6)
	var prop := MeshKit.mat(Color(0.15, 0.15, 0.16, 0.6), 0.4)
	MeshKit.box(d, Vector3(0.08, 0.035, 0.14), Vector3.ZERO, carbon)
	MeshKit.box(d, Vector3(0.05, 0.03, 0.05), Vector3(0, 0.03, 0.02), red)
	MeshKit.box(d, Vector3(0.025, 0.025, 0.03), Vector3(0, 0.0, -0.08), MeshKit.mat(Color(0.2, 0.2, 0.22), 0.3, 0.6))
	var rotors: Array = []
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var arm_end := Vector3(sx * 0.1, 0, sz * 0.1)
			MeshKit.box(d, Vector3(0.02, 0.012, 0.15), arm_end * 0.5, carbon, Vector3(0, rad_to_deg(atan2(sx, sz)), 0))
			MeshKit.cyl(d, 0.014, 0.014, 0.025, arm_end + Vector3(0, 0.015, 0), carbon, Vector3.ZERO, 8)
			var r := Node3D.new()
			r.position = arm_end + Vector3(0, 0.03, 0)
			d.add_child(r)
			MeshKit.box(r, Vector3(0.13, 0.003, 0.016), Vector3.ZERO, prop)
			rotors.append(r)
	if glow:
		MeshKit.sphere(d, 0.008, Vector3(0, -0.01, -0.07), MeshKit.mat(Color(0.2, 1.0, 0.3), 0.5, 0.0, 4.0))
		MeshKit.sphere(d, 0.008, Vector3(0, -0.01, 0.07), MeshKit.mat(Color(1.0, 0.15, 0.1), 0.5, 0.0, 4.0))
	d.set_meta("rotors", rotors)
	return d


## Generated looping sound attached to `parent`.
static func loop_sound(parent: Node3D, sound: String, volume := -6.0, max_dist := 40.0) -> AudioStreamPlayer3D:
	var s := AudioStreamPlayer3D.new()
	s.bus = "SFX"
	s.stream = Game.sounds[sound][0]
	s.volume_db = volume
	s.unit_size = 4.0
	s.max_distance = max_dist
	s.autoplay = true
	parent.add_child(s)
	return s


static func radio_mast(w: Node3D, p: Vector3) -> void:
	var n := Props.pivot(w, p)
	var steel := MeshKit.mat(Color(0.55, 0.56, 0.58), 0.4, 0.8)
	var white := MeshKit.mat(Color(0.85, 0.85, 0.82), 0.5, 0.4)
	var h := 11.0
	MeshKit.static_box(n, Vector3(0.9, 0.3, 0.9), Vector3(0, 0.15, 0), Props.stone(Color(0.6, 0.6, 0.6), 0.8))
	# three-legged lattice, alternate red/white sections
	for i in 3:
		var a := TAU * i / 3.0
		MeshKit.cyl(n, 0.025, 0.035, h, Vector3(sin(a), 0, cos(a)) * 0.25 + Vector3(0, h * 0.5 + 0.3, 0), steel, Vector3.ZERO, 5)
	var y := 0.6
	var k := 0
	while y < h:
		var m := white if k % 2 == 0 else MeshKit.mat(Color(0.75, 0.12, 0.1), 0.5, 0.3)
		for i in 3:
			var a := TAU * (i + 0.5) / 3.0
			MeshKit.box(n, Vector3(0.43, 0.025, 0.025), Vector3(sin(a), 0, cos(a)) * 0.125 + Vector3(0, y, 0), m, Vector3(0, rad_to_deg(a) + 90.0, 0))
			MeshKit.box(n, Vector3(0.5, 0.02, 0.02), Vector3(sin(a), 0, cos(a)) * 0.125 + Vector3(0, y + 0.35, 0), m, Vector3(0, rad_to_deg(a) + 90.0, 35))
		y += 0.7
		k += 1
	MeshKit.static_cyl(n, 0.3, h, Vector3(0, h * 0.5 + 0.3, 0), MeshKit.mat(Color(0, 0, 0, 0)), 4).visible = false
	# antennas, dish and the red beacon
	MeshKit.cyl(n, 0.01, 0.015, 2.2, Vector3(0, h + 1.4, 0), steel, Vector3.ZERO, 4)
	MeshKit.cyl(n, 0.22, 0.05, 0.12, Vector3(0.3, h - 1.5, 0), white, Vector3(0, 0, 70), 10)
	for s in [-1.0, 1.0]:
		MeshKit.cyl(n, 0.008, 0.008, 0.9, Vector3(s * 0.3, h - 0.6, 0), steel, Vector3(0, 0, 90), 4)
	var beacon := MeshKit.sphere(n, 0.08, Vector3(0, h + 2.55, 0), MeshKit.mat(Color(1.0, 0.1, 0.05), 0.4, 0.0, 6.0))
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.15, 0.1)
	l.light_energy = 1.5
	l.omni_range = 6.0
	l.position = Vector3(0, h + 2.55, 0)
	n.add_child(l)
	var tw := n.create_tween().set_loops()
	tw.tween_callback(func() -> void:
		beacon.visible = not beacon.visible
		l.visible = beacon.visible)
	tw.tween_interval(0.8)
	# guy wires
	for i in 3:
		var a := TAU * (i + 0.5) / 3.0
		var foot := n.position + Vector3(sin(a), 0, cos(a)) * 4.5
		foot = Props.ground_at(w, foot)
		wire(w, n.position + Vector3(0, h * 0.75, 0), foot, 0.05, steel)
		MeshKit.cyl(w, 0.06, 0.08, 0.25, foot + Vector3(0, 0.1, 0), steel, Vector3.ZERO, 6)


static func generator(w: Node3D, p: Vector3, yaw: float) -> Vector3:
	var n := Props.pivot(w, p, yaw)
	var green := MeshKit.mat(Color(0.25, 0.38, 0.25), 0.55, 0.4)
	var dark := MeshKit.mat(Color(0.12, 0.12, 0.12), 0.5, 0.6)
	MeshKit.static_box(n, Vector3(1.3, 0.12, 0.8), Vector3(0, 0.06, 0), dark)
	MeshKit.static_box(n, Vector3(1.1, 0.6, 0.6), Vector3(0, 0.45, 0), green)
	MeshKit.cyl(n, 0.2, 0.2, 0.62, Vector3(-0.25, 0.85, 0), MeshKit.mat(Color(0.7, 0.15, 0.1), 0.4, 0.5), Vector3(90, 0, 0), 12)
	MeshKit.box(n, Vector3(0.35, 0.3, 0.02), Vector3(0.3, 0.5, 0.31), MeshKit.mat(Color(0.1, 0.1, 0.1), 0.3, 0.8))
	MeshKit.cyl(n, 0.035, 0.035, 0.5, Vector3(0.5, 0.95, -0.2), dark, Vector3.ZERO, 6)
	var smoke := CPUParticles3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.08
	sm.height = 0.16
	sm.radial_segments = 6
	sm.rings = 3
	sm.material = MeshKit.glow(Color(0.25, 0.25, 0.25, 0.25))
	smoke.mesh = sm
	smoke.amount = 12
	smoke.lifetime = 2.0
	smoke.direction = Vector3.UP
	smoke.spread = 15.0
	smoke.gravity = Vector3(0.2, 0.6, 0)
	smoke.initial_velocity_min = 0.6
	smoke.initial_velocity_max = 1.0
	smoke.scale_amount_max = 3.0
	smoke.position = Vector3(0.5, 1.22, -0.2)
	n.add_child(smoke)
	loop_sound(n, "generator", -10.0, 26.0)
	return n.to_global(Vector3(0, 0.7, 0))


## Wooden electric pole with a lamp. Returns the top (wire) point.
static func electric_lamp(w: Node3D, p: Vector3) -> Vector3:
	var n := Props.pivot(w, p)
	var wood := MeshKit.mat(Color(0.32, 0.24, 0.16), 0.9)
	var iron := MeshKit.mat(Color(0.15, 0.15, 0.16), 0.5, 0.7)
	MeshKit.static_cyl(n, 0.1, 5.2, Vector3(0, 2.6, 0), wood, 8)
	MeshKit.box(n, Vector3(1.1, 0.09, 0.09), Vector3(0, 4.9, 0), wood)
	for x in [-0.45, 0.45]:
		MeshKit.cyl(n, 0.025, 0.035, 0.12, Vector3(x, 5.0, 0), MeshKit.mat(Color(0.9, 0.9, 0.85), 0.2), Vector3.ZERO, 6)
	MeshKit.box(n, Vector3(0.05, 0.05, 0.8), Vector3(0, 4.3, 0.4), iron)
	MeshKit.cyl(n, 0.05, 0.28, 0.14, Vector3(0, 4.22, 0.78), iron, Vector3.ZERO, 10)
	MeshKit.sphere(n, 0.07, Vector3(0, 4.12, 0.78), MeshKit.mat(Color(1.0, 0.95, 0.8), 0.3, 0.0, 5.0))
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.93, 0.8)
	l.light_energy = 1.8
	l.omni_range = 13.0
	l.position = Vector3(0, 4.0, 0.78)
	Buildings.fade(l, 80.0)
	n.add_child(l)
	w.flicker_lights.append([l, l.light_energy])
	return n.position + Vector3(0, 5.05, 0)


## Sagging cable from a to b, made of a few thin segments.
static func wire(w: Node3D, a: Vector3, b: Vector3, sag: float, mat: Material = null) -> void:
	if mat == null:
		mat = MeshKit.mat(Color(0.06, 0.06, 0.06), 0.6)
	var segs := 6
	var prev := a
	for i in range(1, segs + 1):
		var t := float(i) / segs
		var q := a.lerp(b, t) + Vector3.DOWN * sag * a.distance_to(b) * 4.0 * t * (1.0 - t) * 0.25
		var dir := q - prev
		var len := dir.length()
		if len > 0.01:
			var cm := CylinderMesh.new()
			cm.top_radius = 0.012
			cm.bottom_radius = 0.012
			cm.height = len
			cm.radial_segments = 4
			cm.rings = 1
			var mi := MeshInstance3D.new()
			mi.mesh = cm
			mi.material_override = mat
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var y := dir / len
			var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
			var z := x.cross(y)
			w.add_child(mi)
			mi.global_transform = Transform3D(Basis(x, y, z), (prev + q) * 0.5)
		prev = q
