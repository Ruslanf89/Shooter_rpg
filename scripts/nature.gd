class_name Nature
extends RefCounted
## Vegetation: procedural trees with textured bark and alpha-cut leaf / needle cards (MultiMesh),
## leafy card bushes, plus scanned Poly Haven rocks, shrubs, ferns and fallen logs.

const LEAF_TEX := "res://assets/textures/leaf_cluster.png"
const PINE_TEX := "res://assets/textures/pine_cluster.png"
const LEAF_REF := Color(0.42, 0.55, 0.24)    # average colour of the leaf texture
const PINE_REF := Color(0.2, 0.34, 0.14)     # average colour of the needle texture
const CHUNK := 70.0                          # multimesh chunk size (for frustum culling)

static var _card_shader: Shader
static var _models := {}


static func card_material(tex_path: String, colors: Array, ref: Color, snow := 0.0) -> ShaderMaterial:
	if _card_shader == null:
		_card_shader = load("res://shaders/leaf_cards.gdshader")
	var m := ShaderMaterial.new()
	m.shader = _card_shader
	m.set_shader_parameter("leaf_tex", load(tex_path))
	m.set_shader_parameter("tint", _tint(colors[1], ref))
	m.set_shader_parameter("tint2", _tint((colors[1] as Color).lerp(colors[2], 0.45), ref))
	m.set_shader_parameter("snow", snow)
	return m


static func _tint(c: Color, ref: Color) -> Vector3:
	return Vector3.ONE.lerp(Vector3(c.r / ref.r, c.g / ref.g, c.b / ref.b), 0.85)


static func bark_material(tint: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = MeshKit.tex("Bark014")
	m.albedo_color = Color(1, 1, 1).lerp(tint, 0.45)
	m.normal_enabled = true
	m.normal_texture = MeshKit.normal_tex("Bark014")
	m.normal_scale = 1.4
	m.roughness = 0.95
	m.uv1_scale = Vector3(1.0, 0.6, 1.0)
	return m


# --------------------------------------------------------------------------- mesh builders

class MeshData:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	var idx := PackedInt32Array()

	func commit() -> ArrayMesh:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_TEX_UV] = uvs
		if not colors.is_empty():
			arrays[Mesh.ARRAY_COLOR] = colors
		arrays[Mesh.ARRAY_INDEX] = idx
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return mesh


## Adds a tube along `pts` with per-ring radius; `lobes` adds root flares near the bottom.
static func _tube(md: MeshData, pts: Array, radii: Array, segs: int, lobes := 0.0, lobe_count := 5, phase := 0.0) -> void:
	var start := md.verts.size()
	var rings := pts.size()
	var v_acc := 0.0
	for i in rings:
		var p: Vector3 = pts[i]
		var dir: Vector3 = (pts[mini(i + 1, rings - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var side := dir.cross(Vector3.FORWARD if absf(dir.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
		var up := side.cross(dir).normalized()
		if i > 0:
			v_acc += p.distance_to(pts[i - 1])
		var t := float(i) / (rings - 1)
		for j in segs + 1:
			var a := TAU * j / segs
			var r: float = radii[i]
			if lobes > 0.0:
				r *= 1.0 + lobes * pow(1.0 - t, 3.0) * maxf(0.0, sin(a * lobe_count + phase))
			var n := (side * cos(a) + up * sin(a))
			md.verts.append(p + n * r)
			md.normals.append(n)
			md.uvs.append(Vector2(float(j) / segs * 2.0, v_acc / 2.5))
			md.colors.append(Color(1, 1, 1))
	for i in rings - 1:
		for j in segs:
			var a := start + i * (segs + 1) + j
			var b := a + segs + 1
			md.idx.append_array(PackedInt32Array([a, a + 1, b, a + 1, b + 1, b]))   # clockwise = front


static func trunk_mesh(rng: RandomNumberGenerator, height: float, radius: float, flare: float, bend: float, branches: int, branch_len: float) -> ArrayMesh:
	var md := MeshData.new()
	var bend_dir := Vector2.from_angle(rng.randf() * TAU) * bend
	var pts := []
	var radii := []
	var rings := 9
	for i in rings + 1:
		var t := float(i) / rings
		var wob := Vector2(sin(t * 5.0 + rng.randf()) * 0.08, cos(t * 4.0) * 0.08)
		pts.append(Vector3(bend_dir.x * t * t + wob.x, t * height, bend_dir.y * t * t + wob.y))
		radii.append(radius * (1.0 - 0.55 * t) * (1.0 + flare * pow(1.0 - t, 6.0)))
	var root: Vector3 = pts[0]
	root.y = -0.4
	pts[0] = root
	_tube(md, pts, radii, 12, 0.55, rng.randi_range(4, 6), rng.randf() * TAU)
	# branches reaching into the crown
	for b in branches:
		var t0 := rng.randf_range(0.45, 0.85)
		var origin: Vector3 = pts[int(t0 * rings)]
		var a := TAU * b / branches + rng.randf_range(-0.4, 0.4)
		var dir := Vector3(cos(a), rng.randf_range(0.5, 1.1), sin(a)).normalized()
		var bp := []
		var br := []
		var n := 5
		for k in n:
			var s := float(k) / (n - 1)
			bp.append(origin + dir * branch_len * s + Vector3(sin(s * 3.0 + a) * 0.3, -0.25 * s * s, 0))
			br.append(lerpf(radius * 0.42, radius * 0.06, s))
		_tube(md, bp, br, 6)
	return md.commit()


## One textured card (a quad) from `base` towards `up`, in the plane with normal `nrm`.
## `quad` picks one of the 2x2 atlas cells; normals point away from `center` (round shading).
static func _card(md: MeshData, base: Vector3, up: Vector3, nrm: Vector3, w: float, h: float, quad: int, center: Vector3, ao0: float, ao1: float) -> void:
	var right := nrm.cross(up).normalized() * w * 0.5
	var tip := base + up * h
	var u0 := (quad % 2) * 0.5
	var v0 := (quad / 2) * 0.5
	var corners := [base - right, base + right, tip + right, tip - right]
	var uv := [Vector2(u0, v0 + 0.5), Vector2(u0 + 0.5, v0 + 0.5), Vector2(u0 + 0.5, v0), Vector2(u0, v0)]
	var start := md.verts.size()
	for i in 4:
		var p: Vector3 = corners[i]
		md.verts.append(p)
		md.normals.append(((p - center).normalized() + Vector3(0, 0.35, 0)).normalized())
		md.uvs.append(uv[i])
		var a := ao0 if i < 2 else ao1
		md.colors.append(Color(a, a, a))
	md.idx.append_array(PackedInt32Array([start, start + 1, start + 2, start, start + 2, start + 3]))


static func _rand_dir(rng: RandomNumberGenerator) -> Vector3:
	return Vector3(rng.randfn(), rng.randfn(), rng.randfn()).normalized()


## Broadleaf crown: pairs of crossed leaf-twig cards scattered through a few overlapping blobs
## ([center, radius]); most cards sit near the surface, the inner ones are shaded darker.
static func leaf_crown(rng: RandomNumberGenerator, blobs: Array, cards: int, card_size: float) -> ArrayMesh:
	var md := MeshData.new()
	var center := Vector3.ZERO
	var total := 0.0
	for b in blobs:
		center += b[0]
		total += float(b[1]) * float(b[1])
	center /= blobs.size()
	for i in cards:
		var pick := rng.randf() * total
		var blob: Array = blobs[0]
		for b in blobs:
			pick -= float(b[1]) * float(b[1])
			if pick <= 0.0:
				blob = b
				break
		var c: Vector3 = blob[0]
		var r: float = blob[1]
		var d := Vector3(rng.randfn(), rng.randfn() * 0.75 + 0.2, rng.randfn()).normalized()
		var depth := lerpf(0.4, 1.0, sqrt(rng.randf()))
		var p := c + d * r * depth
		var out := (p - center).normalized()
		var up := (out + Vector3(0, 0.55, 0) + _rand_dir(rng) * 0.45).normalized()
		var nrm := _rand_dir(rng).cross(up).normalized()
		var s := card_size * rng.randf_range(0.75, 1.2)
		var base := p - up * s * 0.4
		var ao := clampf(0.15 + 0.6 * depth + 0.3 * (out.y * 0.5 + 0.5), 0.0, 1.0)
		var q := rng.randi() % 4
		_card(md, base, up, nrm, s, s, q, center, ao * 0.65, ao)
		_card(md, base, up, nrm.cross(up).normalized(), s, s, (q + 1) % 4, center, ao * 0.65, ao)
	return md.commit()


## Conifer crown: whorls of drooping needle sprays, long at the bottom and short at the top.
static func pine_crown(rng: RandomNumberGenerator, base_y: float, height: float, radius: float) -> ArrayMesh:
	var md := MeshData.new()
	var center := Vector3(0, base_y + (height - base_y) * 0.35, 0)
	var y := base_y
	while y < height - 0.6:
		var t := (y - base_y) / (height - base_y)
		var length := radius * pow(1.0 - t, 0.9) + 0.5
		var n := 6 if t < 0.65 else 4
		var a0 := rng.randf() * TAU
		for k in n:
			var a := a0 + TAU * k / n + rng.randf_range(-0.25, 0.25)
			var dir := Vector3(cos(a), -0.3 + t * 0.45 + rng.randf_range(-0.08, 0.08), sin(a)).normalized()
			var side := Vector3(-sin(a), 0, cos(a))
			var nrm := dir.cross(side).normalized()
			if nrm.y < 0.0:
				nrm = -nrm
			var base := Vector3(cos(a) * 0.12, y, sin(a) * 0.12)
			var ao := clampf(0.45 + 0.55 * t, 0.0, 1.0)
			_card(md, base, dir, nrm, length * 0.8, length, rng.randi() % 4, center, ao * 0.55, ao)
			var tilt := deg_to_rad(rng.randf_range(35.0, 55.0)) * (1.0 if k % 2 == 0 else -1.0)
			_card(md, base + Vector3(0, 0.12, 0), dir, nrm.rotated(dir, tilt), length * 0.6, length * 0.85, rng.randi() % 4, center, ao * 0.55, ao)
		y += rng.randf_range(0.55, 0.8)
	for k in 2:
		_card(md, Vector3(0, height - 0.9, 0), Vector3.UP, Vector3(cos(k * PI * 0.5), 0, sin(k * PI * 0.5)), 1.1, 1.9, rng.randi() % 4, center, 0.8, 1.0)
	return md.commit()


static func _broadleaf_blobs(rng: RandomNumberGenerator, center: Vector3, radius: float, count: int) -> Array:
	var blobs := [[center, radius * 0.72]]
	for i in count - 1:
		var a := TAU * i / (count - 1) + rng.randf_range(-0.4, 0.4)
		var off := Vector3(cos(a) * radius * rng.randf_range(0.4, 0.8), rng.randf_range(-0.35, 0.45) * radius, sin(a) * radius * rng.randf_range(0.4, 0.8))
		blobs.append([center + off, radius * rng.randf_range(0.42, 0.62)])
	return blobs


# --------------------------------------------------------------------------- placement

## MultiMeshes split into CHUNK-sized cells so off-screen parts of the forest get culled.
static func _multimesh(parent: Node3D, mesh: Mesh, mat: Material, xforms: Array, shadows := true, view_range := 0.0, chunk := CHUNK) -> void:
	var cells := {}
	for t: Transform3D in xforms:
		var key := Vector2i(floori(t.origin.x / chunk), floori(t.origin.z / chunk))
		if not cells.has(key):
			cells[key] = []
		cells[key].append(t)
	for key: Vector2i in cells:
		var list: Array = cells[key]
		var center := Vector3((key.x + 0.5) * chunk, 0, (key.y + 0.5) * chunk)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = list.size()
		for i in list.size():
			var t: Transform3D = list[i]
			t.origin -= center
			mm.set_instance_transform(i, t)
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = mat
		mmi.position = center
		if not shadows:
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if view_range > 0.0:
			mmi.visibility_range_end = view_range + chunk * 0.7
			mmi.visibility_range_end_margin = 10.0
			mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		parent.add_child(mmi)


## Plants trees at `points` (Vector3 on the ground) using the Stylized Nature MegaKit (Quaternius,
## CC0): common trees and pines, dead and twisted trees for the "dead" style. cfg keys: tree_style,
## foliage, pine_foliage, bark_tint, pine_ratio, leaf_snow - leaves and bark are tinted per level.
static func plant_trees(parent: Node3D, points: Array, cfg: Dictionary, rng: RandomNumberGenerator) -> void:
	var style: String = cfg.get("tree_style", "oak")
	var snow: float = cfg.get("leaf_snow", 0.0)
	var foliage: Array = cfg["foliage"]
	var pine_fol: Array = cfg.get("pine_foliage", foliage)
	var leaf_t := _kit_tint(foliage[1], LEAF_REF, snow)
	var pine_t := _kit_tint(pine_fol[1], PINE_REF, snow)
	var bark_t: Color = Color(1, 1, 1).lerp(cfg.get("bark_tint", Color(1, 1, 1)), 0.5)
	var broad := ["CommonTree_1", "CommonTree_2", "CommonTree_3", "CommonTree_4", "CommonTree_5"]
	if style == "dead":
		broad = ["DeadTree_1", "DeadTree_2", "DeadTree_3", "DeadTree_4", "DeadTree_5", "TwistedTree_1", "TwistedTree_3"]
	var pines := ["Pine_1", "Pine_2", "Pine_3", "Pine_4", "Pine_5"]
	var pine_ratio: float = cfg.get("pine_ratio", 0.2)
	var groups := {}
	var trunk_shape := CylinderShape3D.new()
	trunk_shape.radius = 0.6
	trunk_shape.height = 6.0
	for p: Vector3 in points:
		var pine := rng.randf() < pine_ratio
		var name: String = pines[rng.randi() % pines.size()] if pine else broad[rng.randi() % broad.size()]
		var h := kit_size(name).y
		var target := rng.randf_range(11.0, 15.0) if pine else (rng.randf_range(10.0, 14.0) if not name.begins_with("Twisted") else rng.randf_range(11.0, 14.0))
		var s := target / maxf(h, 0.1)
		var t := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * s), p + Vector3(0, -0.15, 0))
		if not groups.has(name):
			groups[name] = []
		groups[name].append(t)
		var body := StaticBody3D.new()
		body.position = p
		body.set_meta("surface", "wood")
		var cs := CollisionShape3D.new()
		cs.shape = trunk_shape
		cs.position.y = 3.0
		cs.scale = Vector3(s, 1.0, s) * 0.55 if not name.begins_with("Twisted") else Vector3(s, 1.0, s) * 0.8
		body.add_child(cs)
		parent.add_child(body)
	for name in groups:
		var tints := {"Leaves": pine_t if (name as String).begins_with("Pine") else leaf_t, "Bark": bark_t}
		_multimesh(parent, kit_mesh(name, tints), null, groups[name])


## Bushes from the nature kit, tinted with the level's bush colours.
static func plant_bushes(parent: Node3D, points: Array, colors: Array, rng: RandomNumberGenerator, snow := 0.0) -> void:
	var tint := _kit_tint(colors[1], LEAF_REF, snow)
	var names := ["Bush_Common", "Bush_Common_Flowers", "Bush_Common"]
	var groups := {}
	for p: Vector3 in points:
		var name: String = names[rng.randi() % names.size()]
		if not groups.has(name):
			groups[name] = []
		groups[name].append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * rng.randf_range(0.8, 1.5)), p + Vector3(0, -0.1, 0)))
	for name in groups:
		_multimesh(parent, kit_mesh(name, {"Leaves": tint}), null, groups[name], true, 130.0)


## Ground cover around a level: flowers, grass clumps, clover, mushrooms and pebbles (no collision).
static func scatter_cover(parent: Node3D, points: Array, cfg: Dictionary, rng: RandomNumberGenerator) -> void:
	var snow: float = cfg.get("leaf_snow", 0.0)
	var foliage: Array = cfg.get("bush_foliage", cfg["foliage"])
	var tint := _kit_tint(foliage[1], LEAF_REF, snow * 0.6)
	var kinds: Array
	if cfg.get("tree_style", "oak") == "dead":
		kinds = ["Grass_Wispy_Tall", "Mushroom_Common", "Mushroom_Laetiporus", "Pebble_Round_1", "Fern_1"]
	else:
		kinds = ["Grass_Common_Tall", "Grass_Wispy_Short", "Flower_3_Group", "Flower_4_Group", "Clover_1", "Mushroom_Common", "Pebble_Round_2"]
	var groups := {}
	for p: Vector3 in points:
		var name: String = kinds[rng.randi() % kinds.size()]
		if not groups.has(name):
			groups[name] = []
		groups[name].append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * rng.randf_range(0.6, 1.1)), p + Vector3(0, -0.03, 0)))
	for name in groups:
		_multimesh(parent, kit_mesh(name, {"Leaves": tint, "Grass": tint}), null, groups[name], false, 70.0, 140.0)


## Kit plants without collision (shrubs, ferns) as multimeshes: size in metres across (or tall).
static func plant_kit(parent: Node3D, points: Array, names: Array, tint: Color, size_range: Vector2, view_range: float, by_height := false, rng: RandomNumberGenerator = null) -> void:
	if rng == null:
		rng = RandomNumberGenerator.new()
	var groups := {}
	for p: Vector3 in points:
		var name: String = names[rng.randi() % names.size()]
		var sz := kit_size(name)
		var base := sz.y if by_height else maxf(sz.x, sz.z)
		var s := rng.randf_range(size_range.x, size_range.y) / maxf(base, 0.01)
		if not groups.has(name):
			groups[name] = []
		groups[name].append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * s), p + Vector3(0, -0.04, 0)))
	for name in groups:
		_multimesh(parent, kit_mesh(name, {"Leaves": tint}), null, groups[name], false, view_range)


## Kit plants (shrubs, ferns) placed like scanned models.
static func kit_parts(names: Array, tint := Color(1, 1, 1), tint_key := "Leaves") -> Array:
	var parts := []
	for name in names:
		var mesh := kit_mesh(name, {tint_key: tint} if tint != Color(1, 1, 1) else {})
		var aabb := mesh.get_aabb()
		var bottom := Vector3(aabb.get_center().x, aabb.position.y, aabb.get_center().z)
		parts.append({"mesh": mesh, "xform": Transform3D(Basis(), -bottom), "size": aabb.size})
	return parts


static var _kit := {}


## A nature-kit mesh; `tints` multiplies the colour of materials whose name starts with a key.
static func kit_mesh(name: String, tints := {}) -> Mesh:
	var key := name + str(tints)
	if _kit.has(key):
		return _kit[key]
	var base_key := name + "{}"
	var base: Mesh = _kit.get(base_key)
	if base == null:
		var root: Node = (load("res://assets/models/nature_kit/%s.gltf" % name) as PackedScene).instantiate()
		var mi := root.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
		base = mi.mesh
		root.free()
		_kit[base_key] = base
	if tints.is_empty():
		return base
	var m := base.duplicate() as Mesh
	for i in m.get_surface_count():
		var mat := m.surface_get_material(i)
		if not (mat is BaseMaterial3D):
			continue
		for k in tints:
			if String(mat.resource_name).begins_with(k):
				var dm := (mat as BaseMaterial3D).duplicate() as BaseMaterial3D
				var c: Color = tints[k]
				dm.albedo_color = Color(dm.albedo_color.r * c.r, dm.albedo_color.g * c.g, dm.albedo_color.b * c.b, dm.albedo_color.a)
				m.surface_set_material(i, dm)
	_kit[key] = m
	return m


static func kit_size(name: String) -> Vector3:
	return kit_mesh(name).get_aabb().size


## Tint that moves the kit's green leaves towards a level's foliage colour (and snow).
static func _kit_tint(target: Color, ref: Color, snow := 0.0) -> Color:
	var c := Color(clampf(target.r / ref.r, 0.25, 2.4), clampf(target.g / ref.g, 0.25, 2.0), clampf(target.b / ref.b, 0.25, 2.4))
	c = c.lerp(Color(0.6, 0.6, 0.6), 0.35)
	return c.lerp(Color(2.2, 2.3, 2.5), snow)

# --------------------------------------------------------------------------- scanned models (Poly Haven, CC0)

## Mesh parts of res://assets/models/nature/<id>/<id>.gltf, each re-centred so its base sits at
## the origin: [{mesh, xform, size}]. `include` filters parts by node name.
static func model_parts(id: String, include := "") -> Array:
	var key := id + "|" + include
	if _models.has(key):
		return _models[key]
	var parts := []
	var path := "res://assets/models/nature/%s/%s.gltf" % [id, id]
	if ResourceLoader.exists(path):
		var root: Node = (load(path) as PackedScene).instantiate()
		_collect(root, Transform3D(), parts, include)
		root.free()
	_models[key] = parts
	return parts


static func _collect(n: Node, xf: Transform3D, parts: Array, include: String) -> void:
	var t := xf
	if n is Node3D:
		t = xf * (n as Node3D).transform
	if n is MeshInstance3D and (include == "" or String(n.name).contains(include)):
		var mesh: Mesh = (n as MeshInstance3D).mesh
		var aabb := t * mesh.get_aabb()
		var bottom := Vector3(aabb.get_center().x, aabb.position.y, aabb.get_center().z)
		parts.append({"mesh": mesh, "xform": Transform3D(t.basis, t.origin - bottom), "size": aabb.size})
	for c in n.get_children():
		_collect(c, t, parts, include)


## Places scanned models at `points`. Each gets a random size in `size_range` (metres, measured
## across - or tall when `by_height`), optional convex collision, and a view distance.
static func place_models(parent: Node3D, points: Array, parts: Array, rng: RandomNumberGenerator, size_range: Vector2,
		collide: bool, view_range := 0.0, tint := Color(1, 1, 1), by_height := false, sink := 0.12) -> void:
	if parts.is_empty():
		return
	var tinted := {}
	for p: Vector3 in points:
		var part: Dictionary = parts[rng.randi() % parts.size()]
		var sz: Vector3 = part["size"]
		var base := sz.y if by_height else maxf(sz.x, sz.z)
		var s := rng.randf_range(size_range.x, size_range.y) / maxf(base, 0.01)
		var place := Transform3D(Basis(Vector3.UP, rng.randf() * TAU), p)
		var local := Transform3D(Basis.from_scale(Vector3.ONE * s), Vector3(0, -sink * sz.y * s, 0)) * (part["xform"] as Transform3D)
		var mi := MeshInstance3D.new()
		mi.mesh = part["mesh"]
		mi.transform = place * local
		if tint != Color(1, 1, 1):
			mi.material_override = _tinted(part["mesh"], tint, tinted)
		if view_range > 0.0:
			mi.visibility_range_end = view_range
			mi.visibility_range_end_margin = 10.0
			mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		if base * s < 0.9:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mi)
		if collide:
			if not part.has("shape"):
				part["shape"] = (part["mesh"] as Mesh).create_convex_shape(true, true)
			var body := StaticBody3D.new()
			body.transform = place
			var cs := CollisionShape3D.new()
			cs.shape = part["shape"]
			cs.transform = local
			body.add_child(cs)
			parent.add_child(body)


static func _tinted(mesh: Mesh, tint: Color, cache: Dictionary) -> Material:
	if not cache.has(mesh):
		var m: Material = mesh.surface_get_material(0)
		if m is BaseMaterial3D:
			m = m.duplicate()
			(m as BaseMaterial3D).albedo_color = tint
		cache[mesh] = m
	return cache[mesh]


## Natural rocks (moss-covered set in lush levels, bare boulders elsewhere).
static func place_rocks(parent: Node3D, points: Array, rng: RandomNumberGenerator, lush: bool, tint := Color(1, 1, 1), size_range := Vector2(0.9, 3.4)) -> void:
	var parts := kit_parts(["Rock_Medium_1", "Rock_Medium_2", "Rock_Medium_3"])
	if not lush:
		parts.append_array(model_parts("boulder_01"))
	place_models(parent, points, parts, rng, size_range, true, 0.0, tint, false, 0.15)
