class_name Terrain
extends Node3D
## Height-mapped ground: rolling hills, flattened building areas and paths, lakes,
## mountain rim, painted terrain shader and wind-swept grass.

const RES := 2.0                 # meters between height samples (visual mesh)

var half := 140.0
var hill_amp := 6.0
var rim_height := 32.0
var sea_z := 0.0               # if set, the land slopes into the sea beyond this z
var seed_value := 1
var flat_zones: Array = []       # [Vector2 center, float radius]
var lakes: Array = []            # [Vector2 center, float radius, float depth]
var paths: Array = []            # [Vector2 a, Vector2 b]
var mask_img: Image              # R path, G paving, B field
var mask_size := 512

var _n := 0
var _heights := PackedFloat32Array()
var _noise := FastNoiseLite.new()
var _noise2 := FastNoiseLite.new()


func generate() -> void:
	_noise.seed = seed_value
	_noise.frequency = 0.011
	_noise.fractal_octaves = 4
	_noise2.seed = seed_value + 7
	_noise2.frequency = 0.03
	_n = int(half * 2.0 / RES) + 1
	_heights.resize(_n * _n)
	for iz in _n:
		for ix in _n:
			_heights[iz * _n + ix] = _height_fn(-half + ix * RES, -half + iz * RES)
	# Terrain3D draws the ground when the addon is there (built in apply_material, once the paths
	# and fields are painted); our own heightmap still gives collision, heights and occlusion
	if not use_terrain3d():
		_build_mesh()
	_build_collision()
	_build_occluder()


func _height_fn(x: float, z: float) -> float:
	var p := Vector2(x, z)
	var h := (_noise.get_noise_2d(x, z) * 0.5 + 0.5) * hill_amp * 1.6
	var d := 999.0
	for zone in flat_zones:
		var c: Vector2 = zone[0]
		d = minf(d, p.distance_to(c) - float(zone[1]))
	for seg in paths:
		d = minf(d, Geometry2D.get_closest_point_to_segment(p, seg[0], seg[1]).distance_to(p) - 3.0)
	h *= smoothstep(0.0, 22.0, d)
	for lake in lakes:
		var lc: Vector2 = lake[0]
		var k := p.distance_to(lc) / float(lake[1])
		if k < 1.4:
			h = lerpf(-float(lake[2]), h, smoothstep(0.55, 1.4, k))
	var e := maxf(absf(x), absf(z))
	var rim := smoothstep(half - 45.0, half - 5.0, e)
	var rim_k := 1.0
	if sea_z != 0.0:
		rim_k = 1.0 - smoothstep(sea_z - 40.0, sea_z - 5.0, z)
		h = lerpf(h, -4.5, smoothstep(sea_z, sea_z + 22.0, z))
	h += rim * rim * rim_height * rim_k * (0.75 + 0.5 * (_noise2.get_noise_2d(x, z) * 0.5 + 0.5))
	return h


## Smooth ground height at any world position.
func height_at(x: float, z: float) -> float:
	var fx := clampf((x + half) / RES, 0.0, _n - 1.001)
	var fz := clampf((z + half) / RES, 0.0, _n - 1.001)
	var ix := int(fx)
	var iz := int(fz)
	var tx := fx - ix
	var tz := fz - iz
	var h00 := _heights[iz * _n + ix]
	var h10 := _heights[iz * _n + ix + 1]
	var h01 := _heights[(iz + 1) * _n + ix]
	var h11 := _heights[(iz + 1) * _n + ix + 1]
	# match the triangle split used by the mesh
	if tx + tz <= 1.0:
		return h00 + (h10 - h00) * tx + (h01 - h00) * tz
	return h11 + (h01 - h11) * (1.0 - tx) + (h10 - h11) * (1.0 - tz)


func slope_at(x: float, z: float) -> float:
	var dx := height_at(x + 1.0, z) - height_at(x - 1.0, z)
	var dz := height_at(x, z + 1.0) - height_at(x, z - 1.0)
	return Vector2(dx, dz).length() * 0.5


func _build_mesh() -> void:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	verts.resize(_n * _n)
	normals.resize(_n * _n)
	for iz in _n:
		for ix in _n:
			var i := iz * _n + ix
			verts[i] = Vector3(-half + ix * RES, _heights[i], -half + iz * RES)
			var hl := _heights[iz * _n + maxi(ix - 1, 0)]
			var hr := _heights[iz * _n + mini(ix + 1, _n - 1)]
			var hd := _heights[maxi(iz - 1, 0) * _n + ix]
			var hu := _heights[mini(iz + 1, _n - 1) * _n + ix]
			normals[i] = Vector3(hl - hr, 2.0 * RES, hd - hu).normalized()
	var idx := PackedInt32Array()
	idx.resize((_n - 1) * (_n - 1) * 6)
	var k := 0
	for iz in _n - 1:
		for ix in _n - 1:
			var a := iz * _n + ix
			var b := a + 1
			var c := a + _n
			var d := c + 1
			idx[k] = a; idx[k + 1] = b; idx[k + 2] = c
			idx[k + 3] = b; idx[k + 4] = d; idx[k + 5] = c
			k += 6
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.name = "Ground"
	mi.mesh = mesh
	add_child(mi)
	_ground = mi


var _ground: MeshInstance3D


## Coarse copy of the ground (8 m grid, kept a little below the real surface) used for
## occlusion culling: anything behind a hill is not drawn.
func _build_occluder() -> void:
	var step := 8.0
	var n := int(half * 2.0 / step) + 1
	var verts := PackedVector3Array()
	verts.resize(n * n)
	for iz in n:
		for ix in n:
			var x := -half + ix * step
			var z := -half + iz * step
			# lowest height around the vertex so the occluder never pokes above the ground
			var h := INF
			for dz in [-step * 0.5, 0.0, step * 0.5]:
				for dx in [-step * 0.5, 0.0, step * 0.5]:
					h = minf(h, height_at(clampf(x + dx, -half, half), clampf(z + dz, -half, half)))
			verts[iz * n + ix] = Vector3(x, h - 0.8, z)
	var idx := PackedInt32Array()
	for iz in n - 1:
		for ix in n - 1:
			var a := iz * n + ix
			idx.append_array(PackedInt32Array([a, a + 1, a + n, a + 1, a + n + 1, a + n]))
	var occ := ArrayOccluder3D.new()
	occ.set_arrays(verts, idx)
	var oi := OccluderInstance3D.new()
	oi.occluder = occ
	add_child(oi)

func _build_collision() -> void:
	# 1 m collision grid, interpolated from the visual heights
	var w := int(half * 2.0) + 1
	var data := PackedFloat32Array()
	data.resize(w * w)
	for iz in w:
		for ix in w:
			data[iz * w + ix] = height_at(-half + ix, -half + iz)
	var shape := HeightMapShape3D.new()
	shape.map_width = w
	shape.map_depth = w
	shape.map_data = data
	var body := StaticBody3D.new()
	body.set_meta("surface", "ground")
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	add_child(body)


# --------------------------------------------------------------------------- mask painting

func init_mask() -> void:
	mask_img = Image.create_empty(mask_size, mask_size, false, Image.FORMAT_RGBA8)
	mask_img.fill(Color(0, 0, 0, 1))


func _to_px(p: Vector2) -> Vector2:
	return (p / (half * 2.0) + Vector2(0.5, 0.5)) * mask_size


func _to_world(px: int, py: int) -> Vector2:
	return (Vector2(px + 0.5, py + 0.5) / mask_size - Vector2(0.5, 0.5)) * half * 2.0


func _paint(px: int, py: int, channel: int, v: float) -> void:
	var c := mask_img.get_pixel(px, py)
	c[channel] = maxf(c[channel], v)
	mask_img.set_pixel(px, py, c)


func paint_segment(a: Vector2, b: Vector2, width: float, channel := 0) -> void:
	var m := width * 0.5 + 2.0
	var pa := _to_px(Vector2(minf(a.x, b.x) - m, minf(a.y, b.y) - m))
	var pb := _to_px(Vector2(maxf(a.x, b.x) + m, maxf(a.y, b.y) + m))
	for py in range(maxi(0, int(pa.y)), mini(mask_size, int(pb.y) + 1)):
		for px in range(maxi(0, int(pa.x)), mini(mask_size, int(pb.x) + 1)):
			var wp := _to_world(px, py)
			var d := Geometry2D.get_closest_point_to_segment(wp, a, b).distance_to(wp)
			var v := 1.0 - smoothstep(width * 0.5 - 1.0, width * 0.5 + 1.0, d)
			if v > 0.0:
				_paint(px, py, channel, v)


func paint_circle(c: Vector2, r: float, channel: int) -> void:
	paint_segment(c, c + Vector2(0.01, 0), r * 2.0, channel)


func paint_rect(rect: Rect2, channel: int) -> void:
	var pa := _to_px(rect.position)
	var pb := _to_px(rect.end)
	for py in range(maxi(0, int(pa.y)), mini(mask_size, int(pb.y) + 1)):
		for px in range(maxi(0, int(pa.x)), mini(mask_size, int(pb.x) + 1)):
			_paint(px, py, channel, 1.0)


func mask_at(x: float, z: float) -> Color:
	var p := _to_px(Vector2(x, z))
	return mask_img.get_pixel(clampi(int(p.x), 0, mask_size - 1), clampi(int(p.y), 0, mask_size - 1))


# --------------------------------------------------------------------------- material

## Terrain3D (TokisanGames, MIT) renders the ground: clipmap LODs, texture blending, normal maps.
static func use_terrain3d() -> bool:
	return ClassDB.class_exists("Terrain3D") and ResourceLoader.exists(T3D_DIR + "Grass004_alb_ht.png")


func apply_material(cfg: Dictionary) -> void:
	if use_terrain3d():
		_build_terrain3d(cfg)
		return
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/terrain.gdshader")
	# levels can swap layers, e.g. "grass_tex": "Snow006"
	var grass: String = cfg.get("grass_tex", "Grass004")
	var floor_t: String = cfg.get("floor_tex", "Ground037")
	m.set_shader_parameter("grass_tex", MeshKit.tex(grass))
	m.set_shader_parameter("floor_tex", MeshKit.tex(floor_t))
	m.set_shader_parameter("dirt_tex", MeshKit.tex("Ground048"))
	m.set_shader_parameter("rock_tex", MeshKit.tex(cfg.get("rock_tex", "Rock030")))
	m.set_shader_parameter("stone_tex", MeshKit.tex("PavingStones070"))
	for pair in [["grass_n", grass], ["floor_n", floor_t], ["dirt_n", "Ground048"], ["stone_n", "PavingStones070"]]:
		var path := "res://assets/textures/%s_normal.jpg" % pair[1]
		if ResourceLoader.exists(path):
			m.set_shader_parameter(pair[0], load(path))
	m.set_shader_parameter("mask_tex", ImageTexture.create_from_image(mask_img))
	var var_noise := FastNoiseLite.new()
	var_noise.frequency = 0.02
	var var_tex := NoiseTexture2D.new()
	var_tex.width = 256
	var_tex.height = 256
	var_tex.seamless = true
	var_tex.noise = var_noise
	m.set_shader_parameter("variation_tex", var_tex)
	m.set_shader_parameter("map_size", half * 2.0)
	for key in ["grass_tint", "grass_tint2", "floor_tint", "dirt_tint", "rock_tint", "stone_tint", "field_tint", "floor_amount", "saturation", "field_saturation"]:
		if cfg.has(key):
			m.set_shader_parameter(key, cfg[key])
	_ground.material_override = m


# --------------------------------------------------------------------------- Terrain3D

const T3D_DIR := "res://assets/terrain3d/"
enum { T_GRASS, T_FLOOR, T_DIRT, T_STONE, T_FIELD, T_ROCK }
var terrain3d: Node3D


## The same ground as our heightmap, drawn by Terrain3D at 1 m per vertex. Every vertex gets a base
## texture (grass) and an overlay (moss/floor, dirt path, paving, field or rock on steep slopes)
## with a blend amount, following the same rules as the old terrain shader. A colour map adds the
## grass tint variation. Terrain3D's own collision is off: ours matches height_at() exactly.
func _build_terrain3d(cfg: Dictionary) -> void:
	var t: Node3D = ClassDB.instantiate("Terrain3D")
	t.name = "Terrain3D"
	t.set("collision_mode", 0)
	t.set("vertex_spacing", 1.0)
	# our textures are built here, not loaded from a saved asset file: keep them when entering the tree
	t.set("free_editor_textures", false)
	# textures (packed albedo+height / normal+roughness, see assets/terrain3d)
	var assets: Resource = ClassDB.instantiate("Terrain3DAssets")
	var grass: String = cfg.get("grass_tex", "Grass004")
	var tint := func(key: String) -> Color:
		var v: Vector3 = cfg.get(key, Vector3.ONE)
		return Color(v.x, v.y, v.z)
	var g1: Color = tint.call("grass_tint")
	var g2: Color = tint.call("grass_tint2") if cfg.has("grass_tint2") else g1
	var gmax := Color(maxf(g1.r, g2.r), maxf(g1.g, g2.g), maxf(g1.b, g2.b))
	var field: Color = tint.call("field_tint")
	if float(cfg.get("field_saturation", 1.0)) < 0.7:
		field = field * Color(1.05, 0.95, 0.8)    # pale sand
	var layers := [[grass, gmax, 0.22], [cfg.get("floor_tex", "Ground037"), tint.call("floor_tint"), 0.16],
		["Ground048", tint.call("dirt_tint"), 0.28], ["PavingStones070", tint.call("stone_tint"), 0.33],
		["Ground048", field, 0.2], [cfg.get("rock_tex", "Rock030"), tint.call("rock_tint"), 0.12]]
	for i in layers.size():
		var l: Array = layers[i]
		var ta: Resource = ClassDB.instantiate("Terrain3DTextureAsset")
		ta.set("name", "%s_%d" % [l[0], i])
		ta.set("albedo_texture", load(T3D_DIR + l[0] + "_alb_ht.png"))
		ta.set("normal_texture", load(T3D_DIR + l[0] + "_nrm_rgh.png"))
		ta.set("albedo_color", l[1])
		ta.set("uv_scale", l[2])
		ta.set("normal_depth", 0.8)
		ta.set("detiling_rotation", 0.15)
		assets.call("set_texture", i, ta)
	t.set("assets", assets)
	var mat: Resource = ClassDB.instantiate("Terrain3DMaterial")
	mat.set("world_background", 0)
	mat.set("auto_shader", false)
	t.set("material", mat)
	add_child(t)
	terrain3d = t
	# maps: 1 m per pixel. Terrain3D puts an imported image at the corner of a region (256 m), so
	# the image starts on a region boundary and covers the whole location; beyond the playable area
	# the edge mountains simply carry on.
	var rs := 256
	var start := floori(-half / rs) * rs
	var size := ceili((half - start) / rs) * rs
	var heights := PackedFloat32Array()
	heights.resize(size * size)
	var control := PackedByteArray()
	control.resize(size * size * 4)
	var col_bytes := PackedByteArray()
	col_bytes.resize(size * size * 4)
	# control map bits (Terrain3DUtil encodes them; looked up once instead of per pixel)
	var u: Object = ClassDB.instantiate("Terrain3DUtil")
	var base_bits: int = u.call("enc_base", T_GRASS)
	var overlay_bits: Array[int] = []
	for k in 6:
		overlay_bits.append(int(u.call("enc_overlay", k)))
	var blend_bits: Array[int] = []
	for b in 256:
		blend_bits.append(int(u.call("enc_blend", b)))
	if not (u is RefCounted):
		u.free()
	var noise := FastNoiseLite.new()
	noise.seed = seed_value + 31
	noise.frequency = 0.045
	var noise_big := FastNoiseLite.new()
	noise_big.seed = seed_value + 57
	noise_big.frequency = 0.01
	var floor_amount: float = cfg.get("floor_amount", 0.7)
	var neutral := PackedByteArray([255, 255, 255, 128])
	for iz in size:
		var z := float(start + iz)
		for ix in size:
			var x := float(start + ix)
			var i := iz * size + ix
			heights[i] = height_at(x, z)
			if absf(x) > half or absf(z) > half:
				control.encode_u32(i * 4, base_bits | overlay_bits[T_ROCK] | blend_bits[160])
				for c in 4:
					col_bytes[i * 4 + c] = neutral[c]
				continue
			var m := mask_at(x, z)
			var v2 := noise.get_noise_2d(x, z) * 0.5 + 0.5
			var g := slope_at(x, z)
			var slope := 1.0 - 1.0 / sqrt(1.0 + g * g)
			var weights := [smoothstep(0.55, 0.78, v2) * floor_amount, smoothstep(0.35, 0.65, m.r + (v2 - 0.5) * 0.4),
				smoothstep(0.4, 0.6, m.g), smoothstep(0.4, 0.6, m.b), smoothstep(0.22, 0.42, slope)]
			var best := 0
			for k in range(1, 5):
				if weights[k] > weights[best]:
					best = k
			var overlay: int = [T_FLOOR, T_DIRT, T_STONE, T_FIELD, T_ROCK][best]
			var blend := int(clampf(weights[best], 0.0, 1.0) * 255.0)
			control.encode_u32(i * 4, base_bits | overlay_bits[overlay] | blend_bits[blend])
			var s := smoothstep(0.35, 0.65, noise_big.get_noise_2d(x, z) * 0.5 + 0.5)
			var gc := g1.lerp(g2, s)
			col_bytes[i * 4] = int(clampf(gc.r / gmax.r, 0.0, 1.0) * 255.0)
			col_bytes[i * 4 + 1] = int(clampf(gc.g / gmax.g, 0.0, 1.0) * 255.0)
			col_bytes[i * 4 + 2] = int(clampf(gc.b / gmax.b, 0.0, 1.0) * 255.0)
			col_bytes[i * 4 + 3] = 128
	var himg := Image.create_from_data(size, size, false, Image.FORMAT_RF, heights.to_byte_array())
	var cimg := Image.create_from_data(size, size, false, Image.FORMAT_RF, control)
	var colors := Image.create_from_data(size, size, false, Image.FORMAT_RGBA8, col_bytes)
	t.call("get_data").call("import_images", [himg, cimg, colors], Vector3(start, 0, start), 0.0, 1.0)


## Terrain3D builds its detail around this camera (call when the player's camera exists).
func set_camera(cam: Camera3D) -> void:
	if terrain3d:
		terrain3d.call("set_camera", cam)


# --------------------------------------------------------------------------- grass

## Builds a tuft mesh of `blades` thin triangles.
static func make_tuft(rng: RandomNumberGenerator, blades: int, height: float, width: float, spread: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in blades:
		var a := rng.randf() * TAU
		var base := Vector3(cos(a), 0, sin(a)) * rng.randf_range(0.0, spread)
		var h := height * rng.randf_range(0.6, 1.0)
		var lean := Vector3(cos(a), 0, sin(a)) * rng.randf_range(0.05, 0.3) * h
		var side := Vector3(-sin(a), 0, cos(a)) * width * 0.5
		st.set_normal(Vector3.UP)
		st.add_vertex(base - side)
		st.add_vertex(base + side)
		st.add_vertex(base + lean + Vector3(0, h, 0))
	return st.commit()


## Scatters tufts in 20 m chunks. `channel_avoid` skips mask channels (paths, paving...);
## `need_channel` >= 0 restricts placement to that mask channel (wheat in fields).
func scatter_tufts(mesh: Mesh, mat: Material, per_chunk: int, rng: RandomNumberGenerator, view_range: float,
		need_channel := -1, scale_range := Vector2(0.8, 1.3), avoid_points: Array = []) -> void:
	var chunk := 20.0
	var count := int(half * 2.0 / chunk)
	for cz in count:
		for cx in count:
			var x0 := -half + cx * chunk
			var z0 := -half + cz * chunk
			var xforms: Array[Transform3D] = []
			var colors: Array[Color] = []
			for i in per_chunk:
				var x := x0 + rng.randf() * chunk
				var z := z0 + rng.randf() * chunk
				if absf(x) > half - 12.0 or absf(z) > half - 12.0:
					continue
				var m := mask_at(x, z)
				if need_channel >= 0:
					if m[need_channel] < 0.5:
						continue
				elif m.r > 0.35 or m.g > 0.3 or m.b > 0.3:
					continue
				var y := height_at(x, z)
				if y < -0.3 or slope_at(x, z) > 0.45:
					continue
				var blocked := false
				for ap in avoid_points:
					var apc: Vector2 = ap[0]
					if apc.distance_squared_to(Vector2(x, z)) < float(ap[1]) * float(ap[1]):
						blocked = true
						break
				if blocked:
					continue
				var b := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * rng.randf_range(scale_range.x, scale_range.y))
				xforms.append(Transform3D(b, Vector3(x, y - 0.02, z)))
				var v := rng.randf_range(0.8, 1.15)
				colors.append(Color(v, v * rng.randf_range(0.95, 1.05), v * 0.9))
			if xforms.is_empty():
				continue
			# visibility range is measured from the node origin, so the origin sits at the chunk center
			var center := Vector3(x0 + chunk * 0.5, 0, z0 + chunk * 0.5)
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.use_colors = true
			mm.mesh = mesh
			mm.instance_count = xforms.size()
			for i in xforms.size():
				var t := xforms[i]
				t.origin -= center
				mm.set_instance_transform(i, t)
				mm.set_instance_color(i, colors[i])
			var mmi := MultiMeshInstance3D.new()
			mmi.multimesh = mm
			mmi.material_override = mat
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mmi.visibility_range_end = view_range
			mmi.visibility_range_end_margin = 8.0
			mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
			mmi.position = center
			add_child(mmi)
