extends Cinematic
## Opening cinematic (new game): dawn on a Ukrainian trench line - sandbags, duckboards, a dugout,
## barbed wire, distant artillery and a drone overhead. The soldier's shift ends, he walks into the
## tree line, finds a grove of glowing mushrooms, eats one, the world bends... and he wakes up in
## a sunny meadow of Northvale with his rifle. Quiet, no gore. Then the game starts.

const TOP := 1.7                       # ground level around the trench (trench floor is y = 0)
const RAMP_X := 10.0
const GROVE := Vector3(14, TOP, -58)
const MEADOW := Vector3(600, 0, 0)     # Northvale, far away from the war set

var _war: Node3D
var _meadow: Node3D
var _hero: Dictionary
var _comrade: Dictionary
var _drone: Node3D
var _rotors: Array = []
var _grove: Node3D
var _warp: ShaderMaterial
var _boom_t := 2.0
var _flash: OmniLight3D
var _flash_mesh: MeshInstance3D
var _wind: AudioStreamPlayer
var _birds: AudioStreamPlayer
var _sun: DirectionalLight3D
var _fill: DirectionalLight3D
var _war_on := true
var _ate := false
var _sat := false
var _fell := false
var _rose := false


func build() -> void:
	Game.stop_music(2.0)
	cfg = (load(Game.LEVELS[0]["script"]).new()).config()
	cfg["foliage"] = [Color(0.1, 0.18, 0.08), Color(0.25, 0.36, 0.14), Color(0.5, 0.55, 0.25)]
	cfg["pine_foliage"] = [Color(0.06, 0.14, 0.07), Color(0.14, 0.25, 0.1), Color(0.3, 0.4, 0.18)]
	cfg["pine_ratio"] = 0.45
	_dawn()
	_war = Node3D.new()
	add_child(_war)
	_build_trench()
	_build_no_mans_land()
	_build_forest()
	_hero = soldier(Vector3(2.0, 0, 0.45), PI)
	play(_hero, "idle")
	_comrade = soldier(Vector3(-4.5, 0, -0.55), PI, false)
	pose_end(_comrade, "sit_down")
	(_comrade["node"] as Node3D).position.y = -0.42
	_drone = TechProps.drone_model(self)
	_drone.scale = Vector3.ONE * 2.0
	_rotors = _drone.get_meta("rotors")
	_drone.position = Vector3(-80, 30, 20)
	TechProps.loop_sound(_drone, "drone_buzz", 4.0, 120.0)
	_wind = loop_sound("amb_wind", -14.0)
	_warp = warp_overlay()
	_plan()


# --------------------------------------------------------------------------- set

func _dawn() -> void:
	make_environment(Color(0.12, 0.18, 0.34), Color(0.95, 0.58, 0.38), Color(0.12, 0.1, 0.08), Color(1.0, 0.6, 0.35),
		Color(0.85, 0.6, 0.55), Color(0.35, 0.3, 0.38), 0.55, 0.15, Color(0.55, 0.45, 0.45), 0.0045, 0.6)
	env.adjustment_saturation = 0.75
	_sun = sun(Color(1.0, 0.62, 0.38), 0.9, Vector3(-7, 18, 0))
	_fill = sun(Color(0.45, 0.55, 0.85), 0.25, Vector3(-50, 200, 0), false)


func _build_trench() -> void:
	var mud := MeshKit.textured("Ground037", Color(0.55, 0.45, 0.35), 0.35, 0.0, 0.75)
	var earth := MeshKit.textured("Ground048", Color(0.5, 0.42, 0.32), 0.4, 0.0, 0.7)
	var planks := MeshKit.textured("Planks021", Color(0.62, 0.5, 0.38), 0.8, 0.0, 0.7)
	var post := MeshKit.mat(Color(0.28, 0.2, 0.13), 0.95)
	# ground: front, rear (with a gap for the exit ramp) and the trench floor
	MeshKit.box(_war, Vector3(500, 0.2, 250), Vector3(0, TOP - 0.1, 126), earth)
	MeshKit.box(_war, Vector3(240, 0.2, 2.6), Vector3(RAMP_X - 1.0 - 120.0, TOP - 0.1, -2.3), earth)
	MeshKit.box(_war, Vector3(240, 0.2, 2.6), Vector3(RAMP_X + 1.0 + 120.0, TOP - 0.1, -2.3), earth)
	MeshKit.box(_war, Vector3(500, 0.2, 250), Vector3(0, TOP - 0.1, -128.6), MeshKit.textured("Grass004", Color(0.42, 0.42, 0.25), 0.25, 0.0, 0.8))
	MeshKit.box(_war, Vector3(64, 0.1, 2.0), Vector3(0, -0.05, 0), mud)
	# walls with plank revetment and posts
	for side in [-1.0, 1.0]:
		var z: float = side * 1.0
		if side < 0.0:
			MeshKit.box(_war, Vector3(RAMP_X - 1.0 + 32.0, TOP, 0.3), Vector3((RAMP_X - 1.0 - 32.0) * 0.5, TOP * 0.5, z - 0.15), earth)
			MeshKit.box(_war, Vector3(32.0 - RAMP_X - 1.0, TOP, 0.3), Vector3((RAMP_X + 1.0 + 32.0) * 0.5, TOP * 0.5, z - 0.15), earth)
		else:
			MeshKit.box(_war, Vector3(64, TOP, 0.3), Vector3(0, TOP * 0.5, z + 0.15), earth)
		var y := 0.15
		while y < TOP - 0.1:
			if side < 0.0:
				MeshKit.box(_war, Vector3(RAMP_X - 1.2 + 30.0, 0.18, 0.04), Vector3((RAMP_X - 1.2 - 30.0) * 0.5, y, z + 0.02), planks)
				MeshKit.box(_war, Vector3(30.0 - RAMP_X - 1.2, 0.18, 0.04), Vector3((RAMP_X + 1.2 + 30.0) * 0.5, y, z + 0.02), planks)
			else:
				MeshKit.box(_war, Vector3(60, 0.18, 0.04), Vector3(0, y, z - 0.02), planks)
			y += 0.21
		var x := -29.0
		while x < 30.0:
			if absf(x - RAMP_X) > 1.3:
				MeshKit.cyl(_war, 0.06, 0.07, TOP + 0.3, Vector3(x + rng.randf_range(-0.2, 0.2), (TOP + 0.3) * 0.5, z - side * 0.06), post, Vector3(side * 4.0, 0, 0), 6)
			x += 2.1
	for ex in [-32.0, 32.0]:
		MeshKit.box(_war, Vector3(0.3, TOP, 2.3), Vector3(ex, TOP * 0.5, 0), earth)
	# duckboards
	var x2 := -29.5
	while x2 < 29.5:
		MeshKit.box(_war, Vector3(0.12, 0.05, 0.9), Vector3(x2, 0.04, 0), planks, Vector3(0, rng.randf_range(-3, 3), 0))
		x2 += 0.22
	MeshKit.box(_war, Vector3(60, 0.06, 0.08), Vector3(0, 0.01, -0.35), post)
	MeshKit.box(_war, Vector3(60, 0.06, 0.08), Vector3(0, 0.01, 0.35), post)
	# exit ramp at the back
	var ramp_len := sqrt(2.6 * 2.6 + TOP * TOP)
	MeshKit.box(_war, Vector3(1.9, 0.12, ramp_len), Vector3(RAMP_X, TOP * 0.5 - 0.05, -2.3), mud, Vector3(rad_to_deg(atan2(TOP, 2.6)), 0, 0))
	for sx in [-1.0, 1.0]:
		MeshKit.box(_war, Vector3(0.3, TOP, 2.6), Vector3(RAMP_X + sx * 1.1, TOP * 0.5, -2.3), earth)
	for i in 5:
		MeshKit.box(_war, Vector3(1.7, 0.06, 0.1), Vector3(RAMP_X, i * 0.34 + 0.05, -1.1 - i * 0.52), post)
	_sandbags()
	_dugout(Vector3(-8.0, 0, -0.84))
	# bits of trench life
	Props.crate(self, Vector3(4.5, 0, -0.6), 10.0)
	MeshKit.box(_war, Vector3(0.45, 0.25, 0.3), Vector3(-1.5, 0.15, -0.65), MeshKit.mat(Color(0.25, 0.3, 0.2), 0.8))
	MeshKit.box(_war, Vector3(0.45, 0.25, 0.3), Vector3(-1.5, 0.4, -0.65), MeshKit.mat(Color(0.25, 0.3, 0.2), 0.8))
	MeshKit.cyl(_war, 0.05, 0.05, 0.1, Vector3(-1.4, 0.58, -0.6), MeshKit.mat(Color(0.8, 0.8, 0.78), 0.4), Vector3.ZERO, 10)


func _sandbags() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var bag := SphereMesh.new()
	bag.radius = 0.5
	bag.height = 1.0
	bag.radial_segments = 10
	bag.rings = 5
	mm.mesh = bag
	var xs: Array = []
	for side in [-1.0, 1.0]:
		for layer in 3:
			var x := -30.0 + layer * 0.2
			while x < 30.0:
				if side > 0.0 or absf(x - RAMP_X) > 1.4:
					xs.append(Transform3D(Basis(Vector3.UP, rng.randf_range(-0.12, 0.12)).scaled(Vector3(0.5, 0.16, 0.3)),
						Vector3(x, TOP + 0.07 + layer * 0.14, side * (1.25 - layer * 0.04))))
				x += 0.46
	mm.instance_count = xs.size()
	for i in xs.size():
		mm.set_instance_transform(i, xs[i])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = MeshKit.textured("Ground048", Color(0.72, 0.64, 0.48), 1.6, 0.25, 0.85)
	_war.add_child(mi)


func _dugout(p: Vector3) -> void:
	var timber := MeshKit.mat(Color(0.25, 0.18, 0.12), 0.95)
	for sx in [-0.7, 0.7]:
		MeshKit.cyl(_war, 0.09, 0.1, 1.9, p + Vector3(sx, 0.95, 0), timber, Vector3.ZERO, 7)
	MeshKit.cyl(_war, 0.1, 0.1, 1.8, p + Vector3(0, 1.85, 0), timber, Vector3(0, 0, 90), 7)
	MeshKit.box(_war, Vector3(1.3, 1.75, 0.04), p + Vector3(0, 0.88, -0.02), MeshKit.mat(Color(0.03, 0.03, 0.03)))
	var tarp := MeshKit.mat(Color(0.22, 0.26, 0.17), 0.95)
	MeshKit.box(_war, Vector3(0.6, 1.6, 0.03), p + Vector3(-0.32, 0.95, 0.05), tarp, Vector3(0, 0, 3))
	# a small stove with tea
	var iron := MeshKit.mat(Color(0.12, 0.12, 0.12), 0.6, 0.5)
	MeshKit.cyl(_war, 0.16, 0.18, 0.4, p + Vector3(1.2, 0.2, 0.25), iron, Vector3.ZERO, 10)
	MeshKit.cyl(_war, 0.03, 0.03, 1.8, p + Vector3(1.2, 1.2, 0.15), iron, Vector3.ZERO, 6)
	MeshKit.cyl(_war, 0.09, 0.11, 0.14, p + Vector3(1.2, 0.47, 0.25), MeshKit.mat(Color(0.5, 0.5, 0.52), 0.35, 0.8), Vector3.ZERO, 10)
	MeshKit.box(_war, Vector3(0.1, 0.06, 0.02), p + Vector3(1.2, 0.18, 0.43), MeshKit.mat(Color(1.0, 0.45, 0.1), 0.5, 0.0, 4.0))
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.55, 0.25)
	l.light_energy = 0.8
	l.omni_range = 2.5
	l.position = p + Vector3(1.2, 0.3, 0.6)
	_war.add_child(l)
	flicker_lights.append([l, 0.8])


func _build_no_mans_land() -> void:
	var steel := MeshKit.mat(Color(0.35, 0.33, 0.3), 0.6, 0.7)
	var wood := MeshKit.mat(Color(0.3, 0.24, 0.17), 0.95)
	# barbed wire: X-shaped stakes and a concertina coil
	var x := -34.0
	while x < 34.0:
		for a in [25.0, -25.0]:
			MeshKit.cyl(_war, 0.03, 0.03, 1.4, Vector3(x, TOP + 0.5, 9.0), wood, Vector3(0, 0, a), 5)
		x += 3.0
	var ring := TorusMesh.new()
	ring.inner_radius = 0.42
	ring.outer_radius = 0.44
	ring.rings = 14
	ring.ring_segments = 3
	x = -34.0
	while x < 34.0:
		MeshKit.inst(_war, ring, Vector3(x, TOP + 0.45, 9.0 + sin(x) * 0.1), steel, Vector3(0, 0, 90 + rng.randf_range(-12, 12)))
		x += 0.35
	# shell craters
	var crater := MeshKit.textured("Ground037", Color(0.3, 0.25, 0.2), 0.5, 0.0, 0.6)
	for i in 26:
		var p := Vector3(rng.randf_range(-60, 60), TOP, rng.randf_range(5, 90))
		var r := rng.randf_range(1.2, 3.5)
		MeshKit.cyl(_war, r, r * 1.25, 0.25, p + Vector3(0, 0.02, 0), crater, Vector3.ZERO, 16)
		MeshKit.cyl(_war, r * 0.75, r * 0.9, 0.1, p + Vector3(0, 0.1, 0), MeshKit.mat(Color(0.08, 0.07, 0.06), 1.0), Vector3.ZERO, 14)
	# shattered trees between the line and the forest
	var bark := MeshKit.mat(Color(0.18, 0.14, 0.1), 1.0)
	for i in 24:
		var p := Vector3(rng.randf_range(-50, 50), TOP, rng.randf_range(-20, -6) if i % 2 == 0 else rng.randf_range(12, 60))
		if absf(p.x - RAMP_X) < 4.0 and p.z < 0.0:
			continue
		var h := rng.randf_range(1.5, 5.0)
		MeshKit.cyl(_war, 0.08, rng.randf_range(0.15, 0.3), h, p + Vector3(0, h * 0.5, 0), bark, Vector3(rng.randf_range(-8, 8), 0, rng.randf_range(-8, 8)), 6)
	# smoke on the horizon
	for i in 4:
		var sm := CPUParticles3D.new()
		var s := SphereMesh.new()
		s.radius = 3.0
		s.height = 6.0
		s.radial_segments = 6
		s.rings = 3
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.25, 0.23, 0.22, 0.25)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		s.material = m
		sm.mesh = s
		sm.amount = 18
		sm.lifetime = 14.0
		sm.direction = Vector3.UP
		sm.spread = 10.0
		sm.gravity = Vector3(1.0, 1.2, 0)
		sm.initial_velocity_min = 2.0
		sm.initial_velocity_max = 3.0
		sm.scale_amount_min = 1.0
		sm.scale_amount_max = 4.0
		sm.preprocess = 14.0
		sm.position = Vector3(-120 + i * 85 + rng.randf_range(-20, 20), TOP, rng.randf_range(160, 260))
		_war.add_child(sm)
	# artillery flash far away
	_flash = OmniLight3D.new()
	_flash.light_color = Color(1.0, 0.65, 0.35)
	_flash.omni_range = 260.0
	_flash.light_energy = 0.0
	_flash.position = Vector3(40, 30, 220)
	_war.add_child(_flash)
	var fm := SphereMesh.new()
	fm.radius = 6.0
	fm.height = 12.0
	_flash_mesh = MeshKit.inst(_war, fm, Vector3(40, TOP + 2, 230), MeshKit.glow(Color(1.0, 0.6, 0.3, 0.8)))
	_flash_mesh.visible = false


func _build_forest() -> void:
	var pts := []
	for i in 260:
		var p := Vector3(rng.randf_range(-90, 90), TOP, rng.randf_range(-130, -22))
		var to_path := absf(p.x - lerpf(RAMP_X + 1.0, GROVE.x, clampf((-p.z - 9.0) / 49.0, 0.0, 1.0)))
		if to_path < 3.5 and p.z > GROVE.z - 4.0:
			continue
		if Vector2(p.x - GROVE.x, p.z - GROVE.z).length() < 7.0:
			continue
		pts.append(p)
	Nature.plant_trees(_war, pts, cfg, rng)
	# undergrowth and the light between the trees
	var fern := MeshKit.mat(Color(0.18, 0.26, 0.1), 0.9)
	for i in 120:
		var p := Vector3(rng.randf_range(-40, 40), TOP, rng.randf_range(-90, -18))
		if Vector2(p.x - GROVE.x, p.z - GROVE.z).length() < 2.5:
			continue
		MeshKit.sphere(_war, rng.randf_range(0.25, 0.6), p + Vector3(0, 0.1, 0), fern, Vector3(1.0, 0.5, 1.0))
	_grove = mushrooms(GROVE, 22)
	var shaft := MeshKit.glow(Color(0.5, 0.8, 1.0, 0.018))
	for i in 3:
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.25
		cyl.bottom_radius = 2.0
		cyl.height = 16.0
		MeshKit.inst(_war, cyl, GROVE + Vector3(i - 1.0, 8.0, i * 0.7 - 0.7), shaft, Vector3(8 - i * 6, 0, 10 - i * 7))


func _build_meadow() -> void:
	_meadow = Node3D.new()
	add_child(_meadow)
	var nv: Dictionary = (load(Game.LEVELS[0]["script"]).new()).config()
	MeshKit.box(_meadow, Vector3(300, 0.2, 300), MEADOW + Vector3(0, -0.1, 0), MeshKit.textured("Grass004", Color(0.75, 0.85, 0.45), 0.22, 0.0, 1.0))
	var pts := []
	for i in 90:
		var a := rng.randf() * TAU
		var r := rng.randf_range(16.0, 90.0)
		pts.append(MEADOW + Vector3(cos(a) * r, 0, sin(a) * r))
	Nature.plant_trees(_meadow, pts, nv, rng)
	var cols := [Color(0.95, 0.85, 0.2), Color(0.9, 0.3, 0.35), Color(0.95, 0.95, 0.95), Color(0.55, 0.45, 0.95)]
	var stem := MeshKit.mat(Color(0.25, 0.5, 0.15))
	for i in 220:
		var p := MEADOW + Vector3(rng.randf_range(-14, 14), 0, rng.randf_range(-14, 14))
		MeshKit.cyl(_meadow, 0.006, 0.008, 0.22, p + Vector3(0, 0.11, 0), stem, Vector3.ZERO, 4)
		MeshKit.sphere(_meadow, 0.035, p + Vector3(0, 0.23, 0), MeshKit.mat(cols[i % cols.size()], 0.6), Vector3(1, 0.5, 1))
	for i in 40:
		var p := MEADOW + Vector3(rng.randf_range(-14, 14), 0, rng.randf_range(-14, 14))
		MeshKit.sphere(_meadow, rng.randf_range(0.2, 0.45), p, MeshKit.mat(Color(0.3, 0.5, 0.15)), Vector3(1, 0.6, 1))
	# the abbey on a far hill
	Buildings.house(self, MEADOW + Vector3(-30, 0, -60), 20, Vector3(9, 6, 7), Color(0.5, 0.3, 0.25))
	VBuild.watchtower(self, MEADOW + Vector3(-22, 0, -66), 0)


# --------------------------------------------------------------------------- shots

func _plan() -> void:
	shots = [
		{"line": "in_1", "min": 7.0, "start": _s1_start, "update": _s1},
		{"line": "in_2", "min": 7.5, "start": _s2_start, "update": _s2},
		{"line": "in_3", "min": 12.0, "start": _s3_start, "update": _s3},
		{"line": "in_4", "min": 9.0, "start": _s4_start, "update": _s4},
		{"line": "in_5", "min": 9.5, "start": _s3_start, "update": _grove_shot},
		{"line": "in_6", "min": 6.5, "start": _start_warp, "update": _warp_shot},
		{"line": "in_7", "min": 8.0, "start": _start_meadow, "update": _meadow_shot},
	]


func _s1_start() -> void:
	show_title(Loc.t("Somewhere in Ukraine"), 2.5)


func _s1(k: float, _t: float) -> void:
	cam_move(k, Vector3(-28, 9, -11), Vector3(-15, 5.5, -7.5), Vector3(4, 1.5, 8), Vector3(6, 1.0, 5))


func _s2_start() -> void:
	_drone.position = Vector3(-60, 26, 14)


func _s2(k: float, t: float) -> void:
	cam_move(k, Vector3(-1.6, 1.15, -0.55), Vector3(-0.3, 1.25, -0.5), Vector3(3.5, 1.6, 0.9), Vector3(3.0, 1.7, 1.0))
	_drone.position = Vector3(-60 + t * 13.0, 26, 14 - t * 1.0)


func _s3_start() -> void:
	play(_hero, "walk")


func _s3(k: float, _t: float) -> void:
	var hero_n: Node3D = _hero["node"]
	_walk_path(hero_n, [Vector3(2, 0, 0.45), Vector3(9.6, 0, 0.1), Vector3(RAMP_X, 0, -1.0), Vector3(RAMP_X, TOP, -3.6), Vector3(RAMP_X + 0.6, TOP, -11)], k)
	if k < 0.02:
		cam.global_position = Vector3(-1.0, 1.3, -0.4)
	cam.global_position = cam.global_position.lerp(Vector3(RAMP_X + 3.2, TOP + 1.8, -6.5), 0.02)
	cam.look_at(hero_n.global_position + Vector3(0, 1.3, 0))


func _s4_start() -> void:
	_wind.volume_db = -22.0
	_war_on = false


func _s4(k: float, _t: float) -> void:
	var hero_n: Node3D = _hero["node"]
	_walk_path(hero_n, [Vector3(12.0, TOP, -32), Vector3(13.2, TOP, -42), Vector3(GROVE.x, TOP, -51)], k)
	var hp := hero_n.global_position
	cam.global_position = hp + Vector3(-3.6, 1.7, 2.6).rotated(Vector3.UP, k * 0.5)
	cam.look_at(hp + Vector3(0.5, 1.3, -3.0))

## Walks a node along a polyline (k = 0..1 by length), facing the way it goes.
func _walk_path(n: Node3D, pts: Array, k: float) -> void:
	var total := 0.0
	for i in range(1, pts.size()):
		total += (pts[i] as Vector3).distance_to(pts[i - 1])
	var d := total * k
	for i in range(1, pts.size()):
		var a: Vector3 = pts[i - 1]
		var b: Vector3 = pts[i]
		var seg := a.distance_to(b)
		if d <= seg or i == pts.size() - 1:
			n.global_position = a.lerp(b, clampf(d / maxf(seg, 0.001), 0.0, 1.0))
			var dir := b - a
			dir.y = 0.0
			if dir.length() > 0.01:
				n.rotation.y = lerp_angle(n.rotation.y, atan2(-dir.x, -dir.z), 0.15)
			return
		d -= seg


func _grove_shot(k: float, _t: float) -> void:
	var hero_n: Node3D = _hero["node"]
	var big: Node3D = _grove.get_meta("big")
	var stop := GROVE + Vector3(0, 0, 1.3)
	if k < 0.3:
		_walk_path(hero_n, [Vector3(GROVE.x, TOP, -51), Vector3(GROVE.x, TOP, -53), stop], k / 0.3)
	elif not _sat:
		_sat = true
		play(_hero, "crouch", 0.5)
		hero_n.position = stop + Vector3(0, 0, 0.2)
	if k > 0.55 and not _ate:
		# picks the big one and eats it
		var head := hero_n.global_position + Vector3(0, 1.0, -0.15)
		big.global_position = big.global_position.lerp(head, 0.06)
		if big.global_position.distance_to(head) < 0.12 or k > 0.85:
			_ate = true
			big.visible = false
			Game.play_sound("drink", null, -6.0, 0.8)
	var l: OmniLight3D = _grove.get_meta("light")
	l.light_energy = 2.2 + sin(Time.get_ticks_msec() * 0.004) * 0.4
	cam_move(k, GROVE + Vector3(2.2, 0.45, -1.6), GROVE + Vector3(1.4, 0.75, -1.4), GROVE + Vector3(0, 0.3, 0), hero_n.global_position + Vector3(0, 0.9, 0))


func _start_warp() -> void:
	Game.play_sound("cast", null, -2.0, 0.4)
	Game.play_sound("blink", null, -6.0, 0.5)
	var tw := create_tween()
	tw.tween_property(_wind, "volume_db", -40.0, 4.0)


func _warp_shot(k: float, t: float) -> void:
	var hero_n: Node3D = _hero["node"]
	_warp.set_shader_parameter("amount", clampf(k * 1.4, 0.0, 1.0))
	_warp.set_shader_parameter("white", clampf((k - 0.7) / 0.3, 0.0, 1.0))
	if k > 0.25 and not _fell:
		_fell = true
		play(_hero, "death", 0.4, 0.7)
	var c := hero_n.global_position + Vector3(0, 0.8, 0)
	cam.fov = lerpf(55.0, 105.0, k * k)
	cam.global_position = c + Vector3(sin(t * 0.8) * 2.4, 1.4 + k * 2.0, cos(t * 0.8) * 2.4)
	cam.look_at(c)
	cam.rotate_object_local(Vector3.FORWARD, k * k * 2.2)


func _start_meadow() -> void:
	_build_meadow()
	_war.visible = false
	_drone.visible = false
	cam.fov = 55.0
	make_environment(Color(0.25, 0.48, 0.9), Color(0.8, 0.88, 0.96), Color(0.3, 0.33, 0.3), Color(1.0, 0.9, 0.7),
		Color(1.0, 0.98, 0.95), Color(0.65, 0.7, 0.82), 0.4, 0.0, Color(0.75, 0.82, 0.92), 0.004, 1.0)
	env.adjustment_saturation = 1.1
	_sun.light_color = Color(1.0, 0.95, 0.85)
	_sun.light_energy = 1.4
	_sun.rotation_degrees = Vector3(-50, -30, 0)
	_fill.light_energy = 0.3
	var hero_n: Node3D = _hero["node"]
	hero_n.global_position = MEADOW
	hero_n.rotation.y = 0.6
	# lying where he fell (last frame of the fall)
	var a: String = _hero["anims"]["death"]
	if a != "":
		_hero["anim"].play(a)
		_hero["anim"].seek(_hero["anim"].current_animation_length, true)
		_hero["anim"].pause()
	_birds = loop_sound("amb_forest", -12.0)
	Game.play_music("rpg/light_ambient_1", 3.0)
	Game.play_sound("heal", null, -10.0, 0.7)


func _meadow_shot(k: float, _t: float) -> void:
	var hero_n: Node3D = _hero["node"]
	_warp.set_shader_parameter("amount", maxf(0.0, 0.6 - k * 3.0))
	_warp.set_shader_parameter("white", maxf(0.0, 1.0 - k * 3.5))
	if k > 0.35 and not _rose:
		_rose = true
		var a: String = _hero["anims"]["death"]
		if a != "":
			_hero["anim"].play_backwards(a)
			_hero["anim"].speed_scale = 0.6
	if _rose and not _hero["anim"].is_playing():
		_hero["anim"].speed_scale = 1.0
		play(_hero, "idle", 0.4)
	var c := hero_n.global_position
	cam_move(k, c + Vector3(0.6, 4.5, 1.2), c + Vector3(3.2, 1.7, 3.6), c + Vector3(0, 0.2, 0), c + Vector3(-2.0, 1.2, -4.0))
	if k > 0.6:
		show_title_once()


var _titled := false


func show_title_once() -> void:
	if _titled:
		return
	_titled = true
	show_title(Loc.t("NORTHVALE"), 2.0)


func _process(delta: float) -> void:
	super(delta)
	for i in _rotors.size():
		(_rotors[i] as Node3D).rotation.y += delta * 80.0
	for fl in flicker_lights:
		var l: OmniLight3D = fl[0]
		l.light_energy = float(fl[1]) * (0.8 + randf() * 0.4)
	# distant artillery: a flash on the horizon, the boom a few seconds later
	if _war_on and _war.visible:
		_boom_t -= delta
		if _boom_t <= 0.0:
			_boom_t = rng.randf_range(5.0, 9.0)
			_flash.position.x = rng.randf_range(-150, 150)
			_flash_mesh.position = Vector3(_flash.position.x, TOP + 1.0, 240)
			var tw := create_tween()
			tw.tween_callback(func() -> void: _flash_mesh.visible = true)
			tw.tween_property(_flash, "light_energy", 1.4, 0.06)
			tw.tween_property(_flash, "light_energy", 0.0, 0.5)
			tw.tween_callback(func() -> void: _flash_mesh.visible = false)
			get_tree().create_timer(rng.randf_range(1.5, 2.5)).timeout.connect(func() -> void:
				if is_instance_valid(self) and _war.visible:
					Game.play_sound("artillery", null, -10.0, rng.randf_range(0.8, 1.0)))


func skip() -> void:
	_end()


func finish() -> void:
	Game.begin_first_level()
