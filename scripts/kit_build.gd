class_name KitBuild
extends RefCounted
## Building visuals from the Medieval Village MegaKit (Quaternius, CC0). Walls are rows of 2 m
## kit pieces: a door or window cell is centred exactly on each opening (so HouseDoor and the
## colliders line up), plain / timber-framed cells fill the rest, a trimmed strip tops up walls
## taller than one 3.12 m storey. Roofs are kit round-tile roofs scaled to the footprint, with gable
## fronts. Collision stays with Buildings (boxes around the openings).

const DIR := "res://assets/models/village_kit/"
const CELL := 2.0
const ROW := 3.12
const Z_CENTER := -0.105          # kit walls span z -0.31 .. 0.10

static var _parts := {}


static func enabled() -> bool:
	return ResourceLoader.exists(DIR + "Wall_Plaster_Straight.gltf")


## [[mesh, transform], ...] of a kit model.
static func parts(name: String) -> Array:
	var key := name
	if window_variant != "" and name.begins_with("Window_"):
		key = name + "#" + window_variant
	if _parts.has(key):
		return _parts[key]
	var out := []
	var path := DIR + name + ".gltf"
	if ResourceLoader.exists(path):
		var root: Node = (load(path) as PackedScene).instantiate()
		_collect(root, Transform3D(), out)
		root.free()
	# window glass: textured panes (Glass); a variant gets its own copy of the mesh
	if Glass.enabled():
		for p in out:
			var m: Mesh = p[0]
			for s in m.get_surface_count():
				var mt := m.surface_get_material(s)
				if mt and String(mt.resource_name) == "MI_WindowGlass" or (mt and String(mt.resource_name).begins_with("Glass_")):
					if key != name:
						m = m.duplicate()
						p[0] = m
					m.surface_set_material(s, Glass.stained() if window_variant == "stained" else Glass.window())
	_parts[key] = out
	return out


## "stained" while building the castle and temple: their windows get coloured glass.
static var window_variant := ""


static func _collect(n: Node, xf: Transform3D, out: Array) -> void:
	var t := xf
	if n is Node3D and n.get_parent() != null:
		t = xf * (n as Node3D).transform
	if n is MeshInstance3D:
		out.append([(n as MeshInstance3D).mesh, t])
	for c in n.get_children():
		_collect(c, t, out)


static func aabb(name: String) -> AABB:
	var box := AABB()
	var first := true
	for p in parts(name):
		var a: AABB = (p[1] as Transform3D) * (p[0] as Mesh).get_aabb()
		box = a if first else box.merge(a)
		first = false
	return box


## Places a kit model under `parent` with transform `t`.
static func put(parent: Node3D, name: String, t: Transform3D) -> void:
	for p in parts(name):
		var mi := MeshInstance3D.new()
		mi.mesh = p[0]
		mi.transform = t * (p[1] as Transform3D)
		# every kit file carries its own copy of the shared materials: use one per name so the
		# batcher can merge pieces from different files
		for i in mi.mesh.get_surface_count():
			var m: Material = mi.mesh.surface_get_material(i)
			if m:
				var key := String(m.resource_name)
				if not _mats.has(key):
					_mats[key] = m
				mi.set_surface_override_material(i, _mats[key])
		parent.add_child(mi)


static var _mats := {}


## Kit wall visuals along a wall pivot (local x 0..length, +z outside, floor at y 0).
## openings: [offset, width, bottom, top]. brick: uneven brick instead of plaster.
static func wall(p: Node3D, length: float, height: float, openings: Array, brick: bool, framed: bool) -> void:
	var rows := maxi(1, int(floor(height / ROW + 0.25)))
	var row_h := minf(ROW, height / rows) if height < ROW else ROW
	for r in rows:
		var y0 := r * ROW
		if y0 >= height - 0.05:
			break
		var fixed := []
		for o in openings:
			var bottom: float = o[2]
			if bottom >= y0 - 0.2 and bottom < y0 + ROW - 0.5:
				var kind := "door" if bottom < 0.1 else ("wide" if float(o[1]) >= 0.95 else "thin")
				if kind == "door" and float(o[1]) > 1.6:
					kind = "arch"
				fixed.append([float(o[0]), kind, maxf(CELL, float(o[1]) + 0.5), float(o[3]) - y0])
		fixed.sort_custom(func(a, b): return a[0] < b[0])
		# drop cells that would overlap a previous one
		var cells := []
		var last := -INF
		for f in fixed:
			var hw: float = float(f[2]) * 0.5
			if f[0] - hw >= last - 0.05 and f[0] - hw > -0.3 and f[0] + hw < length + 0.3:
				cells.append(f)
				last = f[0] + hw
		# fill the spans between fixed cells with plain cells (scaled to fit)
		var cursor := 0.0
		var all := []
		for c in cells:
			var hw: float = float(c[2]) * 0.5
			_fill(all, cursor, c[0] - hw)
			all.append([c[0], c[2], c[1], c[3]])
			cursor = c[0] + hw
		_fill(all, cursor, length)
		var hs := 1.0 if row_h >= ROW - 0.01 else row_h / ROW
		var top_left := height - y0
		if r == rows - 1 and top_left > ROW + 0.05:
			hs = 1.0
		for i in all.size():
			var cell: Array = all[i]
			if cell[2] == "arch":
				# a wide entrance: an arched frame the size of the opening, wall above it
				var oh := minf(float(cell[3]), ROW * hs)
				var fr := aabb("DoorFrame_Round_Brick")
				put(p, "DoorFrame_Round_Brick", Transform3D(Basis.from_scale(Vector3((float(cell[1]) - 0.3) / fr.size.x, oh / fr.size.y, 1.0)), Vector3(float(cell[0]), y0, -Z_CENTER)))
				if oh < ROW * hs - 0.1:
					put(p, "Wall_UnevenBrick_Straight" if brick else "Wall_Plaster_Straight", Transform3D(Basis.from_scale(Vector3(float(cell[1]) / CELL, (ROW * hs - oh) / ROW, 1.0)), Vector3(float(cell[0]), y0 + oh, -Z_CENTER)))
				continue
			var name := _piece_name(cell[2], brick, framed, i)
			var sx: float = float(cell[1]) / CELL
			put(p, name, Transform3D(Basis.from_scale(Vector3(sx, hs, 1.0)), Vector3(float(cell[0]), y0, -Z_CENTER)))
			if cell[2] == "wide" or cell[2] == "thin":
				put(p, "Window_Wide_Round1" if cell[2] == "wide" else "Window_Thin_Round1", Transform3D(Basis(), Vector3(float(cell[0]), y0, -Z_CENTER)))
		# a strip tops up what's left above the last full storey
		if r == rows - 1 and top_left > ROW + 0.05:
			var extra := top_left - ROW
			var plain := []
			_fill(plain, 0.0, length)
			for c in plain:
				put(p, "Wall_UnevenBrick_Straight" if brick else "Wall_Plaster_Straight", Transform3D(Basis.from_scale(Vector3(float(c[1]) / CELL, extra / ROW, 1.0)), Vector3(float(c[0]), y0 + ROW, -Z_CENTER)))


static func _fill(out: Array, from: float, to: float) -> void:
	var span := to - from
	if span < 0.15:
		return
	var n := maxi(1, int(round(span / CELL)))
	var w := span / n
	for i in n:
		out.append([from + w * (i + 0.5), w, "plain"])


static func _piece_name(kind: String, brick: bool, framed: bool, i: int) -> String:
	var mat := "UnevenBrick" if brick else "Plaster"
	match kind:
		"door":
			return "Wall_%s_Door_Round" % mat
		"wide":
			return "Wall_%s_Window_Wide_Round" % mat
		"thin":
			return "Wall_%s_Window_Thin_Round" % mat
	return "Wall_%s_Straight" % mat


## Corner post at a wall pivot's start (covers the joint between two walls).
static func corner(p: Node3D, height: float, brick: bool) -> void:
	var name := "Corner_Exterior_Brick" if brick else "Corner_Exterior_Wood"
	var h := aabb(name).size.y
	put(p, name, Transform3D(Basis.from_scale(Vector3(1, height / maxf(h, 0.1), 1)), Vector3(0, 0, 0.1)))


## Gabled round-tile roof over a sx x sz footprint (ridge along x), eaves at `top`, rising `rise`.
static func roof(n: Node3D, sx: float, sz: float, top: float, rise: float) -> void:
	var options := ["Roof_RoundTiles_4x4", "Roof_RoundTiles_4x6", "Roof_RoundTiles_4x8", "Roof_RoundTiles_6x6", "Roof_RoundTiles_6x8",
		"Roof_RoundTiles_6x10", "Roof_RoundTiles_6x12", "Roof_RoundTiles_8x8", "Roof_RoundTiles_8x10", "Roof_RoundTiles_8x12", "Roof_RoundTiles_8x14"]
	# the kit roofs have their ridge along z: rotate so it runs along x
	var want := Vector2(sz + 1.2, sx + 1.2)
	var best: String = options[0]
	var bd := INF
	for o in options:
		var a := aabb(o)
		var d := absf(a.size.x - want.x) + absf(a.size.z - want.y)
		if d < bd:
			bd = d
			best = o
	var a := aabb(best)
	var sc := Vector3(want.x / a.size.x, rise / maxf(a.size.y + a.position.y, 0.5), want.y / a.size.z)
	var center := a.get_center()
	var t := Transform3D(Basis(Vector3.UP, PI * 0.5) * Basis.from_scale(sc), Vector3(0, top, 0))
	t.origin += t.basis * Vector3(-center.x, 0, -center.z)
	put(n, best, t)
	# gable fronts
	var gname := "Roof_Front_Brick6"
	var g := aabb(gname)
	for s in [-1.0, 1.0]:
		var gt := Transform3D(Basis(Vector3.UP, s * PI * 0.5) * Basis.from_scale(Vector3(sz / g.size.x, rise / g.size.y, 1.0)), Vector3(s * sx * 0.5, top, 0))
		put(n, gname, gt)


## The visual of a house door (hinge at x = 0, slab along +x).
static func door(parent: Node3D, width: float, height: float) -> bool:
	if not enabled():
		return false
	put(parent, "Door_1_Round", Transform3D(Basis.from_scale(Vector3(width / 1.12, height / 2.32, 1.0)), Vector3(0.0, 0.0, 0.0)))
	return true
