class_name VBuild
extends RefCounted
## Village buildings and detailed props. Every builder takes the world, a position (y = height
## above the ground) and a yaw in degrees (door / front faces local +z) and returns a Dictionary
## with useful spots: "work" ([pos, yaw, anim]), "social" (positions), "trader", "stash"...

const T := Buildings.T
const F := Buildings.FLOOR


static func _plaster(c := Color(0.93, 0.89, 0.8)) -> Material:
	return MeshKit.textured("Plaster001", c, 0.3, 0.0, 0.95)


static func _stone(c := Color(1.0, 0.97, 0.9)) -> Material:
	return Props.stone(c, 0.4)


static func _g(n: Node3D, local: Vector3) -> Vector3:
	return n.to_global(local)


## Enterable rectangular shell: floor, walls with openings, door at the front centre, ceiling
## and a gabled roof. ops: {"front", "right", "back", "left"} -> openings (see Buildings.wall).
static func shell(w: Node3D, n: Node3D, sx: float, sz: float, h: float, ops: Dictionary, wall_m: Material, roof_tint: Color,
		ceiling := true, door := true, framing := false) -> Dictionary:
	var hx := sx * 0.5
	var hz := sz * 0.5
	var stone := _stone()
	var timber := Props.dark_wood()
	var fl := MeshKit.static_box(n, Vector3(sx + T, F, sz + T), Vector3(0, F * 0.5, 0), stone)
	fl.set_meta("surface", "wood")
	MeshKit.box(n, Vector3(sx - T, 0.03, sz - T), Vector3(0, F, 0), MeshKit.textured("Planks021", Color(0.72, 0.52, 0.36), 0.9, 0.3, 0.85))
	var f := Vector3(0, F, 0)
	var front: Array = ops.get("front", [])
	if door:
		front = front + [[sx * 0.5, 1.3, 0.0, 2.3]]
	var walls := [[Vector3(-hx, 0, hz), Vector3(hx, 0, hz), front], [Vector3(hx, 0, hz), Vector3(hx, 0, -hz), ops.get("right", [])],
		[Vector3(hx, 0, -hz), Vector3(-hx, 0, -hz), ops.get("back", [])], [Vector3(-hx, 0, -hz), Vector3(-hx, 0, hz), ops.get("left", [])]]
	for wd in walls:
		var wp := Buildings.wall(n, wd[0] + f, wd[1] + f, h, wd[2], wall_m, stone, timber, 0.8, framing)
		for o in wd[2]:
			if float(o[2]) > 0.01:
				Buildings.window(wp, float(o[0]), float(o[1]), float(o[2]), float(o[3]), timber, Color(0.3, 0.38, 0.3))
	var result := {"hx": hx, "hz": hz}
	if door:
		for s in [-1.0, 1.0]:
			MeshKit.box(n, Vector3(0.14, 2.4, T + 0.08), Vector3(s * 0.72, F + 1.2, hz), timber)
		MeshKit.box(n, Vector3(1.75, 0.18, T + 0.1), Vector3(0, F + 2.38, hz), timber)
		var d := HouseDoor.new()
		d.width = 1.3
		d.height = 2.3
		d.position = Vector3(-0.65, F, hz - T * 0.5 + 0.06)
		n.add_child(d)
		result["door"] = d
		var ramp := MeshKit.static_box(n, Vector3(1.8, 0.06, 0.9), Vector3(0, F * 0.5, hz + T * 0.5 + 0.42), stone, Vector3(rad_to_deg(atan2(F, 0.9)), 0, 0))
		ramp.set_meta("surface", "stone")
	if ceiling:
		MeshKit.static_box(n, Vector3(sx, 0.1, sz), Vector3(0, F + h + 0.05, 0), MeshKit.textured("Planks021", Color(0.55, 0.4, 0.28), 0.9, 0.3, 0.75))
		var bx := -hx + 1.2
		while bx < hx - 0.6:
			MeshKit.box(n, Vector3(0.18, 0.22, sz - T), Vector3(bx, F + h - 0.11, 0), timber)
			bx += 1.6
	_gable_roof(n, sx, sz, F + h, roof_tint, wall_m)
	return result


static func _gable_roof(n: Node3D, sx: float, sz: float, top: float, roof_tint: Color, gable_m: Material) -> void:
	var hx := sx * 0.5
	var hz := sz * 0.5
	var rh := sz * 0.4
	var half := hz + 0.6
	var slope := sqrt(half * half + rh * rh)
	var ang := rad_to_deg(atan2(rh, half))
	var roof_m := Props.roof(roof_tint)
	var timber := Props.dark_wood()
	if KitBuild.enabled():
		KitBuild.roof(n, sx, sz, top, rh + 0.3)
		for s in [-1.0, 1.0]:
			MeshKit.collider_box(n, Vector3(sx + 1.0, 0.22, slope), Vector3(0, top + rh * 0.5 + 0.1, s * half * 0.5), Vector3(s * ang, 0, 0))
		return
	for s in [-1.0, 1.0]:
		MeshKit.box(n, Vector3(sx + 1.0, 0.22, slope + 0.1), Vector3(0, top + rh * 0.5 + 0.1, s * half * 0.5), roof_m, Vector3(s * ang, 0, 0))
		MeshKit.collider_box(n, Vector3(sx + 1.0, 0.22, slope), Vector3(0, top + rh * 0.5 + 0.1, s * half * 0.5), Vector3(s * ang, 0, 0))
		MeshKit.box(n, Vector3(sx + 1.02, 0.25, 0.08), Vector3(0, top - 0.12, s * (half - 0.02)), timber)
		var gable := PrismMesh.new()
		gable.size = Vector3(sz + T, rh, T)
		MeshKit.inst(n, gable, Vector3(s * hx, top + rh * 0.5, 0), gable_m, Vector3(0, 90, 0))
	MeshKit.box(n, Vector3(sx + 1.1, 0.22, 0.26), Vector3(0, top + rh + 0.14, 0), timber)


static func _sign(n: Node3D, local: Vector3, text: String, color: Color) -> void:
	var timber := Props.dark_wood()
	MeshKit.box(n, Vector3(0.9, 0.06, 0.06), local + Vector3(0.45, 0.3, 0), timber)
	MeshKit.box(n, Vector3(0.7, 0.45, 0.05), local + Vector3(0.55, 0.0, 0), Props.wood())
	var l := Label3D.new()
	l.text = text
	l.font_size = 48
	l.pixel_size = 0.004
	l.modulate = color
	l.outline_size = 6
	l.position = local + Vector3(0.55, 0.0, 0.035)
	n.add_child(l)
	var l2 := l.duplicate() as Label3D
	l2.position = local + Vector3(0.55, 0.0, -0.035)
	l2.rotation_degrees.y = 180.0
	n.add_child(l2)


# --------------------------------------------------------------------------- tavern

## Two-storey inn: bar, kegs, tables and benches, fireplace, a stair to the rooms upstairs.
static func tavern(w: Node3D, p: Vector3, yaw: float) -> Dictionary:
	var n := Props.pivot(w, p, yaw)
	var sx := 13.0
	var sz := 9.0
	var h := 6.6
	var lw := [1.0, 2.3]
	var up := [4.4, 5.6]
	# openings in one wall must not overlap horizontally (lower and upper windows alternate)
	var ops := {"front": [[2.2, 1.1, lw[0], lw[1]], [10.8, 1.1, lw[0], lw[1]], [4.3, 1.0, up[0], up[1]], [8.7, 1.0, up[0], up[1]]],
		"back": [[3.0, 1.0, lw[0], lw[1]], [10.0, 1.0, up[0], up[1]], [4.5, 1.0, up[0], up[1]]],
		"left": [[2.0, 1.0, lw[0], lw[1]], [7.5, 1.0, up[0], up[1]]], "right": [[2.0, 1.0, up[0], up[1]]]}
	var r := shell(w, n, sx, sz, h, ops, _plaster(Color(0.95, 0.88, 0.74)), Color(0.7, 0.35, 0.25), true, true, true)
	var hx: float = r["hx"]
	var hz: float = r["hz"]
	# upper floor with a stairwell along the right wall
	var y2 := F + 3.3
	var wood := Props.wood()
	var floor2 := MeshKit.static_box(n, Vector3(sx - 1.7, 0.18, sz), Vector3(-0.85, y2 - 0.09, 0), MeshKit.textured("Planks021", Color(0.7, 0.5, 0.34), 0.9, 0.3, 0.85))
	floor2.set_meta("surface", "wood")
	var landing := MeshKit.static_box(n, Vector3(1.7, 0.18, 2.2), Vector3(hx - 0.85, y2 - 0.09, -hz + 1.1), wood)
	landing.set_meta("surface", "wood")
	var run := sz - 3.0
	var ang := rad_to_deg(atan2(3.3 - F, run))
	var ramp := MeshKit.collider_box(n, Vector3(1.3, 0.1, sqrt(run * run + 3.3 * 3.3)), Vector3(hx - 0.85, F + (3.3 - F) * 0.5, -hz + 2.2 + run * 0.5), Vector3(ang, 0, 0))
	ramp.set_meta("surface", "wood")
	for i in 14:
		var t := (i + 0.5) / 14.0
		MeshKit.box(n, Vector3(1.3, 0.08, run / 14.0 + 0.02), Vector3(hx - 0.85, F + (3.3 - F) * (1.0 - t), -hz + 2.2 + run * t), wood)
	MeshKit.box(n, Vector3(0.08, 1.0, run), Vector3(hx - 1.55, F + 2.2, -hz + 2.2 + run * 0.5), Props.dark_wood(), Vector3(ang, 0, 0))
	# bar counter, kegs, bottles
	MeshKit.static_box(n, Vector3(4.0, 1.1, 0.7), Vector3(-hx + 3.0, F + 0.55, -hz + 2.0), Props.dark_wood())
	MeshKit.box(n, Vector3(4.1, 0.08, 0.8), Vector3(-hx + 3.0, F + 1.12, -hz + 2.0), wood)
	if PropKit.enabled():
		for i in 3:
			PropKit.put(n, "Barrel_Holder", Vector3(-hx + 1.6 + i * 1.45, F, -hz + 0.55), 0.0, Vector3.ONE, i == 0)
		for i in 8:
			PropKit.put(n, ["Bottle_1", "Mug", "Bottle_1", "Chalice"][i % 4], Vector3(-hx + 1.4 + i * 0.4, F + 1.16, -hz + 2.05), randf() * 360.0, Vector3.ONE, false, false)
		PropKit.put(n, "Chandelier", Vector3(1.0, F + 3.25, 0.4))
	for i in (0 if PropKit.enabled() else 3):
		var k := Node3D.new()
		k.position = Vector3(-hx + 1.6 + i * 1.3, F + 0.55, -hz + 0.6)
		n.add_child(k)
		MeshKit.cyl(k, 0.45, 0.45, 0.9, Vector3.ZERO, MeshKit.mat(Color(0.45, 0.3, 0.17)), Vector3(90, 0, 0), 14)
		MeshKit.cyl(k, 0.47, 0.47, 0.06, Vector3(0, 0, 0.3), MeshKit.mat(Color(0.2, 0.2, 0.22), 0.5, 0.7), Vector3(90, 0, 0), 14)
		MeshKit.cyl(k, 0.47, 0.47, 0.06, Vector3(0, 0, -0.3), MeshKit.mat(Color(0.2, 0.2, 0.22), 0.5, 0.7), Vector3(90, 0, 0), 14)
	for i in (0 if PropKit.enabled() else 8):
		MeshKit.cyl(n, 0.035, 0.04, 0.26, Vector3(-hx + 1.4 + i * 0.4, F + 1.29, -hz + 2.05), MeshKit.mat(Color(0.2, 0.45, 0.25).lerp(Color(0.5, 0.25, 0.1), randf()), 0.2), Vector3.ZERO, 8)
	# tables with benches
	var social := []
	for tp in [Vector3(-1.5, 0, 1.5), Vector3(2.0, 0, 1.6), Vector3(-1.0, 0, -1.2), Vector3(2.5, 0, -1.6)]:
		_bench_table(n, tp + Vector3(0, F, 0))
		social.append(_g(n, tp + Vector3(0, F, 1.0)))
	Buildings._fireplace(w, n, Vector3(-hx + 0.55, F, 1.0), 90.0)
	MeshKit.static_box(n, Vector3(0.9, h + 3.0, 1.3), Vector3(-hx + 0.15, F + (h + 3.0) * 0.5, 1.0), Props.stone(Color(0.85, 0.55, 0.45), 0.6))
	Buildings.hanging_lamp(n, Vector3(0.5, F + 3.0, 0.0))
	Buildings.hanging_lamp(n, Vector3(-3.0, F + 3.0, 0.5))
	# rooms upstairs
	for bxp in [-hx + 1.3, -hx + 4.0]:
		Buildings.bed(n, Vector3(bxp, y2, -hz + 1.2), 0.0, RandomNumberGenerator.new())
	Buildings.chest_small(n, Vector3(-1.0, y2, -hz + 0.5), 0.0)
	Buildings.hanging_lamp(n, Vector3(-2.0, y2 + 2.9, -1.0))
	_sign(n, Vector3(1.5, F + 3.0, hz + 0.25), Loc.t("Tavern"), Color(1.0, 0.85, 0.5))
	w.homes.append({"door": r["door"], "out": _g(n, Vector3(0, 0, hz + 1.7)), "in": _g(n, Vector3(0, F, hz - 1.4)),
		"bed": _g(n, Vector3(-hx + 1.3, y2, -hz + 1.2)), "bed_yaw": n.rotation.y, "table": _g(n, Vector3(-hx + 3.0, F, -hz + 3.0)), "taken": false, "kind": "tavern"})
	w.building_areas.append([Vector2(n.global_position.x, n.global_position.z), 8.5])
	return {"node": n, "social": social, "work": [_g(n, Vector3(-hx + 3.0, F, -hz + 1.2)), n.rotation.y + PI, "idle"]}


static func _bench_table(n: Node3D, p: Vector3) -> void:
	if PropKit.enabled():
		PropKit.put(n, "Table_Large", p, 0.0, PropKit.fit("Table_Large", Vector3(1.8, 0.8, 0.9)), true)
		for z in [-0.75, 0.75]:
			PropKit.put(n, "Bench", p + Vector3(0, 0, z), 0.0, PropKit.fit("Bench", Vector3(1.8, 0.47, 0.42)), true)
		var rng := RandomNumberGenerator.new()
		rng.seed = int(p.x * 11.0 + p.z * 5.0)
		PropKit.table_clutter(n, p + Vector3(0, 0.8, 0), Vector2(0.65, 0.25), rng, 3)
		Buildings.candle(n, p + Vector3(0, 0.8, 0), false)
		return
	var wd := Props.wood()
	MeshKit.static_box(n, Vector3(1.8, 0.08, 0.9), p + Vector3(0, 0.78, 0), wd)
	for x in [-0.75, 0.75]:
		MeshKit.box(n, Vector3(0.1, 0.74, 0.7), p + Vector3(x, 0.37, 0), wd)
	for z in [-0.75, 0.75]:
		MeshKit.static_box(n, Vector3(1.8, 0.07, 0.32), p + Vector3(0, 0.45, z), wd)
		for x in [-0.75, 0.75]:
			MeshKit.box(n, Vector3(0.08, 0.42, 0.28), p + Vector3(x, 0.21, z), wd)
	MeshKit.cyl(n, 0.06, 0.05, 0.14, p + Vector3(0.3, 0.89, 0.1), MeshKit.mat(Color(0.6, 0.45, 0.3)), Vector3.ZERO, 10)
	MeshKit.cyl(n, 0.06, 0.05, 0.14, p + Vector3(-0.4, 0.89, -0.15), MeshKit.mat(Color(0.6, 0.45, 0.3)), Vector3.ZERO, 10)
	Buildings.candle(n, p + Vector3(0, 0.82, 0), false)


# --------------------------------------------------------------------------- blacksmith

## Open smithy: forge with glowing coals and chimney, anvil, quench barrel, grindstone, racks.
static func blacksmith(w: Node3D, p: Vector3, yaw: float) -> Dictionary:
	var n := Props.pivot(w, p, yaw)
	var stone := _stone(Color(0.9, 0.86, 0.8))
	var timber := Props.dark_wood()
	var fl := MeshKit.static_box(n, Vector3(9.0, F, 7.0), Vector3(0, F * 0.5, 0), stone)
	fl.set_meta("surface", "stone")
	MeshKit.static_box(n, Vector3(9.0, 3.6, 0.5), Vector3(0, F + 1.8, -3.25), stone)
	MeshKit.static_box(n, Vector3(0.5, 3.6, 3.0), Vector3(-4.25, F + 1.8, -1.75), stone)
	for x in [-4.3, 0.0, 4.3]:
		MeshKit.static_box(n, Vector3(0.3, 3.8, 0.3), Vector3(x, F + 1.9, 3.3), timber)
	MeshKit.box(n, Vector3(9.4, 0.25, 0.3), Vector3(0, F + 3.8, 3.3), timber)
	MeshKit.box(n, Vector3(9.8, 0.2, 7.8), Vector3(0, F + 4.2, 0), Props.roof(Color(0.45, 0.4, 0.4)), Vector3(-8, 0, 0))
	MeshKit.collider_box(n, Vector3(9.8, 0.2, 7.8), Vector3(0, F + 4.2, 0), Vector3(-8, 0, 0))
	# forge
	var brick := Props.stone(Color(0.8, 0.5, 0.4), 0.6)
	MeshKit.static_box(n, Vector3(2.2, 1.0, 1.6), Vector3(-2.5, F + 0.5, -2.1), brick)
	MeshKit.box(n, Vector3(1.6, 0.1, 1.0), Vector3(-2.5, F + 1.02, -2.0), MeshKit.mat(Color(1.0, 0.35, 0.05), 0.8, 0.0, 2.5))
	MeshKit.cyl(n, 0.0, 0.3, 0.45, Vector3(-2.5, F + 1.3, -2.0), MeshKit.unshaded(Color(1.0, 0.55, 0.15)), Vector3.ZERO, 7)
	MeshKit.cyl(n, 0.9, 0.4, 1.2, Vector3(-2.5, F + 2.1, -2.2), brick, Vector3.ZERO, 4)
	MeshKit.static_box(n, Vector3(0.7, 4.0, 0.7), Vector3(-2.5, F + 4.4, -2.4), brick)
	var fire := OmniLight3D.new()
	fire.light_color = Color(1.0, 0.5, 0.2)
	fire.omni_range = 7.0
	fire.position = Vector3(-2.5, F + 1.6, -1.4)
	n.add_child(fire)
	w.fire_lights.append(fire)
	# bellows
	MeshKit.box(n, Vector3(0.8, 0.2, 0.5), Vector3(-1.1, F + 0.9, -2.3), MeshKit.mat(Color(0.35, 0.22, 0.12)), Vector3(0, 0, 10))
	if PropKit.enabled():
		# kit anvil on its log, quench barrel, whetstone, weapon stand, tools and a workbench
		PropKit.put(n, "Anvil_Log", Vector3(0.5, F, -0.5), 90.0, Vector3.ONE * 1.05, true)
		PropKit.put(n, "Barrel", Vector3(-0.8, F, 0.6), 0.0, Vector3.ONE * 1.05, true)
		MeshKit.cyl(n, 0.33, 0.33, 0.02, Vector3(-0.8, F + 0.9, 0.6), MeshKit.mat(Color(0.1, 0.18, 0.22), 0.1, 0.3), Vector3.ZERO, 12)
		PropKit.put(n, "Whetstone", Vector3(2.8, F, 0.6), -90.0, Vector3.ONE, true)
		PropKit.put(n, "WeaponStand", Vector3(2.4, F, -2.45), 0.0, Vector3.ONE * 1.1, true)
		if Arms.enabled():
			for i in 3:
				Arms.upright(n, Vector3(2.0 + i * 0.32, F + 0.25, -2.45), 0.0, -6.0 + i * 6.0, 0.95)
		else:
			PropKit.put(n, "Sword_Bronze", Vector3(2.0, F + 1.0, -2.45), 0.0, Vector3.ONE, false, false)
		PropKit.put(n, "Axe_Bronze", Vector3(2.8, F + 0.9, -2.4), 0.0, Vector3.ONE, false, false)
		PropKit.put(n, "Pickaxe_Bronze", Vector3(3.9, F + 0.55, 1.6), 90.0, Vector3.ONE, false, false)
		PropKit.put(n, "Shield_Wooden", Vector3(-3.95, F + 1.6, 0.2), 90.0)
		PropKit.put(n, "Bucket_Metal", Vector3(-1.5, F, 0.9), 30.0)
		PropKit.put(n, "Chain_Coil", Vector3(1.6, F, 1.4), 0.0)
	else:
		# anvil on a stump
		MeshKit.static_cyl(n, 0.35, 0.6, Vector3(0.5, F + 0.3, -0.5), MeshKit.mat(Color(0.4, 0.28, 0.16)), 10)
		var iron := MeshKit.mat(Color(0.12, 0.12, 0.13), 0.4, 0.85)
		MeshKit.box(n, Vector3(0.3, 0.25, 0.25), Vector3(0.5, F + 0.72, -0.5), iron)
		MeshKit.box(n, Vector3(0.6, 0.12, 0.28), Vector3(0.55, F + 0.9, -0.5), iron)
		MeshKit.cyl(n, 0.0, 0.07, 0.25, Vector3(0.95, F + 0.9, -0.5), iron, Vector3(0, 0, 90), 6)
		# quench barrel, grindstone, weapon rack, coal
		MeshKit.static_cyl(n, 0.4, 0.8, Vector3(-0.8, F + 0.4, 0.6), MeshKit.mat(Color(0.45, 0.3, 0.17)), 12)
		MeshKit.cyl(n, 0.36, 0.36, 0.02, Vector3(-0.8, F + 0.78, 0.6), MeshKit.mat(Color(0.1, 0.18, 0.22), 0.1, 0.3), Vector3.ZERO, 12)
		MeshKit.box(n, Vector3(0.8, 0.6, 0.4), Vector3(2.8, F + 0.3, 0.5), timber)
		MeshKit.cyl(n, 0.4, 0.4, 0.12, Vector3(2.8, F + 0.9, 0.5), Props.stone(Color(0.8, 0.78, 0.75), 1.0), Vector3(90, 90, 0), 18)
		MeshKit.static_box(n, Vector3(2.4, 2.0, 0.2), Vector3(2.5, F + 1.0, -2.9), timber)
		for i in 5:
			MeshKit.box(n, Vector3(0.04, 1.2, 0.02), Vector3(1.6 + i * 0.45, F + 1.2, -2.75), MeshKit.mat(Color(0.7, 0.7, 0.75), 0.25, 0.9), Vector3(0, 0, 5))
			MeshKit.box(n, Vector3(0.18, 0.04, 0.04), Vector3(1.6 + i * 0.45, F + 0.66, -2.73), MeshKit.mat(Color(0.4, 0.3, 0.2)))
	MeshKit.sphere(n, 0.7, Vector3(3.6, F, -2.0), MeshKit.mat(Color(0.06, 0.06, 0.06), 1.0), Vector3(1.2, 0.5, 1.0))
	_sign(n, Vector3(4.4, F + 3.0, 3.6), Loc.t("Smithy"), Color(0.9, 0.9, 0.95))
	w.building_areas.append([Vector2(n.global_position.x, n.global_position.z), 6.5])
	return {"node": n, "work": [_g(n, Vector3(0.5, F, 0.4)), n.rotation.y, "hammer"]}


# --------------------------------------------------------------------------- shop

## Trader's shop: counter, shelves of goods, the trader and a stash chest.
static func shop(w: Node3D, p: Vector3, yaw: float) -> Dictionary:
	var n := Props.pivot(w, p, yaw)
	var r := shell(w, n, 9.0, 7.0, 3.6, {"front": [[1.6, 1.1, 1.0, 2.3], [7.4, 1.1, 1.0, 2.3]], "left": [[3.5, 1.0, 1.0, 2.3]], "right": [[3.5, 1.0, 1.0, 2.3]]},
		_plaster(Color(0.85, 0.9, 0.82)), Color(0.35, 0.55, 0.45), true, true, true)
	var hz: float = r["hz"]
	MeshKit.static_box(n, Vector3(5.5, 1.05, 0.6), Vector3(0, F + 0.52, -0.6), Props.dark_wood())
	MeshKit.box(n, Vector3(5.6, 0.08, 0.7), Vector3(0, F + 1.06, -0.6), Props.wood())
	for i in 3:
		Buildings.shelf(n, Vector3(-2.6 + i * 2.6, F, -3.1), 0.0, RandomNumberGenerator.new())
	if PropKit.enabled():
		# goods on the counter, potions on the wall
		var crng := RandomNumberGenerator.new()
		crng.seed = int(p.x * 3.0 + p.z)
		for it in [["Coin_Pile", -1.8], ["Scroll_2", -1.0], ["Pouch_Large", -0.2], ["Potion_4", 0.6], ["Key_Gold", 1.3], ["Book_7", 2.0]]:
			PropKit.put(n, it[0], Vector3(it[1], F + 1.1, -0.6), crng.randf_range(-30, 30), Vector3.ONE, false, false)
		PropKit.put(n, "Shelf_Small_Bottles", Vector3(-4.2, F + 1.4, 0.8), 90.0)
		PropKit.put(n, "Bag", Vector3(3.6, F, 1.6), 40.0, Vector3.ONE, true)
	for i in 4:
		Props.crate(w, _g(n, Vector3(-3.6 + (i % 2) * 0.95, 0, 2.0 + (i / 2) * 0.95)) * Vector3(1, 0, 1) + Vector3(0, F, 0), randf_range(-10, 10))
	Props.barrel(w, _g(n, Vector3(3.6, 0, 2.6)) * Vector3(1, 0, 1) + Vector3(0, F, 0))
	Buildings.hanging_lamp(n, Vector3(0, F + 3.3, 0.5))
	_sign(n, Vector3(1.6, F + 2.9, hz + 0.25), Loc.t("Trader"), Color(1.0, 0.85, 0.35))
	w.building_areas.append([Vector2(n.global_position.x, n.global_position.z), 6.0])
	return {"node": n, "trader": _g(n, Vector3(0, F, -1.6)), "trader_yaw": n.rotation.y, "stash": _g(n, Vector3(3.2, F, 0.4)), "stash_yaw": n.rotation.y - PI * 0.5}


# --------------------------------------------------------------------------- barracks

## Stone barracks with bunk beds and weapon racks; guards patrol outside.
static func barracks(w: Node3D, p: Vector3, yaw: float) -> Dictionary:
	var n := Props.pivot(w, p, yaw)
	var r := shell(w, n, 12.0, 7.0, 3.6, {"front": [[2.0, 0.8, 1.4, 2.2], [10.0, 0.8, 1.4, 2.2]], "back": [[3.0, 0.8, 1.4, 2.2], [6.0, 0.8, 1.4, 2.2], [9.0, 0.8, 1.4, 2.2]]},
		_stone(Color(0.85, 0.85, 0.88)), Color(0.35, 0.4, 0.55), true, true, false)
	var hz: float = r["hz"]
	for i in 4:
		var bx := -4.5 + i * 3.0
		for lvl in 2:
			var y := F + 0.3 + lvl * 1.3
			MeshKit.static_box(n, Vector3(0.95, 0.15, 2.0), Vector3(bx, y, -hz + 1.3), Props.wood())
			MeshKit.box(n, Vector3(0.85, 0.12, 1.9), Vector3(bx, y + 0.13, -hz + 1.3), MeshKit.mat(Color(0.35, 0.38, 0.5), 0.95))
		for c in [Vector3(-0.45, 0, -0.95), Vector3(0.45, 0, -0.95), Vector3(-0.45, 0, 0.95), Vector3(0.45, 0, 0.95)]:
			MeshKit.box(n, Vector3(0.08, 2.0, 0.08), Vector3(bx, F + 1.0, -hz + 1.3) + c, Props.dark_wood())
	MeshKit.static_box(n, Vector3(2.4, 2.0, 0.25), Vector3(-4.0, F + 1.0, hz - 0.5), Props.dark_wood())
	for i in 4:
		if Arms.enabled():
			Arms.upright(n, Vector3(-4.75 + i * 0.5, F + 0.35, hz - 0.72), 180.0, 0.0, 1.0)
		else:
			MeshKit.box(n, Vector3(0.05, 1.5, 0.03), Vector3(-4.8 + i * 0.5, F + 1.1, hz - 0.65), MeshKit.mat(Color(0.65, 0.65, 0.7), 0.3, 0.85))
	if Arms.enabled():
		Arms.wall_display(n, Vector3(2.5, F + 2.2, hz - 0.3), 180.0)
	_bench_table(n, Vector3(2.5, F, 0.8))
	Buildings.hanging_lamp(n, Vector3(0, F + 3.3, 0.0))
	# flag pole
	MeshKit.static_cyl(n, 0.08, 8.0, Vector3(5.5, 4.0, hz + 1.8), MeshKit.mat(Color(0.3, 0.3, 0.32), 0.4, 0.8), 8)
	MeshKit.box(n, Vector3(1.6, 1.0, 0.03), Vector3(6.3, 7.2, hz + 1.8), MeshKit.mat(Color(0.2, 0.3, 0.65)))
	MeshKit.box(n, Vector3(0.5, 0.5, 0.035), Vector3(6.3, 7.2, hz + 1.8), MeshKit.mat(Color(0.9, 0.75, 0.25), 0.4, 0.6))
	w.building_areas.append([Vector2(n.global_position.x, n.global_position.z), 7.5])
	return {"node": n, "guards": [_g(n, Vector3(-2.0, 0, hz + 3.0)), _g(n, Vector3(2.0, 0, hz + 3.0))]}


# --------------------------------------------------------------------------- watchtower

## Wooden watchtower with a ladder (climb with F) and a roofed lookout platform.
static func watchtower(w: Node3D, p: Vector3, yaw: float) -> Dictionary:
	var n := Props.pivot(w, p, yaw)
	var timber := Props.dark_wood()
	var h := 8.0
	for x in [-1.3, 1.3]:
		for z in [-1.3, 1.3]:
			MeshKit.static_box(n, Vector3(0.3, h + 3.0, 0.3), Vector3(x, (h + 3.0) * 0.5, z), timber)
	for y in [2.5, 5.0]:
		for s in [-1.0, 1.0]:
			MeshKit.box(n, Vector3(2.9, 0.15, 0.12), Vector3(0, y, s * 1.3), timber, Vector3(0, 0, s * 35.0))
			MeshKit.box(n, Vector3(0.12, 0.15, 2.9), Vector3(s * 1.3, y, 0), timber, Vector3(s * 35.0, 0, 0))
	var plat := MeshKit.static_box(n, Vector3(3.6, 0.2, 3.6), Vector3(0, h, 0), Props.wood())
	plat.set_meta("surface", "wood")
	for s in [-1.0, 1.0]:
		MeshKit.static_box(n, Vector3(3.6, 1.0, 0.1), Vector3(0, h + 0.6, s * 1.75), Props.wood())
		MeshKit.static_box(n, Vector3(0.1, 1.0, 3.6), Vector3(s * 1.75, h + 0.6, 0) if s < 0 else Vector3(s * 1.75, h + 0.6, -0.6), Props.wood())
	MeshKit.cyl(n, 0.0, 3.0, 1.8, Vector3(0, h + 3.6, 0), Props.roof(Color(0.5, 0.4, 0.35)), Vector3(0, 45, 0), 4)
	# ladder on the +x side
	for s in [-0.3, 0.3]:
		MeshKit.box(n, Vector3(0.08, h, 0.08), Vector3(1.75, h * 0.5, s + 0.9), timber)
	var y := 0.4
	while y < h:
		MeshKit.box(n, Vector3(0.06, 0.06, 0.6), Vector3(1.75, y, 0.9), timber)
		y += 0.4
	var base := n.global_position
	var top := n.to_global(Vector3(0, h + 0.1, 0))
	var face := n.rotation.y + PI * 0.5
	for down in [false, true]:
		var s := ClimbSpot.new()
		s.world = w
		s.tree_base = base + Vector3(sin(face), 0, cos(face)) * 0.0
		s.top_height = h
		s.top_pos = top
		s.radius_bottom = 1.35
		s.radius_top = 1.35
		s.face_angle = face
		s.down = down
		w.add_child(s)
		s.global_position = (top + Vector3(0, 0.4, 0)) if down else n.to_global(Vector3(2.4, 0.5, 0.9))
	return {"node": n, "lookout": top}


# --------------------------------------------------------------------------- rural

static func stable(w: Node3D, p: Vector3, yaw: float) -> Dictionary:
	var n := Props.pivot(w, p, yaw)
	var timber := Props.dark_wood()
	var wood := Props.wood()
	MeshKit.static_box(n, Vector3(10.0, 2.6, 0.2), Vector3(0, 1.3, -2.4), wood)
	for x in [-5.0, 5.0]:
		MeshKit.static_box(n, Vector3(0.2, 2.6, 5.0), Vector3(x, 1.3, 0), wood)
	for i in 4:
		var x := -3.75 + i * 2.5
		if i > 0:
			MeshKit.static_box(n, Vector3(0.12, 1.5, 3.6), Vector3(x - 1.25, 0.75, -0.6), wood)
		MeshKit.box(n, Vector3(1.6, 0.4, 0.5), Vector3(x, 0.4, -2.0), timber)
		MeshKit.sphere(n, 0.8, Vector3(x + 0.3, 0.0, -1.0), MeshKit.mat(Color(0.86, 0.72, 0.36)), Vector3(1.0, 0.35, 0.9))
	for x in [-5.0, -2.5, 0.0, 2.5, 5.0]:
		MeshKit.static_box(n, Vector3(0.2, 3.0, 0.2), Vector3(x, 1.5, 2.4), timber)
	MeshKit.box(n, Vector3(10.6, 0.2, 5.8), Vector3(0, 3.1, 0), Props.roof(Color(0.5, 0.42, 0.38)), Vector3(-10, 0, 0))
	return {"node": n, "work": [n.to_global(Vector3(0, 0, 1.0)), n.rotation.y + PI, "work"]}


static func granary(w: Node3D, p: Vector3, yaw: float) -> Dictionary:
	var n := Props.pivot(w, p, yaw)
	MeshKit.static_cyl(n, 2.4, 4.0, Vector3(0, 2.0, 0), _stone(Color(0.95, 0.9, 0.82)), 18)
	MeshKit.cyl(n, 0.0, 3.0, 2.4, Vector3(0, 5.2, 0), Props.roof(Color(0.75, 0.6, 0.35)), Vector3.ZERO, 18)
	MeshKit.box(n, Vector3(1.1, 1.9, 0.12), Vector3(0, 0.95, 2.38), Props.dark_wood())
	for i in 4:
		MeshKit.sphere(n, 0.35, Vector3(1.4 + (i % 2) * 0.6, 0.35, 2.6 + (i / 2) * 0.5), MeshKit.mat(Color(0.78, 0.68, 0.5), 0.95), Vector3(1, 1.2, 0.9))
	return {"node": n}


static func chicken_coop(w: Node3D, p: Vector3, yaw: float) -> Dictionary:
	var n := Props.pivot(w, p, yaw)
	var wood := Props.wood()
	for x in [-0.8, 0.8]:
		for z in [-0.6, 0.6]:
			MeshKit.box(n, Vector3(0.1, 0.6, 0.1), Vector3(x, 0.3, z), Props.dark_wood())
	MeshKit.static_box(n, Vector3(1.8, 1.0, 1.4), Vector3(0, 1.1, 0), wood)
	MeshKit.prism(n, Vector3(2.0, 0.6, 1.6), Vector3(0, 1.9, 0), Props.roof(Color(0.6, 0.35, 0.25)), Vector3(0, 90, 0))
	MeshKit.box(n, Vector3(0.4, 0.06, 1.2), Vector3(0, 0.35, 1.2), wood, Vector3(30, 0, 0))
	Props.fence(w, n.to_global(Vector3(-3, 0, 1.5)), n.to_global(Vector3(3, 0, 1.5)))
	Props.fence(w, n.to_global(Vector3(-3, 0, -1.2)), n.to_global(Vector3(-3, 0, 4.5)))
	Props.fence(w, n.to_global(Vector3(3, 0, -1.2)), n.to_global(Vector3(3, 0, 4.5)))
	return {"node": n, "chickens": n.to_global(Vector3(0, 0, 3.0))}


static func sawmill(w: Node3D, p: Vector3, yaw: float) -> Dictionary:
	var n := Props.pivot(w, p, yaw)
	var timber := Props.dark_wood()
	for x in [-3.5, 3.5]:
		for z in [-2.5, 2.5]:
			MeshKit.static_box(n, Vector3(0.25, 3.2, 0.25), Vector3(x, 1.6, z), timber)
	MeshKit.box(n, Vector3(8.0, 0.2, 6.0), Vector3(0, 3.3, 0), Props.roof(Color(0.45, 0.42, 0.4)), Vector3(-8, 0, 0))
	MeshKit.static_box(n, Vector3(4.0, 0.9, 1.0), Vector3(0, 0.45, 0), timber)
	var blade := Node3D.new()
	blade.position = Vector3(0, 0.95, 0)
	n.add_child(blade)
	MeshKit.cyl(blade, 0.55, 0.55, 0.02, Vector3.ZERO, MeshKit.mat(Color(0.7, 0.7, 0.72), 0.25, 0.9), Vector3(0, 0, 90), 24)
	w.spinners.append([blade, Vector3(6.0, 0, 0)])
	var bark := Nature.bark_material(Color(1.1, 0.8, 0.5))
	for i in 6:
		MeshKit.cyl(n, 0.3, 0.3, 4.0, Vector3(-1.0 + (i % 3) * 0.62, 0.3 + (i / 3) * 0.55, -4.5), bark, Vector3(0, 0, 90), 10)
	MeshKit.collider_box(n, Vector3(4.0, 1.2, 2.0), Vector3(-0.4, 0.6, -4.5))
	for i in 4:
		MeshKit.box(n, Vector3(3.0, 0.08, 0.3), Vector3(5.0, 0.1 + i * 0.09, 0.0), Props.wood())
	return {"node": n, "work": [n.to_global(Vector3(0, 0, 1.2)), n.rotation.y + PI, "work"]}


static func fishing_hut(w: Node3D, p: Vector3, yaw: float) -> Dictionary:
	var n := Props.pivot(w, p, yaw)
	var timber := Props.dark_wood()
	for x in [-1.6, 1.6]:
		for z in [-1.6, 1.6]:
			MeshKit.static_box(n, Vector3(0.2, 3.0, 0.2), Vector3(x, 0.5, z), timber)
	var deck := MeshKit.static_box(n, Vector3(4.2, 0.18, 4.2), Vector3(0, 1.4, 0), Props.wood())
	deck.set_meta("surface", "wood")
	MeshKit.static_box(n, Vector3(3.0, 2.2, 2.6), Vector3(0, 2.6, -0.5), Props.wood())
	MeshKit.prism(n, Vector3(3.4, 1.0, 3.0), Vector3(0, 4.2, -0.5), Props.roof(Color(0.4, 0.45, 0.5)), Vector3(0, 90, 0))
	MeshKit.box(n, Vector3(1.0, 1.8, 0.05), Vector3(0, 2.4, 0.82), MeshKit.mat(Color(0.08, 0.06, 0.05)))
	var ramp := MeshKit.static_box(n, Vector3(1.2, 0.12, 4.2), Vector3(0, 0.75, 3.9), Props.wood(), Vector3(-rad_to_deg(atan2(1.4, 4.0)), 0, 0))
	ramp.set_meta("surface", "wood")
	MeshKit.cyl(n, 0.02, 0.02, 2.4, Vector3(1.8, 2.4, 1.6), MeshKit.mat(Color(0.5, 0.4, 0.25)), Vector3(40, 0, 0), 5)
	return {"node": n, "work": [n.to_global(Vector3(1.4, 1.5, 1.6)), n.rotation.y, "idle"]}


# --------------------------------------------------------------------------- defenses / ruins

static func gatehouse(w: Node3D, p: Vector3, yaw: float) -> Dictionary:
	var n := Props.pivot(w, p, yaw)
	var st := _stone(Color(0.88, 0.86, 0.82))
	for s in [-1.0, 1.0]:
		MeshKit.static_box(n, Vector3(3.0, 7.0, 3.0), Vector3(s * 3.2, 3.5, 0), st)
		for i in 4:
			MeshKit.box(n, Vector3(0.7, 0.8, 0.7), Vector3(s * 3.2 + (i % 2 - 0.5) * 2.0, 7.4, (i / 2 - 0.5) * 2.0), st)
		MeshKit.box(n, Vector3(0.4, 1.2, 0.1), Vector3(s * 3.2, 4.5, 1.52), MeshKit.mat(Color(0.05, 0.05, 0.06)))
	MeshKit.static_box(n, Vector3(3.4, 1.6, 3.0), Vector3(0, 6.2, 0), st)
	for i in 3:
		MeshKit.box(n, Vector3(0.7, 0.8, 0.7), Vector3(-1.2 + i * 1.2, 7.4, 1.15), st)
	for s in [-1.0, 1.0]:
		var dp := Node3D.new()
		dp.position = Vector3(s * 1.7, 0, 1.4)
		dp.rotation_degrees.y = s * -95.0
		n.add_child(dp)
		MeshKit.static_box(dp, Vector3(1.7, 5.2, 0.15), Vector3(-s * 0.85, 2.6, 0), Props.dark_wood())
	MeshKit.box(n, Vector3(3.6, 0.3, 0.4), Vector3(0, 5.3, 1.3), MeshKit.mat(Color(0.2, 0.2, 0.22), 0.4, 0.8))
	Props.torch(w, n.to_global(Vector3(-2.0, 0, 2.0)))
	Props.torch(w, n.to_global(Vector3(2.0, 0, 2.0)))
	return {"node": n}


## Broken castle: crenellated walls with gaps, two towers, a collapsed keep and rubble.
static func ruined_castle(w: Node3D, p: Vector3, yaw: float, rng: RandomNumberGenerator) -> Dictionary:
	var n := Props.pivot(w, p, yaw)
	var st := _stone(Color(0.78, 0.76, 0.74))
	var size := 22.0
	var hs := size * 0.5
	for side in 4:
		var a := side * PI * 0.5
		var seg := 2.0
		var x := -hs
		while x < hs:
			var h := rng.randf_range(3.0, 6.5) if rng.randf() > 0.15 else 0.0
			if h > 0.0 and not (side == 0 and absf(x + seg * 0.5) < 2.5):
				var local := Vector3(x + seg * 0.5, h * 0.5, hs).rotated(Vector3.UP, a)
				MeshKit.static_box(n, Vector3(seg, h, 1.4) if side % 2 == 0 else Vector3(seg, h, 1.4), local, st, Vector3(0, rad_to_deg(a), 0))
				if h > 5.0:
					MeshKit.box(n, Vector3(0.7, 0.8, 1.4), local + Vector3(0, h * 0.5 + 0.4, 0), st, Vector3(0, rad_to_deg(a), 0))
			x += seg
	for c in [Vector3(-hs, 0, -hs), Vector3(hs, 0, hs)]:
		var cs := CylinderShape3D.new()
		cs.radius = 2.6
		cs.height = 10.0
		var b := StaticBody3D.new()
		b.position = c + Vector3(0, 5.0, 0)
		var col := CollisionShape3D.new()
		col.shape = cs
		b.add_child(col)
		n.add_child(b)
		MeshKit.cyl(n, 2.4, 2.7, 10.0, c + Vector3(0, 5.0, 0), st, Vector3.ZERO, 16)
		for i in 7:
			var a := TAU * i / 10.0
			MeshKit.box(n, Vector3(0.8, rng.randf_range(0.6, 1.8), 0.7), c + Vector3(cos(a) * 2.5, 10.4, sin(a) * 2.5), st, Vector3(0, -rad_to_deg(a), 0))
	MeshKit.static_box(n, Vector3(7.0, 4.0, 6.0), Vector3(0, 2.0, -4.0), st)
	MeshKit.static_box(n, Vector3(3.0, 6.5, 6.0), Vector3(-2.0, 3.25, -4.0), st)
	for i in 14:
		MeshKit.static_box(n, Vector3(1.0, 0.6, 0.8) * rng.randf_range(0.6, 1.4), Vector3(rng.randf_range(-hs + 2, hs - 2), 0.2, rng.randf_range(-hs + 2, hs - 2)), st,
			Vector3(rng.randf_range(-20, 20), rng.randf_range(0, 90), rng.randf_range(-20, 20)))
	return {"node": n}


## Crypt: a stone doorway into a burial mound. Inside, a dark hall with sarcophagi and candles.
static func crypt(w: Node3D, p: Vector3, yaw: float) -> Dictionary:
	var n := Props.pivot(w, p, yaw)
	var st := _stone(Color(0.65, 0.64, 0.66))
	var rock := Props.rock_mat(Color(0.9, 0.95, 0.85))
	var L := 14.0
	var W := 7.0
	var H := 3.6
	# hall: floor, walls, vaulted ceiling
	var fl := MeshKit.static_box(n, Vector3(W, 0.2, L), Vector3(0, 0.1, -L * 0.5), st)
	fl.set_meta("surface", "stone")
	for s in [-1.0, 1.0]:
		MeshKit.static_box(n, Vector3(0.6, H, L), Vector3(s * (W * 0.5 + 0.3), H * 0.5, -L * 0.5), st)
	MeshKit.static_box(n, Vector3(W + 1.2, H, 0.6), Vector3(0, H * 0.5, -L - 0.3), st)
	MeshKit.static_box(n, Vector3(W + 1.2, 0.5, L + 0.6), Vector3(0, H + 0.25, -L * 0.5), st)
	for i in 5:
		var z := -1.5 - i * 2.8
		for s in [-1.0, 1.0]:
			MeshKit.box(n, Vector3(0.5, H, 0.5), Vector3(s * (W * 0.5 - 0.1), H * 0.5, z), st)
		MeshKit.box(n, Vector3(W, 0.4, 0.5), Vector3(0, H - 0.2, z), st)
	# front wall with the doorway
	for s in [-1.0, 1.0]:
		MeshKit.static_box(n, Vector3((W - 1.6) * 0.5 + 0.6, H, 0.8), Vector3(s * ((W - 1.6) * 0.25 + 0.8 + 0.15), H * 0.5, 0.0), st)
	MeshKit.static_box(n, Vector3(1.6, 1.0, 0.8), Vector3(0, H - 0.5, 0.0), st)
	MeshKit.cyl(n, 0.0, 1.8, 1.2, Vector3(0, H + 0.9, 0.3), st, Vector3(0, 45, 0), 4)
	# the mound around it
	for i in 7:
		var z := -1.0 - i * 2.2
		for s in [-1.0, 1.0]:
			MeshKit.static_sphere(n, 3.4, Vector3(s * (W * 0.5 + 2.6), 0.8, z), rock)
		MeshKit.sphere(n, 3.6, Vector3(0, H + 1.4, z), rock, Vector3(1.4, 0.55, 1.0))
	# sarcophagi, candles, bones
	for i in 3:
		var z := -3.5 - i * 3.5
		for s in [-1.0, 1.0]:
			MeshKit.static_box(n, Vector3(1.0, 0.8, 2.2), Vector3(s * 2.2, 0.6, z), st)
			MeshKit.box(n, Vector3(1.1, 0.15, 2.3), Vector3(s * 2.2, 1.05, z), Props.stone(Color(0.55, 0.55, 0.6), 0.6))
			Buildings.candle(n, Vector3(s * 2.2, 1.12, z + 0.9), i == 1)
	MeshKit.static_box(n, Vector3(2.0, 1.1, 1.0), Vector3(0, 0.75, -L + 1.0), st)
	Buildings.candle(n, Vector3(-0.5, 1.32, -L + 1.0))
	Buildings.candle(n, Vector3(0.5, 1.32, -L + 1.0))
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.45, 0.8, 0.55)
	glow.light_energy = 0.8
	glow.omni_range = 8.0
	glow.position = Vector3(0, 2.0, -L * 0.6)
	n.add_child(glow)
	w.building_areas.append([Vector2(n.global_position.x, n.global_position.z), 10.0])
	return {"node": n, "inside": n.to_global(Vector3(0, 0.3, -L * 0.6)), "treasure": n.to_global(Vector3(0, 0, -L + 2.2))}


# --------------------------------------------------------------------------- detailed props

## Stone well with a shingled roof, crank, rope and bucket.
static func well(w: Node3D, p: Vector3) -> void:
	var n := Props.pivot(w, p)
	var brick := MeshKit.textured("Bricks066", Color(0.95, 0.9, 0.82), 0.9)
	MeshKit.static_cyl(n, 1.15, 0.9, Vector3(0, 0.45, 0), brick, 20)
	MeshKit.cyl(n, 1.25, 1.25, 0.12, Vector3(0, 0.95, 0), Props.stone(Color(0.85, 0.82, 0.78), 0.6), Vector3.ZERO, 20)
	MeshKit.cyl(n, 0.95, 0.95, 0.04, Vector3(0, 0.7, 0), MeshKit.mat(Color(0.04, 0.07, 0.09), 0.1, 0.3), Vector3.ZERO, 20)
	var timber := Props.dark_wood()
	for s in [-1.0, 1.0]:
		MeshKit.box(n, Vector3(0.16, 2.3, 0.16), Vector3(s * 1.05, 2.0, 0), timber)
		MeshKit.box(n, Vector3(0.1, 0.5, 0.1), Vector3(s * 0.85, 2.85, 0), timber, Vector3(0, 0, s * 45.0))
	MeshKit.cyl(n, 0.07, 0.07, 2.4, Vector3(0, 2.3, 0), timber, Vector3(0, 0, 90), 10)
	MeshKit.box(n, Vector3(0.06, 0.4, 0.06), Vector3(1.25, 2.15, 0), MeshKit.mat(Color(0.2, 0.2, 0.22), 0.4, 0.8))
	MeshKit.box(n, Vector3(0.25, 0.06, 0.06), Vector3(1.32, 1.97, 0), timber)
	MeshKit.cyl(n, 0.012, 0.012, 1.2, Vector3(0.2, 1.7, 0), MeshKit.mat(Color(0.7, 0.6, 0.4)), Vector3.ZERO, 5)
	MeshKit.cyl(n, 0.16, 0.13, 0.28, Vector3(0.2, 1.0, 0), MeshKit.mat(Color(0.45, 0.32, 0.2)), Vector3.ZERO, 12)
	MeshKit.cyl(n, 0.165, 0.165, 0.03, Vector3(0.2, 1.08, 0), MeshKit.mat(Color(0.2, 0.2, 0.22), 0.4, 0.8), Vector3.ZERO, 12)
	var roof := Props.roof(Color(0.55, 0.4, 0.35))
	for s in [-1.0, 1.0]:
		MeshKit.box(n, Vector3(2.7, 0.08, 1.2), Vector3(0, 3.35, s * 0.5), roof, Vector3(s * 32.0, 0, 0))


static func market_stall(w: Node3D, p: Vector3, yaw: float, cloth: Color, rng: RandomNumberGenerator) -> void:
	var n := Props.pivot(w, p, yaw)
	if PropKit.enabled():
		# kit market stall (or a stall cart) with crates of produce on the counter
		var cart := rng.randf() < 0.35
		var sname := "Stall_Cart_Empty" if cart else "Stall_Empty"
		var ss := PropKit.fit(sname, Vector3(3.6 if cart else 2.6, 2.6, 1.3))
		PropKit.put(n, sname, Vector3(0.4 if cart else 0.0, 0, 0.3), 180.0, ss, true)
		var top := 0.82 * ss.y
		for b in 3:
			PropKit.put(n, ["FarmCrate_Apple", "FarmCrate_Carrot", "FarmCrate_Empty"][rng.randi() % 3], Vector3(-0.75 + b * 0.75, top, 0.3), rng.randf_range(-8, 8))
		PropKit.put(n, "Barrel_Apples", Vector3(1.75, 0, -0.5), rng.randf() * 360.0, Vector3.ONE, true)
		Props.crate(w, n.to_global(Vector3(-1.75, 0, -0.6)) * Vector3(1, 0, 1), rng.randf_range(0, 30))
		return
	var timber := Props.dark_wood()
	for x in [-1.3, 1.3]:
		MeshKit.box(n, Vector3(0.1, 2.5, 0.1), Vector3(x, 1.25, 0.8), timber)
		MeshKit.box(n, Vector3(0.1, 2.1, 0.1), Vector3(x, 1.05, -0.8), timber)
	for i in 5:
		var c := cloth if i % 2 == 0 else Color(0.92, 0.9, 0.85)
		MeshKit.box(n, Vector3(0.56, 0.04, 2.0), Vector3(-1.12 + i * 0.56, 2.3, 0), MeshKit.mat(c, 0.95), Vector3(-12, 0, 0))
	MeshKit.static_box(n, Vector3(2.6, 0.9, 0.8), Vector3(0, 0.45, 0.3), Props.wood())
	var produce := [Color(0.8, 0.15, 0.1), Color(0.35, 0.6, 0.2), Color(0.9, 0.6, 0.15), Color(0.5, 0.25, 0.45)]
	for b in 3:
		var bc := Vector3(-0.85 + b * 0.85, 0.95, 0.3)
		MeshKit.box(n, Vector3(0.7, 0.18, 0.55), bc, MeshKit.mat(Color(0.6, 0.45, 0.25)))
		var pc: Color = produce[rng.randi() % produce.size()]
		for k in 7:
			MeshKit.sphere(n, 0.07, bc + Vector3(rng.randf_range(-0.25, 0.25), 0.12, rng.randf_range(-0.18, 0.18)), MeshKit.mat(pc, 0.6))
	Props.crate(w, n.to_global(Vector3(-1.6, 0, -0.6)) * Vector3(1, 0, 1), rng.randf_range(0, 30))


static func lamp_post(w: Node3D, p: Vector3) -> void:
	var n := Props.pivot(w, p)
	var iron := MeshKit.mat(Color(0.12, 0.12, 0.13), 0.45, 0.8)
	MeshKit.static_cyl(n, 0.08, 3.2, Vector3(0, 1.6, 0), iron, 8)
	MeshKit.cyl(n, 0.16, 0.2, 0.3, Vector3(0, 0.15, 0), iron, Vector3.ZERO, 8)
	MeshKit.box(n, Vector3(0.6, 0.05, 0.05), Vector3(0.3, 3.1, 0), iron)
	MeshKit.cyl(n, 0.12, 0.16, 0.32, Vector3(0.55, 2.82, 0), MeshKit.mat(Color(1.0, 0.82, 0.5), 0.5, 0.0, 2.2), Vector3.ZERO, 6)
	MeshKit.cyl(n, 0.0, 0.2, 0.14, Vector3(0.55, 3.05, 0), iron, Vector3.ZERO, 6)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.78, 0.45)
	l.light_energy = 1.4
	l.omni_range = 10.0
	l.position = Vector3(0.55, 2.7, 0)
	Buildings.fade(l, 70.0)
	n.add_child(l)
	w.flicker_lights.append([l, l.light_energy])


static func bench(w: Node3D, p: Vector3, yaw: float) -> void:
	var n := Props.pivot(w, p, yaw)
	var wood := Props.wood()
	MeshKit.static_box(n, Vector3(1.8, 0.07, 0.45), Vector3(0, 0.45, 0), wood)
	MeshKit.box(n, Vector3(1.8, 0.4, 0.06), Vector3(0, 0.75, -0.22), wood, Vector3(-10, 0, 0))
	for x in [-0.75, 0.75]:
		MeshKit.box(n, Vector3(0.08, 0.45, 0.4), Vector3(x, 0.22, 0), Props.dark_wood())


## Farm cart with spoked wheels, shafts and a load of sacks.
static func cart(w: Node3D, p: Vector3, yaw: float) -> void:
	var n := Props.pivot(w, p, yaw)
	var wood := Props.wood()
	var dark := Props.dark_wood()
	MeshKit.static_box(n, Vector3(1.6, 0.12, 2.6), Vector3(0, 0.85, 0), wood)
	for s in [-1.0, 1.0]:
		MeshKit.box(n, Vector3(0.08, 0.45, 2.6), Vector3(s * 0.8, 1.1, 0), wood)
		MeshKit.box(n, Vector3(0.08, 0.08, 2.4), Vector3(s * 0.45, 0.75, 2.2), dark, Vector3(8, 0, 0))
		var wheel := Node3D.new()
		wheel.position = Vector3(s * 0.95, 0.55, -0.3)
		n.add_child(wheel)
		var rim := TorusMesh.new()
		rim.inner_radius = 0.48
		rim.outer_radius = 0.56
		rim.rings = 20
		rim.ring_segments = 6
		MeshKit.inst(wheel, rim, Vector3.ZERO, dark, Vector3(0, 0, 90))
		for k in 6:
			MeshKit.box(wheel, Vector3(0.05, 1.0, 0.05), Vector3.ZERO, dark, Vector3(k * 30.0, 0, 0))
		MeshKit.cyl(wheel, 0.1, 0.1, 0.15, Vector3.ZERO, MeshKit.mat(Color(0.2, 0.2, 0.22), 0.4, 0.8), Vector3(0, 0, 90), 10)
	MeshKit.box(n, Vector3(0.08, 0.08, 0.9), Vector3(0, 0.75, 3.2), dark, Vector3(0, 90, 0))
	var sack := MeshKit.mat(Color(0.78, 0.68, 0.5), 0.95)
	for i in 4:
		MeshKit.sphere(n, 0.3, Vector3(-0.35 + (i % 2) * 0.7, 1.15, -0.6 + (i / 2) * 0.8), sack, Vector3(1, 0.8, 1.3))


static func signpost(w: Node3D, p: Vector3, yaw: float, names: Array) -> void:
	var n := Props.pivot(w, p, yaw)
	var dark := Props.dark_wood()
	MeshKit.static_box(n, Vector3(0.15, 2.8, 0.15), Vector3(0, 1.4, 0), dark)
	for i in names.size():
		var a := 40.0 + i * 110.0
		var arm := Node3D.new()
		arm.position = Vector3(0, 2.4 - i * 0.4, 0)
		arm.rotation_degrees.y = a
		n.add_child(arm)
		MeshKit.box(arm, Vector3(1.3, 0.25, 0.05), Vector3(0.7, 0, 0), Props.wood())
		MeshKit.prism(arm, Vector3(0.25, 0.2, 0.05), Vector3(1.45, 0, 0), Props.wood(), Vector3(0, 0, -90))
		var l := Label3D.new()
		l.text = str(names[i])
		l.font_size = 36
		l.pixel_size = 0.0032
		l.modulate = Color(0.15, 0.1, 0.05)
		l.position = Vector3(0.7, 0, 0.03)
		arm.add_child(l)
		var l2 := l.duplicate() as Label3D
		l2.position = Vector3(0.7, 0, -0.03)
		l2.rotation_degrees.y = 180.0
		arm.add_child(l2)


## Vegetable garden: soil rows with sprouting crops, a little fence.
static func garden(w: Node3D, p: Vector3, yaw: float, rng: RandomNumberGenerator) -> Vector3:
	var n := Props.pivot(w, p, yaw)
	var soil := MeshKit.mat(Color(0.28, 0.2, 0.13), 1.0)
	var leaf := MeshKit.mat(Color(0.3, 0.55, 0.2), 0.9)
	for r in 4:
		MeshKit.box(n, Vector3(4.0, 0.12, 0.6), Vector3(0, 0.03, -1.2 + r * 0.8), soil)
		for k in 7:
			MeshKit.sphere(n, rng.randf_range(0.1, 0.18), Vector3(-1.8 + k * 0.6, 0.15, -1.2 + r * 0.8), leaf, Vector3(1, 0.7, 1))
	Props.fence(w, n.to_global(Vector3(-2.3, 0, -1.8)), n.to_global(Vector3(2.3, 0, -1.8)))
	Props.fence(w, n.to_global(Vector3(-2.3, 0, -1.8)), n.to_global(Vector3(-2.3, 0, 1.6)))
	return n.to_global(Vector3(0, 0, 0))
