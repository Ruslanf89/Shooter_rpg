class_name QuestGiver
extends StaticBody3D
## Friendly NPC that gives and completes quests and speaks its lines out loud.
## Uses an animated human model (assets/models/people) that can be recolored per material,
## optionally with a photo face and a cap attached to the head bone.

var world: Node
var id := ""
var display_name := ""
var title := ""
var model_file := "people/casual"
var tint := Color(1, 1, 1)
var colors: Dictionary = {}        # material name -> Color or "print"
var shop_kind := "general"          # traders: general, weapons, armor, alchemy
var stock: Array = []               # traders: what's for sale (made on first visit)
var crown := false                  # the King
var face_texture := ""             # optional photo face (res:// path)
var cap_color := Color(0, 0, 0, 0) # alpha > 0 adds a flat cap
var head_height := 1.62
var body_scale := Vector3.ONE       # e.g. VesPer is a chubby teenager: wider, same height
var voice_pitch := 1.0
var role := "quest"              # "quest" or "trader" (opens the shop)
var child := false               # a child: smaller, with a bigger head (KidProportions)
var pose := ""                   # idle animation instead of standing (e.g. "Crouch_Idle", "Sitting_Idle")

var anim: AnimationPlayer
var marker: Label3D
var voice: AudioStreamPlayer3D
var _visual: Node3D
var _idle := ""
var _t := randf() * 10.0


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("npcs")
	collision_layer = 8
	collision_mask = 0
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.8
	cs.shape = cap
	cs.position.y = 0.9
	add_child(cs)

	_visual = Node3D.new()
	add_child(_visual)
	_build_model()

	var name_label := Label3D.new()
	name_label.text = "%s\n<%s>" % [display_name, Loc.t(title)]
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.fixed_size = true
	name_label.pixel_size = 0.0009
	name_label.font_size = 40
	name_label.outline_size = 10
	name_label.modulate = Color(0.45, 1.0, 0.45)
	name_label.position.y = head_height + 0.55
	name_label.visibility_range_end = 45.0
	add_child(name_label)

	marker = Label3D.new()
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.font_size = 200
	marker.pixel_size = 0.005
	marker.outline_size = 30
	marker.outline_modulate = Color(0.2, 0.1, 0.0)
	marker.position.y = head_height + 1.15
	add_child(marker)          # walls hide it (the HUD waypoint still points the way)

	voice = AudioStreamPlayer3D.new()
	voice.bus = "SFX"
	voice.unit_size = 8.0
	voice.max_distance = 40.0
	voice.volume_db = 6.0
	voice.pitch_scale = voice_pitch
	voice.position.y = head_height
	add_child(voice)


func _build_model() -> void:
	if model_file.begins_with("people/"):
		var built := People.build(_visual, model_file, colors, head_height)
		_visual.scale = body_scale
		if not built.is_empty():
			anim = built["anim"]
			_idle = "Idle"
			var sk: Skeleton3D = built["skeleton"]
			if child:
				sk.add_child(KidProportions.new())
			if pose != "" and anim.has_animation(pose):
				_idle = pose
				anim.play(pose)
			if face_texture != "":
				# the photo face replaces the model's own eyes and brows
				for n in (built["model"] as Node3D).find_children("*", "MeshInstance3D", true, false):
					if String(n.name).to_lower().contains("eye"):
						n.visible = false
			var hb := sk.find_bone("Head")
			if hb >= 0 and (face_texture != "" or cap_color.a > 0.0 or crown):
				_attach_head_items(sk, hb)
			# the King, captains and guard officers wear a sword at the hip
			if Arms.enabled() and (crown or id in ["brannock", "ostrand"] or title.contains("Guard") or title.contains("Watch") \
					or title.contains("Knight") or title.contains("Captain")):
				Arms.at_hip(built["model"], sk)
			return
	var scene := load("res://assets/models/%s.glb" % model_file) as PackedScene
	if scene == null:
		MeshKit.box(_visual, Vector3(0.5, 1.8, 0.3), Vector3(0, 0.9, 0), MeshKit.mat(tint))
		return
	var model: Node3D = scene.instantiate()
	_visual.add_child(model)
	model.rotation.y = PI
	anim = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_idle = _find_anim(["Idle", "Man_Idle", "Female_Idle", "Idle_Neutral"])
	if _idle != "":
		anim.get_animation(_idle).loop_mode = Animation.LOOP_LINEAR
		anim.play(_idle)
		anim.seek(randf(), true)
	var sk: Skeleton3D = null
	var skels := model.find_children("*", "Skeleton3D", true, false)
	if not skels.is_empty():
		sk = skels[0]
	var head_bone := sk.find_bone("Head") if sk else -1
	var head_y := 1.6
	if head_bone >= 0:
		head_y = (sk.global_transform * sk.get_bone_global_pose(head_bone).origin).y - global_position.y
		if head_y < 0.05:
			head_y = 1.6
	model.scale = Vector3.ONE * (head_height / head_y)
	# recolor materials (by name), tint everything else
	for n in model.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var m := mi.get_active_material(i)
			if not (m is BaseMaterial3D):
				continue
			var dm := (m as BaseMaterial3D).duplicate() as BaseMaterial3D
			var key := String(m.resource_name)
			if face_texture != "" and key in ["Eye", "Eyes", "Eyebrows"]:
				# the photo face replaces the model's own eyes and brows
				dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				dm.albedo_color = Color(0, 0, 0, 0)
			elif colors.has(key):
				var c = colors[key]
				if c is String and c == "print":
					dm = Enemy._shirt_material()
				else:
					dm.albedo_color = c
			else:
				dm.albedo_color = dm.albedo_color * tint
			mi.set_surface_override_material(i, dm)
	if head_bone >= 0 and (face_texture != "" or cap_color.a > 0.0 or crown):
		_attach_head_items(sk, head_bone)


## Photo face + cap, positioned in the idle pose and then parented to the head bone.
func _attach_head_items(sk: Skeleton3D, head_bone: int) -> void:
	var att := BoneAttachment3D.new()
	att.bone_idx = head_bone
	sk.add_child(att)
	var head_world := sk.global_transform * sk.get_bone_global_pose(head_bone)
	var fwd := -global_transform.basis.z
	var up := Vector3.UP
	var head_center := head_world.origin + up * 0.11
	var holder := Node3D.new()
	add_child(holder)
	holder.global_transform = Transform3D(Basis.looking_at(fwd, up), head_center)
	if face_texture != "":
		# a slightly curved patch: part of a sphere wrapped around the front of the head
		var face := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.135
		sm.height = 0.27
		sm.radial_segments = 32
		sm.rings = 16
		face.mesh = sm
		var fm := ShaderMaterial.new()
		fm.shader = _face_shader()
		fm.set_shader_parameter("face_tex", load(face_texture))
		face.material_override = fm
		face.scale = Vector3(0.95, 1.12, 0.86)
		face.position = Vector3(0, -0.035, -0.045)
		holder.add_child(face)
	if crown:
		var gold := MeshKit.mat(Color(1.0, 0.8, 0.25), 0.25, 0.95)
		MeshKit.cyl(holder, 0.13, 0.12, 0.09, Vector3(0, 0.12, 0.0), gold, Vector3.ZERO, 20)
		for i in 8:
			var a := TAU * i / 8.0
			var prism := PrismMesh.new()
			prism.size = Vector3(0.05, 0.08, 0.02)
			MeshKit.inst(holder, prism, Vector3(cos(a) * 0.125, 0.2, sin(a) * 0.125), gold, Vector3(0, -rad_to_deg(a) + 90.0, 0))
		for i in 4:
			var a := TAU * i / 4.0
			MeshKit.sphere(holder, 0.018, Vector3(cos(a) * 0.132, 0.12, sin(a) * 0.132), MeshKit.mat([Color(0.9, 0.1, 0.1), Color(0.1, 0.3, 0.9)][i % 2], 0.1, 0.3, 0.6))
	if cap_color.a > 0.0:
		var cm := MeshKit.mat(cap_color, 0.95)
		MeshKit.cyl(holder, 0.135, 0.145, 0.08, Vector3(0, 0.1, 0.0), cm, Vector3(-6, 0, 0), 24)
		MeshKit.sphere(holder, 0.137, Vector3(0, 0.11, 0.005), cm, Vector3(1, 0.42, 1))
		MeshKit.box(holder, Vector3(0.2, 0.018, 0.12), Vector3(0, 0.072, -0.17), cm, Vector3(-10, 0, 0))
	holder.reparent(att, true)


static var _fshader: Shader


## Shows the photo only on the front of the sphere patch, alpha-blended at the edges.
static func _face_shader() -> Shader:
	if _fshader:
		return _fshader
	_fshader = Shader.new()
	_fshader.code = """
shader_type spatial;
render_mode cull_back, depth_prepass_alpha;
uniform sampler2D face_tex : source_color, filter_linear_mipmap;
varying vec3 lp;
void vertex() { lp = VERTEX; }
void fragment() {
	// project the photo straight onto the front of the head
	vec2 uv = vec2(lp.x / 0.27 + 0.5, 0.5 - lp.y / 0.27);
	vec4 c = texture(face_tex, uv);
	float front = smoothstep(0.0, 0.06, -lp.z);
	ALBEDO = c.rgb;
	ALPHA = c.a * front;
	ROUGHNESS = 0.8;
	SPECULAR = 0.2;
}
"""
	return _fshader


func _find_anim(wants: Array) -> String:
	if anim == null:
		return ""
	for want in wants:
		for n in anim.get_animation_list():
			if n == want or n.ends_with("|" + want):
				return n
	return ""


func prompt() -> String:
	if role == "trader":
		return Loc.t("Trade with") + " " + display_name
	return Loc.t("Talk to") + " " + display_name


func interact() -> void:
	world.talk(self)


## Plays a voice line. Returns its length in seconds.
func speak(line_id: String) -> float:
	line_id = Loc.line(line_id)
	var path := "res://assets/voice/%s.wav" % line_id
	if not ResourceLoader.exists(path):
		return 2.0 + QuestManager.line_text(line_id).length() / 15.0     # not voiced yet: time to read it
	var stream: AudioStream = load(path)
	voice.stream = stream
	# the Ukrainian voices are one young male and two female speakers: pitch them per character
	var key: String = str(QuestManager.dialogue().get("lines", {}).get(line_id, [""])[0])
	var pitch: float = voice_pitch * {"uk_m_old": 0.94, "uk_m_gruff": 0.9, "uk_f_old": 0.95, "uk_f_young": 1.06,
		"uk_m_elder": 0.86, "uk_m_captain": 0.86, "uk_m_smith": 0.92}.get(key, 1.0)
	voice.pitch_scale = pitch
	voice.play()
	var ta := _find_anim(["Wave", "Interact", "Man_Clapping", "Female_Clapping"]) if pose == "" else ""
	if ta != "":
		anim.play(ta, 0.2)
		if _idle != "":
			anim.queue(_idle)
	return stream.get_length() / pitch


## Plays a generated line (AI brain). Returns its length in seconds.
func speak_stream(stream: AudioStream) -> float:
	if stream == null:
		return 3.0
	voice.stream = stream
	voice.pitch_scale = voice_pitch
	voice.play()
	var ta := _find_anim(["Wave", "Interact", "Man_Clapping", "Female_Clapping"]) if pose == "" else ""
	if ta != "":
		anim.play(ta, 0.2)
		if _idle != "":
			anim.queue(_idle)
	return stream.get_length() / voice_pitch


## A talking gesture (while AI sentences are spoken), at most every few seconds.
var _gesture_at := 0


func gesture() -> void:
	var now := Time.get_ticks_msec()
	if now < _gesture_at or anim == null:
		return
	_gesture_at = now + 6000
	var ta := _find_anim(["Wave", "Interact", "Man_Clapping", "Female_Clapping"]) if pose == "" else ""
	if ta != "":
		anim.play(ta, 0.2)
		if _idle != "":
			anim.queue(_idle)


func stop_speaking() -> void:
	Brain.clear_voice(voice)
	voice.stop()


func _process(delta: float) -> void:
	_t += delta
	var m: String = world.quests.marker_for(id) if world.quests else ""
	match m:
		"!":
			marker.text = "!"
			marker.modulate = Color(1.0, 0.85, 0.1)
		"?":
			marker.text = "?"
			marker.modulate = Color(1.0, 0.85, 0.1)
		".":
			marker.text = "?"
			marker.modulate = Color(0.6, 0.6, 0.6)
		_:
			marker.text = ""
	marker.position.y = head_height + 1.15 + sin(_t * 2.5) * 0.08
	var p: Player = world.player
	if p:
		var to := p.global_position - global_position
		to.y = 0.0
		if to.length() < 8.0:
			rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), minf(1.0, 4.0 * delta))
