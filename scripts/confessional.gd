class_name Confessional
extends RefCounted
## A carved Gothic Revival confessional in polished oak: the priest's booth in the middle (a door
## with iron scrollwork grilles over two raised panels, strap hinges, a pierced attic, a gable with
## a rosette and an iron cross) between two open kneeling bays under pointed arches and gables
## with finials.
##
## Local frame: x across (3.3 m wide), y up from the floor, the front faces +z (1.15 m deep).

const W := 3.3          # overall width
const D := 1.15         # depth
const BOOTH := 0.68     # booth side walls at x = +-BOOTH
const OUTER := 1.62     # outer walls at x = +-OUTER

static var _wood_m: StandardMaterial3D
static var _grille_m: StandardMaterial3D
static var _iron_m: StandardMaterial3D
static var _dark_m: StandardMaterial3D


## Builds one under `parent` at `pos` (on the floor) turned by yaw (degrees). Returns its node.
static func build(parent: Node3D, pos: Vector3, yaw_deg := 0.0) -> Node3D:
	var n := Node3D.new()
	n.name = "Confessional"
	n.position = pos
	n.rotation_degrees.y = yaw_deg
	parent.add_child(n)
	var g := GothicChurch.Geo.new()
	_shape(g)
	g.commit(n, 120.0)
	return n


static func _t(x: float, y: float, z: float) -> Transform3D:
	return Transform3D(Basis(), Vector3(x, y, z))


static func _shape(g: GothicChurch.Geo) -> void:
	var wood := wood()
	var iron := iron()
	var dark := dark()
	var grille := grille()
	var fz := D * 0.5                        # front face of the walls
	# plinth, back, walls
	g.box(wood, _t(0, 0.05, 0.02), Vector3(W + 0.1, 0.1, D + 0.1), true)
	g.box(wood, _t(0, 1.275, -fz + 0.03), Vector3(W, 2.35, 0.05), true)
	for s in [-1.0, 1.0]:
		g.box(wood, _t(s * OUTER, 1.2, 0.0), Vector3(0.06, 2.2, D), true)
		g.box(wood, _t(s * BOOTH, 1.32, 0.0), Vector3(0.06, 2.45, D), true)
	# pilasters with bases and capitals
	for x in [-OUTER, -BOOTH, BOOTH, OUTER]:
		var h := 2.5 if absf(x) < 1.0 else 2.3
		g.box(wood, _t(x, 0.1 + h * 0.5, fz), Vector3(0.13, h, 0.13), true)
		g.box(wood, _t(x, 0.16, fz), Vector3(0.18, 0.12, 0.18))
		g.box(wood, _t(x, 0.1 + h - 0.04, fz), Vector3(0.18, 0.08, 0.18))
		g.box(wood, _t(x, 0.1 + h * 0.5, fz + 0.07), Vector3(0.04, h - 0.3, 0.02))   # fluting
	# --- the priest's door
	var dz := fz - 0.01
	g.box(wood, _t(0, 1.2, dz), Vector3(1.24, 2.2, 0.05), true)
	for s in [-1.0, 1.0]:
		# iron scrollwork grilles over a dark opening
		var cx: float = s * 0.25
		g.box(dark, _t(cx, 1.65, dz + 0.027), Vector3(0.4, 0.82, 0.01))
		g.pane(grille, _t(cx, 1.65, dz + 0.04), PackedVector2Array([Vector2(-0.2, -0.41), Vector2(0.2, -0.41), Vector2(0.2, 0.41), Vector2(-0.2, 0.41)]), 1.0)
		g.box(wood, _t(cx + s * 0.22, 1.65, dz + 0.04), Vector3(0.05, 0.9, 0.04))
		# raised panels below
		g.box(wood, _t(cx, 0.62, dz + 0.035), Vector3(0.38, 0.8, 0.02))
		g.box(field(), _t(cx, 0.62, dz + 0.05), Vector3(0.26, 0.66, 0.02))
		g.box(wood, _t(cx, 0.62, dz + 0.062), Vector3(0.08, 0.5, 0.012))
	g.box(wood, _t(0, 1.65, dz + 0.04), Vector3(0.06, 0.9, 0.04))           # mullion
	g.box(wood, _t(0, 2.12, dz + 0.04), Vector3(0.54, 0.05, 0.04))
	g.box(wood, _t(0, 1.18, dz + 0.04), Vector3(0.54, 0.05, 0.04))
	g.box(wood, _t(0, 2.22, dz + 0.05), Vector3(0.12, 0.12, 0.03))           # carved boss
	g.box(wood, _t(0, 2.22, dz + 0.06), Vector3(0.07, 0.07, 0.03), false)
	for y in [0.3, 1.12, 2.06]:                                             # strap hinges
		g.box(iron, _t(-0.06, y, dz + 0.07), Vector3(1.04, 0.035, 0.012))
		g.box(iron, _t(-0.56, y, dz + 0.07), Vector3(0.05, 0.08, 0.014))
	g.box(iron, _t(0.5, 1.15, dz + 0.07), Vector3(0.04, 0.12, 0.03))         # handle
	# cornice over the door, the pierced attic and its gable
	g.box(wood, _t(0, 2.67, 0.03), Vector3(1.62, 0.12, D + 0.12), true)
	g.box(wood, _t(0, 2.75, 0.03), Vector3(1.5, 0.05, D + 0.06))
	g.box(wood, _t(0, 3.12, -0.02), Vector3(1.3, 0.7, D - 0.1), true)
	for s in [-1.0, 1.0]:
		var ax: float = s * 0.22
		var opening := GothicChurch.arch(ax, 3.22, 0.15, 0.2)
		opening.append(Vector2(ax + 0.15, 2.92))
		opening.append(Vector2(ax - 0.15, 2.92))
		g.extrude(dark, _t(0, 0, fz - 0.06), opening, 0.0, 0.015)
		g.pane(grille, _t(0, 0, fz - 0.035), opening, 1.25)
		g.extrude(wood, _t(0, 0, fz - 0.06), GothicChurch.band(GothicChurch.arch(ax, 3.22, 0.15, 0.2, 0.04), GothicChurch.arch(ax, 3.22, 0.15, 0.2)), 0.0, 0.05)
		g.box(wood, _t(s * 0.6, 3.12, fz - 0.03), Vector3(0.09, 0.72, 0.09))     # attic posts
		g.cyl(wood, _t(s * 0.6, 3.48, fz - 0.03), 0.055, 0.0, 0.32, 4, false, false, PI * 0.25)   # pinnacles
		g.box(wood, _t(s * 0.6, 3.82, fz - 0.03), Vector3(0.03, 0.05, 0.03))
	g.box(wood, _t(0, 3.5, 0.0), Vector3(1.46, 0.07, D), true)
	_gable(g, wood, 0.0, 0.78, 3.54, 0.52, -0.5, fz + 0.02)
	g.extrude(wood, _t(0, 0, fz + 0.02), GothicChurch.circle(Vector2(0, 3.72), 0.085, 16), 0.0, 0.03)
	g.extrude(dark, _t(0, 0, fz + 0.02), GothicChurch.circle(Vector2(0, 3.72), 0.05, 16), 0.0, 0.035)
	# iron cross on the apex
	g.box(wood, _t(0, 4.1, 0.0), Vector3(0.12, 0.1, 0.12))
	g.box(iron, _t(0, 4.36, 0.0), Vector3(0.045, 0.45, 0.045))
	g.box(iron, _t(0, 4.44, 0.0), Vector3(0.26, 0.045, 0.045))
	for p in [Vector3(0, 4.6, 0), Vector3(0.13, 4.44, 0), Vector3(-0.13, 4.44, 0)]:
		g.box(iron, Transform3D(Basis(), p), Vector3(0.06, 0.06, 0.06))
	# --- the kneeling bays
	for s in [-1.0, 1.0]:
		var cx: float = s * (BOOTH + OUTER) * 0.5
		var hw := (OUTER - BOOTH) * 0.5 - 0.07
		var spring := 1.95
		var rise := 0.45
		var x0: float = cx - (OUTER - BOOTH) * 0.5
		var x1: float = cx + (OUTER - BOOTH) * 0.5
		var top := 2.45
		# spandrels and arch moulding over the open front
		var a := GothicChurch.arch(cx, spring, hw, rise)
		var half := a.size() / 2
		var lp := PackedVector2Array([Vector2(x0, top), Vector2(x0, spring)])
		for i in half + 1:
			lp.append(a[i])
		lp.append(Vector2(cx, top))
		var rp := PackedVector2Array([Vector2(cx, top)])
		for i in range(half, a.size()):
			rp.append(a[i])
		rp.append(Vector2(x1, spring))
		rp.append(Vector2(x1, top))
		g.extrude(wood, _t(0, 0, fz - 0.04), lp, 0.0, 0.05, true)
		g.extrude(wood, _t(0, 0, fz - 0.04), rp, 0.0, 0.05, true)
		g.extrude(wood, _t(0, 0, fz - 0.04), GothicChurch.band(GothicChurch.arch(cx, spring, hw, rise, 0.05), a), 0.0, 0.08)
		# a trefoil-ish carving in the spandrel and a cornice
		g.extrude(wood, _t(0, 0, fz + 0.01), GothicChurch.circle(Vector2(cx, top - 0.05), 0.06, 12), 0.0, 0.03)
		g.box(wood, _t(cx, top + 0.05, 0.02), Vector3(x1 - x0 + 0.12, 0.1, D + 0.08), true)
		# gable with a finial, and a pinnacle on the outer corner
		_gable(g, wood, cx, (x1 - x0) * 0.5 + 0.04, top + 0.1, 0.42, -0.5, fz + 0.02)
		g.cyl(wood, _t(cx, top + 0.52, fz), 0.035, 0.0, 0.18, 4, false, false, PI * 0.25)
		g.box(wood, _t(s * OUTER, top + 0.2, fz), Vector3(0.14, 0.2, 0.14))
		g.cyl(wood, _t(s * OUTER, top + 0.3, fz), 0.07, 0.0, 0.34, 4, false, false, PI * 0.25)
		g.box(wood, _t(s * OUTER, top + 0.68, fz), Vector3(0.05, 0.08, 0.05))
		# inside: panelled back, a shelf, a kneeler and the little grille into the booth
		for k in 3:
			g.box(wood, _t(x0 + 0.18 + k * 0.3, 1.25, -fz + 0.07), Vector3(0.04, 2.0, 0.02))
		g.box(wood, _t(cx, 1.2, -fz + 0.08), Vector3(x1 - x0 - 0.08, 0.04, 0.05))
		g.box(wood, _t(cx, 1.02, -fz + 0.17), Vector3(x1 - x0 - 0.08, 0.04, 0.22))
		g.box(wood, _t(cx, 0.2, 0.0), Vector3(x1 - x0 - 0.08, 0.1, 0.32), true)
		# the outer side: framed, raised panels like the door
		var ox: float = s * (OUTER + 0.035)
		for z in [-0.48, 0.0, 0.48]:
			g.box(wood, _t(ox, 1.2, z), Vector3(0.025, 2.0, 0.07))
		for y in [0.22, 1.12, 2.18]:
			g.box(wood, _t(ox, y, 0.0), Vector3(0.025, 0.07, 1.03))
		for z in [-0.24, 0.24]:
			for y in [0.67, 1.65]:
				g.box(field(), _t(ox, y, z), Vector3(0.015, 0.8 if y < 1.0 else 0.95, 0.38))
				g.box(wood, _t(ox + s * 0.01, y, z), Vector3(0.015, 0.6 if y < 1.0 else 0.75, 0.24))
		var gx: float = s * (BOOTH + 0.035)
		g.box(dark, _t(gx, 1.45, -0.05), Vector3(0.01, 0.34, 0.3))
		g.box(wood, _t(gx + s * 0.01, 1.45, -0.05), Vector3(0.015, 0.4, 0.04))


## A gable from cx - half to cx + half, its foot at y0 and apex `h` above, through z0..z1, with
## raking mouldings on the front.
static func _gable(g: GothicChurch.Geo, wood: Material, cx: float, half: float, y0: float, h: float, z0: float, z1: float) -> void:
	var tri := PackedVector2Array([Vector2(cx - half, y0), Vector2(cx + half, y0), Vector2(cx, y0 + h)])
	g.extrude(wood, Transform3D.IDENTITY, tri, z0, z1, true)
	for s in [-1.0, 1.0]:
		var a := Vector3(cx + s * (half + 0.03), y0 - 0.01, z1 + 0.025)
		var b := Vector3(cx, y0 + h + 0.03, z1 + 0.025)
		g.beam(wood, a, b, 0.07, 0.05, Vector3(0, 0, 1))
		g.beam(wood, Vector3(a.x, a.y, z0), Vector3(b.x, b.y, z0), 0.07, 0.05, Vector3(0, 0, 1))


# --------------------------------------------------------------------------- materials

## Polished oak: warm honey brown, long vertical grain, a little clear coat.
static func wood() -> StandardMaterial3D:
	if _wood_m:
		return _wood_m
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_PERLIN
	n.frequency = 0.035
	n.fractal_octaves = 4
	var gr := Gradient.new()
	gr.set_color(0, Color(0.17, 0.075, 0.03))
	gr.set_color(1, Color(0.4, 0.2, 0.085))
	var t := NoiseTexture2D.new()
	t.width = 256
	t.height = 256
	t.seamless = true
	t.noise = n
	t.color_ramp = gr
	var m := StandardMaterial3D.new()
	m.albedo_texture = t
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(5.0, 0.45, 5.0)    # stretched up the y axis: vertical grain
	m.roughness = 0.42
	m.clearcoat_enabled = true
	m.clearcoat = 0.35
	m.clearcoat_roughness = 0.3
	_wood_m = m
	return m


## The same oak a shade darker: recessed panel fields.
static var _field_m: StandardMaterial3D
static func field() -> StandardMaterial3D:
	if _field_m == null:
		_field_m = wood().duplicate() as StandardMaterial3D
		_field_m.albedo_color = Color(0.72, 0.68, 0.65)
	return _field_m


static func iron() -> StandardMaterial3D:
	if _iron_m == null:
		_iron_m = MeshKit.mat(Color(0.1, 0.095, 0.09), 0.45, 0.75)
	return _iron_m


static func dark() -> StandardMaterial3D:
	if _dark_m == null:
		_dark_m = MeshKit.mat(Color(0.015, 0.012, 0.01), 1.0)
	return _dark_m


## Wrought-iron scrollwork: C-scrolls in two columns between straight bars (alpha-cut).
static func grille() -> StandardMaterial3D:
	if _grille_m:
		return _grille_m
	var sz := 128
	var img := Image.create_empty(sz, sz, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Color(0.42, 0.4, 0.37, 1.0)
	# one tile = 0.4 m x 0.4 m of grille (pane uv_scale 1.0 -> 1 tile per metre... see below)
	var cells := 2
	var cs := sz / cells
	for cy in cells:
		for cx in cells:
			var o := Vector2(cx * cs + cs * 0.5, cy * cs + cs * 0.5)
			for py in range(int(o.y - cs * 0.5), int(o.y + cs * 0.5)):
				for px in range(int(o.x - cs * 0.5), int(o.x + cs * 0.5)):
					var p := Vector2(px + 0.5, py + 0.5) - o
					var on := false
					# a ring and two smaller curls (a stylised scroll)
					var r := p.length()
					if absf(r - cs * 0.36) < 2.4:
						on = true
					for k in [-1.0, 1.0]:
						var q := p - Vector2(0, k * cs * 0.18)
						if absf(q.length() - cs * 0.13) < 2.0 and q.x * k > -2.0:
							on = true
					if absf(p.x) < 1.8 or absf(p.y + cs * 0.5) < 2.2 or absf(p.x + cs * 0.5) < 2.2:
						on = true
					if on:
						img.set_pixel(px % sz, py % sz, c)
	img.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.4
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.metallic = 0.7
	m.roughness = 0.35
	m.uv1_scale = Vector3(2.5, 2.5, 1)       # pane UVs are in metres: 2.5 tiles per metre
	_grille_m = m
	return m
