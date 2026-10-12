class_name WeaponModels
extends RefCounted
## First-person weapon models with arms. build() fills `gun` (barrel along -z) and returns the
## moving parts: {"mag", "bolt", "muzzle", "eject", "hip", "ads"} (ads = gun pivot position when
## aiming down the sights).

static var _cache := {}


static func _wood() -> StandardMaterial3D:
	if _cache.has("wood"):
		return _cache["wood"]
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_PERLIN
	n.frequency = 0.03
	n.fractal_octaves = 3
	var g := Gradient.new()
	g.set_color(0, Color(0.3, 0.12, 0.05))
	g.set_color(1, Color(0.62, 0.3, 0.12))
	var t := NoiseTexture2D.new()
	t.width = 256
	t.height = 256
	t.seamless = true
	t.noise = n
	t.color_ramp = g
	var m := StandardMaterial3D.new()
	m.albedo_texture = t
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(40, 40, 3)
	m.roughness = 0.45
	m.clearcoat_enabled = true
	m.clearcoat = 0.4
	_cache["wood"] = m
	return m


static func _metal(c: Color, rough: float) -> StandardMaterial3D:
	var key := "m%s%.2f" % [c.to_html(), rough]
	if _cache.has(key):
		return _cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c.lightened(0.12)
	m.albedo_texture = MeshKit.detail_texture()
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(25, 25, 25)
	m.metallic = 0.45
	m.roughness = clampf(rough + 0.1, 0.0, 1.0)
	m.metallic_specular = 0.7
	_cache[key] = m
	return m


static func _poly(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.55
	return m


static func _limb(gun: Node3D, a: Vector3, b: Vector3, thickness: float, material: Material) -> void:
	var m := CapsuleMesh.new()
	m.radius = thickness * 0.5
	m.height = a.distance_to(b) + thickness
	m.radial_segments = 10
	m.rings = 2
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = material
	mi.transform = Transform3D(Basis.looking_at(b - a, Vector3.UP) * Basis(Vector3.RIGHT, PI * 0.5), (a + b) * 0.5)
	gun.add_child(mi)


## Gloved hands at `lh` (support hand) and `rh` (trigger hand) with forearms and sleeves.
static func _arms(gun: Node3D, lh: Vector3, rh: Vector3) -> void:
	var skin := MeshKit.mat(Color(0.86, 0.67, 0.53), 0.8)
	var glove := MeshKit.mat(Color(0.1, 0.1, 0.1), 0.9)
	var sleeve := MeshKit.mat(Color(0.27, 0.31, 0.21), 0.95)
	MeshKit.sphere(gun, 0.045, lh, glove, Vector3(1.0, 0.8, 1.4))
	for f in 3:
		MeshKit.cyl(gun, 0.011, 0.011, 0.05, lh + Vector3(0.025 - f * 0.018, 0.025, -0.02), glove, Vector3(0, 0, 90), 6)
	_limb(gun, lh + Vector3(-0.02, -0.02, 0.03), lh + Vector3(-0.17, -0.29, 0.33), 0.08, skin)
	_limb(gun, lh + Vector3(-0.1, -0.16, 0.19), lh + Vector3(-0.3, -0.48, 0.55), 0.105, sleeve)
	MeshKit.sphere(gun, 0.042, rh, glove, Vector3(1.0, 1.1, 1.2))
	_limb(gun, rh + Vector3(0.01, -0.03, 0.04), rh + Vector3(0.13, -0.27, 0.2), 0.08, skin)
	_limb(gun, rh + Vector3(0.07, -0.15, 0.12), rh + Vector3(0.24, -0.45, 0.35), 0.105, sleeve)


static func build(base: String, gun: Node3D) -> Dictionary:
	var parts := {}
	match base:
		"pistol": parts = _pistol(gun)
		"smg": parts = _smg(gun)
		"shotgun": parts = _shotgun(gun)
		"sniper": parts = _sniper(gun)
		"lmg": parts = _lmg(gun)
		"crossbow": parts = _crossbow(gun)
		"flamethrower": parts = _flamethrower(gun)
		"launcher": parts = _launcher(gun)
		"staff_frost": parts = _staff(gun, Color(0.45, 0.8, 1.0))
		"staff_fire": parts = _staff(gun, Color(1.0, 0.45, 0.12))
		"staff_storm": parts = _staff(gun, Color(0.7, 0.65, 1.0))
		_: parts = _rifle(gun)
	for n in gun.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		mi.layers = 2
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return parts


static func _node(parent: Node3D, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	parent.add_child(n)
	return n


# --------------------------------------------------------------------------- AK

static func _rifle(gun: Node3D) -> Dictionary:
	var metal := _metal(Color(0.1, 0.1, 0.11), 0.42)
	var metal_light := _metal(Color(0.18, 0.18, 0.19), 0.5)
	var dark := MeshKit.mat(Color(0.02, 0.02, 0.02))
	var wood := _wood()
	var bakelite := _poly(Color(0.42, 0.15, 0.06))
	bakelite.clearcoat_enabled = true
	MeshKit.box(gun, Vector3(0.064, 0.085, 0.4), Vector3(0, 0, 0), metal)
	MeshKit.box(gun, Vector3(0.06, 0.03, 0.36), Vector3(0, 0.055, 0.02), metal_light)
	for z in [0.1, 0.14, 0.18]:
		MeshKit.box(gun, Vector3(0.062, 0.006, 0.012), Vector3(0, 0.071, z), metal_light)
	for p in [Vector3(-0.033, -0.02, 0.15), Vector3(0.033, -0.02, 0.15), Vector3(-0.033, -0.02, 0.12), Vector3(0.033, -0.02, 0.12)]:
		MeshKit.sphere(gun, 0.005, p, metal_light)
	MeshKit.box(gun, Vector3(0.002, 0.025, 0.075), Vector3(0.0325, 0.03, -0.02), dark)
	MeshKit.box(gun, Vector3(0.004, 0.012, 0.16), Vector3(0.034, 0.022, 0.03), metal_light, Vector3(6, 0, 0))
	var bolt := _node(gun, Vector3(0.036, 0.035, -0.04))
	MeshKit.box(bolt, Vector3(0.006, 0.018, 0.09), Vector3.ZERO, metal)
	MeshKit.cyl(bolt, 0.008, 0.008, 0.035, Vector3(0.018, 0, -0.035), metal, Vector3(0, 0, 90), 8)
	MeshKit.sphere(bolt, 0.011, Vector3(0.036, 0, -0.035), metal)
	MeshKit.box(gun, Vector3(0.04, 0.03, 0.06), Vector3(0, 0.062, -0.17), metal)
	MeshKit.box(gun, Vector3(0.03, 0.008, 0.08), Vector3(0, 0.08, -0.15), metal, Vector3(-3, 0, 0))
	MeshKit.box(gun, Vector3(0.068, 0.065, 0.26), Vector3(0, 0.0, -0.335), wood)
	MeshKit.box(gun, Vector3(0.052, 0.04, 0.2), Vector3(0, 0.055, -0.33), wood)
	MeshKit.box(gun, Vector3(0.072, 0.072, 0.012), Vector3(0, 0.005, -0.205), metal)
	MeshKit.box(gun, Vector3(0.072, 0.072, 0.012), Vector3(0, 0.005, -0.466), metal)
	MeshKit.cyl(gun, 0.012, 0.012, 0.14, Vector3(0, 0.052, -0.5), metal, Vector3(90, 0, 0), 8)
	MeshKit.box(gun, Vector3(0.03, 0.045, 0.04), Vector3(0, 0.035, -0.575), metal)
	MeshKit.cyl(gun, 0.0135, 0.0135, 0.44, Vector3(0, 0.012, -0.68), metal, Vector3(90, 0, 0), 12)
	MeshKit.cyl(gun, 0.004, 0.004, 0.42, Vector3(0, -0.012, -0.64), metal_light, Vector3(90, 0, 0), 6)
	MeshKit.box(gun, Vector3(0.028, 0.03, 0.05), Vector3(0, 0.03, -0.8), metal)
	MeshKit.box(gun, Vector3(0.004, 0.045, 0.02), Vector3(-0.012, 0.06, -0.8), metal)
	MeshKit.box(gun, Vector3(0.004, 0.045, 0.02), Vector3(0.012, 0.06, -0.8), metal)
	MeshKit.box(gun, Vector3(0.003, 0.032, 0.003), Vector3(0, 0.058, -0.8), metal)
	MeshKit.cyl(gun, 0.017, 0.017, 0.07, Vector3(0, 0.012, -0.935), metal_light, Vector3(90, 0, 0), 12)
	MeshKit.box(gun, Vector3(0.036, 0.012, 0.04), Vector3(0, 0.026, -0.95), metal_light, Vector3(30, 0, 0))
	MeshKit.box(gun, Vector3(0.04, 0.13, 0.06), Vector3(0, -0.105, 0.1), bakelite, Vector3(18, 0, 0))
	MeshKit.box(gun, Vector3(0.012, 0.006, 0.1), Vector3(0, -0.078, 0.03), metal)
	MeshKit.box(gun, Vector3(0.006, 0.03, 0.008), Vector3(0, -0.058, 0.025), metal, Vector3(15, 0, 0))
	MeshKit.box(gun, Vector3(0.05, 0.02, 0.08), Vector3(0, 0.02, 0.22), metal)
	MeshKit.box(gun, Vector3(0.05, 0.11, 0.32), Vector3(0, -0.03, 0.36), wood, Vector3(-7, 0, 0))
	MeshKit.box(gun, Vector3(0.048, 0.14, 0.12), Vector3(0, -0.05, 0.48), wood, Vector3(-7, 0, 0))
	MeshKit.box(gun, Vector3(0.055, 0.15, 0.015), Vector3(0, -0.055, 0.545), metal, Vector3(-7, 0, 0))
	var mag := _node(gun, Vector3(0, -0.045, -0.09))
	for i in 5:
		var y := -0.03 - i * 0.055
		var z := i * 0.016 + i * i * 0.005
		var rx := -(5.0 + i * 7.0)
		MeshKit.box(mag, Vector3(0.042, 0.06, 0.082), Vector3(0, y, z), bakelite, Vector3(rx, 0, 0))
		MeshKit.box(mag, Vector3(0.046, 0.008, 0.07), Vector3(0, y - 0.02, z), bakelite, Vector3(rx, 0, 0))
	MeshKit.box(mag, Vector3(0.046, 0.02, 0.09), Vector3(0, -0.3, 0.12), metal, Vector3(-36, 0, 0))
	_arms(gun, Vector3(-0.01, -0.05, -0.36), Vector3(0.02, -0.11, 0.12))
	return {"mag": mag, "bolt": bolt, "muzzle": _node(gun, Vector3(0, 0.012, -0.98)), "eject": _node(gun, Vector3(0.04, 0.035, -0.02)),
		"hip": Vector3(0.24, -0.2, -0.6), "ads": Vector3(0.0, -0.086, -0.56)}


# --------------------------------------------------------------------------- pistol

static func _pistol(gun: Node3D) -> Dictionary:
	var metal := _metal(Color(0.12, 0.12, 0.13), 0.35)
	var poly := _poly(Color(0.08, 0.08, 0.08))
	var bolt := _node(gun, Vector3(0, 0.03, -0.05))
	MeshKit.box(bolt, Vector3(0.034, 0.036, 0.2), Vector3.ZERO, metal)
	for i in 6:
		MeshKit.box(bolt, Vector3(0.036, 0.024, 0.004), Vector3(0, 0.0, 0.06 + i * 0.007), _metal(Color(0.2, 0.2, 0.21), 0.5))
	MeshKit.box(bolt, Vector3(0.008, 0.01, 0.008), Vector3(0, 0.022, -0.09), metal)
	MeshKit.box(bolt, Vector3(0.022, 0.01, 0.008), Vector3(0, 0.022, 0.085), metal)
	MeshKit.box(bolt, Vector3(0.008, 0.012, 0.03), Vector3(0.018, 0.004, 0.0), _metal(Color(0.05, 0.05, 0.05), 0.4))
	MeshKit.box(gun, Vector3(0.03, 0.025, 0.17), Vector3(0, 0.0, -0.06), poly)
	MeshKit.cyl(gun, 0.008, 0.008, 0.02, Vector3(0, 0.03, -0.155), _metal(Color(0.05, 0.05, 0.05), 0.3), Vector3(90, 0, 0), 10)
	MeshKit.box(gun, Vector3(0.032, 0.11, 0.05), Vector3(0, -0.06, 0.02), poly, Vector3(12, 0, 0))
	for i in 5:
		MeshKit.box(gun, Vector3(0.034, 0.004, 0.045), Vector3(0, -0.03 - i * 0.017, 0.02 + i * 0.004), _poly(Color(0.14, 0.14, 0.14)), Vector3(12, 0, 0))
	MeshKit.box(gun, Vector3(0.008, 0.004, 0.05), Vector3(0, -0.022, -0.035), metal)
	MeshKit.box(gun, Vector3(0.005, 0.02, 0.006), Vector3(0, -0.02, -0.03), metal, Vector3(15, 0, 0))
	var mag := _node(gun, Vector3(0, -0.07, 0.025))
	MeshKit.box(mag, Vector3(0.026, 0.1, 0.04), Vector3(0, -0.02, 0), metal, Vector3(12, 0, 0))
	_arms(gun, Vector3(-0.025, -0.075, 0.0), Vector3(0.012, -0.07, 0.04))
	return {"mag": mag, "bolt": bolt, "muzzle": _node(gun, Vector3(0, 0.03, -0.17)), "eject": _node(gun, Vector3(0.02, 0.04, -0.03)),
		"hip": Vector3(0.17, -0.16, -0.42), "ads": Vector3(0.0, -0.055, -0.36)}


# --------------------------------------------------------------------------- SMG

static func _smg(gun: Node3D) -> Dictionary:
	var metal := _metal(Color(0.13, 0.13, 0.14), 0.4)
	var poly := _poly(Color(0.07, 0.07, 0.07))
	MeshKit.box(gun, Vector3(0.05, 0.07, 0.32), Vector3(0, 0, -0.05), metal)
	MeshKit.box(gun, Vector3(0.022, 0.012, 0.28), Vector3(0, 0.041, -0.05), poly)
	for z in range(7):
		MeshKit.box(gun, Vector3(0.026, 0.006, 0.012), Vector3(0, 0.049, -0.17 + z * 0.04), metal)
	MeshKit.cyl(gun, 0.022, 0.022, 0.2, Vector3(0, 0.005, -0.31), poly, Vector3(90, 0, 0), 14)
	for i in 4:
		MeshKit.box(gun, Vector3(0.046, 0.004, 0.02), Vector3(0, 0.005, -0.25 - i * 0.04), metal)
	MeshKit.box(gun, Vector3(0.016, 0.02, 0.03), Vector3(0, 0.055, -0.17), metal)
	MeshKit.box(gun, Vector3(0.016, 0.022, 0.02), Vector3(0, 0.056, 0.07), metal)
	MeshKit.box(gun, Vector3(0.036, 0.11, 0.05), Vector3(0, -0.085, 0.07), poly, Vector3(15, 0, 0))
	MeshKit.box(gun, Vector3(0.032, 0.09, 0.04), Vector3(0, -0.075, -0.21), poly, Vector3(-8, 0, 0))
	MeshKit.box(gun, Vector3(0.01, 0.006, 0.08), Vector3(0, -0.055, 0.03), metal)
	var bolt := _node(gun, Vector3(0.028, 0.02, -0.03))
	MeshKit.box(bolt, Vector3(0.008, 0.012, 0.03), Vector3.ZERO, metal)
	for s in [-1.0, 1.0]:
		MeshKit.cyl(gun, 0.005, 0.005, 0.24, Vector3(s * 0.02, 0.0, 0.22), metal, Vector3(90, 0, 0), 6)
	MeshKit.box(gun, Vector3(0.05, 0.08, 0.015), Vector3(0, -0.02, 0.34), metal)
	var mag := _node(gun, Vector3(0, -0.04, -0.06))
	MeshKit.box(mag, Vector3(0.026, 0.2, 0.05), Vector3(0, -0.1, 0), metal, Vector3(-4, 0, 0))
	_arms(gun, Vector3(-0.005, -0.12, -0.21), Vector3(0.015, -0.1, 0.07))
	return {"mag": mag, "bolt": bolt, "muzzle": _node(gun, Vector3(0, 0.005, -0.42)), "eject": _node(gun, Vector3(0.03, 0.03, -0.02)),
		"hip": Vector3(0.21, -0.18, -0.5), "ads": Vector3(0.0, -0.068, -0.44)}


# --------------------------------------------------------------------------- shotgun

static func _shotgun(gun: Node3D) -> Dictionary:
	var metal := _metal(Color(0.1, 0.1, 0.1), 0.35)
	var wood := _wood()
	MeshKit.box(gun, Vector3(0.055, 0.07, 0.26), Vector3(0, 0, -0.02), metal)
	MeshKit.cyl(gun, 0.017, 0.017, 0.62, Vector3(0, 0.015, -0.45), metal, Vector3(90, 0, 0), 14)
	MeshKit.cyl(gun, 0.014, 0.014, 0.55, Vector3(0, -0.02, -0.42), metal, Vector3(90, 0, 0), 12)
	MeshKit.cyl(gun, 0.019, 0.019, 0.015, Vector3(0, 0.015, -0.755), metal, Vector3(90, 0, 0), 14)
	MeshKit.sphere(gun, 0.005, Vector3(0, 0.035, -0.74), _metal(Color(0.8, 0.75, 0.6), 0.3))
	var bolt := _node(gun, Vector3(0, -0.02, -0.32))
	MeshKit.cyl(bolt, 0.026, 0.026, 0.17, Vector3.ZERO, wood, Vector3(90, 0, 0), 12)
	for i in 5:
		MeshKit.cyl(bolt, 0.027, 0.027, 0.008, Vector3(0, 0, -0.06 + i * 0.03), _wood(), Vector3(90, 0, 0), 12)
	MeshKit.box(gun, Vector3(0.045, 0.11, 0.06), Vector3(0, -0.08, 0.1), wood, Vector3(20, 0, 0))
	MeshKit.box(gun, Vector3(0.05, 0.09, 0.3), Vector3(0, -0.04, 0.3), wood, Vector3(-6, 0, 0))
	MeshKit.box(gun, Vector3(0.052, 0.13, 0.02), Vector3(0, -0.06, 0.45), _poly(Color(0.08, 0.06, 0.05)), Vector3(-6, 0, 0))
	MeshKit.box(gun, Vector3(0.012, 0.006, 0.08), Vector3(0, -0.045, 0.02), metal)
	MeshKit.box(gun, Vector3(0.004, 0.022, 0.05), Vector3(0.028, 0.0, -0.03), _metal(Color(0.03, 0.03, 0.03), 0.5))
	var mag := _node(gun, Vector3(0, -0.06, 0.0))
	MeshKit.cyl(mag, 0.011, 0.011, 0.05, Vector3.ZERO, MeshKit.mat(Color(0.75, 0.12, 0.08)), Vector3(90, 0, 0), 10)
	mag.visible = false
	_arms(gun, Vector3(-0.005, -0.06, -0.32), Vector3(0.015, -0.11, 0.1))
	return {"mag": mag, "bolt": bolt, "muzzle": _node(gun, Vector3(0, 0.015, -0.77)), "eject": _node(gun, Vector3(0.03, 0.02, -0.04)),
		"hip": Vector3(0.23, -0.2, -0.55), "ads": Vector3(0.0, -0.06, -0.5)}


# --------------------------------------------------------------------------- sniper

static func _sniper(gun: Node3D) -> Dictionary:
	var metal := _metal(Color(0.12, 0.13, 0.12), 0.4)
	var green := _poly(Color(0.22, 0.26, 0.18))
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.2, 0.35, 0.5, 0.6)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.metallic = 0.8
	glass.roughness = 0.05
	MeshKit.box(gun, Vector3(0.05, 0.065, 0.3), Vector3(0, 0, -0.02), metal)
	MeshKit.cyl(gun, 0.016, 0.013, 0.78, Vector3(0, 0.01, -0.56), metal, Vector3(90, 0, 0), 14)
	MeshKit.cyl(gun, 0.022, 0.022, 0.06, Vector3(0, 0.01, -0.97), metal, Vector3(90, 0, 0), 12)
	for i in 3:
		MeshKit.box(gun, Vector3(0.046, 0.006, 0.012), Vector3(0, 0.01, -0.95 - i * 0.02), _metal(Color(0.03, 0.03, 0.03), 0.4))
	# scope
	MeshKit.cyl(gun, 0.022, 0.022, 0.26, Vector3(0, 0.085, -0.04), metal, Vector3(90, 0, 0), 18)
	MeshKit.cyl(gun, 0.03, 0.024, 0.06, Vector3(0, 0.085, -0.19), metal, Vector3(90, 0, 0), 18)
	MeshKit.cyl(gun, 0.026, 0.022, 0.04, Vector3(0, 0.085, 0.11), metal, Vector3(90, 0, 0), 18)
	MeshKit.cyl(gun, 0.028, 0.028, 0.004, Vector3(0, 0.085, -0.222), glass, Vector3(90, 0, 0), 18)
	MeshKit.cyl(gun, 0.024, 0.024, 0.004, Vector3(0, 0.085, 0.132), glass, Vector3(90, 0, 0), 18)
	MeshKit.cyl(gun, 0.012, 0.012, 0.03, Vector3(0, 0.115, -0.04), metal, Vector3.ZERO, 10)
	MeshKit.cyl(gun, 0.012, 0.012, 0.03, Vector3(0.03, 0.085, -0.04), metal, Vector3(0, 0, 90), 10)
	for z in [-0.1, 0.03]:
		MeshKit.box(gun, Vector3(0.03, 0.04, 0.02), Vector3(0, 0.05, z), metal)
	var bolt := _node(gun, Vector3(0.04, 0.025, 0.08))
	MeshKit.cyl(bolt, 0.006, 0.006, 0.06, Vector3(0.025, 0, 0), metal, Vector3(0, 0, 90), 8)
	MeshKit.sphere(bolt, 0.013, Vector3(0.055, 0, 0), metal)
	MeshKit.box(gun, Vector3(0.06, 0.07, 0.42), Vector3(0, -0.035, -0.3), green)
	MeshKit.box(gun, Vector3(0.04, 0.12, 0.06), Vector3(0, -0.09, 0.12), green, Vector3(20, 0, 0))
	MeshKit.box(gun, Vector3(0.052, 0.1, 0.32), Vector3(0, -0.04, 0.33), green, Vector3(-5, 0, 0))
	MeshKit.box(gun, Vector3(0.04, 0.03, 0.18), Vector3(0, 0.025, 0.3), green)
	MeshKit.box(gun, Vector3(0.056, 0.14, 0.02), Vector3(0, -0.06, 0.49), _poly(Color(0.05, 0.05, 0.05)), Vector3(-5, 0, 0))
	for s in [-1.0, 1.0]:
		MeshKit.cyl(gun, 0.005, 0.005, 0.22, Vector3(s * 0.015, -0.07, -0.6), metal, Vector3(80, 0, s * 8.0), 6)
	var mag := _node(gun, Vector3(0, -0.06, -0.02))
	MeshKit.box(mag, Vector3(0.03, 0.06, 0.07), Vector3(0, -0.02, 0), metal)
	_arms(gun, Vector3(-0.005, -0.08, -0.36), Vector3(0.015, -0.13, 0.12))
	return {"mag": mag, "bolt": bolt, "muzzle": _node(gun, Vector3(0, 0.01, -1.0)), "eject": _node(gun, Vector3(0.03, 0.03, 0.0)),
		"hip": Vector3(0.24, -0.21, -0.6), "ads": Vector3(0.0, -0.085, -0.34)}


# --------------------------------------------------------------------------- machine gun

static func _lmg(gun: Node3D) -> Dictionary:
	var metal := _metal(Color(0.11, 0.11, 0.12), 0.45)
	var olive := _poly(Color(0.25, 0.27, 0.2))
	MeshKit.box(gun, Vector3(0.07, 0.1, 0.42), Vector3(0, 0, -0.04), metal)
	MeshKit.box(gun, Vector3(0.074, 0.03, 0.3), Vector3(0, 0.06, -0.02), metal)
	MeshKit.cyl(gun, 0.032, 0.032, 0.42, Vector3(0, 0.01, -0.45), metal, Vector3(90, 0, 0), 14)
	for i in 8:
		MeshKit.box(gun, Vector3(0.068, 0.012, 0.02), Vector3(0, 0.035, -0.3 - i * 0.045), _metal(Color(0.03, 0.03, 0.03), 0.4))
	MeshKit.cyl(gun, 0.016, 0.016, 0.22, Vector3(0, 0.01, -0.77), metal, Vector3(90, 0, 0), 12)
	MeshKit.cyl(gun, 0.022, 0.02, 0.06, Vector3(0, 0.01, -0.9), metal, Vector3(90, 0, 0), 10)
	MeshKit.box(gun, Vector3(0.02, 0.05, 0.12), Vector3(0, 0.1, -0.08), metal)
	MeshKit.box(gun, Vector3(0.02, 0.012, 0.16), Vector3(0, 0.125, -0.08), metal)
	MeshKit.box(gun, Vector3(0.04, 0.12, 0.06), Vector3(0, -0.1, 0.1), olive, Vector3(18, 0, 0))
	MeshKit.box(gun, Vector3(0.06, 0.1, 0.28), Vector3(0, -0.03, 0.3), olive, Vector3(-4, 0, 0))
	for s in [-1.0, 1.0]:
		MeshKit.cyl(gun, 0.006, 0.006, 0.26, Vector3(s * 0.04, -0.1, -0.62), metal, Vector3(20, 0, s * 18.0), 6)
	var bolt := _node(gun, Vector3(0.04, 0.02, -0.08))
	MeshKit.box(bolt, Vector3(0.012, 0.018, 0.04), Vector3.ZERO, metal)
	var mag := _node(gun, Vector3(-0.04, -0.07, -0.08))
	MeshKit.box(mag, Vector3(0.09, 0.12, 0.16), Vector3(0, -0.05, 0), olive)
	MeshKit.box(mag, Vector3(0.092, 0.02, 0.165), Vector3(0, 0.01, 0), metal)
	_arms(gun, Vector3(-0.02, -0.05, -0.36), Vector3(0.02, -0.13, 0.12))
	return {"mag": mag, "bolt": bolt, "muzzle": _node(gun, Vector3(0, 0.01, -0.93)), "eject": _node(gun, Vector3(0.045, 0.02, -0.04)),
		"hip": Vector3(0.24, -0.23, -0.58), "ads": Vector3(0.0, -0.13, -0.5)}


# --------------------------------------------------------------------------- crossbow

static func _crossbow(gun: Node3D) -> Dictionary:
	var wood := _wood()
	var metal := _metal(Color(0.2, 0.2, 0.21), 0.4)
	var string_m := MeshKit.mat(Color(0.85, 0.82, 0.72))
	MeshKit.box(gun, Vector3(0.05, 0.06, 0.7), Vector3(0, 0, -0.15), wood)
	MeshKit.box(gun, Vector3(0.015, 0.008, 0.55), Vector3(0, 0.034, -0.2), metal)
	MeshKit.box(gun, Vector3(0.045, 0.12, 0.06), Vector3(0, -0.08, 0.08), wood, Vector3(20, 0, 0))
	MeshKit.box(gun, Vector3(0.05, 0.1, 0.22), Vector3(0, -0.03, 0.3), wood, Vector3(-6, 0, 0))
	MeshKit.box(gun, Vector3(0.07, 0.07, 0.04), Vector3(0, 0.0, -0.49), metal)
	for s in [-1.0, 1.0]:
		MeshKit.box(gun, Vector3(0.3, 0.02, 0.025), Vector3(s * 0.15, 0.0, -0.46), metal, Vector3(0, s * -18.0, 0))
		MeshKit.cyl(gun, 0.002, 0.002, 0.36, Vector3(s * 0.16, 0.03, -0.27), string_m, Vector3(90, s * -63.0, 0), 4)
	MeshKit.box(gun, Vector3(0.02, 0.025, 0.02), Vector3(0, 0.04, -0.1), metal)
	MeshKit.box(gun, Vector3(0.006, 0.04, 0.006), Vector3(0, 0.06, -0.45), metal)
	MeshKit.box(gun, Vector3(0.008, 0.03, 0.05), Vector3(0, -0.045, 0.02), metal, Vector3(30, 0, 0))
	var mag := _node(gun, Vector3(0, 0.045, -0.3))
	MeshKit.cyl(mag, 0.005, 0.005, 0.42, Vector3.ZERO, wood, Vector3(90, 0, 0), 6)
	MeshKit.cyl(mag, 0.0, 0.01, 0.04, Vector3(0, 0, -0.23), metal, Vector3(-90, 0, 0), 6)
	for s in [-1.0, 1.0]:
		MeshKit.box(mag, Vector3(0.002, 0.018, 0.05), Vector3(s * 0.006, 0.006, 0.18), MeshKit.mat(Color(0.8, 0.15, 0.1)))
	_arms(gun, Vector3(-0.01, -0.04, -0.3), Vector3(0.015, -0.11, 0.1))
	return {"mag": mag, "bolt": _node(gun, Vector3.ZERO), "muzzle": _node(gun, Vector3(0, 0.045, -0.55)), "eject": _node(gun, Vector3.ZERO),
		"hip": Vector3(0.22, -0.2, -0.52), "ads": Vector3(0.0, -0.07, -0.42)}


# --------------------------------------------------------------------------- flamethrower

static func _flamethrower(gun: Node3D) -> Dictionary:
	var metal := _metal(Color(0.2, 0.2, 0.21), 0.4)
	var red := _metal(Color(0.6, 0.08, 0.05), 0.5)
	MeshKit.box(gun, Vector3(0.06, 0.07, 0.36), Vector3(0, 0, -0.08), metal)
	MeshKit.cyl(gun, 0.045, 0.045, 0.32, Vector3(0, -0.075, -0.12), red, Vector3(90, 0, 0), 16)
	MeshKit.cyl(gun, 0.046, 0.046, 0.01, Vector3(0, -0.075, -0.2), metal, Vector3(90, 0, 0), 16)
	MeshKit.cyl(gun, 0.046, 0.046, 0.01, Vector3(0, -0.075, -0.04), metal, Vector3(90, 0, 0), 16)
	MeshKit.cyl(gun, 0.018, 0.018, 0.4, Vector3(0, 0.01, -0.45), metal, Vector3(90, 0, 0), 12)
	MeshKit.cyl(gun, 0.03, 0.022, 0.08, Vector3(0, 0.01, -0.68), metal, Vector3(90, 0, 0), 12)
	MeshKit.cyl(gun, 0.006, 0.006, 0.3, Vector3(0.026, -0.01, -0.5), _metal(Color(0.7, 0.55, 0.3), 0.3), Vector3(90, 0, 0), 6)
	var pilot := MeshKit.sphere(gun, 0.008, Vector3(0.026, -0.01, -0.66), MeshKit.unshaded(Color(0.4, 0.6, 1.0)), Vector3(1, 1, 2))
	pilot.name = "Pilot"
	MeshKit.box(gun, Vector3(0.04, 0.12, 0.055), Vector3(0, -0.07, 0.1), _poly(Color(0.1, 0.1, 0.1)), Vector3(18, 0, 0))
	MeshKit.box(gun, Vector3(0.035, 0.1, 0.04), Vector3(0, -0.06, -0.32), _poly(Color(0.1, 0.1, 0.1)), Vector3(-10, 0, 0))
	var mag := _node(gun, Vector3(0, -0.075, -0.12))
	_arms(gun, Vector3(-0.005, -0.1, -0.32), Vector3(0.015, -0.1, 0.1))
	return {"mag": mag, "bolt": _node(gun, Vector3.ZERO), "muzzle": _node(gun, Vector3(0, 0.01, -0.73)), "eject": _node(gun, Vector3.ZERO),
		"hip": Vector3(0.22, -0.2, -0.52), "ads": Vector3(0.1, -0.15, -0.5)}


# --------------------------------------------------------------------------- grenade launcher

static func _launcher(gun: Node3D) -> Dictionary:
	var metal := _metal(Color(0.12, 0.13, 0.12), 0.45)
	var olive := _poly(Color(0.28, 0.3, 0.22))
	MeshKit.cyl(gun, 0.04, 0.04, 0.42, Vector3(0, 0.02, -0.33), metal, Vector3(90, 0, 0), 18)
	MeshKit.cyl(gun, 0.034, 0.034, 0.43, Vector3(0, 0.02, -0.33), MeshKit.mat(Color(0.02, 0.02, 0.02)), Vector3(90, 0, 0), 18)
	var mag := _node(gun, Vector3(0, 0.0, -0.05))
	MeshKit.cyl(mag, 0.075, 0.075, 0.13, Vector3.ZERO, olive, Vector3(90, 0, 0), 12)
	for i in 6:
		var a := TAU * i / 6.0
		MeshKit.cyl(mag, 0.022, 0.022, 0.135, Vector3(cos(a) * 0.048, sin(a) * 0.048, 0), MeshKit.mat(Color(0.05, 0.05, 0.05)), Vector3(90, 0, 0), 10)
	MeshKit.box(gun, Vector3(0.05, 0.05, 0.25), Vector3(0, -0.02, 0.12), metal)
	MeshKit.box(gun, Vector3(0.04, 0.12, 0.06), Vector3(0, -0.1, 0.12), olive, Vector3(18, 0, 0))
	MeshKit.box(gun, Vector3(0.04, 0.1, 0.05), Vector3(0, -0.08, -0.32), olive, Vector3(-10, 0, 0))
	MeshKit.box(gun, Vector3(0.05, 0.08, 0.22), Vector3(0, -0.03, 0.34), olive, Vector3(-6, 0, 0))
	MeshKit.box(gun, Vector3(0.004, 0.06, 0.03), Vector3(0, 0.085, -0.25), metal, Vector3(-20, 0, 0))
	_arms(gun, Vector3(-0.005, -0.11, -0.32), Vector3(0.015, -0.12, 0.12))
	return {"mag": mag, "bolt": _node(gun, Vector3.ZERO), "muzzle": _node(gun, Vector3(0, 0.02, -0.56)), "eject": _node(gun, Vector3.ZERO),
		"hip": Vector3(0.23, -0.21, -0.55), "ads": Vector3(0.0, -0.1, -0.48)}


# --------------------------------------------------------------------------- staffs

static func _staff(gun: Node3D, glow: Color) -> Dictionary:
	var wood := _wood()
	var metal := _metal(Color(0.65, 0.55, 0.3), 0.3)
	var pivot := _node(gun, Vector3.ZERO)
	pivot.rotation_degrees = Vector3(-62, 0, -8)
	MeshKit.cyl(pivot, 0.016, 0.02, 1.2, Vector3(0, -0.1, 0), wood, Vector3.ZERO, 10)
	for y in [-0.45, -0.1, 0.25]:
		MeshKit.cyl(pivot, 0.022, 0.022, 0.03, Vector3(0, y, 0), metal, Vector3.ZERO, 10)
	MeshKit.cyl(pivot, 0.03, 0.018, 0.08, Vector3(0, 0.52, 0), metal, Vector3.ZERO, 10)
	for i in 4:
		var a := TAU * i / 4.0
		MeshKit.box(pivot, Vector3(0.012, 0.12, 0.012), Vector3(cos(a) * 0.035, 0.6, sin(a) * 0.035), metal, Vector3(sin(a) * 18.0, 0, -cos(a) * 18.0))
	var crystal := MeshKit.mat(glow, 0.1, 0.0, 2.2)
	MeshKit.cyl(pivot, 0.0, 0.03, 0.09, Vector3(0, 0.7, 0), crystal, Vector3.ZERO, 6)
	MeshKit.cyl(pivot, 0.03, 0.0, 0.05, Vector3(0, 0.63, 0), crystal, Vector3.ZERO, 6)
	MeshKit.sphere(pivot, 0.06, Vector3(0, 0.66, 0), MeshKit.glow(Color(glow, 0.35)))
	var l := OmniLight3D.new()
	l.light_color = glow
	l.light_energy = 0.8
	l.omni_range = 2.5
	l.position = Vector3(0, 0.66, 0)
	l.layers = 2
	pivot.add_child(l)
	var tip := _node(pivot, Vector3(0, 0.75, 0))
	_arms(gun, Vector3(-0.02, -0.15, -0.12), Vector3(0.02, -0.25, 0.08))
	return {"mag": _node(gun, Vector3.ZERO), "bolt": _node(gun, Vector3.ZERO), "muzzle": tip, "eject": _node(gun, Vector3.ZERO),
		"hip": Vector3(0.28, -0.12, -0.55), "ads": Vector3(0.15, -0.1, -0.5)}
