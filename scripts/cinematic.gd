class_name Cinematic
extends Node3D
## Base for the story cinematics (intro, ending): a standalone 3D scene with letterbox bars,
## voiced subtitles (data/dialogue.json lines, Ukrainian variants follow the narration setting),
## a list of timed shots, fades, and the small part of the world API that Props / Buildings /
## Nature use. Space / Enter / Esc skips. Subclasses fill `shots` in build() and override finish().
##
## A shot: {"line": "in_1" (optional), "min": seconds, "start": Callable(), "update": Callable(k, t)}

var cfg: Dictionary
var fire_lights: Array[OmniLight3D] = []
var flicker_lights: Array = []
var spinners: Array = []
var homes: Array = []
var building_areas: Array = []
var water_zones: Array = []
var lamp_mult := 1.6

var cam: Camera3D
var env: Environment
var sky_mat: ShaderMaterial
var shots: Array = []
var rng := RandomNumberGenerator.new()
var uk := false

var _ui: CanvasLayer
var _sub: Label
var _sub2: Label
var _title: Label
var _fade: ColorRect
var _voice: AudioStreamPlayer
var _shot := -1
var _t := 0.0
var _dur := 0.0
var _done := false
var _skippable := true


func ground(_x: float, _z: float) -> float:
	return 0.0


func _ready() -> void:
	rng.seed = 11
	uk = int(Game.settings.get("narration", 0)) == 1
	Game.stop_ambience()
	cam = Camera3D.new()
	cam.fov = 55.0
	cam.far = 900.0
	add_child(cam)
	cam.current = true
	_voice = AudioStreamPlayer.new()
	_voice.bus = "SFX"
	_voice.volume_db = 4.0
	add_child(_voice)
	_build_ui()
	build()
	_next_shot()
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, 1.6)


## Subclasses: build the set and fill `shots`.
func build() -> void:
	pass


## Subclasses: what happens when the cinematic ends (or is skipped).
func finish() -> void:
	Game.go_to_menu()


# --------------------------------------------------------------------------- UI

func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 60
	add_child(_ui)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(root)
	for top in [true, false]:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.anchor_right = 1.0
		bar.anchor_top = 0.0 if top else 0.86
		bar.anchor_bottom = 0.1 if top else 1.0
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(bar)
	_sub = label(23, Color(0.95, 0.93, 0.88))
	_sub.anchor_left = 0.08
	_sub.anchor_right = 0.92
	_sub.anchor_top = 0.86
	_sub.anchor_bottom = 0.945
	root.add_child(_sub)
	_sub2 = label(17, Color(0.68, 0.68, 0.7))
	_sub2.anchor_left = 0.08
	_sub2.anchor_right = 0.92
	_sub2.anchor_top = 0.945
	_sub2.anchor_bottom = 0.995
	root.add_child(_sub2)
	_title = label(54, Color(1.0, 0.9, 0.7))
	_title.anchor_right = 1.0
	_title.anchor_top = 0.36
	_title.anchor_bottom = 0.64
	_title.modulate.a = 0.0
	root.add_child(_title)
	var skip := label(15, Color(0.6, 0.6, 0.62))
	skip.text = "[Space]  " + Loc.t("skip")
	skip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	skip.anchor_left = 0.7
	skip.anchor_right = 0.98
	skip.anchor_top = 0.02
	skip.anchor_bottom = 0.08
	skip.name = "Skip"
	root.add_child(skip)
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_fade)


func ui_root() -> Control:
	return _ui.get_child(0)


func label(size: int, color: Color) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 6)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Big centred title that fades in and out.
func show_title(text: String, hold := 3.0) -> void:
	_title.text = text
	var tw := _title.create_tween()
	tw.tween_property(_title, "modulate:a", 1.0, 1.0)
	tw.tween_interval(hold)
	tw.tween_property(_title, "modulate:a", 0.0, 1.0)


func fade_to(color: Color, time: float) -> Tween:
	var tw := create_tween()
	tw.tween_property(_fade, "color", color, time)
	return tw


func set_skippable(on: bool) -> void:
	_skippable = on
	var s := ui_root().get_node_or_null("Skip")
	if s:
		s.visible = on


# --------------------------------------------------------------------------- voice

## Plays a dialogue line (Ukrainian variant when narration is Ukrainian) with subtitles.
## Returns its length in seconds.
func say(line_id: String) -> float:
	var id := Loc.line(line_id)
	_sub.text = QuestManager.line_text(id)
	_sub2.text = QuestManager.line_translation(id)
	for l in [_sub, _sub2]:
		l.modulate.a = 0.0
		l.create_tween().tween_property(l, "modulate:a", 1.0, 0.4).set_delay(0.2)
	var path := "res://assets/voice/%s.wav" % id
	if ResourceLoader.exists(path):
		var s: AudioStream = load(path)
		_voice.stream = s
		_voice.play()
		return s.get_length()
	return 4.0


func clear_subtitles() -> void:
	for l in [_sub, _sub2]:
		l.create_tween().tween_property(l, "modulate:a", 0.0, 0.4)


# --------------------------------------------------------------------------- shots

func _next_shot() -> void:
	_shot += 1
	_t = 0.0
	if _shot >= shots.size():
		_end()
		return
	var s: Dictionary = shots[_shot]
	_dur = float(s.get("min", 4.0))
	if s.has("line"):
		_dur = maxf(_dur, say(s["line"]) + float(s.get("pad", 0.8)))
	else:
		clear_subtitles()
	if s.has("start"):
		(s["start"] as Callable).call()


func _process(delta: float) -> void:
	for sp in spinners:
		if is_instance_valid(sp[0]):
			(sp[0] as Node3D).rotation += (sp[1] as Vector3) * delta
	if _done or _shot < 0 or _shot >= shots.size():
		return
	_t += delta
	var s: Dictionary = shots[_shot]
	if s.has("update"):
		(s["update"] as Callable).call(clampf(_t / _dur, 0.0, 1.0), _t)
	if s.get("wait", false):
		return
	if _t >= _dur:
		_next_shot()


## For shots with "wait": true (e.g. a choice) - continue to the next shot.
func advance() -> void:
	_next_shot()


func _unhandled_input(event: InputEvent) -> void:
	if _done or not _skippable:
		return
	if event.is_action_pressed("jump") or event.is_action_pressed("ui_accept") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		skip()


## Skipping jumps to the end (subclasses may override, e.g. to jump to a choice).
func skip() -> void:
	_end()


func _end() -> void:
	if _done:
		return
	_done = true
	_voice.stop()
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.8)
	tw.tween_callback(finish)


# --------------------------------------------------------------------------- helpers

## Camera on a path from a to b looking from la to lb, eased.
func cam_move(k: float, a: Vector3, b: Vector3, la: Vector3, lb: Vector3) -> void:
	var e := k * k * (3.0 - 2.0 * k)
	cam.global_position = a.lerp(b, e)
	var look := la.lerp(lb, e)
	if cam.global_position.distance_to(look) > 0.05:
		cam.look_at(look)


func make_environment(top: Color, horizon: Color, ground_c: Color, sun_glow: Color, clouds: Color, cloud_shadow: Color,
		cover: float, night: float, fog: Color, fog_density: float, ambient: float) -> void:
	sky_mat = ShaderMaterial.new()
	sky_mat.shader = load("res://shaders/sky.gdshader")
	sky_mat.set_shader_parameter("top_color", top)
	sky_mat.set_shader_parameter("horizon_color", horizon)
	sky_mat.set_shader_parameter("ground_color", ground_c)
	sky_mat.set_shader_parameter("sun_glow", sun_glow)
	sky_mat.set_shader_parameter("cloud_color", clouds)
	sky_mat.set_shader_parameter("cloud_shadow", cloud_shadow)
	sky_mat.set_shader_parameter("cloud_cover", cover)
	sky_mat.set_shader_parameter("night", night)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	if env == null:
		env = Environment.new()
		var we := WorldEnvironment.new()
		we.environment = env
		add_child(we)
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = ambient
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.fog_enabled = true
	env.fog_light_color = fog
	env.fog_density = fog_density
	env.fog_aerial_perspective = 0.5
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = fog_density * 1.6
	env.volumetric_fog_albedo = fog
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.12
	env.adjustment_enabled = true
	env.adjustment_saturation = 0.9
	env.adjustment_contrast = 1.1
	env.ssao_enabled = true


func sun(color: Color, energy: float, rot: Vector3, shadows := true) -> DirectionalLight3D:
	var l := DirectionalLight3D.new()
	l.light_color = color
	l.light_energy = energy
	l.rotation_degrees = rot
	l.shadow_enabled = shadows
	l.directional_shadow_max_distance = 120.0
	add_child(l)
	return l


## Animated human (People model) under a pivot node. Returns {"node", "anim", "skeleton", "anims"}.
func person(file: String, colors: Dictionary, pos: Vector3, yaw: float, height := 1.64) -> Dictionary:
	var n := Node3D.new()
	add_child(n)
	n.position = pos
	n.rotation.y = yaw
	var built := People.build(n, file, colors, height)
	var anim: AnimationPlayer = built.get("anim")
	var prefix := "Female_" if file.begins_with("people/woman") else "Man_"
	var anims := {}
	for k in ["Idle", "Walk", "Run", "Sitting", "Death", "Standing", "Clapping", "Punch"]:
		anims[k.to_lower()] = People.find_anim(anim, [prefix + k, k])
	anims["crouch"] = People.find_anim(anim, ["Crouch_Idle"])
	anims["sit_down"] = People.find_anim(anim, ["Sitting_Enter"])
	for k in ["idle", "walk", "run"]:
		if anims[k] != "":
			anim.get_animation(anims[k]).loop_mode = Animation.LOOP_LINEAR
	return {"node": n, "anim": anim, "skeleton": built.get("skeleton"), "anims": anims}


func play(p: Dictionary, key: String, blend := 0.3, speed := 1.0) -> void:
	var a: String = p["anims"].get(key, "")
	if a != "" and p["anim"]:
		p["anim"].play(a, blend, speed)


## Jumps straight to the last frame of a one-shot clip (e.g. already seated).
func pose_end(p: Dictionary, key: String) -> void:
	var a: String = p["anims"].get(key, "")
	if a != "" and p["anim"]:
		p["anim"].play(a, 0.0)
		p["anim"].seek(p["anim"].current_animation_length - 0.01, true)


## Hangs `node` on a bone (with an offset transform in the bone's space).
func attach(p: Dictionary, bone: String, node: Node3D, offset := Transform3D.IDENTITY) -> void:
	var sk: Skeleton3D = p["skeleton"]
	if sk == null:
		node.queue_free()
		return
	var att := BoneAttachment3D.new()
	att.bone_name = bone
	sk.add_child(att)
	att.add_child(node)
	# model is scaled to the wanted height: undo it so offsets are in metres
	var s := sk.global_transform.basis.get_scale().x
	node.transform = Transform3D(offset.basis.scaled(Vector3.ONE / maxf(s, 0.001)), offset.origin / maxf(s, 0.001))


## Photo face on a person's head (like QuestGiver): hides the model's eyes, wraps the photo
## around the front of the head and hangs it on the head bone.
func face_on(p: Dictionary, texture_path: String) -> void:
	var sk: Skeleton3D = p["skeleton"]
	var n: Node3D = p["node"]
	if sk == null or not ResourceLoader.exists(texture_path):
		return
	for c in n.find_children("*", "MeshInstance3D", true, false):
		var mi := c as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var m := mi.get_active_material(i)
			if m is BaseMaterial3D and (String(m.resource_name) in ["Eye", "Eyes", "Eyebrows"] or String(mi.name).to_lower().contains("eye")):
				var dm := (m as BaseMaterial3D).duplicate() as BaseMaterial3D
				dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				dm.albedo_color = Color(0, 0, 0, 0)
				mi.set_surface_override_material(i, dm)
	var hb := sk.find_bone("Head")
	if hb < 0:
		return
	var att := BoneAttachment3D.new()
	att.bone_idx = hb
	sk.add_child(att)
	var head_world := sk.global_transform * sk.get_bone_global_pose(hb)
	var holder := Node3D.new()
	add_child(holder)
	holder.global_transform = Transform3D(Basis.looking_at(-n.global_transform.basis.z, Vector3.UP), head_world.origin + Vector3.UP * 0.11)
	var face := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.135
	sm.height = 0.27
	sm.radial_segments = 32
	sm.rings = 16
	face.mesh = sm
	var fm := ShaderMaterial.new()
	fm.shader = QuestGiver._face_shader()
	fm.set_shader_parameter("face_tex", load(texture_path))
	face.material_override = fm
	face.scale = Vector3(0.95, 1.12, 0.86)
	face.position = Vector3(0, -0.035, -0.045)
	holder.add_child(face)
	holder.reparent(att, true)


## VesPerFPV as in the game (printed shirt, photo face).
func vesper(pos: Vector3, yaw: float) -> Dictionary:
	var p := person("people/casual", {"White": "print", "LightBlue": Color(0.06, 0.06, 0.07), "Red_Dark": Color(0.16, 0.16, 0.17),
		"Hair": Color(0.16, 0.1, 0.06), "Skin": Color(0.88, 0.68, 0.6)}, pos, yaw, 1.62)
	play(p, "idle")
	face_on(p, "res://assets/textures/vesper_face.png")
	return p


## Kalashnikov-style rifle (third person), barrel along -z, grip at the origin.
func rifle(parent: Node3D) -> Node3D:
	var g := Node3D.new()
	parent.add_child(g)
	var steel := MeshKit.mat(Color(0.1, 0.1, 0.11), 0.4, 0.8)
	var poly := MeshKit.mat(Color(0.32, 0.12, 0.05), 0.5)
	var black := MeshKit.mat(Color(0.04, 0.04, 0.04), 0.6)
	MeshKit.box(g, Vector3(0.05, 0.07, 0.38), Vector3(0, 0.05, -0.12), steel)
	MeshKit.box(g, Vector3(0.045, 0.06, 0.2), Vector3(0, 0.035, -0.38), poly)
	MeshKit.cyl(g, 0.011, 0.011, 0.36, Vector3(0, 0.07, -0.58), steel, Vector3(90, 0, 0), 6)
	MeshKit.cyl(g, 0.009, 0.009, 0.3, Vector3(0, 0.1, -0.46), steel, Vector3(90, 0, 0), 6)
	MeshKit.box(g, Vector3(0.035, 0.16, 0.07), Vector3(0, -0.06, -0.2), black, Vector3(-18, 0, 0))
	MeshKit.box(g, Vector3(0.03, 0.1, 0.04), Vector3(0, -0.03, -0.02), poly, Vector3(15, 0, 0))
	MeshKit.box(g, Vector3(0.04, 0.09, 0.26), Vector3(0, 0.02, 0.18), black)
	return g


## Pixel camouflage (Ukrainian MM-14 style) as a tiling texture for triplanar mapping.
static func camo_material() -> StandardMaterial3D:
	var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	var cols := [Color(0.55, 0.53, 0.38), Color(0.38, 0.42, 0.25), Color(0.22, 0.27, 0.15), Color(0.17, 0.13, 0.09)]
	var noise := FastNoiseLite.new()
	noise.seed = 4
	noise.frequency = 0.09
	var noise2 := FastNoiseLite.new()
	noise2.seed = 9
	noise2.frequency = 0.2
	for y in 64:
		for x in 64:
			# blocky: sample per 2x2 pixel cell
			var cx := (x / 4) * 4
			var cy := (y / 4) * 4
			var v := noise.get_noise_2d(cx, cy) * 0.7 + noise2.get_noise_2d(cx, cy) * 0.5
			var i := 0
			if v > 0.25:
				i = 3
			elif v > 0.05:
				i = 2
			elif v > -0.2:
				i = 1
			img.set_pixel(x, y, cols[i])
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	m.uv1_triplanar = true
	m.uv1_world_triplanar = false
	m.roughness = 0.95
	return m


## A Ukrainian soldier: People man1 in pixel camo with helmet, plate carrier and rifle.
func soldier(pos: Vector3, yaw: float, with_rifle := true) -> Dictionary:
	var p := person("people/man1", {"Skin": Color(0.86, 0.68, 0.56), "Hair": Color(0.25, 0.18, 0.1), "Shoes": Color(0.14, 0.12, 0.09),
		"outfit": "soldier", "hair_style": "Hair_Buzzed", "no_beard": true}, pos, yaw)
	var camo_base := camo_material()
	for n in (p["node"] as Node3D).find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		# triplanar in mesh space: about 1.3 texture repeats per metre of body
		var camo := camo_base.duplicate() as StandardMaterial3D
		var s := 1.3 * 1.75 / maxf(mi.mesh.get_aabb().size.y, 0.001)
		camo.uv1_scale = Vector3(s, s, s)
		for i in mi.mesh.get_surface_count():
			var m := mi.get_active_material(i)
			if m and String(m.resource_name) in ["Shirt", "Shirt2", "Pants"]:
				mi.set_surface_override_material(i, camo)
	var olive := MeshKit.mat(Color(0.28, 0.3, 0.2), 0.9)
	var dark := MeshKit.mat(Color(0.12, 0.13, 0.1), 0.85)
	# helmet with cover and strap
	var helmet := Node3D.new()
	var hcamo := camo_base.duplicate() as StandardMaterial3D
	hcamo.uv1_scale = Vector3(1.3, 1.3, 1.3)
	MeshKit.sphere(helmet, 0.145, Vector3(0, 0.07, 0.0), hcamo, Vector3(1.0, 0.82, 1.08))
	MeshKit.cyl(helmet, 0.15, 0.155, 0.04, Vector3(0, 0.03, 0.0), hcamo, Vector3.ZERO, 16)
	MeshKit.box(helmet, Vector3(0.012, 0.13, 0.02), Vector3(0.13, -0.05, 0.0), dark)
	MeshKit.box(helmet, Vector3(0.012, 0.13, 0.02), Vector3(-0.13, -0.05, 0.0), dark)
	MeshKit.box(helmet, Vector3(0.05, 0.03, 0.03), Vector3(0, 0.12, 0.12), dark)
	attach(p, "Head", helmet, Transform3D(Basis(), Vector3(0, 0.12, 0.0)))
	# plate carrier with pouches
	var vest := Node3D.new()
	MeshKit.box(vest, Vector3(0.34, 0.36, 0.07), Vector3(0, 0, 0.12), olive)
	MeshKit.box(vest, Vector3(0.34, 0.36, 0.06), Vector3(0, 0, -0.13), olive)
	for x in [-0.11, 0.0, 0.11]:
		MeshKit.box(vest, Vector3(0.09, 0.13, 0.05), Vector3(x, -0.1, 0.17), dark)
	MeshKit.box(vest, Vector3(0.36, 0.05, 0.3), Vector3(0, -0.17, 0), dark)
	MeshKit.box(vest, Vector3(0.1, 0.04, 0.03), Vector3(0.09, 0.08, 0.16), MeshKit.mat(Color(0.95, 0.85, 0.1)))
	MeshKit.box(vest, Vector3(0.1, 0.04, 0.03), Vector3(0.09, 0.04, 0.16), MeshKit.mat(Color(0.1, 0.35, 0.8)))
	attach(p, "spine_03", vest, Transform3D(Basis(), Vector3(0, 0.0, 0)))
	if with_rifle:
		var holder := Node3D.new()
		var r := rifle(holder)
		r.rotation_degrees = Vector3(0, 0, 0)
		# slung across the back
		attach(p, "spine_03", holder, Transform3D(Basis(Vector3(0, 0, 1), deg_to_rad(-50)) * Basis(Vector3.UP, PI * 0.5), Vector3(0, 0.05, -0.2)))
	return p


## Glowing mushroom cluster. Returns the cluster node; the biggest cap is meta "big".
func mushrooms(pos: Vector3, count: int, color := Color(0.35, 0.85, 1.0)) -> Node3D:
	var n := Node3D.new()
	add_child(n)
	n.position = pos
	var stem := MeshKit.mat(Color(0.85, 0.82, 0.72), 0.7, 0.0, 0.4)
	var cap := MeshKit.mat(color, 0.4, 0.0, 1.3)
	var spot := MeshKit.mat(Color(0.95, 1.0, 1.0), 0.4, 0.0, 2.0)
	for i in count:
		var a := rng.randf() * TAU
		var r := 0.0 if i == 0 else rng.randf_range(0.25, 1.6)
		var s := 1.6 if i == 0 else rng.randf_range(0.5, 1.1)
		var m := Node3D.new()
		m.position = Vector3(cos(a) * r, 0, sin(a) * r)
		m.rotation = Vector3(rng.randf_range(-0.15, 0.15), rng.randf() * TAU, rng.randf_range(-0.15, 0.15))
		m.scale = Vector3.ONE * s
		n.add_child(m)
		MeshKit.cyl(m, 0.022, 0.03, 0.14, Vector3(0, 0.07, 0), stem, Vector3.ZERO, 8)
		MeshKit.sphere(m, 0.07, Vector3(0, 0.15, 0), cap, Vector3(1.0, 0.55, 1.0))
		for k in 4:
			var b := TAU * k / 4.0 + 0.4
			MeshKit.sphere(m, 0.01, Vector3(cos(b) * 0.04, 0.175, sin(b) * 0.04), spot)
		if i == 0:
			n.set_meta("big", m)
	var l := OmniLight3D.new()
	l.light_color = color
	l.light_energy = 2.2
	l.omni_range = 5.0
	l.position = Vector3(0, 0.5, 0)
	n.add_child(l)
	n.set_meta("light", l)
	# drifting spores
	var sp := CPUParticles3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.012
	sm.height = 0.024
	sm.radial_segments = 4
	sm.rings = 2
	sm.material = MeshKit.unshaded(color.lightened(0.4))
	sp.mesh = sm
	sp.amount = 40
	sp.lifetime = 5.0
	sp.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	sp.emission_sphere_radius = 1.6
	sp.direction = Vector3.UP
	sp.spread = 40.0
	sp.gravity = Vector3(0, 0.05, 0)
	sp.initial_velocity_min = 0.05
	sp.initial_velocity_max = 0.2
	sp.preprocess = 5.0
	sp.position = Vector3(0, 0.6, 0)
	n.add_child(sp)
	return n


## Full-screen "reality bends" effect; animate its "amount" (0..1) and "white" (0..1).
func warp_overlay() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float amount = 0.0;
uniform float white = 0.0;
void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 c = uv - 0.5;
	float r = length(c);
	float ang = amount * 6.0 * (1.0 - smoothstep(0.0, 0.75, r)) + sin(TIME * 3.0 + r * 18.0) * amount * 0.25;
	vec2 sw = vec2(cos(ang) * c.x - sin(ang) * c.y, sin(ang) * c.x + cos(ang) * c.y);
	sw *= 1.0 + sin(TIME * 2.0) * amount * 0.08;
	vec2 off = normalize(c + 1e-5) * amount * 0.02;
	vec3 col;
	col.r = texture(screen_tex, sw + 0.5 + off).r;
	col.g = texture(screen_tex, sw + 0.5).g;
	col.b = texture(screen_tex, sw + 0.5 - off).b;
	col = mix(col, col * vec3(0.7, 1.2, 1.3) + vec3(0.05, 0.1, 0.15), amount * 0.6);
	col = mix(col, vec3(1.0), white);
	COLOR = vec4(col, 1.0);
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	var r := ColorRect.new()
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.material = m
	var root := ui_root()
	root.add_child(r)
	root.move_child(r, 0)
	return m


func loop_sound(sound: String, volume: float) -> AudioStreamPlayer:
	var s := AudioStreamPlayer.new()
	s.bus = "SFX"
	if Game.sounds.has(sound):
		s.stream = Game.sounds[sound][0]
		if s.stream is AudioStreamWAV:
			(s.stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
			if (s.stream as AudioStreamWAV).loop_end == 0:
				(s.stream as AudioStreamWAV).loop_end = int((s.stream as AudioStreamWAV).get_length() * (s.stream as AudioStreamWAV).mix_rate)
		elif "loop" in s.stream:
			s.stream.loop = true
	s.volume_db = volume
	add_child(s)
	s.play()
	return s
