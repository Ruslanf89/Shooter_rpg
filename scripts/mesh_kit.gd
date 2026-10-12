class_name MeshKit
extends RefCounted
## Small helpers for building low-poly geometry out of primitive meshes.

static var _mats: Dictionary = {}
static var _textures: Dictionary = {}
static var _detail: NoiseTexture2D
static var _textured_shader: Shader


## Loads res://assets/textures/<tex_name>_color.jpg (cached).
static func tex(tex_name: String) -> Texture2D:
	if not _textures.has(tex_name):
		_textures[tex_name] = load("res://assets/textures/%s_color.jpg" % tex_name)
	return _textures[tex_name]


## Soft painterly noise used to break up flat colors.
static func detail_texture() -> NoiseTexture2D:
	if _detail == null:
		var n := FastNoiseLite.new()
		n.frequency = 0.03
		n.fractal_octaves = 3
		var g := Gradient.new()
		g.set_color(0, Color(0.72, 0.72, 0.72))
		g.set_color(1, Color(1.0, 1.0, 1.0))
		_detail = NoiseTexture2D.new()
		_detail.width = 256
		_detail.height = 256
		_detail.seamless = true
		_detail.noise = n
		_detail.color_ramp = g
	return _detail


## World-space triplanar textured material with color grading (see textured.gdshader).
static func textured(tex_name: String, tint := Color(1, 1, 1), uv_scale := 0.5, tint_mix := 0.0, brightness := 1.0) -> ShaderMaterial:
	var key := "tex|%s|%s|%.2f|%.2f|%.2f" % [tex_name, tint.to_html(), uv_scale, tint_mix, brightness]
	if _mats.has(key):
		return _mats[key]
	if _textured_shader == null:
		_textured_shader = load("res://shaders/textured.gdshader")
	var m := ShaderMaterial.new()
	m.shader = _textured_shader
	m.set_shader_parameter("albedo_tex", tex(tex_name))
	m.set_shader_parameter("tint", Vector3(tint.r, tint.g, tint.b))
	m.set_shader_parameter("uv_scale", uv_scale)
	m.set_shader_parameter("tint_mix", tint_mix)
	m.set_shader_parameter("brightness", brightness)
	var nrm := normal_tex(tex_name)
	if nrm:
		m.set_shader_parameter("normal_tex", nrm)
		m.set_shader_parameter("normal_strength", 1.0)
	_mats[key] = m
	return m


## res://assets/textures/<tex_name>_normal.jpg, or null when the texture has no normal map.
static func normal_tex(tex_name: String) -> Texture2D:
	var key := tex_name + "|n"
	if not _textures.has(key):
		var path := "res://assets/textures/%s_normal.jpg" % tex_name
		_textures[key] = load(path) if ResourceLoader.exists(path) else null
	return _textures[key]


static func mat(color: Color, roughness := 0.85, metallic := 0.0, emission := 0.0) -> StandardMaterial3D:
	var key := "%s|%.2f|%.2f|%.2f" % [color.to_html(), roughness, metallic, emission]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	if emission == 0.0:
		m.albedo_texture = detail_texture()
		m.uv1_triplanar = true
		m.uv1_scale = Vector3(1.5, 1.5, 1.5)
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	_mats[key] = m
	return m


static func unshaded(color: Color) -> StandardMaterial3D:
	var key := "unshaded|%s" % color.to_html()
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mats[key] = m
	return m


## Additive see-through glow (spell auras, muzzle flash halo).
static func glow(color: Color) -> StandardMaterial3D:
	var key := "glow|%s" % color.to_html()
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mats[key] = m
	return m


static func inst(parent: Node3D, mesh: Mesh, pos: Vector3, material: Material, rot_deg := Vector3.ZERO, scl := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.scale = scl
	parent.add_child(mi)
	return mi


static func box(parent: Node3D, size: Vector3, pos: Vector3, material: Material, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = size
	return inst(parent, m, pos, material, rot_deg)


static func cyl(parent: Node3D, top_r: float, bottom_r: float, height: float, pos: Vector3, material: Material, rot_deg := Vector3.ZERO, segments := 12) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.top_radius = top_r
	m.bottom_radius = bottom_r
	m.height = height
	m.radial_segments = segments
	m.rings = 1
	return inst(parent, m, pos, material, rot_deg)


static func sphere(parent: Node3D, radius: float, pos: Vector3, material: Material, scl := Vector3.ONE) -> MeshInstance3D:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = 14
	m.rings = 7
	return inst(parent, m, pos, material, Vector3.ZERO, scl)


static func prism(parent: Node3D, size: Vector3, pos: Vector3, material: Material, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var m := PrismMesh.new()
	m.size = size
	return inst(parent, m, pos, material, rot_deg)


static func _body(parent: Node3D, pos: Vector3, rot_deg: Vector3, shape: Shape3D) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation_degrees = rot_deg
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	parent.add_child(body)
	return body


static func collider_box(parent: Node3D, size: Vector3, pos: Vector3, rot_deg := Vector3.ZERO) -> StaticBody3D:
	var s := BoxShape3D.new()
	s.size = size
	return _body(parent, pos, rot_deg, s)


static func static_box(parent: Node3D, size: Vector3, pos: Vector3, material: Material, rot_deg := Vector3.ZERO) -> StaticBody3D:
	var body := collider_box(parent, size, pos, rot_deg)
	box(body, size, Vector3.ZERO, material)
	return body


static func static_cyl(parent: Node3D, radius: float, height: float, pos: Vector3, material: Material, segments := 12) -> StaticBody3D:
	var s := CylinderShape3D.new()
	s.radius = radius
	s.height = height
	var body := _body(parent, pos, Vector3.ZERO, s)
	cyl(body, radius, radius, height, Vector3.ZERO, material, Vector3.ZERO, segments)
	return body


static func static_sphere(parent: Node3D, radius: float, pos: Vector3, material: Material) -> StaticBody3D:
	var s := SphereShape3D.new()
	s.radius = radius
	var body := _body(parent, pos, Vector3.ZERO, s)
	sphere(body, radius, Vector3.ZERO, material)
	return body


## Merges the primitive meshes under `node` (not under the nodes in `keep`) into one mesh per
## material - for small composite objects that have dozens of parts (gathering nodes, portals).
static func merge_children(node: Node3D, keep: Array = []) -> void:
	var groups := {}
	var stack: Array = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			if c in keep or c.get_script() != null or c is CollisionObject3D or c is Light3D or c is GPUParticles3D or c is CPUParticles3D:
				continue
			if c is MeshInstance3D and (c as MeshInstance3D).mesh is PrimitiveMesh and (c as MeshInstance3D).material_override != null:
				var mi := c as MeshInstance3D
				var key := mi.material_override.get_instance_id()
				if not groups.has(key):
					groups[key] = [mi.material_override, []]
				groups[key][1].append(mi)
			elif c is Node3D and c.get_child_count() > 0:
				stack.append(c)
	for key in groups:
		var list: Array = groups[key][1]
		if list.size() < 2:
			continue
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var inv := node.global_transform.affine_inverse()
		for mi: MeshInstance3D in list:
			var am := ArrayMesh.new()
			am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mi.mesh.get_mesh_arrays())
			st.append_from(am, 0, inv * mi.global_transform)
		var merged := MeshInstance3D.new()
		merged.mesh = st.commit()
		merged.material_override = groups[key][0]
		node.add_child(merged)
		for mi: MeshInstance3D in list:
			mi.queue_free()