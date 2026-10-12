class_name Buildings
extends RefCounted
## Detailed, enterable buildings: timber-framed houses with real window openings, glass,
## shutters, a hinged door, ceilings, tiled roofs, chimneys and furnished interiors, plus the
## furniture pieces themselves. House-local space: x = width, z = depth, door on the +z side.

const T := 0.28          # wall thickness
const FLOOR := 0.12      # floor height above the ground (a small ramp leads up at the door)


static func glass() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.55, 0.65, 0.68, 0.28)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.metallic = 0.4
	m.roughness = 0.06
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


## Wall from a to b (house-local, at floor level) with openings [offset from a, width, bottom,
## top]. Walls must go clockwise seen from above (front: left to right) so local +z faces out.
## Stone up to `stone_h`, plaster above, timber framing on the outside. Returns the wall pivot.
static func wall(n: Node3D, a: Vector3, b: Vector3, height: float, openings: Array, plaster: Material,
		stone: Material, timber: Material, stone_h := 0.8, framing := true) -> Node3D:
	var d := b - a
	var length := d.length() + T
	var dir := d.normalized()
	var p := Node3D.new()
	p.position = a - dir * T * 0.5
	p.rotation.y = atan2(-dir.z, dir.x)
	n.add_child(p)
	var ops := openings.duplicate()
	ops.sort_custom(func(x, y): return x[0] < y[0])
	var kit := KitBuild.enabled()
	if kit:
		# Medieval Village MegaKit pieces for the looks; the boxes below only collide
		var kops := []
		for o in ops:
			kops.append([float(o[0]) + T * 0.5, o[1], o[2], o[3]])
		KitBuild.wall(p, length, height, kops, stone_h >= height - 0.01 or plaster == stone, framing)
		KitBuild.corner(p, height, stone_h >= height - 0.01 or plaster == stone)
	var cursor := 0.0
	var solid: Array = []        # [x0, x1] of full-height pieces, for braces
	for o in ops:
		var c: float = float(o[0]) + T * 0.5
		var x0 := c - float(o[1]) * 0.5
		var x1 := c + float(o[1]) * 0.5
		if x0 > cursor + 0.01:
			_piece(p, cursor, x0, 0.0, height, plaster, stone, stone_h, kit)
			solid.append([cursor, x0])
		if float(o[2]) > 0.01:
			_piece(p, x0, x1, 0.0, float(o[2]), plaster, stone, stone_h, kit)
		if float(o[3]) < height - 0.01:
			_piece(p, x0, x1, float(o[3]), height, plaster, stone, stone_h, kit)
		cursor = x1
	if cursor < length - 0.01:
		_piece(p, cursor, length, 0.0, height, plaster, stone, stone_h, kit)
		solid.append([cursor, length])
	if framing and not kit:
		var z := T * 0.5 + 0.035
		# sill beam, interrupted by door openings
		var cur := -0.05
		for o in ops:
			if float(o[2]) < 0.01:
				var dc: float = float(o[0]) + T * 0.5
				var d0 := dc - float(o[1]) * 0.5 - 0.13
				if d0 > cur:
					MeshKit.box(p, Vector3(d0 - cur, 0.16, 0.08), Vector3((cur + d0) * 0.5, stone_h + 0.08, z), timber)
				cur = dc + float(o[1]) * 0.5 + 0.13
		if cur < length + 0.05:
			MeshKit.box(p, Vector3(length + 0.05 - cur, 0.16, 0.08), Vector3((cur + length + 0.05) * 0.5, stone_h + 0.08, z), timber)
		MeshKit.box(p, Vector3(length + 0.1, 0.2, 0.09), Vector3(length * 0.5, height - 0.1, z), timber)
		for x in [0.06, length - 0.06]:
			MeshKit.box(p, Vector3(0.18, height, 0.1), Vector3(x, height * 0.5, z + 0.005), timber)
		for o in ops:
			var c: float = float(o[0]) + T * 0.5
			for x in [c - float(o[1]) * 0.5 - 0.07, c + float(o[1]) * 0.5 + 0.07]:
				MeshKit.box(p, Vector3(0.12, height - stone_h, 0.08), Vector3(x, (height + stone_h) * 0.5, z), timber)
		for s in solid:
			var w: float = float(s[1]) - float(s[0])
			if w > 1.3:
				var h := height - stone_h - 0.3
				var ang := rad_to_deg(atan2(h, w - 0.3))
				MeshKit.box(p, Vector3(sqrt(pow(w - 0.3, 2) + h * h), 0.12, 0.07), Vector3((float(s[0]) + float(s[1])) * 0.5, stone_h + 0.15 + h * 0.5, z), timber, Vector3(0, 0, ang if int(s[0] * 10) % 2 == 0 else -ang))
	return p


static func _piece(p: Node3D, x0: float, x1: float, y0: float, y1: float, plaster: Material, stone: Material, stone_h: float, collide_only := false) -> void:
	var w := x1 - x0
	var h := y1 - y0
	if w <= 0.01 or h <= 0.01:
		return
	MeshKit.collider_box(p, Vector3(w, h, T), Vector3(x0 + w * 0.5, y0 + h * 0.5, 0))
	if collide_only:
		return
	var sy := clampf(stone_h, y0, y1)
	if sy > y0 + 0.01:
		MeshKit.box(p, Vector3(w, sy - y0, T + 0.04), Vector3(x0 + w * 0.5, (y0 + sy) * 0.5, 0), stone)
	if y1 > sy + 0.01:
		MeshKit.box(p, Vector3(w, y1 - sy, T), Vector3(x0 + w * 0.5, (sy + y1) * 0.5, 0), plaster)


## Window in a wall pivot opening (x = centre along the wall): frame, cross mullions, glass,
## outer sill and open shutters.
static func window(p: Node3D, x: float, w: float, y0: float, y1: float, timber: Material, shutter_color: Color) -> void:
	if KitBuild.enabled():
		return      # the kit wall piece already has its window
	var h := y1 - y0
	var cy := (y0 + y1) * 0.5
	var c := x + T * 0.5
	var fz := 0.0
	for s in [-1.0, 1.0]:
		MeshKit.box(p, Vector3(0.08, h, T + 0.02), Vector3(c + s * (w * 0.5 - 0.04), cy, fz), timber)
	MeshKit.box(p, Vector3(w, 0.08, T + 0.02), Vector3(c, y1 - 0.04, fz), timber)
	MeshKit.box(p, Vector3(w, 0.08, T + 0.02), Vector3(c, y0 + 0.04, fz), timber)
	MeshKit.box(p, Vector3(0.05, h, 0.06), Vector3(c, cy, fz), timber)
	MeshKit.box(p, Vector3(w, 0.05, 0.06), Vector3(c, cy + h * 0.1, fz), timber)
	MeshKit.box(p, Vector3(w - 0.08, h - 0.08, 0.01), Vector3(c, cy, fz), glass())
	MeshKit.box(p, Vector3(w + 0.2, 0.07, 0.24), Vector3(c, y0 - 0.02, T * 0.5 + 0.08), timber)
	var sm := MeshKit.textured("Planks021", shutter_color, 1.6, 0.6, 0.85)
	for s in [-1.0, 1.0]:
		var hinge := Node3D.new()
		hinge.position = Vector3(c + s * w * 0.5, cy, T * 0.5 + 0.03)
		hinge.rotation_degrees.y = s * -100.0
		p.add_child(hinge)
		MeshKit.box(hinge, Vector3(w * 0.5, h, 0.04), Vector3(s * w * 0.25, 0, 0), sm)
		for yy in [-h * 0.3, h * 0.3]:
			MeshKit.box(hinge, Vector3(w * 0.45, 0.06, 0.02), Vector3(s * w * 0.25, yy, 0.03), sm)


## A furnished, enterable house. `size` is the footprint/height before the 1.35x scale-up that
## the old Props.house used (so level scripts keep working).
static func house(w: Node3D, pos: Vector3, yaw_deg: float, size: Vector3, roof_tint: Color, wall_color := Color(0.93, 0.89, 0.8)) -> Node3D:
	size *= 1.35
	var sx := maxf(size.x, 6.0)
	var sz := maxf(size.z, 5.0)
	var sy := clampf(size.y * 0.72, 3.2, 3.8)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(pos.x * 7.3 + pos.z * 3.1)
	var n := Props.pivot(w, pos, yaw_deg)
	w.building_areas.append([Vector2(pos.x, pos.z), sqrt(sx * sx + sz * sz) * 0.5 + 0.3])
	var plaster := MeshKit.textured("Plaster001", wall_color, 0.3, 0.0, 0.95)
	var stone := Props.stone(Color(1.0, 0.97, 0.9), 0.4)
	var timber := Props.dark_wood()
	var floor_m := MeshKit.textured("Planks021", Color(0.75, 0.55, 0.38), 0.9, 0.3, 0.85)
	var shutter := Color(0.35, 0.45, 0.32).lerp(roof_tint, 0.35)
	var hx := sx * 0.5
	var hz := sz * 0.5

	# plinth, plank floor, entrance steps
	var floor_body := MeshKit.static_box(n, Vector3(sx + T, FLOOR, sz + T), Vector3(0, FLOOR * 0.5, 0), stone)
	floor_body.set_meta("surface", "wood")
	MeshKit.box(n, Vector3(sx - T, 0.04, sz - T), Vector3(0, FLOOR + 0.0, 0), floor_m)
	# doorstep: a shallow stone ramp (walkable for the player and villagers)
	var ramp := MeshKit.static_box(n, Vector3(1.8, 0.06, 0.9), Vector3(0, FLOOR * 0.5, hz + T * 0.5 + 0.42), stone, Vector3(rad_to_deg(atan2(FLOOR, 0.9)), 0, 0))
	ramp.set_meta("surface", "stone")

	# walls with door and windows (offsets are from each wall's start corner)
	var wy0 := 1.0
	var wy1 := minf(2.3, sy - 0.5)
	var door_w := 1.2
	var door_h := 2.25
	var f := Vector3(0, FLOOR, 0)
	var front_ops := [[sx * 0.5, door_w, 0.0, door_h], [sx * 0.18, 1.0, wy0, wy1], [sx * 0.82, 1.0, wy0, wy1]]
	var back_ops := [[sx * 0.3, 1.0, wy0, wy1], [sx * 0.7, 1.0, wy0, wy1]]
	var side_ops := [[sz * 0.5, 0.9, wy0, wy1]]
	var right_ops := [[sz * 0.75, 0.9, wy0, wy1]]       # the fireplace takes the middle of the right wall
	var walls := [
		[Vector3(-hx, 0, hz), Vector3(hx, 0, hz), front_ops],
		[Vector3(hx, 0, hz), Vector3(hx, 0, -hz), right_ops],
		[Vector3(hx, 0, -hz), Vector3(-hx, 0, -hz), back_ops],
		[Vector3(-hx, 0, -hz), Vector3(-hx, 0, hz), side_ops]]
	for wd in walls:
		var wp := wall(n, wd[0] + f, wd[1] + f, sy, wd[2], plaster, stone, timber)
		for o in wd[2]:
			if float(o[2]) > 0.01:
				window(wp, float(o[0]), float(o[1]), float(o[2]), float(o[3]), timber, shutter)
	# door frame + door
	for s in [-1.0, 1.0]:
		MeshKit.box(n, Vector3(0.14, door_h + 0.1, T + 0.08), Vector3(s * (door_w * 0.5 + 0.07), FLOOR + door_h * 0.5, hz), timber)
	MeshKit.box(n, Vector3(door_w + 0.42, 0.18, T + 0.1), Vector3(0, FLOOR + door_h + 0.09, hz), timber)
	var door := HouseDoor.new()
	door.width = door_w
	door.height = door_h
	door.position = Vector3(-door_w * 0.5, FLOOR, hz - T * 0.5 + 0.06)
	n.add_child(door)
	# little canopy over the door
	var can := MeshKit.box(n, Vector3(door_w + 1.2, 0.08, 1.0), Vector3(0, FLOOR + door_h + 0.55, hz + 0.6), Props.roof(roof_tint), Vector3(16, 0, 0))
	can.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for s in [-1.0, 1.0]:
		MeshKit.box(n, Vector3(0.08, 0.08, 0.9), Vector3(s * (door_w * 0.5 + 0.45), FLOOR + door_h + 0.35, hz + 0.45), timber, Vector3(-35, 0, 0))

	# ceiling with exposed beams
	MeshKit.static_box(n, Vector3(sx, 0.1, sz), Vector3(0, FLOOR + sy + 0.05, 0), MeshKit.textured("Planks021", Color(0.55, 0.4, 0.28), 0.9, 0.3, 0.75))
	var bx := -hx + 1.2
	while bx < hx - 0.6:
		MeshKit.box(n, Vector3(0.18, 0.22, sz - T), Vector3(bx, FLOOR + sy - 0.11, 0), timber)
		bx += 1.5

	# roof: thick tiled slabs with overhang, gables, ridge, rafter tails
	var rh := sz * 0.42
	var over := 0.6
	var half := hz + over
	var slope := sqrt(half * half + rh * rh)
	var ang := rad_to_deg(atan2(rh, half))
	var roof_m := Props.roof(roof_tint)
	var top := FLOOR + sy
	var kit_roof := KitBuild.enabled()
	if kit_roof:
		KitBuild.roof(n, sx, sz, top, rh + 0.3)
	for s in [-1.0, 1.0]:
		MeshKit.collider_box(n, Vector3(sx + 1.0, 0.22, slope), Vector3(0, top + rh * 0.5 + 0.1, s * half * 0.5), Vector3(s * ang, 0, 0))
		if kit_roof:
			continue
		var slab := MeshKit.box(n, Vector3(sx + 1.0, 0.22, slope + 0.1), Vector3(0, top + rh * 0.5 + 0.1, s * half * 0.5), roof_m, Vector3(s * ang, 0, 0))
		slab.name = "Roof"
		var t := -hx - 0.4
		while t <= hx + 0.4:
			MeshKit.box(n, Vector3(0.12, 0.14, 0.7), Vector3(t, top - 0.05, s * (hz + 0.3)), timber, Vector3(s * ang, 0, 0))
			t += 0.9
		MeshKit.box(n, Vector3(sx + 1.02, 0.25, 0.08), Vector3(0, top - 0.12, s * (half - 0.02)), timber)
	if not kit_roof:
		MeshKit.box(n, Vector3(sx + 1.1, 0.22, 0.26), Vector3(0, top + rh + 0.14, 0), timber)
	for s in [-1.0, 1.0]:
		if kit_roof:
			break
		var gable := PrismMesh.new()
		gable.size = Vector3(sz + T, rh, T)
		MeshKit.inst(n, gable, Vector3(s * hx, top + rh * 0.5, 0), plaster, Vector3(0, 90, 0))
		MeshKit.box(n, Vector3(0.1, rh, 0.14), Vector3(s * (hx + T * 0.5 + 0.03), top + rh * 0.5, 0), timber)
		MeshKit.box(n, Vector3(0.1, 0.14, sz * 0.9), Vector3(s * (hx + T * 0.5 + 0.03), top + rh * 0.35, 0), timber)

	# chimney + fireplace on the right wall
	var chx := hx - 0.55
	var chz := -sz * 0.08
	var brick := Props.stone(Color(0.85, 0.55, 0.45), 0.6)
	MeshKit.static_box(n, Vector3(0.9, sy + rh + 1.0, 1.4), Vector3(chx + 0.15, FLOOR + (sy + rh + 1.0) * 0.5, chz), brick)
	MeshKit.box(n, Vector3(1.0, 0.15, 1.5), Vector3(chx + 0.15, FLOOR + sy + rh + 1.05, chz), stone)
	_fireplace(w, n, Vector3(chx - 0.45, FLOOR, chz), -90.0)
	var smoke := CPUParticles3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.3
	sm.height = 0.6
	sm.radial_segments = 6
	sm.rings = 3
	sm.material = MeshKit.glow(Color(0.3, 0.3, 0.3, 0.18))
	smoke.mesh = sm
	smoke.amount = 10
	smoke.lifetime = 5.0
	smoke.direction = Vector3.UP
	smoke.spread = 12.0
	smoke.gravity = Vector3(0.25, 0.35, 0)
	smoke.initial_velocity_min = 0.5
	smoke.initial_velocity_max = 0.9
	smoke.scale_amount_min = 0.8
	smoke.scale_amount_max = 2.5
	smoke.position = Vector3(chx + 0.15, FLOOR + sy + rh + 1.3, chz)
	n.add_child(smoke)

	# furniture
	var ix := hx - T - 0.1
	var iz := hz - T - 0.1
	bed(n, Vector3(-ix + 1.05, FLOOR, -iz + 1.1), 0.0, rng)
	table(n, Vector3(-sx * 0.12, FLOOR, sz * 0.05), rng.randf_range(-8, 8), rng)
	shelf(n, Vector3(sx * 0.15, FLOOR, -iz + 0.22), 0.0, rng)
	rug(n, Vector3(sx * 0.05, FLOOR, sz * 0.12), Vector2(2.4, 1.6), Color(0.45, 0.16, 0.12).lerp(roof_tint, 0.25))
	var bp := n.to_global(Vector3(ix - 0.45, 0, iz - 0.45))
	Props.barrel(w, Vector3(bp.x, FLOOR, bp.z))
	if rng.randf() < 0.7:
		chest_small(n, Vector3(-ix + 0.45, FLOOR, iz - 0.9), 90.0)
	hanging_lamp(n, Vector3(-sx * 0.1, FLOOR + sy - 0.25, sz * 0.05))
	# outside lantern by the door
	var lp := n.to_global(Vector3(door_w * 0.5 + 1.2, 0, hz + 1.0))
	Props.lantern(w, Vector3(lp.x, 0, lp.z))
	# somewhere for a villager to live
	w.homes.append({"door": door, "out": n.to_global(Vector3(0, 0, hz + 1.7)), "in": n.to_global(Vector3(0, FLOOR, hz - 1.4)),
		"bed": n.to_global(Vector3(-ix + 1.05, FLOOR, -iz + 1.1)), "bed_yaw": n.rotation.y,
		"table": n.to_global(Vector3(-sx * 0.12, FLOOR, sz * 0.05 + 1.3)), "taken": false})
	return n


static func _gable_pivot(n: Node3D, s: float, hx: float, y: float) -> Node3D:
	var p := Node3D.new()
	p.position = Vector3(s * hx, y, 0)
	p.rotation.y = s * PI * 0.5
	n.add_child(p)
	return p


# --------------------------------------------------------------------------- round towers

## Hollow round (optionally tapered) wall made of segments. openings: [angle (rad, 0 = +z),
## width (m), bottom, top]. `band_mats` alternate every `band_h` metres (lighthouse stripes).
## Each piece has its own collision so the inside is walkable.
static func ring_wall(n: Node3D, rb: float, rt: float, height: float, openings: Array, band_mats: Array,
		band_h := 1000.0, segs := 24, thick := 0.35) -> void:
	var taper := atan2(rb - rt, height)
	for i in segs:
		var a := TAU * (i + 0.5) / segs
		var bounds: Array = [[0.0, height]]
		for o in openings:
			var da := absf(wrapf(a - float(o[0]), -PI, PI))
			var rmid := lerpf(rb, rt, clampf((float(o[2]) + float(o[3])) * 0.5 / height, 0.0, 1.0))
			if da * rmid < float(o[1]) * 0.5:
				var nb: Array = []
				for bb in bounds:
					if float(o[2]) > bb[0]:
						nb.append([bb[0], minf(bb[1], float(o[2]))])
					if float(o[3]) < bb[1]:
						nb.append([maxf(bb[0], float(o[3])), bb[1]])
				bounds = nb
		for bb in bounds:
			var y0: float = bb[0]
			var y1: float = bb[1]
			# split at the stripe boundaries
			var y := y0
			while y < y1 - 0.01:
				var ny := minf(y1, (floorf(y / band_h + 0.001) + 1.0) * band_h)
				var band := int(floorf(y / band_h + 0.001)) % band_mats.size()
				var ym := (y + ny) * 0.5
				var r := lerpf(rb, rt, ym / height)
				var w := TAU * r / segs * 1.06
				var piece := Node3D.new()
				piece.position = Vector3(sin(a) * r, ym, cos(a) * r)
				piece.rotation = Vector3(0, a, 0)
				n.add_child(piece)
				var tilt := Node3D.new()
				tilt.rotation.x = -taper
				piece.add_child(tilt)
				MeshKit.box(tilt, Vector3(w, ny - y, thick), Vector3.ZERO, band_mats[band])
				MeshKit.collider_box(tilt, Vector3(w, ny - y, thick), Vector3.ZERO)
				y = ny


# --------------------------------------------------------------------------- barn / windmill / lighthouse

## Enterable red barn: plank walls, wide open front with swung-out doors, hay inside, a loft
## with a ramp, lantern light.
static func barn(w: Node3D, pos: Vector3, yaw_deg: float) -> void:
	var n := Props.pivot(w, pos, yaw_deg)
	var sx := 12.0
	var sz := 9.0
	var h := 5.5
	w.building_areas.append([Vector2(pos.x, pos.z), 7.6])
	var red := MeshKit.textured("WoodSiding008", Color(1.6, 0.55, 0.42), 0.8, 0.2, 0.9)
	var white := MeshKit.mat(Color(0.9, 0.88, 0.82))
	var stone := Props.stone(Color(0.95, 0.92, 0.88), 0.4)
	var hx := sx * 0.5
	var hz := sz * 0.5
	var walls := [[Vector3(-hx, 0, hz), Vector3(hx, 0, hz), [[6.0, 3.8, 0.0, 4.4]]],
		[Vector3(hx, 0, hz), Vector3(hx, 0, -hz), [[2.5, 1.0, 1.8, 2.8], [6.5, 1.0, 1.8, 2.8]]],
		[Vector3(hx, 0, -hz), Vector3(-hx, 0, -hz), [[6.0, 1.2, 0.0, 2.2]]],
		[Vector3(-hx, 0, -hz), Vector3(-hx, 0, hz), [[2.5, 1.0, 1.8, 2.8], [6.5, 1.0, 1.8, 2.8]]]]
	for wd in walls:
		wall(n, wd[0], wd[1], h, wd[2], red, stone, white, 0.5, false)
	# white trim around the big opening and swung-open doors
	for s in [-1.0, 1.0]:
		MeshKit.box(n, Vector3(0.18, 4.5, T + 0.08), Vector3(s * 1.99, 2.25, hz), white)
		var dp := Node3D.new()
		dp.position = Vector3(s * 1.9, 0, hz + 0.1)
		dp.rotation_degrees.y = s * 110.0
		n.add_child(dp)
		MeshKit.static_box(dp, Vector3(1.9, 4.3, 0.12), Vector3(-s * 0.95, 2.2, 0), red)
		MeshKit.box(dp, Vector3(1.9, 0.14, 0.04), Vector3(-s * 0.95, 2.2, 0.08), white)
		MeshKit.box(dp, Vector3(2.4, 0.14, 0.04), Vector3(-s * 0.95, 2.2, 0.08), white, Vector3(0, 0, s * 63.0))
	MeshKit.box(n, Vector3(4.2, 0.2, T + 0.08), Vector3(0, 4.5, hz), white)
	# floor, roof, gable ends
	MeshKit.box(n, Vector3(sx, 0.05, sz), Vector3(0, 0.03, 0), MeshKit.textured("Planks021", Color(0.6, 0.45, 0.3), 0.8, 0.3, 0.75))
	var rh := 4.0
	var half := hz + 0.5
	var slope := sqrt(half * half + rh * rh)
	var ang := rad_to_deg(atan2(rh, half))
	for s in [-1.0, 1.0]:
		MeshKit.box(n, Vector3(sx + 0.8, 0.2, slope), Vector3(0, h + rh * 0.5 + 0.1, s * half * 0.5), Props.roof(Color(0.5, 0.45, 0.45)), Vector3(s * ang, 0, 0))
		MeshKit.collider_box(n, Vector3(sx + 0.8, 0.2, slope), Vector3(0, h + rh * 0.5 + 0.1, s * half * 0.5), Vector3(s * ang, 0, 0))
		var gable := PrismMesh.new()
		gable.size = Vector3(sz + T, rh, T)
		MeshKit.inst(n, gable, Vector3(s * hx, h + rh * 0.5, 0), red, Vector3(0, 90, 0))
	for x in [-4.0, 0.0, 4.0]:
		MeshKit.box(n, Vector3(0.25, 0.3, sz), Vector3(x, h - 0.15, 0), Props.dark_wood())
	# loft over the back half, with a ramp up to it
	var loft_y := 2.8
	var loft := MeshKit.static_box(n, Vector3(sx - T, 0.15, 3.6), Vector3(0, loft_y, -hz + 1.9), Props.wood())
	loft.set_meta("surface", "wood")
	for x in [-4.0, 0.0, 4.0]:
		MeshKit.static_box(n, Vector3(0.22, loft_y, 0.22), Vector3(x, loft_y * 0.5, -hz + 3.6), Props.dark_wood())
	var ramp_len := sqrt(loft_y * loft_y + 4.6 * 4.6)
	var ramp := MeshKit.static_box(n, Vector3(1.2, 0.12, ramp_len), Vector3(hx - 1.0, loft_y * 0.5, -hz + 3.7 + 2.3), Props.wood(), Vector3(-rad_to_deg(atan2(loft_y, 4.6)), 0, 0))
	ramp.set_meta("surface", "wood")
	MeshKit.box(n, Vector3(sx - T, 0.9, 0.06), Vector3(0, loft_y + 0.5, -hz + 3.7), Props.dark_wood())
	# hay and clutter
	for p in [Vector3(-4.5, 0, 2.5), Vector3(-4.5, 1, 2.5), Vector3(-3.0, 0, 2.6), Vector3(-2.0, loft_y + 0.15, -3.2), Vector3(-0.3, loft_y + 0.15, -3.0), Vector3(1.4, loft_y + 0.15, -3.3)]:
		Props.hay_bale(w, n.to_global(Vector3(p.x, 0, p.z)) * Vector3(1, 0, 1) + Vector3(0, p.y, 0), randf_range(-20, 20))
	var hay := MeshKit.mat(Color(0.86, 0.72, 0.36))
	MeshKit.sphere(n, 1.6, Vector3(3.0, 0, -1.5), hay, Vector3(1.2, 0.55, 1.0))
	Buildings.hanging_lamp(n, Vector3(0, h - 0.3, 0.5))


## Ground floor of the windmill becomes a room: hollow tower, door, millstones, sacks.
static func windmill_room(w: Node3D, n: Node3D, door_angle: float) -> void:
	var st := Props.stone(Color(1.2, 1.1, 0.95))
	ring_wall(n, 3.4, 2.4, 11.0, [[door_angle, 1.3, 0.0, 2.3], [door_angle + PI * 0.5, 0.7, 4.0, 5.0], [door_angle - PI * 0.5, 0.7, 6.5, 7.5]], [st])
	MeshKit.static_cyl(n, 2.9, 0.2, Vector3(0, 3.6, 0), Props.dark_wood(), 20)
	MeshKit.static_cyl(n, 3.1, 0.3, Vector3(0, 0.0, 0), MeshKit.textured("Planks021", Color(0.6, 0.45, 0.3), 0.8, 0.3, 0.75), 24)
	var mill := Props.stone(Color(0.85, 0.85, 0.85), 0.8)
	MeshKit.static_cyl(n, 1.0, 0.35, Vector3(0, 0.6, 0), mill, 20)
	MeshKit.cyl(n, 1.0, 1.0, 0.3, Vector3(0, 0.95, 0), mill, Vector3.ZERO, 20)
	MeshKit.static_box(n, Vector3(1.8, 0.4, 1.8), Vector3(0, 0.2, 0), Props.dark_wood())
	MeshKit.cyl(n, 0.12, 0.12, 2.8, Vector3(0, 2.3, 0), Props.dark_wood(), Vector3.ZERO, 8)
	var sack := MeshKit.mat(Color(0.78, 0.68, 0.5), 0.95)
	for i in 5:
		var a := door_angle + PI + (i - 2) * 0.35
		MeshKit.sphere(n, 0.35, Vector3(sin(a) * 2.2, 0.35, cos(a) * 2.2), sack, Vector3(1, 1.25, 0.9))
	Buildings.hanging_lamp(n, Vector3(1.2, 3.3, 0.0))


## Lighthouse with a spiral stair inside, up to a balcony with a railing near the top.
## Returns the balcony height.
static func lighthouse(w: Node3D, n: Node3D) -> float:
	var white := MeshKit.mat(Color(0.95, 0.94, 0.9))
	var red := MeshKit.mat(Color(0.75, 0.12, 0.1))
	var top := 22.0
	var balcony := 19.0
	var r_at := func(y: float) -> float: return 3.5 - 1.75 * y / top
	var stair_end_angle := 0.0
	# spiral: column + steps (visual) on a smooth ramp (collision)
	var col := 0.35
	var rin := 1.4
	var rise_turn := 2.7
	var seg := 16
	var steps := int(ceilf(balcony / (rise_turn / seg)))
	var st_mat := Props.stone(Color(0.9, 0.88, 0.85), 0.6)
	MeshKit.static_cyl(n, col, balcony + 1.5, Vector3(0, (balcony + 1.5) * 0.5, 0), st_mat, 12)
	var start_a := PI * 0.5
	for k in steps:
		var y0 := k * rise_turn / seg
		var a0 := start_a + TAU * k / seg
		var a1 := a0 + TAU / seg
		var am := (a0 + a1) * 0.5
		var rm := (col + rin) * 0.5
		var arc := TAU / seg * rm
		var piece := Node3D.new()
		piece.position = Vector3(sin(am) * rm, y0 + rise_turn / seg * 0.5, cos(am) * rm)
		piece.rotation.y = am
		n.add_child(piece)
		MeshKit.box(piece, Vector3(arc * 1.25, 0.12, rin - col), Vector3(0, 0, 0), st_mat)
		var rp := MeshKit.collider_box(piece, Vector3(arc * 1.4, 0.1, rin - col), Vector3(0, -0.02, 0), Vector3(0, 0, rad_to_deg(atan2(rise_turn / seg, arc))))
		rp.set_meta("surface", "stone")
		stair_end_angle = a1
	# landing at the balcony level, balcony outside, walls with door and balcony opening
	var land := MeshKit.static_box(n, Vector3(1.6, 0.15, 1.6), Vector3(sin(stair_end_angle) * 1.0, balcony - 0.07, cos(stair_end_angle) * 1.0), st_mat)
	land.rotation.y = stair_end_angle
	var bands := [white, red]
	ring_wall(n, 3.5, 1.75, top, [[0.0, 1.3, 0.0, 2.4], [stair_end_angle, 1.1, balcony, balcony + 2.1],
		[PI * 0.25, 0.6, 5.0, 6.2], [PI * 1.25, 0.6, 10.0, 11.2], [PI * 0.75, 0.6, 15.0, 16.0]], bands, 4.4, 28, 0.3)
	MeshKit.static_cyl(n, 1.95, 0.25, Vector3(0, top + 0.12, 0), MeshKit.mat(Color(0.2, 0.2, 0.22), 0.4, 0.7), 20)
	var rb: float = r_at.call(balcony)
	var rail := MeshKit.mat(Color(0.15, 0.15, 0.17), 0.4, 0.8)
	for i in 24:
		var a := TAU * (i + 0.5) / 24.0
		var r1 := rb + 0.9
		var piece := Node3D.new()
		piece.position = Vector3(sin(a) * (rb + 0.45), balcony - 0.08, cos(a) * (rb + 0.45))
		piece.rotation.y = a
		n.add_child(piece)
		MeshKit.static_box(piece, Vector3(TAU * (rb + 0.45) / 24.0 * 1.08, 0.16, 1.1), Vector3.ZERO, Props.wood())
		var post := Node3D.new()
		post.position = Vector3(sin(a) * r1, balcony + 0.55, cos(a) * r1)
		post.rotation.y = a
		n.add_child(post)
		MeshKit.box(post, Vector3(0.05, 1.1, 0.05), Vector3.ZERO, rail)
		MeshKit.box(post, Vector3(TAU * r1 / 24.0 * 1.05, 0.06, 0.06), Vector3(0, 0.55, 0), rail)
		MeshKit.collider_box(post, Vector3(TAU * r1 / 24.0, 1.2, 0.1), Vector3.ZERO)
	# lights inside so the stair isn't pitch black
	for y in [2.5, 9.0, 15.5]:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.78, 0.5)
		l.light_energy = 1.2
		l.omni_range = 5.0
		l.position = Vector3(0, y, 0)
		n.add_child(l)
	return balcony


# --------------------------------------------------------------------------- furniture

static func _wood(tint := Color(0.7, 0.48, 0.3)) -> Material:
	return MeshKit.textured("Planks021", tint, 1.4, 0.3, 0.85)


static func table(n: Node3D, p: Vector3, yaw: float, rng: RandomNumberGenerator) -> void:
	var t := Node3D.new()
	t.position = p
	t.rotation_degrees.y = yaw
	n.add_child(t)
	if PropKit.enabled():
		PropKit.put(t, "Table_Large", Vector3.ZERO, 0.0, PropKit.fit("Table_Large", Vector3(1.8, 0.8, 0.95)), true)
		for s in [-1.0, 1.0]:
			chair(t, Vector3(rng.randf_range(-0.4, 0.4), 0, s * 0.85), 0.0 if s > 0 else 180.0)
		PropKit.table_clutter(t, Vector3(0, 0.8, 0), Vector2(0.7, 0.3), rng, 4)
		candle(t, Vector3(0.0, 0.8, 0.2))
		return
	var wd := _wood()
	MeshKit.static_box(t, Vector3(1.8, 0.08, 0.95), Vector3(0, 0.78, 0), wd)
	for x in [-0.78, 0.78]:
		for z in [-0.38, 0.38]:
			MeshKit.box(t, Vector3(0.09, 0.74, 0.09), Vector3(x, 0.37, z), wd)
	MeshKit.box(t, Vector3(1.5, 0.07, 0.05), Vector3(0, 0.2, 0), wd)
	for s in [-1.0, 1.0]:
		chair(t, Vector3(rng.randf_range(-0.4, 0.4), 0, s * 0.85), 0.0 if s > 0 else 180.0)
	# things on the table
	var clay := MeshKit.mat(Color(0.55, 0.35, 0.25), 0.8)
	MeshKit.cyl(t, 0.16, 0.1, 0.08, Vector3(-0.3, 0.86, 0.1), clay, Vector3.ZERO, 14)
	MeshKit.sphere(t, 0.12, Vector3(0.25, 0.88, -0.1), MeshKit.mat(Color(0.75, 0.52, 0.28)), Vector3(1.4, 0.6, 1))
	MeshKit.cyl(t, 0.05, 0.06, 0.18, Vector3(0.55, 0.91, 0.15), MeshKit.mat(Color(0.55, 0.42, 0.3), 0.6), Vector3.ZERO, 10)
	candle(t, Vector3(0.0, 0.82, 0.25))


static func chair(n: Node3D, p: Vector3, yaw: float) -> void:
	var c := Node3D.new()
	c.position = p
	c.rotation_degrees.y = yaw
	n.add_child(c)
	if PropKit.enabled():
		# the kit chair's back is at -z; ours faces the other way
		PropKit.put(c, "Chair_1", Vector3.ZERO, 180.0, Vector3.ONE * 0.95)
		MeshKit.collider_box(c, Vector3(0.45, 0.5, 0.45), Vector3(0, 0.25, 0))
		return
	var wd := _wood(Color(0.62, 0.42, 0.27))
	MeshKit.box(c, Vector3(0.45, 0.05, 0.45), Vector3(0, 0.46, 0), wd)
	for x in [-0.19, 0.19]:
		for z in [-0.19, 0.19]:
			MeshKit.box(c, Vector3(0.05, 0.46, 0.05), Vector3(x, 0.23, z), wd)
		MeshKit.box(c, Vector3(0.05, 0.5, 0.05), Vector3(x, 0.72, 0.2), wd)
	for y in [0.62, 0.86]:
		MeshKit.box(c, Vector3(0.43, 0.06, 0.03), Vector3(0, y, 0.2), wd)
	MeshKit.collider_box(c, Vector3(0.45, 0.5, 0.45), Vector3(0, 0.25, 0))


static func bed(n: Node3D, p: Vector3, yaw: float, rng: RandomNumberGenerator) -> void:
	var b := Node3D.new()
	b.position = p
	b.rotation_degrees.y = yaw
	n.add_child(b)
	if PropKit.enabled():
		var bed_name := "Bed_Twin1" if rng.randf() < 0.5 else "Bed_Twin2"
		PropKit.put(b, bed_name, Vector3.ZERO, 0.0, PropKit.fit(bed_name, Vector3(1.15, 0.8, 2.05)))
		MeshKit.collider_box(b, Vector3(1.1, 0.5, 2.0), Vector3(0, 0.25, 0))
		return
	var wd := _wood(Color(0.55, 0.37, 0.24))
	MeshKit.static_box(b, Vector3(1.1, 0.35, 2.0), Vector3(0, 0.25, 0), wd)
	MeshKit.box(b, Vector3(1.15, 0.9, 0.08), Vector3(0, 0.45, -1.0), wd)
	MeshKit.box(b, Vector3(1.15, 0.55, 0.08), Vector3(0, 0.28, 1.0), wd)
	MeshKit.box(b, Vector3(1.0, 0.16, 1.9), Vector3(0, 0.5, 0.0), MeshKit.mat(Color(0.85, 0.82, 0.72), 0.95))
	var blanket := Color(rng.randf_range(0.3, 0.6), rng.randf_range(0.15, 0.3), rng.randf_range(0.1, 0.25))
	MeshKit.box(b, Vector3(1.06, 0.08, 1.2), Vector3(0, 0.6, 0.35), MeshKit.mat(blanket, 0.95), Vector3(-2, 0, 0))
	MeshKit.box(b, Vector3(1.06, 0.3, 0.04), Vector3(0, 0.47, 0.96), MeshKit.mat(blanket, 0.95))
	MeshKit.sphere(b, 0.22, Vector3(0, 0.66, -0.72), MeshKit.mat(Color(0.92, 0.9, 0.84), 0.95), Vector3(1.9, 0.5, 1.0))


static func shelf(n: Node3D, p: Vector3, yaw: float, rng: RandomNumberGenerator) -> void:
	var s := Node3D.new()
	s.position = p
	s.rotation_degrees.y = yaw
	n.add_child(s)
	MeshKit.collider_box(s, Vector3(1.6, 2.0, 0.4), Vector3(0, 1.0, 0))
	if PropKit.enabled():
		var bs := PropKit.fit("Bookcase_2", Vector3(1.6, 2.1, 0.42))
		PropKit.put(s, "Bookcase_2", Vector3(0, 0, 0.0), 0.0, bs)
		# books and jars on the shelves (shelf board heights of the kit bookcase, scaled)
		for y0 in [0.73, 1.15, 1.55, 1.9]:
			var y: float = y0 * bs.y
			var x := -0.55
			while x < 0.55:
				var pick := rng.randi() % 5
				if pick < 2:
					PropKit.put(s, ["BookGroup_Small_1", "BookGroup_Small_2", "BookGroup_Small_3"][rng.randi() % 3], Vector3(x + 0.12, y, 0.0), 0.0, Vector3.ONE, false, false)
					x += 0.3
				elif pick == 2:
					PropKit.put(s, ["Potion_2", "Vase_4", "Bottle_1", "Book_Stack_1"][rng.randi() % 4], Vector3(x + 0.1, y, 0.0), rng.randf() * 360.0, Vector3.ONE * 0.8, false, false)
					x += 0.25
				else:
					x += 0.18
		return
	var wd := _wood(Color(0.58, 0.4, 0.26))
	for x in [-0.78, 0.78]:
		MeshKit.box(s, Vector3(0.05, 2.0, 0.4), Vector3(x, 1.0, 0), wd)
	MeshKit.box(s, Vector3(1.6, 2.0, 0.03), Vector3(0, 1.0, -0.19), wd)
	for i in 4:
		var y := 0.15 + i * 0.55
		MeshKit.box(s, Vector3(1.55, 0.04, 0.38), Vector3(0, y, 0), wd)
		var x := -0.65
		while x < 0.65:
			var kind := rng.randi() % 3
			if kind == 0:
				var bw := rng.randf_range(0.04, 0.07)
				var bh := rng.randf_range(0.2, 0.3)
				MeshKit.box(s, Vector3(bw, bh, 0.2), Vector3(x, y + 0.02 + bh * 0.5, 0.02), MeshKit.mat(Color(rng.randf_range(0.2, 0.6), rng.randf_range(0.1, 0.35), rng.randf_range(0.08, 0.3)), 0.8), Vector3(0, 0, rng.randf_range(-4, 4)))
				x += bw + 0.01
			elif kind == 1:
				var r := rng.randf_range(0.05, 0.08)
				MeshKit.cyl(s, r * 0.7, r, r * 2.6, Vector3(x + r, y + 0.02 + r * 1.3, 0.02), MeshKit.mat(Color(0.6, 0.45, 0.32).darkened(rng.randf() * 0.4), 0.7), Vector3.ZERO, 10)
				x += r * 2.2
			else:
				x += 0.12


static func rug(n: Node3D, p: Vector3, size: Vector2, color: Color) -> void:
	MeshKit.box(n, Vector3(size.x, 0.015, size.y), p + Vector3(0, 0.03, 0), MeshKit.mat(color, 1.0))
	MeshKit.box(n, Vector3(size.x * 0.82, 0.018, size.y * 0.75), p + Vector3(0, 0.032, 0), MeshKit.mat(color.lightened(0.25), 1.0))


static func candle(n: Node3D, p: Vector3, light := true) -> void:
	MeshKit.cyl(n, 0.035, 0.04, 0.02, p, MeshKit.mat(Color(0.4, 0.3, 0.2), 0.5, 0.6), Vector3.ZERO, 10)
	MeshKit.cyl(n, 0.022, 0.022, 0.12, p + Vector3(0, 0.07, 0), MeshKit.mat(Color(0.95, 0.92, 0.82)), Vector3.ZERO, 8)
	MeshKit.sphere(n, 0.014, p + Vector3(0, 0.15, 0), MeshKit.unshaded(Color(1.0, 0.8, 0.35)), Vector3(1, 1.8, 1))
	if not light:
		return
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.72, 0.4)
	l.light_energy = 0.6
	l.omni_range = 2.5
	l.position = p + Vector3(0, 0.2, 0)
	fade(l, 25.0)
	n.add_child(l)


static func hanging_lamp(n: Node3D, p: Vector3) -> void:
	var iron := MeshKit.mat(Color(0.15, 0.14, 0.13), 0.5, 0.8)
	MeshKit.cyl(n, 0.01, 0.01, 0.5, p + Vector3(0, 0.0, 0), iron, Vector3.ZERO, 4)
	MeshKit.cyl(n, 0.12, 0.16, 0.25, p + Vector3(0, -0.35, 0), MeshKit.mat(Color(1.0, 0.82, 0.5), 0.5, 0.0, 1.6), Vector3.ZERO, 8)
	MeshKit.cyl(n, 0.0, 0.17, 0.12, p + Vector3(0, -0.17, 0), iron, Vector3.ZERO, 8)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.75, 0.45)
	l.light_energy = 1.6
	l.omni_range = 7.0
	l.position = p + Vector3(0, -0.45, 0)
	fade(l, 45.0)
	n.add_child(l)


static func chest_small(n: Node3D, p: Vector3, yaw: float) -> void:
	var c := Node3D.new()
	c.position = p
	c.rotation_degrees.y = yaw
	n.add_child(c)
	if PropKit.enabled():
		PropKit.put(c, "Chest_Wood", Vector3.ZERO, 0.0, PropKit.fit("Chest_Wood", Vector3(0.9, 0.52, 0.5)), true)
		return
	var wd := _wood(Color(0.5, 0.33, 0.2))
	var iron := MeshKit.mat(Color(0.16, 0.15, 0.15), 0.5, 0.85)
	MeshKit.static_box(c, Vector3(0.9, 0.5, 0.5), Vector3(0, 0.25, 0), wd)
	MeshKit.box(c, Vector3(0.92, 0.06, 0.52), Vector3(0, 0.5, 0), wd)
	for x in [-0.3, 0.3]:
		MeshKit.box(c, Vector3(0.05, 0.52, 0.52), Vector3(x, 0.26, 0), iron)


## Stone fireplace against a wall: hearth, firebox, mantel, burning logs, flickering light.
static func _fireplace(w: Node3D, n: Node3D, p: Vector3, yaw: float) -> void:
	var f := Node3D.new()
	f.position = p
	f.rotation_degrees.y = yaw
	n.add_child(f)
	var st := Props.stone(Color(0.9, 0.86, 0.8), 0.7)
	MeshKit.static_box(f, Vector3(1.8, 0.12, 0.8), Vector3(0, 0.06, 0.25), st)
	for s in [-1.0, 1.0]:
		MeshKit.static_box(f, Vector3(0.35, 1.2, 0.55), Vector3(s * 0.62, 0.6, 0), st)
	MeshKit.box(f, Vector3(1.6, 0.4, 0.6), Vector3(0, 1.35, 0), st)
	MeshKit.box(f, Vector3(1.9, 0.1, 0.7), Vector3(0, 1.6, 0.02), Props.dark_wood())
	MeshKit.box(f, Vector3(0.9, 1.0, 0.1), Vector3(0, 0.6, -0.25), MeshKit.mat(Color(0.05, 0.04, 0.04)))
	var wd := Props.dark_wood()
	MeshKit.cyl(f, 0.07, 0.07, 0.7, Vector3(0, 0.2, 0), wd, Vector3(0, 0, 90), 7)
	MeshKit.cyl(f, 0.07, 0.07, 0.7, Vector3(0, 0.3, -0.05), wd, Vector3(0, 30, 90), 7)
	MeshKit.cyl(f, 0.0, 0.25, 0.55, Vector3(0, 0.55, -0.05), MeshKit.unshaded(Color(1.0, 0.45, 0.1)), Vector3.ZERO, 7)
	MeshKit.cyl(f, 0.0, 0.14, 0.4, Vector3(0, 0.48, 0.0), MeshKit.unshaded(Color(1.0, 0.85, 0.35)), Vector3.ZERO, 7)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.55, 0.22)
	l.omni_range = 6.0
	l.position = Vector3(0, 0.6, 0.5)
	fade(l, 45.0)
	f.add_child(l)
	w.fire_lights.append(l)
	for i in 3:
		MeshKit.cyl(f, 0.04, 0.05, 0.18, Vector3(-0.5 + i * 0.5, 1.74, 0.0), MeshKit.mat(Color(0.5, 0.35, 0.25), 0.6), Vector3.ZERO, 8)


## Lights switch off smoothly beyond `dist` metres (cheap culling for interior lights).
static func fade(l: Light3D, dist: float) -> void:
	l.distance_fade_enabled = true
	l.distance_fade_begin = dist
	l.distance_fade_length = 10.0