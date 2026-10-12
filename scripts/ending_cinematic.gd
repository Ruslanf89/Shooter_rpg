extends Cinematic
## Ending (after Captain Bones): VesPer waits at the lighthouse at sunset and finally tells his
## story - flashbacks of a wheat field and his tractor, a mermaid in the river trading a glowing
## mushroom for his drone controller - he recognised the player's rifle from the start, and the
## same mushroom grows behind the lighthouse. The player chooses: stay, or go home. Then credits.

const LH := Vector3(0, 0, 0)                  # lighthouse
const GROVE := Vector3(-7, 0, -13)
const FIELD := Vector3(900, 0, 0)             # flashback: wheat field
const RIVER := Vector3(900, 0, 320)           # flashback: river
const LINE := Vector3(900, 0, -320)           # home ending: the tree line behind the trench

var _ves: Dictionary
var _hero: Dictionary
var _grove: Node3D
var _tractor: Node3D
var _wheels: Array = []
var _rider: Dictionary
var _drone: Node3D
var _rotors: Array = []
var _mermaid: Dictionary
var _fin: Node3D
var _young: Dictionary
var _controller: Node3D
var _gift: Node3D
var _warp: ShaderMaterial
var _sun: DirectionalLight3D
var _fill: DirectionalLight3D
var _engine: AudioStreamPlayer
var _sea: AudioStreamPlayer
var _choice_box: HBoxContainer
var _choice_shot := -1
var _credits: Control
var _credits_t := -1.0
var _flyers: Array = []
var _crystal: Node3D
var _flags := {}


func build() -> void:
	Game.play_music("rpg/ambient_10", 3.0)
	cfg = (load(Game.LEVELS[5]["script"]).new()).config()
	_sunset()
	_build_coast()
	_build_field()
	_build_river()
	_ves = vesper(LH + Vector3(3.0, 0, 6.0), 0.0)
	_hero = soldier(LH + Vector3(3.4, 0, 9.6), PI)
	play(_hero, "idle")
	_face(_ves, _hero["node"].position)
	_face(_hero, _ves["node"].position)
	_warp = warp_overlay()
	_sea = loop_sound("amb_wind", -16.0)
	shots = [
		{"line": "en_1", "min": 7.0, "start": _s_coast_start, "update": _s1},
		{"line": "en_2", "min": 8.0, "start": _s_field_start, "update": _s2},
		{"line": "en_3", "min": 8.0, "start": _s_river_start, "update": _s3},
		{"line": "en_4", "min": 9.0, "update": _s4},
		{"line": "en_5", "min": 8.0, "update": _s5},
		{"line": "en_6", "min": 7.0, "start": _s_back_start, "update": _s6},
		{"line": "en_7", "min": 8.0, "update": _s7},
		{"min": 1.0, "wait": true, "start": _show_choice, "update": _s_choice},
	]
	_choice_shot = shots.size() - 1


# --------------------------------------------------------------------------- sets

func _sunset() -> void:
	make_environment(Color(0.16, 0.22, 0.45), Color(1.0, 0.62, 0.38), Color(0.2, 0.2, 0.25), Color(1.0, 0.55, 0.3),
		Color(1.0, 0.75, 0.6), Color(0.45, 0.35, 0.5), 0.45, 0.1, Color(0.85, 0.6, 0.5), 0.003, 0.8)
	_sun = sun(Color(1.0, 0.65, 0.4), 1.2, Vector3(-8, 10, 0))
	_fill = sun(Color(0.5, 0.55, 0.9), 0.25, Vector3(-45, 190, 0), false)


func _face(p: Dictionary, target: Vector3) -> void:
	var n: Node3D = p["node"]
	var d := target - n.position
	n.rotation.y = atan2(-d.x, -d.z)


func _build_coast() -> void:
	var grass := MeshKit.textured("Grass004", Color(0.8, 0.8, 0.45), 0.22, 0.0, 0.95)
	var sand := MeshKit.textured("Ground048", Color(1.25, 1.1, 0.8), 0.3, 0.0, 1.0)
	MeshKit.box(self, Vector3(500, 0.2, 260), LH + Vector3(0, -0.1, -110), grass)
	MeshKit.box(self, Vector3(500, 0.2, 20), LH + Vector3(0, -0.35, 28), sand, Vector3(6, 0, 0))
	Props.sea(self, LH + Vector3(0, 0, 160), Vector2(700, 280), -0.9)
	var rk := Props.rock_mat(Color(1.1, 1.05, 0.95))
	for i in 14:
		var p := LH + Vector3(rng.randf_range(-60, 60), -0.4, rng.randf_range(24, 40))
		MeshKit.sphere(self, rng.randf_range(0.8, 2.4), p, rk, Vector3(1.0, 0.7, 1.0))
	var n := Props.pivot(self, LH)
	Buildings.lighthouse(self, n)
	MeshKit.cyl(n, 1.5, 1.5, 2.2, Vector3(0, 23.4, 0), MeshKit.glow(Color(1.0, 0.9, 0.6, 0.5)), Vector3.ZERO, 12)
	MeshKit.cyl(n, 0.0, 1.9, 1.6, Vector3(0, 25.3, 0), MeshKit.mat(Color(0.75, 0.12, 0.1)), Vector3.ZERO, 12)
	var beam := Node3D.new()
	beam.position.y = 23.4
	n.add_child(beam)
	var sl := SpotLight3D.new()
	sl.light_color = Color(1.0, 0.92, 0.7)
	sl.light_energy = 6.0
	sl.spot_range = 80.0
	sl.spot_angle = 12.0
	beam.add_child(sl)
	var bm := CylinderMesh.new()
	bm.top_radius = 0.4
	bm.bottom_radius = 4.0
	bm.height = 40.0
	MeshKit.inst(beam, bm, Vector3(0, 0, -20), MeshKit.glow(Color(1.0, 0.9, 0.6, 0.06)), Vector3(90, 0, 0))
	spinners.append([beam, Vector3(0, 0.6, 0)])
	Props.house(self, LH + Vector3(-10, 0, 2), 180, Vector3(5, 3.4, 4.5), Color(0.75, 0.3, 0.25), Color(0.92, 0.9, 0.85))
	var pts := []
	for i in 120:
		var a := rng.randf() * TAU
		var r := rng.randf_range(24.0, 120.0)
		var p := LH + Vector3(cos(a) * r, 0, sin(a) * r)
		if p.z > 12.0:
			continue
		if Vector2(p.x - GROVE.x, p.z - GROVE.z).length() < 9.0:
			continue
		pts.append(p)
	Nature.plant_trees(self, pts, cfg, rng)
	_grove = mushrooms(GROVE, 26)


func _build_field() -> void:
	var soil := MeshKit.textured("Ground048", Color(0.8, 0.65, 0.45), 0.3, 0.0, 0.9)
	MeshKit.box(self, Vector3(300, 0.2, 300), FIELD + Vector3(0, -0.1, 0), soil)
	MeshKit.box(self, Vector3(95, 0.05, 90), FIELD + Vector3(0, 0.02, 0), MeshKit.textured("Grass004", Color(1.6, 1.25, 0.55), 0.3, 0.6, 1.0))
	MeshKit.box(self, Vector3(300, 0.02, 4), FIELD + Vector3(0, 0.01, 8), MeshKit.textured("Ground037", Color(0.7, 0.6, 0.45), 0.3, 0.0, 0.8))
	# wheat: thousands of stalks in a MultiMesh
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var stalk := BoxMesh.new()
	stalk.size = Vector3(0.03, 1.0, 0.03)
	mm.mesh = stalk
	var ts: Array = []
	var ears: Array = []
	for i in 26000:
		var p := FIELD + Vector3(rng.randf_range(-45, 45), 0, rng.randf_range(-12, 20) if i % 4 != 0 else rng.randf_range(-40, 40))
		if absf(p.z - FIELD.z - 8.0) < 2.4:
			continue
		var h := rng.randf_range(0.8, 1.1)
		var b := Basis.from_euler(Vector3(rng.randf_range(-0.2, 0.2), rng.randf() * TAU, rng.randf_range(-0.2, 0.2)))
		ts.append(Transform3D(b.scaled(Vector3(1, h, 1)), p + b * Vector3(0, h * 0.5, 0)))
		ears.append(Transform3D(b.scaled(Vector3(0.05, 0.16, 0.05)), p + b * Vector3(0, h, 0)))
	mm.instance_count = ts.size()
	for i in ts.size():
		mm.set_instance_transform(i, ts[i])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = MeshKit.mat(Color(0.86, 0.68, 0.3), 0.8)
	add_child(mi)
	var em := MultiMesh.new()
	em.transform_format = MultiMesh.TRANSFORM_3D
	var ear := SphereMesh.new()
	ear.radial_segments = 6
	ear.rings = 3
	em.mesh = ear
	em.instance_count = ears.size()
	for i in ears.size():
		em.set_instance_transform(i, ears[i])
	var emi := MultiMeshInstance3D.new()
	emi.multimesh = em
	emi.material_override = MeshKit.mat(Color(0.95, 0.75, 0.35), 0.7)
	add_child(emi)
	var trees := []
	for i in 30:
		trees.append(FIELD + Vector3(rng.randf_range(-120, 120), 0, rng.randf_range(-110, -55)))
	Nature.plant_trees(self, trees, cfg, rng)
	_tractor = _build_tractor()
	_tractor.position = FIELD + Vector3(-30, 0, 8)
	_tractor.rotation.y = -PI * 0.5
	_rider = vesper(Vector3.ZERO, 0.0)
	var rn: Node3D = _rider["node"]
	rn.reparent(_tractor, false)
	rn.position = Vector3(0, 0.55, 0.45)
	rn.rotation = Vector3.ZERO
	pose_end(_rider, "sit_down")
	_drone = TechProps.drone_model(self)
	_drone.scale = Vector3.ONE * 2.0
	_rotors = _drone.get_meta("rotors")


func _build_tractor() -> Node3D:
	var t := Node3D.new()
	add_child(t)
	var red := MeshKit.mat(Color(0.2, 0.35, 0.6), 0.5, 0.3)
	var dark := MeshKit.mat(Color(0.08, 0.08, 0.08), 0.8)
	var rim := MeshKit.mat(Color(0.85, 0.75, 0.2), 0.5, 0.4)
	MeshKit.box(t, Vector3(0.9, 0.6, 2.4), Vector3(0, 0.75, -0.4), red)
	MeshKit.box(t, Vector3(0.8, 0.55, 1.2), Vector3(0, 1.2, -1.0), red)
	MeshKit.box(t, Vector3(0.82, 0.3, 0.05), Vector3(0, 1.0, -1.62), MeshKit.mat(Color(0.2, 0.2, 0.2), 0.4, 0.8))
	for sx in [-0.3, 0.3]:
		MeshKit.sphere(t, 0.07, Vector3(sx, 1.25, -1.62), MeshKit.mat(Color(1.0, 0.95, 0.8), 0.3, 0.0, 2.0))
	MeshKit.cyl(t, 0.05, 0.05, 1.0, Vector3(0.25, 1.9, -1.2), dark, Vector3.ZERO, 8)
	MeshKit.box(t, Vector3(0.6, 0.12, 0.5), Vector3(0, 1.05, 0.45), dark)
	MeshKit.box(t, Vector3(0.6, 0.5, 0.08), Vector3(0, 1.35, 0.72), dark)
	MeshKit.cyl(t, 0.18, 0.18, 0.03, Vector3(0, 1.45, -0.05), dark, Vector3(-50, 0, 0), 12)
	# cabin frame
	for sx in [-0.55, 0.55]:
		for sz in [-0.1, 0.85]:
			MeshKit.cyl(t, 0.03, 0.03, 1.5, Vector3(sx, 1.85, sz), dark, Vector3.ZERO, 6)
	MeshKit.box(t, Vector3(1.3, 0.06, 1.15), Vector3(0, 2.6, 0.38), red)
	for wd in [[Vector3(-0.72, 0.75, 0.5), 0.75, 0.38], [Vector3(0.72, 0.75, 0.5), 0.75, 0.38], [Vector3(-0.55, 0.42, -1.3), 0.42, 0.22], [Vector3(0.55, 0.42, -1.3), 0.42, 0.22]]:
		var w := Node3D.new()
		w.position = wd[0]
		t.add_child(w)
		MeshKit.cyl(w, wd[1], wd[1], wd[2], Vector3.ZERO, dark, Vector3(0, 0, 90), 18)
		MeshKit.cyl(w, float(wd[1]) * 0.6, float(wd[1]) * 0.6, float(wd[2]) + 0.02, Vector3.ZERO, rim, Vector3(0, 0, 90), 12)
		for k in 6:
			MeshKit.box(w, Vector3(float(wd[2]) + 0.04, 0.08, 0.06), Vector3(0, 0, 0).rotated(Vector3.RIGHT, k), dark, Vector3(k * 30.0, 0, 0))
		_wheels.append([w, float(wd[1])])
	return t


func _build_river() -> void:
	var bank := MeshKit.textured("Grass004", Color(0.45, 0.55, 0.4), 0.22, 0.0, 0.8)
	MeshKit.box(self, Vector3(150, 0.4, 300), RIVER + Vector3(-81, -0.2, 0), bank)
	MeshKit.box(self, Vector3(150, 0.4, 300), RIVER + Vector3(81, -0.2, 0), bank)
	MeshKit.box(self, Vector3(14, 0.2, 300), RIVER + Vector3(0, -2.2, 0), MeshKit.textured("Ground037", Color(0.4, 0.38, 0.32), 0.3, 0.0, 0.6))
	Props.sea(self, RIVER, Vector2(13, 300), -0.45)
	var rk := Props.rock_mat(Color(0.9, 0.9, 0.85))
	MeshKit.sphere(self, 1.0, RIVER + Vector3(-3.4, -0.75, -0.4), rk, Vector3(1.2, 0.6, 1.0))
	var reed := MeshKit.mat(Color(0.35, 0.42, 0.2), 0.9)
	for i in 160:
		var side := -1.0 if i % 2 == 0 else 1.0
		var p := RIVER + Vector3(side * rng.randf_range(5.6, 7.5), 0, rng.randf_range(-30, 30))
		MeshKit.cyl(self, 0.01, 0.02, rng.randf_range(0.8, 1.6), p + Vector3(0, 0.6, 0), reed, Vector3(rng.randf_range(-8, 8), 0, rng.randf_range(-8, 8)), 4)
	var trees := []
	for i in 40:
		var side := -1.0 if i % 2 == 0 else 1.0
		trees.append(RIVER + Vector3(side * rng.randf_range(12, 60), 0, rng.randf_range(-80, 60)))
	Nature.plant_trees(self, trees, cfg, rng)
	# the mermaid: in the water up to her waist, a tail fin flicking behind her
	_mermaid = person("people/woman_dress", {"Dress": Color(0.1, 0.5, 0.45), "Hair": Color(0.8, 0.28, 0.12), "Skin": Color(0.9, 0.78, 0.72)},
		RIVER + Vector3(-4.6, -1.35, 1.0), PI * 0.5, 1.6)
	play(_mermaid, "idle")
	_fin = Node3D.new()
	add_child(_fin)
	var scale_mat := MeshKit.mat(Color(0.15, 0.6, 0.55), 0.3, 0.4, 0.3)
	MeshKit.cyl(_fin, 0.05, 0.12, 0.5, Vector3(0, 0.25, 0), scale_mat, Vector3.ZERO, 10)
	for s in [-1.0, 1.0]:
		MeshKit.sphere(_fin, 0.22, Vector3(s * 0.18, 0.55, 0), scale_mat, Vector3(1.0, 0.35, 0.12))
	_fin.position = RIVER + Vector3(-2.4, -0.9, 1.3)
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.4, 1.0, 0.9)
	glow.light_energy = 1.2
	glow.omni_range = 4.0
	glow.position = RIVER + Vector3(-4.6, 0.8, 1.0)
	add_child(glow)
	_young = vesper(RIVER + Vector3(-11.0, 0, 1.0), -PI * 0.5)
	# what they trade
	_controller = Node3D.new()
	add_child(_controller)
	var plastic := MeshKit.mat(Color(0.12, 0.12, 0.13), 0.5)
	MeshKit.box(_controller, Vector3(0.2, 0.04, 0.12), Vector3.ZERO, plastic)
	for sx in [-0.05, 0.05]:
		MeshKit.cyl(_controller, 0.008, 0.008, 0.04, Vector3(sx, 0.03, 0), MeshKit.mat(Color(0.7, 0.7, 0.7), 0.4, 0.7), Vector3.ZERO, 6)
	MeshKit.cyl(_controller, 0.005, 0.005, 0.18, Vector3(0.08, 0.1, -0.05), plastic, Vector3.ZERO, 4)
	MeshKit.box(_controller, Vector3(0.05, 0.02, 0.03), Vector3(-0.05, 0.025, -0.045), MeshKit.mat(Color(0.2, 0.9, 0.4), 0.4, 0.0, 2.0))
	_gift = Node3D.new()
	add_child(_gift)
	MeshKit.cyl(_gift, 0.02, 0.026, 0.12, Vector3(0, 0.06, 0), MeshKit.mat(Color(0.85, 0.82, 0.72), 0.7, 0.0, 0.4), Vector3.ZERO, 8)
	MeshKit.sphere(_gift, 0.06, Vector3(0, 0.13, 0), MeshKit.mat(Color(0.35, 0.85, 1.0), 0.4, 0.0, 1.5), Vector3(1, 0.55, 1))
	var gl := OmniLight3D.new()
	gl.light_color = Color(0.35, 0.85, 1.0)
	gl.light_energy = 0.8
	gl.omni_range = 2.0
	_gift.add_child(gl)


func _hand(p: Dictionary) -> Vector3:
	var n: Node3D = p["node"]
	return n.global_position + n.global_transform.basis * Vector3(0.18, 1.0, -0.35)


# --------------------------------------------------------------------------- main shots

func _s_coast_start() -> void:
	_set_flash(false)


func _s1(k: float, _t: float) -> void:
	var c := LH + Vector3(3.2, 1.3, 7.8)
	cam_move(k, LH + Vector3(16, 14, 20), c + Vector3(5.0, 0.9, 3.5), LH + Vector3(0, 20, 0), c)


func _set_flash(on: bool) -> void:
	env.adjustment_saturation = 0.45 if on else 0.95
	env.adjustment_contrast = 1.05 if on else 1.1


func _s_field_start() -> void:
	_set_flash(true)
	make_environment(Color(0.35, 0.5, 0.75), Color(0.95, 0.85, 0.65), Color(0.3, 0.28, 0.2), Color(1.0, 0.85, 0.55),
		Color(1.0, 0.95, 0.85), Color(0.7, 0.65, 0.6), 0.35, 0.0, Color(0.9, 0.8, 0.6), 0.003, 0.9)
	_set_flash(true)
	_sun.rotation_degrees = Vector3(-25, 40, 0)
	_sun.light_energy = 1.3
	_engine = loop_sound("generator", -8.0)
	_engine.pitch_scale = 0.8


func _s2(k: float, t: float) -> void:
	_tractor.position = FIELD + Vector3(-30 + k * 22.0, 0, 8)
	for w in _wheels:
		(w[0] as Node3D).rotation.x -= 0.016 * 2.75 / float(w[1])
	_tractor.position.y = sin(t * 9.0) * 0.015
	_drone.position = _tractor.position + Vector3(2.5 + sin(t) * 1.5, 3.5 + sin(t * 1.7) * 0.5, -3.0)
	var tp := _tractor.position
	cam.global_position = tp + Vector3(-5.0 + k * 3.0, 1.7, 7.5)
	cam.look_at(tp + Vector3(1.0, 1.4, 0))


func _s_river_start() -> void:
	if _engine:
		_engine.stop()
	make_environment(Color(0.05, 0.08, 0.18), Color(0.45, 0.4, 0.55), Color(0.05, 0.06, 0.08), Color(0.9, 0.6, 0.5),
		Color(0.4, 0.4, 0.5), Color(0.15, 0.15, 0.22), 0.3, 0.7, Color(0.3, 0.35, 0.45), 0.004, 0.95)
	_set_flash(true)
	_sun.light_color = Color(0.7, 0.75, 1.0)
	_sun.light_energy = 0.85
	_sun.rotation_degrees = Vector3(-35, -60, 0)
	_drone.visible = false
	_controller.global_position = _hand(_young)
	_gift.global_position = _hand(_mermaid) + Vector3(0, 0.0, 0)
	Game.play_sound("splash", RIVER + Vector3(2.6, 0, 1.0), -6.0)


func _s3(k: float, t: float) -> void:
	# fin flicks out of the water now and then
	_fin.position.y = -0.9 + maxf(0.0, sin(t * 1.6)) * 1.0
	_fin.rotation.z = sin(t * 3.0) * 0.4
	var yn: Node3D = _young["node"]
	if k < 0.6:
		yn.position = RIVER + Vector3(-11.0 + k * 7.5, 0, 1.0)
		play(_young, "walk")
	elif not _flags.has("stop"):
		_flags["stop"] = true
		play(_young, "idle")
	_controller.global_position = _hand(_young)
	_gift.global_position = _hand(_mermaid)
	cam_move(k, RIVER + Vector3(-11, 2.0, 6.5), RIVER + Vector3(-7.5, 1.5, 4.2), RIVER + Vector3(-6, 1.0, 1.0), RIVER + Vector3(-4.6, 0.6, 1.0))


func _s4(k: float, t: float) -> void:
	_fin.position.y = -0.9 + maxf(0.0, sin(t * 1.6)) * 0.6
	var a := _hand(_young)
	var b := _hand(_mermaid)
	var mid := (a + b) * 0.5 + Vector3(0, 0.25, 0)
	# the mushroom offered, the controller handed over
	var e := clampf((k - 0.25) / 0.5, 0.0, 1.0)
	_gift.global_position = b.lerp(mid, minf(1.0, e * 2.0)).lerp(a, maxf(0.0, e * 2.0 - 1.0))
	_controller.global_position = a.lerp(mid, minf(1.0, e * 2.0)).lerp(b, maxf(0.0, e * 2.0 - 1.0))
	cam_move(k, RIVER + Vector3(-5.6, 1.5, 3.4), RIVER + Vector3(-5.4, 1.3, 2.7), mid, mid)


func _s5(k: float, t: float) -> void:
	var a := _hand(_young)
	var mouth: Vector3 = _young["node"].global_position + Vector3(0, 1.5, 0)
	if k < 0.3:
		_gift.global_position = a.lerp(mouth, k / 0.3)
	else:
		_gift.visible = false
		if not _flags.has("fall"):
			_flags["fall"] = true
			play(_young, "death", 0.4, 0.7)
			Game.play_sound("cast", null, -4.0, 0.4)
	_warp.set_shader_parameter("amount", clampf((k - 0.3) * 1.6, 0.0, 1.0))
	_warp.set_shader_parameter("white", clampf((k - 0.75) / 0.25, 0.0, 1.0))
	var c: Vector3 = _young["node"].global_position + Vector3(0, 1.0, 0)
	cam.global_position = c + Vector3(-2.5 + sin(t * 0.7), 0.8, 2.0 + cos(t * 0.7))
	cam.look_at(c)


func _s_back_start() -> void:
	_sunset()
	_set_flash(false)
	_sun.light_energy = 0.8
	_sun.rotation_degrees = Vector3(-3, 10, 0)


func _s6(k: float, _t: float) -> void:
	_warp.set_shader_parameter("amount", maxf(0.0, 0.5 - k * 2.0))
	_warp.set_shader_parameter("white", maxf(0.0, 1.0 - k * 3.0))
	var hn: Node3D = _hero["node"]
	var back := hn.global_position + Vector3(0, 1.35, 0) + hn.global_transform.basis.z * 0.3
	var vn: Node3D = _ves["node"]
	if k < 0.5:
		cam_move(k * 2.0, back + hn.global_transform.basis.z * 1.6 + Vector3(0.6, 0.2, 0), back + hn.global_transform.basis.z * 1.1 + Vector3(0.4, 0.1, 0), back, back)
	else:
		var f := vn.global_position + Vector3(0, 1.55, 0)
		cam_move((k - 0.5) * 2.0, f - vn.global_transform.basis.z * 1.6 + Vector3(0.3, 0, 0), f - vn.global_transform.basis.z * 1.2, f, f)


func _s7(k: float, _t: float) -> void:
	var l: OmniLight3D = _grove.get_meta("light")
	l.light_energy = 2.2 + sin(Time.get_ticks_msec() * 0.004) * 0.4
	if not _flags.has("turn"):
		_flags["turn"] = true
		_face(_ves, GROVE)
	cam_move(k, LH + Vector3(-6.0, 2.4, 9.0), GROVE + Vector3(1.5, 1.3, 5.0), LH + Vector3(0, 3, 0), GROVE + Vector3(0, 0.3, 0))


# --------------------------------------------------------------------------- choice

func _show_choice() -> void:
	clear_subtitles()
	set_skippable(false)
	_face(_ves, _hero["node"].position)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_choice_box = HBoxContainer.new()
	_choice_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_choice_box.add_theme_constant_override("separation", 40)
	_choice_box.anchor_left = 0.1
	_choice_box.anchor_right = 0.9
	_choice_box.anchor_top = 0.72
	_choice_box.anchor_bottom = 0.8
	ui_root().add_child(_choice_box)
	for c in [["stay", Loc.t("[1]  Stay in this world")], ["home", Loc.t("[2]  Go home")]]:
		var b := Button.new()
		b.text = c[1]
		b.custom_minimum_size = Vector2(320, 56)
		b.add_theme_font_size_override("font_size", 22)
		b.pressed.connect(choose.bind(c[0]))
		_choice_box.add_child(b)
	_choice_box.modulate.a = 0.0
	_choice_box.create_tween().tween_property(_choice_box, "modulate:a", 1.0, 0.6)
	(_choice_box.get_child(0) as Button).grab_focus()


func _s_choice(_k: float, t: float) -> void:
	var c := LH + Vector3(3.2, 1.3, 7.8)
	cam.global_position = c + Vector3(sin(1.75 + t * 0.03) * 6.5, 0.8, cos(1.75 + t * 0.03) * 6.5)
	cam.look_at(c + Vector3(0, 0.3, 0))


func _input(event: InputEvent) -> void:
	if _choice_box and is_instance_valid(_choice_box) and _shot == _choice_shot and event is InputEventKey and event.pressed:
		if (event as InputEventKey).physical_keycode == KEY_1:
			choose("stay")
		elif (event as InputEventKey).physical_keycode == KEY_2:
			choose("home")


func choose(which: String) -> void:
	if _shot != _choice_shot:
		return
	_choice_box.queue_free()
	_choice_box = null
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	set_skippable(true)
	shots.resize(_choice_shot + 1)
	if which == "stay":
		shots.append({"line": "es_1", "min": 9.0, "start": _stay_start, "update": _stay1})
		shots.append({"line": "es_2", "min": 6.0, "update": _stay2})
	else:
		shots.append({"line": "eh_1", "min": 10.0, "start": _home_start, "update": _home1})
		shots.append({"line": "eh_2", "min": 9.0, "start": _home2_start, "update": _home2})
	shots.append({"min": 30.0, "start": _credits_start, "update": _credits_update})
	advance()


func skip() -> void:
	if _shot < _choice_shot:
		# straight to the choice
		_voice.stop()
		_warp.set_shader_parameter("amount", 0.0)
		_warp.set_shader_parameter("white", 0.0)
		_s_back_start()
		_shot = _choice_shot - 1
		advance()
	elif _shot > _choice_shot:
		_end()


# --------------------------------------------------------------------------- endings

func _stay_start() -> void:
	make_environment(Color(0.03, 0.04, 0.1), Color(0.3, 0.22, 0.35), Color(0.02, 0.02, 0.03), Color(0.9, 0.5, 0.3),
		Color(0.2, 0.18, 0.25), Color(0.06, 0.06, 0.1), 0.35, 0.9, Color(0.15, 0.15, 0.22), 0.004, 0.45)
	_sun.light_energy = 0.15
	_fill.light_energy = 0.3
	for p in [_ves, _hero]:
		_face(p, (p["node"] as Node3D).position + Vector3(0, 0, 10))
	# VesPer's drones with lights over the sea
	for i in 5:
		var d := TechProps.drone_model(self)
		d.scale = Vector3.ONE * 2.0
		var l := OmniLight3D.new()
		l.light_color = [Color(1.0, 0.3, 0.2), Color(0.3, 1.0, 0.4), Color(0.4, 0.6, 1.0)][i % 3]
		l.light_energy = 1.5
		l.omni_range = 5.0
		d.add_child(l)
		_flyers.append([d, i * 1.3])


func _stay1(k: float, t: float) -> void:
	_fly(t)
	var c := LH + Vector3(3.2, 1.2, 7.8)
	cam_move(k, c + Vector3(-6.0, 0.5, 0.5), c + Vector3(-7.0, 4.5, -1.5), c, c + Vector3(0, 6.0, 30.0))


func _stay2(k: float, t: float) -> void:
	_fly(t + 9.0)
	var c := LH + Vector3(3.2, 1.2, 7.8)
	cam_move(k, c + Vector3(4.0, 0.6, -1.0), c + Vector3(5.0, 1.0, -2.5), c + Vector3(0, 0.6, 2.0), c + Vector3(0, 8.0, 25.0))


func _fly(t: float) -> void:
	for f in _flyers:
		var d: Node3D = f[0]
		var ph: float = f[1]
		d.global_position = LH + Vector3(sin(t * 0.4 + ph) * 18.0, 9.0 + sin(t * 0.9 + ph) * 2.0, 22.0 + cos(t * 0.3 + ph) * 8.0)
		for r in d.get_meta("rotors"):
			(r as Node3D).rotation.y += 1.2


func _home_start() -> void:
	play(_hero, "walk")


func _home1(k: float, _t: float) -> void:
	var hn: Node3D = _hero["node"]
	if k < 0.45:
		var a := LH + Vector3(3.4, 0, 9.6)
		var b := GROVE + Vector3(0, 0, 1.4)
		hn.global_position = a.lerp(b, k / 0.45)
		var d := b - a
		hn.rotation.y = atan2(-d.x, -d.z)
		cam.global_position = hn.global_position + Vector3(3.5, 2.0, 4.0)
		cam.look_at(hn.global_position + Vector3(0, 1.2, 0))
	elif k < 0.75:
		if not _flags.has("eat"):
			_flags["eat"] = true
			play(_hero, "crouch", 0.4)
			(_grove.get_meta("big") as Node3D).visible = false
			Game.play_sound("cast", null, -4.0, 0.4)
		_warp.set_shader_parameter("amount", (k - 0.45) / 0.3)
		_warp.set_shader_parameter("white", clampf((k - 0.6) / 0.15, 0.0, 1.0))
	else:
		if not _flags.has("line"):
			_flags["line"] = true
			_build_tree_line()
			hn.global_position = LINE
			hn.rotation.y = 0.5
			var a: String = _hero["anims"]["death"]
			if a != "":
				_hero["anim"].play(a)
				_hero["anim"].seek(_hero["anim"].current_animation_length, true)
				_hero["anim"].pause()
		_warp.set_shader_parameter("amount", maxf(0.0, 1.0 - (k - 0.75) * 6.0))
		_warp.set_shader_parameter("white", maxf(0.0, 1.0 - (k - 0.75) * 5.0))
		cam.global_position = LINE + Vector3(1.0, 3.5, 1.5)
		cam.look_at(LINE + Vector3(0, 0.2, 0))


func _build_tree_line() -> void:
	make_environment(Color(0.12, 0.18, 0.34), Color(0.95, 0.58, 0.38), Color(0.12, 0.1, 0.08), Color(1.0, 0.6, 0.35),
		Color(0.85, 0.6, 0.55), Color(0.35, 0.3, 0.38), 0.55, 0.15, Color(0.55, 0.45, 0.45), 0.005, 0.6)
	env.adjustment_saturation = 0.75
	_sun.light_color = Color(1.0, 0.62, 0.38)
	_sun.light_energy = 0.9
	_sun.rotation_degrees = Vector3(-7, 18, 0)
	MeshKit.box(self, Vector3(300, 0.2, 300), LINE + Vector3(0, -0.1, 0), MeshKit.textured("Grass004", Color(0.42, 0.42, 0.25), 0.25, 0.0, 0.8))
	var c2 := cfg.duplicate()
	c2["foliage"] = [Color(0.1, 0.18, 0.08), Color(0.25, 0.36, 0.14), Color(0.5, 0.55, 0.25)]
	c2["pine_ratio"] = 0.45
	var pts := []
	for i in 140:
		var p := LINE + Vector3(rng.randf_range(-60, 60), 0, rng.randf_range(-70, 50))
		if Vector2(p.x - LINE.x, p.z - LINE.z).length() < 5.0:
			continue
		pts.append(p)
	Nature.plant_trees(self, pts, c2, rng)
	Game.play_sound("artillery", null, -12.0, 0.9)


func _home2_start() -> void:
	var a: String = _hero["anims"]["death"]
	if a != "":
		_hero["anim"].play_backwards(a)
		_hero["anim"].speed_scale = 0.6
	_crystal = Node3D.new()
	add_child(_crystal)
	var cm := MeshKit.mat(Color(0.3, 0.6, 1.0, 0.85), 0.1, 0.2, 2.5)
	cm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var prism := PrismMesh.new()
	prism.size = Vector3(0.05, 0.08, 0.05)
	MeshKit.inst(_crystal, prism, Vector3(0, 0.04, 0), cm)
	MeshKit.inst(_crystal, prism, Vector3(0, -0.04, 0), cm, Vector3(180, 0, 0))
	var l := OmniLight3D.new()
	l.light_color = Color(0.3, 0.6, 1.0)
	l.light_energy = 1.2
	l.omni_range = 1.5
	_crystal.add_child(l)
	_crystal.visible = false
	get_tree().create_timer(4.0).timeout.connect(func() -> void:
		if is_instance_valid(self):
			Game.play_sound("artillery", null, -14.0, 0.85))


func _home2(k: float, t: float) -> void:
	var hn: Node3D = _hero["node"]
	if not _hero["anim"].is_playing() and not _flags.has("up"):
		_flags["up"] = true
		_hero["anim"].speed_scale = 1.0
		play(_hero, "idle", 0.4)
	if k > 0.45:
		_crystal.visible = true
		var fwd := -hn.global_transform.basis.z
		var side := hn.global_transform.basis.x
		_crystal.global_position = hn.global_position + fwd * 0.55 + Vector3(0, 1.25, 0)
		_crystal.rotation.y = t * 1.5
		# in front of him: the crystal close, his face behind it
		var e := (k - 0.45) / 0.55
		cam_move(e, _crystal.global_position + fwd * 1.1 + side * 0.4 + Vector3(0, 0.1, 0), _crystal.global_position + fwd * 0.6 + side * 0.2 + Vector3(0, 0.05, 0),
			_crystal.global_position, _crystal.global_position + Vector3(0, 0.1, 0) - fwd * 0.3)
	else:
		cam_move(k / 0.45, LINE + Vector3(1.0, 3.5, 1.5), LINE + Vector3(2.5, 1.8, 3.0), LINE + Vector3(0, 0.3, 0), hn.global_position + Vector3(0, 1.3, 0))
	if k > 0.7 and not _flags.has("buzz"):
		_flags["buzz"] = true
		var b := loop_sound("drone_buzz", -18.0)
		b.create_tween().tween_property(b, "volume_db", -8.0, 3.0)


# --------------------------------------------------------------------------- credits

func _credits_start() -> void:
	clear_subtitles()
	fade_to(Color(0, 0, 0, 1), 1.5)
	_credits = Control.new()
	_credits.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_credits.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root().add_child(_credits)
	var vb := VBoxContainer.new()
	vb.anchor_left = 0.15
	vb.anchor_right = 0.85
	vb.add_theme_constant_override("separation", 14)
	_credits.add_child(vb)
	var lines := [
		["NORTHVALE", 64, Color(1.0, 0.85, 0.5)],
		[Loc.t("A soldier, a mushroom, and a world that needed both."), 22, Color(0.85, 0.85, 0.8)],
		["", 30, Color.WHITE],
		[Loc.t("Story"), 18, Color(0.85, 0.7, 0.4)], [Loc.t("A soldier from the Ukrainian trenches and VesPerFPV, the farmer who came first"), 22, Color.WHITE],
		["", 20, Color.WHITE],
		[Loc.t("Made with"), 18, Color(0.85, 0.7, 0.4)], ["Godot Engine 4.7", 22, Color.WHITE],
		[Loc.t("Ukrainian voices"), 18, Color(0.85, 0.7, 0.4)], ["Piper TTS  -  oleksa, tetiana, mykyta (rhasspy / piper-voices)", 22, Color.WHITE],
		[Loc.t("English voices"), 18, Color(0.85, 0.7, 0.4)], ["Windows Speech  -  David, Zira", 22, Color.WHITE],
		[Loc.t("3D models"), 18, Color(0.85, 0.7, 0.4)], ["Quaternius (poly.pizza), Poly Haven  -  CC0", 22, Color.WHITE],
		[Loc.t("Textures"), 18, Color(0.85, 0.7, 0.4)], ["ambientCG  -  CC0", 22, Color.WHITE],
		[Loc.t("Sounds"), 18, Color(0.85, 0.7, 0.4)], ["Kenney, OpenGameArt contributors  -  CC0", 22, Color.WHITE],
		[Loc.t("Music"), 18, Color(0.85, 0.7, 0.4)], ["AlkaKrab  -  Fantasy RPG Music Vol. 2\nAndrew Sitkov  -  Music Loops Mini Set", 22, Color.WHITE],
		[Loc.t("Sky and terrain"), 18, Color(0.85, 0.7, 0.4)], ["Sky3D and Terrain3D by Tokisan Games (Cory Petkovsek) and contributors  -  MIT", 22, Color.WHITE],
		[Loc.t("More addons and models"), 18, Color(0.85, 0.7, 0.4)], ["GEQO by marrero171  -  MIT\nMirror3D by Joyless, Norodix  -  MIT\nArming Sword by Vairek  -  CC0\nTextured Glass Material Pack  -  CC0\nGolem, Charcharosaurus and Super Human models from Sketchfab", 22, Color.WHITE],
		["The Milky Way panorama by ESO/S. Brunier, licensed under CC BY 4.0\n(creativecommons.org/licenses/by/4.0), used in original and modified forms.\nMoon map (c) 2019 GPoSM  -  MIT", 18, Color(0.85, 0.85, 0.8)],
		["", 40, Color.WHITE],
		[Loc.t("Thank you for playing"), 34, Color(1.0, 0.9, 0.7)],
	]
	for l in lines:
		var lb := label(int(l[1]), l[2])
		lb.text = l[0]
		lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vb.add_child(lb)
	vb.position.y = get_viewport().get_visible_rect().size.y
	_credits_t = 0.0
	set_skippable(true)


func _credits_update(_k: float, t: float) -> void:
	var vb := _credits.get_child(0) as VBoxContainer
	var h := get_viewport().get_visible_rect().size.y
	vb.position.y = h - t * h / 14.0
	vb.size.x = _credits.size.x * 0.7


func finish() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Game.go_to_menu()


func _process(delta: float) -> void:
	super(delta)
	for i in _rotors.size():
		(_rotors[i] as Node3D).rotation.y += delta * 80.0
