class_name VesPortal
extends Node3D
## VesPer's portal: a ring of scaffolding, cables and drone parts with a swirling field inside.
## Built in every location's main settlement once you've brought VesPer his drone (Game.flags
## "portal"); until then it is a construction site. Press F to travel to any location.

var world: Node
var _ring: Node3D
var _field: MeshInstance3D
var _site: Node3D
var _drones: Array = []
var _hum: AudioStreamPlayer3D
var _light: OmniLight3D
var _t := 0.0


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("portals")
	var steel := MeshKit.mat(Color(0.55, 0.56, 0.58), 0.35, 0.85)
	var dark := MeshKit.mat(Color(0.12, 0.12, 0.13), 0.5, 0.6)
	var concrete := Props.stone(Color(0.8, 0.8, 0.8), 0.6)
	var pad := MeshKit.static_cyl(self, 2.2, 0.25, Vector3(0, 0.12, 0), concrete, 24)
	pad.set_meta("surface", "stone")
	MeshKit.cyl(self, 2.25, 2.25, 0.06, Vector3(0, 0.26, 0), MeshKit.mat(Color(0.95, 0.75, 0.1), 0.5, 0.4), Vector3.ZERO, 24)
	# two scaffold towers
	for s in [-1.0, 1.0]:
		var x: float = s * 2.0
		for cx in [-0.25, 0.25]:
			for cz in [-0.25, 0.25]:
				MeshKit.cyl(self, 0.03, 0.03, 4.2, Vector3(x + cx, 2.35, cz), steel, Vector3.ZERO, 6)
		var y := 0.6
		while y < 4.3:
			MeshKit.box(self, Vector3(0.55, 0.03, 0.03), Vector3(x, y, 0.25), steel)
			MeshKit.box(self, Vector3(0.55, 0.03, 0.03), Vector3(x, y, -0.25), steel)
			MeshKit.box(self, Vector3(0.03, 0.03, 0.55), Vector3(x + 0.25, y, 0), steel)
			MeshKit.box(self, Vector3(0.03, 0.03, 0.55), Vector3(x - 0.25, y, 0), steel)
			y += 0.6
		MeshKit.box(self, Vector3(0.3, 0.4, 0.2), Vector3(x, 1.3, 0.3), MeshKit.mat(Color(0.85, 0.75, 0.15), 0.5, 0.3))
		MeshKit.sphere(self, 0.05, Vector3(x, 4.5, 0), MeshKit.mat(Color(1.0, 0.2, 0.1), 0.4, 0.0, 4.0))
	# cables on the ground to a generator and a work table with a laptop
	TechProps.wire(self, to_global(Vector3(-2.0, 0.3, 0.3)), to_global(Vector3(-3.6, 0.3, 1.6)), 0.0, dark)
	TechProps.wire(self, to_global(Vector3(2.0, 0.3, 0.3)), to_global(Vector3(3.4, 0.3, 1.4)), 0.0, dark)
	var gen := Node3D.new()
	gen.position = Vector3(-3.8, 0.26, 1.8)
	add_child(gen)
	MeshKit.static_box(gen, Vector3(0.9, 0.55, 0.55), Vector3(0, 0.27, 0), MeshKit.mat(Color(0.25, 0.38, 0.25), 0.55, 0.4))
	MeshKit.cyl(gen, 0.16, 0.16, 0.56, Vector3(-0.2, 0.62, 0), MeshKit.mat(Color(0.7, 0.15, 0.1), 0.4, 0.5), Vector3(90, 0, 0), 10)
	var table := Node3D.new()
	table.position = Vector3(3.5, 0.26, 1.6)
	table.rotation_degrees.y = -30.0
	add_child(table)
	MeshKit.static_box(table, Vector3(1.2, 0.06, 0.6), Vector3(0, 0.78, 0), Props.wood())
	for lx in [-0.55, 0.55]:
		for lz in [-0.25, 0.25]:
			MeshKit.box(table, Vector3(0.05, 0.76, 0.05), Vector3(lx, 0.38, lz), dark)
	MeshKit.box(table, Vector3(0.36, 0.02, 0.25), Vector3(-0.2, 0.82, 0), dark)
	MeshKit.box(table, Vector3(0.36, 0.24, 0.02), Vector3(-0.2, 0.94, -0.12), dark, Vector3(-15, 0, 0))
	MeshKit.box(table, Vector3(0.32, 0.2, 0.01), Vector3(-0.2, 0.94, -0.105), MeshKit.mat(Color(0.2, 0.6, 1.0), 0.3, 0.0, 2.5), Vector3(-15, 0, 0))
	var part := TechProps.drone_model(table, false)
	part.position = Vector3(0.3, 0.83, 0.05)
	part.scale = Vector3.ONE * 1.4
	# the ring and its field (only once it's built)
	_ring = Node3D.new()
	_ring.position = Vector3(0, 2.3, 0)
	add_child(_ring)
	var torus := TorusMesh.new()
	torus.inner_radius = 1.55
	torus.outer_radius = 1.8
	torus.rings = 40
	torus.ring_segments = 10
	MeshKit.inst(_ring, torus, Vector3.ZERO, steel, Vector3(90, 0, 0))
	for i in 12:
		var a := TAU * i / 12.0
		MeshKit.box(_ring, Vector3(0.22, 0.22, 0.3), Vector3(cos(a) * 1.68, sin(a) * 1.68, 0), dark, Vector3(0, 0, rad_to_deg(a)))
		MeshKit.sphere(_ring, 0.04, Vector3(cos(a) * 1.68, sin(a) * 1.68, 0.17), MeshKit.mat(Color(0.3, 0.8, 1.0), 0.4, 0.0, 4.0))
	_field = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 1.56
	disc.bottom_radius = 1.56
	disc.height = 0.02
	disc.radial_segments = 40
	_field.mesh = disc
	_field.rotation_degrees.x = 90.0
	_field.material_override = _field_material()
	_field.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.add_child(_field)
	_light = OmniLight3D.new()
	_light.light_color = Color(0.35, 0.75, 1.0)
	_light.light_energy = 2.0
	_light.omni_range = 9.0
	_light.position = Vector3(0, 2.3, 0.6)
	add_child(_light)
	for i in 2:
		var d := TechProps.drone_model(self)
		d.scale = Vector3.ONE * 1.5
		_drones.append(d)
	_hum = AudioStreamPlayer3D.new()
	_hum.bus = "SFX"
	_hum.stream = Game.sounds["drone_buzz"][0]
	_hum.pitch_scale = 0.45
	_hum.volume_db = -14.0
	_hum.unit_size = 3.0
	_hum.max_distance = 24.0
	add_child(_hum)
	# construction site look until VesPer finishes it
	_site = Node3D.new()
	add_child(_site)
	for i in 3:
		MeshKit.box(_site, Vector3(0.7, 0.7, 0.7), Vector3(-1.0 + i * 0.9, 0.61, -1.4), Props.wood(), Vector3(0, randf_range(-20, 20), 0))
	MeshKit.box(_site, Vector3(1.6, 0.9, 0.05), Vector3(0, 1.0, 1.9), MeshKit.mat(Color(0.95, 0.8, 0.15), 0.6), Vector3(-8, 0, 0))
	var sign := Label3D.new()
	sign.text = Loc.t("UNDER CONSTRUCTION\n- VesPer")
	sign.font_size = 40
	sign.pixel_size = 0.004
	sign.modulate = Color(0.1, 0.1, 0.1)
	sign.position = Vector3(0, 1.0, 1.93)
	sign.rotation_degrees.x = -8.0
	_site.add_child(sign)
	# dozens of small parts: one mesh per material (the ring, the site and the drones stay apart)
	MeshKit.merge_children(self, [_ring, _site] + _drones)
	MeshKit.merge_children(_ring)
	refresh()


func is_built() -> bool:
	return Game.flags.get("portal", false)


func refresh() -> void:
	var on := is_built()
	_ring.visible = on
	_light.visible = on
	_site.visible = not on
	for d in _drones:
		d.visible = on
	if on and not _hum.playing:
		_hum.play()
	elif not on:
		_hum.stop()


func _field_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
void fragment() {
	vec2 c = UV - 0.5;
	float r = length(c) * 2.0;
	float a = atan(c.y, c.x);
	float swirl = sin(a * 5.0 + r * 12.0 - TIME * 3.0) * 0.5 + 0.5;
	float sp2 = sin(a * 3.0 - r * 8.0 + TIME * 2.0) * 0.5 + 0.5;
	vec3 col = mix(vec3(0.1, 0.4, 1.0), vec3(0.4, 1.0, 1.0), swirl) * (0.6 + sp2 * 0.6);
	col += vec3(0.9, 1.0, 1.0) * pow(1.0 - r, 3.0) * 1.5;
	ALBEDO = col * smoothstep(1.0, 0.85, r) * 0.9;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	return m


func prompt() -> String:
	return Loc.t("Travel (VesPer's portal)") if is_built() else Loc.t("VesPer's portal (under construction)")


func interact() -> void:
	if not is_built():
		world.hud.show_message(Loc.t("VesPer is still building it. Help him with his drone in Northvale first."), Color(1.0, 0.85, 0.5), 3.5)
		return
	world.open_travel()


## Where travellers step out.
func arrival_point() -> Vector3:
	return global_transform * Vector3(0, 0.4, 3.4)


func _process(delta: float) -> void:
	if not _ring.visible:
		return
	_t += delta
	_ring.rotation.z += delta * 0.2
	_light.light_energy = 2.0 + sin(_t * 3.0) * 0.4
	for i in _drones.size():
		var d: Node3D = _drones[i]
		var a := _t * 0.8 + i * PI
		d.position = Vector3(cos(a) * 2.6, 3.6 + sin(_t * 1.7 + i) * 0.3, sin(a) * 1.2)
		d.rotation.y = -a
		for r in d.get_meta("rotors"):
			(r as Node3D).rotation.y += delta * 70.0
