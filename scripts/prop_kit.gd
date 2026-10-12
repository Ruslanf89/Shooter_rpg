class_name PropKit
extends RefCounted
## Props and furniture from Quaternius' Fantasy Props MegaKit (CC0): barrels, crates, beds,
## tables, chairs, bookcases, anvils, cauldrons, market stalls, pickaxes, coins... Models are
## loaded once; each file's copies of the shared trim materials are merged by name so the batcher
## can combine everything. Falls back to the old box props when the kit is missing.

const DIR := "res://assets/models/props_kit/"

static var _parts := {}
static var _mats := {}


static func enabled() -> bool:
	return ResourceLoader.exists(DIR + "Barrel.gltf")


## [[mesh, transform], ...] of a kit model.
static func parts(name: String) -> Array:
	if _parts.has(name):
		return _parts[name]
	var out := []
	var path := DIR + name + ".gltf"
	if ResourceLoader.exists(path):
		var root: Node = (load(path) as PackedScene).instantiate()
		KitBuild._collect(root, Transform3D(), out)
		root.free()
	_parts[name] = out
	return out


static func aabb(name: String) -> AABB:
	var box := AABB()
	var first := true
	for p in parts(name):
		var a: AABB = (p[1] as Transform3D) * (p[0] as Mesh).get_aabb()
		box = a if first else box.merge(a)
		first = false
	return box


## Places a model under `parent` at local position `pos`, turned `yaw` degrees, scaled.
## collide: adds a box collider around it (on the parent, so it stays when meshes are batched).
static func put(parent: Node3D, name: String, pos: Vector3, yaw := 0.0, scl := Vector3.ONE, collide := false, shadows := true) -> void:
	var t := Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)).scaled_local(scl), pos)
	for p in parts(name):
		var mi := MeshInstance3D.new()
		mi.mesh = p[0]
		if name == "Bottle_1" and Glass.enabled():
			mi.material_override = Glass.bottle()
		mi.transform = t * (p[1] as Transform3D)
		if not shadows:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for i in mi.mesh.get_surface_count():
			var m: Material = mi.mesh.surface_get_material(i)
			if m:
				var key := String(m.resource_name)
				if not _mats.has(key):
					_mats[key] = m
				mi.set_surface_override_material(i, _mats[key])
		parent.add_child(mi)
	if collide:
		var b := aabb(name)
		var size := b.size * scl
		MeshKit.collider_box(parent, Vector3(maxf(size.x, 0.1), maxf(size.y, 0.1), maxf(size.z, 0.1)),
			pos + Basis(Vector3.UP, deg_to_rad(yaw)) * ((b.position + b.size * 0.5) * scl), Vector3(0, yaw, 0))


## A model on the ground in the world (its own pivot), optionally solid.
static func place(w: Node3D, name: String, p: Vector3, yaw := 0.0, scl := Vector3.ONE, collide := true) -> Node3D:
	var n := Props.pivot(w, p, yaw)
	put(n, name, Vector3.ZERO, 0.0, scl, collide)
	return n


## Scale that makes a model `size` big (x, y, z; 0 keeps that axis proportional to y).
static func fit(name: String, size: Vector3) -> Vector3:
	var s := aabb(name).size
	var sy := size.y / maxf(s.y, 0.01)
	return Vector3(size.x / maxf(s.x, 0.01) if size.x > 0.0 else sy, sy, size.z / maxf(s.z, 0.01) if size.z > 0.0 else sy)


## A few random small things to scatter on a table top or shelf (local, y = surface height).
static func table_clutter(parent: Node3D, center: Vector3, half: Vector2, rng: RandomNumberGenerator, count := 4) -> void:
	var items := ["Mug", "Table_Plate", "Bottle_1", "Candle_1", "Book_5", "Chalice", "Potion_2", "Coin_Pile", "Scroll_1", "Mug", "Table_Plate"]
	for i in count:
		var it: String = items[rng.randi() % items.size()]
		put(parent, it, center + Vector3(rng.randf_range(-half.x, half.x), 0.0, rng.randf_range(-half.y, half.y)), rng.randf() * 360.0, Vector3.ONE, false, false)


## Camp clutter around a point: bags, a pot, rope, a bucket, a crate or two.
static func camp_clutter(w: Node3D, center: Vector3, rng: RandomNumberGenerator, radius := 3.0) -> void:
	var items := ["Bag", "Pot_1_Lid", "Rope_2", "Bucket_Wooden_1", "Rope_1", "Bag", "Crate_Wooden", "Stool", "Chain_Coil", "Coin_Pile_2"]
	for i in 5:
		var a := rng.randf() * TAU
		var r := rng.randf_range(radius * 0.7, radius * 1.3)
		var it: String = items[rng.randi() % items.size()]
		place(w, it, center + Vector3(cos(a) * r, 0, sin(a) * r), rng.randf() * 360.0, Vector3.ONE, it in ["Crate_Wooden", "Bag", "Stool"])
