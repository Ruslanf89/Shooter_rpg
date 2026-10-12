class_name MeshBatcher
extends RefCounted
## Merges the many small static primitive meshes of buildings and props (boxes, cylinders,
## spheres...) into one mesh per material per 48 m cell. Thousands of draw calls become a few
## hundred. Moving or interactive things (doors, chests, characters, spinning parts) are skipped.

const CELL := 48.0
const SKIP_TYPES := ["HouseDoor", "TreasureChest", "Enemy", "Villager", "Animal", "Player", "QuestGiver", "LootDrop",
	"GatherItem", "Projectile", "ExplosiveBarrel", "AmmoPickup", "Terrain", "AnimatableBody3D", "CPUParticles3D",
	"RigidBody3D", "Kid", "EscortNPC", "KidBall", "VesPortal", "DroneFlyer", "MaterialDrop", "GatherNode", "Skeleton3D", "Mirror3D", "SubViewport", "Tactics"]


static func bake(world: Node3D) -> int:
	var skip := {}
	for s in world.spinners:
		skip[s[0]] = true
	var groups := {}     # key -> {"mat", "shadow", "items": [[mesh, xform, MeshInstance3D]], "center"}
	var victims: Array = []
	var kits := {}       # kit pieces: key -> {"mesh", "shadow", "items": [[xform, MeshInstance3D]], "center"}
	_collect(world, world, skip, groups, victims, kits)
	var removed := 0
	# kit pieces become one MultiMesh per piece type per cell (surfaces and materials untouched)
	for key in kits:
		var k: Dictionary = kits[key]
		var origin: Vector3 = k["center"]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = k["mesh"]
		mm.instance_count = k["items"].size()
		for i in k["items"].size():
			var xf: Transform3D = k["items"][i][0]
			mm.set_instance_transform(i, Transform3D(xf.basis, xf.origin - origin))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.cast_shadow = k["shadow"]
		mmi.position = origin
		world.add_child(mmi)
		for it in k["items"]:
			(it[1] as Node).queue_free()
			removed += 1
	for key in groups:
		var g: Dictionary = groups[key]
		# a lone piece stays as it is (it was never removed)
		if g["items"].size() < 2:
			continue
		var origin: Vector3 = g["center"]
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for it in g["items"]:
			var xf: Transform3D = it[1]
			st.append_from(it[0], 0, Transform3D(xf.basis, xf.origin - origin))
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		mi.material_override = g["mat"]
		mi.cast_shadow = g["shadow"]
		mi.position = origin
		world.add_child(mi)
		for it in g["items"]:
			(it[2] as Node).queue_free()
			removed += 1
	_add_occluders(world, victims)
	return removed


## Big opaque boxes (walls, house bodies, ruins) also become occluders, so whatever is hidden
## behind them is not drawn (occlusion culling).
static func _add_occluders(world: Node3D, boxes: Array) -> void:
	for mi: MeshInstance3D in boxes:
		if not mi.mesh is BoxMesh:
			continue
		var m := mi.material_override
		if m is BaseMaterial3D and ((m as BaseMaterial3D).transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or (m as BaseMaterial3D).shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED):
			continue
		var size: Vector3 = (mi.mesh as BoxMesh).size * mi.global_transform.basis.get_scale()
		var dims := [size.x, size.y, size.z]
		dims.sort()
		if dims[1] < 2.0 or dims[2] < 2.5 or dims[0] < 0.15:
			continue
		var occ := OccluderInstance3D.new()
		var bo := BoxOccluder3D.new()
		bo.size = size * 0.96
		occ.occluder = bo
		world.add_child(occ)
		occ.global_transform = Transform3D(mi.global_transform.basis.orthonormalized(), mi.global_transform.origin)

static func _skip_node(n: Node, skip: Dictionary) -> bool:
	if skip.has(n):
		return true
	for t in SKIP_TYPES:
		if n.is_class(t):
			return true
	var sc = n.get_script()
	if sc:
		var gname: String = sc.get_global_name()
		if gname in SKIP_TYPES:
			return true
	return false


static func _collect(n: Node, world: Node3D, skip: Dictionary, groups: Dictionary, victims: Array, kits: Dictionary) -> void:
	for c in n.get_children():
		if _skip_node(c, skip):
			continue
		if c is MeshInstance3D:
			var mi := c as MeshInstance3D
			var special: bool = mi.material_override is ShaderMaterial and not str((mi.material_override as ShaderMaterial).shader.resource_path).ends_with("textured.gdshader")
			if mi.mesh is PrimitiveMesh and mi.material_override != null and not special and mi.visibility_range_end == 0.0 and mi.layers == 1 and mi.get_child_count() == 0:
				var xf := mi.global_transform
				var cell := Vector2i(floori(xf.origin.x / CELL), floori(xf.origin.z / CELL))
				var key := "%d_%d_%d_%d" % [cell.x, cell.y, mi.material_override.get_instance_id(), mi.cast_shadow]
				if not groups.has(key):
					groups[key] = {"mat": mi.material_override, "shadow": mi.cast_shadow, "items": [],
						"center": Vector3((cell.x + 0.5) * CELL, 0, (cell.y + 0.5) * CELL)}
				var arrays_mesh := ArrayMesh.new()
				arrays_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mi.mesh.get_mesh_arrays())
				groups[key]["items"].append([arrays_mesh, xf, mi, 0])
				victims.append(mi)
				continue
			# kit models (Medieval Village MegaKit, nature kit props): every surface goes to its material's batch
			if mi.mesh is ArrayMesh and mi.material_override == null and mi.skin == null and mi.skeleton == NodePath("") and mi.visibility_range_end == 0.0 \
					and mi.layers == 1 and mi.get_child_count() == 0 and mi.mesh.get_blend_shape_count() == 0:
				var xf := mi.global_transform
				var cell := Vector2i(floori(xf.origin.x / CELL), floori(xf.origin.z / CELL))
				var key := "%d_%d_%d_%d" % [cell.x, cell.y, mi.mesh.get_instance_id(), mi.cast_shadow]
				if not kits.has(key):
					kits[key] = {"mesh": mi.mesh, "shadow": mi.cast_shadow, "items": [],
						"center": Vector3((cell.x + 0.5) * CELL, 0, (cell.y + 0.5) * CELL)}
				kits[key]["items"].append([xf, mi])
				continue
		_collect(c, world, skip, groups, victims, kits)
