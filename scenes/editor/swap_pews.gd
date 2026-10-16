@tool
extends EditorScript
## Replaces the box pews in the abbey church (Interior/Pews) with the church pew model
## (assets/models/pew). Run it from the Script editor: File > Run (Ctrl+Shift+X).
## Every pew keeps its place, turn, scale and visibility; only what's inside it changes.
## A copy of the church from before is saved to user://abbey_church_before_pews.scn.

const SCENE := "res://scenes/buildings/abbey_church.scn"
const MODEL := "res://assets/models/pew/church_pew.dae"
const MESH_OUT := "res://assets/models/pew/church_pew_mesh.res"
const MAT_OUT := "res://assets/models/pew/church_pew.tres"
const LENGTH := 3.2     # metres, same as the old pews
const HEIGHT := 1.05    # top of the backrest


func _run() -> void:
	var err := DirAccess.copy_absolute(ProjectSettings.globalize_path(SCENE),
		ProjectSettings.globalize_path("user://abbey_church_before_pews.scn"))
	if err != OK:
		printerr("PEWS: could not back up the church (", err, "), nothing changed")
		return
	var mat := _material()
	ResourceSaver.save(mat, MAT_OUT, ResourceSaver.FLAG_CHANGE_PATH)
	var mesh := _mesh()
	ResourceSaver.save(mesh, MESH_OUT, ResourceSaver.FLAG_CHANGE_PATH)
	mat = load(MAT_OUT)
	mesh = load(MESH_OUT)

	var root := (load(SCENE) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) as Node3D
	var pews := root.get_node_or_null("Interior/Pews")
	if pews == null:
		printerr("PEWS: no Interior/Pews in the church, nothing changed")
		root.free()
		return
	var sh := ConcavePolygonShape3D.new()     # one shape shared by every pew
	sh.backface_collision = true
	sh.set_faces(mesh.get_faces())
	var count := 0
	for pew in pews.get_children():
		if not pew is Node3D:
			continue
		var vis := 0.0
		for c in pew.get_children():
			if c is MeshInstance3D:
				vis = maxf(vis, (c as MeshInstance3D).visibility_range_end)
		for c in pew.get_children():
			pew.remove_child(c)
			c.free()
		var mi := MeshInstance3D.new()
		mi.name = "Mesh"
		mi.mesh = mesh
		mi.material_override = mat
		if vis > 0.0:
			mi.visibility_range_end = vis
			mi.visibility_range_end_margin = 8.0
			mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		pew.add_child(mi)
		mi.owner = root
		var body := StaticBody3D.new()
		body.name = "Collision"
		body.set_meta("surface", "wood")
		body.set_meta("church_part", true)
		var cs := CollisionShape3D.new()
		cs.shape = sh
		body.add_child(cs)
		pew.add_child(body)
		body.owner = root
		cs.owner = root
		count += 1

	var out := PackedScene.new()
	err = out.pack(root)
	root.free()
	if err != OK:
		printerr("PEWS: could not pack the church (", err, "), nothing changed")
		return
	err = ResourceSaver.save(out, SCENE)
	if err != OK:
		printerr("PEWS: could not save the church (", err, ")")
		return
	EditorInterface.get_resource_filesystem().scan()
	print("PEWS: replaced ", count, " pews with the church pew model. Backup: user://abbey_church_before_pews.scn")


## The model's three pieces in one mesh: turned to face the altar (-Z), LENGTH long, HEIGHT tall,
## centred on its node with its feet on the floor.
func _mesh() -> ArrayMesh:
	var model := (load(MODEL) as PackedScene).instantiate() as Node3D
	var parts := []
	var box := AABB()
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		var t := Transform3D()
		var x: Node = mi
		while x is Node3D and x != model:
			t = (x as Node3D).transform * t
			x = x.get_parent()
		var b := t * mi.mesh.get_aabb()
		box = b if parts.is_empty() else box.merge(b)
		parts.append([mi.mesh, t])
	model.free()
	var s := Vector3(LENGTH / box.size.x, HEIGHT / box.size.y, HEIGHT / box.size.y)
	var c := box.get_center()
	var fit := Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO) \
		* Transform3D(Basis.from_scale(s), Vector3.ZERO) \
		* Transform3D(Basis(), -Vector3(c.x, box.position.y, c.z))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p in parts:
		var m: Mesh = p[0]
		for i in m.get_surface_count():
			st.append_from(m, i, fit * (p[1] as Transform3D))
	st.generate_tangents()
	return st.commit()


func _material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://assets/models/pew/pew_albedo.jpg")
	m.albedo_color = Color(2.5, 2.25, 1.95)   # the texture is near black: lift it to mid oak
	m.normal_enabled = true
	m.normal_texture = load("res://assets/models/pew/pew_normal.jpg")
	m.roughness = 1.0
	m.roughness_texture = load("res://assets/models/pew/pew_roughness.jpg")
	m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	return m
