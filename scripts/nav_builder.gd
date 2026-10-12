class_name NavBuilder
extends RefCounted
## Navigation meshes for the places where people walk (villages and towns). The level's static
## colliders are parsed once on the main thread (doors switched off, so doorways stay open), then
## every area is baked on a worker thread and added as a NavigationRegion3D when ready.
## Villagers and kids ask NavBuilder.path() for a route; until a region is baked (or outside one)
## they fall back to walking straight with obstacle steering.

const CELL := 0.25
const CELL_H := 0.1


static func build(w: Node3D, areas: Array) -> void:
	if areas.is_empty():
		return
	var map: RID = w.get_world_3d().navigation_map
	NavigationServer3D.map_set_cell_size(map, CELL)
	NavigationServer3D.map_set_cell_height(map, CELL_H)
	var template := _template()
	# doors would close the doorways: switch their colliders off while parsing
	var doors := []
	for d in w.get_tree().get_nodes_in_group("doors"):
		if d._shape and not d._shape.disabled:
			d._shape.disabled = true
			doors.append(d)
	var source := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(template, source, w)
	for d in doors:
		d._shape.disabled = false
	for a in areas:
		var c: Vector3 = a[0]
		var r: float = a[1]
		var nm := _template()
		var gy: float = w.ground(c.x, c.z)
		nm.filter_baking_aabb = AABB(Vector3(c.x - r, gy - 12.0, c.z - r), Vector3(r * 2.0, 40.0, r * 2.0))
		NavigationServer3D.bake_from_source_geometry_data_async(nm, source, _on_baked.bind(w, nm))


static func _template() -> NavigationMesh:
	var nm := NavigationMesh.new()
	nm.cell_size = CELL
	nm.cell_height = CELL_H
	nm.agent_radius = 0.5
	nm.agent_height = 1.6
	nm.agent_max_climb = 0.4
	nm.agent_max_slope = 42.0
	nm.region_min_size = 4.0
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_collision_mask = 1
	return nm


static func _on_baked(w: Node3D, nm: NavigationMesh) -> void:
	if not is_instance_valid(w) or not w.is_inside_tree():
		return
	var region := NavigationRegion3D.new()
	region.navigation_mesh = nm
	w.add_child(region)


## Route from a to b on the navigation mesh, or [] when there is none (not baked yet, outside the
## baked areas, or b unreachable).
static func path(w: Node3D, a: Vector3, b: Vector3) -> PackedVector3Array:
	var map: RID = w.get_world_3d().navigation_map
	if NavigationServer3D.map_get_iteration_id(map) == 0:
		return PackedVector3Array()
	var sa := NavigationServer3D.map_get_closest_point(map, a)
	var sb := NavigationServer3D.map_get_closest_point(map, b)
	if sa.distance_to(a) > 1.5 or sb.distance_to(b) > 1.5:
		return PackedVector3Array()
	var p := NavigationServer3D.map_get_path(map, sa, sb, true)
	if p.size() < 2 or p[-1].distance_to(sb) > 0.8:
		return PackedVector3Array()
	return p
