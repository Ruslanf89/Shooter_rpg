class_name TBuild
extends RefCounted
## Big-town buildings: the King's castle with its throne hall, a temple, the armorer, the
## alchemist, the tinker's workshop, town walls with gatehouses and towers, and the notice board.
## Same conventions as VBuild: position (y = height above ground), yaw in degrees, front = +z.

const T := Buildings.T
const F := Buildings.FLOOR


static func _stone(c := Color(0.92, 0.9, 0.86)) -> Material:
	return Props.stone(c, 0.45)


static func _g(n: Node3D, local: Vector3) -> Vector3:
	return n.to_global(local)


# --------------------------------------------------------------------------- castle

## The King's keep: a stone hall with corner towers and crenellations; inside, pillars, a red
## carpet up to the throne on a dais, banners, braziers and chandeliers.
static func castle(w: Node3D, p: Vector3, yaw: float) -> Dictionary:
	var n := Props.pivot(w, p, yaw)
	var sx := 20.0
	var sz := 16.0
	var h := 8.0
	var hx := sx * 0.5
	var hz := sz * 0.5
	var st := _stone()
	var dark_st := _stone(Color(0.7, 0.68, 0.66))
	var fl := MeshKit.static_box(n, Vector3(sx + T, F + 0.3, sz + T), Vector3(0, (F + 0.3) * 0.5, 0), dark_st)
	fl.set_meta("surface", "stone")
	var y0 := F + 0.3
	var f := Vector3(0, y0, 0)
	var win := []
	for i in 4:
		win.append([2.5 + i * 5.0, 1.0, 3.0, 6.2])
	var front := [[hx, 3.4, 0.0, 4.4], [3.0, 1.0, 3.0, 6.2], [sx - 3.0, 1.0, 3.0, 6.2]]
	var walls := [[Vector3(-hx, 0, hz), Vector3(hx, 0, hz), front], [Vector3(hx, 0, hz), Vector3(hx, 0, -hz), [[4.0, 1.0, 3.0, 6.2], [12.0, 1.0, 3.0, 6.2]]],
		[Vector3(hx, 0, -hz), Vector3(-hx, 0, -hz), win], [Vector3(-hx, 0, -hz), Vector3(-hx, 0, hz), [[4.0, 1.0, 3.0, 6.2], [12.0, 1.0, 3.0, 6.2]]]]
	var glass := MeshKit.mat(Color(0.35, 0.45, 0.85, 0.7), 0.1, 0.0, 0.4)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	KitBuild.window_variant = "stained"
	for wd in walls:
		var wp := Buildings.wall(n, wd[0] + f, wd[1] + f, h, wd[2], st, st, Props.dark_wood(), h, false)
		for o in wd[2]:
			if float(o[2]) > 0.01 and not KitBuild.enabled():
				MeshKit.box(wp, Vector3(float(o[1]), float(o[3]) - float(o[2]), 0.04), Vector3(float(o[0]) + T * 0.5, (float(o[2]) + float(o[3])) * 0.5, 0), glass)
	KitBuild.window_variant = ""
	# roof slab and crenellations
	MeshKit.static_box(n, Vector3(sx + 0.6, 0.4, sz + 0.6), Vector3(0, y0 + h + 0.2, 0), dark_st)
	var mx := -hx
	while mx <= hx:
		for s in [-1.0, 1.0]:
			MeshKit.box(n, Vector3(0.7, 0.8, 0.5), Vector3(mx, y0 + h + 0.8, s * (hz + 0.1)), st)
		mx += 1.4
	var mz := -hz
	while mz <= hz:
		for s in [-1.0, 1.0]:
			MeshKit.box(n, Vector3(0.5, 0.8, 0.7), Vector3(s * (hx + 0.1), y0 + h + 0.8, mz), st)
		mz += 1.4
	# corner towers with pointed roofs and flags
	var roof := Props.roof(Color(0.55, 0.15, 0.15))
	for cx in [-hx, hx]:
		for cz in [-hz, hz]:
			MeshKit.static_cyl(n, 2.4, h + 5.0, Vector3(cx, (h + 5.0) * 0.5, cz), st, 16)
			MeshKit.cyl(n, 0.0, 3.0, 4.0, Vector3(cx, h + 7.0, cz), roof, Vector3.ZERO, 16)
			MeshKit.cyl(n, 0.04, 0.04, 2.0, Vector3(cx, h + 10.0, cz), MeshKit.mat(Color(0.3, 0.3, 0.3), 0.4, 0.8), Vector3.ZERO, 6)
			MeshKit.box(n, Vector3(1.2, 0.7, 0.03), Vector3(cx + 0.6, h + 10.6, cz), MeshKit.mat(Color(0.2, 0.3, 0.7)))
	# open double doors and a gold crest above them
	for s in [-1.0, 1.0]:
		var dp := Node3D.new()
		dp.position = Vector3(s * 1.7, y0, hz + 0.1)
		dp.rotation_degrees.y = s * -100.0
		n.add_child(dp)
		MeshKit.static_box(dp, Vector3(1.7, 4.3, 0.15), Vector3(-s * 0.85, 2.15, 0), Props.dark_wood())
	MeshKit.cyl(n, 0.8, 0.8, 0.15, Vector3(0, y0 + 5.6, hz + 0.25), MeshKit.mat(Color(1.0, 0.8, 0.25), 0.3, 0.9), Vector3(90, 0, 0), 20)
	# steps up to the door
	for i in 3:
		MeshKit.static_box(n, Vector3(5.0, 0.15, 0.5), Vector3(0, 0.075 + i * 0.15, hz + 1.6 - i * 0.45), dark_st)
	# inside: pillars, carpet, dais, throne
	for row in [-1.0, 1.0]:
		for i in 4:
			MeshKit.static_cyl(n, 0.45, h, Vector3(row * 4.5, y0 + h * 0.5, -5.0 + i * 3.4), _stone(Color(0.85, 0.82, 0.78)), 12)
	var red := MeshKit.mat(Color(0.6, 0.08, 0.08), 0.9)
	MeshKit.box(n, Vector3(2.6, 0.02, sz - 3.0), Vector3(0, y0 + 0.01, 1.0), red)
	for i in 3:
		MeshKit.static_box(n, Vector3(7.0 - i * 1.2, 0.25, 3.2 - i * 0.6), Vector3(0, y0 + 0.125 + i * 0.25, -hz + 2.2 - i * 0.2), dark_st)
	var gold := MeshKit.mat(Color(1.0, 0.8, 0.25), 0.3, 0.9)
	var ty := y0 + 0.75
	MeshKit.static_box(n, Vector3(1.4, 0.5, 1.1), Vector3(0, ty + 0.25, -hz + 1.6), red)
	MeshKit.box(n, Vector3(1.5, 2.6, 0.25), Vector3(0, ty + 1.3, -hz + 1.0), red)
	MeshKit.box(n, Vector3(1.7, 0.2, 0.3), Vector3(0, ty + 2.7, -hz + 1.0), gold)
	for s in [-1.0, 1.0]:
		MeshKit.box(n, Vector3(0.18, 0.9, 1.1), Vector3(s * 0.75, ty + 0.55, -hz + 1.6), gold)
		MeshKit.sphere(n, 0.12, Vector3(s * 0.75, ty + 2.9, -hz + 1.0), gold)
	# banners
	for i in 3:
		for s in [-1.0, 1.0]:
			MeshKit.box(n, Vector3(0.05, 3.2, 1.2), Vector3(s * (hx - 0.2), y0 + 4.5, -4.5 + i * 4.5), MeshKit.mat([Color(0.6, 0.08, 0.08), Color(0.15, 0.22, 0.6)][i % 2]))
			MeshKit.box(n, Vector3(0.06, 0.5, 0.5), Vector3(s * (hx - 0.22), y0 + 5.0, -4.5 + i * 4.5), gold)
	MeshKit.box(n, Vector3(4.0, 4.5, 0.05), Vector3(0, y0 + 5.0, -hz + 0.2), MeshKit.mat(Color(0.15, 0.22, 0.6)))
	# crossed swords and shields between the banners, and a great mirror facing the throne
	if Arms.enabled():
		for z in [-2.25, 2.25]:
			for s in [-1.0, 1.0]:
				Arms.wall_display(n, Vector3(s * (hx - 0.25), y0 + 3.2, z), -90.0 * s)
	_hall_mirror(n, Vector3(-4.3, y0, hz - 0.3), 180.0)
	MeshKit.cyl(n, 1.0, 1.0, 0.06, Vector3(0, y0 + 5.6, -hz + 0.25), gold, Vector3(90, 0, 0), 20)
	# braziers and chandeliers
	for bp in [Vector3(-3.2, 0, -hz + 2.0), Vector3(3.2, 0, -hz + 2.0), Vector3(-2.2, 0, hz - 1.5), Vector3(2.2, 0, hz - 1.5)]:
		MeshKit.cyl(n, 0.05, 0.08, 1.1, Vector3(bp.x, y0 + 0.55 + (0.75 if bp.z < 0.0 else 0.0), bp.z), MeshKit.mat(Color(0.15, 0.15, 0.15), 0.4, 0.8), Vector3.ZERO, 8)
		MeshKit.cyl(n, 0.35, 0.15, 0.3, Vector3(bp.x, y0 + 1.25 + (0.75 if bp.z < 0.0 else 0.0), bp.z), MeshKit.mat(Color(0.15, 0.15, 0.15), 0.4, 0.8), Vector3.ZERO, 10)
		MeshKit.cyl(n, 0.0, 0.25, 0.45, Vector3(bp.x, y0 + 1.55 + (0.75 if bp.z < 0.0 else 0.0), bp.z), MeshKit.unshaded(Color(1.0, 0.55, 0.15)), Vector3.ZERO, 7)
		var fl2 := OmniLight3D.new()
		fl2.light_color = Color(1.0, 0.6, 0.3)
		fl2.omni_range = 6.0
		fl2.position = Vector3(bp.x, y0 + 1.9 + (0.75 if bp.z < 0.0 else 0.0), bp.z)
		n.add_child(fl2)
		w.fire_lights.append(fl2)
	for cz in [-2.0, 3.0]:
		Buildings.hanging_lamp(n, Vector3(0, y0 + h - 1.2, cz))
	w.building_areas.append([Vector2(n.global_position.x, n.global_position.z), 13.0])
	var guards := [_g(n, Vector3(-2.2, y0, -hz + 3.6)), _g(n, Vector3(2.2, y0, -hz + 3.6)), _g(n, Vector3(-3.0, 0, hz + 3.0)), _g(n, Vector3(3.0, 0, hz + 3.0))]
	return {"node": n, "king": _g(n, Vector3(0, ty + 0.05, -hz + 2.3)), "king_yaw": n.rotation.y, "guards": guards,
		"herald": _g(n, Vector3(-3.6, 0, hz + 2.6)), "herald_yaw": n.rotation.y}


## A tall gilded mirror (Mirror3D addon) - it reflects the hall in real time, but only while you
## are close (it freezes beyond 18 m, and renders at most 30 times a second).
static func _hall_mirror(n: Node3D, pos: Vector3, yaw: float) -> void:
	var gold := MeshKit.mat(Color(1.0, 0.8, 0.25), 0.3, 0.9)
	var m := Node3D.new()
	n.add_child(m)
	m.position = pos
	m.rotation.y = deg_to_rad(yaw)
	var w := 1.5
	var h := 2.6
	MeshKit.static_box(m, Vector3(w + 0.3, h + 0.3, 0.12), Vector3(0, h * 0.5 + 0.15, -0.04), gold)
	MeshKit.sphere(m, 0.16, Vector3(0, h + 0.4, 0.0), gold)
	if ResourceLoader.exists("res://addons/Mirror3D/Mirror3D.tscn"):
		var mirror: Node3D = (load("res://addons/Mirror3D/Mirror3D.tscn") as PackedScene).instantiate()
		mirror.set("size", Vector2(w, h))
		mirror.set("pixels_per_unit", 160)
		mirror.set("freeze_distance", 18.0)
		mirror.set("max_fps", 30.0)
		mirror.set("cull_far", 25.0)
		mirror.set("color", Color(0.92, 0.95, 0.97))
		m.add_child(mirror)
		mirror.position = Vector3(0, h * 0.5 + 0.15, 0.03)
	else:
		MeshKit.box(m, Vector3(w, h, 0.02), Vector3(0, h * 0.5 + 0.15, 0.03), MeshKit.mat(Color(0.75, 0.8, 0.85), 0.05, 0.9))


const HERO_STATUE := "res://assets/models/statue/hero_statue.res"


## Kingsreach square: a bronze hero on a stone pedestal with steps and four braziers.
static func hero_statue(w: Node3D, p: Vector3, yaw: float) -> void:
	var n := Props.pivot(w, p, yaw)
	var st := _stone(Color(0.85, 0.83, 0.8))
	for i in 3:
		var s := 4.6 - i * 0.9
		MeshKit.static_box(n, Vector3(s, 0.3, s), Vector3(0, 0.15 + i * 0.3, 0), st)
	MeshKit.static_box(n, Vector3(1.9, 1.5, 1.9), Vector3(0, 0.9 + 0.75, 0), st)
	MeshKit.box(n, Vector3(2.1, 0.15, 2.1), Vector3(0, 2.47, 0), st)
	MeshKit.box(n, Vector3(0.9, 0.3, 0.04), Vector3(0, 1.6, 0.97), MeshKit.mat(Color(0.75, 0.55, 0.25), 0.35, 0.9))
	var mesh: Mesh = load(HERO_STATUE)
	var bronze := StandardMaterial3D.new()
	bronze.albedo_color = Color(0.55, 0.38, 0.22)
	bronze.metallic = 0.85
	bronze.roughness = 0.38
	bronze.normal_enabled = true
	bronze.normal_texture = load("res://assets/models/statue/hero_statue_normal.png")
	var h := mesh.get_aabb().size.y
	var s := 3.4 / h
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = bronze
	mi.scale = Vector3.ONE * s
	mi.position = Vector3(0, 2.55 - mesh.get_aabb().position.y * s, 0)
	n.add_child(mi)
	MeshKit.collider_box(n, Vector3(1.2, 3.4, 1.0), Vector3(0, 2.55 + 1.7, 0))
	for i in 4:
		var a := TAU * i / 4.0 + PI * 0.25
		Props.torch(w, p + Vector3(cos(a), 0, sin(a)) * 3.0, Color(1.0, 0.65, 0.3))


# --------------------------------------------------------------------------- temple

static func temple(w: Node3D, p: Vector3, yaw: float) -> Dictionary:
	var n := Props.pivot(w, p, yaw)
	var sx := 14.0
	var sz := 10.0
	var h := 6.0
	var st := _stone(Color(0.95, 0.93, 0.88))
	var ops := {"front": [[2.5, 1.0, 2.2, 4.8], [11.5, 1.0, 2.2, 4.8]], "left": [[3.0, 1.0, 2.2, 4.8], [7.0, 1.0, 2.2, 4.8]],
		"right": [[3.0, 1.0, 2.2, 4.8], [7.0, 1.0, 2.2, 4.8]], "back": [[4.0, 1.0, 2.2, 4.8], [10.0, 1.0, 2.2, 4.8]]}
	KitBuild.window_variant = "stained"
	var r := VBuild.shell(w, n, sx, sz, h, ops, st, Color(0.3, 0.32, 0.45), true, true, false)
	KitBuild.window_variant = ""
	var hz: float = r["hz"]
	var cols := [Color(0.9, 0.2, 0.2), Color(0.2, 0.4, 0.95), Color(0.95, 0.8, 0.2), Color(0.3, 0.8, 0.35)]
	# coloured glass in every window
	var k := 0
	for side in ops:
		for o in ops[side]:
			var gm := MeshKit.mat(cols[k % cols.size()], 0.1, 0.0, 0.8)
			k += 1
			var lp := Vector3.ZERO
			var rot := 0.0
			match side:
				"front": lp = Vector3(-sx * 0.5 + float(o[0]), F + 3.5, hz)
				"back": lp = Vector3(sx * 0.5 - float(o[0]), F + 3.5, -hz)
				"left":
					lp = Vector3(-sx * 0.5, F + 3.5, -hz + float(o[0]))
					rot = 90.0
				"right":
					lp = Vector3(sx * 0.5, F + 3.5, hz - float(o[0]))
					rot = 90.0
			MeshKit.box(n, Vector3(1.0, 2.6, 0.04), lp, gm, Vector3(0, rot, 0))
	# altar, candles, pews
	var gold := MeshKit.mat(Color(1.0, 0.8, 0.25), 0.3, 0.9)
	MeshKit.static_box(n, Vector3(3.0, 1.0, 1.0), Vector3(0, F + 0.5, -hz + 1.4), _stone(Color(0.98, 0.96, 0.9)))
	MeshKit.box(n, Vector3(3.1, 0.06, 1.1), Vector3(0, F + 1.03, -hz + 1.4), MeshKit.mat(Color(0.75, 0.1, 0.12)))
	MeshKit.box(n, Vector3(0.12, 1.4, 0.12), Vector3(0, F + 1.8, -hz + 1.2), gold)
	MeshKit.box(n, Vector3(0.7, 0.12, 0.12), Vector3(0, F + 2.15, -hz + 1.2), gold)
	for i in 6:
		Buildings.candle(n, Vector3(-1.2 + i * 0.48, F + 1.06, -hz + 1.6), i % 2 == 0)
	for row in 4:
		for s in [-1.0, 1.0]:
			MeshKit.static_box(n, Vector3(3.6, 0.08, 0.5), Vector3(s * 2.6, F + 0.45, -0.5 + row * 1.5), Props.wood())
			MeshKit.box(n, Vector3(3.6, 0.5, 0.06), Vector3(s * 2.6, F + 0.75, -0.25 + row * 1.5), Props.dark_wood())
	# a small bell spire on the roof
	MeshKit.static_box(n, Vector3(1.6, 3.0, 1.6), Vector3(0, F + h + 3.5, hz - 1.0), st)
	MeshKit.cyl(n, 0.0, 1.3, 2.4, Vector3(0, F + h + 6.2, hz - 1.0), Props.roof(Color(0.3, 0.32, 0.45)), Vector3.ZERO, 4)
	MeshKit.cyl(n, 0.3, 0.4, 0.5, Vector3(0, F + h + 3.0, hz - 1.0), gold, Vector3.ZERO, 12)
	VBuild._sign(n, Vector3(1.6, F + 2.9, hz + 0.25), Loc.t("Temple"), Color(1.0, 0.95, 0.75))
	w.building_areas.append([Vector2(n.global_position.x, n.global_position.z), 9.0])
	return {"node": n, "work": [_g(n, Vector3(0, F, -hz + 2.6)), n.rotation.y + PI, "idle"], "door": r.get("door")}


# --------------------------------------------------------------------------- shops

static func armorer(w: Node3D, p: Vector3, yaw: float) -> Dictionary:
	var n := Props.pivot(w, p, yaw)
	var r := VBuild.shell(w, n, 9.0, 7.0, 3.6, {"front": [[1.6, 1.1, 1.0, 2.3], [7.4, 1.1, 1.0, 2.3]], "left": [[3.5, 1.0, 1.0, 2.3]]},
		VBuild._plaster(Color(0.85, 0.82, 0.78)), Color(0.4, 0.4, 0.45), true, true, true)
	var hz: float = r["hz"]
	MeshKit.static_box(n, Vector3(4.5, 1.05, 0.6), Vector3(0, F + 0.52, -0.6), Props.dark_wood())
	var steel := MeshKit.mat(Color(0.6, 0.62, 0.66), 0.3, 0.85)
	for i in 3:
		var sp := Vector3(-3.0 + i * 3.0, F, -2.6)
		MeshKit.cyl(n, 0.04, 0.04, 1.2, sp + Vector3(0, 0.6, 0), Props.dark_wood(), Vector3.ZERO, 6)
		MeshKit.box(n, Vector3(0.55, 0.65, 0.3), sp + Vector3(0, 1.35, 0), steel)
		MeshKit.sphere(n, 0.17, sp + Vector3(0, 1.85, 0), steel, Vector3(1, 0.9, 1.1))
		MeshKit.box(n, Vector3(0.8, 0.12, 0.3), sp + Vector3(0, 1.62, 0), steel)
	Buildings.hanging_lamp(n, Vector3(0, F + 3.3, 0.5))
	VBuild._sign(n, Vector3(1.6, F + 2.9, hz + 0.25), Loc.t("Armorer"), Color(0.85, 0.9, 1.0))
	w.building_areas.append([Vector2(n.global_position.x, n.global_position.z), 6.0])
	return {"node": n, "trader": _g(n, Vector3(0, F, -1.6)), "trader_yaw": n.rotation.y}


static func alchemist(w: Node3D, p: Vector3, yaw: float) -> Dictionary:
	var n := Props.pivot(w, p, yaw)
	var r := VBuild.shell(w, n, 9.0, 7.0, 3.6, {"front": [[1.6, 1.1, 1.0, 2.3], [7.4, 1.1, 1.0, 2.3]], "right": [[3.5, 1.0, 1.0, 2.3]]},
		VBuild._plaster(Color(0.78, 0.88, 0.8)), Color(0.3, 0.45, 0.35), true, true, true)
	var hz: float = r["hz"]
	MeshKit.static_box(n, Vector3(4.0, 1.05, 0.6), Vector3(0.8, F + 0.52, -0.6), Props.dark_wood())
	for i in 2:
		Buildings.shelf(n, Vector3(-1.5 + i * 3.0, F, -3.1), 0.0, RandomNumberGenerator.new())
	var st := CraftStation.new()
	st.world = w
	st.kind = "alchemy"
	n.add_child(st)
	st.position = Vector3(-3.1, F, 1.0)
	st.rotation_degrees.y = 90.0
	Buildings.hanging_lamp(n, Vector3(0, F + 3.3, 0.5))
	VBuild._sign(n, Vector3(1.6, F + 2.9, hz + 0.25), Loc.t("Alchemist"), Color(0.6, 1.0, 0.6))
	w.building_areas.append([Vector2(n.global_position.x, n.global_position.z), 6.0])
	return {"node": n, "trader": _g(n, Vector3(0.8, F, -1.6)), "trader_yaw": n.rotation.y}


static func workshop(w: Node3D, p: Vector3, yaw: float) -> Dictionary:
	var n := Props.pivot(w, p, yaw)
	var r := VBuild.shell(w, n, 10.0, 7.0, 3.8, {"front": [[2.0, 1.0, 1.0, 2.3]], "left": [[3.5, 1.0, 1.0, 2.3]]},
		VBuild._plaster(Color(0.8, 0.78, 0.72)), Color(0.35, 0.35, 0.38), true, true, true)
	var hz: float = r["hz"]
	var st := CraftStation.new()
	st.world = w
	st.kind = "workbench"
	n.add_child(st)
	st.position = Vector3(0.5, F, -2.6)
	var forge := CraftStation.new()
	forge.world = w
	forge.kind = "forge"
	n.add_child(forge)
	forge.position = Vector3(3.2, F, 0.6)
	forge.rotation_degrees.y = -90.0
	TechProps.loop_sound(n, "generator", -18.0, 14.0)
	VBuild._sign(n, Vector3(1.6, F + 2.9, hz + 0.25), Loc.t("Workshop"), Color(0.55, 0.9, 1.0))
	w.building_areas.append([Vector2(n.global_position.x, n.global_position.z), 6.5])
	return {"node": n, "work": [_g(n, Vector3(0.5, F, -1.6)), n.rotation.y + PI, "work"]}


# --------------------------------------------------------------------------- walls and the board

## Town wall on a circle of radius r around c, with gatehouses at `gates` (angles, radians).
static func town_wall(w: Node3D, c: Vector3, r: float, gates: Array) -> void:
	var st := _stone(Color(0.85, 0.83, 0.8))
	var seg := 6.0
	var count := int(TAU * r / seg)
	for i in count:
		var a := TAU * (i + 0.5) / count
		var gate_near := false
		for g: float in gates:
			if absf(wrapf(a - g, -PI, PI)) * r < 6.5:
				gate_near = true
		if gate_near:
			continue
		var pos := c + Vector3(sin(a), 0, cos(a)) * r
		var n := Props.pivot(w, pos, rad_to_deg(a))
		var len := TAU * r / count + 0.25
		MeshKit.static_box(n, Vector3(len, 6.5, 1.4), Vector3(0, 2.9, 0), st)
		for m in 4:
			MeshKit.box(n, Vector3(0.75, 0.8, 0.5), Vector3(-len * 0.5 + (m + 0.5) * len / 4.0, 6.55, 0.5), st)
		if i % 9 == 0:
			MeshKit.static_cyl(n, 2.2, 9.0, Vector3(0, 4.0, 0), st, 14)
			MeshKit.cyl(n, 0.0, 2.7, 3.0, Vector3(0, 10.0, 0), Props.roof(Color(0.5, 0.2, 0.18)), Vector3.ZERO, 14)
	for g: float in gates:
		VBuild.gatehouse(w, c + Vector3(sin(g), 0, cos(g)) * r, rad_to_deg(g))


static func notice_board(w: Node3D, p: Vector3, yaw: float) -> NoticeBoard:
	var b := NoticeBoard.new()
	b.world = w
	var gp := Props.ground_at(w, p)
	b.position = gp
	b.rotation_degrees.y = yaw
	w.add_child(b)
	return b
