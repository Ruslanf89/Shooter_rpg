class_name Arms
extends RefCounted
## The arming sword (Vairek, CC0): carried by guards, captains and the King, and hung on the walls
## of the castle hall, the barracks and the smithy. The model is loaded once and shared.

const SWORD := "res://assets/models/weapons/arming_sword.glb"

static var _parts: Array = []
static var _box := AABB()


static func enabled() -> bool:
	return ResourceLoader.exists(SWORD)


static func _sword_parts() -> Array:
	if _parts.is_empty() and enabled():
		var root: Node = (load(SWORD) as PackedScene).instantiate()
		KitBuild._collect(root, Transform3D(), _parts)
		root.free()
		var first := true
		for p in _parts:
			var b: AABB = (p[1] as Transform3D) * (p[0] as Mesh).get_aabb()
			_box = b if first else _box.merge(b)
			first = false
	return _parts


## A sword `length` metres long in a "holder" frame: the grip at the origin, the blade along -Z
## (the hand convention used by Enemy._attach_gear). Returns its root node.
static func sword(parent: Node3D, length := 0.95, shadows := true) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	var parts := _sword_parts()
	if parts.is_empty():
		return root
	var s := length / maxf(_box.size.y, 0.01)
	# the model stands hilt down, blade up (+Y): grip a little above the pommel, then turn it so the
	# blade points along -Z
	var grip := Vector3(_box.get_center().x, _box.position.y + _box.size.y * 0.11, _box.get_center().z)
	var xf := Transform3D(Basis(Vector3.RIGHT, -PI * 0.5).scaled(Vector3.ONE * s), Vector3.ZERO)
	xf.origin = -(xf.basis * grip)
	for p in parts:
		var mi := MeshInstance3D.new()
		mi.mesh = p[0]
		mi.transform = xf * (p[1] as Transform3D)
		if not shadows:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
	return root


## Standing upright, tip up (e.g. in a weapon stand or rack), tilted `lean` degrees.
static func upright(parent: Node3D, pos: Vector3, yaw := 0.0, lean := 0.0, length := 0.95) -> Node3D:
	var holder := Node3D.new()
	parent.add_child(holder)
	holder.position = pos
	# tip up, and the flat of the blade (and the crossguard) facing forward, not edge-on
	holder.basis = Basis(Vector3.UP, deg_to_rad(yaw)) * Basis(Vector3.BACK, deg_to_rad(lean)) * Basis(Vector3.RIGHT, PI * 0.5) * Basis(Vector3.BACK, PI * 0.5)
	sword(holder, length, false)
	return holder


## A wall trophy: two crossed swords behind a round shield. `pos` is on the wall surface, the
## display faces local +Z (into the room).
static func wall_display(parent: Node3D, pos: Vector3, yaw := 0.0) -> void:
	var d := Node3D.new()
	parent.add_child(d)
	d.position = pos
	d.rotation.y = deg_to_rad(yaw)
	for s in [-1.0, 1.0]:
		# hilts below the shield, blades crossing behind it, tips showing above it
		upright(d, Vector3(s * 0.24, -0.62, 0.03), 0.0, s * 22.0, 1.2)
	if PropKit.enabled():
		PropKit.put(d, "Shield_Wooden", Vector3(0, 0, 0.07), 0.0, Vector3.ONE * 0.85, false, false)


## At the left hip of a person (People model), hanging down and a little back.
static func at_hip(model: Node3D, sk: Skeleton3D) -> void:
	var n := Node3D.new()
	var holder := Node3D.new()
	n.add_child(holder)
	holder.basis = Basis(Vector3.BACK, deg_to_rad(12.0)) * Basis(Vector3.RIGHT, deg_to_rad(-72.0))   # down, back, tip a little out
	sword(holder, 0.9, true)
	People._hang(model, sk, "pelvis", n, Vector3(0.36, 0.02, -0.02))
