class_name Cave
extends Node3D
## An enterable cave: a timber-shored tunnel into a hill and a big domed chamber with glowing
## crystals, stalagmites, ore veins, a treasure chest and whatever lives there. Built on top of
## the terrain (the hill is rock around it). The pivot is at the mouth; the tunnel runs along -z.
## Inside, the world's light dims (world.cave_dim) so it feels like a cave; bring a flashlight.

const TUNNEL_LEN := 20.0
const HALF_W := 2.2
const TUNNEL_H := 3.8
const CHAMBER_R := 10.0
const DOME_H := 7.6

var world: Node
var chamber_center := Vector3.ZERO   # local
var _inside := false


static func create(w: Node3D, mouth: Vector3, yaw: float, seed_value := 1) -> Cave:
	var c := Cave.new()
	c.world = w
	c.position = Vector3(mouth.x, w.ground(mouth.x, mouth.z), mouth.z)
	c.rotation.y = yaw
	w.add_child(c)
	c._build(seed_value)
	return c


## Where the chamber is in the world (for spawns and treasure).
func chamber_point(local_offset := Vector3.ZERO) -> Vector3:
	return to_global(chamber_center + local_offset)


func _build(seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var rock: Material = Props.rock_mat(Color(0.85, 0.8, 0.72))
	var dark_rock: Material = Props.rock_mat(Color(0.55, 0.52, 0.48))
	var wood := Props.dark_wood()
	var iron := MeshKit.mat(Color(0.3, 0.3, 0.32), 0.5, 0.6)
	chamber_center = Vector3(0, 0, -TUNNEL_LEN - CHAMBER_R)
	# --- tunnel: rough rock walls and ceiling, timber frames, rails
	var z := -1.0
	while z > -TUNNEL_LEN - 1.0:
		for s in [-1.0, 1.0]:
			var wx: float = s * (HALF_W + 0.7 + rng.randf_range(-0.1, 0.25))
			MeshKit.static_box(self, Vector3(1.4, TUNNEL_H + 0.8, 2.9), Vector3(wx, (TUNNEL_H + 0.8) * 0.5, z), rock, Vector3(0, rng.randf_range(-7, 7), rng.randf_range(-3, 3)))
		MeshKit.static_box(self, Vector3(HALF_W * 2.0 + 2.4, 1.1, 2.9), Vector3(0, TUNNEL_H + 0.5 + rng.randf_range(-0.1, 0.15), z), dark_rock, Vector3(rng.randf_range(-3, 3), 0, rng.randf_range(-4, 4)))
		z -= 2.5
	var f := -2.0
	while f > -TUNNEL_LEN:
		for s in [-1.0, 1.0]:
			MeshKit.static_box(self, Vector3(0.28, TUNNEL_H - 0.2, 0.28), Vector3(s * (HALF_W - 0.15), (TUNNEL_H - 0.2) * 0.5, f), wood)
		MeshKit.box(self, Vector3(HALF_W * 2.0, 0.32, 0.34), Vector3(0, TUNNEL_H - 0.3, f), wood)
		f -= 5.0
	for s in [-0.6, 0.6]:
		MeshKit.box(self, Vector3(0.08, 0.08, TUNNEL_LEN + 6.0), Vector3(s, 0.1, -TUNNEL_LEN * 0.5 - 2.0), iron)
	var t := 0.0
	while t < TUNNEL_LEN + 5.0:
		MeshKit.box(self, Vector3(1.7, 0.08, 0.3), Vector3(0, 0.04, -t), wood)
		t += 1.4
	# the mouth: a timber portal
	for s in [-1.0, 1.0]:
		MeshKit.static_box(self, Vector3(0.45, 4.4, 0.45), Vector3(s * (HALF_W + 0.1), 2.2, 0.0), wood)
	MeshKit.box(self, Vector3(HALF_W * 2.0 + 1.2, 0.55, 0.6), Vector3(0, 4.3, 0.0), wood)
	# --- chamber: a ring of rock walls under a dome
	var c := chamber_center
	var n_walls := 20
	for i in n_walls:
		var a := TAU * (i + 0.5) / n_walls
		var dir := Vector3(sin(a), 0, cos(a))
		# leave the opening towards the tunnel (+z from the chamber centre)
		if dir.z > 0.0 and absf(dir.x) * CHAMBER_R < HALF_W + 0.6:
			continue
		var p := c + dir * (CHAMBER_R + 0.8)
		var chord := TAU * (CHAMBER_R + 0.8) / n_walls + 0.6
		MeshKit.static_box(self, Vector3(chord, DOME_H + 1.0, 1.6), p + Vector3(0, (DOME_H + 1.0) * 0.5, 0), rock, Vector3(rng.randf_range(-3, 3), rad_to_deg(a), 0))
	# fill the corners where the tunnel meets the chamber
	for s in [-1.0, 1.0]:
		MeshKit.static_box(self, Vector3(2.4, TUNNEL_H + 1.0, 3.0), Vector3(s * (HALF_W + 1.4), (TUNNEL_H + 1.0) * 0.5, -TUNNEL_LEN - 0.6), rock)
	MeshKit.static_box(self, Vector3(HALF_W * 2.0 + 2.0, DOME_H - TUNNEL_H + 1.0, 2.0), Vector3(0, TUNNEL_H + (DOME_H - TUNNEL_H + 1.0) * 0.5, -TUNNEL_LEN - 0.6), rock)
	# dome seen from inside, plus a solid roof
	var dome_mat := StandardMaterial3D.new()
	dome_mat.albedo_texture = MeshKit.tex("Rock030")
	dome_mat.albedo_color = Color(0.62, 0.58, 0.52)
	dome_mat.uv1_triplanar = true
	dome_mat.uv1_world_triplanar = true
	dome_mat.uv1_scale = Vector3(0.25, 0.25, 0.25)
	dome_mat.roughness = 0.95
	dome_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	MeshKit.inst(self, _dome_mesh(CHAMBER_R + 0.6, DOME_H), c, dome_mat)
	MeshKit.static_box(self, Vector3(CHAMBER_R * 2.0 + 4.0, 1.2, CHAMBER_R * 2.0 + 4.0), c + Vector3(0, DOME_H + 0.7, 0), dark_rock)
	# --- the hill over it all: rocky mounds hiding the walls (solid, so nobody walks into them)
	var hill: Material = Props.rock_mat(Color(1.25, 1.15, 1.0))
	var zz := -2.5
	while zz > -TUNNEL_LEN - 2.0:
		for s in [-1.0, 1.0]:
			var r := rng.randf_range(4.5, 6.0)
			MeshKit.static_sphere(self, r, Vector3(s * (r + 2.6), rng.randf_range(-0.5, 1.0), zz), hill)
		var rt := rng.randf_range(3.5, 4.5)
		MeshKit.sphere(self, rt, Vector3(rng.randf_range(-1, 1), TUNNEL_H + 0.6 + rt * 0.8, zz - 1.0), hill, Vector3(1.5, 0.8, 1.2))
		zz -= 4.0
	for i in 10:
		var a := TAU * (i + 0.5) / 10.0
		if cos(a) > 0.6:
			continue   # the tunnel side
		var r := rng.randf_range(6.5, 8.5)
		MeshKit.static_sphere(self, r, c + Vector3(sin(a), 0, cos(a)) * (CHAMBER_R + r + 0.4) + Vector3(0, rng.randf_range(-1.5, 1.0), 0), hill)
	MeshKit.sphere(self, 13.5, c + Vector3(0, DOME_H + 1.0 + 13.5 * 0.42, 0), hill, Vector3(1.0, 0.42, 1.0))
	MeshKit.sphere(self, 8.0, c + Vector3(0, DOME_H + 2.2, CHAMBER_R + 2.0), hill, Vector3(1.0, 0.6, 1.0))
	# --- inside the chamber: stalagmites, stalactites, crystals, a cart, light
	for i in 9:
		var a := rng.randf() * TAU
		var r := rng.randf_range(4.0, CHAMBER_R - 1.5)
		var h := rng.randf_range(0.8, 2.6)
		var p := c + Vector3(sin(a), 0, cos(a)) * r
		if p.z > c.z + CHAMBER_R - 3.0 and absf(p.x) < 3.0:
			continue
		var base_r := rng.randf_range(0.35, 0.7)
		MeshKit.cyl(self, 0.04, base_r, h, p + Vector3(0, h * 0.5, 0), dark_rock, Vector3.ZERO, 8)
		MeshKit.collider_box(self, Vector3(base_r * 1.2, h, base_r * 1.2), p + Vector3(0, h * 0.5, 0))
	for i in 12:
		var a := rng.randf() * TAU
		var r := rng.randf_range(2.0, CHAMBER_R - 2.0)
		var h := rng.randf_range(0.8, 2.2)
		var top := DOME_H * sqrt(maxf(0.0, 1.0 - pow(r / (CHAMBER_R + 0.6), 2.0)))
		MeshKit.cyl(self, 0.25, 0.0, h, c + Vector3(sin(a) * r, top - h * 0.5, cos(a) * r), dark_rock, Vector3.ZERO, 7)
	var cols := [Color(0.55, 0.3, 1.0), Color(0.3, 0.7, 1.0), Color(0.4, 1.0, 0.75)]
	for i in 7:
		var a := TAU * i / 7.0 + 0.3
		var r := CHAMBER_R - rng.randf_range(0.6, 1.4)
		var p := c + Vector3(sin(a), 0, cos(a)) * r
		if p.z > c.z + CHAMBER_R - 3.0 and absf(p.x) < 3.5:
			continue
		var col: Color = cols[i % cols.size()]
		var cm := MeshKit.mat(col, 0.2, 0.0, 2.5)
		for k in 5:
			var prism := PrismMesh.new()
			prism.size = Vector3(0.25, rng.randf_range(0.6, 1.4), 0.25)
			MeshKit.inst(self, prism, p + Vector3(rng.randf_range(-0.4, 0.4), prism.size.y * 0.5, rng.randf_range(-0.4, 0.4)), cm, Vector3(rng.randf_range(-25, 25), rng.randf() * 90, rng.randf_range(-25, 25)))
		var l := OmniLight3D.new()
		l.light_color = col
		l.light_energy = 1.6
		l.omni_range = 6.5
		l.position = p + Vector3(0, 1.0, 0)
		add_child(l)
	# an overturned ore cart at the end of the rails
	var cart := Node3D.new()
	cart.position = c + Vector3(1.8, 0.5, CHAMBER_R - 3.0)
	cart.rotation_degrees = Vector3(0, 30, 75)
	add_child(cart)
	MeshKit.box(cart, Vector3(1.4, 0.9, 1.1), Vector3.ZERO, MeshKit.mat(Color(0.42, 0.29, 0.16)))
	# torches along the tunnel
	for tz in [-5.0, -12.0, -19.0]:
		for s in [-1.0, 1.0]:
			if (tz == -12.0) == (s > 0.0):
				continue
			var tl := OmniLight3D.new()
			tl.light_color = Color(1.0, 0.6, 0.3)
			tl.light_energy = 1.6
			tl.omni_range = 7.0
			tl.position = Vector3(s * (HALF_W - 0.3), 2.4, tz)
			add_child(tl)
			world.fire_lights.append(tl)
			if PropKit.enabled():
				PropKit.put(self, "Torch_Metal", Vector3(s * (HALF_W - 0.02), 2.0, tz), -90.0 * s)
				MeshKit.sphere(self, 0.08, Vector3(s * (HALF_W - 0.2), 2.42, tz), MeshKit.unshaded(Color(1.0, 0.6, 0.2)), Vector3(1, 1.6, 1))
			else:
				MeshKit.cyl(self, 0.04, 0.05, 0.5, Vector3(s * (HALF_W - 0.1), 2.0, tz), wood, Vector3(0, 0, s * -20.0), 6)
				MeshKit.sphere(self, 0.09, Vector3(s * (HALF_W - 0.22), 2.3, tz), MeshKit.unshaded(Color(1.0, 0.6, 0.2)))
	# no grass or trees inside
	for gp in [Vector3(0, 0, -TUNNEL_LEN * 0.5), c]:
		var g := to_global(gp)
		world.building_areas.append([Vector2(g.x, g.z), CHAMBER_R + 2.0 if gp == c else TUNNEL_LEN * 0.6])
	_furnish()


## The chamber's rock dome seen from inside (normals point inwards), with a hole where the
## tunnel comes in - a closed dome would hide the way out behind a rock you can walk through.
func _dome_mesh(r: float, h: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg := 36
	var rings := 12
	var pt := func(i: int, j: int) -> Vector3:
		var a := TAU * i / seg
		var e := PI * 0.5 * j / rings
		return Vector3(sin(a) * cos(e) * r, sin(e) * h, cos(a) * cos(e) * r)
	for j in rings:
		for i in seg:
			var q: Array[Vector3] = [pt.call(i, j), pt.call(i + 1, j), pt.call(i + 1, j + 1), pt.call(i, j + 1)]
			var mid: Vector3 = (q[0] + q[1] + q[2] + q[3]) * 0.25
			# the tunnel mouth (towards +z, up to a little over the tunnel's height)
			if mid.z > 0.0 and absf(mid.x) < HALF_W + 0.9 and mid.y < TUNNEL_H + 0.8:
				continue
			for k in [0, 2, 1, 0, 3, 2]:
				var v: Vector3 = q[k]
				st.set_normal(-Vector3(v.x / (r * r), v.y / (h * h), v.z / (r * r)).normalized())
				st.add_vertex(v)
	return st.commit()


## Ore veins and a treasure chest in the chamber.
func _furnish() -> void:
	for i in 3:
		var a := TAU * i / 3.0 + 1.0
		var g := GatherNode.new()
		g.world = world
		g.kind = "ore"
		var p := chamber_point(Vector3(sin(a), 0, cos(a)) * (CHAMBER_R - 2.2))
		g.position = Vector3(p.x, world.ground(p.x, p.z), p.z)
		world.add_child(g)
	var chest := TreasureChest.new()
	chest.world = world
	world.add_child(chest)
	chest.global_position = world.free_spot(chamber_point(Vector3(0, 0, -CHAMBER_R + 3.0)), 0.7, 1.0)
	chest.rotation.y = rotation.y
	if not PropKit.enabled():
		return
	# miners' leftovers: tools, rope, chains, crates, buckets, and coins spilled by the chest
	var c := chamber_center
	for it in [["Crate_Wooden", Vector3(1.5, 0, -3.0), 10.0, true], ["Crate_Wooden", Vector3(1.6, 0.93, -3.1), 35.0, false],
			["Pickaxe_Bronze", Vector3(-1.85, 0.5, -7.0), 90.0, false], ["Rope_3", Vector3(1.4, 0, -10.5), 0.0, false],
			["Bucket_Metal", Vector3(-1.5, 0, -14.0), 40.0, false], ["Barrel", Vector3(1.6, 0, -17.0), 0.0, true],
			["Chain_Coil", c + Vector3(-4.0, 0, 3.0), 20.0, false], ["Pickaxe_Bronze", c + Vector3(5.5, 0.5, 2.0), 0.0, false],
			["Rope_2", c + Vector3(3.0, 0, 5.5), 60.0, false], ["Crate_Metal", c + Vector3(-6.0, 0, -2.0), 15.0, true],
			["Vase_Rubble_Medium", c + Vector3(-2.5, 0, -6.0), 0.0, false], ["Vase_2", c + Vector3(-3.5, 0, -6.6), 0.0, true],
			["Bag", c + Vector3(6.0, 0, -3.0), 120.0, true], ["Cage_Small", c + Vector3(4.8, 0, -5.4), 30.0, true]]:
		PropKit.put(self, it[0], it[1], it[2], Vector3.ONE, it[3])
	var cp := to_local(chest.global_position)
	for k in 4:
		PropKit.put(self, ["Coin_Pile", "Coin_Pile_2"][k % 2], cp + Vector3(-0.9 + k * 0.6, 0, 0.8 + (k % 2) * 0.3), k * 47.0, Vector3.ONE, false, false)


func _process(delta: float) -> void:
	var p: Player = world.player
	if p == null:
		return
	var lp := to_local(p.global_position)
	var inside := (absf(lp.x) < HALF_W + 0.4 and lp.z < 0.5 and lp.z > -TUNNEL_LEN - 1.0 and lp.y < TUNNEL_H + 1.0) \
		or (Vector2(lp.x - chamber_center.x, lp.z - chamber_center.z).length() < CHAMBER_R + 0.5 and lp.y < DOME_H + 1.0)
	# dim more the deeper you go
	var depth := clampf(-lp.z / 8.0, 0.0, 1.0) if inside else 0.0
	var target := lerpf(1.0, 0.12, depth)
	world.cave_dim = move_toward(world.cave_dim, target, delta * 1.5)
	if inside and not _inside:
		world.hud.show_message(Loc.t("A cave. It's dark in here - [L] flashlight"), Color(0.8, 0.85, 1.0), 3.0)
	_inside = inside
