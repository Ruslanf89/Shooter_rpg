class_name MenuScene
extends Node3D
## Live 3D background for the main menu: a village at dusk in the style of the last played
## location (sky, fog, ground, trees), lanterns flickering, a villager at the well, the dead
## shambling out of the treeline, and a slow drifting camera.
## Provides the small part of the world API that Props / Buildings / Nature use.

var cfg: Dictionary
var fire_lights: Array[OmniLight3D] = []
var flicker_lights: Array = []
var spinners: Array = []
var homes: Array = []
var building_areas: Array = []
var lamp_mult := 1.8
var _cam: Camera3D
var _t := 0.0
var _walkers: Array = []     # [Node3D, start, end, speed]
var _rng := RandomNumberGenerator.new()


func ground(_x: float, _z: float) -> float:
	return 0.0


func _ready() -> void:
	_rng.seed = 7
	var info: Dictionary = SaveGame.peek()
	var li := clampi(int(info.get("level_index", 0)), 0, Game.LEVELS.size() - 1)
	cfg = (load(Game.LEVELS[li]["script"]).new()).config()
	_build_environment()
	_build_ground()
	_build_village()
	_build_forest()
	_build_people()
	_cam = Camera3D.new()
	_cam.fov = 58.0
	_cam.far = 400.0
	add_child(_cam)
	_cam.current = true


func _build_environment() -> void:
	var sky_cfg: Dictionary = cfg["sky"]
	var sky_mat := ShaderMaterial.new()
	sky_mat.shader = load("res://shaders/sky.gdshader")
	sky_mat.set_shader_parameter("top_color", Color(0.03, 0.035, 0.07))
	sky_mat.set_shader_parameter("horizon_color", (sky_cfg.get("horizon_color", Color(0.7, 0.75, 0.9)) as Color).lerp(Color(0.45, 0.18, 0.12), 0.55).darkened(0.35))
	sky_mat.set_shader_parameter("ground_color", Color(0.02, 0.02, 0.03))
	sky_mat.set_shader_parameter("cloud_color", Color(0.18, 0.12, 0.14))
	sky_mat.set_shader_parameter("cloud_shadow", Color(0.05, 0.05, 0.08))
	sky_mat.set_shader_parameter("cloud_cover", 0.6)
	sky_mat.set_shader_parameter("sun_glow", Color(0.9, 0.35, 0.2))
	sky_mat.set_shader_parameter("night", 0.75)
	sky_mat.set_shader_parameter("moon_dir", Vector3(-0.4, 0.35, -0.85))
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.1
	env.fog_enabled = true
	env.fog_light_color = Color(0.12, 0.1, 0.13)
	env.fog_density = 0.009
	env.fog_aerial_perspective = 0.4
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.012
	env.volumetric_fog_albedo = Color(0.35, 0.3, 0.35)
	env.glow_enabled = true
	env.glow_intensity = 1.1
	env.glow_bloom = 0.15
	env.adjustment_enabled = true
	env.adjustment_saturation = 0.75
	env.adjustment_contrast = 1.15
	env.ssao_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.6, 0.68, 1.0)
	moon.light_energy = 0.35
	moon.rotation_degrees = Vector3(-28, 160, 0)
	moon.shadow_enabled = true
	add_child(moon)
	var dusk := DirectionalLight3D.new()
	dusk.light_color = Color(1.0, 0.4, 0.2)
	dusk.light_energy = 0.25
	dusk.rotation_degrees = Vector3(-6, -20, 0)
	add_child(dusk)


func _build_ground() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(500, 500)
	var tex: String = cfg.get("grass_tex", "Grass004")
	var tint: Vector3 = cfg.get("grass_tint", Vector3(1, 1, 0.6))
	var m := MeshKit.textured(tex, Color(tint.x * 0.55, tint.y * 0.55, tint.z * 0.55), 0.22, 0.0, 1.0)
	MeshKit.inst(self, plane, Vector3.ZERO, m)
	var road := MeshKit.textured("Ground048", Color(0.7, 0.6, 0.5), 0.3, 0.0, 0.8)
	MeshKit.box(self, Vector3(4.0, 0.02, 120.0), Vector3(0, 0.01, 30.0), road)
	MeshKit.box(self, Vector3(60.0, 0.02, 3.0), Vector3(0, 0.012, -2.0), road)
	var square := MeshKit.textured("PavingStones070", Color(0.9, 0.88, 0.82), 0.33, 0.0, 0.85)
	MeshKit.cyl(self, 9.0, 9.0, 0.04, Vector3(0, 0.02, -2), square, Vector3.ZERO, 32)


func _build_village() -> void:
	VBuild.well(self, Vector3(0, 0, -2))
	Buildings.house(self, Vector3(-14, 0, -10), 60, Vector3(7, 4, 5.5), Color(0.6, 0.3, 0.22))
	Buildings.house(self, Vector3(13, 0, -12), -55, Vector3(6.5, 4, 5), Color(0.45, 0.45, 0.55))
	Buildings.house(self, Vector3(-16, 0, 10), 120, Vector3(6, 4, 5), Color(0.5, 0.4, 0.35))
	VBuild.tavern(self, Vector3(16, 0, 9), -120)
	VBuild.watchtower(self, Vector3(-8, 0, -24), 20)
	VBuild.market_stall(self, Vector3(5, 0, 3), -30, Color(0.6, 0.15, 0.12), _rng)
	VBuild.cart(self, Vector3(-5, 0, 5), 70)
	for p in [Vector3(-6, 0, -7), Vector3(6, 0, -7), Vector3(-3, 0, 14), Vector3(3, 0, 26)]:
		VBuild.lamp_post(self, p)
	Props.fence(self, Vector3(-24, 0, 18), Vector3(-6, 0, 32))
	Props.fence(self, Vector3(6, 0, 32), Vector3(24, 0, 18))
	Props.campfire(self, Vector3(8, 0, 18))
	for i in 3:
		Props.tombstone(self, Vector3(-20 + i * 2.2, 0, 26 + i * 0.6), _rng.randf_range(-20, 20), _rng)


func _build_forest() -> void:
	var pts := []
	for i in 140:
		var a := _rng.randf() * TAU
		var r := _rng.randf_range(32.0, 110.0)
		var p := Vector3(cos(a) * r, 0, sin(a) * r)
		if absf(p.x) < 6.0 and p.z > 0.0:
			continue
		pts.append(p)
	Nature.plant_trees(self, pts, cfg, _rng)


func _build_people() -> void:
	# a villager by the well with a lantern glow
	var v := Node3D.new()
	add_child(v)
	v.position = Vector3(1.8, 0, -0.5)
	v.rotation.y = 2.4
	People.build(v, "people/farmer", People.random_colors("people/farmer", _rng), 1.62)
	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.7, 0.4)
	glow.light_energy = 1.6
	glow.omni_range = 6.0
	glow.position = Vector3(0.4, 1.1, -0.3)
	v.add_child(glow)
	flicker_lights.append([glow, glow.light_energy])
	# the dead coming out of the forest
	var files := ["zombie", "skeleton", "zombie", "zombie"]
	for i in files.size():
		var path := "res://assets/models/%s.glb" % files[i]
		if not ResourceLoader.exists(path):
			continue
		var w := Node3D.new()
		add_child(w)
		var model: Node3D = (load(path) as PackedScene).instantiate()
		w.add_child(model)
		model.rotation.y = PI
		var anim := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
		var walk := People.find_anim(anim, ["Walk", "Skeleton_Walking", "Skeleton_Running", "Run"])
		if walk != "":
			anim.get_animation(walk).loop_mode = Animation.LOOP_LINEAR
			anim.play(walk)
			anim.speed_scale = 0.6
			anim.seek(randf(), true)
		var x := -10.0 + i * 6.5
		var start := Vector3(x, 0, 62 + i * 4.0)
		var end := Vector3(x * 0.5, 0, 24.0)
		w.position = start
		w.look_at(end)
		for s in [-1.0, 1.0]:
			var eye := OmniLight3D.new()
			eye.light_color = Color(1.0, 0.1, 0.05)
			eye.light_energy = 0.5
			eye.omni_range = 0.6
			eye.position = Vector3(s * 0.05, 1.6, -0.15)
			w.add_child(eye)
		_walkers.append([w, start, end, randf_range(0.35, 0.55)])
	# embers drifting through the village
	var em := CPUParticles3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.03
	sm.height = 0.06
	sm.radial_segments = 4
	sm.rings = 2
	sm.material = MeshKit.unshaded(Color(1.0, 0.5, 0.15))
	em.mesh = sm
	em.amount = 120
	em.lifetime = 9.0
	em.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	em.emission_box_extents = Vector3(25, 1, 25)
	em.position = Vector3(0, 0.5, 8)
	em.direction = Vector3(0.3, 1, 0)
	em.spread = 30.0
	em.gravity = Vector3(0.2, 0.25, 0)
	em.initial_velocity_min = 0.2
	em.initial_velocity_max = 0.6
	em.preprocess = 8.0
	add_child(em)


func _process(delta: float) -> void:
	_t += delta
	# slow drift: from the road towards the square, swaying, looping every 70 s
	var k := fmod(_t, 70.0) / 70.0
	var e := 0.5 - 0.5 * cos(k * TAU)
	var pos := Vector3(sin(_t * 0.07) * 6.0 + 4.0, 3.2 + sin(_t * 0.11) * 0.6, lerpf(42.0, 26.0, e))
	_cam.global_position = pos
	_cam.look_at(Vector3(sin(_t * 0.05) * 3.0, 3.0, -4.0))
	for i in flicker_lights.size():
		var fl: Array = flicker_lights[i]
		var l: OmniLight3D = fl[0]
		if not is_instance_valid(l):
			continue
		var s := sin(_t * (1.3 + (i % 5) * 0.23) + i * 2.3)
		l.light_energy = float(fl[1]) * lamp_mult * (0.2 + randf() * 0.4 if s > 0.97 else 1.0)
	for i in fire_lights.size():
		fire_lights[i].light_energy = 2.2 + sin(_t * 9.0 + i) * 0.35
	for wk in _walkers:
		var n: Node3D = wk[0]
		var a: Vector3 = wk[1]
		var b: Vector3 = wk[2]
		var dir := (b - a).normalized()
		n.position += dir * float(wk[3]) * delta
		if n.position.distance_to(b) < 0.5 or (n.position - a).length() > (b - a).length():
			n.position = a
