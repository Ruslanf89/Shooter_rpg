class_name People
extends RefCounted
## Human characters: Quaternius Universal Base Characters (male / female body, hairstyles) animated
## with the Universal Animation Library (same skeleton). Clothing is painted on the body by a
## shader - every vertex is tagged with the body part of the bone it's skinned to (torso, upper
## arm, forearm, hips, shins, feet), so shirts, sleeves, trousers and boots follow the animation
## exactly - plus simple pieces hung on bones: skirts, coats, robes, aprons, belts, hats, armor.
##
## build(parent, file, colors, head_height) keeps the old interface: `file` ("people/farmer",
## "people/woman_dress"...) picks the body and the outfit, `colors` the clothes ("Shirt", "Pants",
## "Dress", "Hair", "Skin"...); colors["outfit"] overrides the outfit. Old animation names
## ("Man_Walk", "Female_Idle", "Run"...) are aliases of the library's animations.

const MALE := ["people/man1", "people/man2", "people/casual", "people/hoodie", "people/farmer", "people/worker", "people/business"]
const FEMALE := ["people/woman", "people/woman_casual", "people/woman_dress"]

const DIR := "res://assets/models/characters/"
const BODY := {"m": "Superhero_Male_FullBody", "f": "Superhero_Female_FullBody"}
const HAIR := {"m": ["Hair_SimpleParted", "Hair_Buzzed", "Hair_SimpleParted", "Hair_Long"], "f": ["Hair_Long", "Hair_Buns", "Hair_Long", "Hair_BuzzedFemale"]}

## Body parts by bone (stored in the vertex colour, read by the clothing shader).
enum {SKIN, TORSO, UPPER_ARM, FOREARM, HIPS, SHIN, FOOT}

## Outfit: sleeves 0 none / 1 short / 2 long, legs 0 shorts / 1 trousers, barefoot, extra pieces.
const OUTFITS := {
	"tunic": {"sleeves": 2, "legs": 1, "pieces": ["belt"]},
	"farmer": {"sleeves": 1, "legs": 1, "pieces": ["belt", "straw_hat"]},
	"apron": {"sleeves": 1, "legs": 1, "pieces": ["apron"]},
	"coat": {"sleeves": 2, "legs": 1, "pieces": ["coat", "belt"]},
	"robe": {"sleeves": 2, "legs": 1, "pieces": ["robe", "belt"]},
	"leather": {"sleeves": 0, "legs": 1, "pieces": ["belt", "bracers"]},
	"dress": {"sleeves": 1, "legs": 0, "pieces": ["skirt", "belt"]},
	"blouse": {"sleeves": 2, "legs": 1, "pieces": ["belt"]},
	"guard": {"sleeves": 2, "legs": 1, "pieces": ["breastplate", "pauldrons", "helmet", "belt"]},
	"bandit": {"sleeves": 0, "legs": 1, "pieces": ["belt", "bracers"]},
	"soldier": {"sleeves": 2, "legs": 1, "pieces": [], "camo": true},
}

static var _lib: AnimationLibrary
static var _meshes := {}            # gender -> body ArrayMesh with body-part vertex colours
static var _shader: Shader


## Builds the character under `parent` (facing -z). Returns {"model", "anim", "skeleton"}.
static func build(parent: Node3D, file: String, colors: Dictionary, head_height := 1.62) -> Dictionary:
	var gender := "f" if file.begins_with("people/woman") else "m"
	var path: String = DIR + BODY[gender] + ".gltf"
	if not ResourceLoader.exists(path):
		return {}
	var model: Node3D = (load(path) as PackedScene).instantiate()
	parent.add_child(model)
	model.rotation.y = PI
	var sk: Skeleton3D = model.find_children("*", "Skeleton3D", true, false)[0]
	var anim := AnimationPlayer.new()
	anim.name = "AnimationPlayer"
	model.add_child(anim)
	anim.add_animation_library("", library())
	var seed_v := hash(file + str(colors.get("Shirt", colors.get("Dress", ""))) + str(colors.get("Hair", "")))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var outfit_name: String = colors.get("outfit", _default_outfit(file, rng))
	var outfit: Dictionary = OUTFITS.get(outfit_name, OUTFITS["tunic"])
	var shirt := _pick(colors, ["Shirt", "Dress", "White", "Suit", "Purple", "LightGreen", "LightBlue", "Worker_Vest", "Red_Dark"], Color(0.45, 0.35, 0.25))
	var pants := _pick(colors, ["Pants", "Shirt2", "Grey", "Brown2", "Green", "Black", "Beige"], shirt.darkened(0.45))
	if outfit_name == "dress":
		pants = shirt
	var hair_c := _pick(colors, ["Hair", "Hair_Brown", "Hair_Blond", "HairBase"], Color(0.25, 0.17, 0.1))
	var skin := _pick(colors, ["Skin"], Color(0.82, 0.62, 0.5))
	var boots := _pick(colors, ["Shoes"], Color(0.2, 0.14, 0.09))
	# body with painted clothes, eyebrows in the hair colour
	for n in model.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var nm := String(mi.name).to_lower()
		if nm.contains("superhero"):
			mi.mesh = _body_mesh(gender, mi, sk)
			var m := ShaderMaterial.new()
			m.shader = _clothing_shader()
			var src := mi.get_active_material(0)
			if src is BaseMaterial3D:
				m.set_shader_parameter("albedo_tex", (src as BaseMaterial3D).albedo_texture)
				m.set_shader_parameter("normal_tex", (src as BaseMaterial3D).normal_texture)
				m.set_shader_parameter("rough_tex", (src as BaseMaterial3D).roughness_texture)
			m.set_shader_parameter("skin_tint", Vector3(skin.r / 0.82, skin.g / 0.62, skin.b / 0.5))
			m.set_shader_parameter("shirt_col", shirt)
			m.set_shader_parameter("pants_col", pants)
			m.set_shader_parameter("boots_col", boots)
			m.set_shader_parameter("sleeves", int(outfit["sleeves"]))
			m.set_shader_parameter("legs", int(outfit["legs"]))
			m.set_shader_parameter("camo", outfit.get("camo", false))
			if outfit.get("camo", false):
				m.set_shader_parameter("camo_tex", Cinematic.camo_material().albedo_texture)
			mi.material_override = m
		elif nm.contains("eyebrow"):
			_tint(mi, hair_c)
	# hair (rigged to the head bone of the same skeleton)
	var styles: Array = HAIR[gender]
	var style: String = colors.get("hair_style", styles[rng.randi() % styles.size()])
	_add_hair(model, sk, style, hair_c)
	if gender == "m" and rng.randf() < 0.3 and not colors.has("no_beard"):
		_add_hair(model, sk, "Hair_Beard", hair_c)
	# idle pose, then scale to the wanted head height
	anim.play("Idle")
	anim.seek(rng.randf() * 2.0, true)
	var head_y := 1.6
	var hb := sk.find_bone("Head")
	if hb >= 0:
		head_y = (sk.global_transform * sk.get_bone_global_pose(hb).origin).y - parent.global_position.y
		if head_y < 0.05:
			head_y = 1.6
	model.scale = Vector3.ONE * (head_height / head_y)
	for piece in outfit["pieces"]:
		_piece(model, sk, piece, shirt, pants, outfit_name)
	return {"model": model, "anim": anim, "skeleton": sk}


static func find_anim(anim: AnimationPlayer, wants: Array) -> String:
	if anim == null:
		return ""
	for want in wants:
		for n in anim.get_animation_list():
			if n == want or n.ends_with("|" + want) or n.ends_with("/" + want):
				return n
	return ""


## A random outfit for a model (material name -> colour) so villagers don't look alike.
static func random_colors(file: String, rng: RandomNumberGenerator) -> Dictionary:
	var cloth := [Color(0.45, 0.32, 0.22), Color(0.3, 0.38, 0.28), Color(0.55, 0.5, 0.42), Color(0.35, 0.33, 0.45),
		Color(0.6, 0.25, 0.2), Color(0.25, 0.3, 0.4), Color(0.7, 0.65, 0.55), Color(0.4, 0.4, 0.38)]
	var hair := [Color(0.12, 0.08, 0.05), Color(0.35, 0.22, 0.1), Color(0.6, 0.45, 0.25), Color(0.55, 0.55, 0.55), Color(0.2, 0.15, 0.1)]
	var c1: Color = cloth[rng.randi() % cloth.size()]
	var c2: Color = cloth[rng.randi() % cloth.size()]
	var h: Color = hair[rng.randi() % hair.size()]
	var skin := Color(0.92, 0.75, 0.62).lerp(Color(0.55, 0.38, 0.28), rng.randf() * 0.6)
	var d := {"Skin": skin, "Hair": h, "Hair2": h.lightened(0.1), "HairBase": h, "Hair_Brown": h, "Hair_Blond": h}
	for k in ["Shirt", "White", "Purple", "LightBlue", "Dress", "Brown", "Worker_Vest", "LightGreen", "Suit", "Red_Dark"]:
		d[k] = c1
	for k in ["Pants", "Shirt2", "Grey", "Brown2", "Green", "Black"]:
		d[k] = c2
	return d


# --------------------------------------------------------------------------- animation library

## The Universal Animation Library plus the names the game already uses.
static func library() -> AnimationLibrary:
	if _lib:
		return _lib
	_lib = AnimationLibrary.new()
	var src_scene: Node = (load(DIR + "UAL1_Standard.glb") as PackedScene).instantiate()
	var ap := src_scene.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var src: AnimationLibrary = ap.get_animation_library(ap.get_animation_library_list()[0])
	for n in src.get_animation_list():
		_lib.add_animation(n, src.get_animation(n))
	src_scene.free()
	for loop in ["Idle", "Walk", "Jog_Fwd", "Sprint", "Sitting_Idle", "Idle_Talking", "Crouch_Idle", "Fixing_Kneeling", "Sword_Idle", "Pistol_Idle", "Spell_Simple_Idle", "Walk_Formal", "Crouch_Fwd"]:
		if _lib.has_animation(loop):
			_lib.get_animation(loop).loop_mode = Animation.LOOP_LINEAR
	var aliases := {
		"Idle": ["Man_Idle", "Female_Idle", "Idle_Neutral"],
		"Walk": ["Man_Walk", "Female_Walk"],
		"Jog_Fwd": ["Run", "Man_Run", "Female_Run"],
		"Death01": ["Death", "Man_Death", "Female_Death"],
		"Punch_Cross": ["Punch_Right", "Man_Punch", "Female_Punch"],
		"Sword_Attack": ["Sword_Slash", "Man_SwordSlash", "Female_SwordSlash"],
		"Sitting_Idle": ["Man_Sitting", "Female_Sitting", "Sitting"],
		"Sitting_Exit": ["Man_Standing", "Female_Standing", "Standing"],
		"Idle_Talking": ["Wave", "Man_Clapping", "Female_Clapping", "Clapping"],
		"Pistol_Shoot": ["Gun_Shoot", "Idle_Gun_Shoot"],
		"Jump": ["Man_Jump", "Female_Jump"],
		"Hit_Chest": ["HitRecieve", "Hit"],
		"Fixing_Kneeling": ["Work_Kneel"],
	}
	for k in aliases:
		if _lib.has_animation(k):
			for a in aliases[k]:
				if not _lib.has_animation(a):
					_lib.add_animation(a, _lib.get_animation(k))
	return _lib


# --------------------------------------------------------------------------- clothing

static func _default_outfit(file: String, rng: RandomNumberGenerator) -> String:
	match file:
		"people/farmer": return "farmer"
		"people/worker": return "apron"
		"people/business": return "coat"
		"people/adventurer": return "leather"
		"people/woman_dress": return "dress"
		"people/woman", "people/woman_casual": return "dress" if rng.randf() < 0.5 else "blouse"
	return "tunic"


static func _pick(colors: Dictionary, keys: Array, fallback: Color) -> Color:
	for k in keys:
		var c = colors.get(k)
		if c is Color:
			return c
		if c is String and c == "print":
			return Color(0.13, 0.13, 0.14)
	return fallback


static func _v(c: Color) -> Vector3:
	return Vector3(c.r, c.g, c.b)


static func _tint(mi: MeshInstance3D, c: Color) -> void:
	for i in mi.mesh.get_surface_count():
		var m := mi.get_active_material(i)
		if m is BaseMaterial3D:
			var dm := (m as BaseMaterial3D).duplicate() as BaseMaterial3D
			dm.albedo_color = Color(c.r * 1.6, c.g * 1.6, c.b * 1.6).clamp()
			mi.set_surface_override_material(i, dm)


## The body mesh with each vertex tagged by body part (from its strongest bone).
static func _body_mesh(gender: String, mi: MeshInstance3D, sk: Skeleton3D) -> Mesh:
	if _meshes.has(gender):
		return _meshes[gender]
	var src: Mesh = mi.mesh
	var skin := mi.skin
	var names := []
	if skin:
		for i in skin.get_bind_count():
			var bn := String(skin.get_bind_name(i))
			if bn == "" and skin.get_bind_bone(i) >= 0:
				bn = sk.get_bone_name(skin.get_bind_bone(i))
			names.append(bn)
	var out := ArrayMesh.new()
	for s in src.get_surface_count():
		var arr := src.surface_get_arrays(s)
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var bones = arr[Mesh.ARRAY_BONES]
		var weights = arr[Mesh.ARRAY_WEIGHTS]
		var cols := PackedColorArray()
		cols.resize(verts.size())
		var per: int = (bones.size() / verts.size()) if verts.size() > 0 and bones != null else 0
		for v in verts.size():
			var best := 0
			var bw := -1.0
			for j in per:
				if weights[v * per + j] > bw:
					bw = weights[v * per + j]
					best = bones[v * per + j]
			var bname: String = names[best] if best < names.size() else sk.get_bone_name(best)
			cols[v] = Color(float(_part(bname)) / 8.0, 0.0, 0.0, 1.0)
		arr[Mesh.ARRAY_COLOR] = cols
		for ci in [Mesh.ARRAY_CUSTOM0, Mesh.ARRAY_CUSTOM1, Mesh.ARRAY_CUSTOM2, Mesh.ARRAY_CUSTOM3]:
			arr[ci] = null
		var flags: int = src.surface_get_format(s) & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
		out.add_surface_from_arrays(src.surface_get_primitive_type(s), arr, [], {}, flags)
		out.surface_set_material(s, src.surface_get_material(s))
	_meshes[gender] = out
	return out


static func _part(bone: String) -> int:
	var b := bone.to_lower()
	if b.begins_with("foot") or b.begins_with("ball"):
		return FOOT
	if b.begins_with("calf"):
		return SHIN
	if b.begins_with("thigh") or b == "pelvis" or b == "root":
		return HIPS
	if b.begins_with("spine") or b.begins_with("clavicle"):
		return TORSO
	if b.begins_with("upperarm"):
		return UPPER_ARM
	if b.begins_with("lowerarm"):
		return FOREARM
	return SKIN


static func _clothing_shader() -> Shader:
	if _shader:
		return _shader
	_shader = Shader.new()
	_shader.code = """
shader_type spatial;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap;
uniform sampler2D rough_tex : filter_linear_mipmap;
uniform sampler2D camo_tex : source_color, filter_nearest_mipmap;
uniform vec3 skin_tint = vec3(1.0);
uniform vec3 shirt_col : source_color = vec3(0.5, 0.4, 0.3);
uniform vec3 pants_col : source_color = vec3(0.3, 0.25, 0.2);
uniform vec3 boots_col : source_color = vec3(0.2, 0.14, 0.09);
uniform int sleeves = 2;
uniform int legs = 1;
uniform bool camo = false;
uniform bool debug_parts = false;
varying flat float part;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void vertex() {
	part = COLOR.r * 8.0;
}

void fragment() {
	int r = int(part + 0.5);
	vec3 base = texture(albedo_tex, UV).rgb;
	float cloth = 0.0;
	vec3 cc = vec3(0.0);
	if (r == 1 || (r == 2 && sleeves >= 1) || (r == 3 && sleeves >= 2)) { cc = shirt_col; cloth = 1.0; }
	else if (r == 4 || (r == 5 && legs >= 1)) { cc = pants_col; cloth = 1.0; }
	else if (r == 6) { cc = boots_col; cloth = 1.0; }
	vec3 col = base * skin_tint;
	if (cloth > 0.5) {
		if (camo && r != 6) {
			cc = texture(camo_tex, UV * 7.0).rgb;
		}
		// woven fabric: a fine noise and a soft shade from the body texture
		float weave = 0.88 + 0.12 * hash(floor(UV * 900.0));
		float shade = mix(0.75, 1.1, dot(base, vec3(0.33)) * 1.6);
		col = cc * weave * clamp(shade, 0.7, 1.15);
	}
	if (debug_parts) {
		col = vec3(float(r == 1 || r == 4), float(r == 2 || r == 5), float(r == 3 || r == 6)) * (r >= 4 ? 0.5 : 1.0) + vec3(float(r == 0) * 0.9);
	}
	ALBEDO = col;
	ROUGHNESS = mix(texture(rough_tex, UV).r, 0.92, cloth);
	NORMAL_MAP = mix(texture(normal_tex, UV).rgb, vec3(0.5, 0.5, 1.0), cloth * 0.7);
}
"""
	return _shader


## Adds a hairstyle (its mesh is moved onto the body's skeleton).
static func _add_hair(model: Node3D, sk: Skeleton3D, style: String, color: Color) -> void:
	var path := DIR + style + ".gltf"
	if not ResourceLoader.exists(path):
		return
	var h: Node = (load(path) as PackedScene).instantiate()
	for n in h.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		mi.get_parent().remove_child(mi)
		mi.owner = null
		sk.get_parent().add_child(mi)
		mi.skeleton = mi.get_path_to(sk)
		_tint(mi, color)
	h.free()


## A piece of clothing hung on a bone, placed in the idle pose (model space offsets in metres).
static func _hang(model: Node3D, sk: Skeleton3D, bone: String, node: Node3D, offset: Vector3) -> void:
	var b := sk.find_bone(bone)
	if b < 0:
		node.queue_free()
		return
	var att := BoneAttachment3D.new()
	att.bone_idx = b
	sk.add_child(att)
	var bp := (sk.global_transform * sk.get_bone_global_pose(b)).origin
	var basis := Basis(Vector3.UP, model.global_rotation.y)
	model.add_child(node)
	node.global_transform = Transform3D(basis.scaled(model.scale), bp + basis * (offset * model.scale.x))
	node.reparent(att, true)


static func _piece(model: Node3D, sk: Skeleton3D, piece: String, shirt: Color, pants: Color, outfit: String) -> void:
	var leather := MeshKit.mat(Color(0.28, 0.18, 0.1), 0.8)
	var steel := MeshKit.mat(Color(0.62, 0.64, 0.68), 0.45, 0.6)
	var cloth := MeshKit.mat(shirt.darkened(0.08), 0.95)
	var n := Node3D.new()
	match piece:
		"belt":
			var t := TorusMesh.new()
			t.inner_radius = 0.135
			t.outer_radius = 0.165
			t.rings = 16
			t.ring_segments = 4
			MeshKit.inst(n, t, Vector3.ZERO, leather, Vector3.ZERO, Vector3(1.0, 1.0, 0.8))
			MeshKit.box(n, Vector3(0.06, 0.05, 0.02), Vector3(0, 0, 0.13), MeshKit.mat(Color(0.8, 0.7, 0.3), 0.3, 0.8))
			_hang(model, sk, "pelvis", n, Vector3(0, 0.1, 0))
		"skirt", "coat", "robe":
			var length: float = {"skirt": 0.55, "coat": 0.5, "robe": 0.9}[piece]
			var cm := CylinderMesh.new()
			cm.top_radius = 0.15
			cm.bottom_radius = 0.27 if piece != "robe" else 0.32
			cm.height = length
			cm.radial_segments = 16
			cm.rings = 1
			var mat := MeshKit.mat(shirt if piece != "coat" else shirt.darkened(0.15), 0.95)
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			MeshKit.inst(n, cm, Vector3(0, -length * 0.5 + 0.08, 0), mat, Vector3.ZERO, Vector3(1.0, 1.0, 0.85))
			_hang(model, sk, "pelvis", n, Vector3(0, 0.05, 0))
		"apron":
			MeshKit.box(n, Vector3(0.36, 0.75, 0.02), Vector3(0, -0.2, 0.0), MeshKit.mat(Color(0.45, 0.32, 0.2), 0.9))
			_hang(model, sk, "pelvis", n, Vector3(0, 0.1, 0.16))
		"straw_hat":
			var hat := MeshKit.mat(Color(0.85, 0.72, 0.4), 0.95)
			MeshKit.cyl(n, 0.3, 0.3, 0.02, Vector3.ZERO, hat, Vector3.ZERO, 20)
			MeshKit.cyl(n, 0.1, 0.13, 0.12, Vector3(0, 0.07, 0), hat, Vector3.ZERO, 14)
			MeshKit.cyl(n, 0.132, 0.132, 0.03, Vector3(0, 0.03, 0), MeshKit.mat(Color(0.5, 0.15, 0.1)), Vector3.ZERO, 14)
			_hang(model, sk, "Head", n, Vector3(0, 0.2, 0.0))
		"bracers":
			for s in ["lowerarm_l", "lowerarm_r"]:
				var bn := Node3D.new()
				MeshKit.cyl(bn, 0.045, 0.05, 0.14, Vector3.ZERO, leather, Vector3(0, 0, 90), 10)
				var b := sk.find_bone(s)
				if b >= 0:
					var child := sk.find_bone("hand_" + s.right(1))
					var a := (sk.global_transform * sk.get_bone_global_pose(b)).origin
					var c := (sk.global_transform * sk.get_bone_global_pose(child)).origin if child >= 0 else a
					var mid := a.lerp(c, 0.6)
					var att := BoneAttachment3D.new()
					att.bone_idx = b
					sk.add_child(att)
					model.add_child(bn)
					var dir := (c - a).normalized()
					var side := dir.cross(Vector3.UP).normalized()
					if side.length() < 0.1:
						side = Vector3.RIGHT
					bn.global_transform = Transform3D(Basis(dir, side.cross(dir), side).scaled(model.scale), mid)
					bn.reparent(att, true)
				else:
					bn.queue_free()
			n.queue_free()
		"breastplate":
			MeshKit.sphere(n, 0.17, Vector3(0, 0, 0.05), steel, Vector3(1.0, 1.1, 0.6))
			MeshKit.box(n, Vector3(0.26, 0.04, 0.2), Vector3(0, -0.16, 0.02), leather)
			_hang(model, sk, "spine_03", n, Vector3(0, -0.02, 0.0))
		"pauldrons":
			for s in ["upperarm_l", "upperarm_r"]:
				var pn := Node3D.new()
				MeshKit.sphere(pn, 0.07, Vector3.ZERO, steel, Vector3(1.1, 0.7, 1.1))
				_hang(model, sk, s, pn, Vector3(0, 0.03, 0))
			n.queue_free()
		"helmet":
			MeshKit.sphere(n, 0.14, Vector3(0, 0.0, 0.0), steel, Vector3(1.0, 0.8, 1.1))
			MeshKit.cyl(n, 0.15, 0.155, 0.03, Vector3(0, -0.04, 0.0), steel, Vector3.ZERO, 18)
			MeshKit.box(n, Vector3(0.02, 0.07, 0.04), Vector3(0, -0.07, 0.14), steel)
			_hang(model, sk, "Head", n, Vector3(0, 0.15, 0.0))
		_:
			n.queue_free()
