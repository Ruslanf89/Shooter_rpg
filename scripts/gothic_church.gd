class_name GothicChurch
extends RefCounted
## A gothic abbey church in the English manner (after Salisbury): a broad screen front with
## spired turrets, three portals, a triple lancet and a rose window; a tall vaulted nave with lower
## side aisles held up by flying buttresses; transepts; a crossing tower with a tall stone spire; a
## two-bay choir with a flat east end. Pointed arches, tracery and ribbed vaults are built from
## extruded outlines and merged into a few meshes (one per material).
##
## Local frame: x across the church, y up, the west front's face at z = 0; the church runs to -z.
## Distances along the church are given as u = -z.

# --- plan (metres)
const NAVE_IN := 4.6        # nave wall, inner face (|x|)
const NAVE_OUT := 5.4       # nave wall, outer face
const PIER_X := 5.0         # arcade line (centre of the nave wall)
const AISLE_IN := 9.0       # aisle wall, inner face
const AISLE_OUT := 9.9      # aisle wall, outer face
const FRONT := 1.6          # thickness of the west front
const BAY := 5.0
const NAVE_BAYS := 6
const U_CROSS0 := 31.6      # crossing (and transepts) from u = 31.6 ...
const U_CROSS1 := 40.8      # ... to 40.8
const CHOIR_BAYS := 2
const U_EAST := 50.8        # east wall, inner face
const TRANS_IN := 18.5      # transept end wall, inner face (|x|)
const TRANS_OUT := 19.5
const CROSS_Z := -36.2      # crossing centre
# --- heights
const ARCADE_SPRING := 5.6
const ARCADE_RISE := 2.2
const TRIFORIUM := 8.6
const CLERESTORY := 11.0
const VAULT_SPRING := 11.4
const VAULT_RISE := 6.0
const AISLE_SPRING := 5.5
const AISLE_RISE := 2.6
const AISLE_TOP := 8.4
const WALL_TOP := 18.0
const GABLE_TOP := 25.6
const RIDGE := 25.4

static var _glass_tex: ImageTexture


# =========================================================================== geometry

## Collects triangles per material (and collision faces) and turns them into meshes at the end.
class Geo:
	var surf := {}                          # Material -> SurfaceTool
	var col := PackedVector3Array()

	func _st(m: Material) -> SurfaceTool:
		if not surf.has(m):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			surf[m] = st
		return surf[m]

	## One triangle (any vertex order), turned to face `facing`. Optional smooth normals / UVs.
	func tri(m: Material, a: Vector3, b: Vector3, c: Vector3, facing: Vector3, collide := false, ns: Array = [], uvs: Array = []) -> void:
		var n := (b - a).cross(c - a)
		if n.length_squared() < 1e-14:
			return
		var order := [0, 2, 1]               # Godot's front faces wind clockwise
		if n.dot(facing) < 0.0:
			order = [0, 1, 2]
			n = -n
		n = n.normalized()
		var vs := [a, b, c]
		var st := _st(m)
		for i in order:
			st.set_normal(ns[i] if not ns.is_empty() else n)
			st.set_uv(uvs[i] if not uvs.is_empty() else Vector2.ZERO)
			st.add_vertex(vs[i])
		if collide:
			for i in order:
				col.append(vs[i])

	func quad(m: Material, a: Vector3, b: Vector3, c: Vector3, d: Vector3, facing: Vector3, collide := false) -> void:
		tri(m, a, b, c, facing, collide)
		tri(m, a, c, d, facing, collide)

	func box(m: Material, t: Transform3D, size: Vector3, collide := false) -> void:
		var h := size * 0.5
		var c: Array[Vector3] = []
		for i in 8:
			c.append(t * Vector3(h.x if i & 1 else -h.x, h.y if i & 2 else -h.y, h.z if i & 4 else -h.z))
		var bx := t.basis.x
		var by := t.basis.y
		var bz := t.basis.z
		quad(m, c[1], c[3], c[7], c[5], bx, collide)
		quad(m, c[0], c[2], c[6], c[4], -bx, collide)
		quad(m, c[2], c[3], c[7], c[6], by, collide)
		quad(m, c[0], c[1], c[5], c[4], -by, collide)
		quad(m, c[4], c[5], c[7], c[6], bz, collide)
		quad(m, c[0], c[1], c[3], c[2], -bz, collide)

	## A flat outline (local x/y) extruded from z0 to z1.
	func extrude(m: Material, t: Transform3D, poly: PackedVector2Array, z0: float, z1: float, collide := false, caps := true) -> void:
		var p := GothicChurch.ccw(poly)
		if p.size() < 3:
			return
		if caps:
			var idx := Geometry2D.triangulate_polygon(p)
			if idx.is_empty():
				push_warning("GothicChurch: an outline could not be triangulated")
			var fz := t.basis.z
			for i in range(0, idx.size(), 3):
				var a := p[idx[i]]
				var b := p[idx[i + 1]]
				var c := p[idx[i + 2]]
				tri(m, t * Vector3(a.x, a.y, z1), t * Vector3(b.x, b.y, z1), t * Vector3(c.x, c.y, z1), fz, collide)
				tri(m, t * Vector3(a.x, a.y, z0), t * Vector3(b.x, b.y, z0), t * Vector3(c.x, c.y, z0), -fz, collide)
		for i in p.size():
			var a := p[i]
			var b := p[(i + 1) % p.size()]
			var e := b - a
			var f := t.basis * Vector3(e.y, -e.x, 0.0)
			quad(m, t * Vector3(a.x, a.y, z0), t * Vector3(b.x, b.y, z0), t * Vector3(b.x, b.y, z1), t * Vector3(a.x, a.y, z1), f, collide)

	## A flat pane (both sides drawn by its material) with UVs from the outline.
	func pane(m: Material, t: Transform3D, poly: PackedVector2Array, uv_scale := 0.42) -> void:
		var p := GothicChurch.ccw(poly)
		var idx := Geometry2D.triangulate_polygon(p)
		for i in range(0, idx.size(), 3):
			var vs: Array = []
			var uvs: Array = []
			for k in 3:
				var q := p[idx[i + k]]
				vs.append(t * Vector3(q.x, q.y, 0.0))
				uvs.append(Vector2(q.x, -q.y) * uv_scale)
			tri(m, vs[0], vs[1], vs[2], t.basis.z, false, [], uvs)

	## A cylinder or cone standing on t's origin along t's y axis.
	func cyl(m: Material, t: Transform3D, r0: float, r1: float, h: float, seg: int, collide := false, smooth := true, rot := 0.0) -> void:
		var slope := (r0 - r1) / h
		for i in seg:
			var a0 := rot + TAU * i / seg
			var a1 := rot + TAU * (i + 1) / seg
			var b0 := t * Vector3(cos(a0) * r0, 0, sin(a0) * r0)
			var b1 := t * Vector3(cos(a1) * r0, 0, sin(a1) * r0)
			var u0 := t * Vector3(cos(a0) * r1, h, sin(a0) * r1)
			var u1 := t * Vector3(cos(a1) * r1, h, sin(a1) * r1)
			var am := (a0 + a1) * 0.5
			var nf := (t.basis * Vector3(cos(am), slope, sin(am))).normalized()
			if smooth:
				var n0 := (t.basis * Vector3(cos(a0), slope, sin(a0))).normalized()
				var n1 := (t.basis * Vector3(cos(a1), slope, sin(a1))).normalized()
				tri(m, b0, b1, u1, nf, collide, [n0, n1, n1])
				tri(m, b0, u1, u0, nf, collide, [n0, n1, n0])
			else:
				quad(m, b0, b1, u1, u0, nf, collide)
			if r1 > 0.001:
				tri(m, t * Vector3(0, h, 0), u0, u1, t.basis.y, collide)

	## A square beam from a to b (rib, spoke, coping). `up` picks which way its height points.
	func beam(m: Material, a: Vector3, b: Vector3, w: float, h: float, up := Vector3.UP, collide := false) -> void:
		var d := b - a
		var l := d.length()
		if l < 0.001:
			return
		var z := d / l
		var x := up.cross(z)
		if x.length() < 0.01:
			x = Vector3.RIGHT.cross(z)
		x = x.normalized()
		box(m, Transform3D(Basis(x, z.cross(x), z), (a + b) * 0.5), Vector3(w, h, l), collide)

	func commit(parent: Node3D, vis_end := 0.0) -> void:
		for m in surf:
			var mi := MeshInstance3D.new()
			mi.mesh = (surf[m] as SurfaceTool).commit()
			mi.material_override = m
			if vis_end > 0.0:
				mi.visibility_range_end = vis_end
				mi.visibility_range_end_margin = 8.0
				mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
			parent.add_child(mi)
		if not col.is_empty():
			var sh := ConcavePolygonShape3D.new()
			sh.backface_collision = true
			sh.set_faces(col)
			var body := StaticBody3D.new()
			body.set_meta("surface", "stone")
			var cs := CollisionShape3D.new()
			cs.shape = sh
			body.add_child(cs)
			parent.add_child(body)


# =========================================================================== outlines

## The outline turned counter-clockwise, without repeated points.
static func ccw(poly: PackedVector2Array) -> PackedVector2Array:
	var p := PackedVector2Array()
	for q in poly:
		if p.is_empty() or p[p.size() - 1].distance_to(q) > 0.002:
			p.append(q)
	if p.size() > 2 and p[0].distance_to(p[p.size() - 1]) < 0.002:
		p.remove_at(p.size() - 1)
	var area := 0.0
	for i in p.size():
		var a := p[i]
		var b := p[(i + 1) % p.size()]
		area += a.x * b.y - b.x * a.y
	if area < 0.0:
		p.reverse()
	return p


## A pointed arch over [cx - hw, cx + hw] springing at y0 and rising `rise` (at least hw), from the
## left springing point over the apex to the right one. `off` grows it outwards (mouldings).
static func arch(cx: float, y0: float, hw: float, rise: float, off := 0.0, seg := 7) -> PackedVector2Array:
	var r := maxf((rise * rise + hw * hw) / (2.0 * hw), hw)
	var d := r - hw                          # the left arc's centre sits d to the right of cx
	var rr := r + off
	var th := acos(clampf(-d / rr, -1.0, 1.0))
	var left := PackedVector2Array()
	for i in seg + 1:
		var a := lerpf(PI, th, float(i) / seg)
		left.append(Vector2(cx + d + cos(a) * rr, y0 + sin(a) * rr))
	var out := left.duplicate()
	for i in range(seg - 1, -1, -1):
		out.append(Vector2(2.0 * cx - left[i].x, left[i].y))
	return out


## Height of a pointed arch (span 2 hw, `rise`) above its springing, u from its centre.
static func arch_h(u: float, hw: float, rise: float) -> float:
	var r := maxf((rise * rise + hw * hw) / (2.0 * hw), hw)
	var x := absf(u) + r - hw
	return sqrt(maxf(0.0, r * r - x * x))


## The band between two arch curves (an arch moulding / tracery bar).
static func band(outer: PackedVector2Array, inner: PackedVector2Array) -> PackedVector2Array:
	var p := outer.duplicate()
	var rev := inner.duplicate()
	rev.reverse()
	p.append_array(rev)
	return p


static func circle(c: Vector2, r: float, seg := 20) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in seg:
		p.append(c + Vector2(cos(TAU * i / seg), sin(TAU * i / seg)) * r)
	return p


## A triangular gable [cx - half, cx + half] from y0 to its apex y1, pierced by a round window
## (radius oc_r at height oc_y): two outlines, one each side of the centre line.
static func gable_polys(cx: float, half: float, y0: float, y1: float, oc_y: float, oc_r: float) -> Array:
	var out := []
	for s in [-1.0, 1.0]:
		var p := PackedVector2Array([Vector2(cx, y0), Vector2(cx + s * half, y0), Vector2(cx, y1), Vector2(cx, oc_y + oc_r)])
		for i in range(1, 12):
			var a := PI * 0.5 - PI * i / 12.0
			p.append(Vector2(cx + s * cos(a) * oc_r, oc_y + sin(a) * oc_r))
		p.append(Vector2(cx, oc_y - oc_r))
		out.append(p)
	return out


## An opening: centre, width, sill, springing height and rise of its pointed head.
static func op(cx: float, w: float, sill: float, spring: float, rise: float) -> Dictionary:
	return {"cx": cx, "w": w, "sill": sill, "spring": spring, "rise": rise}


## A wall in t's x/y plane (thickness along z) from x0 to x1 and y0 to y1, with pointed openings.
static func wall(g: Geo, m: Material, t: Transform3D, x0: float, x1: float, y0: float, y1: float, th: float, ops: Array, collide := true) -> void:
	var list := ops.duplicate()
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["cx"] < b["cx"])
	var x := x0
	for o: Dictionary in list:
		var l: float = o["cx"] - o["w"] * 0.5
		var r: float = o["cx"] + o["w"] * 0.5
		if float(o["spring"]) + float(o["rise"]) > y1 - 0.05:
			push_warning("GothicChurch: an opening pokes out of its wall")
		if l > x + 0.01:
			g.box(m, t * Transform3D(Basis(), Vector3((x + l) * 0.5, (y0 + y1) * 0.5, 0)), Vector3(l - x, y1 - y0, th), collide)
		if o["sill"] > y0 + 0.01:
			g.box(m, t * Transform3D(Basis(), Vector3(o["cx"], (y0 + o["sill"]) * 0.5, 0)), Vector3(o["w"], o["sill"] - y0, th), collide)
		var p := arch(o["cx"], o["spring"], o["w"] * 0.5, o["rise"])
		p.append(Vector2(r, y1))
		p.append(Vector2(l, y1))
		g.extrude(m, t, p, -th * 0.5, th * 0.5, collide)
		x = r
	if x1 > x + 0.01:
		g.box(m, t * Transform3D(Basis(), Vector3((x + x1) * 0.5, (y0 + y1) * 0.5, 0)), Vector3(x1 - x, y1 - y0, th), collide)


## Stained glass in an opening (in t's z = 0 plane) and its tracery: "" a plain lancet, "two" two
## lights under a circle (bar tracery, as at Salisbury's cloisters and Westminster).
static func fill(g: Geo, t: Transform3D, o: Dictionary, style: String, glass: Material, trac: Material) -> void:
	var cx: float = o["cx"]
	var hw: float = o["w"] * 0.5
	var sp: float = o["spring"]
	var rise: float = o["rise"]
	var sill: float = o["sill"]
	var p := arch(cx, sp, hw, rise)
	p.append(Vector2(cx + hw, sill))
	p.append(Vector2(cx - hw, sill))
	g.pane(glass, t, p)
	if style != "two":
		return
	var mw := 0.11
	var top := sp + rise * 0.3
	g.box(trac, t * Transform3D(Basis(), Vector3(cx, (sill + top) * 0.5, 0)), Vector3(mw, top - sill, 0.16))
	var lhw := (hw - mw * 0.5) * 0.5
	for s in [-1.0, 1.0]:
		var lc: float = cx + s * (mw * 0.5 + lhw)
		g.extrude(trac, t, band(arch(lc, sp, lhw, rise * 0.48), arch(lc, sp, lhw, rise * 0.48, -0.08)), -0.08, 0.08)
	var orr := minf(hw * 0.42, rise * 0.24)
	ring(g, trac, t, Vector2(cx, sp + rise * 0.5 + orr), orr - 0.07, orr, -0.08, 0.08, 14)
	# the transom across the springing
	g.box(trac, t * Transform3D(Basis(), Vector3(cx, sp, 0)), Vector3(o["w"], 0.08, 0.14))


static func ring(g: Geo, m: Material, t: Transform3D, c: Vector2, r0: float, r1: float, z0: float, z1: float, seg := 16) -> void:
	for i in seg:
		var a0 := TAU * i / seg
		var a1 := TAU * (i + 1) / seg
		var d0 := Vector2(cos(a0), sin(a0))
		var d1 := Vector2(cos(a1), sin(a1))
		g.extrude(m, t, PackedVector2Array([c + d0 * r0, c + d0 * r1, c + d1 * r1, c + d1 * r0]), z0, z1)


## A rose window: glass disc, outer and inner rings, twelve spokes and twelve small roundels.
static func rose(g: Geo, t: Transform3D, c: Vector2, r: float, glass: Material, trac: Material) -> void:
	g.pane(glass, t, circle(c, r, 28))
	ring(g, trac, t, c, r - 0.16, r + 0.08, -0.14, 0.14, 28)
	ring(g, trac, t, c, r * 0.26 - 0.08, r * 0.26, -0.12, 0.12, 14)
	for i in 12:
		var a := TAU * i / 12.0
		var d := Vector2(cos(a), sin(a))
		var p0 := c + d * r * 0.26
		var p1 := c + d * (r - 0.14)
		g.beam(trac, t * Vector3(p0.x, p0.y, 0), t * Vector3(p1.x, p1.y, 0), 0.08, 0.18, t.basis.z)
		var pc := c + Vector2(cos(a + PI / 12.0), sin(a + PI / 12.0)) * r * 0.64
		ring(g, trac, t, pc, r * 0.14 - 0.06, r * 0.14, -0.09, 0.09, 10)


## A gothic pinnacle: a square shaft with a little gable cornice and a slender four-sided spirelet.
static func pinnacle(g: Geo, m: Material, t: Transform3D, size: float, h: float) -> void:
	g.box(m, t * Transform3D(Basis(), Vector3(0, size * 0.7, 0)), Vector3(size, size * 1.4, size))
	g.box(m, t * Transform3D(Basis(), Vector3(0, size * 1.45, 0)), Vector3(size * 1.15, size * 0.12, size * 1.15))
	g.cyl(m, t * Transform3D(Basis(), Vector3(0, size * 1.5, 0)), size * 0.62, 0.0, h - size * 1.5, 4, false, false, PI * 0.25)


## A round (octagonal) stair turret with a cornice and a stone spirelet.
static func turret(g: Geo, m: Material, trim: Material, p: Vector3, r: float, h: float, spire: float) -> void:
	g.cyl(m, Transform3D(Basis(), p), r, r, h, 8, true, false, PI / 8.0)
	g.cyl(trim, Transform3D(Basis(), p + Vector3(0, h, 0)), r * 1.18, r * 1.18, 0.4, 8, false, false, PI / 8.0)
	g.cyl(m, Transform3D(Basis(), p + Vector3(0, h + 0.4, 0)), r * 1.05, 0.0, spire, 8, false, false, PI / 8.0)
	for k in 3:
		var y := h * (0.3 + 0.25 * k)
		g.cyl(trim, Transform3D(Basis(), p + Vector3(0, y, 0)), r * 1.06, r * 1.06, 0.18, 8, false, false, PI / 8.0)


## A quadripartite rib vault over one bay (t: bay centre at the springing; x across, z along):
## two pointed tunnels crossing, with diagonal, transverse and ridge ribs and a boss.
static func vault(g: Geo, m: Material, rib: Material, boss: Material, t: Transform3D, sx: float, sz: float, rise: float, n := 12) -> void:
	var hx := sx * 0.5
	var hz := sz * 0.5
	var pts: Array[Vector3] = []
	var nrm: Array[Vector3] = []
	var e := 0.02
	for j in n + 1:
		for i in n + 1:
			var x := -hx + sx * i / n
			var z := -hz + sz * j / n
			var dx := (_vh(x + e, z, hx, hz, rise) - _vh(x - e, z, hx, hz, rise)) / (2.0 * e)
			var dz := (_vh(x, z + e, hx, hz, rise) - _vh(x, z - e, hx, hz, rise)) / (2.0 * e)
			pts.append(t * Vector3(x, _vh(x, z, hx, hz, rise), z))
			nrm.append((t.basis * Vector3(dx, -1.0, dz)).normalized())
	var down := -t.basis.y
	for j in n:
		for i in n:
			var a := j * (n + 1) + i
			var b := a + 1
			var c := a + n + 2
			var d := a + n + 1
			g.tri(m, pts[a], pts[b], pts[c], down, false, [nrm[a], nrm[b], nrm[c]])
			g.tri(m, pts[a], pts[c], pts[d], down, false, [nrm[a], nrm[c], nrm[d]])
	# diagonal ribs along the groins, from each corner to the crown
	for sxn in [-1.0, 1.0]:
		for szn in [-1.0, 1.0]:
			var prev := Vector3.ZERO
			for k in 11:
				var x := hx * (1.0 - k / 10.0)
				var yv := arch_h(x, hx, rise)
				var lo := 0.0
				var hi := hz
				for it in 18:
					var mid := (lo + hi) * 0.5
					if arch_h(mid, hz, rise) > yv:
						lo = mid
					else:
						hi = mid
				var p := t * Vector3(sxn * x, yv - 0.05, szn * lo)
				if k > 0:
					g.beam(rib, prev, p, 0.18, 0.22)
				prev = p
	# transverse ribs on both bay edges, ridge ribs, boss
	for szn in [-1.0, 1.0]:
		var prev := Vector3.ZERO
		for k in 13:
			var x := -hx + sx * k / 12.0
			var p := t * Vector3(x, arch_h(x, hx, rise) - 0.06, szn * hz)
			if k > 0:
				g.beam(rib, prev, p, 0.26, 0.28)
			prev = p
	g.beam(rib, t * Vector3(0, rise - 0.04, -hz), t * Vector3(0, rise - 0.04, hz), 0.14, 0.14)
	g.beam(rib, t * Vector3(-hx, rise - 0.04, 0), t * Vector3(hx, rise - 0.04, 0), 0.14, 0.14)
	g.box(boss, Transform3D(t.basis * Basis(Vector3.UP, PI * 0.25), t * Vector3(0, rise - 0.12, 0)), Vector3(0.42, 0.3, 0.42))


static func _vh(x: float, z: float, hx: float, hz: float, rise: float) -> float:
	return maxf(arch_h(clampf(x, -hx, hx), hx, rise), arch_h(clampf(z, -hz, hz), hz, rise))


static func _t(p: Vector3) -> Transform3D:
	return Transform3D(Basis(), p)


## Frame of a wall running along the church at x (local x = u = -z, local z = s * world x).
static func axis_frame(x: float, s: float) -> Transform3D:
	return Transform3D(Basis(Vector3(0, 0, -1), Vector3.UP, Vector3(s, 0, 0)), Vector3(x, 0, 0))


## Frame of a wall across the church at z (local x = s * world x).
static func cross_frame(z: float, s := 1.0) -> Transform3D:
	return Transform3D(Basis(Vector3(s, 0, 0), Vector3.UP, Vector3(0, 0, 1)), Vector3(0, 0, z))


# =========================================================================== materials

## Procedural stained glass: jewel-coloured cells between dark lead lines (tiles seamlessly).
static func glass_texture() -> ImageTexture:
	if _glass_tex:
		return _glass_tex
	var size := 128
	var cells := 8
	var cs := size / cells
	var rng := RandomNumberGenerator.new()
	rng.seed = 1220
	var pal := [Color(0.08, 0.16, 0.62), Color(0.1, 0.22, 0.75), Color(0.62, 0.06, 0.08), Color(0.78, 0.1, 0.1),
		Color(0.92, 0.66, 0.12), Color(0.1, 0.45, 0.2), Color(0.38, 0.12, 0.52), Color(0.85, 0.8, 0.58)]
	var pts := []
	var cols := []
	for j in cells:
		for i in cells:
			pts.append(Vector2((i + rng.randf_range(0.15, 0.85)) * cs, (j + rng.randf_range(0.15, 0.85)) * cs))
			cols.append(pal[rng.randi() % pal.size()])
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	for y in size:
		for x in size:
			var ci := x / cs
			var cj := y / cs
			var d1 := 1e9
			var d2 := 1e9
			var best := 0
			for oj in range(-1, 2):
				for oi in range(-1, 2):
					var ii := posmod(ci + oi, cells)
					var jj := posmod(cj + oj, cells)
					var q: Vector2 = pts[jj * cells + ii] + Vector2((ci + oi - ii) * cs, (cj + oj - jj) * cs)
					var dd := q.distance_to(Vector2(x, y))
					if dd < d1:
						d2 = d1
						d1 = dd
						best = jj * cells + ii
					elif dd < d2:
						d2 = dd
			var c: Color = cols[best]
			if d2 - d1 < 1.7:
				c = Color(0.04, 0.04, 0.045)
			else:
				c = c.lightened(clampf(0.25 - d1 / 40.0, 0.0, 0.25))
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	_glass_tex = ImageTexture.create_from_image(img)
	return _glass_tex


## The glass of one church: glows from inside it, dark and glossy from outside (stained_glass.gdshader).
static func glass_material(root: Node3D) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/stained_glass.gdshader")
	m.set_shader_parameter("glass_tex", glass_texture())
	m.set_shader_parameter("to_local", Projection(root.global_transform.affine_inverse()))
	return m


static func _materials(root: Node3D) -> Dictionary:
	return {
		"stone": Props.stone(Color(1.12, 1.06, 0.94), 0.28),
		"trim": Props.stone(Color(0.92, 0.88, 0.8), 0.28),
		"inner": Props.stone(Color(1.08, 1.03, 0.95), 0.45),
		"roof": MeshKit.textured("RoofingTiles013A", Color(0.8, 0.86, 0.98), 0.55, 0.35, 2.1),
		"floor": Props.stone(Color(0.8, 0.78, 0.74), 0.55),
		"dark": MeshKit.mat(Color(0.05, 0.05, 0.06)),
		"gold": MeshKit.mat(Color(0.95, 0.75, 0.25), 0.4, 0.6),
		"wood": Props.dark_wood(),
		"pew": Props.wood(),
		"iron": MeshKit.mat(Color(0.12, 0.11, 0.1), 0.5, 0.8),
		"red": MeshKit.mat(Color(0.5, 0.08, 0.08), 1.0),
		"cloth": MeshKit.mat(Color(0.9, 0.88, 0.8), 0.95),
		"glass": glass_material(root),
	}


# =========================================================================== the church

## Builds the church with its west front centred on `pos` (on the ground), facing +z rotated by yaw.
static func build(w: Node3D, pos: Vector3, yaw_deg := 0.0) -> Node3D:
	var root := Props.pivot(w, pos, yaw_deg)
	root.name = "AbbeyChurch"
	var g := Geo.new()          # the shell (and its collision)
	var gi := Geo.new()         # interior details, only drawn when near
	var m := _materials(root)
	_west_front(g, m)
	_body(g, gi, m)
	_transepts(g, m)
	_east_end(g, m)
	_tower(g, m)
	_roofs(g, m)
	_interior(gi, m)
	_vaults(gi, m)
	g.commit(root)
	gi.commit(root, 120.0)
	_fittings(root, m)
	# no grass or trees inside
	for u in range(4, 53, 6):
		w.building_areas.append([_flat(root, Vector3(0, 0, -u)), 10.5])
	for s in [-1.0, 1.0]:
		for x in [12.0, 16.0]:
			w.building_areas.append([_flat(root, Vector3(s * x, 0, CROSS_Z)), 6.0])
	return root


static func _flat(root: Node3D, local: Vector3) -> Vector2:
	var p := root.to_global(local)
	return Vector2(p.x, p.z)


# --------------------------------------------------------------------------- west front

static func _west_front(g: Geo, m: Dictionary) -> void:
	var st: Material = m["stone"]
	var trim: Material = m["trim"]
	var t := cross_frame(-FRONT * 0.5)
	# central block: the great portal, then the triple lancet
	var portal := op(0, 3.8, 0, 4.8, 3.0)
	wall(g, st, t, -NAVE_OUT, NAVE_OUT, 0, 8.2, FRONT, [portal])
	var lancets := [op(-2.1, 1.3, 9.8, 12.6, 1.3), op(0, 1.6, 9.8, 14.2, 1.6), op(2.1, 1.3, 9.8, 12.6, 1.3)]
	wall(g, st, t, -NAVE_OUT, NAVE_OUT, 8.2, WALL_TOP, FRONT, lancets)
	for o in lancets:
		fill(g, t, o, "", m["glass"], trim)
		g.extrude(trim, cross_frame(0), band(arch(o["cx"], o["spring"], o["w"] * 0.5, o["rise"], 0.2), arch(o["cx"], o["spring"], o["w"] * 0.5, o["rise"], 0.04)), 0.0, 0.14)
	# gable with the rose window, coping and a cross on top
	var tg := cross_frame(-0.5)
	for p in gable_polys(0, NAVE_OUT, WALL_TOP, GABLE_TOP, 20.7, 2.0):
		g.extrude(st, tg, p, -0.5, 0.5)
	rose(g, tg, Vector2(0, 20.7), 2.0, m["glass"], trim)
	ring(g, trim, cross_frame(0), Vector2(0, 20.7), 2.02, 2.3, 0.0, 0.14, 28)
	for s in [-1.0, 1.0]:
		g.beam(trim, Vector3(s * 5.7, 17.75, -0.5), Vector3(0, GABLE_TOP + 0.25, -0.5), 0.35, 1.2, Vector3.BACK)
	g.box(trim, _t(Vector3(0, GABLE_TOP + 1.0, -0.5)), Vector3(0.28, 1.9, 0.28))
	g.box(trim, _t(Vector3(0, GABLE_TOP + 1.35, -0.5)), Vector3(1.1, 0.26, 0.26))
	# cornice and string course of the central block
	g.box(trim, _t(Vector3(0, WALL_TOP - 0.1, -FRONT * 0.5)), Vector3(2 * NAVE_OUT, 0.3, FRONT + 0.3))
	g.box(trim, _t(Vector3(0, 8.3, 0)), Vector3(2 * NAVE_OUT, 0.25, 0.36))
	# portal: three receding arch mouldings on shafts, a carved tympanum, a hood
	for k in 3:
		var a0 := 0.22 * k
		g.extrude(trim, cross_frame(0), band(arch(0, 4.8, 1.9, 3.0, a0 + 0.22), arch(0, 4.8, 1.9, 3.0, a0)), 0.0, 0.1 + 0.1 * k)
		for s in [-1.0, 1.0]:
			g.cyl(trim, _t(Vector3(s * (1.9 + a0 + 0.11), 0.5, 0.06 + 0.05 * k)), 0.09, 0.09, 4.3, 8)
			g.box(trim, _t(Vector3(s * (1.9 + a0 + 0.11), 4.72, 0.06 + 0.05 * k)), Vector3(0.26, 0.16, 0.26))
	for s in [-1.0, 1.0]:
		g.box(trim, _t(Vector3(s * 2.25, 0.25, 0.15)), Vector3(0.8, 0.5, 0.3))
	g.extrude(trim, cross_frame(-0.8), arch(0, 4.8, 1.9, 3.0), -0.12, 0.12)
	g.cyl(m["gold"], Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 6.05, -0.68)), 0.55, 0.55, 0.06, 20)
	g.box(m["gold"], _t(Vector3(0, 6.05, -0.6)), Vector3(0.12, 0.8, 0.06))
	g.box(m["gold"], _t(Vector3(0, 6.2, -0.6)), Vector3(0.55, 0.12, 0.06))
	g.box(trim, _t(Vector3(0, 4.85, -0.8)), Vector3(3.9, 0.12, 0.3))   # lintel over the doors
	# aisle ends: a blind portal and a lancet, flat top with a parapet
	for s in [-1.0, 1.0]:
		var o := op(s * 7.2, 1.4, 6.2, 9.4, 1.3)
		wall(g, st, t, minf(s * NAVE_OUT, s * 10.2), maxf(s * NAVE_OUT, s * 10.2), 0, 12.6, FRONT, [o])
		fill(g, t, o, "", m["glass"], trim)
		g.extrude(trim, cross_frame(0), band(arch(s * 7.2, 9.4, 0.7, 1.3, 0.2), arch(s * 7.2, 9.4, 0.7, 1.3, 0.04)), 0.0, 0.14)
		g.box(trim, _t(Vector3(s * 7.8, 6.05, 0)), Vector3(4.8, 0.2, 0.32))
		g.box(trim, _t(Vector3(s * 7.8, 12.5, -FRONT * 0.5)), Vector3(4.8, 0.25, FRONT + 0.3))
		g.box(st, _t(Vector3(s * 7.8, 13.1, -0.2)), Vector3(4.8, 0.9, 0.4), true)
		var dp := arch(s * 7.2, 3.2, 0.9, 1.1)
		dp.append(Vector2(s * 7.2 + 0.9, 0))
		dp.append(Vector2(s * 7.2 - 0.9, 0))
		g.extrude(m["wood"], cross_frame(0), dp, 0.0, 0.05)
		g.extrude(trim, cross_frame(0), band(arch(s * 7.2, 3.2, 0.9, 1.1, 0.26), arch(s * 7.2, 3.2, 0.9, 1.1)), 0.0, 0.16)
		for e in [-1.0, 1.0]:
			g.box(trim, _t(Vector3(s * 7.2 + e * 1.03, 1.6, 0.08)), Vector3(0.26, 3.2, 0.16))
		g.box(m["iron"], _t(Vector3(s * 7.2 + 0.45, 1.3, 0.07)), Vector3(0.1, 0.1, 0.06))
		# plinth (gap at the portal)
		g.box(trim, _t(Vector3(s * 6.4, 0.4, 0.1)), Vector3(7.6, 0.8, 0.3))
		# stair turrets
		turret(g, st, trim, Vector3(s * 10.2, 0, -0.8), 0.95, 17.0, 5.0)
		turret(g, st, trim, Vector3(s * NAVE_OUT, 0, -0.8), 0.75, 19.8, 4.8)


# --------------------------------------------------------------------------- nave, aisles, choir

static func _segments() -> Array:
	return [[FRONT, U_CROSS0, NAVE_BAYS], [U_CROSS1, U_EAST, CHOIR_BAYS]]


static func _body(g: Geo, gi: Geo, m: Dictionary) -> void:
	var st: Material = m["stone"]
	var trim: Material = m["trim"]
	for s in [-1.0, 1.0]:
		var ta := axis_frame(s * (AISLE_IN + AISLE_OUT) * 0.5, s)
		var tn := axis_frame(s * PIER_X, s)
		var th := AISLE_OUT - AISLE_IN
		for seg in _segments():
			var u0: float = seg[0]
			var u1: float = seg[1]
			var mid := (u0 + u1) * 0.5
			var length := u1 - u0
			# aisle wall: two-light windows, plinth, sill course, cornice
			var aisle_ops := []
			var clere_ops := []
			for k in int(seg[2]):
				aisle_ops.append(op(u0 + BAY * (k + 0.5), 2.4, 2.2, 5.0, 1.6))
				clere_ops.append(op(u0 + BAY * (k + 0.5), 2.0, 12.0, 14.4, 1.8))
			wall(g, st, ta, u0, u1, 0, AISLE_TOP, th, aisle_ops)
			for o in aisle_ops:
				fill(g, ta, o, "two", m["glass"], trim)
				g.extrude(trim, ta, band(arch(o["cx"], 5.0, 1.2, 1.6, 0.22), arch(o["cx"], 5.0, 1.2, 1.6, 0.05)), th * 0.5, th * 0.5 + 0.14)
			g.box(trim, ta * _t(Vector3(mid, 0.4, th * 0.5 + 0.12)), Vector3(length, 0.8, 0.3))
			g.box(trim, ta * _t(Vector3(mid, 2.1, th * 0.5 + 0.08)), Vector3(length, 0.18, 0.2))
			g.box(trim, ta * _t(Vector3(mid, AISLE_TOP - 0.1, th * 0.5 + 0.1)), Vector3(length, 0.3, 0.3))
			# arcade: pointed arches between the piers
			for k in int(seg[2]):
				var b0 := u0 + BAY * k
				var p := PackedVector2Array([Vector2(b0, ARCADE_SPRING)])
				p.append_array(arch(b0 + BAY * 0.5, ARCADE_SPRING, 1.9, ARCADE_RISE))
				p.append_array([Vector2(b0 + BAY, ARCADE_SPRING), Vector2(b0 + BAY, TRIFORIUM), Vector2(b0, TRIFORIUM)])
				g.extrude(st, tn, p, -0.4, 0.4, true)
				g.extrude(trim, tn, band(arch(b0 + BAY * 0.5, ARCADE_SPRING, 1.9, ARCADE_RISE, 0.18), arch(b0 + BAY * 0.5, ARCADE_SPRING, 1.9, ARCADE_RISE)), -0.5, -0.4)
				# triforium: a blind arcade of four small arches per bay (nave side)
				for j in 4:
					var c := b0 + 0.85 + 1.1 * j
					var dp := arch(c, 9.9, 0.42, 0.5)
					dp.append(Vector2(c + 0.42, 8.85))
					dp.append(Vector2(c - 0.42, 8.85))
					gi.extrude(m["dark"], tn, dp, -0.42, -0.41)
					gi.extrude(trim, tn, band(arch(c, 9.9, 0.42, 0.5, 0.1), arch(c, 9.9, 0.42, 0.5)), -0.5, -0.4)
					for e in [-1.0, 1.0]:
						gi.box(trim, tn * _t(Vector3(c + e * 0.47, 9.375, -0.45)), Vector3(0.1, 1.05, 0.1))
			g.box(st, tn * _t(Vector3(mid, (TRIFORIUM + CLERESTORY) * 0.5, 0)), Vector3(length, CLERESTORY - TRIFORIUM, 0.8), true)
			gi.box(trim, tn * _t(Vector3(mid, TRIFORIUM + 0.1, -0.47)), Vector3(length, 0.2, 0.14))
			gi.box(trim, tn * _t(Vector3(mid, CLERESTORY + 0.05, -0.47)), Vector3(length, 0.16, 0.14))
			# clerestory
			wall(g, st, tn, u0, u1, CLERESTORY, WALL_TOP, 0.8, clere_ops)
			for o in clere_ops:
				fill(g, tn, o, "", m["glass"], trim)
				g.extrude(trim, tn, band(arch(o["cx"], 14.4, 1.0, 1.8, 0.2), arch(o["cx"], 14.4, 1.0, 1.8, 0.04)), 0.4, 0.52)
			g.box(trim, tn * _t(Vector3(mid, WALL_TOP - 0.15, 0.5)), Vector3(length, 0.3, 0.3))
		# buttress piers, pinnacles and flying buttresses at the bay divisions
		var divisions := []
		for k in range(1, NAVE_BAYS):
			divisions.append(FRONT + BAY * k)
		for k in range(1, CHOIR_BAYS):
			divisions.append(U_CROSS1 + BAY * k)
		for u in divisions:
			g.box(st, ta * _t(Vector3(u, 7.2, 1.05)), Vector3(1.0, 14.4, 1.2), true)
			g.box(st, ta * _t(Vector3(u, 1.4, 1.5)), Vector3(1.2, 2.8, 1.2), true)
			g.box(trim, ta * _t(Vector3(u, 2.85, 1.5)), Vector3(1.3, 0.15, 1.3))
			pinnacle(g, st, ta * _t(Vector3(u, 14.4, 1.05)), 0.85, 4.2)
			var tf := Transform3D(Basis(Vector3(s, 0, 0), Vector3.UP, Vector3.BACK), Vector3(0, 0, -u))
			var fp := PackedVector2Array([Vector2(NAVE_OUT, 15.8), Vector2(NAVE_OUT, 14.4)])
			for i in range(1, 9):
				var q := 1.0 - i / 8.0
				fp.append((1.0 - q) * (1.0 - q) * Vector2(AISLE_OUT, 11.0) + 2.0 * (1.0 - q) * q * Vector2(AISLE_OUT, 14.4) + q * q * Vector2(NAVE_OUT, 14.4))
			fp.append(Vector2(AISLE_OUT, 13.8))
			g.extrude(st, tf, fp, -0.3, 0.3)
			g.beam(trim, tf * Vector3(AISLE_OUT, 13.95, 0), tf * Vector3(NAVE_OUT, 15.95, 0), 0.3, 0.7, Vector3.BACK)
	# piers: clustered columns; crossing piers rise to the vault
	for s in [-1.0, 1.0]:
		for k in range(1, NAVE_BAYS):
			_pier(g, gi, m, Vector3(s * PIER_X, 0, -(FRONT + BAY * k)), 0.55, ARCADE_SPRING, s)
		for k in range(1, CHOIR_BAYS):
			_pier(g, gi, m, Vector3(s * PIER_X, 0, -(U_CROSS1 + BAY * k)), 0.55, ARCADE_SPRING, s)
		for u in [U_CROSS0, U_CROSS1]:
			_pier(g, gi, m, Vector3(s * PIER_X, 0, -u), 0.8, VAULT_SPRING, s)
		for u in [FRONT, U_EAST]:
			_pier(g, gi, m, Vector3(s * PIER_X, 0, -u), 0.45, ARCADE_SPRING, s)
		# wall shafts in the aisles, carrying the aisle vaults
		for seg in _segments():
			for k in int(seg[2]) + 1:
				var u: float = seg[0] + BAY * k
				gi.cyl(m["stone"], _t(Vector3(s * (AISLE_IN - 0.1), 0, -u)), 0.16, 0.16, AISLE_SPRING, 8)
				gi.box(trim, _t(Vector3(s * (AISLE_IN - 0.1), AISLE_SPRING - 0.1, -u)), Vector3(0.5, 0.2, 0.5))


static func _pier(g: Geo, gi: Geo, m: Dictionary, p: Vector3, r: float, top: float, s: float) -> void:
	var trim: Material = m["trim"]
	g.box(trim, _t(p + Vector3(0, 0.25, 0)), Vector3(r * 2.6, 0.5, r * 2.6), true)
	g.cyl(m["stone"], _t(p), r, r, top, 16, true)
	for d in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		gi.cyl(m["stone"], _t(p + d * r), 0.14, 0.14, top, 8)
	gi.box(trim, _t(p + Vector3(0, top - 0.15, 0)), Vector3(r * 2.7, 0.3, r * 2.7))
	if top < VAULT_SPRING:
		var q := p + Vector3(-s * (r + 0.05), 0, 0)
		gi.cyl(m["stone"], _t(q + Vector3(0, top, 0)), 0.13, 0.13, VAULT_SPRING - top, 8)
		gi.box(trim, _t(q + Vector3(0, VAULT_SPRING - 0.1, 0)), Vector3(0.45, 0.2, 0.45))


# --------------------------------------------------------------------------- transepts

static func _transepts(g: Geo, m: Dictionary) -> void:
	var st: Material = m["stone"]
	var trim: Material = m["trim"]
	var bay_w := (TRANS_IN - NAVE_IN) / 3.0
	var wc := [NAVE_IN + bay_w * 1.5, NAVE_IN + bay_w * 2.5]
	for s in [-1.0, 1.0]:
		# west and east walls of the arm
		for zc in [-(U_CROSS0 - 0.5), -(U_CROSS1 + 0.5)]:
			var out := 1.0 if zc > CROSS_Z else -1.0
			var tw := cross_frame(zc, s)
			wall(g, st, tw, NAVE_OUT, AISLE_IN, 0, WALL_TOP, 1.0, [op(7.2, 3.6, 0, AISLE_SPRING, AISLE_RISE)])
			var lower := [op(wc[0], 2.0, 3.0, 7.6, 1.8), op(wc[1], 2.0, 3.0, 7.6, 1.8)]
			var upper := [op(wc[0], 2.0, 11.6, 14.4, 1.8), op(wc[1], 2.0, 11.6, 14.4, 1.8)]
			wall(g, st, tw, AISLE_IN, TRANS_OUT, 0, 10.4, 1.0, lower)
			wall(g, st, tw, AISLE_IN, TRANS_OUT, 10.4, WALL_TOP, 1.0, upper)
			for o in lower:
				fill(g, tw, o, "two", m["glass"], trim)
			for o in upper:
				fill(g, tw, o, "", m["glass"], trim)
			g.box(trim, tw * _t(Vector3((AISLE_IN + TRANS_OUT) * 0.5, 0.4, out * 0.62)), Vector3(TRANS_OUT - AISLE_IN, 0.8, 0.3))
			g.box(trim, tw * _t(Vector3((AISLE_IN + TRANS_OUT) * 0.5, WALL_TOP - 0.15, out * 0.6)), Vector3(TRANS_OUT - AISLE_IN, 0.3, 0.3))
			g.box(trim, tw * _t(Vector3((AISLE_IN + TRANS_OUT) * 0.5, 10.4, out * 0.56)), Vector3(TRANS_OUT - AISLE_IN, 0.2, 0.2))
			# buttress between the bays, with a pinnacle
			var bx := NAVE_IN + bay_w * 2.0
			g.box(st, tw * _t(Vector3(bx, 7.0, out * 1.1)), Vector3(1.0, 14.0, 1.2), true)
			pinnacle(g, st, tw * _t(Vector3(bx, 14.0, out * 1.1)), 0.85, 4.2)
			# corner buttresses at the end wall
			g.box(st, tw * _t(Vector3(TRANS_OUT - 0.5, 6.5, out * 1.1)), Vector3(1.0, 13.0, 1.2), true)
			g.box(st, tw * _t(Vector3(TRANS_OUT + 0.6, 6.5, 0)), Vector3(1.2, 13.0, 1.0), true)
			pinnacle(g, st, tw * _t(Vector3(TRANS_OUT + 0.1, 13.0, out * 0.6)), 1.0, 5.0)
		# end wall: a tall triple lancet, a gable with a rose
		var te := axis_frame(s * (TRANS_IN + TRANS_OUT) * 0.5, s)
		var u0 := U_CROSS0 - 1.0
		var u1 := U_CROSS1 + 1.0
		var uc := -CROSS_Z
		var ops := [op(uc, 1.8, 3.0, 11.0, 1.8), op(uc - 2.3, 1.5, 3.0, 9.6, 1.5), op(uc + 2.3, 1.5, 3.0, 9.6, 1.5)]
		wall(g, st, te, u0, u1, 0, WALL_TOP, 1.0, ops)
		for o in ops:
			fill(g, te, o, "", m["glass"], trim)
			g.extrude(trim, te, band(arch(o["cx"], o["spring"], o["w"] * 0.5, o["rise"], 0.2), arch(o["cx"], o["spring"], o["w"] * 0.5, o["rise"], 0.04)), 0.5, 0.62)
		for p in gable_polys(uc, 5.6, WALL_TOP, GABLE_TOP, 20.8, 1.5):
			g.extrude(st, te, p, -0.5, 0.5)
		rose(g, te, Vector2(uc, 20.8), 1.5, m["glass"], trim)
		ring(g, trim, te, Vector2(uc, 20.8), 1.52, 1.78, 0.5, 0.62, 24)
		g.box(trim, te * _t(Vector3(uc, 0.4, 0.62)), Vector3(u1 - u0, 0.8, 0.3))
		g.box(trim, te * _t(Vector3(uc, WALL_TOP - 0.1, 0.0)), Vector3(u1 - u0, 0.3, 1.3))
		for e in [-1.0, 1.0]:
			g.beam(trim, te * Vector3(uc + e * 5.9, 17.75, 0), te * Vector3(uc, GABLE_TOP + 0.25, 0), 0.35, 1.2, te.basis.z)
		g.box(trim, te * _t(Vector3(uc, GABLE_TOP + 1.0, 0)), Vector3(0.28, 1.9, 0.28))
		g.box(trim, te * _t(Vector3(uc, GABLE_TOP + 1.35, 0)), Vector3(0.26, 0.26, 1.1))


# --------------------------------------------------------------------------- east end

static func _east_end(g: Geo, m: Dictionary) -> void:
	var st: Material = m["stone"]
	var trim: Material = m["trim"]
	var te := cross_frame(-(U_EAST + 0.5))
	var ops := [op(0, 1.8, 4.0, 13.4, 1.8), op(-2.3, 1.5, 4.0, 11.6, 1.5), op(2.3, 1.5, 4.0, 11.6, 1.5)]
	wall(g, st, te, -NAVE_OUT, NAVE_OUT, 0, WALL_TOP, 1.0, ops)
	for o in ops:
		fill(g, te, o, "", m["glass"], trim)
		g.extrude(trim, te, band(arch(o["cx"], o["spring"], o["w"] * 0.5, o["rise"], 0.2), arch(o["cx"], o["spring"], o["w"] * 0.5, o["rise"], 0.04)), -0.62, -0.5)
	for p in gable_polys(0, NAVE_OUT, WALL_TOP, GABLE_TOP, 20.8, 1.6):
		g.extrude(st, te, p, -0.5, 0.5)
	rose(g, te, Vector2(0, 20.8), 1.6, m["glass"], trim)
	g.box(trim, te * _t(Vector3(0, WALL_TOP - 0.1, 0)), Vector3(2 * NAVE_OUT, 0.3, 1.3))
	for s in [-1.0, 1.0]:
		g.beam(trim, te * Vector3(s * 5.7, 17.75, 0), te * Vector3(0, GABLE_TOP + 0.25, 0), 0.35, 1.2, Vector3.BACK)
		# aisle ends
		var o := op(s * 7.2, 1.4, 2.4, 5.6, 1.3)
		wall(g, st, te, minf(s * NAVE_OUT, s * AISLE_OUT), maxf(s * NAVE_OUT, s * AISLE_OUT), 0, AISLE_TOP, 1.0, [o])
		fill(g, te, o, "", m["glass"], trim)
		g.extrude(st, te, PackedVector2Array([Vector2(s * NAVE_OUT, AISLE_TOP), Vector2(s * AISLE_OUT, AISLE_TOP), Vector2(s * NAVE_OUT, 11.4)]), -0.5, 0.5)
		# buttresses: at the corners and either side of the great window
		g.box(st, _t(Vector3(s * NAVE_OUT, 8.0, -(U_EAST + 1.6))), Vector3(1.0, 16.0, 1.2), true)
		pinnacle(g, st, _t(Vector3(s * NAVE_OUT, 16.0, -(U_EAST + 1.6))), 0.9, 4.6)
		g.box(st, _t(Vector3(s * (AISLE_OUT - 0.5), 5.5, -(U_EAST + 1.6))), Vector3(1.0, 11.0, 1.2), true)
		g.box(st, _t(Vector3(s * (AISLE_OUT + 0.6), 5.5, -(U_EAST + 0.5))), Vector3(1.2, 11.0, 1.0), true)
		pinnacle(g, st, _t(Vector3(s * (AISLE_OUT + 0.1), 11.0, -(U_EAST + 1.1))), 0.9, 4.2)
	g.box(trim, _t(Vector3(0, 0.4, -(U_EAST + 1.12))), Vector3(2 * AISLE_OUT, 0.8, 0.3))
	g.box(trim, _t(Vector3(0, GABLE_TOP + 1.0, -(U_EAST + 0.5))), Vector3(0.28, 1.9, 0.28))
	g.box(trim, _t(Vector3(0, GABLE_TOP + 1.35, -(U_EAST + 0.5))), Vector3(1.1, 0.26, 0.26))


# --------------------------------------------------------------------------- crossing tower and spire

static func _tower(g: Geo, m: Dictionary) -> void:
	var st: Material = m["stone"]
	var trim: Material = m["trim"]
	var c := Vector3(0, 0, CROSS_Z)
	var half := 5.6
	var th := 0.9
	var h0 := 17.6
	var h1 := 33.0
	var ops := [op(-1.7, 1.5, 25.0, 29.2, 1.4), op(1.7, 1.5, 25.0, 29.2, 1.4)]
	for k in 4:
		var b := Basis(Vector3.UP, k * PI * 0.5)
		var t := Transform3D(b, c + b * Vector3(0, 0, half - th * 0.5))
		wall(g, st, t, -half, half, h0, h1, th, ops, false)
		for o in ops:
			for j in 4:
				g.box(m["wood"], t * Transform3D(Basis(Vector3.RIGHT, 0.5), Vector3(o["cx"], 25.6 + j * 0.85, -0.1)), Vector3(1.5, 0.06, 0.55))
			g.extrude(trim, t, band(arch(o["cx"], 29.2, 0.75, 1.4, 0.2), arch(o["cx"], 29.2, 0.75, 1.4, 0.04)), th * 0.5, th * 0.5 + 0.12)
		# a blind arcade band below the belfry
		for j in 5:
			var cx := -4.0 + 2.0 * j
			g.extrude(trim, t, band(arch(cx, 21.8, 0.75, 0.9, 0.12), arch(cx, 21.8, 0.75, 0.9)), th * 0.5, th * 0.5 + 0.12)
			g.extrude(m["dark"], t, arch(cx, 21.8, 0.75, 0.9) + PackedVector2Array([Vector2(cx + 0.75, 19.4), Vector2(cx - 0.75, 19.4)]), th * 0.5, th * 0.5 + 0.02)
			for e in [-1.0, 1.0]:
				g.box(trim, t * _t(Vector3(cx + e * 0.82, 20.6, th * 0.5 + 0.06)), Vector3(0.14, 2.4, 0.12))
		# parapet
		g.box(st, Transform3D(b, c + b * Vector3(0, 33.75, half - 0.18)), Vector3(2 * half, 0.9, 0.36))
	g.box(m["dark"], _t(c + Vector3(0, 28.5, 0)), Vector3(9.6, 9.0, 9.6))
	g.box(trim, _t(c + Vector3(0, 23.7, 0)), Vector3(2 * half + 0.3, 0.3, 2 * half + 0.3))
	g.box(trim, _t(c + Vector3(0, 33.15, 0)), Vector3(2 * half + 0.5, 0.35, 2 * half + 0.5))
	g.box(trim, _t(c + Vector3(0, h0 + 0.15, 0)), Vector3(2 * half + 0.3, 0.3, 2 * half + 0.3))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			pinnacle(g, st, _t(c + Vector3(sx * 5.15, 33.3, sz * 5.15)), 1.0, 5.2)
	# the spire: eight faces, bands, little gabled lucarnes, a gilded cross
	var base := 33.3
	var top := 64.0
	var r0 := 4.6
	g.cyl(st, _t(c + Vector3(0, base, 0)), r0, 0.0, top - base, 8, false, false, PI / 8.0)
	for y: float in [41.0, 49.0, 56.0]:
		var r := r0 * (1.0 - (y - base) / (top - base))
		g.cyl(trim, _t(c + Vector3(0, y, 0)), r + 0.1, r + 0.08, 0.35, 8, false, false, PI / 8.0)
	for k in 4:
		var b := Basis(Vector3.UP, k * PI * 0.5)
		var lt := Transform3D(b, c + b * Vector3(0, base, 3.9))
		g.box(st, lt * _t(Vector3(0, 1.3, 0)), Vector3(1.3, 2.6, 1.4))
		g.box(m["dark"], lt * _t(Vector3(0, 1.2, 0.71)), Vector3(0.6, 1.4, 0.02))
		g.extrude(st, lt, PackedVector2Array([Vector2(-0.75, 2.6), Vector2(0.75, 2.6), Vector2(0, 3.7)]), -0.7, 0.75)
	g.cyl(m["gold"], _t(c + Vector3(0, top - 0.2, 0)), 0.18, 0.18, 0.5, 8)
	g.box(m["gold"], _t(c + Vector3(0, top + 0.9, 0)), Vector3(0.14, 1.6, 0.14))
	g.box(m["gold"], _t(c + Vector3(0, top + 1.2, 0)), Vector3(0.8, 0.14, 0.14))


# --------------------------------------------------------------------------- roofs

static func _roofs(g: Geo, m: Dictionary) -> void:
	var roof: Material = m["roof"]
	var lead: Material = m["dark"]
	var prof := PackedVector2Array([Vector2(-5.75, 17.85), Vector2(5.75, 17.85), Vector2(0, RIDGE)])
	g.extrude(roof, Transform3D(), prof, -(U_EAST + 0.6), -0.9)
	g.box(lead, _t(Vector3(0, RIDGE + 0.05, -(U_EAST * 0.5 + 0.45))), Vector3(0.18, 0.22, U_EAST - 0.3))
	var tprof := PackedVector2Array([Vector2(-5.9, 17.85), Vector2(5.9, 17.85), Vector2(0, RIDGE)])
	var tt := Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0, 0, CROSS_Z))
	g.extrude(roof, tt, tprof, NAVE_OUT, TRANS_OUT + 0.35)
	g.extrude(roof, tt, tprof, -(TRANS_OUT + 0.35), -NAVE_OUT)
	for s in [-1.0, 1.0]:
		g.box(lead, _t(Vector3(s * (TRANS_OUT + NAVE_OUT) * 0.5, RIDGE + 0.05, CROSS_Z)), Vector3(TRANS_OUT - NAVE_OUT, 0.22, 0.18))
		var ta := Transform3D(Basis(Vector3(s, 0, 0), Vector3.UP, Vector3.BACK), Vector3.ZERO)
		var lean := PackedVector2Array([Vector2(NAVE_OUT, 11.4), Vector2(AISLE_OUT + 0.35, 8.25), Vector2(AISLE_OUT + 0.35, 8.0), Vector2(NAVE_OUT, 11.15)])
		g.extrude(roof, ta, lean, -(U_CROSS0 - 1.0), -FRONT)
		g.extrude(roof, ta, lean, -U_EAST, -(U_CROSS1 + 1.0))


# --------------------------------------------------------------------------- inside

static func _interior(gi: Geo, m: Dictionary) -> void:
	var trim: Material = m["trim"]
	var pew: Material = m["pew"]
	gi.box(m["floor"], _t(Vector3(0, 0.02, -(FRONT + U_EAST) * 0.5)), Vector3(2 * AISLE_IN, 0.04, U_EAST - FRONT))
	for s in [-1.0, 1.0]:
		gi.box(m["floor"], _t(Vector3(s * (AISLE_IN + TRANS_IN) * 0.5, 0.02, CROSS_Z)), Vector3(TRANS_IN - AISLE_IN, 0.04, U_CROSS1 - U_CROSS0))
	gi.box(m["red"], _t(Vector3(0, 0.05, -24.0)), Vector3(1.6, 0.02, 42.0))
	# pews
	for k in 15:
		var z := -5.2 - 1.5 * k
		for s in [-1.0, 1.0]:
			var x: float = s * 2.55
			gi.box(pew, _t(Vector3(x, 0.47, z)), Vector3(3.2, 0.08, 0.46), true)
			gi.box(pew, _t(Vector3(x, 0.82, z + 0.25)), Vector3(3.2, 0.62, 0.06), true)
			for e in [-1.0, 1.0]:
				gi.box(pew, _t(Vector3(x + e * 1.6, 0.5, z + 0.05)), Vector3(0.08, 1.0, 0.6))
	# choir stalls facing each other, with canopies
	for s in [-1.0, 1.0]:
		var zc := -(U_CROSS1 + 2.6)
		gi.box(pew, _t(Vector3(s * 3.3, 0.47, zc)), Vector3(0.5, 0.08, 3.8), true)
		gi.box(m["wood"], _t(Vector3(s * 3.62, 1.2, zc)), Vector3(0.08, 2.4, 3.8), true)
		gi.box(m["wood"], _t(Vector3(s * 3.35, 2.45, zc)), Vector3(0.65, 0.1, 3.9))
		for k in 5:
			gi.box(m["wood"], _t(Vector3(s * 3.3, 0.6, zc - 1.9 + 0.95 * k)), Vector3(0.5, 0.35, 0.06))
		gi.box(pew, _t(Vector3(s * 2.6, 0.75, zc)), Vector3(0.4, 0.06, 3.8), true)
		gi.box(m["wood"], _t(Vector3(s * 2.45, 0.4, zc)), Vector3(0.06, 0.8, 3.8))
	# sanctuary: a step, the altar, a carved reredos
	gi.box(trim, _t(Vector3(0, 0.08, -(U_EAST - 2.5))), Vector3(2 * NAVE_IN, 0.16, 5.0))
	var az := -(U_EAST - 1.8)
	gi.box(m["stone"], _t(Vector3(0, 0.71, az)), Vector3(3.0, 1.1, 1.1), true)
	gi.box(m["cloth"], _t(Vector3(0, 1.28, az)), Vector3(3.1, 0.04, 1.2))
	gi.box(m["red"], _t(Vector3(0, 0.78, az + 0.56)), Vector3(0.8, 1.0, 0.02))
	gi.box(trim, _t(Vector3(0, 1.9, -(U_EAST - 0.16))), Vector3(6.0, 3.8, 0.3), true)
	for j in 5:
		var cx := -2.4 + 1.2 * j
		var dp := arch(cx, 2.6, 0.42, 0.5)
		dp.append(Vector2(cx + 0.42, 0.6))
		dp.append(Vector2(cx - 0.42, 0.6))
		gi.extrude(m["dark"], cross_frame(-(U_EAST - 0.32)), dp, 0.0, 0.02)
		gi.extrude(m["gold"], cross_frame(-(U_EAST - 0.32)), band(arch(cx, 2.6, 0.42, 0.5, 0.08), arch(cx, 2.6, 0.42, 0.5)), 0.0, 0.05)
	gi.box(m["gold"], _t(Vector3(0, 2.4, az - 0.45)), Vector3(0.16, 2.0, 0.1))
	gi.box(m["gold"], _t(Vector3(0, 2.85, az - 0.45)), Vector3(1.0, 0.16, 0.1))
	# font by the door, in the south aisle
	var f := Vector3(7.2, 0, -4.4)
	gi.cyl(trim, _t(f), 0.5, 0.5, 0.15, 8, true, false)
	gi.cyl(m["stone"], _t(f + Vector3(0, 0.15, 0)), 0.22, 0.28, 0.5, 8, true, false)
	gi.cyl(m["stone"], _t(f + Vector3(0, 0.65, 0)), 0.65, 0.4, 0.4, 8, true, false)
	gi.cyl(MeshKit.mat(Color(0.25, 0.45, 0.6), 0.1, 0.2), _t(f + Vector3(0, 1.0, 0)), 0.55, 0.55, 0.02, 8)


static func _vaults(gi: Geo, m: Dictionary) -> void:
	var inner: Material = m["inner"]
	var rib: Material = m["trim"]
	var boss: Material = m["gold"]
	for seg in _segments():
		for k in int(seg[2]):
			var zc: float = -(seg[0] + BAY * (k + 0.5))
			vault(gi, inner, rib, boss, _t(Vector3(0, VAULT_SPRING, zc)), 2 * NAVE_IN, BAY, VAULT_RISE)
			for s in [-1.0, 1.0]:
				vault(gi, inner, rib, boss, _t(Vector3(s * (NAVE_OUT + AISLE_IN) * 0.5, AISLE_SPRING, zc)), AISLE_IN - NAVE_OUT, BAY, AISLE_RISE, 8)
	vault(gi, inner, rib, boss, _t(Vector3(0, VAULT_SPRING, CROSS_Z)), 2 * NAVE_IN, U_CROSS1 - U_CROSS0, VAULT_RISE)
	var bay_w := (TRANS_IN - NAVE_IN) / 3.0
	for s in [-1.0, 1.0]:
		for k in 3:
			var x: float = s * (NAVE_IN + bay_w * (k + 0.5))
			vault(gi, inner, rib, boss, Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(x, VAULT_SPRING, CROSS_Z)), U_CROSS1 - U_CROSS0, bay_w, VAULT_RISE)


## Doors, candles, chandeliers and the coloured light the windows throw on the floor.
static func _fittings(root: Node3D, m: Dictionary) -> void:
	for s in [-1.0, 1.0]:
		var d := HouseDoor.new()
		d.width = 1.9
		d.height = 4.8
		d.position = Vector3(s * -1.9, 0, -0.95)
		if s < 0:
			d.rotation.y = PI
			d.open_angle = -105.0
		root.add_child(d)
	var iron: Material = m["iron"]
	for z in [-9.1, -19.1, -29.1, CROSS_Z]:
		MeshKit.cyl(root, 0.025, 0.025, 9.5, Vector3(0, 11.6, z), iron, Vector3.ZERO, 4)
		var ring := TorusMesh.new()
		ring.inner_radius = 0.92
		ring.outer_radius = 1.0
		ring.rings = 24
		ring.ring_segments = 5
		MeshKit.inst(root, ring, Vector3(0, 6.8, z), iron)
		for i in 4:
			var a := TAU * i / 4.0
			MeshKit.box(root, Vector3(0.03, 0.03, 2.0), Vector3(cos(a) * 0.5, 6.85, z + sin(a) * 0.5), iron, Vector3(0, -rad_to_deg(a) + 90, 0))
		for i in 8:
			var a := TAU * i / 8.0
			Buildings.candle(root, Vector3(cos(a) * 0.96, 6.84, z + sin(a) * 0.96), false)
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.76, 0.48)
		l.light_energy = 2.4
		l.omni_range = 13.0
		Buildings.fade(l, 60.0)
		l.position = Vector3(0, 6.4, z)
		root.add_child(l)
	var az := -(U_EAST - 1.8)
	for x in [-1.2, -0.7, 0.7, 1.2]:
		Buildings.candle(root, Vector3(x, 1.3, az), absf(x) > 1.0)
	for x in [-2.2, 2.2]:
		MeshKit.cyl(root, 0.05, 0.12, 1.6, Vector3(x, 0.96, az + 0.3), m["gold"], Vector3.ZERO, 8)
		Buildings.candle(root, Vector3(x, 1.76, az + 0.3))
	var al := OmniLight3D.new()
	al.light_color = Color(1.0, 0.8, 0.55)
	al.light_energy = 1.6
	al.omni_range = 11.0
	Buildings.fade(al, 60.0)
	al.position = Vector3(0, 5.0, -(U_EAST - 4.0))
	root.add_child(al)
	# soft pools of coloured light under the aisle windows and in the nave (the glass, blurred)
	var small := glass_texture().get_image()
	small.clear_mipmaps()
	small.resize(12, 12, Image.INTERPOLATE_BILINEAR)
	var tex := ImageTexture.create_from_image(small)
	var spots := []
	for seg in _segments():
		for k in int(seg[2]):
			var u: float = seg[0] + BAY * (k + 0.5)
			for s in [-1.0, 1.0]:
				spots.append([Vector3(s * 6.6, 0.5, -u), Vector3(2.4, 2.0, 3.0), s * 12.0])
			spots.append([Vector3((1.0 if k % 2 == 0 else -1.0) * 2.4, 0.5, -u), Vector3(2.0, 2.0, 2.6), 0.0])
	for sp in spots:
		var dc := Decal.new()
		dc.texture_albedo = tex
		dc.texture_emission = tex
		dc.emission_energy = 0.35
		dc.modulate = Color(1, 1, 1, 0.16)
		dc.albedo_mix = 0.5
		dc.normal_fade = 0.7               # floors only, not the sides of pews and piers
		dc.upper_fade = 0.5
		dc.lower_fade = 0.5
		dc.size = Vector3(sp[1].x, 0.5, sp[1].z)
		dc.position = Vector3(sp[0].x, 0.15, sp[0].z)
		dc.rotation_degrees.y = sp[2]
		dc.distance_fade_enabled = true
		dc.distance_fade_begin = 45.0
		dc.distance_fade_length = 10.0
		root.add_child(dc)
