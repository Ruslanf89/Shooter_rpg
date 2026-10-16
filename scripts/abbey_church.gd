class_name AbbeyChurch
extends Node3D
## Root of the editable abbey church scene (scenes/buildings/abbey_church.scn, made by
## scenes/editor/bake_church.tscn). Edit it in Godot like any scene: move, rotate, scale, copy or
## delete parts, hide them, add your own models. In the game the church's parts are merged into one
## mesh per material and one collision shape, so all those separate parts cost nothing.

@export var merge_in_game := true


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_fix_glass(self)
	if merge_in_game:
		_merge()


## The glass and the walls tell inside from outside: tell them where the church stands now.
func _fix_glass(n: Node) -> void:
	for c in n.get_children():
		if c is MeshInstance3D:
			var m := (c as MeshInstance3D).material_override as ShaderMaterial
			if m and m.shader and (m.shader.resource_path.ends_with("stained_glass.gdshader") or m.shader.resource_path.ends_with("church_wall.gdshader")):
				GothicChurch.set_frame(m, self)
				if m.shader.resource_path.ends_with("church_wall.gdshader"):
					m.set_shader_parameter("out_scale", GothicChurch.BRICK_SCALE)   # real brick size
		_fix_glass(c)


func _merge() -> void:
	var inv := global_transform.affine_inverse()
	var groups := {}                       # material + draw distance -> [material, distance, SurfaceTool]
	var faces := PackedVector3Array()
	var done: Array[Node] = []
	var stack: Array[Node] = [self]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			if c.get_script() != null:      # doors and other scripted things stay as they are
				continue
			if c is MeshInstance3D:
				var mi := c as MeshInstance3D
				if mi.mesh == null or mi.material_override == null:
					continue
				if mi.is_visible_in_tree():
					var key := "%d|%.1f" % [mi.material_override.get_instance_id(), mi.visibility_range_end]
					if not groups.has(key):
						var st := SurfaceTool.new()
						st.begin(Mesh.PRIMITIVE_TRIANGLES)
						groups[key] = [mi.material_override, mi.visibility_range_end, st]
					var src := mi.mesh
					if src is PrimitiveMesh:
						var am := ArrayMesh.new()
						am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, src.get_mesh_arrays())
						src = am
					(groups[key][2] as SurfaceTool).append_from(src, 0, inv * mi.global_transform)
				done.append(mi)
			elif c is StaticBody3D and c.has_meta("church_part"):
				if (c as Node3D).is_visible_in_tree():
					for cs in c.get_children():
						if cs is CollisionShape3D and (cs as CollisionShape3D).shape is ConcavePolygonShape3D:
							var xf := inv * (cs as CollisionShape3D).global_transform
							for v in ((cs as CollisionShape3D).shape as ConcavePolygonShape3D).get_faces():
								faces.append(xf * v)
				done.append(c)
			else:
				stack.append(c)
	for key in groups:
		var g: Array = groups[key]
		var mi := MeshInstance3D.new()
		mi.mesh = (g[2] as SurfaceTool).commit()
		mi.material_override = g[0]
		if g[1] > 0.0:
			mi.visibility_range_end = g[1]
			mi.visibility_range_end_margin = 8.0
			mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		add_child(mi)
	if not faces.is_empty():
		var sh := ConcavePolygonShape3D.new()
		sh.backface_collision = true
		sh.set_faces(faces)
		var body := StaticBody3D.new()
		body.set_meta("surface", "stone")
		var cs := CollisionShape3D.new()
		cs.shape = sh
		body.add_child(cs)
		add_child(body)
	for n in done:
		n.get_parent().remove_child(n)
		n.queue_free()
